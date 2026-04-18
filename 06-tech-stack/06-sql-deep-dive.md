# SQL Deep Dive

## 1. What & Why

**SQL is tested in almost every backend interview. You need to write correct queries under pressure, understand execution plans, and know how indexes affect performance. This doc covers the patterns that appear most frequently.**

> 🔗 **See Also:** [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for B+ tree, LSM tree, MVCC internals. [02-system-design/10-indexing-query-optimization.md](../02-system-design/10-indexing-query-optimization.md) for index design and EXPLAIN plans.

## 2. Core Concepts

### JOIN Types [🔥 Must Know]

```sql
-- Sample tables:
-- users: {id, name, dept_id}
-- departments: {id, name}

-- INNER JOIN: only matching rows from both tables
SELECT u.name, d.name FROM users u INNER JOIN departments d ON u.dept_id = d.id;
-- Users without a department are excluded. Departments without users are excluded.

-- LEFT JOIN: all rows from left table, matching from right (NULL if no match)
SELECT u.name, d.name FROM users u LEFT JOIN departments d ON u.dept_id = d.id;
-- All users included. dept_name is NULL for users without a department.

-- RIGHT JOIN: all rows from right table, matching from left
SELECT u.name, d.name FROM users u RIGHT JOIN departments d ON u.dept_id = d.id;
-- All departments included. user_name is NULL for departments without users.

-- FULL OUTER JOIN: all rows from both tables
SELECT u.name, d.name FROM users u FULL OUTER JOIN departments d ON u.dept_id = d.id;
-- All users and all departments. NULLs where no match.

-- CROSS JOIN: every row from A paired with every row from B (cartesian product)
SELECT u.name, d.name FROM users u CROSS JOIN departments d;
-- If users has 100 rows and departments has 10, result has 1000 rows.

-- SELF JOIN: join a table with itself
SELECT e.name AS employee, m.name AS manager
FROM employees e LEFT JOIN employees m ON e.manager_id = m.id;
```

### Window Functions [🔥 Must Know]

**Window functions compute a value across a set of rows related to the current row, without collapsing rows (unlike GROUP BY).**

```sql
-- ROW_NUMBER: unique sequential number per partition
SELECT name, dept, salary,
       ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rank
FROM employees;
-- Result: each department's employees numbered 1, 2, 3... by salary

-- RANK vs DENSE_RANK:
-- RANK: 1, 2, 2, 4 (skips after tie)
-- DENSE_RANK: 1, 2, 2, 3 (no skip after tie)

-- Top N per group (common interview pattern):
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
    FROM employees
) ranked WHERE rn <= 3;
-- Top 3 highest-paid employees per department

-- LAG / LEAD: access previous/next row
SELECT date, revenue,
       revenue - LAG(revenue) OVER (ORDER BY date) AS daily_change
FROM daily_sales;
-- Difference from previous day's revenue

-- Running total:
SELECT date, amount,
       SUM(amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING) AS running_total
FROM transactions;

-- Moving average:
SELECT date, amount,
       AVG(amount) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_7day
FROM daily_sales;
```

### CTEs (Common Table Expressions)

```sql
-- Basic CTE: readable alternative to subqueries
WITH active_users AS (
    SELECT user_id, COUNT(*) AS order_count
    FROM orders
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT u.name, au.order_count
FROM users u JOIN active_users au ON u.id = au.user_id
WHERE au.order_count > 5;

-- Recursive CTE: traverse hierarchical data (org chart, categories)
WITH RECURSIVE org_chart AS (
    -- Base case: CEO (no manager)
    SELECT id, name, manager_id, 0 AS level
    FROM employees WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees reporting to someone in the previous level
    SELECT e.id, e.name, e.manager_id, oc.level + 1
    FROM employees e JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart ORDER BY level, name;
```

### Transaction Isolation Levels

(Detailed in [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md))

```sql
-- Set isolation level
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN;
SELECT balance FROM accounts WHERE id = 1; -- sees snapshot
-- Another transaction updates balance
SELECT balance FROM accounts WHERE id = 1; -- still sees same snapshot (repeatable read)
COMMIT;
```

### N+1 Query Problem [🔥 Must Know]

```java
// N+1 PROBLEM: 1 query for users + N queries for orders
List<User> users = userRepo.findAll();           // 1 query: SELECT * FROM users
for (User u : users) {
    List<Order> orders = orderRepo.findByUserId(u.getId()); // N queries!
}
// If 100 users → 101 queries. Terrible performance.

// FIX 1: JOIN query
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders(); // 1 query with JOIN

// FIX 2: Batch fetch
@EntityGraph(attributePaths = "orders")
List<User> findAll(); // Hibernate generates IN clause: WHERE user_id IN (1,2,3...)

// FIX 3: Subquery
SELECT * FROM orders WHERE user_id IN (SELECT id FROM users WHERE active = true);
```

### Connection Pooling [🔥 Must Know]

```
Without pooling:
  Each request: open TCP connection + authenticate + query + close
  Connection setup: ~50ms. At 1000 QPS: 1000 connections/sec. Huge overhead.

With HikariCP (Spring Boot default):
  Pool maintains 10-50 persistent connections.
  Request borrows connection → query → returns to pool. No setup overhead.

Key settings:
  maximum-pool-size: 20 (max concurrent DB connections)
  minimum-idle: 5 (keep at least 5 connections ready)
  connection-timeout: 30s (max wait for a connection from pool)
  max-lifetime: 30min (replace connections to avoid stale connections)

Rule of thumb: pool size = CPU cores * 2 + disk spindles
  For SSD: pool size ≈ 10-20 is usually enough.
  Too large: DB overwhelmed. Too small: requests wait for connections.
```

## 3. EXPLAIN Plans [🔥 Must Know]

**EXPLAIN shows how the database executes your query — which indexes it uses, how many rows it scans, and where the bottlenecks are.**

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123 ORDER BY created_at DESC LIMIT 20;

-- Output (PostgreSQL):
-- Limit (cost=0.43..12.50 rows=20)
--   → Index Scan using idx_orders_user_date on orders (cost=0.43..150.00 rows=250)
--       Index Cond: (user_id = 123)
--       Actual time: 0.05..0.12 rows=20 loops=1
-- Planning Time: 0.2ms
-- Execution Time: 0.15ms
```

**What to look for:**

| Indicator | Good | Bad |
|-----------|------|-----|
| Scan type | Index Scan, Index Only Scan | Seq Scan (full table scan) on large table |
| Rows | Close to actual rows returned | Estimated 1, actual 100K (bad stats) |
| Cost | Low first number (startup cost) | High cost with no index |
| Actual time | < 10ms for simple queries | > 100ms = investigate |
| Filter | Rows Removed by Filter: 0 | Rows Removed: 99999 (scanning too much) |

**Common fixes:**
```sql
-- Bad: Seq Scan (no index on email)
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
-- Fix: CREATE INDEX idx_users_email ON users(email);

-- Bad: Index Scan but sorting in memory (filesort)
EXPLAIN SELECT * FROM orders WHERE user_id = 123 ORDER BY created_at DESC;
-- Fix: CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC);
-- Composite index covers both WHERE and ORDER BY

-- Bad: Using index but still slow (too many rows)
EXPLAIN SELECT * FROM logs WHERE created_at > '2024-01-01';
-- Fix: Partition by month. Query only hits relevant partition.
```

## 4. Locking & Deadlocks [🔥 Must Know]

### Row-Level Locking

```sql
-- Pessimistic locking: lock rows for update
SELECT * FROM products WHERE id = 123 FOR UPDATE;
-- Other transactions trying to SELECT FOR UPDATE on same row will WAIT

-- SKIP LOCKED: skip already-locked rows (useful for job queues)
SELECT * FROM tasks WHERE status = 'PENDING' LIMIT 1 FOR UPDATE SKIP LOCKED;
-- If row is locked by another worker, skip it and grab the next one

-- NOWAIT: fail immediately if row is locked
SELECT * FROM products WHERE id = 123 FOR UPDATE NOWAIT;
-- Throws error instead of waiting. Good for user-facing requests.
```

### Deadlocks

```
Deadlock scenario:
  Transaction A: UPDATE accounts SET balance = balance - 100 WHERE id = 1; (locks row 1)
  Transaction B: UPDATE accounts SET balance = balance - 50 WHERE id = 2;  (locks row 2)
  Transaction A: UPDATE accounts SET balance = balance + 100 WHERE id = 2; (WAITS for row 2)
  Transaction B: UPDATE accounts SET balance = balance + 50 WHERE id = 1;  (WAITS for row 1)
  → DEADLOCK! Both waiting for each other.

Prevention:
  1. Always lock rows in the SAME ORDER (e.g., by ascending ID)
     → Both transactions lock id=1 first, then id=2. No cycle.
  2. Keep transactions SHORT (less time holding locks)
  3. Use optimistic locking (version column) instead of pessimistic
  4. Set lock_timeout to fail fast instead of waiting forever

Detection:
  PostgreSQL/MySQL automatically detect deadlocks and kill one transaction.
  The killed transaction gets an error → application should RETRY.
```

### Optimistic vs Pessimistic Locking

| Aspect | Optimistic | Pessimistic |
|--------|-----------|-------------|
| How | Version column, check on update | SELECT FOR UPDATE, lock row |
| Conflict handling | Retry on version mismatch | Wait for lock release |
| Best for | Low contention (most updates succeed) | High contention (many concurrent updates) |
| Throughput | Higher (no locks held) | Lower (locks block others) |
| Example | E-commerce product page | Flash sale inventory |

```sql
-- Optimistic: version check
UPDATE products SET stock = stock - 1, version = version + 1
WHERE id = 123 AND version = 5;
-- If affected_rows = 0 → someone else updated first → RETRY

-- Pessimistic: explicit lock
BEGIN;
SELECT stock FROM products WHERE id = 123 FOR UPDATE;
-- check stock >= 1
UPDATE products SET stock = stock - 1 WHERE id = 123;
COMMIT;
```

## 5. Top 10 SQL Interview Questions

1. **Second highest salary:**
```sql
SELECT MAX(salary) FROM employees WHERE salary < (SELECT MAX(salary) FROM employees);
-- Or: SELECT DISTINCT salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET 1;
```

2. **Nth highest salary:**
```sql
SELECT DISTINCT salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET N-1;
-- Or with DENSE_RANK:
SELECT salary FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk FROM employees
) t WHERE rnk = N;
```

3. **Duplicate emails:**
```sql
SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1;
```

4. **Employees earning more than their manager:**
```sql
SELECT e.name FROM employees e JOIN employees m ON e.manager_id = m.id WHERE e.salary > m.salary;
```

5. **Department with highest average salary:**
```sql
SELECT dept, AVG(salary) AS avg_sal FROM employees GROUP BY dept ORDER BY avg_sal DESC LIMIT 1;
```

6. **Consecutive days with login (gaps and islands):**
```sql
WITH numbered AS (
    SELECT user_id, login_date,
           login_date - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) * INTERVAL '1 day' AS grp
    FROM logins
)
SELECT user_id, MIN(login_date) AS start_date, MAX(login_date) AS end_date,
       COUNT(*) AS consecutive_days
FROM numbered GROUP BY user_id, grp HAVING COUNT(*) >= 3;
```

7. **Running total:**
```sql
SELECT date, amount, SUM(amount) OVER (ORDER BY date) AS running_total FROM transactions;
```

8. **Pivot (rows to columns):**
```sql
SELECT user_id,
       SUM(CASE WHEN category = 'food' THEN amount ELSE 0 END) AS food,
       SUM(CASE WHEN category = 'travel' THEN amount ELSE 0 END) AS travel
FROM expenses GROUP BY user_id;
```

9. **Delete duplicates (keep one):**
```sql
DELETE FROM users WHERE id NOT IN (SELECT MIN(id) FROM users GROUP BY email);
```

10. **Median salary:**
```sql
SELECT AVG(salary) FROM (
    SELECT salary, ROW_NUMBER() OVER (ORDER BY salary) AS rn, COUNT(*) OVER () AS cnt
    FROM employees
) t WHERE rn IN (FLOOR((cnt+1)/2.0), CEIL((cnt+1)/2.0));
```

## 6. Revision Checklist

- [ ] JOINs: INNER (both match), LEFT (all left + matching right), FULL (all from both)
- [ ] Window functions: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, running SUM/AVG
- [ ] Top N per group: ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) then filter rn <= N
- [ ] CTE: WITH clause for readability. Recursive CTE for hierarchical data.
- [ ] N+1 problem: 1 + N queries. Fix with JOIN FETCH, @EntityGraph, or IN clause.
- [ ] Connection pooling: HikariCP, pool size ≈ 10-20, avoid per-request connection setup.
- [ ] Index: columns in WHERE, JOIN, ORDER BY. Composite index follows leftmost prefix rule.
- [ ] EXPLAIN: check for full scans (type=ALL bad), index usage (type=ref good).
- [ ] Gaps and islands: ROW_NUMBER trick to group consecutive values.
- [ ] Pivot: CASE WHEN inside aggregate function.

> 🔗 **See Also:** [02-system-design/10-indexing-query-optimization.md](../02-system-design/10-indexing-query-optimization.md) for EXPLAIN plans and index design. [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for storage engine internals.
