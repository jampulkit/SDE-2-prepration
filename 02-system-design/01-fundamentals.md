# System Design — Fundamentals

## 1. Prerequisites
- [00-prerequisites.md](./00-prerequisites.md) — latency numbers, caching, load balancing, consistent hashing
- This document covers the interview framework and core scaling patterns used in every system design problem

## 2. Core Concepts

### The System Design Interview Framework [🔥 Must Know]

**The system design interview is a structured conversation, not a coding exercise. You drive the discussion through 5 phases, making trade-off decisions at each step and justifying them.**

Every system design interview follows this structure. Spend your 45 minutes roughly as:

| Phase | Time | What to Do | What Interviewer Evaluates |
|-------|------|-----------|---------------------------|
| 1. Requirements | 5 min | Clarify functional + non-functional requirements | Can you scope a problem? Do you ask the right questions? |
| 2. Estimation | 5 min | Back-of-envelope: QPS, storage, bandwidth | Can you reason about scale? |
| 3. High-Level Design | 10 min | API, data model, architecture diagram | Can you design a working system? |
| 4. Deep Dive | 20 min | Scaling, bottlenecks, trade-offs | Can you handle complexity? Do you know trade-offs? |
| 5. Wrap-up | 5 min | Monitoring, failure handling, extensions | Do you think about production concerns? |

💡 **Intuition — Why This Framework Matters:** Interviewers have seen thousands of candidates. The ones who fail usually skip requirements (design the wrong thing), skip estimation (over/under-engineer), or can't go deep (surface-level knowledge). This framework ensures you hit all the points they're evaluating.

**Sample opening dialogue:**

```
Interviewer: "Design a URL shortener."

You: "Before I start, let me clarify the requirements.
     Functional: users can create short URLs, redirect to original URL,
     optionally set custom aliases and expiration.
     Non-functional: how many URLs per day? I'll assume 100M new URLs/day,
     10:1 read:write ratio, so 1B redirects/day. Latency for redirect
     should be < 100ms. Availability: 99.99%. Data retention: 5 years.
     Does that sound right?"

Interviewer: "Yes, that's good. Go ahead."
```

This shows you can scope a problem, think about scale, and drive the conversation.

### Phase 1: Requirements Gathering

**Functional requirements:** What does the system do? (Features, user actions, core use cases)
**Non-functional requirements:** How well does it do it? (Scale, latency, availability, consistency)

**Questions to always ask** [🔥 Must Know]:

| Category | Questions |
|----------|----------|
| Scale | How many users? DAU? How many requests/day? |
| Read/Write ratio | Read-heavy or write-heavy? What's the ratio? |
| Latency | What latency is acceptable? (p99 < 200ms?) |
| Availability | What availability target? (99.9%? 99.99%?) |
| Consistency | Strong consistency needed? Or eventual is OK? |
| Data | How much data per record? How long to retain? |
| Geography | Single region or global? Where are users? |
| Features | What's in scope? What's explicitly out of scope? |

💡 **Intuition — Why Requirements Matter So Much:** "Design Twitter" is a completely different problem depending on whether you're designing for 1K users or 1B users. At 1K users, a single server with PostgreSQL works fine. At 1B users, you need sharding, caching, CDN, message queues, and a fan-out strategy. The requirements determine the architecture.

🎯 **Likely Follow-ups:**
- **Q:** What if the interviewer says "just assume reasonable numbers"?
  **A:** State your assumptions explicitly: "I'll assume 100M DAU, 10:1 read:write ratio, 99.9% availability, eventual consistency is OK for feeds but strong consistency for payments." This shows you can think about scale even without guidance.

### Phase 2: Back-of-Envelope Estimation [🔥 Must Know]

**Quick estimation gives you the numbers that drive architectural decisions — whether you need caching, sharding, CDN, or message queues.**

(Detailed in [05-estimation-math.md](05-estimation-math.md))

**Key numbers to memorize:**

| Metric | Value | How to Remember |
|--------|-------|-----------------|
| Seconds in a day | 86,400 ≈ 10⁵ | ~100K seconds |
| Seconds in a month | 2.6M ≈ 2.5 × 10⁶ | ~2.5M seconds |
| 1M requests/day | ~12 QPS | 10⁶ / 10⁵ = 10 |
| 100M requests/day | ~1,200 QPS | 10⁸ / 10⁵ = 1,000 |
| 1B requests/day | ~12,000 QPS | 10⁹ / 10⁵ = 10,000 |
| Average tweet/message | ~200 bytes | Short text |
| Average image | ~200 KB | Compressed JPEG |
| Average video (1 min) | ~5 MB | Compressed |
| 1 TB | 10¹² bytes | 1 million MB |

**QPS estimation formula:**
```
Average QPS = DAU × actions_per_user_per_day / 86,400
Peak QPS ≈ 2-3 × average QPS

Example: Twitter-like system
  DAU = 300M, each user reads 100 tweets/day, writes 1 tweet/day
  Read QPS = 300M × 100 / 86,400 ≈ 350,000 QPS
  Write QPS = 300M × 1 / 86,400 ≈ 3,500 QPS
  Peak read QPS ≈ 700,000 QPS → need heavy caching
```

**Storage estimation:**
```
Storage = DAU × actions_per_day × data_per_action × retention_days

Example: URL shortener, 5-year retention
  100M new URLs/day × 200 bytes/URL × 365 × 5 = 36.5 TB
  → fits on a few database servers, but need sharding for QPS
```

⚙️ **Under the Hood — How Estimation Drives Architecture:**

| Estimated Metric | Architectural Decision |
|-----------------|----------------------|
| QPS < 1,000 | Single server, simple DB |
| QPS 1K-10K | Load balancer + multiple app servers + caching |
| QPS 10K-100K | Sharded DB + distributed cache + CDN |
| QPS > 100K | All of the above + message queues + async processing |
| Storage < 1 TB | Single DB server |
| Storage 1-10 TB | Read replicas + archival |
| Storage > 10 TB | Sharding required |

### Phase 3: High-Level Design

**API Design:**
- Define key endpoints (REST or gRPC)
- Request/response format with field types
- Authentication method (API key, OAuth, JWT)
- Pagination strategy (cursor-based preferred over offset)

**Data Model:**
- Identify entities and relationships
- Choose SQL vs NoSQL (justify based on access patterns)
- Define schemas/tables with data types
- Identify access patterns (how data is queried — this drives index design)

**Architecture — The Standard Template:**

```
                    ┌─────────┐
                    │   CDN   │ (static assets, images)
                    └────┬────┘
                         │
┌────────┐    ┌──────────┴──────────┐    ┌───────────┐
│ Client │───→│   Load Balancer     │───→│ Web Server│──┐
└────────┘    │   (L7 / Nginx)      │    └───────────┘  │
              └─────────────────────┘                    │
                                                         │
              ┌──────────┐    ┌──────────┐    ┌─────────┴──┐
              │  Cache    │←──│ App Server│←──│ App Server  │
              │ (Redis)   │   └─────┬────┘   └──────┬──────┘
              └──────────┘         │                │
                            ┌──────┴────┐    ┌─────┴──────┐
                            │ Database  │    │ Message    │
                            │ (Primary) │    │ Queue      │
                            └─────┬─────┘    │ (Kafka)    │
                                  │          └─────┬──────┘
                            ┌─────┴─────┐         │
                            │ Database  │    ┌─────┴──────┐
                            │ (Replica) │    │  Workers   │
                            └───────────┘    └────────────┘
```

💡 **Intuition — Draw This Template First:** In every system design interview, start by drawing this basic architecture. Then customize it for the specific problem. This gives you a foundation to build on and shows the interviewer you know the standard components.

### Phase 4: Deep Dive — Scaling Patterns

#### Database Scaling [🔥 Must Know]

**Read replicas:**
- Primary handles ALL writes, replicas handle reads
- Asynchronous replication → eventual consistency (replica may be milliseconds behind)
- Use for read-heavy workloads (typical: 10:1 read:write ratio)
- Scaling: add more replicas for more read throughput

```
Write path:  Client → Primary DB (single writer)
Read path:   Client → Any Replica (multiple readers)

Primary ──async replication──→ Replica 1
                           ──→ Replica 2
                           ──→ Replica 3

Replication lag: typically 10-100ms. During this window,
reads from replicas may return stale data.
```

💥 **What Can Go Wrong — Replication Lag:**
User writes a post, then immediately reads their feed → the post might not appear yet (read hits a replica that hasn't received the write). Solutions:
- Read-after-write consistency: route the user's own reads to the primary for a short window after writes
- Monotonic reads: always route a user to the same replica (sticky sessions)

**Sharding (horizontal partitioning)** [🔥 Must Know]:

**Split data across multiple databases by a shard key. Each shard holds a subset of data.**

💡 **Intuition:** Imagine a library that's too big for one building. You split it into 4 buildings: A-F in building 1, G-L in building 2, etc. Each building (shard) is independent. To find a book, you first determine which building it's in (shard routing), then search within that building.

**Shard key strategies:**

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| Hash-based | `hash(user_id) % N` | Even distribution | Range queries across shards impossible |
| Range-based | Users A-M → shard 1, N-Z → shard 2 | Range queries efficient | Uneven distribution (hotspots) |
| Geographic | US → shard 1, EU → shard 2 | Data locality, compliance | Uneven load |
| Directory-based | Lookup table maps key → shard | Flexible, can rebalance | Lookup table is SPOF, extra hop |

⚙️ **Under the Hood — Choosing a Shard Key:**
The shard key determines EVERYTHING about your sharding strategy. A good shard key:
1. Distributes data evenly (no hotspots)
2. Distributes queries evenly (no hot shards)
3. Keeps related data together (queries don't span shards)
4. Is immutable (changing shard key = moving data between shards)

Example: For a social media app, `user_id` is a good shard key — each user's data lives on one shard, and users are roughly evenly distributed. But `country` is a bad shard key — the US shard would be 10x larger than others.

**Sharding challenges:**
- Joins across shards are expensive/impossible → denormalize
- Resharding when data grows → consistent hashing helps
- Hotspots (celebrity problem — one shard gets disproportionate traffic) → split hot shards, cache hot data
- Distributed transactions are complex → use saga pattern or avoid cross-shard transactions
- Auto-increment IDs don't work across shards → use UUIDs or distributed ID generators (Snowflake)

🎯 **Likely Follow-ups:**
- **Q:** How do you handle resharding?
  **A:** Use consistent hashing so adding a shard only moves ~1/N of the data. Or use a directory-based approach where you can remap keys to new shards. Some databases (Vitess, CockroachDB) handle resharding automatically.
- **Q:** What about cross-shard queries?
  **A:** Scatter-gather: send the query to all shards, collect results, merge. This is expensive (latency = slowest shard). Design your shard key to minimize cross-shard queries. For analytics, use a separate denormalized data warehouse.
- **Q:** How does Instagram handle the celebrity problem?
  **A:** Hot accounts are cached aggressively. Fan-out on read (pull model) instead of fan-out on write (push model) for celebrities with millions of followers.

> 🔗 **See Also:** [03-distributed-systems/04-partitioning-replication.md](../03-distributed-systems/04-partitioning-replication.md) for deep dive on partitioning strategies. [02-system-design/02-database-choices.md](02-database-choices.md) for SQL vs NoSQL selection.

#### Asynchronous Processing [🔥 Must Know]

**Decouple time-consuming operations from the request path using message queues — the user gets an immediate response while the heavy work happens in the background.**

**Message queues** (Kafka, SQS, RabbitMQ):
- Decouple producers from consumers (producer doesn't wait for consumer)
- Buffer traffic spikes (queue absorbs bursts, workers process at steady rate)
- Enable retry and dead-letter queues (failed messages aren't lost)
- Guarantee at-least-once or exactly-once delivery (depending on configuration)

```
Synchronous (slow, fragile):
  User → API → Send Email (3s) → Process Image (5s) → Response (8s total)

Asynchronous (fast, resilient):
  User → API → Queue(email) → Queue(image) → Response (50ms)
                    ↓                ↓
              Email Worker      Image Worker
              (processes         (processes
               in background)    in background)
```

💡 **Intuition — The Restaurant Analogy:** In a synchronous restaurant, the waiter takes your order, goes to the kitchen, waits for the food, and brings it back before taking the next order. In an async restaurant, the waiter takes your order, puts it on a ticket board (queue), and immediately takes the next order. The kitchen (workers) processes tickets independently.

**When to use async:**
- Sending emails/notifications (user doesn't need to wait)
- Image/video processing (resize, transcode, thumbnail generation)
- Analytics event ingestion (log events, process later)
- Any operation that doesn't need an immediate response
- Cross-service communication in microservices

**When NOT to use async:**
- User needs immediate confirmation (payment processing — though even this can be partially async)
- Simple CRUD operations that are already fast
- When ordering guarantees are critical and hard to maintain

💥 **What Can Go Wrong — Message Queue Failure Modes:**

| Problem | What Happens | Solution |
|---------|-------------|----------|
| Consumer crashes mid-processing | Message lost or reprocessed | At-least-once delivery + idempotent consumers |
| Queue fills up (backpressure) | Producers blocked or messages dropped | Auto-scaling consumers, dead-letter queue, backpressure signals |
| Poison message | One bad message crashes consumer repeatedly | Dead-letter queue after N retries, alerting |
| Out-of-order processing | Messages processed in wrong order | Partition by key (Kafka), sequence numbers |

> 🔗 **See Also:** [06-tech-stack/01-kafka-deep-dive.md](../06-tech-stack/01-kafka-deep-dive.md) for Kafka internals. [02-system-design/03-message-queues-event-driven.md](03-message-queues-event-driven.md) for event-driven architecture patterns.

#### Rate Limiting [🔥 Must Know]

**Protect your system from abuse and overload by limiting how many requests a client can make in a given time window.**

**Why:** Prevent abuse (DDoS, scraping), protect resources (DB, downstream services), ensure fair usage (one user can't starve others), cost control (API billing).

**Algorithms:**

| Algorithm | How It Works | Allows Bursts? | Accuracy | Memory |
|-----------|-------------|---------------|----------|--------|
| Token Bucket | Tokens added at fixed rate, consumed per request | Yes (up to bucket size) | Good | O(1) per user |
| Leaky Bucket | Requests processed at fixed rate, excess queued/dropped | No (smooth output) | Good | O(1) per user |
| Fixed Window | Count requests in fixed time windows (e.g., per minute) | Yes (2x burst at boundary) | Approximate | O(1) per user |
| Sliding Window Log | Track timestamp of each request in a sorted set | No | Exact | O(n) per user |
| Sliding Window Counter | Weighted count: `prev_window × overlap% + curr_window` | Minimal | Good approximation | O(1) per user |

💡 **Intuition — Token Bucket (Most Common):**
Imagine a bucket that holds 10 tokens. Every second, 1 token is added (up to max 10). Each request costs 1 token. If the bucket is empty, the request is rejected. This allows short bursts (up to 10 requests at once) while maintaining a long-term average rate of 1 req/sec.

```
Token Bucket state over time:
  t=0:  tokens=10 (full bucket)
  t=0:  5 requests → tokens=5 (burst allowed)
  t=1:  +1 token → tokens=6
  t=1:  2 requests → tokens=4
  t=2:  +1 token → tokens=5
  ...
  If tokens=0 and request arrives → REJECT (429 Too Many Requests)
```

⚙️ **Under the Hood — Fixed Window Boundary Problem:**

```
Window: 1 minute, limit: 100 requests

Minute 1: [.............|100 requests at 0:59]
Minute 2: [100 requests at 1:00|.............]

At the boundary (0:59 to 1:00), the user sends 200 requests in 2 seconds!
The fixed window sees 100 in each window → both pass.

Sliding window counter fixes this by weighting:
  At 1:00:15 (15 seconds into minute 2):
  count = (prev_window_count × 0.75) + curr_window_count
        = (100 × 0.75) + 100 = 175 > 100 → REJECT
```

> 🔗 **See Also:** [02-system-design/problems/rate-limiter.md](problems/rate-limiter.md) for full rate limiter system design.

#### Idempotency [🔥 Must Know]

**An idempotent operation produces the same result no matter how many times it's executed. In distributed systems where retries are inevitable, idempotency prevents duplicate side effects.**

💡 **Intuition — The Elevator Button:** Pressing the elevator button once calls the elevator. Pressing it 10 more times doesn't call 10 more elevators. The operation is idempotent — the result is the same regardless of how many times you perform it.

**Why it matters:** Network failures, timeouts, and retries are facts of life in distributed systems. Without idempotency:
- Payment retry → double charge
- Order submission retry → duplicate order
- Email send retry → user gets 5 copies

**How to implement:**
- **Idempotency key:** Client sends a unique key (UUID) with each request. Server checks: "Have I seen this key before?" If yes, return the cached result. If no, process and store the result.
- **Database constraints:** Unique constraints prevent duplicate inserts (`INSERT ... ON CONFLICT DO NOTHING`).
- **State machine:** Only allow valid state transitions (order can only go PENDING → PAID once; a second PENDING → PAID attempt is rejected).

```java
// Idempotency key implementation (simplified)
public PaymentResult processPayment(String idempotencyKey, PaymentRequest request) {
    // Check if already processed
    PaymentResult cached = redis.get("idempotency:" + idempotencyKey);
    if (cached != null) return cached; // return same result — idempotent!

    // Process payment
    PaymentResult result = paymentGateway.charge(request);

    // Cache result with TTL (e.g., 24 hours)
    redis.setex("idempotency:" + idempotencyKey, 86400, result);
    return result;
}
```

⚠️ **Common Pitfall — Race Condition:** Two identical requests arrive simultaneously. Both check Redis, both find no cached result, both process the payment → double charge. Solution: use a distributed lock (Redis `SETNX`) or database unique constraint on the idempotency key.

> 🔗 **See Also:** [02-system-design/problems/payment-system.md](problems/payment-system.md) for idempotency in payment system design. [03-distributed-systems/03-distributed-transactions.md](../03-distributed-systems/03-distributed-transactions.md) for exactly-once semantics.

### Phase 5: Monitoring & Observability

**Three pillars of observability:**
1. **Metrics:** Quantitative measurements — QPS, latency (p50, p95, p99), error rate, CPU/memory usage, cache hit rate
2. **Logging:** Structured logs with request IDs for debugging — what happened and why
3. **Tracing:** Distributed tracing (Jaeger, Zipkin, AWS X-Ray) — follow a single request across multiple services

⚙️ **Under the Hood — p50, p95, p99 Latency:**

```
If you have 100 requests sorted by latency:
  p50 (median): 50th request's latency — "typical" experience
  p95: 95th request's latency — "most users" experience
  p99: 99th request's latency — "worst case for 1 in 100 users"

Example:
  p50 = 50ms (half of requests are faster than this)
  p95 = 200ms (95% of requests are faster than this)
  p99 = 1000ms (1% of requests take over 1 second)

Why p99 matters: at 1M requests/day, p99 = 10,000 users having a bad experience.
Amazon found that every 100ms of latency costs 1% in sales.
```

**Alerting:** Set thresholds on key metrics. Alert on anomalies (sudden spike in error rate), not just absolute thresholds (CPU > 80%). Use SLIs (Service Level Indicators) tied to SLOs (Service Level Objectives).

**What to mention in interviews:** "I'd monitor QPS, p99 latency, error rate, and cache hit ratio. I'd set up alerts for error rate > 1% and p99 > 500ms. I'd use distributed tracing to debug slow requests across services."

## 3. Comparison Tables

### SQL vs NoSQL Decision Framework

| Factor | Choose SQL | Choose NoSQL |
|--------|-----------|-------------|
| Data structure | Well-defined, relational | Flexible, evolving schema |
| Consistency | Strong consistency needed (payments, inventory) | Eventual consistency OK (feeds, analytics) |
| Queries | Complex joins, aggregations, ad-hoc queries | Simple key-value or document lookups |
| Scale | Moderate (vertical + read replicas) | Massive (horizontal sharding built-in) |
| Transactions | Multi-row ACID transactions | Single-document atomicity (usually) |
| Examples | User accounts, financial data, orders | Session data, product catalogs, logs, time-series |

### When to Use Each Scaling Pattern

| Pattern | When to Use | Impact |
|---------|------------|--------|
| Caching (Redis) | Read-heavy, repeated queries | 10-100x latency reduction |
| Read replicas | Read:write > 5:1 | Linear read scaling |
| Sharding | Single DB can't handle write QPS or data size | Horizontal write scaling |
| CDN | Static content, global users | Latency from 100ms to 10ms |
| Message queue | Async processing, decoupling | Absorb traffic spikes, improve response time |
| Rate limiting | Protect from abuse/overload | Prevent cascading failures |

## 4. How This Shows Up in Interviews

**What SDE-2 candidates are expected to know:**
- Drive the interview — don't wait for the interviewer to guide you through each phase
- Make trade-off decisions and justify them with reasoning (not just "I'd use Redis")
- Estimate scale and design accordingly (don't over-engineer for 1K users, don't under-engineer for 1B)
- Identify bottlenecks and propose solutions proactively
- Discuss failure scenarios and recovery without being asked

**Red flags in weak answers:**
- Jumping to solution without gathering requirements
- Not estimating scale ("I'd use a database" — which one? how many? why?)
- Single point of failure in design (no redundancy)
- No caching strategy for a read-heavy system
- Can't explain why you chose SQL vs NoSQL
- No discussion of failure handling ("what if the cache goes down?")
- Over-engineering for small scale ("we need Kafka for 100 users/day")

**Strong answer signals:**
- Starts with requirements and estimation before drawing anything
- Makes explicit trade-offs: "I'm choosing eventual consistency here because strong consistency would require distributed transactions, which add latency and complexity. For a news feed, stale data for a few seconds is acceptable."
- Identifies bottlenecks: "At 100K QPS, the database is the bottleneck. I'll add a Redis cache with cache-aside strategy to handle 90% of reads."
- Considers failure: "If Redis goes down, we fall back to the database. I'll add a circuit breaker to prevent cascading failures."

## 5. Deep Dive Questions

1. [🔥 Must Know] **Walk me through how you'd design a system from scratch.** — Use the 5-phase framework.
2. [🔥 Must Know] **How do you decide between SQL and NoSQL?** — Access patterns, consistency needs, scale.
3. [🔥 Must Know] **Explain database sharding.** — Strategies, shard key selection, challenges, resharding.
4. [🔥 Must Know] **What is idempotency and why is it important?** — Retries, idempotency keys, state machines.
5. [🔥 Must Know] **How would you handle a thundering herd on your cache?** — Lock on miss, staggered TTL, pre-warming.
6. **What is the difference between horizontal and vertical partitioning?** — Rows vs columns, when to use each.
7. [🔥 Must Know] **Explain rate limiting algorithms.** — Token bucket vs sliding window, trade-offs.
8. **How do read replicas work? What consistency guarantees do they provide?** — Async replication, replication lag, read-after-write consistency.
9. [🔥 Must Know] **When would you use a message queue?** — Async processing, decoupling, buffering, examples.
10. **What is denormalization? When is it appropriate?** — Duplicate data to avoid joins, trade storage for read performance.
11. **How do you monitor a distributed system?** — Metrics, logging, tracing, alerting, SLIs/SLOs.
12. [🔥 Must Know] **What is the difference between p50, p95, and p99 latency?** — Percentiles, why p99 matters, tail latency.
13. **How do you handle database migrations with zero downtime?** — Dual-write, expand-contract, feature flags.
14. **What is a circuit breaker pattern?** — Prevent cascading failures, states (closed/open/half-open).
15. [🔥 Must Know] **How do you ensure exactly-once processing?** — Idempotency + at-least-once delivery, deduplication.
16. **What is backpressure and how do you handle it?** — Producer faster than consumer, queue overflow, flow control.
17. **Explain synchronous vs asynchronous communication.** — When to use each, trade-offs.
18. **How do you handle hotspots in a sharded database?** — Cache hot keys, split hot shards, fan-out on read.
19. **What is a dead-letter queue?** — Failed messages after N retries, manual inspection, alerting.
20. [🔥 Must Know] **How do you design for failure? What is graceful degradation?** — Circuit breakers, fallbacks, feature flags, bulkheads.

## 6. Revision Checklist

**Interview framework:**
- [ ] Requirements (5 min) → Estimation (5 min) → High-Level Design (10 min) → Deep Dive (20 min) → Wrap-up (5 min)
- [ ] Always ask: scale, read/write ratio, latency, availability, consistency, data retention, geography

**Scaling patterns:**
- [ ] Read replicas: primary writes, replicas read. Async replication → eventual consistency.
- [ ] Sharding: split data by shard key. Hash-based (even) vs range-based (range queries). Challenges: joins, resharding, hotspots.
- [ ] Caching: cache-aside most common. Redis handles ~100K QPS. DB handles ~100-200 QPS.
- [ ] Message queues: decouple, buffer, retry. Kafka for high throughput, SQS for simplicity.
- [ ] CDN: static content close to users. Push (proactive) vs pull (reactive).
- [ ] Rate limiting: token bucket (allows bursts), sliding window counter (accurate).

**Database:**
- [ ] SQL: ACID, joins, strong consistency. Scale: vertical + read replicas.
- [ ] NoSQL: flexible schema, horizontal scaling, eventual consistency.
- [ ] Shard key: even distribution, even queries, related data together, immutable.

**Key concepts:**
- [ ] Idempotency: same result on retry. Implement with idempotency key + Redis/DB unique constraint.
- [ ] Denormalization: duplicate data to avoid joins. Trade storage for read performance.
- [ ] Circuit breaker: stop calling failing service, fail fast, recover gradually (closed → open → half-open).
- [ ] Backpressure: producer faster than consumer. Solutions: queue, rate limit producer, auto-scale consumer.

**Estimation shortcuts:**
- [ ] 1M requests/day ≈ 12 QPS. 100M/day ≈ 1,200 QPS. 1B/day ≈ 12,000 QPS.
- [ ] Peak ≈ 2-3× average.
- [ ] 86,400 seconds/day ≈ 10⁵.
- [ ] One DB server: ~100-200 QPS. One Redis server: ~100K QPS.

**Monitoring:**
- [ ] Three pillars: metrics (QPS, latency, errors), logging (structured, request IDs), tracing (distributed, cross-service).
- [ ] Latency percentiles: p50 (typical), p95 (most users), p99 (tail — 1% worst case).

---

## 📋 Suggested New Documents

### 1. Resilience Patterns (Circuit Breaker, Bulkhead, Retry)
- **Placement**: `02-system-design/06-resilience-patterns.md`
- **Why needed**: Circuit breaker, bulkhead, retry with backoff, timeout, and fallback patterns are critical for production systems and frequently asked in SDE-2 interviews. Currently mentioned briefly but not covered in depth.
- **Key subtopics**: Circuit breaker states and implementation, bulkhead pattern (thread pool isolation), retry with exponential backoff and jitter, timeout strategies, graceful degradation, chaos engineering basics

### 2. Data Consistency Patterns
- **Placement**: `02-system-design/06-consistency-patterns.md`
- **Why needed**: Read-after-write consistency, monotonic reads, causal consistency, and eventual consistency patterns are discussed in multiple docs but never consolidated. These are critical for answering "what happens when..." questions.
- **Key subtopics**: Consistency models (strong, eventual, causal), read-after-write consistency implementation, conflict resolution (last-write-wins, CRDTs), dual-write problems, change data capture (CDC)
