# NoSQL Databases

## 1. What & Why

**NoSQL databases solve problems that relational databases struggle with: massive horizontal scale, flexible schemas, high write throughput, and optimized performance for specific access patterns. Knowing when to use DynamoDB vs Cassandra vs MongoDB is a key system design skill.**

💡 **Intuition — NoSQL is Not "No SQL" but "Not Only SQL":** NoSQL databases aren't replacements for SQL — they're specialized tools for specific problems. Use SQL when you need ACID transactions and complex queries. Use NoSQL when you need massive scale, flexible schemas, or specific access patterns (key-value, time-series, graph).

> 🔗 **See Also:** [02-system-design/02-database-choices.md](../02-system-design/02-database-choices.md) for the complete database selection framework. [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for B+ tree vs LSM tree storage engines.

## 2. Core Concepts by Type

### DynamoDB [🔥 Must Know]
- Managed key-value + document store by AWS
- Single-digit millisecond latency at any scale
- **Partition key** (hash) + optional **sort key** (range)
- Auto-scaling, serverless option (on-demand mode)
- Strongly consistent or eventually consistent reads
- GSI (Global Secondary Index) and LSI (Local Secondary Index)
- Streams for change data capture

⚙️ **Under the Hood, DynamoDB Partition Key Design:**

```
DynamoDB distributes data across partitions based on hash(partition_key).
Each partition handles ~3000 RCU and ~1000 WCU.

GOOD partition key (high cardinality, even distribution):
  user_id: millions of unique values → even distribution across partitions
  order_id: UUID → perfectly distributed

BAD partition key (hot partition):
  status: only 3 values (PENDING, ACTIVE, COMPLETED) → 3 partitions, uneven load
  date: all today's writes go to one partition → hot partition

Composite key example:
  Partition key: user_id
  Sort key: order_date
  
  Query: "Get all orders for user 123 in January 2024"
  → Partition key = "user123", Sort key BETWEEN "2024-01-01" AND "2024-01-31"
  → Hits exactly ONE partition, range scan on sort key. Very efficient.
```

**GSI vs LSI:**

| Feature | GSI (Global Secondary Index) | LSI (Local Secondary Index) |
|---------|-------|------|
| Partition key | Different from base table | Same as base table |
| Sort key | Any attribute | Different sort key |
| When to create | Anytime | Only at table creation |
| Consistency | Eventually consistent only | Strongly consistent option |
| Throughput | Separate (own RCU/WCU) | Shares base table's throughput |
| Use when | Query by a different key entirely | Same partition key, different sort order |

**Capacity modes:**

| Mode | How | Best For |
|------|-----|----------|
| Provisioned | Set RCU/WCU, auto-scaling optional | Predictable traffic, cost optimization |
| On-demand | Pay per request, no capacity planning | Unpredictable traffic, new tables |

**Single-table design pattern** (advanced):

```
Instead of: Users table, Orders table, Products table
Use ONE table with different item types:

PK              SK                  Data
USER#123        PROFILE             {name: "Alice", email: "..."}
USER#123        ORDER#2024-001      {total: 50.00, status: "SHIPPED"}
USER#123        ORDER#2024-002      {total: 30.00, status: "PENDING"}
PRODUCT#456     METADATA            {name: "Widget", price: 9.99}
PRODUCT#456     REVIEW#USER#123     {rating: 5, text: "Great!"}

Benefits: all related data in one table, one query gets user + orders.
Trade-off: complex access patterns, harder to understand.
```

🎯 **Likely Follow-ups:**
- **Q:** When would you NOT use DynamoDB?
  **A:** When you need complex queries (joins, aggregations), ad-hoc queries, or strong consistency across multiple items. DynamoDB is optimized for known access patterns with simple key-based lookups. For analytics, use Redshift or Athena.
- **Q:** How does DynamoDB handle hot partitions?
  **A:** Adaptive capacity: DynamoDB automatically redistributes throughput from less-active partitions to hot ones. But this has limits. For extreme hot keys (celebrity user), use write sharding: append a random suffix to the partition key (e.g., user_123#1, user_123#2) and scatter-gather on reads.

### MongoDB
- Document store (BSON/JSON documents)
- Flexible schema (each document can differ)
- Rich query language, aggregation pipeline
- Replica sets for HA, sharding for scale
- Use for: product catalogs, content management, user profiles

### Cassandra
- Wide-column store, masterless (no SPOF, every node is equal)
- Tunable consistency (W + R > N for strong consistency)
- LSM-tree storage → optimized for writes
- Partition key determines data distribution
- Use for: time-series, IoT, messaging, activity logs

⚙️ **Under the Hood, Cassandra Data Model:**

```
Primary key = (partition key, clustering columns)

Partition key: determines WHICH node stores the data (hash → token ring)
Clustering columns: determine ORDER within a partition (sorted on disk)

Example: messaging app
  CREATE TABLE messages (
    chat_id UUID,           -- partition key (all messages for a chat on same node)
    sent_at TIMESTAMP,      -- clustering column (sorted by time within partition)
    sender TEXT,
    content TEXT,
    PRIMARY KEY (chat_id, sent_at)
  ) WITH CLUSTERING ORDER BY (sent_at DESC);

  Query: SELECT * FROM messages WHERE chat_id = ? ORDER BY sent_at DESC LIMIT 50;
  → Hits ONE partition, reads last 50 messages. Very fast.
```

**Cassandra read/write path:**

```
Write path (fast, append-only):
  1. Write to commit log (durability, sequential write)
  2. Write to memtable (in-memory, sorted)
  3. Return success to client
  4. Background: memtable flushes to SSTable on disk when full

Read path (slower, check multiple places):
  1. Check memtable (in-memory)
  2. Check bloom filters for each SSTable (skip SSTables that don't have the key)
  3. Read from SSTables (newest first)
  4. Merge results (newest version wins)

Compaction: background process merges SSTables, removes tombstones (deleted data)
  Strategies: SizeTiered (write-heavy), Leveled (read-heavy), TimeWindow (time-series)
```

**Tunable consistency:**

```
N = replication factor (e.g., 3 replicas)
W = write consistency level (how many replicas must acknowledge write)
R = read consistency level (how many replicas must respond to read)

Strong consistency: W + R > N
  Example: W=2, R=2, N=3 → 2+2=4 > 3 → at least one replica has latest data

Common configurations:
  W=1, R=1 (fastest, eventual consistency)
  W=QUORUM, R=QUORUM (strong consistency, balanced)
  W=ALL, R=1 (durable writes, fast reads, but write fails if any replica is down)
```

### Elasticsearch
- Search engine built on Apache Lucene
- Inverted index for full-text search
- Near real-time search (< 1 second indexing delay)
- Use alongside primary DB for search functionality
- Use for: log analysis, product search, autocomplete

## 7. Comparison

| Feature | DynamoDB | MongoDB | Cassandra | Elasticsearch |
|---------|----------|---------|-----------|---------------|
| Model | Key-value + document | Document | Wide-column | Search engine |
| Consistency | Tunable | Strong (primary) | Tunable | Eventual |
| Scaling | Auto | Manual sharding | Linear | Manual |
| Writes | Fast | Good | Excellent | Good |
| Queries | Limited (key-based) | Rich | Limited (partition key) | Full-text search |
| Managed | Yes (AWS) | Atlas | Astra | Elastic Cloud |

## 8. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** When would you use DynamoDB? **A:** Simple access patterns (key-value lookups), need auto-scaling, serverless, single-digit ms latency. Not for complex queries or joins.
2. [🔥 Must Know] **Q:** DynamoDB partition key design? **A:** High cardinality (many unique values) for even distribution. Avoid hot partitions. Composite keys (partition + sort) for range queries.
3. [🔥 Must Know] **Q:** When Cassandra over DynamoDB? **A:** Need multi-cloud/on-prem, higher write throughput, more control over consistency tuning, time-series data.

## 9. Revision Checklist
- [ ] DynamoDB: partition key + sort key, GSI/LSI, auto-scaling, single-digit ms
- [ ] MongoDB: flexible schema, rich queries, replica sets
- [ ] Cassandra: masterless, tunable consistency, LSM-tree, high writes
- [ ] Elasticsearch: inverted index, full-text search, use alongside primary DB
