# Consistency in Practice — Patterns & Anti-Patterns

## 1. Prerequisites
- [01-cap-theorem-consistency.md](01-cap-theorem-consistency.md) — CAP theorem, consistency models
- [03-distributed-transactions.md](03-distributed-transactions.md) — saga, outbox pattern

## 2. Core Concepts

### The Dual-Write Problem [🔥 Must Know]

**Any time you write to two different systems (DB + cache, DB + search index, DB + message queue), you risk inconsistency if one write fails.**

(Detailed in [02-system-design/06-consistency-patterns.md](../02-system-design/06-consistency-patterns.md))

**Solutions ranked by reliability:**
1. **Outbox pattern + CDC** (most reliable): write event to DB atomically, Debezium relays to Kafka
2. **Cache-aside with invalidation** (simple): write DB, delete cache. Small inconsistency window.
3. **Write-through cache** (strong): cache writes to DB synchronously. Higher latency.

### Change Data Capture (CDC) [🔥 Must Know]

**CDC reads the database's transaction log (WAL/binlog) and publishes changes as events. This is the most reliable way to keep secondary systems (cache, search, analytics) in sync.**

```
Database (PostgreSQL) → WAL → Debezium → Kafka → Consumers
                                                    ├── Update Redis cache
                                                    ├── Update Elasticsearch index
                                                    └── Update analytics warehouse

Benefits:
  - No dual-write problem (single source of truth is the DB)
  - No application code changes (Debezium reads the WAL directly)
  - Real-time (sub-second latency)
  - Reliable (WAL is durable, Kafka is durable)
```

**Tools:** Debezium (open source, Kafka Connect), AWS DMS, Maxwell (MySQL).

### Causal Consistency [🔥 Must Know]

**Causally related operations are seen in the correct order by all nodes. Concurrent (unrelated) operations may be seen in different orders.**

```
Causal: Alice posts "I got the job!" → Bob replies "Congratulations!"
  Everyone must see Alice's post BEFORE Bob's reply.
  But unrelated posts from Carol can appear in any order.

Implementation: Lamport timestamps or vector clocks track causal dependencies.
  Each operation carries a "happens-before" timestamp.
  Replicas deliver operations in causal order.
```

### Conflict-Free Replicated Data Types (CRDTs)

**Data structures that can be replicated across nodes and merged without conflicts — mathematically guaranteed to converge.**

| CRDT | Type | Operations | Use Case |
|------|------|-----------|----------|
| G-Counter | Counter | Increment only | View counts, likes |
| PN-Counter | Counter | Increment + decrement | Inventory count |
| G-Set | Set | Add only | Tags, labels |
| OR-Set | Set | Add + remove | Shopping cart items |
| LWW-Register | Register | Set (last write wins) | User profile fields |

```
G-Counter example (3 replicas):
  Replica A: {A:5, B:0, C:0}  → total = 5
  Replica B: {A:0, B:3, C:0}  → total = 3
  Replica C: {A:0, B:0, C:7}  → total = 7
  
  Merge: {A:max(5,0,0), B:max(0,3,0), C:max(0,0,7)} = {A:5, B:3, C:7} → total = 15
  No conflicts! Each replica only increments its own counter.
```

### Consistency in Microservices

**In microservices, strong consistency across services is expensive (distributed transactions). Most systems use eventual consistency with these patterns:**

1. **Saga pattern:** Sequence of local transactions + compensating actions (see [03-distributed-transactions.md](03-distributed-transactions.md))
2. **Outbox + CDC:** Reliable event publishing without dual writes
3. **Idempotent consumers:** Handle duplicate events gracefully
4. **Read-your-writes:** Route user's reads to primary after their writes
5. **Eventual consistency with reconciliation:** Periodic jobs compare systems and fix discrepancies

## 3. Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Dual write (DB + cache) | One fails → inconsistency | Outbox pattern or cache-aside with invalidation |
| Distributed transactions (2PC) across services | Blocking, doesn't scale | Saga pattern |
| Ignoring replication lag | User doesn't see own writes | Read-after-write consistency |
| No idempotency | Duplicate processing on retry | Idempotency keys, dedup tables |
| Synchronous consistency everywhere | High latency, low availability | Use eventual consistency where acceptable |

## 4. Revision Checklist
- [ ] Dual-write problem: can't atomically write to two systems. Use outbox + CDC.
- [ ] CDC (Debezium): reads DB WAL, publishes to Kafka. Most reliable sync method.
- [ ] Causal consistency: causally related ops in order, concurrent ops may differ.
- [ ] CRDTs: auto-merging data types (G-Counter, OR-Set). No conflicts by design.
- [ ] Microservices consistency: saga + outbox + idempotency + read-your-writes.
- [ ] Anti-patterns: dual write, 2PC across services, ignoring replication lag.

> 🔗 **See Also:** [03-distributed-systems/01-cap-theorem-consistency.md](01-cap-theorem-consistency.md) for consistency models. [03-distributed-systems/03-distributed-transactions.md](03-distributed-transactions.md) for saga and outbox patterns.
