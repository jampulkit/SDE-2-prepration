# 05 — Subqueries

### Q1. [Easy] Find all employees who earn more than the company average salary.

### Q2. [Medium] Find the second highest salary in the company. 
-- Classic interview question. Multiple approaches: LIMIT OFFSET, subquery, DENSE_RANK.

### Q3. [Medium] Find all products that are more expensive than the average price in their category.
-- Concept: Correlated subquery — inner query references outer query.

### Q4. [Medium] Find customers who have placed an order in the last 30 days (relative to the most recent order date in the data). Use EXISTS.
-- Trick: use (SELECT MAX(order_date) FROM orders) instead of NOW(), since data is static.
-- EXISTS vs IN — EXISTS stops at first match (faster for large datasets).

### Q5. [Medium] Find departments where the average salary is higher than the overall company average.

### Q6. [Hard] Find the Nth highest salary (make it work for any N).
-- Interview classic. Use DENSE_RANK or OFFSET.

### Q7. [Hard] Find employees who earn more than their department's average salary. Show name, salary, dept avg.
-- Concept: Correlated subquery or JOIN with aggregated subquery.
