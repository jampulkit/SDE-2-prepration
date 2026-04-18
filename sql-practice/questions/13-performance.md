# 13 — Performance & Query Optimization

### Q1. [Medium] Run EXPLAIN ANALYZE on: `SELECT * FROM orders WHERE customer_id = 5`. Is it using an index? What's the cost?

### Q2. [Medium] This query is slow. Why? How would you fix it?
```sql
SELECT * FROM orders WHERE EXTRACT(YEAR FROM order_date) = 2023;
```
-- Trick: function on column prevents index usage. Rewrite as range: `order_date >= '2023-01-01' AND order_date < '2024-01-01'`.

### Q3. [Hard] Create an optimal composite index for this query:
```sql
SELECT * FROM orders WHERE customer_id = 5 AND status = 'DELIVERED' ORDER BY order_date DESC LIMIT 10;
```
-- Answer: CREATE INDEX idx ON orders(customer_id, status, order_date DESC).
-- Explain: leftmost prefix rule, why order_date DESC matters.

### Q4. [Hard] This query returns correct results but is very slow on 10M rows. Optimize it.
```sql
SELECT * FROM employees WHERE salary IN (SELECT MAX(salary) FROM employees GROUP BY dept_id);
```
-- Rewrite with window function: RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) = 1.

### Q5. [Hard] Explain the difference between these two queries' performance:
```sql
-- (Create this table first: CREATE TABLE blacklist (customer_id INT);
--  INSERT INTO blacklist VALUES (1),(2),(NULL);)
-- Query A:
SELECT * FROM orders WHERE customer_id NOT IN (SELECT customer_id FROM blacklist);
-- Query B:
SELECT * FROM orders o WHERE NOT EXISTS (SELECT 1 FROM blacklist b WHERE b.customer_id = o.customer_id);
```
-- Trick: NOT IN returns NO ROWS if subquery contains NULL! Query A returns empty. Query B works correctly. NOT EXISTS is always safer.
