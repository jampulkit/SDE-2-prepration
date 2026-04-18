# 09 — String & Date Functions

### Q1. [Easy] Extract the first name and last name from the employees.name column (split by space).
-- SPLIT_PART(name, ' ', 1) and SPLIT_PART(name, ' ', 2).

### Q2. [Easy] Find all orders placed on a weekend (Saturday or Sunday).
-- EXTRACT(DOW FROM order_date) — 0=Sunday, 6=Saturday.

### Q3. [Medium] Calculate the age of each customer account in years and months.
-- AGE(NOW(), created_at) or DATE_PART.

### Q4. [Medium] Find the day of the week with the most orders. Show day name and count.
-- TO_CHAR(order_date, 'Day') or EXTRACT(DOW ...).

### Q5. [Medium] For each employee, calculate their tenure in years (from hire_date to today). Show name, hire_date, tenure_years.

### Q6. [Medium] Find all orders placed in the last 90 days from the most recent order date (not from NOW — from the data).
-- Trick: use a subquery for MAX(order_date), not CURRENT_DATE.

### Q7. [Hard] Group orders by fiscal quarter (Q1=Apr-Jun, Q2=Jul-Sep, Q3=Oct-Dec, Q4=Jan-Mar for Indian FY). Show quarter and total revenue.
-- Trick: Indian fiscal year starts April. Need CASE on month.
