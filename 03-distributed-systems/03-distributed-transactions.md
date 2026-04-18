# Distributed Transactions

## 1. Prerequisites
- [02-consensus-algorithms.md](./02-consensus-algorithms.md) — 2PC, consensus
- [01-cap-theorem-consistency.md](./01-cap-theorem-consistency.md) — consistency models

## 2. Core Concepts

### Why Distributed Transactions Are Hard

**In a monolith with one database, ACID transactions are straightforward — BEGIN, do work, COMMIT. In microservices with separate databases, a single business operation may span multiple services, and there's no single transaction manager.**

💡 **Intuition — The Problem:** An e-commerce order involves: (1) create order in Order Service, (2) charge payment in Payment Service, (3) reserve inventory in Inventory Service. Each has its own database. If payment succeeds but inventory reservation fails, you need to refund the payment. There's no single `ROLLBACK` that spans all three databases.

```
Monolith (easy):
  BEGIN TRANSACTION
    INSERT INTO orders (...)
    UPDATE inventory SET stock = stock - 1
    INSERT INTO payments (...)
  COMMIT  -- all or nothing, guaranteed by one DB

Microservices (hard):
  Order Service DB:     INSERT INTO orders (...)     ✓
  Payment Service DB:   INSERT INTO payments (...)   ✓
  Inventory Service DB: UPDATE inventory ...          ✗ FAILS!
  
  Now what? Order and payment are committed. Can't rollback across DBs.
  Need: compensating transactions (refund payment, cancel order).
```

### Two-Phase Commit (2PC) — Revisited

(Detailed in [02-consensus-algorithms.md](./02-consensus-algorithms.md))

- Coordinator + participants. Prepare → Commit/Abort.
- **Pros:** Strong consistency, atomic across databases.
- **Cons:** Blocking (coordinator failure), high latency (2 round trips), holds locks during prepare, doesn't scale well across services.
- **Use when:** Absolutely need atomicity across databases within a single datacenter (rare in microservices). Example: MySQL XA transactions.

### Saga Pattern [🔥 Must Know]

**A saga breaks a distributed transaction into a sequence of local transactions. Each service performs its local transaction and publishes an event. If any step fails, compensating transactions undo the previous steps.**

💡 **Intuition — The Travel Booking Analogy:** Booking a trip involves: (1) book flight, (2) book hotel, (3) book car. If the car rental fails, you need to cancel the hotel and cancel the flight. Each cancellation is a "compensating transaction" — it undoes the effect of the original transaction.

**Choreography (event-driven):**

```
Happy path:
  Order Service: Create Order (PENDING) → emit OrderCreated
  Payment Service: hears OrderCreated → Process Payment → emit PaymentProcessed
  Inventory Service: hears PaymentProcessed → Reserve Stock → emit StockReserved
  Order Service: hears StockReserved → Update Order (CONFIRMED)

Failure path (inventory fails):
  Inventory Service: Reserve Stock FAILS → emit StockReservationFailed
  Payment Service: hears StockReservationFailed → REFUND Payment (compensating)
  Order Service: hears PaymentRefunded → Cancel Order (CANCELLED)
```

**Orchestration (central coordinator):**

```
Saga Orchestrator:
  1. Tell Order Service: Create Order → success
  2. Tell Payment Service: Process Payment → success
  3. Tell Inventory Service: Reserve Stock → FAILURE!
  4. Compensate:
     Tell Payment Service: Refund Payment → success
     Tell Order Service: Cancel Order → success
  5. Saga completed (rolled back)
```

| Aspect | Choreography | Orchestration |
|--------|-------------|---------------|
| Coupling | Loose (services only know events) | Tighter (orchestrator knows all steps) |
| Visibility | Hard to track overall flow | Centralized, easy to monitor/debug |
| Single point of failure | No | Orchestrator (mitigate with HA + persistence) |
| Complexity | Grows with number of services | Centralized logic, manageable |
| Best for | Simple flows (2-3 services) | Complex flows (4+ services, conditional logic) |

⚙️ **Under the Hood — Compensating Transactions:**

```
Not all operations are easily reversible:
  ✅ Payment → Refund (reversible)
  ✅ Order creation → Order cancellation (reversible)
  ⚠️ Email sent → Can't unsend! (not reversible)
  ⚠️ Physical shipment → Recall is expensive (partially reversible)

Design principle: make operations reversible where possible.
For irreversible operations: delay them until the saga is likely to succeed,
or accept that compensation may be imperfect (e.g., send "sorry" email).
```

🎯 **Likely Follow-ups:**
- **Q:** How do you handle a compensating transaction that fails?
  **A:** Retry with exponential backoff. If it still fails, alert the operations team for manual intervention. Log everything for audit. Some systems use a "saga log" that tracks the state of each step.
- **Q:** How do you ensure the saga completes even if the orchestrator crashes?
  **A:** Persist the saga state (current step, completed steps) in a database. On restart, the orchestrator resumes from the last persisted state. Use a durable message queue (Kafka) for communication.
- **Q:** Saga vs 2PC — when to use which?
  **A:** Saga for microservices (non-blocking, eventual consistency, scales well). 2PC for tightly coupled databases within one service (strong consistency, blocking, doesn't scale). In practice, sagas are used 95% of the time in microservices architectures.

### Outbox Pattern [🔥 Must Know]

**The outbox pattern solves the dual-write problem: how to atomically update a database AND publish an event to a message queue.**

**Problem:** Service needs to update DB AND publish event. If DB commits but event publish fails → data inconsistency (DB updated, downstream services don't know). If event publishes but DB fails → downstream services act on non-existent data.

```
WRONG (dual write — not atomic):
  1. UPDATE orders SET status = 'CONFIRMED'  → success
  2. Publish "OrderConfirmed" to Kafka        → FAILS (Kafka down)
  Result: DB updated, but no event published. Downstream services don't know.

WRONG (reverse order):
  1. Publish "OrderConfirmed" to Kafka        → success
  2. UPDATE orders SET status = 'CONFIRMED'  → FAILS (DB down)
  Result: Event published, but DB not updated. Downstream services act on stale data.
```

**Solution — Outbox Pattern:**

```
CORRECT (outbox — atomic):
  BEGIN TRANSACTION
    UPDATE orders SET status = 'CONFIRMED'
    INSERT INTO outbox (event_type, payload) VALUES ('OrderConfirmed', '{...}')
  COMMIT
  -- Both writes are in the SAME database transaction → atomic!

  Separate process (CDC or poller):
    Read from outbox table → Publish to Kafka → Mark as published (or delete)
```

💡 **Intuition:** Instead of trying to write to two different systems atomically (impossible without 2PC), write everything to ONE system (the database) atomically, then asynchronously relay the event to the message queue. The outbox table is the "bridge" between the database and the message queue.

**CDC (Change Data Capture)** — the modern approach:

```
Instead of polling the outbox table, use CDC (e.g., Debezium):
  1. Debezium reads the database's transaction log (WAL/binlog)
  2. Detects new rows in the outbox table
  3. Publishes them to Kafka automatically
  4. No polling, no delay, no missed events

Benefits: real-time, reliable, no application-level polling code needed.
```

### Idempotent Consumers [🔥 Must Know]

**Since at-least-once delivery means duplicates are possible, consumers must handle receiving the same message multiple times without side effects.**

```java
// Idempotent consumer pattern
public void handleOrderConfirmed(OrderConfirmedEvent event) {
    // Check if already processed (dedup)
    if (processedEvents.contains(event.getEventId())) {
        log.info("Duplicate event {}, skipping", event.getEventId());
        return;
    }
    
    // Process the event
    inventoryService.reserveStock(event.getOrderId(), event.getItems());
    
    // Record as processed (in same transaction as the business logic)
    processedEvents.add(event.getEventId());
}
```

**Strategies for idempotency:**
- **Dedup table:** Store processed event IDs. Check before processing.
- **Database unique constraints:** `INSERT ... ON CONFLICT DO NOTHING`
- **Natural idempotency:** Use SET (idempotent) instead of INCREMENT (not idempotent). `SET balance = 50` is safe to retry. `INCREMENT balance BY 10` is not.

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Dual write (DB + Kafka) | Inconsistency if one fails | Outbox pattern (single atomic write) |
| Compensating transaction fails | Saga stuck in inconsistent state | Retry + alert + manual intervention |
| Duplicate event processing | Double charge, double inventory deduction | Idempotent consumers (dedup table) |
| Saga timeout | Step takes too long, other steps waiting | Timeout per step, compensate on timeout |
| Out-of-order events | Process refund before payment | Sequence numbers, or design for out-of-order |

> 🔗 **See Also:** [02-system-design/03-message-queues-event-driven.md](../02-system-design/03-message-queues-event-driven.md) for Kafka and event-driven patterns. [02-system-design/problems/payment-system.md](../02-system-design/problems/payment-system.md) for idempotency in payment processing.

## 3. Comparison Tables

| Pattern | Consistency | Blocking | Complexity | Scalability | Use Case |
|---------|------------|----------|-----------|-------------|----------|
| 2PC | Strong | Yes (coordinator crash) | Medium | Low | Cross-DB atomicity (single DC) |
| Saga (choreography) | Eventual | No | Medium | High | Simple multi-service flows |
| Saga (orchestration) | Eventual | No | High | High | Complex multi-service flows |
| Outbox + CDC | Eventual | No | Medium | High | Reliable event publishing |

## 4. How This Shows Up in Interviews

**What to say:**
> "For this e-commerce order flow spanning 3 services, I'll use the saga pattern with orchestration. The orchestrator manages the sequence: create order → charge payment → reserve inventory. If inventory fails, it triggers compensating transactions: refund payment → cancel order. I'll use the outbox pattern to ensure each service's DB update and event publication are atomic."

## 5. Deep Dive Questions

1. [🔥 Must Know] **How do you handle transactions across microservices?** — Saga pattern, not 2PC.
2. [🔥 Must Know] **Explain the Saga pattern. Choreography vs orchestration.** — Events vs coordinator, trade-offs.
3. [🔥 Must Know] **What is the outbox pattern and why is it needed?** — Dual-write problem, atomic DB + event.
4. **What are compensating transactions? Give an example.** — Refund for failed order, cancel reservation.
5. [🔥 Must Know] **How do you ensure exactly-once processing?** — At-least-once delivery + idempotent consumers.
6. **When would you use 2PC vs Saga?** — 2PC for single-DC strong consistency, saga for microservices.
7. **What is CDC (Change Data Capture)?** — Read DB transaction log, publish changes to Kafka (Debezium).
8. **How do you handle partial failures in a saga?** — Compensating transactions, retry, timeout, manual intervention.

## 6. Revision Checklist

- [ ] 2PC: strong consistency, blocking on coordinator failure, doesn't scale across services
- [ ] Saga: sequence of local transactions + compensating transactions for rollback
- [ ] Choreography: event-driven, loose coupling, hard to track (good for 2-3 services)
- [ ] Orchestration: central coordinator, easier to debug (good for 4+ services)
- [ ] Outbox pattern: write event to DB in same transaction, publish separately via CDC/poller
- [ ] CDC (Debezium): reads DB transaction log, publishes to Kafka — real-time, reliable
- [ ] Dual-write problem: can't atomically write to DB AND Kafka → use outbox
- [ ] Idempotent consumers: dedup table, unique constraints, natural idempotency (SET vs INCREMENT)
- [ ] Compensating transactions: not all operations are reversible (email sent, shipment dispatched)
