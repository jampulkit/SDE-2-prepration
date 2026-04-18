# Design: Payment System

## 1. Problem Statement & Scope

**Design a payment processing system like Stripe or a payment service for an e-commerce platform that handles credit card payments, refunds, and provides a complete audit trail.**

**Clarifying questions to ask:**
- Payment methods? → Credit card, bank transfer (extensible)
- Refunds? → Yes, full and partial
- Multi-currency? → Single currency initially, multi-currency as extension
- Who are the users? → Merchants integrate via API, end-users pay through merchant's UI
- Compliance? → PCI DSS compliance required

💡 **Why this is critical for your profile:** As a payments/fintech engineer, this is YOUR domain. Interviewers will expect deeper answers from you — idempotency, double-entry bookkeeping, reconciliation, and PSP integration should be second nature. This is where you differentiate yourself.

## 2. Requirements

**Functional:**
- Process payments (credit card, bank transfer)
- Handle refunds (full and partial)
- Payment status tracking (real-time status updates)
- Webhook notifications to merchants (payment succeeded/failed)
- Ledger/audit trail (every money movement recorded)
- Idempotent payment processing (no double charges on retry)

**Non-functional:**
- **Strong consistency** (no double charges, no lost payments)
- **Exactly-once processing** (idempotency key + state machine)
- 99.99% availability (payments must always work)
- PCI DSS compliance (never store raw card numbers)
- < 2s payment processing (end-to-end)

**Estimation:**
```
1M transactions/day
QPS: 1M / 86,400 ≈ 12 QPS. Peak: ~50 QPS.
  → Low QPS! But EVERY transaction must be correct. Consistency > throughput.

Each transaction: ~1 KB (payment record + ledger entries)
Storage: 1M × 1 KB × 365 = 365 GB/year
  → Single PostgreSQL instance handles this easily

Revenue at risk: if avg transaction = $50, daily volume = $50M
  → A bug causing 0.1% double charges = $50K/day lost. Correctness is paramount.
```

## 3. High-Level Design

```
┌──────────┐    ┌───────────┐    ┌─────────────────┐    ┌──────────────┐
│ Merchant │───→│ API       │───→│ Payment Service │───→│ Payment      │
│ Client   │    │ Gateway   │    │ (orchestrator)  │    │ Executor     │
└──────────┘    │ (auth,    │    │                 │    │ (calls PSP)  │
                │  rate     │    │ - Idempotency   │    └──────┬───────┘
                │  limit)   │    │ - State Machine │           │
                └───────────┘    │ - Ledger        │    ┌──────┴───────┐
                                 └────────┬────────┘    │ PSP (Stripe, │
                                          │             │  Adyen)      │
                                 ┌────────┴────────┐    └──────┬───────┘
                                 │ PostgreSQL      │           │
                                 │ (payments +     │    ┌──────┴───────┐
                                 │  ledger)        │    │ Webhook      │
                                 └─────────────────┘    │ Service      │──→ Merchant
                                          │             └──────────────┘
                                 ┌────────┴────────┐
                                 │ Redis           │
                                 │ (idempotency    │
                                 │  cache)         │
                                 └─────────────────┘
```

**Core principle: Payment State Machine** [🔥 Must Know]

```
State transitions (only valid transitions allowed):

  CREATED ──→ PROCESSING ──→ SUCCESS ──→ REFUND_REQUESTED ──→ REFUNDED
                   │                          │
                   └──→ FAILED ──→ RETRY ──→ PROCESSING
                                    │
                                    └──→ ABANDONED

Invalid transitions are REJECTED:
  SUCCESS → CREATED  ❌ (can't go backwards)
  FAILED → SUCCESS   ❌ (must go through RETRY → PROCESSING)
  REFUNDED → SUCCESS ❌ (can't un-refund)

Implementation: database CHECK constraint or application-level validation
  UPDATE payments SET status = 'SUCCESS'
  WHERE payment_id = ? AND status = 'PROCESSING'  -- only valid transition
  -- If 0 rows affected → invalid transition → reject
```

💡 **Intuition — Why State Machine?** Without a state machine, a race condition could move a payment from PROCESSING to both SUCCESS and FAILED simultaneously. The state machine ensures only one valid transition happens, and the database's row-level locking prevents concurrent transitions.

**Data Model** [🔥 Must Know]:

```sql
-- Payment record (source of truth for payment status)
payments (
  payment_id      UUID PRIMARY KEY,
  idempotency_key VARCHAR(64) UNIQUE,  -- prevents double processing
  merchant_id     BIGINT NOT NULL,
  amount          DECIMAL(19,4) NOT NULL,  -- 19 digits, 4 decimal places
  currency        VARCHAR(3) NOT NULL,     -- ISO 4217 (USD, EUR, INR)
  status          VARCHAR(20) NOT NULL,    -- CREATED, PROCESSING, SUCCESS, FAILED, ...
  psp_reference   VARCHAR(128),            -- PSP's transaction ID
  payment_method  VARCHAR(20),             -- CARD, BANK_TRANSFER
  description     VARCHAR(256),
  created_at      TIMESTAMP NOT NULL,
  updated_at      TIMESTAMP NOT NULL,
  version         INT DEFAULT 1            -- optimistic locking
)

-- Double-entry ledger (every money movement has two entries)
ledger_entries (
  entry_id    UUID PRIMARY KEY,
  payment_id  UUID NOT NULL REFERENCES payments,
  account_id  BIGINT NOT NULL,       -- buyer account or merchant account
  amount      DECIMAL(19,4) NOT NULL, -- positive for credit, negative for debit
  type        VARCHAR(10) NOT NULL,   -- DEBIT or CREDIT
  created_at  TIMESTAMP NOT NULL
)
-- CONSTRAINT: for every payment_id, SUM(amount) = 0 (debits = credits)
```

⚙️ **Under the Hood — Why DECIMAL(19,4) for Money:**
Never use `float` or `double` for money — they have precision errors (`0.1 + 0.2 = 0.30000000000000004`). `DECIMAL(19,4)` stores exact values with 4 decimal places, supporting amounts up to 10¹⁵ (quadrillions) with cent precision. In Java, use `BigDecimal`, never `double`.

## 4. Deep Dive

**Idempotency** [🔥 Must Know]:

```
Problem: Client sends payment request, server processes it, but response is lost
  (network timeout). Client retries → WITHOUT idempotency, customer is charged TWICE.

Solution: Idempotency Key
  1. Client generates a unique key (UUID) and sends it with every request
  2. Server checks Redis: has this key been processed?
     - YES → return cached result (same response as first time)
     - NO → process payment, store result in Redis with TTL (24h)
  3. Also: UNIQUE constraint on idempotency_key in payments table (DB-level safety net)

Race condition prevention:
  Two identical requests arrive simultaneously:
  - Request 1: Redis SETNX("idempotency:abc123", "processing") → success → process
  - Request 2: Redis SETNX("idempotency:abc123", "processing") → FAIL (key exists) → wait/return
  SETNX (SET if Not eXists) is atomic → only one request processes
```

**Exactly-once processing:**
Three layers of protection:
1. **Idempotency key** in Redis (fast check, prevents most duplicates)
2. **UNIQUE constraint** on idempotency_key in DB (catches race conditions Redis misses)
3. **State machine** transitions (payment can only move PROCESSING → SUCCESS once)

**Double-entry bookkeeping** [🔥 Must Know]:

```
Payment of $100 from Buyer to Merchant:

  Ledger Entry 1: DEBIT  Buyer's account   -$100
  Ledger Entry 2: CREDIT Merchant's account +$100

  SUM of all entries for this payment = -100 + 100 = 0 ✓

Refund of $100:
  Ledger Entry 3: CREDIT Buyer's account    +$100
  Ledger Entry 4: DEBIT  Merchant's account -$100

  SUM = 0 ✓

Why double-entry?
  - Self-auditing: if SUM ≠ 0 for any payment, something is wrong
  - Complete audit trail: every money movement is recorded
  - Reconciliation: compare our ledger with PSP's settlement report
  - Regulatory compliance: required for financial systems
```

**PSP integration flow:**

```
1. Payment Service creates payment record (status = CREATED)
2. Payment Service calls PSP API:
   POST https://api.stripe.com/v1/charges
   { amount: 10000, currency: "usd", source: "tok_visa", idempotency_key: "abc123" }
3. PSP returns:
   - Synchronous: { status: "succeeded", id: "ch_123" } → update to SUCCESS
   - Async: { status: "pending" } → wait for webhook
4. PSP sends webhook:
   POST https://our-api.com/webhooks/stripe
   { type: "charge.succeeded", data: { id: "ch_123" } }
5. Webhook handler: verify signature, update payment status, create ledger entries
6. Notify merchant via their registered webhook URL
```

**Reconciliation** [🔥 Must Know]:

```
Daily reconciliation job:
  1. Fetch our ledger entries for the day
  2. Fetch PSP's settlement report for the day
  3. Match by PSP reference ID
  4. Flag discrepancies:
     - Payment in our system but not in PSP → investigate (maybe PSP hasn't settled yet)
     - Payment in PSP but not in our system → investigate (maybe webhook was missed)
     - Amount mismatch → investigate (currency conversion, fees)
  5. Generate reconciliation report for finance team
```

**Failure handling:**

| Failure | Impact | Solution |
|---------|--------|---------|
| PSP timeout | Don't know if payment succeeded | Retry with SAME idempotency key. PSP returns cached result if already processed. |
| PSP returns failure | Payment failed | Mark as FAILED. Allow retry (FAILED → RETRY → PROCESSING). |
| Our service crashes mid-processing | Payment stuck in PROCESSING | Recovery job: find PROCESSING payments older than 5 min, check PSP status, update accordingly. |
| Webhook missed | Payment succeeded but we don't know | Reconciliation job catches this. Also: periodic polling of PSP for pending payments. |
| Double charge | Customer charged twice | Idempotency key prevents this. If it happens: automatic refund + alert. |

💥 **What Can Go Wrong — The Nightmare Scenarios:**

| Scenario | How It Happens | Prevention |
|----------|---------------|------------|
| Double charge | Retry without idempotency key | ALWAYS require idempotency key. UNIQUE constraint in DB. |
| Lost payment | Crash after PSP charge, before DB update | Recovery job checks PSP for PROCESSING payments. |
| Refund without charge | Race condition in refund processing | State machine: can only refund SUCCESS payments. |
| Money leak | Ledger entries don't balance | Double-entry bookkeeping. Daily reconciliation. Alert if SUM ≠ 0. |

🎯 **Likely Follow-ups:**
- **Q:** How do you handle multi-currency payments?
  **A:** Store amount in the original currency + converted amount in settlement currency. Use a currency conversion service with locked exchange rates at transaction time. Ledger entries in both currencies.
- **Q:** How do you handle PCI DSS compliance?
  **A:** Never store raw card numbers. Use tokenization: the PSP (Stripe) provides a token representing the card. We store the token, not the card number. All card data flows through the PSP's PCI-compliant infrastructure.
- **Q:** How do you handle fraud detection?
  **A:** ML model scoring each transaction: features include amount, location, device, time, merchant category, user history. High-risk transactions are flagged for manual review or automatically declined. Rules engine for known fraud patterns.
- **Q:** What if you need to support multiple PSPs (Stripe + Adyen)?
  **A:** Abstract the PSP behind an interface. Payment Executor has adapters for each PSP. Routing logic decides which PSP to use (based on currency, merchant preference, PSP health). Failover: if primary PSP is down, route to secondary.

## 5. Advanced / Follow-ups
- **Multi-currency:** Exchange rate locking, settlement in different currencies
- **Fraud detection:** ML scoring, rules engine, manual review queue
- **PCI DSS compliance:** Tokenization, encrypted storage, audit logging, access controls
- **Multi-PSP failover:** Abstract PSP interface, routing logic, automatic failover
- **Subscription/recurring payments:** Scheduled payment jobs, retry logic for failed recurring charges
- **Dispute/chargeback handling:** Merchant notification, evidence submission, automatic refund

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Use float for money" | "DECIMAL(19,4) in DB, BigDecimal in Java — never float/double for money" |
| No idempotency | "Idempotency key (UUID) + Redis SETNX + DB UNIQUE constraint — three layers of protection" |
| No state machine | "Payment state machine with valid transitions enforced by DB WHERE clause" |
| No ledger | "Double-entry bookkeeping: every payment creates debit + credit entries. SUM = 0 always." |
| "Just call Stripe API" | "PSP integration with webhook handling, retry logic, reconciliation job" |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Idempotency | Three layers: Redis + DB unique + state machine |
| State machine | Valid transitions only, enforced at DB level |
| Double-entry ledger | Debit + credit for every payment, SUM = 0 |
| PSP integration | Webhook handling, retry with idempotency, reconciliation |
| Failure handling | Crash recovery, timeout handling, reconciliation |
| Data types | DECIMAL for money, not float |
| Consistency | Strong consistency (PostgreSQL), not eventual |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Payment processing system. Credit card, bank transfer. Refunds (full and partial).
Strong consistency, exactly-once processing, idempotent. 1M transactions/day.
PCI DSS compliance. < 2s end-to-end."

[5-10 min] Estimation:
"QPS: ~12, peak ~50. Low QPS but EVERY transaction must be correct.
At $50 avg, daily volume = $50M. A 0.1% double-charge bug = $50K/day lost.
Storage: 365GB/year. Single PostgreSQL handles this."

[10-20 min] High-Level Design:
"API Gateway → Payment Service (orchestrator) → Payment Executor (calls PSP).
PostgreSQL for payments + ledger (same DB, same transaction).
Redis for idempotency key cache. Webhook service for merchant notifications."

[20-40 min] Deep Dive:
"Payment state machine: CREATED → PROCESSING → SUCCESS/FAILED. Only valid transitions.
Idempotency: client sends UUID key. Redis SETNX for fast check. DB UNIQUE for safety.
Double-entry ledger: every money movement has debit + credit entries that sum to zero.
PSP integration: call Stripe/Adyen with our idempotency key. Handle async callbacks.
Reconciliation: nightly job compares our ledger with PSP settlement reports."

[40-45 min] Wrap-up:
"Monitoring: payment success rate, latency p99, reconciliation discrepancy rate.
Failure: PSP timeout → mark as UNKNOWN → reconcile later. Never assume success.
Extensions: multi-currency, subscription billing, fraud detection."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| No idempotency key | Network retry = double charge | Client-generated UUID, server checks before processing |
| Assuming PSP response is immediate | PSP can timeout, return async | Handle UNKNOWN state, reconcile with PSP later |
| Using eventual consistency | Double charges, lost payments | Strong consistency (PostgreSQL ACID) for payment records |
| Storing raw card numbers | PCI DSS violation, massive liability | Tokenization via PSP. Never touch raw card data. |
| No double-entry ledger | Can't audit money flow, reconciliation nightmare | Every movement: debit entry + credit entry. Sum = 0. |

## 8. Revision Checklist

- [ ] Idempotency key: UUID from client, Redis SETNX for fast check, DB UNIQUE for safety
- [ ] Payment state machine: CREATED → PROCESSING → SUCCESS/FAILED, only valid transitions
- [ ] Double-entry ledger: debit + credit for every payment, SUM = 0, enables reconciliation
- [ ] PSP integration: call PSP API with idempotency key, handle webhooks for async status
- [ ] Reconciliation: daily job comparing our ledger with PSP settlement report
- [ ] Recovery job: find stuck PROCESSING payments, check PSP status, update
- [ ] DECIMAL(19,4) for money, BigDecimal in Java — NEVER float/double
- [ ] Strong consistency: PostgreSQL with ACID transactions
- [ ] Estimation: 12 QPS (low), but every transaction must be correct
- [ ] PCI DSS: tokenization, never store raw card numbers

> 🔗 **See Also:** [03-distributed-systems/03-distributed-transactions.md](../../03-distributed-systems/03-distributed-transactions.md) for distributed transaction patterns (saga, 2PC). [02-system-design/01-fundamentals.md](../01-fundamentals.md) for idempotency patterns. [02-system-design/03-message-queues-event-driven.md](../03-message-queues-event-driven.md) for webhook and event-driven patterns.

---

## 9. Interviewer Deep-Dive Questions

1. **"PSP times out mid-payment. You don't know if the charge went through. What do you do?"**
   → Mark payment as UNKNOWN. Do NOT retry immediately (might double-charge). Run a reconciliation check: query PSP's API with your idempotency key. PSP returns the actual status. Update accordingly. If PSP is also down: wait and retry the status check with exponential backoff.

2. **"Two requests with the same idempotency key arrive at the exact same millisecond."**
   → Redis SETNX is atomic — only one wins. The loser gets a "processing" response and polls for result. DB UNIQUE constraint is the safety net if Redis fails. The state machine prevents double transitions.

3. **"How do you handle partial refunds across multiple payment methods?"**
   → Refund proportionally: if user paid $70 card + $30 wallet, a $50 refund = $35 card + $15 wallet. Each refund is a separate PSP call with its own idempotency key. Ledger entries for each. State: PARTIAL_REFUND (tracks remaining refundable amount).

4. **"End-of-day reconciliation: your ledger says $1M processed, PSP says $999,500. What do you do?"**
   → $500 discrepancy. Common causes: (1) Pending transactions not yet settled by PSP. (2) Currency conversion rounding. (3) Missed webhooks. Process: auto-match by PSP reference ID. Flag unmatched entries. For missed webhooks: query PSP for those transactions. For rounding: accept within threshold ($0.01 per transaction). Alert if discrepancy > threshold.

5. **"Redis (idempotency store) goes down. Do you fail open or fail closed?"**
   → Fail CLOSED (reject payments). Reason: failing open risks double charges, which is worse than temporary unavailability. The DB UNIQUE constraint is the backup, but it's slower. Alternative: Redis Cluster with replicas — if primary fails, replica promotes in seconds.

6. **"How do you handle chargebacks/disputes?"**
   → PSP sends chargeback webhook. Create a dispute record. Freeze the merchant's payout for that amount. Merchant submits evidence (receipt, delivery proof). Forward to PSP. PSP arbitrates. If merchant loses: debit merchant's account (ledger entry). If merchant wins: release frozen funds.

7. **"How would you add support for a second PSP (Adyen alongside Stripe)?"**
   → PaymentExecutor interface with `charge()`, `refund()`, `getStatus()`. StripeExecutor and AdyenExecutor implement it. Router decides which PSP based on: currency, merchant preference, PSP health (circuit breaker), cost. Failover: if primary PSP returns 5xx, route to secondary.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| PostgreSQL | Can't process any payments | Synchronous replication to standby. Automatic failover. Payments are too critical for eventual consistency. |
| Redis | Idempotency check fails | Fail closed (reject). Fall back to DB UNIQUE check (slower but safe). |
| PSP (Stripe) | Can't charge cards | Circuit breaker → route to secondary PSP (Adyen). Queue payments if both down. |
| Webhook delivery | Don't know payment outcome | Polling job: query PSP for PROCESSING payments older than 5 min. Reconciliation catches the rest. |
