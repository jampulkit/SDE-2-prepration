# Day-Before-Interview Revision Checklist

**Read this in 30 minutes the night before your interview. It pulls the top items from every section.**

---

## DSA Patterns (5 minutes)

- [ ] **Arrays/Hashing:** frequency map, prefix sum + HashMap (init with {0:1}), two pointers on sorted array
- [ ] **Sliding Window:** fixed (sum of k), variable (expand right, shrink left when invalid). O(n).
- [ ] **Stack:** monotonic stack for next greater/smaller. Store indices, not values.
- [ ] **Linked List:** dummy head for edge cases. Fast/slow for cycle detection and middle.
- [ ] **Trees:** DFS (preorder=copy, inorder=BST sorted, postorder=children first). BFS for level-order.
- [ ] **Graphs:** BFS (shortest unweighted), DFS (connected components), Dijkstra (weighted), Union-Find (connectivity)
- [ ] **DP:** define state → recurrence → base case → iteration order → space optimize. Top-down first, convert to bottom-up.
- [ ] **Greedy:** sort by end time for intervals. Exchange argument for proof.
- [ ] **Binary Search:** `lo <= hi` for exact match. `lo < hi` for boundary. Always check `mid` calculation for overflow.
- [ ] **Heap:** PriorityQueue (min-heap default). Max-heap: `Comparator.reverseOrder()`. Top-K = min-heap of size K.

## System Design Framework (3 minutes)

- [ ] **5 phases:** Requirements (5 min) → Estimation (5 min) → High-Level Design (10 min) → Deep Dive (20 min) → Wrap-up (5 min)
- [ ] **Always ask:** scale (DAU, QPS), read/write ratio, latency target, consistency requirement, data retention
- [ ] **Estimation:** 1M req/day ≈ 12 QPS. 86400 sec/day ≈ 10⁵. Peak ≈ 2-3x average.
- [ ] **Caching:** cache-aside (write DB → delete cache). Redis: 100K QPS. DB: 100-200 QPS.
- [ ] **Database:** SQL for ACID + joins. NoSQL for scale + flexible schema. Shard by high-cardinality key.
- [ ] **Message queue:** Kafka for high throughput + replay. SQS for simplicity.
- [ ] **Consistency:** strong (payments) vs eventual (feeds). Cache-aside has brief inconsistency window.

## System Design Key Patterns (3 minutes)

- [ ] **Fan-out:** push for normal users, pull for celebrities (hybrid)
- [ ] **Idempotency:** idempotency key + DB unique constraint. Prevent double charges.
- [ ] **Rate limiting:** token bucket (allows bursts). Sliding window counter (accurate).
- [ ] **Circuit breaker:** CLOSED → OPEN (on failures) → HALF-OPEN (test) → CLOSED
- [ ] **CDC:** DB transaction log → Debezium → Kafka → update cache/search. Reliable sync.
- [ ] **Saga:** distributed transaction as sequence of local transactions + compensating actions

## Java Internals (3 minutes)

- [ ] **HashMap:** default capacity 16, load factor 0.75, treeify at 8. `hashCode ^ (hashCode >>> 16)`.
- [ ] **ConcurrentHashMap:** per-bucket CAS (Java 8+). No null keys/values.
- [ ] **synchronized:** mutual exclusion + visibility. **volatile:** visibility only, NOT atomic.
- [ ] **CompletableFuture:** thenApply (map), thenCompose (flatMap), allOf (wait all), exceptionally (catch)
- [ ] **GC:** Young Gen (minor, fast) + Old Gen (major, slow). G1 default since Java 9. ZGC for < 10ms pauses.
- [ ] **Memory leaks:** static collections, unclosed resources, ThreadLocal not removed, inner class refs

## Distributed Systems (2 minutes)

- [ ] **CAP:** during partition, choose Consistency (CP) or Availability (AP). Real choice is C vs A.
- [ ] **Raft:** leader election, log replication, majority commit. Used in etcd, CockroachDB.
- [ ] **Saga vs 2PC:** saga for microservices (compensating transactions). 2PC for single-datacenter atomicity.
- [ ] **Vector clocks:** detect concurrency. Lamport clocks: causal order only.

## LLD (2 minutes)

- [ ] **SOLID:** SRP (one reason to change), OCP (extend not modify), LSP (subtypes substitutable), ISP (small interfaces), DIP (depend on abstractions)
- [ ] **Patterns:** Strategy (varying algorithms), Factory (creation), Observer (notifications), State (lifecycle), Builder (complex objects)
- [ ] **Framework:** requirements → entities → class diagram → patterns → concurrency

## Behavioral (2 minutes)

- [ ] **STAR:** Situation (2-3 sentences) → Task (your responsibility) → Action (what YOU did, use "I") → Result (quantified)
- [ ] **Keep to 2-3 minutes.** Practice with a timer.
- [ ] **Amazon:** one story per LP. Focus on Ownership, Dive Deep, Have Backbone, Deliver Results.
- [ ] **Bar Raiser:** goes 3-5 levels deep. Prepare "what would you do differently?" for every story.
- [ ] **No-hire signals:** using "we" not "I", no metrics, blaming others, can't go deeper when probed.
- [ ] **"Tell me about yourself":** Present → Past → Future. End with "why this company." Under 2 minutes.

## Tech Stack Quick Recall (2 minutes)

- [ ] **Spring Boot:** @Transactional uses AOP proxy. Self-invocation bypasses proxy. Constructor injection preferred.
- [ ] **Spring Security:** SecurityFilterChain → JWT filter → authorization → controller.
- [ ] **HikariCP:** pool size ≈ 10-20. Too small = connection timeout. Too large = DB overwhelmed.
- [ ] **Kafka:** per-partition ordering. acks=all for durability. Exactly-once = idempotent producer + transactions + read_committed.
- [ ] **Redis:** single-threaded, 100K ops/sec. SET NX EX for locks. Cluster = 16384 hash slots.
- [ ] **SQL:** EXPLAIN for query analysis. FOR UPDATE SKIP LOCKED for concurrent workers. Deadlock prevention = lock in same order.

## Additional SD Patterns (1 minute)

- [ ] **CQRS:** separate read/write models. Sync via CDC/Kafka. Eventually consistent.
- [ ] **Bloom filter:** "definitely no" or "probably yes". Used in caches, crawlers, LSM-tree DBs.
- [ ] **CDN:** pull (on-demand) vs push (proactive). Versioned URLs for invalidation.
- [ ] **Consistent hashing:** only K/N keys remap on server change. Virtual nodes for even distribution.
- [ ] **Task scheduler:** poll with FOR UPDATE SKIP LOCKED. Priority queues. Idempotent handlers.
- [ ] **Ticket booking:** Redis SET NX EX for seat locks. Hold timeout via TTL. Atomic multi-seat with Lua.

## Numbers to Remember

```
Latency:     RAM = 100ns. SSD = 150μs. HDD = 10ms. Same DC = 0.5ms. Cross-region = 40-150ms.
Throughput:  Redis = 100K QPS. PostgreSQL = 100-200 QPS. Kafka = 1M msg/sec.
Storage:     1 char = 1 byte. 1M users × 1KB = 1GB. 1B rows × 1KB = 1TB.
Time:        86400 sec/day. 2.6M sec/month. 1M req/day ≈ 12 QPS.
Availability: 99.9% = 8.7 hr/year. 99.99% = 52 min/year. 99.999% = 5 min/year.
```
