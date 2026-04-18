# Redis — Deep Dive

## 1. What & Why

**Redis is an in-memory data structure store that provides sub-millisecond latency for reads and writes. It's the most commonly used caching layer in modern backend systems and appears in virtually every system design interview.**

Used for: caching (most common), session storage, rate limiting, leaderboards, pub-sub messaging, distributed locks, real-time analytics.

💡 **Intuition — Why Redis is Everywhere:** A database query takes 5-10ms. A Redis lookup takes 0.1ms. That's 50-100x faster. For a system handling 100K QPS, the difference between hitting the database and hitting Redis is the difference between needing 50 database servers and needing 1 Redis instance. Redis is the single most impactful optimization in system design.

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](../02-system-design/00-prerequisites.md) for caching strategies (cache-aside, write-through). [02-system-design/problems/distributed-cache.md](../02-system-design/problems/distributed-cache.md) for distributed cache system design. [02-system-design/problems/rate-limiter.md](../02-system-design/problems/rate-limiter.md) for Redis-based rate limiting.

## 2. Architecture & Internals

**Data structures:** Strings, Lists, Sets, Sorted Sets, Hashes, Streams, Bitmaps, HyperLogLog.

**Single-threaded:** Redis processes commands in a single thread (event loop). No locks needed. I/O multiplexing (epoll). Throughput: ~100K ops/sec per instance.

⚙️ **Under the Hood — Why Single-Threaded is FASTER:**

```
Multi-threaded approach (e.g., Memcached):
  Thread 1: lock → read → unlock → lock → write → unlock
  Thread 2: lock → (blocked, waiting) → read → unlock
  Overhead: context switching, lock contention, cache invalidation between cores

Redis single-threaded approach:
  Event loop: read → process → write → read → process → write → ...
  No locks, no context switching, no cache invalidation.
  CPU cache stays warm (all data accessed by one core).

Why it works: Redis operations are FAST (microseconds).
  The bottleneck is network I/O, not CPU.
  I/O multiplexing (epoll) handles thousands of connections on one thread.
  
Redis 6.0+ added I/O threads for network read/write (not command execution).
  Commands still processed single-threaded. I/O threads handle serialization/deserialization.
```

🎯 **Likely Follow-ups:**
- **Q:** If Redis is single-threaded, how does it handle 100K ops/sec?
  **A:** Each operation takes ~1μs (microsecond). 1 second / 1μs = 1 million potential operations. Network I/O is the bottleneck, not CPU. With I/O multiplexing, Redis handles thousands of connections without thread-per-connection overhead.
- **Q:** When does single-threaded become a bottleneck?
  **A:** CPU-intensive operations: large SORT, KEYS *, Lua scripts with heavy computation. These block the event loop. Solution: avoid expensive operations, use SCAN instead of KEYS, offload computation to clients.

**Persistence:**
- **RDB (snapshots):** Point-in-time snapshots at intervals. Fast recovery, but data loss between snapshots.
- **AOF (Append-Only File):** Logs every write. More durable (fsync every second or every write). Slower recovery.
- **Hybrid:** RDB + AOF. Best of both.

**Replication:** Master-replica. Async replication. Replicas are read-only. On master failure, manual or Sentinel-based failover.

**Redis Cluster:** Automatic sharding across multiple nodes. 16384 hash slots distributed across masters. Each master has replicas. Client-side routing.

**Eviction policies:** `noeviction`, `allkeys-lru`, `volatile-lru`, `allkeys-random`, `volatile-ttl`, `allkeys-lfu`.

## 3. Core Operations (Java — Jedis/Lettuce)

```java
// Common operations
SET key value EX 3600    // set with 1-hour TTL
GET key
DEL key
INCR counter             // atomic increment
EXPIRE key 60            // set TTL

// Sorted Set (leaderboard)
ZADD leaderboard 100 "player1"
ZREVRANGE leaderboard 0 9  // top 10

// Distributed Lock (Redlock)
SET lock_key unique_value NX EX 30  // acquire (NX = only if not exists)
// Release: check value matches, then DEL (Lua script for atomicity)
```

## 6. How to Use in System Design Interviews

**When to propose Redis:**
- Caching (most common): cache-aside, write-through
- Session storage: fast, TTL support
- Rate limiting: INCR + EXPIRE or Lua script
- Leaderboards: Sorted Sets
- Pub-sub: real-time notifications
- Distributed locks: SET NX EX

**When NOT to use:** Primary database (data loss risk with async replication), complex queries (no SQL, no joins), large datasets that don't fit in memory (Redis is memory-bound), strong consistency requirements (async replication = eventual consistency).

💥 **What Can Go Wrong with Redis:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Memory full | Eviction or OOM crash | Set `maxmemory` + eviction policy (`allkeys-lru`), monitor memory usage |
| Master failure | Data loss (async replication) | Redis Sentinel for automatic failover, accept small data loss window |
| Hot key | Single key overwhelms one node | Local cache on app servers, key replication, read from replicas |
| Thundering herd | Cache expires, all requests hit DB | Lock on cache miss, staggered TTL, probabilistic early expiration |
| Large key | Blocks event loop during serialization | Break into smaller keys, use SCAN for large collections |

## 8. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** Why is Redis fast? **A:** In-memory, single-threaded (no lock contention), efficient data structures, I/O multiplexing.
2. [🔥 Must Know] **Q:** RDB vs AOF? **A:** RDB: snapshots, fast recovery, data loss between snapshots. AOF: every write logged, more durable, slower recovery. Use both.
3. [🔥 Must Know] **Q:** How does Redis handle persistence if it's in-memory? **A:** RDB snapshots and/or AOF log. On restart, loads from disk. Data between last persist and crash is lost (unless AOF with fsync=always).
4. [🔥 Must Know] **Q:** How to implement distributed lock with Redis? **A:** `SET key value NX EX ttl`. NX ensures only one client acquires. TTL prevents deadlock. Release with Lua script checking value.
5. [🔥 Must Know] **Q:** Redis Cluster vs Sentinel? **A:** Sentinel: HA for single-master setup (automatic failover). Cluster: sharding + HA (data split across multiple masters, each with replicas). Use Sentinel for small datasets, Cluster for large.
6. [🔥 Must Know] **Q:** What is the Redlock controversy? **A:** Redlock uses multiple independent Redis masters for distributed locking. Martin Kleppmann argued it's unsafe under clock skew and GC pauses. Antirez (Redis creator) disagreed. Takeaway: for critical locks (payments), use a consensus-based system (ZooKeeper/etcd). For best-effort locks (rate limiting, dedup), Redis is fine.
7. [🔥 Must Know] **Q:** How does Redis Pub/Sub differ from Kafka? **A:** Redis Pub/Sub: fire-and-forget, no persistence, no replay, no consumer groups. If subscriber is offline, messages are lost. Kafka: persistent, replayable, consumer groups. Use Redis Pub/Sub for ephemeral events (typing indicators, presence). Use Kafka for durable events.

## Additional Deep-Dive Topics

### Redis Cluster Internals [🔥 Must Know]

```
16384 hash slots distributed across N masters:
  slot = CRC16(key) % 16384
  
  Master A: slots 0-5460
  Master B: slots 5461-10922
  Master C: slots 10923-16383
  Each master has 1+ replicas for HA.

Client routing:
  Client sends command to any node.
  If node owns the slot → execute.
  If not → MOVED redirect: "MOVED 3999 192.168.1.2:6379"
  Smart clients (Jedis, Lettuce) cache slot→node mapping, route directly.

Adding a node:
  New node joins with 0 slots.
  Reshard: migrate slots from existing nodes to new node.
  Only affected keys are moved (consistent hashing-like behavior).

Failover:
  Replica detects master failure (heartbeat timeout).
  Replica promotes itself, takes over master's slots.
  Other nodes update their slot mapping.
```

### Distributed Lock — Redlock vs Single-Instance

```
Single-instance lock (simple, good enough for most cases):
  SET lock:order:123 <unique_id> NX EX 30
  -- NX: only if not exists. EX 30: auto-expire in 30s.
  
  Release (Lua script for atomicity):
  if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("del", KEYS[1])
  end
  -- Only delete if WE hold the lock (check unique_id).

Redlock (multi-master, higher safety):
  1. Get current time.
  2. Try to acquire lock on N/2+1 independent Redis masters.
  3. If majority acquired within timeout → lock acquired.
  4. If not → release all locks, retry.
  
  When to use Redlock: when single Redis failure = unacceptable.
  When NOT to use: for critical financial operations (use ZooKeeper/etcd instead).
```

### Redis Pub/Sub vs Streams

| Feature | Pub/Sub | Streams |
|---------|---------|---------|
| Persistence | No (fire-and-forget) | Yes (stored in Redis) |
| Replay | No | Yes (read from any ID) |
| Consumer groups | No | Yes (like Kafka consumer groups) |
| Delivery | At-most-once | At-least-once (with ACK) |
| Use case | Typing indicators, presence | Event log, task queue, lightweight Kafka alternative |

```
// Streams (lightweight Kafka in Redis)
XADD mystream * name "order" action "created"    // append event
XREAD COUNT 10 STREAMS mystream 0                  // read from beginning
XREADGROUP GROUP mygroup consumer1 COUNT 10 STREAMS mystream >  // consumer group
XACK mystream mygroup <message-id>                 // acknowledge processing
```

### Memory Optimization

```
Key naming: use short prefixes. "u:123:name" not "user:123:name" (saves bytes × millions of keys).

Data structure encoding (automatic):
  Small hashes (<128 fields, values <64 bytes) → ziplist (compact, sequential)
  Large hashes → hashtable (fast, more memory)
  
  Configure thresholds:
  hash-max-ziplist-entries 128
  hash-max-ziplist-value 64

Compression: Redis doesn't compress values. Compress in application (gzip/snappy) for large values.

Memory analysis:
  INFO memory                    -- total memory usage
  MEMORY USAGE key               -- memory for specific key
  redis-cli --bigkeys            -- find largest keys
  redis-cli --memkeys            -- memory usage per key type
```

## 9. Revision Checklist
- [ ] In-memory, single-threaded, ~100K ops/sec
- [ ] Data structures: String, List, Set, Sorted Set, Hash, Stream
- [ ] Persistence: RDB (snapshots) + AOF (write log)
- [ ] Eviction: allkeys-lru most common for caching
- [ ] Cluster: 16384 hash slots, automatic sharding
- [ ] Use for: caching, sessions, rate limiting, leaderboards, locks
- [ ] Distributed lock: SET NX EX + Lua script for release
