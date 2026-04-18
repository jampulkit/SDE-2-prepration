# 10 — CASE WHEN & Pivot

### Q1. [Easy] Categorize employees by salary: <100K = 'Junior', 100K-180K = 'Mid', >180K = 'Senior'. Show name, salary, level.

### Q2. [Medium] Pivot: show each customer's spending by payment method as columns. customer_name, card_total, upi_total, wallet_total, cod_total.
-- CASE WHEN inside SUM: SUM(CASE WHEN method = 'CARD' THEN amount ELSE 0 END).

### Q3. [Medium] For each product, show the count of 1-star, 2-star, 3-star, 4-star, and 5-star reviews as separate columns.
-- Conditional aggregation (pivot).

### Q4. [Medium] Create a report: for each department, show count of ACTIVE, INACTIVE, and ON_LEAVE employees as columns.

### Q5. [Hard] Show monthly revenue for 2023 as a pivot table: one row per category, one column per month (Jan, Feb, ..., Dec).
-- 12 CASE WHEN expressions inside SUM.

### Q6. [Hard] Flag orders as 'High Value' (>20000), 'Medium' (5000-20000), 'Low' (<5000). Then show the count and total revenue per flag per month.
