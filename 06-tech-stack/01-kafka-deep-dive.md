# Apache Kafka — Deep Dive

## 1. What & Why

**Kafka is a distributed event streaming platform that handles millions of events per second with durability, ordering, and replay capability. It's the backbone of event-driven architectures and appears in almost every system design interview.**

Kafka solves: decoupling services, handling traffic spikes, enabling event-driven architecture, and providing a durable log of events.

💡 **Intuition — Kafka as a Distributed Commit Log:** Think of Kafka as a giant, distributed, append-only log file. Producers write events to the end of the log. Consumers read from any position in the log (and can re-read). Multiple consumers can read the same log independently. The log is split into partitions for parallelism and replicated for durability.

**Real-world use cases:** LinkedIn (activity tracking — Kafka was created here), Netflix (real-time analytics), Uber (trip events), payment event processing, log aggregation, change data capture.

> 🔗 **See Also:** [02-system-design/03-message-queues-event-driven.md](../02-system-design/03-message-queues-event-driven.md) for Kafka vs SQS vs RabbitMQ comparison and event-driven patterns. [03-distributed-systems/03-distributed-transactions.md](../03-distributed-systems/03-distributed-transactions.md) for outbox pattern with Kafka.

## 2. Architecture & Internals

**Components:** Producers → Topics (Partitions) → Consumers (Consumer Groups). Brokers form a cluster. ZooKeeper (or KRaft in newer versions) manages metadata.

**Topic & Partitions:** Topic is a named log. Partitions provide parallelism. Each partition is an ordered, immutable sequence of records. Records identified by offset.

**Storage:** Append-only log files on disk. Sequential I/O (fast). Segments with index files. Retention: time-based or size-based.

**Replication:** Each partition has a leader and N-1 followers (ISR — In-Sync Replicas). Leader handles all reads/writes. Followers replicate. If leader fails, ISR member promoted.

**Producer:** Sends records to topic. Partitioning: by key (hash) or round-robin. Acks: 0 (fire-forget), 1 (leader ack), all (all ISR ack).

**Consumer Groups:** Each partition consumed by exactly one consumer in a group. Adding consumers (up to partition count) increases parallelism. Offsets committed to `__consumer_offsets` topic.

## 3. Core Operations (Java)

```java
// Producer
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

KafkaProducer<String, String> producer = new KafkaProducer<>(props);
producer.send(new ProducerRecord<>("my-topic", "key", "value"));
producer.close();

// Consumer
props.put("group.id", "my-group");
props.put("auto.offset.reset", "earliest");
KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
consumer.subscribe(List.of("my-topic"));
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    for (ConsumerRecord<String, String> record : records) {
        process(record.key(), record.value());
    }
    consumer.commitSync();
}
```

## 6. How to Use in System Design Interviews

**When to propose Kafka:**
- Decoupling microservices
- Event sourcing / event-driven architecture
- High-throughput data ingestion (logs, metrics, clickstream)
- Stream processing (with Kafka Streams or Flink)

**When NOT to use:** Simple request-response, low-volume messaging (SQS simpler), need for message routing/filtering (RabbitMQ better).

## 8. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** How does Kafka guarantee ordering? **A:** Per-partition ordering. Use the same key for related messages to ensure they go to the same partition.
2. [🔥 Must Know] **Q:** What happens when a consumer crashes? **A:** Partition reassigned to another consumer in the group (rebalancing). Uncommitted messages reprocessed (at-least-once).
3. [🔥 Must Know] **Q:** Explain ISR. **A:** In-Sync Replicas — followers that are caught up with the leader. Only ISR members can be elected leader. `acks=all` waits for all ISR to acknowledge.
4. [🔥 Must Know] **Q:** How is Kafka different from RabbitMQ? **A:** Kafka: log-based, retained, replayable, high throughput. RabbitMQ: message broker, deleted after consumption, complex routing.
5. [🔥 Must Know] **Q:** How does Kafka achieve exactly-once semantics? **A:** Idempotent producer (dedup by sequence number) + transactional API (atomic writes across partitions) + consumer `read_committed` isolation. All three together = exactly-once.
6. [🔥 Must Know] **Q:** How do you choose the number of partitions? **A:** Target throughput / per-consumer throughput. E.g., need 100K msg/sec, each consumer handles 10K → 10 partitions minimum. More partitions = more parallelism but more overhead (memory, file handles, rebalancing time).
7. [🔥 Must Know] **Q:** What is consumer rebalancing and why is it a problem? **A:** When a consumer joins/leaves a group, partitions are redistributed. During rebalancing, ALL consumers in the group stop processing (stop-the-world). Can cause latency spikes. Fix: use cooperative rebalancing (incremental, only affected partitions reassigned).

## Additional Deep-Dive Topics

### Exactly-Once Semantics (EOS) [🔥 Must Know]

```
Three delivery guarantees:
  At-most-once:  fire and forget (acks=0). Fast but lossy.
  At-least-once: retry on failure (acks=all + consumer commit after processing). Duplicates possible.
  Exactly-once:  idempotent producer + transactions + read_committed consumer.

Idempotent Producer:
  enable.idempotence=true
  Producer assigns sequence number to each message.
  Broker deduplicates: if same sequence number received twice, discard the duplicate.
  Prevents duplicates from producer retries.

Transactional API (atomic writes across partitions):
  producer.initTransactions();
  producer.beginTransaction();
  producer.send(record1);  // to partition A
  producer.send(record2);  // to partition B
  producer.sendOffsetsToTransaction(offsets, consumerGroupId);  // commit consumer offsets
  producer.commitTransaction();  // atomic: all or nothing
  
  Use case: consume from topic A, process, produce to topic B, commit offsets — all atomically.
  If any step fails: abort transaction, nothing is visible to consumers.

Consumer side:
  isolation.level=read_committed
  Consumer only sees messages from committed transactions.
  Uncommitted/aborted messages are invisible.
```

### Consumer Rebalancing [🔥 Must Know]

```
Eager rebalancing (default, old):
  1. Consumer joins/leaves group
  2. ALL consumers revoke ALL partitions (stop processing)
  3. Group coordinator reassigns all partitions
  4. All consumers resume
  Problem: stop-the-world pause. At scale (100 consumers), rebalancing takes seconds.

Cooperative rebalancing (recommended):
  partition.assignment.strategy=CooperativeStickyAssignor
  1. Consumer joins/leaves group
  2. Only AFFECTED partitions are revoked and reassigned
  3. Other consumers continue processing unaffected partitions
  4. Much shorter pause, no stop-the-world

Static group membership (for long-running consumers):
  group.instance.id=consumer-1
  Consumer gets a stable identity. On restart (within session.timeout), 
  it gets the same partitions back without triggering rebalance.
```

### Partition Strategy [🔥 Must Know]

```
How to choose partition count:
  desired_throughput / per_consumer_throughput = min_partitions
  Example: 100K msg/sec target, each consumer handles 10K → at least 10 partitions

  Rules:
  - More partitions = more parallelism (up to consumer count)
  - More partitions = more overhead (file handles, memory, leader elections)
  - Can increase partitions later, but CANNOT decrease
  - Typical: 6-12 partitions for moderate topics, 50-100 for high-throughput

Key-based partitioning:
  Same key → same partition → ordering guaranteed for that key
  partition = hash(key) % num_partitions
  
  ⚠️ Adding partitions BREAKS key ordering (hash changes)
  → Plan partition count upfront for key-ordered topics

Custom partitioner:
  Implement Partitioner interface for special routing logic
  Example: route VIP customers to dedicated partitions for priority processing
```

### Kafka Streams vs Flink

| Aspect | Kafka Streams | Apache Flink |
|--------|--------------|-------------|
| Deployment | Library (runs in your app, no cluster) | Separate cluster (JobManager + TaskManagers) |
| Source/Sink | Kafka only | Kafka, HDFS, S3, JDBC, etc. |
| Complexity | Simple (just a JAR dependency) | Complex (cluster management) |
| Windowing | Tumbling, hopping, session, sliding | Same + custom windows |
| State | RocksDB (local), changelog topic for recovery | RocksDB, managed state with checkpoints |
| Best for | Kafka-to-Kafka stream processing | Complex event processing, multi-source joins |
| Scaling | Add more app instances (Kafka handles partition assignment) | Flink cluster auto-scaling |

**Use Kafka Streams when:** source and sink are both Kafka, logic is straightforward (filter, map, aggregate, join).
**Use Flink when:** multiple data sources, complex event processing, need exactly-once with non-Kafka sinks.

### Kafka Connect & CDC

```
Kafka Connect: pre-built connectors for moving data in/out of Kafka
  Source connectors: DB → Kafka (e.g., Debezium for CDC)
  Sink connectors: Kafka → DB/S3/Elasticsearch

CDC (Change Data Capture) with Debezium:
  Reads database transaction log (WAL in PostgreSQL, binlog in MySQL)
  Publishes every INSERT/UPDATE/DELETE as a Kafka event
  
  Use cases:
  - Keep cache in sync with DB (DB change → Kafka → cache update)
  - Replicate data to search index (DB → Kafka → Elasticsearch)
  - Outbox pattern: write to outbox table → Debezium reads → Kafka
  
  Advantage over dual-write: no consistency issues (single source of truth is the DB)
```

### Troubleshooting [🔥 Must Know]

| Problem | Symptom | Fix |
|---------|---------|-----|
| Consumer lag | Messages piling up, consumers can't keep up | Add more consumers (up to partition count). Increase batch size. Optimize processing logic. |
| Under-replicated partitions | ISR count < replication factor | Check broker health. Disk full? Network issues? Restart lagging broker. |
| Rebalancing storms | Frequent rebalances, processing stalls | Use cooperative rebalancing. Increase `session.timeout.ms`. Use static group membership. |
| Message too large | Producer error: `RecordTooLargeException` | Increase `max.message.bytes` on broker and `max.request.size` on producer. Or compress messages. |
| Offset out of range | Consumer can't find its offset (expired) | Set `auto.offset.reset=earliest` (reprocess) or `latest` (skip). Increase retention. |

## 9. Revision Checklist
- [ ] Topic → Partitions → Offsets. Partition = unit of parallelism.
- [ ] Producer acks: 0 (fast, lossy), 1 (leader), all (durable)
- [ ] Consumer groups: one consumer per partition, offset tracking
- [ ] Replication: leader + ISR followers, leader handles reads/writes
- [ ] Ordering: per-partition only. Same key → same partition.
- [ ] Retention: time or size based. Messages not deleted on consumption.
- [ ] Sequential disk I/O → high throughput despite being disk-based
