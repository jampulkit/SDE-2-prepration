# Design: Distributed Cache

## 1. Problem Statement & Scope

**Design a distributed in-memory caching system like Memcached or Redis Cluster that provides sub-millisecond key-value lookups across multiple nodes with high availability.**

**Clarifying questions to ask:**
- What operations? → GET, SET, DELETE with TTL
- Data types? → Strings initially, extensible to lists/sets/hashes
- Consistency model? → Eventual consistency OK (it's a cache, not source of truth)
- Eviction policy? → LRU (Least Recently Used)
- Scale? → 10 TB data, 1M QPS across cluster

💡 **Why this is important:** Caching is the single most impactful optimization in system design. Understanding how a distributed cache works internally (consistent hashing, LRU eviction, replication) is foundational for every other system design problem.

## 2. Requirements

**Functional:**
- GET/SET/DELETE by key
- TTL (Time To Live) support — auto-expire keys
- Eviction policies (LRU default)
- Support for various data types (strings, lists, sets, hashes)

**Non-functional:**
- Sub-millisecond latency (< 1ms for GET/SET)
- High throughput (100K+ ops/sec per node)
- Horizontal scalability (add nodes to increase capacity)
- High availability (node failure doesn't cause downtime)
- Partition tolerance (network splits handled gracefully)

**Estimation:**
```
10 TB total data, average value size 1 KB
Number of keys: 10 TB / 1 KB = 10 billion keys
1M QPS across cluster
Per-node capacity: ~100K QPS → need ~10 nodes for QPS
Per-node memory: ~64-128 GB → need ~80-160 nodes for data
  (10 TB / 128 GB per node ≈ 80 nodes)
```

## 3. High-Level Design

```
┌────────┐    ┌──────────────────┐    ┌─────────────┐
│ Client │───→│ Client Library   │───→│ Cache Node 1│ (primary)
│ (App   │    │ (consistent hash │    │ (in-memory) │──→ Replica 1a
│ Server)│    │  routing)        │    └─────────────┘
└────────┘    │                  │    ┌─────────────┐
              │ hash(key) →      │───→│ Cache Node 2│ (primary)
              │ determine node   │    │ (in-memory) │──→ Replica 2a
              └──────────────────┘    └─────────────┘
                                      ┌─────────────┐
                                 ───→ │ Cache Node 3│ (primary)
                                      │ (in-memory) │──→ Replica 3a
                                      └─────────────┘
```

**Key components:**
- **Consistent hashing** for key distribution (virtual nodes for even balance)
- **In-memory storage** on each node: hash table for O(1) lookup + doubly-linked list for LRU
- **Replication** for availability (async to replicas)
- **Client library** handles routing (no central proxy = no bottleneck)

**Data structure per node — LRU Cache** [🔥 Must Know]:

```
HashMap<Key, Node> + Doubly-Linked List

HashMap: key → pointer to linked list node (O(1) lookup)
Linked List: most recently used at HEAD, least recently used at TAIL

GET(key):
  1. HashMap lookup → O(1)
  2. Move node to HEAD of linked list → O(1)
  3. Return value

SET(key, value):
  1. If key exists: update value, move to HEAD → O(1)
  2. If key doesn't exist:
     a. If at capacity: remove TAIL node (LRU eviction), remove from HashMap
     b. Create new node, add to HEAD, add to HashMap → O(1)

DELETE(key):
  1. HashMap lookup → O(1)
  2. Remove node from linked list → O(1)
  3. Remove from HashMap → O(1)

All operations: O(1) time ✓
```

```
Doubly-Linked List (most recent → least recent):
  HEAD ↔ [D] ↔ [B] ↔ [A] ↔ [C] ↔ TAIL
                                     ↑ evict this first (LRU)

HashMap:
  A → pointer to node [A]
  B → pointer to node [B]
  C → pointer to node [C]
  D → pointer to node [D]

GET(B): move [B] to HEAD → HEAD ↔ [B] ↔ [D] ↔ [A] ↔ [C] ↔ TAIL
```

> 🔗 **See Also:** [04-lld/problems/cache-lru-lfu.md](../../04-lld/problems/cache-lru-lfu.md) for complete Java implementation of LRU/LFU cache.

## 4. Deep Dive

**Consistent hashing** [🔥 Must Know]:

```
Hash ring: 0 ────── Node1 ────── Node2 ────── Node3 ────── 2^32

Key "user:123" → hash = 0x4A2B → falls between Node1 and Node2 → routed to Node2

Virtual nodes: each physical node gets 100-200 positions on the ring
  Node1: v1, v2, ..., v150 (scattered around ring)
  Node2: v1, v2, ..., v150
  This ensures even key distribution (without virtual nodes, one node might own 60% of the ring)

Adding Node4: only keys between Node4 and its predecessor move to Node4
  ~K/N keys remapped (K = total keys, N = nodes)
  Much better than hash(key) % N which remaps almost ALL keys
```

**Replication:**
- Primary node handles writes
- Async replication to N-1 replicas (typically N=3: 1 primary + 2 replicas)
- On primary failure: replica promoted to primary (automatic failover)
- Trade-off: async replication is fast but may lose recent writes (last few milliseconds)

| Replication Mode | Latency | Data Safety | Use When |
|-----------------|---------|-------------|----------|
| Async | Low (don't wait for replicas) | May lose recent writes | Default for caches (speed > durability) |
| Sync | Higher (wait for all replicas) | No data loss | When cache acts as primary store |
| Semi-sync | Medium (wait for 1 replica) | Balanced | Good compromise |

**Cache stampede prevention** [🔥 Must Know]:

```
Problem: popular key expires → 1000 requests simultaneously miss cache → all hit DB

Solutions:
1. Locking: first request acquires lock, fetches from DB, populates cache.
   Other requests wait (or return stale data).

2. Probabilistic early expiration: each request has a small chance of
   refreshing the cache BEFORE it expires. As expiry approaches,
   probability increases. One request refreshes early, others still hit cache.

3. Staggered TTL: add random jitter to TTL (e.g., TTL = 300 ± 30 seconds).
   Prevents many keys from expiring at the exact same time.

4. Background refresh: separate thread refreshes popular keys before expiry.
```

**Hot key problem:**

```
Problem: one key (e.g., celebrity profile, viral post) gets 100K QPS
  → single cache node handling that key is overloaded

Solutions:
1. Local cache on app servers: cache hot keys in-process (HashMap/Caffeine)
   → no network hop, but each server has its own copy

2. Key replication: replicate hot key across multiple cache nodes
   → client randomly picks one of the replicas

3. Read from replicas: allow reads from replica nodes (not just primary)
   → distributes read load across primary + replicas
```

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Node failure | Data on that node lost | Consistent hashing routes to next node. Replicas provide redundancy. Cache is not source of truth — DB is the fallback. |
| Cache stampede | DB overwhelmed | Locking, probabilistic early expiration, staggered TTL |
| Hot key | Single node overloaded | Local cache, key replication, read from replicas |
| Network partition | Some nodes unreachable | Continue serving from reachable nodes. Accept stale data. |
| Memory full | Can't store new keys | LRU eviction removes least recently used keys |
| Inconsistency | Cache has stale data | TTL-based expiration, event-based invalidation |

🎯 **Likely Follow-ups:**
- **Q:** How does Redis Cluster differ from this design?
  **A:** Redis Cluster uses hash slots (16384 slots) instead of consistent hashing. Each node owns a range of slots. Keys are assigned to slots via `CRC16(key) % 16384`. Resharding moves slots between nodes. It's simpler than consistent hashing but less flexible.
- **Q:** How do you handle cache warming after a node restart?
  **A:** Options: (1) Let it warm up naturally (cache misses go to DB, gradually fill cache). (2) Pre-warm from a snapshot (Redis RDB). (3) Replicate from another node. (4) Shadow traffic: replay recent requests to fill the cache.
- **Q:** Cache vs CDN — when to use which?
  **A:** CDN caches static content (images, CSS, JS) at edge locations close to users. Application cache (Redis) caches dynamic data (query results, session data) close to the application. Use both: CDN for static, Redis for dynamic.

## 5. Advanced / Follow-ups
- **Persistence:** RDB snapshots (periodic full dump) + AOF (append-only log of every write) like Redis
- **Cluster auto-discovery:** Gossip protocol for nodes to discover each other
- **Cross-datacenter replication:** Async replication across regions for disaster recovery
- **Multi-tier caching:** L1 (local in-process) → L2 (distributed Redis) → L3 (DB)

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Use a HashMap" | "HashMap + doubly-linked list for O(1) LRU eviction" |
| "hash(key) % N for routing" | "Consistent hashing with virtual nodes — only K/N keys remapped on node change" |
| No replication | "Async replication to 2 replicas for availability. Accept potential data loss (it's a cache)." |
| No stampede handling | "Lock on cache miss, staggered TTL, probabilistic early expiration" |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Data structure | LRU: HashMap + doubly-linked list, O(1) all operations |
| Distribution | Consistent hashing with virtual nodes |
| Replication | Async replication, failover strategy |
| Failure handling | Cache stampede, hot key, node failure |
| Trade-offs | Cache is not source of truth, eventual consistency OK |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Distributed in-memory cache like Memcached/Redis Cluster. GET/SET/DELETE with TTL.
10TB data, 1M QPS. Sub-millisecond latency. LRU eviction. High availability."

[5-10 min] Estimation:
"Per-node: 100K QPS, 64-128GB memory. Need ~10 nodes for QPS, ~80 for data.
Total: ~100 nodes. Consistent hashing for key distribution."

[10-20 min] High-Level Design:
"Client library does consistent hashing to route to the right node.
Each node: HashMap + doubly-linked list for LRU. Async replication to one replica.
No central proxy (client-side routing avoids bottleneck)."

[20-40 min] Deep Dive:
"LRU implementation: HashMap for O(1) lookup, doubly-linked list for O(1) eviction.
Consistent hashing with virtual nodes (150 per physical) for even distribution.
Cache stampede prevention: lock per key, only one thread fetches from DB on miss.
Hot key: replicate to multiple nodes, client randomly picks one."

[40-45 min] Wrap-up:
"Monitoring: hit rate, miss rate, eviction rate, memory usage, latency p99.
Failure: replica promoted on node failure. Client retries on next node in ring.
Extensions: write-through mode, pub/sub for invalidation, multi-region replication."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| No consistent hashing | Adding/removing nodes invalidates all keys | Consistent hashing with virtual nodes |
| No cache stampede prevention | 1000 threads hit DB simultaneously on cache miss | Mutex per key: one thread fetches, others wait |
| Treating cache as source of truth | Cache can lose data (eviction, restart) | Cache is always a copy. DB is source of truth. |
| No replication | Node failure = data loss + cache miss storm | Async replication to at least one replica |
| Ignoring hot keys | One popular key overloads a single node | Replicate hot keys to multiple nodes |

## 8. Revision Checklist

- [ ] LRU: HashMap + doubly-linked list, O(1) GET/SET/DELETE/eviction
- [ ] Consistent hashing with virtual nodes (100-200 per physical node)
- [ ] Async replication (1 primary + 2 replicas), replica promotion on failure
- [ ] Cache stampede: locking, probabilistic early expiration, staggered TTL
- [ ] Hot key: local cache, key replication, read from replicas
- [ ] Cache is NOT source of truth — data loss is acceptable, DB is fallback
- [ ] Client library handles routing (no central proxy bottleneck)
- [ ] Estimation: 10 TB data, 1M QPS, ~80-160 nodes

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](../00-prerequisites.md) for consistent hashing and caching strategies. [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis internals. [04-lld/problems/cache-lru-lfu.md](../../04-lld/problems/cache-lru-lfu.md) for LRU/LFU Java implementation.

---

## 9. Interviewer Deep-Dive Questions

1. **"A cache node fails. 1000 keys suddenly have no cache. What happens?"**
   → Thundering herd: 1000 concurrent requests hit DB for the same keys. Solutions: (1) Consistent hashing with virtual nodes — only 1/N keys are affected. (2) Lock on cache miss — only one request fetches from DB, others wait. (3) Cache warming — pre-populate new node from replica.

2. **"Hot key problem — one key gets 100K QPS."**
   → Single Redis node can handle 100K QPS, but if it's one key, it's one CPU core. Solutions: (1) Replicate hot key to multiple nodes, client randomly picks one. (2) Local in-memory cache (L1) in front of Redis (L2). (3) Key splitting: `hot_key_1`, `hot_key_2`, ..., `hot_key_10` — client hashes to pick one.

3. **"Cache and DB are inconsistent. How do you detect and fix?"**
   → Detection: periodic consistency checker (sample keys, compare cache vs DB). Fix: cache-aside with DELETE (not UPDATE) on write. For critical data: write-through cache. For eventual consistency: TTL ensures staleness is bounded.

4. **"How do you handle cache warming after a deploy or cold start?"**
   → (1) Pre-warm: script that loads top-N hot keys from DB into cache before routing traffic. (2) Gradual rollout: shift traffic slowly to new nodes. (3) Shadow mode: new cache serves reads alongside old cache, builds up entries.

5. **"LRU vs LFU — when would you pick each?"**
   → LRU: good for recency-biased workloads (most recent = most likely accessed again). LFU: good for frequency-biased workloads (popular items stay cached even if not accessed recently). LFU is better for CDN caches. LRU is simpler and works well for most cases.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Cache node | Thundering herd on DB | Consistent hashing (limits blast radius). Lock on miss. Replica promotion. |
| All cache nodes | DB overwhelmed | Circuit breaker on DB. Serve stale data if possible. Emergency cache rebuild. |
| Network partition | Split-brain: stale reads | TTL limits staleness. Prefer AP (available + partition-tolerant) for cache. |
