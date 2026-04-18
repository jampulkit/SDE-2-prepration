# 06 — Window Functions

### Q1. [Medium] Rank all employees by salary within their department. Show name, dept_id, salary, rank.
-- Use ROW_NUMBER, RANK, and DENSE_RANK — explain the difference in results.

### Q2. [Medium] Find the top 3 highest-paid employees in each department.
-- Classic "Top N per group" — ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC).

### Q3. [Medium] For each order, show the running total of order amounts sorted by date.
-- SUM(total_amount) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING).

### Q4. [Medium] For each day's sales, show the 7-day moving average.
-- AVG() OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW).

### Q5. [Medium] For each employee, show their salary and the difference from the previous employee's salary (ordered by hire_date).
-- LAG(salary) OVER (ORDER BY hire_date).

### Q6. [Medium] Divide employees into 4 salary quartiles. Show name, salary, quartile.
-- NTILE(4) OVER (ORDER BY salary).

### Q7. [Hard] For each customer, show their order and the number of days since their previous order.
-- LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date).

### Q8. [Hard] Calculate the cumulative percentage of total revenue per product category.
-- SUM() OVER (ORDER BY revenue DESC) / SUM() OVER () * 100.

### Q9. [Hard] Find employees whose salary is above the average of their department — using only window functions (no subquery, no JOIN).
-- AVG(salary) OVER (PARTITION BY dept_id) as dept_avg, then filter.
-- Trick: can't use window function in WHERE — need a subquery/CTE wrapper.

### Q10. [Hard] For each product, show its rank by revenue within its category AND its overall rank across all products.
-- Two window functions in the same query with different PARTITION BY.
