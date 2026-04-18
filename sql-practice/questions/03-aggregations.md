# 03 — Aggregations (COUNT, SUM, AVG, GROUP BY, HAVING)

### Q1. [Easy] Count the number of employees in each department. Show dept_id and count.

### Q2. [Easy] Find the average salary per department. Show dept_id, avg_salary. Sort by avg_salary descending.

### Q3. [Easy] Find the total revenue (sum of total_amount) per order status.

### Q4. [Medium] Find departments that have more than 5 employees. Show dept_id and employee count.
-- Concept: HAVING (filter AFTER aggregation, unlike WHERE which filters BEFORE).

### Q5. [Medium] Find the number of orders per customer, but only for customers with more than 10 orders. Show customer_id, order_count.

### Q6. [Medium] Find the min, max, and average price for each product category. Only include categories with at least 3 products.

### Q7. [Medium] Find the total revenue per month in 2023. Show month and total. Sort by month.
-- Hint: DATE_TRUNC('month', order_date) or EXTRACT(MONTH FROM order_date).

### Q8. [Hard] Find the percentage of orders in each status. Show status, count, and percentage (rounded to 2 decimals).
-- Trick: need total count as denominator. Use subquery or window function.
