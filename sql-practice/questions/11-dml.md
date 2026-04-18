# 11 — DML (INSERT, UPDATE, DELETE, UPSERT)

### Q1. [Easy] Insert a new customer: 'Test User', 'test@email.com', Mumbai, India, premium=true.

### Q2. [Medium] Give a 10% salary raise to all employees in the Engineering department (dept_id = 1).
-- UPDATE with JOIN or subquery.

### Q3. [Medium] Delete all orders with status 'CANCELLED' that are older than 1 year.
-- DELETE with WHERE + date condition.

### Q4. [Hard] Update the total_amount of each order to match the actual sum of its order_items (quantity × unit_price).
-- UPDATE with a subquery or FROM clause.

### Q5. [Hard] Upsert: insert a review, but if the customer already reviewed that product, update the rating and comment instead.
-- INSERT ... ON CONFLICT (product_id, customer_id) DO UPDATE SET ...
