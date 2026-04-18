# SDE-2 Interview Preparation Guide
[DSA-TRACKER_SHEET](https://docs.google.com/spreadsheets/d/1wpOP1Ux0MFfnxEJ9CDj9D9hFHHk4o0ICyK0NrrP4yWk/edit?gid=2012553345#gid=2012553345)
End-to-end preparation material for SDE-2 interviews at top product-based companies.

## Target Profile

- 4 years Java backend experience (payments/fintech)
- Targeting: Google, Amazon, Microsoft, Meta, Flipkart, Atlassian

## Repository Structure

| Section | Topics | Count |
|---------|--------|-------|
| [00-revision-checklist](./00-revision-checklist.md) | Day-before-interview rapid review | 1 |
| [01-dsa](./01-dsa/) | Complexity Analysis, Arrays, Trees, Graphs, DP, Advanced Topics | 27 |
| [02-system-design](./02-system-design/) | Concepts (13) + Design Problems (14) | 27 |
| [03-distributed-systems](./03-distributed-systems/) | CAP, Consensus, Transactions, Partitioning, Consistency, Clocks | 6 |
| [04-lld](./04-lld/) | Interview Framework, SOLID, Patterns + 11 Design Problems | 14 |
| [05-java](./05-java/) | Core Java, Collections, Concurrency, JVM, Java 8-21 | 6 |
| [06-tech-stack](./06-tech-stack/) | Kafka, Redis, NoSQL, Spring Boot, Docker/K8s, SQL | 6 |
| [07-cs-fundamentals](./07-cs-fundamentals/) | OS, Networking, DB Internals | 3 |
| [08-behavioral](./08-behavioral/) | STAR, Story Bank, Company-Specific, Intro/Closing | 4 |
| [09-mock-interviews](./09-mock-interviews/) | DSA, System Design, Behavioral Mocks | 3 |

**Total: 97 documents**

## Detailed Table of Contents

### 01 — Data Structures & Algorithms (27 docs)

**Core (12 docs):**

| # | Document | Topics |
|---|----------|--------|
| 00 | [Complexity Analysis](./01-dsa/00-complexity-analysis.md) | Big-O, amortized analysis, space complexity |
| 01 | [Arrays, Strings & Hashing](./01-dsa/01-arrays-strings-hashing.md) | Frequency counting, prefix sum, HashMap internals, grouping |
| 02 | [Two Pointers & Sliding Window](./01-dsa/02-two-pointers-sliding-window.md) | Opposite/same direction, fixed/variable window, monotonic deque |
| 03 | [Stacks & Queues](./01-dsa/03-stacks-queues.md) | Matching brackets, monotonic stack, expression eval, histogram |
| 04 | [Linked Lists](./01-dsa/04-linked-lists.md) | Fast/slow pointers, reversal, merge, cycle detection |
| 05 | [Trees](./01-dsa/05-trees.md) | DFS/BFS, BST, LCA, trie, serialize/deserialize |
| 06 | [Graphs](./01-dsa/06-graphs.md) | BFS, DFS, topological sort, Union-Find, Dijkstra, MST |
| 07 | [Dynamic Programming](./01-dsa/07-dynamic-programming.md) | 1D, knapsack, LCS, LIS, grid, interval, state machine |
| 08 | [Greedy & Backtracking](./01-dsa/08-greedy-backtracking.md) | Intervals, subsets, permutations, N-Queens, word search |
| 09 | [Heap & Priority Queue](./01-dsa/09-heap-priority-queue.md) | Top-K, merge K sorted, two heaps, scheduling |
| 10 | [Bit Manipulation](./01-dsa/10-bit-manipulation.md) | XOR tricks, counting bits, bitmask as set |
| 11 | [Sorting & Searching](./01-dsa/11-sorting-searching.md) | Merge/quick sort, binary search, rotated array, BS on answer |

**Advanced (15 docs):**

| # | Document | Topics |
|---|----------|--------|
| 12 | [String Matching](./01-dsa/12-string-matching.md) | Rabin-Karp, KMP, Z-algorithm |
| 13 | [Interval Problems](./01-dsa/13-interval-problems.md) | Merge, insert, scheduling, weighted job scheduling |
| 14 | [Math Techniques](./01-dsa/14-math-techniques.md) | Boyer-Moore, GCD, modular arithmetic, reservoir sampling, sieve |
| 15 | [Monotonic Stack & Queue](./01-dsa/15-monotonic-stack-queue.md) | Next greater/smaller, contribution technique, histogram |
| 16 | [Advanced Sliding Window](./01-dsa/16-advanced-sliding-window.md) | Prefix sum + monotonic deque, negative numbers |
| 17 | [Advanced Linked List](./01-dsa/17-advanced-linked-list.md) | Skip lists, XOR linked list |
| 18 | [Segment Tree & BIT](./01-dsa/18-segment-tree-bit.md) | Range queries, Fenwick tree, lazy propagation |
| 19 | [Advanced Trees](./01-dsa/19-advanced-trees.md) | Morris traversal, binary lifting, Euler tour |
| 20 | [Advanced Graphs](./01-dsa/20-advanced-graphs.md) | Bellman-Ford, Floyd-Warshall, Tarjan's, 0-1 BFS |
| 21 | [State-Space Search](./01-dsa/21-state-space-search.md) | BFS on implicit graphs, bidirectional BFS |
| 22 | [DP on Trees](./01-dsa/22-dp-on-trees.md) | Rob/not-rob, diameter, max path sum, rerooting |
| 23 | [Bitmask DP](./01-dsa/23-bitmask-dp.md) | TSP, shortest path visiting all nodes |
| 24 | [Sweep Line](./01-dsa/24-sweep-line.md) | Meeting rooms, skyline problem, interval intersection |
| 25 | [Selection Algorithms](./01-dsa/25-selection-algorithms.md) | Quickselect, median of medians |
| 26 | [Advanced Binary Search](./01-dsa/26-advanced-binary-search.md) | Median of two sorted arrays, floating-point BS |

### 02 — System Design (27 docs)

**Concepts (13 docs):**

| # | Document | Topics |
|---|----------|--------|
| 00 | [Prerequisites](./02-system-design/00-prerequisites.md) | Latency numbers, caching, load balancing, consistent hashing |
| 01 | [Fundamentals](./02-system-design/01-fundamentals.md) | Interview framework, sharding, async processing, rate limiting |
| 02 | [Database Choices](./02-system-design/02-database-choices.md) | SQL vs NoSQL, ACID, indexing, storage engines |
| 03 | [Message Queues & Events](./02-system-design/03-message-queues-event-driven.md) | Kafka, SQS, saga pattern, event sourcing, CQRS |
| 04 | [API Design](./02-system-design/04-api-design.md) | REST, gRPC, GraphQL, pagination, JWT, versioning |
| 05 | [Estimation Math](./02-system-design/05-estimation-math.md) | QPS, storage, bandwidth, worked examples |
| 06 | [Observability & Monitoring](./02-system-design/06-observability-monitoring.md) | Metrics, logging, tracing, SLI/SLO/SLA, alerting |
| 07 | [Security Fundamentals](./02-system-design/07-security-fundamentals.md) | OAuth, encryption, OWASP, DDoS protection |
| 08 | [Resilience Patterns](./02-system-design/08-resilience-patterns.md) | Circuit breaker, retry, bulkhead, graceful degradation |
| 09 | [Consistency Patterns](./02-system-design/09-consistency-patterns.md) | Dual-write problem, cache-aside, CDC, read-after-write |
| 10 | [Indexing & Query Optimization](./02-system-design/10-indexing-query-optimization.md) | EXPLAIN, composite indexes, N+1, connection pooling |
| 11 | [API Gateway & Service Mesh](./02-system-design/11-api-gateway-service-mesh.md) | Routing, service discovery, sidecar pattern |
| 12 | [Data Migration Strategies](./02-system-design/12-data-migration-strategies.md) | Zero-downtime migration, dual-write, expand-contract |

**Design Problems (14 docs):**

| # | Document | Key Concepts |
|---|----------|-------------|
| 1 | [URL Shortener](./02-system-design/problems/url-shortener.md) | Base62, key generation, 301 vs 302, analytics pipeline |
| 2 | [Chat System](./02-system-design/problems/chat-system.md) | WebSocket, Cassandra, presence, fan-out |
| 3 | [News Feed](./02-system-design/problems/news-feed.md) | Hybrid fan-out, celebrity problem, ranking |
| 4 | [Notification System](./02-system-design/problems/notification-system.md) | Multi-channel, Kafka, rate limiting, DLQ |
| 5 | [Rate Limiter](./02-system-design/problems/rate-limiter.md) | Token bucket, sliding window, Redis + Lua |
| 6 | [Distributed Cache](./02-system-design/problems/distributed-cache.md) | Consistent hashing, LRU, replication, stampede |
| 7 | [Search Autocomplete](./02-system-design/problems/search-autocomplete.md) | Trie, offline pipeline, debouncing |
| 8 | [Payment System](./02-system-design/problems/payment-system.md) | Idempotency, state machine, double-entry ledger |
| 9 | [File Storage](./02-system-design/problems/file-storage-system.md) | Block-level sync, deduplication, presigned URLs |
| 10 | [Video Streaming](./02-system-design/problems/video-streaming.md) | Adaptive bitrate, transcoding pipeline, CDN |
| 11 | [Distributed ID Generator](./02-system-design/problems/distributed-id-generator.md) | Snowflake, UUID, database sequences |
| 12 | [E-Commerce System](./02-system-design/problems/e-commerce-system.md) | Catalog, cart, checkout, inventory management |
| 13 | [Ride Sharing](./02-system-design/problems/ride-sharing.md) | Location matching, ETA, surge pricing |
| 14 | [Social Media (Instagram)](./02-system-design/problems/social-media-instagram.md) | Feed, stories, explore, media storage |

### 03 — Distributed Systems (6 docs)

| # | Document | Topics |
|---|----------|--------|
| 01 | [CAP Theorem & Consistency](./03-distributed-systems/01-cap-theorem-consistency.md) | CAP, PACELC, consistency models, tunable consistency |
| 02 | [Consensus Algorithms](./03-distributed-systems/02-consensus-algorithms.md) | Raft, Paxos, ZooKeeper, 2PC |
| 03 | [Distributed Transactions](./03-distributed-systems/03-distributed-transactions.md) | Saga, outbox pattern, CDC, idempotent consumers |
| 04 | [Partitioning & Replication](./03-distributed-systems/04-partitioning-replication.md) | Single/multi/leaderless replication, sharding strategies |
| 05 | [Consistency Patterns](./03-distributed-systems/05-consistency-patterns.md) | CDC, CRDTs, causal consistency, dual-write solutions |
| 06 | [Clocks & Ordering](./03-distributed-systems/06-clocks-ordering.md) | Lamport clocks, vector clocks, NTP, TrueTime |

### 04 — Low-Level Design (14 docs)

**Concepts (3 docs):**

| # | Document | Topics |
|---|----------|--------|
| 00 | [LLD Interview Framework](./04-lld/00-lld-interview-framework.md) | How to approach LLD interviews, time management |
| 01 | [SOLID Principles](./04-lld/01-solid-principles.md) | SRP, OCP, LSP, ISP, DIP with Java examples |
| 02 | [Design Patterns](./04-lld/02-design-patterns.md) | Singleton, Factory, Builder, Strategy, Observer, Decorator, State |

**LLD Problems (11 docs):**

| # | Problem | Key Patterns |
|---|---------|-------------|
| 1 | [Parking Lot](./04-lld/problems/parking-lot.md) | Strategy (pricing), Factory, vehicle hierarchy |
| 2 | [Elevator System](./04-lld/problems/elevator-system.md) | State, Strategy (scheduling), Observer |
| 3 | [BookMyShow](./04-lld/problems/bookmyshow.md) | State (seat lifecycle), concurrent booking |
| 4 | [Chess Game](./04-lld/problems/chess-game.md) | Strategy (move validation), Command (undo) |
| 5 | [Splitwise](./04-lld/problems/splitwise.md) | Strategy (split types), debt simplification |
| 6 | [Library Management](./04-lld/problems/library-management.md) | State (book lifecycle), fine calculation |
| 7 | [Snake & Ladder](./04-lld/problems/snake-and-ladder.md) | Game loop, configurable board |
| 8 | [LRU/LFU Cache](./04-lld/problems/cache-lru-lfu.md) | HashMap + doubly-linked list, O(1) operations |
| 9 | [Stack/Queue Designs](./04-lld/problems/stack-queue-designs.md) | Browser history, undo/redo, task scheduler |
| 10 | [Food Delivery](./04-lld/problems/food-delivery.md) | Order lifecycle, delivery assignment, tracking |
| 11 | [Rate Limiter LLD](./04-lld/problems/rate-limiter-lld.md) | Token bucket implementation, OOP design |

### 05 — Java (6 docs)

| # | Document | Topics |
|---|----------|--------|
| 01 | [Core Java](./05-java/01-core-java.md) | OOP, equals/hashCode, immutability, generics, exceptions |
| 02 | [Collections Internals](./05-java/02-collections-internals.md) | HashMap, ConcurrentHashMap, ArrayList, TreeMap, fail-fast |
| 03 | [Concurrency & Multithreading](./05-java/03-concurrency-multithreading.md) | synchronized, volatile, JMM, ExecutorService, CompletableFuture |
| 04 | [JVM Internals & GC](./05-java/04-jvm-internals-gc.md) | Memory areas, GC algorithms (G1, ZGC), class loading |
| 05 | [Java 8 to 21 Features](./05-java/05-java8-to-21-features.md) | Lambdas, streams, Optional, records, sealed classes, virtual threads |
| 06 | [Interview Questions](./05-java/06-java-interview-questions.md) | Rapid-fire Q&A across all Java topics |

### 06 — Tech Stack (6 docs)

| # | Document | Topics |
|---|----------|--------|
| 01 | [Kafka Deep Dive](./06-tech-stack/01-kafka-deep-dive.md) | Architecture, partitions, consumer groups, delivery semantics |
| 02 | [Redis Deep Dive](./06-tech-stack/02-redis-deep-dive.md) | Data structures, persistence, cluster, distributed locks |
| 03 | [NoSQL Databases](./06-tech-stack/03-nosql-databases.md) | DynamoDB, MongoDB, Cassandra, Elasticsearch |
| 04 | [Spring Boot](./06-tech-stack/04-spring-boot.md) | Annotations, DI, REST APIs, JPA, testing |
| 05 | [Docker & Kubernetes](./06-tech-stack/05-docker-kubernetes-basics.md) | Containers, Dockerfile, pods, deployments, services |
| 06 | [SQL Deep Dive](./06-tech-stack/06-sql-deep-dive.md) | Joins, window functions, query optimization, transactions |

### 07 — CS Fundamentals (3 docs)

| # | Document | Topics |
|---|----------|--------|
| 01 | [Operating Systems](./07-cs-fundamentals/01-operating-systems.md) | Processes, threads, scheduling, memory, deadlock |
| 02 | [Networking](./07-cs-fundamentals/02-networking.md) | TCP/UDP, HTTP, DNS, TLS, OSI model |
| 03 | [Database Internals](./07-cs-fundamentals/03-database-internals.md) | B+ tree, LSM tree, WAL, MVCC, query execution |

### 08 — Behavioral (4 docs)

| # | Document | Topics |
|---|----------|--------|
| 01 | [Behavioral Prep](./08-behavioral/01-behavioral-prep.md) | STAR method, top 30 questions, frameworks |
| 02 | [Story Bank](./08-behavioral/02-story-bank.md) | Template for building reusable stories |
| 03 | [Company-Specific](./08-behavioral/03-company-specific.md) | Amazon LPs, Google Googleyness, Microsoft, Flipkart |
| 04 | [Intro & Closing](./08-behavioral/04-intro-and-closing.md) | Self-introduction, questions to ask interviewer |

### 09 — Mock Interviews (3 docs)

| # | Document | Topics |
|---|----------|--------|
| 01 | [DSA Mock](./09-mock-interviews/01-dsa-mock.md) | Timed practice problems, approach scripts |
| 02 | [System Design Mock](./09-mock-interviews/02-system-design-mock.md) | End-to-end mock walkthrough |
| 03 | [Behavioral Mock](./09-mock-interviews/03-behavioral-mock.md) | Practice questions with model answers |

## How to Use

1. **Sequential study**: Follow the numbered order within each section (00-11 are core, 12+ are advanced)
2. **Pattern recognition**: DSA docs focus on recognizing patterns, not memorizing solutions
3. **Revision mode**: Every document ends with a condensed Revision Checklist. Use [00-revision-checklist.md](./00-revision-checklist.md) for a master checklist.
4. **[🔥 Must Know] / [🔥 Must Do]**: Prioritize these items when short on time
5. **Practice**: DSA docs include curated LeetCode lists — solve them independently
6. **Cross-references**: 🔗 See Also links connect related topics across sections
7. **Follow-ups**: 🎯 Likely Follow-ups prepare you for interviewer deep-dive questions
8. **Mock interviews**: Use [09-mock-interviews](./09-mock-interviews/) for timed practice

## Study Plan (Suggested Order)

**Week 1-2: Foundations**
- 01-dsa/00 through 01-dsa/11 (core DSA patterns + complexity analysis)
- 05-java/01 through 05-java/04 (Java fundamentals)

**Week 3-4: System Design**
- 02-system-design/00 through 02-system-design/05 (core concepts)
- 02-system-design/problems (all 14 design problems)
- 03-distributed-systems (all 6 docs)

**Week 5: LLD + Tech Stack**
- 04-lld (framework + SOLID + patterns + all 11 problems)
- 06-tech-stack (Kafka, Redis, SQL, Spring Boot, Docker/K8s)

**Week 6: Advanced + Review**
- 01-dsa/12 through 01-dsa/26 (advanced DSA)
- 02-system-design/06 through 02-system-design/12 (advanced concepts)
- 07-cs-fundamentals + 08-behavioral
- 09-mock-interviews (timed practice)
- 00-revision-checklist (final review)

## Legend

- [🔥 Must Know] — Frequently asked in interviews, must be able to explain clearly
- [🔥 Must Do] — Must solve and internalize before interviews
- 💡 **Intuition** — Mental model to understand the concept before details
- ⚙️ **Under the Hood** — Internal mechanisms interviewers love to probe
- 🎯 **Likely Follow-ups** — Questions interviewers ask to go deeper
- 💥 **What Can Go Wrong** — Failure modes and edge cases
- 🔗 **See Also** — Cross-references to related documents
- ☐ **Edge Cases** — Boundary conditions to check
