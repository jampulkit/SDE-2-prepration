# Database Internals

## 1. What & Why

**Understanding how databases work under the hood, including storage engines, indexing, query execution, and transactions, helps you make better design decisions, write efficient queries, and answer the deep "why" questions that separate SDE-2 from SDE-1.**

💡 **Why this matters in interviews:** When you say "I'll use PostgreSQL with a B+ tree index on user_id", the interviewer might ask "Why B+ tree? How does it work? What's the lookup complexity? When would you use an LSM tree instead?" This document gives you those answers.

> 🔗 **See Also:** [02-system-design/02-database-choices.md](../02-system-design/02-database-choices.md) for database selection framework. [02-system-design/10-indexing-query-optimization.md](../02-system-design/10-indexing-query-optimization.md) for practical query optimization.

## 2. Core Concepts

### Storage Engines [🔥 Must Know]

**B+ Tree (InnoDB, PostgreSQL):**

```
B+ Tree structure (order 3):

         [30 | 60]                    ← internal node (keys only, no data)
        /    |    \
   [10|20] [40|50] [70|80]           ← leaf nodes (keys + data + next pointer)
      ↓       ↓       ↓
   data     data     data
   
   Leaf nodes linked: [10|20] → [40|50] → [70|80]
   This linked list enables efficient range scans.

Lookup "50":
  Root: 50 > 30, 50 < 60 → go to middle child
  Leaf [40|50]: found! Return data.
  2 disk reads (root + leaf). O(log n) where n = number of keys.

Range scan "40 to 70":
  Find 40 (2 disk reads) → follow leaf chain → [40|50] → [70|80] → stop at 80.
  Sequential reads after finding start point. Very efficient.
```

**Properties:**
- All data in leaf nodes (internal nodes only store keys for routing)
- Leaf nodes linked for range scans
- Balanced: all leaves at same depth
- High fan-out (hundreds of keys per node) → tree is shallow (3-4 levels for millions of rows)
- In-place updates: modify data where it lives

⚙️ **Under the Hood, Why B+ Tree is Shallow:**

```
Assume: page size = 16KB, key size = 8 bytes, pointer size = 8 bytes
Keys per internal node: 16KB / (8+8) ≈ 1000
Keys per leaf node: ~500 (data takes more space)

Level 0 (root): 1 node, 1000 keys
Level 1: 1000 nodes, 1M keys
Level 2: 1M nodes, 500M keys (leaf level)

3 levels can index 500 MILLION rows.
Root is always cached in memory → only 2 disk reads per lookup.
```

**LSM Tree (RocksDB, Cassandra, LevelDB):**

```
Write path:
  1. Write to in-memory buffer (memtable, typically a red-black tree or skip list)
  2. When memtable is full → flush to disk as sorted file (SSTable)
  3. Background compaction merges SSTables to reduce read amplification

Read path:
  1. Check memtable (in-memory, fast)
  2. Check bloom filters for each SSTable level (skip SSTables that don't contain the key)
  3. Search SSTables from newest to oldest (newest has latest data)

Compaction:
  Level 0: unsorted SSTables (direct flush from memtable)
  Level 1: sorted, non-overlapping SSTables (merged from Level 0)
  Level 2: larger sorted SSTables (merged from Level 1)
  ...
  Each level is ~10x larger than the previous.
```

**B+ Tree vs LSM Tree:**

| Aspect | B+ Tree | LSM Tree |
|--------|---------|----------|
| Write speed | O(log n) random I/O | O(1) sequential I/O (append to memtable) |
| Read speed | O(log n), 2-3 disk reads | O(log n) but may check multiple levels |
| Write amplification | Low (in-place update) | High (compaction rewrites data) |
| Read amplification | Low (one index lookup) | Higher (check multiple levels) |
| Space amplification | Low | Medium (old versions until compacted) |
| Best for | Read-heavy workloads (OLTP) | Write-heavy workloads (logging, time-series) |
| Used by | PostgreSQL, MySQL InnoDB | Cassandra, RocksDB, LevelDB, HBase |

### ACID Transactions [🔥 Must Know]

| Property | What | How |
|----------|------|-----|
| **Atomicity** | All or nothing | Undo log: on abort, replay undo log to reverse changes |
| **Consistency** | Valid state to valid state | Constraints, triggers, foreign keys |
| **Isolation** | Concurrent transactions don't interfere | MVCC + locks (see below) |
| **Durability** | Committed data survives crashes | WAL (Write-Ahead Log) |

### Write-Ahead Log (WAL) [🔥 Must Know]

```
Without WAL:
  1. Modify data page in memory
  2. Write data page to disk
  Problem: crash between step 1 and 2 → data lost

With WAL:
  1. Write change to WAL (sequential write, fast)
  2. Modify data page in memory
  3. Eventually write data page to disk (checkpoint)
  On crash: replay WAL to recover committed changes

Why WAL is fast:
  WAL writes are SEQUENTIAL (append-only). Disk sequential write: ~100 MB/s.
  Data page writes are RANDOM (update in place). Disk random write: ~1 MB/s.
  WAL converts random writes to sequential writes → 100x faster.
```

### MVCC (Multi-Version Concurrency Control) [🔥 Must Know]

**Each transaction sees a consistent snapshot of the database. Readers don't block writers, writers don't block readers.**

⚙️ **Under the Hood, How MVCC Works (PostgreSQL):**

```
Table "accounts": id=1, balance=100

Transaction T1 (read): BEGIN (snapshot at time 10)
Transaction T2 (write): BEGIN
  T2: UPDATE accounts SET balance = 200 WHERE id = 1
  PostgreSQL creates a NEW version of the row:
    Version 1: balance=100, created_by=T0, deleted_by=T2
    Version 2: balance=200, created_by=T2, deleted_by=NULL
  T2: COMMIT

T1 reads id=1:
  T1's snapshot is at time 10 (before T2 committed)
  T1 sees Version 1 (balance=100) — T2's change is invisible to T1
  No blocking! T1 reads old version while T2 writes new version.

After T1 commits:
  Version 1 is now "dead" (no active transaction needs it)
  VACUUM process eventually removes Version 1 to reclaim space
```

### Transaction Isolation Levels [🔥 Must Know]

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Performance |
|-------|-----------|-------------------|-------------|-------------|
| READ UNCOMMITTED | Possible | Possible | Possible | Fastest |
| READ COMMITTED | No | Possible | Possible | Default in PostgreSQL |
| REPEATABLE READ | No | No | Possible* | Default in MySQL InnoDB |
| SERIALIZABLE | No | No | No | Slowest |

*MySQL's REPEATABLE READ prevents phantom reads using gap locks.

**Anomaly examples:**

```
Dirty Read (READ UNCOMMITTED):
  T1: UPDATE balance = 200 (not committed yet)
  T2: SELECT balance → sees 200 (uncommitted data!)
  T1: ROLLBACK → balance is back to 100
  T2 used a value (200) that never existed. Dangerous.

Non-Repeatable Read (READ COMMITTED):
  T1: SELECT balance → 100
  T2: UPDATE balance = 200, COMMIT
  T1: SELECT balance → 200 (different from first read!)
  Same query, different results within one transaction.

Phantom Read (REPEATABLE READ):
  T1: SELECT COUNT(*) FROM orders WHERE status='PENDING' → 5
  T2: INSERT INTO orders (status='PENDING'), COMMIT
  T1: SELECT COUNT(*) FROM orders WHERE status='PENDING' → 6 (new row appeared!)
  A "phantom" row appeared between two identical queries.
```

### Query Execution Pipeline

```
SQL: SELECT name FROM users WHERE age > 25 ORDER BY name LIMIT 10

1. Parser: SQL text → Abstract Syntax Tree (AST)
   Checks syntax. "Is this valid SQL?"

2. Analyzer: AST → Logical Plan
   Resolves table/column names. Checks permissions. Type checking.

3. Optimizer: Logical Plan → Physical Plan
   Chooses: which index to use? Which join algorithm? Which scan method?
   Cost-based: estimates I/O cost, CPU cost for each plan. Picks cheapest.
   
   Plan A: Full table scan + sort → cost: 10,000
   Plan B: Index scan on age + sort → cost: 500
   Plan C: Index scan on (age, name) → cost: 100 (covering index, no sort needed!)
   Optimizer picks Plan C.

4. Executor: Physical Plan → Result
   Executes the plan. Reads pages from buffer pool (or disk). Returns rows.
```

### Join Algorithms [🔥 Must Know]

| Algorithm | How | Time | Best For |
|-----------|-----|------|----------|
| **Nested Loop** | For each row in A, scan B | O(n * m) | Small tables, indexed inner table |
| **Hash Join** | Build hash table on smaller table, probe with larger | O(n + m) | Equality joins, no index |
| **Sort-Merge Join** | Sort both tables, merge | O(n log n + m log m) | Pre-sorted data, range joins |
| **Index Nested Loop** | For each row in A, index lookup in B | O(n * log m) | One table has index on join column |

```
Hash Join example:
  SELECT * FROM orders o JOIN users u ON o.user_id = u.id

  Phase 1 (Build): scan users table, build hash table {id → user_row}
  Phase 2 (Probe): scan orders table, for each order, look up user_id in hash table
  
  Total: O(|users| + |orders|). Very fast for large tables without indexes.
  Memory: hash table must fit in memory (or spill to disk).
```

## 3. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** How does a B+ Tree index work? **A:** Balanced tree with data in leaf nodes. Leaf nodes linked for range scans. O(log n) lookup. High fan-out means 3 levels can index 500M rows. Used by default in most RDBMS.
2. [🔥 Must Know] **Q:** What is MVCC? **A:** Each transaction sees a consistent snapshot. Multiple versions of rows maintained. Readers don't block writers. PostgreSQL stores old versions in heap (cleaned by VACUUM). MySQL stores in undo log.
3. [🔥 Must Know] **Q:** B+ Tree vs LSM Tree? **A:** B+ Tree: read-optimized, in-place updates, 2-3 disk reads per lookup. LSM Tree: write-optimized, append-only, compaction in background. Choose based on read/write ratio.
4. [🔥 Must Know] **Q:** What is WAL? **A:** Write-Ahead Log. Changes written to log (sequential) before data files (random). On crash, replay log to recover. Converts random writes to sequential writes for durability.
5. [🔥 Must Know] **Q:** Explain transaction isolation levels. **A:** READ COMMITTED (default PG): no dirty reads. REPEATABLE READ (default MySQL): no non-repeatable reads. SERIALIZABLE: no anomalies but slowest. Trade-off between consistency and performance.
6. [🔥 Must Know] **Q:** What is a composite index and the leftmost prefix rule? **A:** Index on (A, B, C) supports queries on A, (A,B), (A,B,C) but NOT B alone or (B,C). The index is sorted by A first, then B within same A, then C.
7. **Q:** How does the query optimizer choose an execution plan? **A:** Cost-based optimization. Estimates I/O and CPU cost for each possible plan (full scan vs index scan, nested loop vs hash join). Picks the plan with lowest estimated cost. EXPLAIN shows the chosen plan.

## 4. Revision Checklist

- [ ] B+ Tree: balanced, data in leaves, linked leaves for range scans, O(log n), 3 levels for 500M rows
- [ ] LSM Tree: memtable → SSTables → compaction. Write-optimized. Bloom filters for read optimization.
- [ ] B+ Tree for read-heavy (OLTP). LSM Tree for write-heavy (logging, time-series).
- [ ] WAL: write log first (sequential), then data (random). Replay on crash. 100x faster than random writes.
- [ ] MVCC: snapshot isolation, multiple row versions, readers don't block writers
- [ ] PostgreSQL MVCC: old versions in heap, VACUUM cleans. MySQL: undo log.
- [ ] Isolation levels: READ COMMITTED (no dirty reads), REPEATABLE READ (no non-repeatable reads), SERIALIZABLE (no phantoms)
- [ ] Anomalies: dirty read (uncommitted data), non-repeatable read (different results), phantom read (new rows appear)
- [ ] Query pipeline: parse → analyze → optimize (cost-based) → execute
- [ ] Join algorithms: nested loop (small), hash join (equality, no index), sort-merge (pre-sorted)
- [ ] Composite index: leftmost prefix rule. Covering index: all columns in index, no table lookup.

> 🔗 **See Also:** [02-system-design/02-database-choices.md](../02-system-design/02-database-choices.md) for database selection. [02-system-design/10-indexing-query-optimization.md](../02-system-design/10-indexing-query-optimization.md) for practical query optimization. [06-tech-stack/02-redis-deep-dive.md](../06-tech-stack/02-redis-deep-dive.md) for in-memory data structures.
