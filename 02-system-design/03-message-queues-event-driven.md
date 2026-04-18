# System Design — Message Queues & Event-Driven Architecture

## 1. Prerequisites
- [01-fundamentals.md](./01-fundamentals.md) — async processing, microservices
- [00-prerequisites.md](./00-prerequisites.md) — communication protocols, scalability

## 2. Core Concepts

### Why Message Queues Exist

**A message queue sits between services, decoupling the sender from the receiver — the sender publishes a message and moves on, while the receiver processes it at its own pace.**

**Problem:** In synchronous systems, Service A calls Service B directly. If B is slow or down, A is blocked. If traffic spikes, B gets overwhelmed. If B crashes mid-processing, the request is lost.

**Solution:** Put a queue between them. A publishes messages, B consumes at its own pace.

```
Synchronous (fragile):
  Service A ──HTTP──→ Service B (slow/down) → A is BLOCKED

Asynchronous with queue (resilient):
  Service A ──publish──→ [Message Queue] ──consume──→ Service B
  A returns immediately.                    B processes at its own pace.
  If B is down, messages wait in queue.     When B recovers, it catches up.
```

💡 **Intuition — The Post Office Analogy:** Synchronous communication is like a phone call — both parties must be available at the same time. A message queue is like a post office — you drop off your letter (message) and leave. The recipient picks it up when they're ready. If they're on vacation, the letter waits.

**Benefits:**
- **Decoupling:** A doesn't know/care about B's existence, location, or implementation
- **Buffering:** Absorbs traffic spikes (Black Friday: 10x normal traffic → queue absorbs the burst)
- **Reliability:** Messages persist until processed (survives consumer crashes)
- **Scalability:** Add more consumers to increase throughput (horizontal scaling of processing)
- **Retry:** Failed messages can be retried automatically

### Message Queue vs Event Streaming [🔥 Must Know]

| Feature | Message Queue (SQS, RabbitMQ) | Event Streaming (Kafka) |
|---------|-------------------------------|------------------------|
| Model | Point-to-point (one consumer per message) | Pub-sub (multiple consumer groups) |
| Message retention | Deleted after consumption/ack | Retained for configurable period (days/weeks) |
| Ordering | Best-effort (FIFO with SQS FIFO) | Per-partition ordering guaranteed |
| Replay | No (message gone after ack) | Yes (consumers can rewind to any offset) |
| Throughput | Moderate (thousands/sec) | Very high (millions/sec per cluster) |
| Consumer model | Competing consumers (load balanced) | Consumer groups (each group gets all messages) |
| Use case | Task queues, job processing, one-time actions | Event sourcing, log aggregation, real-time streaming |

💡 **Intuition — Queue vs Stream:**
- **Message Queue** is like a to-do list. Each task is done by one person, then crossed off. Once done, it's gone.
- **Event Stream** is like a newspaper. Everyone can read it. You can go back and re-read yesterday's edition. Multiple people can read the same article independently.

⚙️ **Under the Hood — When to Use Which:**

```
Use Message Queue (SQS/RabbitMQ) when:
  ✅ Each message should be processed by exactly ONE consumer
  ✅ Messages are tasks/commands (send email, process payment)
  ✅ You don't need replay
  ✅ Simple setup is preferred

Use Event Streaming (Kafka) when:
  ✅ Multiple services need to react to the same event
  ✅ You need replay capability (reprocess events after bug fix)
  ✅ You need high throughput (100K+ events/sec)
  ✅ You want event sourcing or audit trail
  ✅ You need per-key ordering (all events for user_123 in order)
```

🎯 **Likely Follow-ups:**
- **Q:** Can Kafka be used as a message queue?
  **A:** Yes — with a single consumer group, Kafka behaves like a message queue (each message consumed by one consumer). But it's overkill for simple task queues. SQS is simpler and cheaper for that use case.
- **Q:** Can SQS guarantee ordering?
  **A:** SQS FIFO queues guarantee ordering within a message group (similar to Kafka partitions). Standard SQS queues provide best-effort ordering only.

### Apache Kafka — Architecture [🔥 Must Know]

**Kafka is a distributed event streaming platform that stores events in ordered, immutable logs (partitions) and allows multiple consumer groups to read independently.**

```
Producers → Topic "orders" ─┬─ Partition 0: [msg0, msg1, msg2, ...]
                             ├─ Partition 1: [msg0, msg1, msg2, ...]
                             └─ Partition 2: [msg0, msg1, msg2, ...]
                                     ↓              ↓              ↓
                             Consumer Group A: [C1 reads P0] [C2 reads P1] [C3 reads P2]
                             Consumer Group B: [C4 reads P0, P1, P2] (single consumer)
```

**Key concepts:**
- **Topic:** Named feed of messages (like a database table for events)
- **Partition:** Ordered, immutable, append-only log within a topic. Unit of parallelism.
- **Offset:** Sequential ID of a message within a partition (0, 1, 2, ...)
- **Producer:** Publishes messages. Chooses partition by key hash or round-robin.
- **Consumer:** Reads messages from partitions. Tracks its own offset.
- **Consumer Group:** Set of consumers that share the work. Each partition assigned to exactly ONE consumer in the group. Different groups read independently.
- **Broker:** A Kafka server. Multiple brokers form a cluster.
- **Replication:** Each partition has a leader (handles reads/writes) and N-1 followers (ISR — In-Sync Replicas). If leader fails, an ISR member is promoted.

⚙️ **Under the Hood — Kafka's Storage Model:**

```
Partition 0 on disk:
  Segment 1: [offset 0-999]   ← old, may be deleted by retention policy
  Segment 2: [offset 1000-1999]
  Segment 3: [offset 2000-2500] ← active segment (being written to)

Each segment has:
  .log file:   actual messages (append-only)
  .index file: offset → file position mapping (for fast lookup)
  .timeindex:  timestamp → offset mapping

Why it's fast:
  - Writes are sequential (append-only) → exploits disk sequential I/O
  - Reads use OS page cache → frequently accessed data served from memory
  - Zero-copy transfer: data goes from disk → network without copying through app memory
```

**Ordering guarantee:** Messages within a partition are strictly ordered. No ordering across partitions. To ensure ordering for a key (e.g., all events for user_123), use the key as the partition key → `hash(user_123) % num_partitions` → always goes to the same partition.

**Delivery semantics** [🔥 Must Know]:

| Semantic | How | Risk | Use Case |
|----------|-----|------|----------|
| At-most-once | Fire and forget (acks=0) | May lose messages | Metrics, logs (loss acceptable) |
| At-least-once | Retry until ack (acks=1 or all) | May duplicate | Most use cases (with idempotent consumer) |
| Exactly-once | Idempotent producer + transactional consumer | Complex, slight overhead | Financial events, inventory |

💡 **Intuition — Why At-Least-Once + Idempotency is the Standard:**
Exactly-once is hard and expensive. At-least-once is simple (just retry on failure). The trick: make your consumer idempotent (processing the same message twice has no additional effect). This gives you effectively-exactly-once semantics with the simplicity of at-least-once delivery.

```
At-least-once + idempotent consumer:
  1. Consumer reads message "charge user $10, idempotency_key=abc123"
  2. Consumer checks: "Have I processed abc123?" → No → process, record abc123
  3. Consumer crashes before committing offset
  4. Consumer restarts, reads same message again
  5. Consumer checks: "Have I processed abc123?" → Yes → skip
  Result: charged exactly once, even though message was delivered twice ✓
```

🎯 **Likely Follow-ups:**
- **Q:** What happens when a Kafka consumer crashes?
  **A:** The partition is reassigned to another consumer in the group (rebalancing). The new consumer starts from the last committed offset. Messages since the last commit are reprocessed (at-least-once). This is why idempotent consumers are important.
- **Q:** How do you scale Kafka consumers?
  **A:** Add more consumers to the consumer group (up to the number of partitions). Each consumer gets a subset of partitions. If consumers > partitions, extra consumers are idle. To increase parallelism beyond current partitions, increase the partition count (but this can't be decreased later).
- **Q:** What's the difference between Kafka's acks=1 and acks=all?
  **A:** `acks=1`: leader acknowledges after writing to its own log (fast, but data lost if leader crashes before replication). `acks=all`: leader waits for all ISR replicas to acknowledge (slower, but no data loss as long as at least one ISR survives).

> 🔗 **See Also:** [06-tech-stack/01-kafka-deep-dive.md](../06-tech-stack/01-kafka-deep-dive.md) for Kafka internals, Java producer/consumer code, and production tuning.

### Event-Driven Architecture Patterns

**Event Notification:** Service publishes an event, other services react independently. The publisher doesn't know or care who's listening.

```
Order Service → publishes "OrderCreated" event
                    ↓                ↓                ↓
            Inventory Service   Notification Service   Analytics Service
            (reserve stock)     (send confirmation)    (track metrics)

Each service has its own consumer group → each gets every event.
Services are completely decoupled — adding a new service requires zero changes to Order Service.
```

💡 **Intuition — Why Event-Driven?** In a synchronous system, the Order Service would need to call Inventory, Notification, and Analytics APIs sequentially (slow, fragile). With events, Order Service publishes once and returns. Each downstream service processes independently. If Analytics is down, orders still work — Analytics catches up when it recovers.

**Event Sourcing** [🔥 Must Know]: Store state as a sequence of events, not current state. Rebuild state by replaying events.

```
Traditional (store current state):
  Account balance = $500 (just the final number)

Event Sourcing (store all events):
  Event 1: AccountCreated(balance=$0)
  Event 2: Deposited($1000)
  Event 3: Withdrawn($300)
  Event 4: Withdrawn($200)
  Current state: replay events → $0 + $1000 - $300 - $200 = $500

Benefits: full audit trail, can rebuild state at any point in time,
          can add new projections (views) by replaying events.
```

| Aspect | Pros | Cons |
|--------|------|------|
| Audit trail | Complete history of every change | Storage grows indefinitely |
| Temporal queries | "What was the balance on Jan 15?" | Must replay events to answer |
| Debugging | Replay events to reproduce bugs | Complex to implement correctly |
| New features | Add new read models by replaying | Eventual consistency between write and read models |
| Schema evolution | Events are immutable, versioned | Must handle old event formats |

**CQRS (Command Query Responsibility Segregation):** Separate read and write models.
- **Write model:** Optimized for writes (normalized, event store)
- **Read model:** Optimized for reads (denormalized, materialized views, search indexes)
- Often combined with event sourcing: events are the write model, projections are the read model

```
CQRS Architecture:

  Write path: Client → Command → Write Model (event store) → Events published
  Read path:  Client → Query → Read Model (materialized view) → Response

  Events → Projection Service → Updates Read Model (async)

  Write model and read model can use DIFFERENT databases:
    Write: PostgreSQL (ACID for events)
    Read: Elasticsearch (fast search), Redis (fast lookups), DynamoDB (scalable reads)
```

**Saga Pattern** [🔥 Must Know]: Manage distributed transactions across microservices without a distributed transaction coordinator.

💡 **Intuition — Why Sagas?** In a monolith, you wrap everything in one database transaction. In microservices, each service has its own database — you can't use a single transaction. A saga breaks the transaction into a sequence of local transactions, each with a compensating action for rollback.

```
Order Saga (Choreography):
  1. Order Service: Create order (PENDING)
  2. → publishes OrderCreated
  3. Payment Service: Charge customer
  4. → publishes PaymentCompleted
  5. Inventory Service: Reserve stock
  6. → publishes StockReserved
  7. Order Service: Update order (CONFIRMED)

If step 5 fails (out of stock):
  5. → publishes StockReservationFailed
  6. Payment Service: REFUND customer (compensating action)
  7. Order Service: Update order (CANCELLED)
```

| Approach | How It Works | Pros | Cons |
|----------|-------------|------|------|
| Choreography | Each service publishes events, next service reacts | Simple, decoupled | Hard to track overall flow, debugging difficult |
| Orchestration | Central orchestrator tells each service what to do | Easy to understand, centralized logic | Orchestrator is a single point of complexity |

**When to use which:** Choreography for simple flows (2-3 services). Orchestration for complex flows (4+ services, conditional logic, timeouts).

### Dead Letter Queue (DLQ)

**Messages that fail processing after N retries go to a DLQ for manual inspection. This prevents poison messages from blocking the queue.**

```
Normal flow:    Queue → Consumer → Success → Ack (message removed)
Failure flow:   Queue → Consumer → Fail → Retry (up to N times)
                                        → After N failures → DLQ
                                        → Alert ops team → Manual inspection
```

💡 **Intuition:** A DLQ is like the "return to sender" pile at a post office. If a letter can't be delivered after several attempts, it goes to a special pile for human review instead of being thrown away or blocking other mail.

### Backpressure

**When consumers can't keep up with producers, the queue grows unboundedly. Backpressure is the mechanism to handle this.**

| Strategy | How | Trade-off |
|----------|-----|-----------|
| Drop messages | Discard oldest or newest | Data loss (OK for metrics, not for orders) |
| Buffer (grow queue) | Queue absorbs the burst | Needs monitoring, may run out of memory/disk |
| Slow down producer | Reject or throttle producer | Producer must handle rejection |
| Scale consumers | Add more consumer instances | Takes time to spin up, cost |

## 3. Comparison Tables

| Technology | Type | Ordering | Throughput | Persistence | Best For |
|-----------|------|----------|-----------|-------------|----------|
| Apache Kafka | Event streaming | Per-partition | Very high (millions/sec) | Yes (configurable retention) | Event sourcing, log aggregation, streaming |
| Amazon SQS | Message queue | Best-effort (FIFO available) | High (thousands/sec) | Yes (14 days max) | Task queues, decoupling, serverless |
| RabbitMQ | Message broker | Per-queue | Moderate | Optional | Complex routing, RPC, priority queues |
| Amazon SNS | Pub-sub notification | No ordering | High | No (fire-and-forget) | Fan-out to SQS/Lambda/HTTP |
| Redis Streams | Lightweight streaming | Per-stream | High | Yes (with persistence) | Simple event streaming, lightweight Kafka alternative |

**Decision framework:**

| Need | Choose | Why |
|------|--------|-----|
| Simple task queue | SQS | Managed, simple, pay-per-use |
| High-throughput event streaming | Kafka | Millions/sec, replay, multi-consumer |
| Complex routing (topic/header-based) | RabbitMQ | Exchange types, routing keys |
| Fan-out to multiple targets | SNS + SQS | SNS fans out, SQS queues per consumer |
| Lightweight streaming | Redis Streams | Already using Redis, simple setup |
| Managed Kafka | Amazon MSK or Confluent | Kafka without operational overhead |

## 4. How This Shows Up in Interviews

**When to propose a message queue:**
- "The user doesn't need to wait for this" → async processing (email, image resize)
- "We need to handle traffic spikes" → buffering (Black Friday, flash sales)
- "Multiple services need to react to this event" → pub-sub (Kafka)
- "We need reliable delivery with retries" → persistent queue with DLQ
- "We need to decouple services" → any message queue

**What to say:**
> "I'll use Kafka here because multiple services need to react to order events independently. The order service publishes an OrderCreated event to a Kafka topic. The inventory, notification, and analytics services each have their own consumer group, so each gets every event. If we need to add a new service later (e.g., fraud detection), we just add a new consumer group — zero changes to the order service."

**Red flags:**
- "I'll use Kafka" without explaining why (not SQS or RabbitMQ)
- Not mentioning delivery guarantees (at-least-once, idempotency)
- Not considering failure scenarios (consumer crash, poison messages, DLQ)
- Using synchronous calls where async would be better

## 5. Deep Dive Questions

1. [🔥 Must Know] **When would you use Kafka vs SQS vs RabbitMQ?** — Throughput, replay, routing, simplicity.
2. [🔥 Must Know] **How does Kafka guarantee ordering?** — Per-partition, same key → same partition.
3. [🔥 Must Know] **Explain at-least-once vs exactly-once delivery.** — Retry semantics, idempotent consumers.
4. **What is a consumer group in Kafka?** — Shared consumption, one partition per consumer.
5. [🔥 Must Know] **What is the Saga pattern?** — Distributed transactions, choreography vs orchestration, compensating actions.
6. **How do you handle poison messages?** — Retry N times, then DLQ, alert, manual review.
7. [🔥 Must Know] **What is event sourcing?** — Store events not state, replay to rebuild, audit trail.
8. **What is CQRS?** — Separate read/write models, different databases, async projection.
9. **How do you handle backpressure?** — Drop, buffer, throttle producer, scale consumers.
10. [🔥 Must Know] **What is a dead letter queue?** — Failed messages after N retries, manual inspection.
11. **How does Kafka replication work?** — Leader + ISR followers, acks=all for durability.
12. **What happens when a Kafka consumer crashes?** — Rebalancing, resume from last committed offset.
13. **How do you ensure exactly-once processing?** — Idempotent producer + transactional consumer, or at-least-once + idempotent consumer.
14. **Message queue vs pub-sub?** — Queue: one consumer per message. Pub-sub: all subscribers get every message.
15. **Design an event-driven payment system.** — Order → Payment → Inventory saga with compensating actions.

## 6. Revision Checklist

**Message queue vs event streaming:**
- [ ] Queue (SQS, RabbitMQ): point-to-point, message deleted after consumption, task processing
- [ ] Stream (Kafka): pub-sub, retained, replayable, per-partition ordering, multiple consumer groups

**Kafka essentials:**
- [ ] Topics → partitions → offsets. Partition = unit of parallelism and ordering.
- [ ] Producer acks: 0 (fire-forget), 1 (leader), all (all ISR — most durable)
- [ ] Consumer groups: one consumer per partition, offset tracking, rebalancing on crash
- [ ] Replication: leader + ISR followers. Leader handles reads/writes.
- [ ] Ordering: per-partition only. Same key → same partition → ordered.
- [ ] Retention: time or size based. Messages NOT deleted on consumption.

**Delivery semantics:**
- [ ] At-most-once: may lose. At-least-once: may duplicate (most common). Exactly-once: complex.
- [ ] Standard pattern: at-least-once delivery + idempotent consumer = effectively exactly-once.

**Event-driven patterns:**
- [ ] Event notification: publish event, multiple services react independently
- [ ] Event sourcing: store events not state, replay to rebuild, full audit trail
- [ ] CQRS: separate read/write models, different databases, async projection
- [ ] Saga: distributed transactions via choreography (events) or orchestration (coordinator)
- [ ] DLQ: failed messages after N retries → manual inspection
- [ ] Backpressure: drop, buffer, throttle, or scale consumers

**Technology selection:**
- [ ] Simple task queue → SQS (managed, simple)
- [ ] High-throughput streaming → Kafka (millions/sec, replay)
- [ ] Complex routing → RabbitMQ (exchanges, routing keys)
- [ ] Fan-out → SNS + SQS (SNS distributes, SQS queues per consumer)

---

## 📋 Suggested New Documents

### 1. Distributed Transactions Deep Dive
- **Placement**: `03-distributed-systems/05-distributed-transactions-patterns.md`
- **Why needed**: Saga pattern, two-phase commit, outbox pattern, and change data capture (CDC) are critical for microservices but only briefly covered here. The existing distributed transactions doc focuses on theory; a patterns-focused doc would complement it.
- **Key subtopics**: Outbox pattern (transactional outbox + CDC), saga orchestration implementation, idempotency patterns, dual-write problem and solutions, eventual consistency patterns
