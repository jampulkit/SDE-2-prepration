# 02 — Filtering (AND/OR, IN, BETWEEN, LIKE, IS NULL)

### Q1. [Easy] Find all customers from Mumbai or Delhi who are premium members.

### Q2. [Easy] Find all products priced between 5000 and 50000. Show name, category, price.

### Q3. [Easy] Find all employees whose name starts with 'A'. 

### Q4. [Easy] Find all customers who don't have a phone number (NULL phone).

### Q5. [Medium] Find all orders that are either DELIVERED or SHIPPED, placed in 2023, with total_amount > 10000.

### Q6. [Medium] Find all employees who have a NULL bonus OR bonus = 0. Show name, salary, bonus.
-- Trick: `bonus = NULL` doesn't work! Must use `IS NULL`.

### Q7. [Medium] Find all products whose name contains 'Air' (case-insensitive).
-- Hint: ILIKE in PostgreSQL, or LOWER() + LIKE.

### Q8. [Medium] Find all customers NOT from India who signed up in 2023.
