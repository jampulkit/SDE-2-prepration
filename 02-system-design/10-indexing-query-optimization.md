# System Design — Database Indexing & Query Optimization

## 1. Prerequisites
- [02-database-choices.md](02-database-choices.md) — B+ tree, LSM tree, index types

## 2. Core Concepts

### Index Types [🔥 Must Know]

| Index Type | Structure | Best For | Example |
|-----------|-----------|----------|---------|
| **B+ Tree** (default) | Balanced tree, sorted | Range queries, ORDER BY, equality | `WHERE age > 25 AND age < 50` |
| **Hash** | Hash table | Exact equality only | `WHERE email = 'user@example.com'` |
| **GIN** (Generalized Inverted) | Inverted index | Full-text search, array contains, JSONB | `WHERE tags @> '{java}'` |
| **GiST** (Generalized Search Tree) | R-tree variant | Geospatial, range types | `WHERE location <-> point(40.7, -74.0) < 1000` |
| **BRIN** (Block Range) | Min/max per block | Large tables with natural ordering | `WHERE created_at > '2024-01-01'` on time-series data |

⚙️ **Under the Hood, B+ Tree vs Hash Index:**

```
B+ Tree:
  Sorted structure. Supports: =, <, >, <=, >=, BETWEEN, ORDER BY, LIKE 'prefix%'
  Lookup: O(log n). Range scan: O(log n + k) where k = result size.
  
  Internal nodes: [keys + child pointers]
  Leaf nodes: [keys + row pointers + next-leaf pointer]
  Leaf nodes are linked → efficient range scans (follow the chain)

Hash Index:
  Hash table. Supports: = only. No range queries, no ORDER BY.
  Lookup: O(1) average. But: no range support, no sorting.
  
  Use when: exact match lookups on high-cardinality columns (email, UUID)
  Don't use when: range queries, sorting, or low-cardinality columns
```

### Database Partitioning [🔥 Must Know]

```
Horizontal partitioning (sharding): split rows across tables/servers
  orders_2024_q1: rows where created_at in Q1 2024
  orders_2024_q2: rows where created_at in Q2 2024
  
  Query: WHERE created_at = '2024-03-15'
  → Only scans orders_2024_q1 (partition pruning). Skips all other partitions.

Partition strategies:
  Range: by date, by ID range. Good for time-series.
  List: by region, by status. Good for categorical data.
  Hash: by hash(user_id) % N. Good for even distribution.
```

🎯 **Likely Follow-ups:**
- **Q:** How do you decide which columns to index?
  **A:** Index columns that appear in WHERE, JOIN ON, and ORDER BY clauses of your most frequent queries. Check slow query logs. Use EXPLAIN to verify the index is used. Don't over-index: each index slows down writes (INSERT/UPDATE/DELETE must update all indexes).
- **Q:** What is the cost of too many indexes?
  **A:** Each index adds O(log n) overhead to every INSERT and UPDATE. For a table with 10 indexes, each write updates 10 B+ trees. Write-heavy workloads suffer. Rule of thumb: 3-5 indexes per table is typical. More than 10 is a red flag.
- **Q:** How do you handle slow queries in production?
  **A:** (1) Enable slow query log (queries > 100ms). (2) EXPLAIN the slow query. (3) Add missing index or rewrite query. (4) If the table is too large, partition it. (5) If reads are too heavy, add a read replica or cache layer.

### Index Design Principles [🔥 Must Know]

**1. Index columns used in WHERE, JOIN, ORDER BY**
```sql
-- This query benefits from index on (user_id, created_at):
SELECT * FROM orders WHERE user_id = 123 ORDER BY created_at DESC LIMIT 20;

-- Composite index: CREATE INDEX idx_user_date ON orders(user_id, created_at DESC);
-- Without index: full table scan O(n). With index: O(log n) + 20 rows.
```

**2. Leftmost prefix rule for composite indexes**
```sql
CREATE INDEX idx ON orders(user_id, status, created_at);

-- Uses index: WHERE user_id = 123
-- Uses index: WHERE user_id = 123 AND status = 'PAID'
-- Uses index: WHERE user_id = 123 AND status = 'PAID' AND created_at > '2024-01-01'
-- Does NOT use index: WHERE status = 'PAID' (skips user_id)
-- Does NOT use index: WHERE created_at > '2024-01-01' (skips user_id, status)
```

**3. Covering index (index-only scan)**
```sql
-- If index contains ALL columns the query needs, no table lookup required
CREATE INDEX idx_covering ON orders(user_id, status, total);
SELECT status, total FROM orders WHERE user_id = 123;
-- Answered entirely from index — no disk read for actual row!
```

### Reading EXPLAIN Plans [🔥 Must Know]

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123 AND status = 'PAID';

-- Key things to look for:
-- type: ALL (full scan — BAD), index (index scan), ref (index lookup — GOOD), const (primary key)
-- rows: estimated rows examined (lower is better)
-- Extra: "Using index" (covering index — GREAT), "Using filesort" (sorting without index — BAD)
-- key: which index is used (NULL = no index used)
```

### Common Query Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| `SELECT *` | Fetches unnecessary columns, prevents covering index | Select only needed columns |
| `WHERE function(column)` | Can't use index on column | Rewrite: `WHERE column > '2024-01-01'` not `WHERE YEAR(column) > 2024` |
| N+1 queries | 1 query for list + N queries for details | Use JOIN or batch `WHERE id IN (...)` |
| Missing index on JOIN column | Full table scan on joined table | Add index on foreign key columns |
| `OFFSET 1000000 LIMIT 20` | Scans and skips 1M rows | Use cursor/keyset pagination: `WHERE id > last_id LIMIT 20` |
| `LIKE '%search%'` | Can't use B+ tree index (leading wildcard) | Use full-text index or Elasticsearch |

### Connection Pooling [🔥 Must Know]

```
Without pooling:
  Each request: open connection (TCP + auth = 50ms) → query → close connection
  At 1000 QPS: 1000 connections opened/closed per second — huge overhead

With pooling (HikariCP):
  Pool maintains 10-50 persistent connections
  Request borrows connection → query → returns connection to pool
  No connection setup overhead per request

HikariCP config (Spring Boot):
  spring.datasource.hikari.maximum-pool-size=20
  spring.datasource.hikari.minimum-idle=5
  spring.datasource.hikari.connection-timeout=30000
  spring.datasource.hikari.idle-timeout=600000
```

### Slow Query Optimization Checklist

1. **EXPLAIN** the query — check if index is used
2. **Add missing indexes** on WHERE/JOIN/ORDER BY columns
3. **Rewrite query** — avoid functions on indexed columns, avoid `SELECT *`
4. **Denormalize** — if JOINs are too expensive, duplicate data
5. **Cache** — if query is repeated, cache the result in Redis
6. **Partition** — if table is too large, partition by date/range
7. **Read replica** — offload read queries to replicas

## 3. How This Shows Up in Interviews

**What to say:**
> "I'll add a composite index on (user_id, created_at) for the orders table since our primary query pattern is fetching a user's recent orders. I'll use cursor-based pagination instead of OFFSET for the feed. For the search feature, I'll use Elasticsearch instead of LIKE queries on PostgreSQL."

## 4. Revision Checklist
- [ ] Index columns in WHERE, JOIN, ORDER BY. Composite index follows leftmost prefix rule.
- [ ] Covering index: all query columns in index → no table lookup (index-only scan).
- [ ] EXPLAIN: check type (ALL=bad, ref=good), rows (lower=better), key (which index).
- [ ] Anti-patterns: SELECT *, function on indexed column, N+1, OFFSET pagination, LIKE '%x%'.
- [ ] Connection pooling: HikariCP, 10-50 connections, avoid per-request connection setup.
- [ ] Cursor pagination: `WHERE id > last_id LIMIT 20` instead of `OFFSET 1000000`.

> 🔗 **See Also:** [02-system-design/02-database-choices.md](02-database-choices.md) for B+ tree index internals. [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for storage engine details.
