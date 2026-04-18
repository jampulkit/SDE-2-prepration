# System Design — Database Choices

## 1. Prerequisites
- [00-prerequisites.md](./00-prerequisites.md) — SQL vs NoSQL overview, latency numbers
- [01-fundamentals.md](./01-fundamentals.md) — sharding, replication, denormalization
- This document is the definitive reference for "which database should I use?" in system design interviews

## 2. Core Concepts

### Relational Databases (SQL)

**Relational databases store data in tables with predefined schemas, enforce relationships through foreign keys, and guarantee ACID transactions — they're the default choice when data integrity matters.**

**When to use** [🔥 Must Know]:
- Data has clear relationships (foreign keys, joins)
- Need ACID transactions (financial data, user accounts, inventory)
- Complex queries with aggregations, GROUP BY, JOINs
- Data integrity is critical (constraints, triggers, referential integrity)
- Schema is well-defined and unlikely to change frequently

💡 **Intuition — When SQL is the Right Choice:** If you're building a payments system and a user pays $100, you need to guarantee that the $100 is deducted from their account AND added to the merchant's account atomically. If the system crashes between these two operations, you need rollback. This is exactly what ACID transactions provide. NoSQL databases generally don't support multi-document transactions (or do so with significant limitations).

**ACID properties** [🔥 Must Know]:

| Property | What It Means | Real-World Example |
|----------|--------------|-------------------|
| **Atomicity** | Transaction is all-or-nothing. If any part fails, everything rolls back. | Transfer $100: debit AND credit must both succeed or both fail. |
| **Consistency** | Database moves from one valid state to another. Constraints are never violated. | Account balance can't go negative (if constrained). |
| **Isolation** | Concurrent transactions don't interfere with each other. | Two users buying the last item: only one succeeds. |
| **Durability** | Committed data survives crashes (written to disk via WAL). | Server crashes after commit → data is still there on restart. |

⚙️ **Under the Hood — Write-Ahead Log (WAL):**
Before modifying actual data pages, the database writes the change to a sequential log file (WAL). If the system crashes mid-write, the WAL can replay the changes on recovery. This is how durability is guaranteed without flushing every write to disk immediately (which would be too slow).

```
Without WAL:
  Write to data page → CRASH → data page corrupted, partial write

With WAL:
  Write to WAL (sequential, fast) → Write to data page → CRASH
  Recovery: replay WAL → data page restored to consistent state
```

**Isolation levels** [🔥 Must Know]:

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Performance | Use Case |
|-------|-----------|-------------------|-------------|-------------|----------|
| READ UNCOMMITTED | ✅ possible | ✅ possible | ✅ possible | Fastest | Almost never used |
| READ COMMITTED | ❌ prevented | ✅ possible | ✅ possible | Good | PostgreSQL default. Most web apps. |
| REPEATABLE READ | ❌ | ❌ prevented | ✅ possible | Medium | MySQL default. Prevents most anomalies. |
| SERIALIZABLE | ❌ | ❌ | ❌ prevented | Slowest | Financial systems, inventory. |

💡 **Intuition — Isolation Level Anomalies:**
- **Dirty read:** You read data that another transaction hasn't committed yet. If they roll back, you read phantom data.
- **Non-repeatable read:** You read a row, another transaction updates it, you read again → different value.
- **Phantom read:** You query "all orders > $100", another transaction inserts a new order > $100, you query again → extra row appears.

MySQL default: REPEATABLE READ (with gap locking to prevent some phantoms). PostgreSQL default: READ COMMITTED.

**Indexing** [🔥 Must Know]:

| Index Type | Structure | Lookup | Range Query | Best For |
|-----------|-----------|--------|-------------|----------|
| B+ Tree | Balanced tree, sorted leaves | O(log n) | ✅ Excellent | Default. Most queries. |
| Hash | Hash table | O(1) | ❌ No | Exact equality only |
| Composite | B+ tree on multiple columns | O(log n) | ✅ (leftmost prefix) | Multi-column WHERE clauses |
| Covering | Index contains all needed columns | O(log n) | ✅ | Avoid table lookup entirely |
| Full-text | Inverted index | O(1) per term | N/A | Text search |

⚙️ **Under the Hood — B+ Tree Index:**

```
B+ Tree for index on user_id:

              [50]
             /    \
        [20, 35]   [70, 85]
        /  |  \     /  |  \
      [10,15] [20,25,30] [35,40,45] [50,55,60] [70,75,80] [85,90,95]
       ↓        ↓          ↓          ↓          ↓          ↓
      data     data       data       data       data       data

Lookup user_id=75: root→right→middle→scan leaf → 3 disk reads (3 levels)
Range query user_id BETWEEN 30 AND 60: find 30, then follow leaf pointers → sequential scan

For 1 billion rows: ~4 levels → 4 disk reads per lookup ≈ 40ms (HDD) or 0.6ms (SSD)
```

**Composite index and leftmost prefix rule:**
```sql
CREATE INDEX idx ON orders(user_id, created_at, status);

-- Uses index (leftmost prefix):
WHERE user_id = 123                           ✅
WHERE user_id = 123 AND created_at > '2024-01-01'  ✅
WHERE user_id = 123 AND created_at > '2024-01-01' AND status = 'PAID'  ✅

-- Does NOT use index (skips leftmost column):
WHERE created_at > '2024-01-01'               ❌ (user_id not specified)
WHERE status = 'PAID'                          ❌ (user_id, created_at not specified)
```

**When NOT to index:** Low-cardinality columns (boolean, gender — index doesn't help much), frequently updated columns (index maintenance overhead), small tables (full scan is faster than index lookup), columns rarely used in WHERE/JOIN/ORDER BY.

🎯 **Likely Follow-ups:**
- **Q:** What's the N+1 query problem?
  **A:** Loading a list of users, then for each user loading their orders in a separate query: 1 query for users + N queries for orders = N+1 queries. Fix: use JOIN or batch loading (`WHERE user_id IN (...)`).
- **Q:** When would you use a covering index?
  **A:** When a query only needs columns that are in the index. The database can answer the query entirely from the index without reading the actual table row (no "table lookup"). This is significantly faster for read-heavy queries.
- **Q:** How does PostgreSQL's MVCC differ from MySQL's?
  **A:** PostgreSQL stores old row versions in the heap (same table) and uses VACUUM to clean up. MySQL (InnoDB) stores old versions in a separate undo log. PostgreSQL's approach is simpler but can cause table bloat without regular VACUUM.

> 🔗 **See Also:** [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for deep dive on B+ trees, LSM trees, and storage engines.

### NoSQL Databases

**NoSQL databases sacrifice some SQL guarantees (usually joins and multi-row transactions) in exchange for flexible schemas, horizontal scalability, and optimized performance for specific access patterns.**

**Key-Value Stores** (Redis, DynamoDB, Memcached):

| Feature | Redis | DynamoDB | Memcached |
|---------|-------|----------|-----------|
| Data model | Rich (strings, lists, sets, sorted sets, hashes) | Key-value + sort key | Simple key-value |
| Persistence | Optional (RDB/AOF) | Fully managed, durable | None (pure cache) |
| Scaling | Single-node or cluster | Auto-scaling, managed | Client-side sharding |
| Latency | Sub-ms | Single-digit ms | Sub-ms |
| Best for | Caching, sessions, leaderboards, pub/sub | Serverless apps, high scale key-value | Pure caching |

**Document Stores** (MongoDB, CouchDB):
- Store JSON/BSON documents with flexible schema
- Each document can have different fields (schema-on-read)
- Rich query language, secondary indexes, aggregation pipeline
- Use for: product catalogs (each product has different attributes), content management, user profiles

**Wide-Column Stores** (Cassandra, HBase):
- Row key → column families → columns (sparse, dynamic)
- Optimized for writes (LSM tree) and time-series data
- Cassandra: masterless (no SPOF), tunable consistency (ONE, QUORUM, ALL), linear scalability
- Use for: time-series, IoT data, activity logs, messaging (write-heavy, time-ordered)

💡 **Intuition — Why Cassandra is Write-Optimized:**
Cassandra uses an LSM tree: writes go to an in-memory table (memtable), which is periodically flushed to disk as sorted files (SSTables). Writes are always sequential (append-only) → extremely fast. Reads may need to check multiple SSTables → slower. Compaction merges SSTables in the background to improve read performance.

**Graph Databases** (Neo4j, Amazon Neptune):
- Nodes + edges + properties
- Optimized for traversing relationships (O(1) per hop via index-free adjacency)
- Use for: social networks ("friends of friends"), recommendation engines, fraud detection, knowledge graphs

### NewSQL

**Combines SQL's ACID guarantees with NoSQL's horizontal scalability.** The best of both worlds, but with added complexity and cost.

| Database | Key Feature | Compatibility | Use Case |
|----------|------------|---------------|----------|
| CockroachDB | Distributed SQL, survives AZ failures | PostgreSQL wire protocol | Global apps needing ACID |
| Google Spanner | Globally distributed, externally consistent | Custom SQL | Google-scale global consistency |
| TiDB | Distributed HTAP (OLTP + OLAP) | MySQL compatible | Mixed workloads |
| Vitess | MySQL sharding middleware | MySQL | Scaling existing MySQL (YouTube uses it) |

## 3. Comparison Tables

### Database Selection Framework [🔥 Must Know]

| Requirement | Best Choice | Why | Example System |
|-------------|------------|-----|----------------|
| ACID transactions | PostgreSQL/MySQL | Built-in transaction support | Payment system, banking |
| Flexible schema | MongoDB | Schema-less documents | Product catalog, CMS |
| High write throughput | Cassandra | LSM-tree, append-only, masterless | IoT data, activity logs |
| Simple key-value lookups | Redis / DynamoDB | O(1) access, sub-ms latency | Caching, session store |
| Complex relationships | Neo4j | Index-free adjacency, O(1) traversal | Social graph, fraud detection |
| Global distribution + SQL | Spanner / CockroachDB | Distributed ACID | Global e-commerce |
| Caching layer | Redis | In-memory, rich data structures | Cache, leaderboards, pub/sub |
| Full-text search | Elasticsearch | Inverted index, relevance scoring | Search, log analysis |
| Time-series | TimescaleDB / InfluxDB | Time-partitioned, downsampling | Metrics, monitoring |
| Analytics/OLAP | ClickHouse / Redshift | Columnar storage, fast aggregations | Dashboards, reporting |

### Storage Engine Comparison [🔥 Must Know]

| Engine | Structure | Writes | Reads | Space | Use Case |
|--------|-----------|--------|-------|-------|----------|
| B+ Tree | Balanced tree, sorted | O(log n) in-place | O(log n) | Moderate | General purpose (InnoDB, PostgreSQL) |
| LSM Tree | Memtable + SSTables | O(1) amortized (append) | O(log n) multi-level | Higher (compaction) | Write-heavy (Cassandra, RocksDB, LevelDB) |
| Hash | Hash table | O(1) | O(1) | Low | Key-value only (Memcached, Bitcask) |

⚙️ **Under the Hood — B+ Tree vs LSM Tree:**

```
B+ Tree (read-optimized):
  Write: find correct leaf → update in place → O(log n) random I/O
  Read: traverse tree → O(log n), usually 3-4 disk reads
  Amplification: write amplification = 1 (one write per update)

LSM Tree (write-optimized):
  Write: append to memtable (memory) → O(1). Flush to SSTable when full.
  Read: check memtable → check each SSTable level → O(log n) but slower
  Amplification: read amplification (check multiple levels), space amplification (old versions)
  Compaction: merge SSTables in background → reclaims space, improves reads

Trade-off: LSM trades read performance and space for write performance.
```

| Factor | B+ Tree | LSM Tree |
|--------|---------|----------|
| Write speed | Moderate (random I/O) | Fast (sequential I/O) |
| Read speed | Fast (single tree) | Moderate (multiple levels) |
| Space usage | Efficient | Higher (before compaction) |
| Write amplification | Low | Higher (compaction rewrites) |
| Best for | Read-heavy, OLTP | Write-heavy, time-series |

🎯 **Likely Follow-ups:**
- **Q:** Why does Cassandra use LSM trees?
  **A:** Cassandra is designed for high write throughput (IoT, logs, time-series). LSM trees convert random writes to sequential writes, which are 100x faster on disk. The trade-off (slower reads) is acceptable because Cassandra queries are typically by partition key (efficient even with LSM).
- **Q:** Can you use both B+ tree and LSM tree in the same system?
  **A:** Yes. MySQL uses B+ tree (InnoDB) for OLTP. You might use RocksDB (LSM) for a write-heavy cache or log store alongside it. TiDB uses both: TiKV (LSM for storage) + TiFlash (columnar for analytics).

## 4. How This Shows Up in Interviews

**What to say when choosing a database:**
1. **State the access pattern:** "This is read-heavy with complex queries, so I'll use PostgreSQL."
2. **Justify with requirements:** "We need ACID for payment transactions and joins for order-user relationships."
3. **Acknowledge trade-offs:** "SQL doesn't scale writes as easily as Cassandra, but at our estimated 3,500 write QPS, a single PostgreSQL with read replicas handles it fine."
4. **Mention alternatives:** "If write QPS grows to 100K+, we could consider sharding PostgreSQL or moving time-series data to Cassandra."

**Common interview scenarios:**

| System | Primary DB | Why | Secondary |
|--------|-----------|-----|-----------|
| User accounts, auth | PostgreSQL | ACID, relationships | Redis (session cache) |
| Chat messages | Cassandra | High write throughput, time-ordered | Redis (recent messages cache) |
| Product catalog | MongoDB | Flexible schema, varied attributes | Elasticsearch (search) |
| Social graph | PostgreSQL + Neo4j | Transactions + relationship traversal | Redis (feed cache) |
| URL shortener | DynamoDB or Redis | Simple key-value, high throughput | — |
| Analytics dashboard | ClickHouse | Columnar, fast aggregations | — |
| Payment system | PostgreSQL | ACID, strong consistency | Redis (idempotency cache) |
| Notification system | Cassandra | High writes, time-ordered | Redis (unread count) |

💥 **What Can Go Wrong — Database Anti-Patterns:**

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| "Just use MongoDB for everything" | No ACID for payments, no joins | Use the right DB for each use case |
| Indexing every column | Slow writes, wasted space | Index only columns used in WHERE/JOIN/ORDER BY |
| No read replicas for read-heavy system | DB becomes bottleneck | Add read replicas, cache with Redis |
| Sharding too early | Unnecessary complexity | Scale vertically first, shard when needed |
| Using SQL for time-series at scale | Poor write performance | Use Cassandra, TimescaleDB, or InfluxDB |

## 5. Deep Dive Questions

1. [🔥 Must Know] **When would you choose SQL over NoSQL?** — ACID needs, relationships, complex queries.
2. [🔥 Must Know] **Explain ACID properties with real-world examples.** — Payment transfer, inventory deduction.
3. [🔥 Must Know] **B+ Tree vs LSM Tree — when to use each?** — Read-heavy vs write-heavy, in-place vs append.
4. [🔥 Must Know] **How does database indexing work?** — B+ tree structure, composite index, leftmost prefix rule.
5. **What are isolation levels? Which for a banking app?** — SERIALIZABLE for strict, REPEATABLE READ for most.
6. [🔥 Must Know] **Compare DynamoDB vs Cassandra vs MongoDB.** — Access patterns, consistency, scaling model.
7. **What is a write-ahead log (WAL)?** — Sequential log before data page write, crash recovery.
8. **How does MVCC work?** — Multiple versions of rows, readers don't block writers.
9. [🔥 Must Know] **When would you use Elasticsearch alongside a primary DB?** — Full-text search, log analysis, not as primary store.
10. **OLTP vs OLAP?** — Transactional (row-based, many small queries) vs analytical (columnar, few large queries).
11. [🔥 Must Know] **Design the database for a social media platform.** — Users (SQL), posts (SQL or Cassandra), feed (Redis cache), search (Elasticsearch).
12. **What is a materialized view?** — Precomputed query result stored as a table, refreshed periodically.
13. **How does Cassandra achieve high write throughput?** — LSM tree, memtable, sequential SSTable writes, no leader.
14. **What is the N+1 query problem?** — 1 query for list + N queries for details. Fix: JOIN or batch IN clause.
15. [🔥 Must Know] **When would you denormalize?** — When joins are too expensive (sharded DB, read-heavy), trade storage for read speed.

## 6. Revision Checklist

**SQL:**
- [ ] ACID: Atomicity (all-or-nothing), Consistency (valid states), Isolation (no interference), Durability (survives crashes)
- [ ] Isolation levels: READ UNCOMMITTED → READ COMMITTED → REPEATABLE READ → SERIALIZABLE
- [ ] MySQL default: REPEATABLE READ. PostgreSQL default: READ COMMITTED.
- [ ] WAL: write-ahead log for crash recovery and durability

**Indexing:**
- [ ] B+ Tree: default, O(log n), range queries, sorted leaves linked
- [ ] Hash: O(1) equality only, no range queries
- [ ] Composite: leftmost prefix rule — (A, B, C) index works for A, A+B, A+B+C but NOT B or C alone
- [ ] Covering index: all query columns in index → no table lookup
- [ ] Don't index: low cardinality, frequently updated, small tables

**NoSQL types:**
- [ ] Key-Value (Redis, DynamoDB): O(1) lookups, caching, sessions
- [ ] Document (MongoDB): flexible schema, JSON documents, rich queries
- [ ] Wide-Column (Cassandra): write-optimized (LSM), time-series, masterless
- [ ] Graph (Neo4j): relationship traversal, social networks

**Storage engines:**
- [ ] B+ Tree: read-optimized, in-place updates, random I/O writes
- [ ] LSM Tree: write-optimized, append-only, sequential I/O, compaction needed
- [ ] Trade-off: LSM trades read speed and space for write speed

**Decision framework:**
- [ ] Need ACID? → SQL (PostgreSQL/MySQL)
- [ ] Flexible schema? → MongoDB
- [ ] High writes? → Cassandra
- [ ] Simple lookups? → Redis/DynamoDB
- [ ] Relationships? → Neo4j (+ SQL for transactions)
- [ ] Search? → Elasticsearch (secondary, not primary)
- [ ] Analytics? → ClickHouse/Redshift (columnar)

---

## 📋 Suggested New Documents

### 1. Database Indexing & Query Optimization Deep Dive
- **Placement**: `02-system-design/06-indexing-query-optimization.md`
- **Why needed**: Index design, query execution plans (EXPLAIN), slow query analysis, and query optimization are critical for SDE-2 interviews (especially at Amazon, Flipkart) but only briefly covered here.
- **Key subtopics**: EXPLAIN plan reading, index selection strategies, covering indexes, partial indexes, query rewriting, connection pooling, prepared statements, database-level caching
