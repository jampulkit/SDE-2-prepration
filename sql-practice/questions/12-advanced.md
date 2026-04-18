# 12 — Advanced Interview Tricks 🔥

> These are the tricky patterns that separate "knows SQL" from "aces SQL interviews."

## Gaps & Islands

### Q1. [Hard] Find the longest streak of consecutive login days for each customer.
-- Table: login_logs. Show customer_id, streak_start, streak_end, streak_length.
-- Trick: login_date - ROW_NUMBER() = constant for consecutive dates.

### Q2. [Hard] Find all "gaps" in customer 2's login history — periods where they didn't log in.
-- Show gap_start (day after last login), gap_end (day before next login), gap_days.

## Top-N Per Group

### Q3. [Hard] Find the top 2 most expensive orders for each customer. Show customer name, order_id, total_amount, rank.
-- Trick: ROW_NUMBER() in subquery/CTE, then filter rn <= 2.

### Q4. [Hard] For each category, find the product with the highest total revenue. Handle ties (show all tied products).
-- Trick: DENSE_RANK, not ROW_NUMBER (ROW_NUMBER breaks ties arbitrarily).

## Duplicate Detection & Removal

### Q5. [Medium] Find all duplicate emails in the customers table (if any exist).
-- GROUP BY email HAVING COUNT(*) > 1.

### Q6. [Hard] Delete duplicate rows, keeping only the one with the smallest id.
-- DELETE WHERE id NOT IN (SELECT MIN(id) FROM table GROUP BY duplicate_column).
-- Trick: in PostgreSQL, use ctid for tables without a unique column.

## Nth Highest / Ranking Tricks

### Q7. [Hard] Find the 3rd highest salary in each department. If a department has fewer than 3 employees, show NULL.
-- DENSE_RANK + LEFT JOIN or conditional.

### Q8. [Hard] Find employees who earn the median salary in their department.
-- Trick: PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) or ROW_NUMBER approach.

## Running Calculations

### Q9. [Hard] For each month, calculate the month-over-month change in revenue AND the percentage change.
-- LAG() for previous month, then (current - previous) / previous * 100.

### Q10. [Hard] Calculate the cumulative percentage of total revenue, ordered by product revenue descending (Pareto / 80-20 analysis).
-- SUM(revenue) OVER (ORDER BY revenue DESC) / total_revenue * 100.

## Relational Division (The Hardest Pattern)

### Q11. [Hard] Find customers who have purchased ALL products in the 'Books' category.
-- Trick: COUNT(DISTINCT product_id) for that customer in Books = total Books count.
-- This is "relational division" — one of the hardest SQL patterns.

### Q12. [Hard] Find departments where ALL employees have salary > 100000 (not just some — ALL of them).
-- Trick: NOT EXISTS (employee in dept with salary <= 100000). Or MIN(salary) > 100000.

## Tricky NULL Handling

### Q13. [Medium] Find the total bonus paid per department. Handle NULLs correctly (NULL bonus ≠ 0 bonus).
-- Trick: SUM ignores NULLs, but COUNT doesn't. COALESCE(bonus, 0) if you want NULLs as 0.

### Q14. [Medium] Find employees whose bonus is NOT equal to 30000. Include employees with NULL bonus.
-- Trick: `bonus != 30000` EXCLUDES NULLs! Must use `bonus != 30000 OR bonus IS NULL`.
-- This is the #1 NULL trap in SQL interviews.

## Self-Join Tricks

### Q15. [Hard] Find all employees who earn more than their manager.
-- Self-join: employees e JOIN employees m ON e.manager_id = m.id WHERE e.salary > m.salary.

### Q16. [Hard] For each employee, show how many people report to them (direct reports only). Include employees with 0 reports.
-- LEFT JOIN employees m ON m.manager_id = e.id, then COUNT.

## Correlated Subquery Tricks

### Q17. [Hard] For each product, find the customer who spent the most on it. Show product name, customer name, total_spent.
-- Correlated subquery or LATERAL JOIN.

### Q18. [Hard] Find orders where the total_amount is greater than the average total_amount for that customer's orders.
-- Correlated subquery: WHERE total_amount > (SELECT AVG(total_amount) FROM orders o2 WHERE o2.customer_id = o1.customer_id).

## Date Tricks

### Q19. [Hard] Find customers who placed orders in 3 or more consecutive months.
-- Trick: DATE_TRUNC('month', order_date), then gaps & islands on months.

### Q20. [Hard] For each customer, find the average number of days between consecutive orders.
-- LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), then AVG the diffs.

## EXISTS vs IN vs JOIN

### Q21. [Medium] Rewrite this query three ways (same result): "Find customers who have at least one delivered order."
-- (a) Using IN subquery
-- (b) Using EXISTS
-- (c) Using JOIN + DISTINCT
-- Discuss: which is fastest and why? (EXISTS short-circuits, IN materializes, JOIN may duplicate rows).

## Anti-Join Patterns

### Q22. [Hard] Find products that have NEVER been ordered. Write it 3 ways:
-- (a) LEFT JOIN ... WHERE order_items.id IS NULL
-- (b) NOT IN (SELECT product_id FROM order_items)
-- (c) NOT EXISTS (SELECT 1 FROM order_items WHERE product_id = p.id)
-- Trick: NOT IN fails if subquery returns NULL! NOT EXISTS is safest.

## Window Function Traps

### Q23. [Hard] Why does this query NOT work? Fix it.
-- SELECT name, salary, AVG(salary) OVER (PARTITION BY dept_id) as dept_avg
-- FROM employees
-- WHERE salary > dept_avg;
-- Trick: Can't use window function in WHERE. Must wrap in CTE/subquery.

### Q24. [Hard] Find the first and last order date for each customer, and the total number of orders — in a single query without GROUP BY.
-- Use FIRST_VALUE, LAST_VALUE (with proper frame), and COUNT as window functions.
-- Trick: LAST_VALUE needs ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.
