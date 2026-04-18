# 07 — CTEs & Recursive Queries

### Q1. [Medium] Using a CTE, find the top 5 customers by total spending. Show name, total_spent.

### Q2. [Medium] Using multiple CTEs, find the most popular product (by order count) in each category.

### Q3. [Hard] Using a recursive CTE, display the full org chart: employee name, manager name, and level (CEO = 0).

### Q4. [Hard] Using a recursive CTE, find all employees who report to 'Rajesh Kumar' (directly or indirectly).

### Q5. [Hard] Generate a date series for all days in January 2024, and LEFT JOIN with orders to show daily order count (0 for days with no orders).
-- Trick: generate_series() + LEFT JOIN. Common for "fill gaps in time series" problems.

### Q6. [Hard] Using a CTE, calculate month-over-month revenue growth rate (%). Show month, revenue, prev_month_revenue, growth_pct.
