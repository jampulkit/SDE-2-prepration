# 04 — Joins (INNER, LEFT, RIGHT, SELF, CROSS)

### Q1. [Easy] List all employees with their department name. Show employee name, department name, salary.

### Q2. [Easy] List all orders with customer name. Show order_id, customer name, order_date, total_amount.

### Q3. [Medium] Find all customers who have NEVER placed an order. Show customer name and email.
-- Trick: LEFT JOIN + WHERE orders.id IS NULL. Or use NOT EXISTS.

### Q4. [Medium] List each employee with their manager's name. Show employee name, manager name. Include employees with no manager (CEO).
-- Concept: SELF JOIN.

### Q5. [Medium] Find the total amount spent by each customer. Show customer name, total_spent. Include customers who spent nothing (show 0).
-- Trick: LEFT JOIN + COALESCE(SUM(...), 0).

### Q6. [Medium] For each order, show the order_id, product names, quantities, and line total (quantity × unit_price).
-- Concept: Multi-table JOIN (orders → order_items → products).

### Q7. [Hard] Find products that have been ordered but never reviewed. Show product name.
-- Concept: LEFT JOIN on reviews, filter NULL. Or EXISTS + NOT EXISTS.

### Q8. [Hard] Find customers who have ordered ALL products in the 'Books' category. Show customer name.
-- Trick: This is a "relational division" problem. COUNT(DISTINCT product_id) for Books = total Books count.
-- Note: with 4 Books products and 10K orders, some customers may qualify. If result is empty, that's valid too — the pattern matters.

### Q9. [Hard] Find pairs of employees in the same department who earn the same salary. Show both names and the salary.
-- Concept: SELF JOIN with e1.id < e2.id to avoid duplicates.

### Q10. [Hard] For each department, find the employee with the highest salary. If there's a tie, show all tied employees.
-- Trick: Can't just use MAX — need to handle ties. Use DENSE_RANK or subquery.
