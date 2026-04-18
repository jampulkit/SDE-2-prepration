# System Design — Data Migration Strategies

## 1. Prerequisites
- [01-fundamentals.md](01-fundamentals.md) — system design basics
- [09-consistency-patterns.md](09-consistency-patterns.md) — dual-write, CDC

## 2. Core Concepts

### Why Zero-Downtime Migration Matters

**At SDE-2 level, interviewers expect you to know how to evolve a system without taking it offline. "We'll schedule a maintenance window" is not an acceptable answer for a system serving millions of users.**

### Database Schema Migration [🔥 Must Know]

**The expand-contract pattern (safe for zero-downtime):**

```
WRONG: ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL;
  → Locks table for minutes/hours on large tables. Blocks all reads and writes.

RIGHT: Expand-Contract (3 phases)

Phase 1 — Expand (backward compatible):
  ALTER TABLE users ADD COLUMN phone VARCHAR(20) NULL;  -- nullable, no lock on PG
  Deploy code that writes to BOTH old and new columns.
  Backfill: UPDATE users SET phone = 'unknown' WHERE phone IS NULL; (batched)

Phase 2 — Migrate:
  All code reads from new column.
  Verify: no code reads old column. Run for 1-2 weeks.

Phase 3 — Contract:
  ALTER TABLE users ALTER COLUMN phone SET NOT NULL;  -- now safe
  Remove old column if applicable.
  Remove dual-write code.
```

**Safe schema change rules:**
- Adding a nullable column: safe (no lock in PostgreSQL)
- Adding a NOT NULL column: unsafe (locks table). Use expand-contract.
- Renaming a column: unsafe (breaks existing queries). Use expand-contract.
- Dropping a column: safe only after all code stops reading it.
- Adding an index: use `CREATE INDEX CONCURRENTLY` (PostgreSQL) to avoid locking.

### Service Migration: Strangler Fig Pattern [🔥 Must Know]

**Gradually replace a legacy system by routing traffic to the new system one feature at a time.**

```
Phase 1: New service handles 0% of traffic (shadow mode)
  Client → Legacy System (serves response)
           ↓ (copy request)
           New System (processes but response discarded, compare results)

Phase 2: Canary (1-5% of traffic to new system)
  Client → Router → 95% Legacy System
                   → 5% New System
  Monitor: error rates, latency, correctness.

Phase 3: Gradual rollout (5% → 25% → 50% → 100%)
  Increase traffic to new system. Decrease to legacy.
  Feature flags control the split.

Phase 4: Decommission legacy
  100% traffic on new system for 2+ weeks with no issues.
  Remove legacy system.
```

### Data Migration Patterns

**Dual-write:**
```
Write to BOTH old and new systems simultaneously.
  Pros: simple concept
  Cons: not atomic (one can fail), ordering issues, performance overhead
  Use when: short migration window, low write volume
```

**CDC (Change Data Capture):**
```
Old DB → transaction log → Debezium → Kafka → New DB
  Pros: reliable, ordered, no application changes
  Cons: eventual consistency (seconds of lag)
  Use when: migrating databases, keeping systems in sync long-term
```

**Backfill + CDC:**
```
1. Start CDC: stream changes from old DB to new DB (captures ongoing changes)
2. Backfill: copy all existing data from old DB to new DB (batch job)
3. CDC catches up: processes changes that happened during backfill
4. Verify: compare old and new DB (row counts, checksums)
5. Switch reads to new DB
6. Switch writes to new DB
7. Decommission old DB

This is the safest approach for large-scale database migrations.
```

### Data Validation

```
Before switching traffic:
  1. Row count comparison: SELECT COUNT(*) from both DBs
  2. Checksum comparison: hash random samples of rows
  3. Shadow reads: send read queries to both, compare results
  4. Reconciliation job: nightly comparison of all records

After switching:
  5. Monitor error rates for 1-2 weeks
  6. Keep old system running (read-only) as rollback option
```

### Rollback Strategy

```
Always have a rollback plan BEFORE starting migration.

Database rollback:
  - Keep old DB running and receiving CDC updates (reverse CDC)
  - Feature flag to switch reads/writes back to old DB instantly
  - Test rollback procedure in staging before production

Service rollback:
  - Feature flag to route traffic back to legacy service
  - Keep legacy service deployed and warm (not just in code repo)
  - Rollback should take < 5 minutes (feature flag flip, not a deployment)
```

🎯 **Likely Follow-ups:**
- **Q:** How do you handle a migration that takes weeks?
  **A:** Use the backfill + CDC approach. CDC runs continuously, keeping the new system in sync. Take as long as needed for backfill and validation. The cutover itself is instant (feature flag flip).
- **Q:** What if the old and new systems have different data models?
  **A:** The CDC consumer or backfill job includes a transformation layer that maps old schema to new schema. Test the transformation thoroughly with production data samples.
- **Q:** How do you migrate without losing a single transaction?
  **A:** CDC from the transaction log guarantees no data loss (the log is the source of truth). Dual-write is riskier because one write can fail. For payment systems, use the outbox pattern: write to old DB + outbox in one transaction, relay from outbox to new system.

## 3. Revision Checklist

- [ ] Expand-contract: add nullable column → backfill → set NOT NULL. Never add NOT NULL directly.
- [ ] `CREATE INDEX CONCURRENTLY` to avoid table locks.
- [ ] Strangler fig: shadow → canary (5%) → gradual rollout → decommission legacy.
- [ ] Backfill + CDC: start CDC first, then backfill, CDC catches up, verify, switch.
- [ ] Dual-write: simple but not atomic. Use for short migrations only.
- [ ] Validation: row counts, checksums, shadow reads, reconciliation jobs.
- [ ] Rollback: feature flag flip (< 5 min). Keep old system warm. Test rollback in staging.
- [ ] Feature flags control traffic split. Not deployments.

> 🔗 **See Also:** [02-system-design/09-consistency-patterns.md](09-consistency-patterns.md) for CDC and dual-write patterns. [03-distributed-systems/03-distributed-transactions.md](../03-distributed-systems/03-distributed-transactions.md) for outbox pattern.
