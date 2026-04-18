# System Design — Data Consistency Patterns

## 1. Prerequisites
- [03-distributed-systems/01-cap-theorem-consistency.md](../03-distributed-systems/01-cap-theorem-consistency.md) — consistency models

## 2. Core Concepts

### The Dual-Write Problem [🔥 Must Know]

**Writing to two systems (DB + cache, or DB + message queue) is NOT atomic. If one succeeds and the other fails, data is inconsistent.**

```
WRONG — Dual write:
  1. Write to DB → SUCCESS
  2. Write to Cache → FAILS (network error)
  Result: DB has new data, cache has stale data. Reads from cache return wrong value.

WRONG — Reverse order:
  1. Write to Cache → SUCCESS
  2. Write to DB → FAILS
  Result: Cache has new data, DB has old data. On cache eviction, stale DB data is loaded.
```

**Solutions:**

| Pattern | How | Consistency | Complexity |
|---------|-----|-------------|-----------|
| Cache-aside (invalidate) | Write to DB, then DELETE cache key | Eventual (small window) | Low |
| Outbox pattern | Write to DB + outbox table atomically, relay to cache/queue | Eventual (reliable) | Medium |
| CDC (Change Data Capture) | DB transaction log → Debezium → Kafka → update cache | Eventual (reliable) | Medium |
| Write-through cache | Write to cache, cache writes to DB synchronously | Strong | Medium |

### Cache-Aside with Invalidation (Most Common) [🔥 Must Know]

```
WRITE: Update DB → DELETE cache key (don't update cache — just invalidate)
READ:  Check cache → miss → read DB → populate cache

Why DELETE instead of UPDATE cache?
  Race condition with UPDATE:
    Thread A: read DB (value=1) → (context switch)
    Thread B: write DB (value=2) → update cache (value=2)
    Thread A: (resumes) → update cache (value=1) ← STALE!
  
  With DELETE:
    Thread A: read DB (value=1) → (context switch)
    Thread B: write DB (value=2) → DELETE cache
    Thread A: (resumes) → set cache (value=1) ← still stale briefly
    Next read: cache miss → reads DB (value=2) → cache updated ← CORRECT
  
  The DELETE approach has a smaller inconsistency window.
```

### Outbox Pattern [🔥 Must Know]

(Detailed in [03-distributed-systems/03-distributed-transactions.md](../03-distributed-systems/03-distributed-transactions.md))

```
BEGIN TRANSACTION
  UPDATE orders SET status = 'CONFIRMED'
  INSERT INTO outbox (event_type, payload) VALUES ('OrderConfirmed', '{...}')
COMMIT

CDC (Debezium) reads outbox → publishes to Kafka → consumer updates cache/search index
```

### Read-After-Write Consistency [🔥 Must Know]

**User writes data, then immediately reads — they should see their own write.**

```
Implementation options:
1. Read from primary: after a write, route that user's reads to the primary
   (not replica) for 10 seconds. Use a cookie/header to track "recent writer."

2. Client-side optimistic update: after writing, client updates local state
   immediately without waiting for server confirmation. Server confirms async.

3. Timestamp-based: client sends "last write timestamp" with read request.
   Server ensures the replica is at least that fresh before responding.
   If replica is behind, either wait or redirect to primary.
```

### Eventual Consistency Patterns

**Conflict resolution when two replicas have different values:**

| Strategy | How | Data Loss? | Used By |
|----------|-----|-----------|---------|
| Last-Write-Wins (LWW) | Highest timestamp wins | Yes (concurrent writes lost) | Cassandra, DynamoDB |
| Merge (application) | App-specific merge logic | No (if merge is correct) | Custom |
| CRDTs | Auto-merging data types | No | Riak, Redis CRDT |

⚙️ **Under the Hood, CRDTs (Conflict-free Replicated Data Types):**

```
Problem: two replicas independently modify the same data. How to merge without conflicts?

G-Counter (Grow-only Counter):
  Each replica maintains its own counter.
  Replica A: {A: 5, B: 0}
  Replica B: {A: 0, B: 3}
  Merge: take max of each: {A: 5, B: 3} → total = 8
  No conflicts! Both increments are preserved.

PN-Counter (Positive-Negative Counter):
  Two G-Counters: one for increments, one for decrements.
  Value = sum(increments) - sum(decrements)

OR-Set (Observed-Remove Set):
  Each add gets a unique tag. Remove only removes observed tags.
  Add "apple" on A: {("apple", tag1)}
  Add "apple" on B: {("apple", tag2)}
  Remove "apple" on A: removes tag1 only
  Merge: {("apple", tag2)} → "apple" is still in the set (B's add survives)

CRDTs guarantee: any order of operations on any replica converges to the same state.
Trade-off: limited data types (counters, sets, registers). Not general-purpose.
```

### Change Data Capture (CDC) [🔥 Must Know]

**CDC reads the database transaction log and streams changes to other systems. This is the most reliable way to keep derived data (cache, search index, analytics) in sync with the source database.**

```
Architecture:
  PostgreSQL → WAL (Write-Ahead Log) → Debezium → Kafka → Consumers
                                                          ├→ Update Redis cache
                                                          ├→ Update Elasticsearch index
                                                          └→ Update analytics DB

Why CDC over dual-write?
  1. Atomic: changes come from the DB transaction log, so they're consistent
  2. Reliable: no "write to DB succeeded but cache update failed" problem
  3. Ordered: events arrive in transaction order
  4. No application changes: Debezium reads the log directly

Debezium event format:
{
  "before": {"id": 1, "status": "PENDING"},
  "after":  {"id": 1, "status": "CONFIRMED"},
  "source": {"table": "orders", "ts_ms": 1700000000}
}
```

🎯 **Likely Follow-ups:**
- **Q:** What is the inconsistency window with cache-aside invalidation?
  **A:** Between the DB write and the cache DELETE, a reader might get stale data from cache. This window is typically milliseconds. For most applications, this is acceptable. For critical data (account balance), read from the primary DB, not cache.
- **Q:** How does read-after-write consistency work in a replicated database?
  **A:** Option 1: route the user's reads to the primary for N seconds after their write. Option 2: the client sends its last write timestamp, and the server waits until the replica is caught up to that timestamp before responding. Option 3: use synchronous replication (slower writes, but reads are always consistent).
- **Q:** When would you use CDC over the outbox pattern?
  **A:** CDC is simpler (no outbox table, no polling). But CDC depends on the database's transaction log format (vendor-specific). Outbox pattern is database-agnostic and gives you more control over the event format. Use CDC when you want to sync derived data stores. Use outbox when you need custom event schemas for domain events.

## 3. How This Shows Up in Interviews

**What to say:**
> "For cache consistency, I'll use cache-aside with invalidation: write to DB, then DELETE the cache key. On read, if cache miss, read from DB and populate cache. For the brief inconsistency window, I'll set a short TTL (5 minutes) as a safety net. For critical data (payment status), I'll read from the primary database, not the cache."

## 4. Revision Checklist
- [ ] Dual-write problem: can't atomically write to DB + cache/queue
- [ ] Cache-aside: write DB → DELETE cache (not update). Read: cache miss → DB → populate cache.
- [ ] Outbox pattern: write event to DB in same transaction, relay via CDC
- [ ] Read-after-write: read from primary for 10s after write, or timestamp-based
- [ ] LWW: simple but loses concurrent writes. CRDTs: no conflicts but limited types.
- [ ] DELETE cache (not update) to minimize race condition window

> 🔗 **See Also:** [03-distributed-systems/01-cap-theorem-consistency.md](../03-distributed-systems/01-cap-theorem-consistency.md) for consistency models. [03-distributed-systems/03-distributed-transactions.md](../03-distributed-systems/03-distributed-transactions.md) for outbox pattern.
