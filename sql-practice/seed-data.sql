-- SQL Practice Project — Seed Data (Large Dataset)
-- Run after schema.sql: psql -U postgres -d sql_practice -f seed-data.sql
-- Total rows: ~55,000+

-- ============ DEPARTMENTS (10) ============
INSERT INTO departments (name, budget, location) VALUES
('Engineering', 5000000, 'Bangalore'),
('Product', 2000000, 'Bangalore'),
('Sales', 3000000, 'Mumbai'),
('Marketing', 1500000, 'Mumbai'),
('HR', 1000000, 'Gurugram'),
('Finance', 2500000, 'Gurugram'),
('Support', 800000, 'Hyderabad'),
('Data Science', 3500000, 'Bangalore'),
('Operations', 1200000, 'Delhi'),
('Legal', 900000, NULL);

-- ============ EMPLOYEES (500) ============
-- First 50 hand-crafted (managers, edge cases)
INSERT INTO employees (name, email, dept_id, manager_id, salary, bonus, hire_date, status) VALUES
('Rajesh Kumar', 'rajesh@company.com', 1, NULL, 250000, 50000, '2018-03-15', 'ACTIVE'),
('Priya Sharma', 'priya@company.com', 1, 1, 180000, 30000, '2019-06-01', 'ACTIVE'),
('Amit Patel', 'amit@company.com', 1, 1, 200000, 40000, '2019-01-10', 'ACTIVE'),
('Sneha Reddy', 'sneha@company.com', 1, 1, 170000, 25000, '2020-04-20', 'ACTIVE'),
('Vikram Singh', 'vikram@company.com', 1, 3, 150000, 20000, '2021-07-01', 'ACTIVE'),
('Ananya Gupta', 'ananya@company.com', 1, 3, 160000, 22000, '2020-11-15', 'ACTIVE'),
('Rahul Verma', 'rahul@company.com', 1, 2, 140000, 15000, '2022-01-10', 'ACTIVE'),
('Deepika Nair', 'deepika@company.com', 2, NULL, 220000, 45000, '2018-08-01', 'ACTIVE'),
('Karthik Iyer', 'karthik@company.com', 2, 8, 170000, 30000, '2019-12-01', 'ACTIVE'),
('Meera Joshi', 'meera@company.com', 2, 8, 165000, 28000, '2020-03-15', 'ON_LEAVE'),
('Suresh Menon', 'suresh@company.com', 3, NULL, 190000, 60000, '2017-05-20', 'ACTIVE'),
('Kavita Rao', 'kavita@company.com', 3, 11, 140000, 45000, '2019-09-01', 'ACTIVE'),
('Arjun Das', 'arjun@company.com', 3, 11, 130000, 40000, '2020-06-15', 'ACTIVE'),
('Pooja Mishra', 'pooja@company.com', 3, 11, 125000, 35000, '2021-02-01', 'INACTIVE'),
('Nikhil Saxena', 'nikhil@company.com', 4, NULL, 175000, 35000, '2018-11-01', 'ACTIVE'),
('Ritu Agarwal', 'ritu@company.com', 4, 15, 130000, 20000, '2020-08-01', 'ACTIVE'),
('Sanjay Tiwari', 'sanjay@company.com', 4, 15, 125000, 18000, '2021-04-15', 'ACTIVE'),
('Divya Kapoor', 'divya@company.com', 5, NULL, 160000, 25000, '2019-02-01', 'ACTIVE'),
('Manish Dubey', 'manish@company.com', 5, 18, 120000, 15000, '2021-09-01', 'ACTIVE'),
('Swati Pandey', 'swati@company.com', 6, NULL, 210000, 40000, '2018-06-01', 'ACTIVE'),
('Rohit Choudhary', 'rohit@company.com', 6, 20, 155000, 25000, '2020-01-15', 'ACTIVE'),
('Neha Bansal', 'neha@company.com', 6, 20, 145000, 22000, '2020-10-01', 'ACTIVE'),
('Arun Pillai', 'arun@company.com', 7, NULL, 130000, 15000, '2019-07-01', 'ACTIVE'),
('Lakshmi Krishnan', 'lakshmi@company.com', 7, 23, 100000, 10000, '2021-03-01', 'ACTIVE'),
('Gaurav Malhotra', 'gaurav@company.com', 7, 23, 95000, 8000, '2022-06-01', 'ACTIVE'),
('Tanvi Deshmukh', 'tanvi@company.com', 8, NULL, 230000, 50000, '2019-04-01', 'ACTIVE'),
('Harsh Vardhan', 'harsh@company.com', 8, 26, 190000, 35000, '2020-07-15', 'ACTIVE'),
('Isha Bhatt', 'isha@company.com', 8, 26, 180000, 30000, '2021-01-10', 'ACTIVE'),
('Vivek Chauhan', 'vivek@company.com', 9, NULL, 145000, 20000, '2019-10-01', 'ACTIVE'),
('Pallavi Sinha', 'pallavi@company.com', 9, 29, 110000, 12000, '2021-05-15', 'ACTIVE'),
('Ajay Thakur', 'ajay@company.com', 10, NULL, 200000, 30000, '2018-12-01', 'ACTIVE'),
('Nisha Goyal', 'nisha@company.com', 10, 31, 150000, 20000, '2020-09-01', 'ACTIVE'),
-- Duplicate salaries for ranking questions
('Ramesh Yadav', 'ramesh@company.com', 1, 2, 180000, 30000, '2020-02-01', 'ACTIVE'),
('Sunita Devi', 'sunita@company.com', 3, 11, 130000, 40000, '2021-08-01', 'ACTIVE'),
('Manoj Kumar', 'manoj@company.com', 1, 1, 200000, 40000, '2019-05-01', 'ACTIVE'),
-- NULL bonus employees
('Preeti Sharma', 'preeti@company.com', 4, 15, 135000, NULL, '2022-03-01', 'ACTIVE'),
('Anil Mehta', 'anil@company.com', 6, 20, 140000, NULL, '2022-07-01', 'ACTIVE'),
('Rekha Singh', 'rekha@company.com', 1, 3, 150000, 0, '2023-01-15', 'ACTIVE');

-- Generate remaining employees (39-500)
INSERT INTO employees (name, email, dept_id, manager_id, salary, bonus, hire_date, status)
SELECT
    'Employee_' || i,
    'emp' || i || '@company.com',
    1 + (i % 10),
    CASE WHEN i % 10 = 0 THEN NULL ELSE (1 + (i % 30)) END,
    (80000 + (i * 317) % 200000)::decimal(10,2),
    CASE WHEN i % 7 = 0 THEN NULL ELSE (5000 + (i * 131) % 50000)::decimal(10,2) END,
    '2018-01-01'::date + ((i * 7) % 2200 || ' days')::interval,
    (ARRAY['ACTIVE','ACTIVE','ACTIVE','ACTIVE','INACTIVE','ON_LEAVE'])[1 + (i % 6)]
FROM generate_series(39, 500) AS i;

-- ============ CUSTOMERS (2000) ============
-- First 30 hand-crafted
INSERT INTO customers (name, email, phone, city, country, created_at, is_premium) VALUES
('Aarav Mehta', 'aarav@email.com', '9876543210', 'Mumbai', 'India', '2022-01-15', TRUE),
('Diya Sharma', 'diya@email.com', '9876543211', 'Delhi', 'India', '2022-02-20', FALSE),
('Vihaan Patel', 'vihaan@email.com', '9876543212', 'Bangalore', 'India', '2022-03-10', TRUE),
('Anaya Singh', 'anaya@email.com', '9876543213', 'Chennai', 'India', '2022-04-05', FALSE),
('Aditya Kumar', 'aditya@email.com', '9876543214', 'Hyderabad', 'India', '2022-05-12', TRUE),
('Isha Gupta', 'isha.g@email.com', '9876543215', 'Pune', 'India', '2022-06-18', FALSE),
('Arjun Reddy', 'arjun.r@email.com', '9876543216', 'Mumbai', 'India', '2022-07-22', TRUE),
('Myra Joshi', 'myra@email.com', '9876543217', 'Kolkata', 'India', '2022-08-30', FALSE),
('Kabir Das', 'kabir@email.com', '9876543218', 'Jaipur', 'India', '2022-09-14', FALSE),
('Saanvi Nair', 'saanvi@email.com', '9876543219', 'Kochi', 'India', '2022-10-01', TRUE),
('Reyansh Iyer', 'reyansh@email.com', NULL, 'Bangalore', 'India', '2022-11-05', FALSE),
('Kiara Kapoor', 'kiara@email.com', '9876543221', 'Delhi', 'India', '2022-12-10', TRUE),
('John Smith', 'john@email.com', '+14155551234', 'San Francisco', 'USA', '2022-03-01', TRUE),
('Emma Wilson', 'emma@email.com', '+14155551235', 'New York', 'USA', '2022-06-15', FALSE),
('James Brown', 'james@email.com', '+442071234567', 'London', 'UK', '2022-09-01', TRUE),
('Sophie Martin', 'sophie@email.com', '+33142123456', 'Paris', 'France', '2023-01-10', FALSE),
('Yuki Tanaka', 'yuki@email.com', '+81312345678', 'Tokyo', 'Japan', '2023-04-20', TRUE),
-- Customers with no orders (for LEFT JOIN questions)
('Riya Chopra', 'riya@email.com', '9876543230', 'Mumbai', 'India', '2024-01-01', FALSE),
('Karan Oberoi', 'karan@email.com', '9876543231', 'Delhi', 'India', '2024-01-15', FALSE),
('Zara Khan', 'zara@email.com', NULL, 'Hyderabad', 'India', '2024-02-01', FALSE);

-- Generate remaining customers (21-2000)
INSERT INTO customers (name, email, phone, city, country, created_at, is_premium)
SELECT
    'Customer_' || i,
    'customer' || i || '@email.com',
    CASE WHEN i % 8 = 0 THEN NULL ELSE '98' || LPAD((10000000 + i)::text, 8, '0') END,
    (ARRAY['Mumbai','Delhi','Bangalore','Chennai','Hyderabad','Pune','Kolkata','Jaipur','Ahmedabad','Lucknow','Gurugram','Noida','Chandigarh','Kochi','Indore'])[1 + (i % 15)],
    (ARRAY['India','India','India','India','India','India','India','India','USA','UK','France','Japan','Germany','Singapore','UAE'])[1 + (i % 15)],
    '2021-01-01'::timestamp + ((i * 13) % 1100 || ' days')::interval,
    (i % 7 = 0)
FROM generate_series(21, 2000) AS i;

-- ============ PRODUCTS (500) ============
-- First 30 hand-crafted
INSERT INTO products (name, category, price, cost, stock, rating, created_at, is_active) VALUES
('iPhone 15', 'Electronics', 79999, 60000, 50, 4.5, '2023-09-01', TRUE),
('Samsung Galaxy S24', 'Electronics', 69999, 52000, 75, 4.3, '2024-01-15', TRUE),
('MacBook Air M3', 'Electronics', 114999, 85000, 30, 4.7, '2023-11-01', TRUE),
('Sony WH-1000XM5', 'Electronics', 29999, 18000, 100, 4.6, '2023-06-01', TRUE),
('iPad Air', 'Electronics', 59999, 42000, 40, 4.4, '2023-03-15', TRUE),
('Dell XPS 15', 'Electronics', 129999, 95000, 20, 4.2, '2023-07-01', TRUE),
('AirPods Pro', 'Electronics', 24999, 15000, 200, 4.5, '2023-09-15', TRUE),
('Kindle Paperwhite', 'Electronics', 13999, 8000, 150, 4.6, '2022-10-01', TRUE),
('Nike Air Max', 'Footwear', 12999, 5000, 80, 4.3, '2023-04-01', TRUE),
('Adidas Ultraboost', 'Footwear', 15999, 6500, 60, 4.4, '2023-05-15', TRUE),
('Puma RS-X', 'Footwear', 8999, 3500, 100, 4.0, '2023-06-01', TRUE),
('Levi''s 501', 'Clothing', 3999, 1500, 200, 4.2, '2023-01-15', TRUE),
('Allen Solly Shirt', 'Clothing', 1999, 800, 300, 4.0, '2023-02-01', TRUE),
('Van Heusen Blazer', 'Clothing', 5999, 2500, 50, 4.1, '2023-03-01', TRUE),
('Boat Rockerz 450', 'Electronics', 1499, 600, 500, 3.8, '2023-01-01', TRUE),
('JBL Flip 6', 'Electronics', 9999, 5500, 80, 4.4, '2023-04-15', TRUE),
('Samsung 55" TV', 'Electronics', 54999, 38000, 25, 4.3, '2023-08-01', TRUE),
('Dyson V15', 'Home', 52999, 35000, 15, 4.7, '2023-05-01', TRUE),
('Instant Pot', 'Home', 8999, 4000, 120, 4.5, '2023-02-15', TRUE),
('Prestige Cooker', 'Home', 2499, 1200, 200, 4.3, '2022-06-01', TRUE),
('Nokia 3310 Reboot', 'Electronics', 3999, 2000, 0, 3.5, '2020-01-01', FALSE),
('PS5 Console', 'Electronics', 49999, 40000, 0, 4.8, '2023-11-15', TRUE),
('Rolex Submariner', 'Luxury', 850000, 600000, 5, 4.9, '2023-01-01', TRUE),
('Louis Vuitton Bag', 'Luxury', 120000, 70000, 10, 4.6, '2023-06-01', TRUE),
('Atomic Habits', 'Books', 499, 200, 500, 4.7, '2022-01-01', TRUE),
('System Design Interview', 'Books', 699, 300, 300, 4.5, '2022-06-01', TRUE),
('Clean Code', 'Books', 599, 250, 250, 4.4, '2022-03-01', TRUE),
('DDIA', 'Books', 799, 350, 200, 4.8, '2022-09-01', TRUE),
('Cricket Bat SG', 'Sports', 4999, 2000, 100, 4.3, '2023-03-01', TRUE),
('Yoga Mat', 'Sports', 999, 400, 300, 4.1, '2023-01-15', TRUE);

-- Generate remaining products (31-500)
INSERT INTO products (name, category, price, cost, stock, rating, is_active)
SELECT
    (ARRAY['Widget','Gadget','Tool','Device','Accessory','Kit','Pack','Set','Pro','Ultra'])[1 + (i % 10)]
        || ' ' || chr(64 + (i % 26 + 1)) || '-' || i,
    (ARRAY['Electronics','Clothing','Home','Books','Footwear','Sports','Beauty','Grocery','Toys','Automotive'])[1 + (i % 10)],
    (200 + (i * 73) % 100000)::decimal(10,2),
    (100 + (i * 37) % 50000)::decimal(10,2),
    (i * 3) % 500,
    (3.0 + (i % 20) * 0.1)::decimal(2,1),
    (i % 20 != 0)
FROM generate_series(31, 500) AS i;

-- ============ ORDERS (10,000) ============
INSERT INTO orders (customer_id, order_date, status, total_amount, discount, shipping_city)
SELECT
    1 + (i % 1500),  -- spread across first 1500 customers (some customers have 0 orders)
    '2022-01-01'::date + ((i * 3) % 1095 || ' days')::interval,  -- 3 years of data
    (ARRAY['PENDING','CONFIRMED','SHIPPED','DELIVERED','DELIVERED','DELIVERED','DELIVERED','CANCELLED','RETURNED'])[1 + (i % 9)],
    (500 + (i * 137) % 80000)::decimal(10,2),
    CASE WHEN i % 4 = 0 THEN (50 + (i * 7) % 2000)::decimal ELSE 0 END,
    (ARRAY['Mumbai','Delhi','Bangalore','Chennai','Hyderabad','Pune','Kolkata','Jaipur','Ahmedabad','Lucknow','Gurugram','Noida','Kochi','Indore','Chandigarh'])[1 + (i % 15)]
FROM generate_series(1, 10000) AS i;

-- ============ ORDER ITEMS (30,000) ============
-- ~3 items per order on average
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    1 + (i % 10000),
    1 + (i % 500),
    1 + (i % 5),
    p.price
FROM generate_series(1, 30000) AS i
JOIN products p ON p.id = 1 + (i % 500)
WHERE p.id IS NOT NULL;

-- ============ PAYMENTS (10,000) ============
INSERT INTO payments (order_id, amount, method, status, paid_at, transaction_ref)
SELECT
    o.id,
    o.total_amount - o.discount,
    (ARRAY['CARD','UPI','UPI','UPI','WALLET','COD','BANK_TRANSFER'])[1 + (o.id % 7)],
    CASE
        WHEN o.status = 'CANCELLED' THEN 'REFUNDED'
        WHEN o.id % 25 = 0 THEN 'FAILED'
        WHEN o.status = 'PENDING' THEN 'PENDING'
        ELSE 'SUCCESS'
    END,
    CASE WHEN o.status NOT IN ('PENDING','CANCELLED') THEN o.order_date::timestamp + interval '2 hours' END,
    'TXN' || LPAD(o.id::text, 10, '0')
FROM orders o;

-- ============ REVIEWS (5,000) ============
INSERT INTO reviews (product_id, customer_id, rating, comment, created_at)
SELECT
    1 + (i % 500),
    1 + ((i * 7) % 1500),
    1 + (i % 5),
    (ARRAY[
        'Excellent product, highly recommend!',
        'Good quality, fast delivery',
        'Decent for the price',
        'Average, nothing special',
        'Below expectations, not worth it',
        'Great value for money',
        'Poor quality, returning it',
        'Loved it! Will buy again',
        'Okay product, could be better',
        'Terrible experience, waste of money'
    ])[1 + (i % 10)],
    '2022-06-01'::timestamp + ((i * 5) % 900 || ' days')::interval
FROM generate_series(1, 5000) AS i
ON CONFLICT (product_id, customer_id) DO NOTHING;

-- ============ LOGIN LOGS (3,000+) ============
-- Customer 1: consecutive streak Jan 1-15, gap, then Jan 20-25
INSERT INTO login_logs (customer_id, login_date)
SELECT 1, '2024-01-01'::date + i FROM generate_series(0, 14) i
UNION ALL SELECT 1, '2024-01-20'::date + i FROM generate_series(0, 5) i
UNION ALL
-- Customer 2: sporadic
SELECT 2, d::date FROM unnest(ARRAY['2024-01-01','2024-01-02','2024-01-05','2024-01-06','2024-01-07','2024-01-10','2024-01-15','2024-01-16']) d
UNION ALL
-- Customer 3: every day for 2 months
SELECT 3, '2024-01-01'::date + i FROM generate_series(0, 59) i
UNION ALL
-- Customer 4: weekdays only
SELECT 4, d FROM generate_series('2024-01-01'::date, '2024-03-31'::date, '1 day') d WHERE EXTRACT(DOW FROM d) BETWEEN 1 AND 5
ON CONFLICT DO NOTHING;

-- Bulk login data for many customers
INSERT INTO login_logs (customer_id, login_date)
SELECT
    c_id,
    '2024-01-01'::date + (day_offset || ' days')::interval
FROM
    generate_series(5, 500) AS c_id,
    generate_series(0, 29) AS day_offset
WHERE
    -- Random-ish pattern: skip some days based on customer+day combo
    (c_id * 7 + day_offset * 13) % 3 != 0
ON CONFLICT DO NOTHING;

-- ============ SALARY HISTORY (1,000) ============
INSERT INTO salary_history (employee_id, old_salary, new_salary, changed_at)
SELECT
    e.id,
    e.salary - (5000 + (e.id * 131) % 20000),
    e.salary,
    e.hire_date + ((e.id * 97) % 365 || ' days')::interval
FROM employees e
WHERE e.id <= 200;

-- Second raise for some employees
INSERT INTO salary_history (employee_id, old_salary, new_salary, changed_at)
SELECT
    e.id,
    e.salary,
    e.salary + (5000 + (e.id * 73) % 30000),
    e.hire_date + ((e.id * 97) % 365 + 365 || ' days')::interval
FROM employees e
WHERE e.id <= 100;

-- ============ VERIFY COUNTS ============
-- Run these after loading to verify:
-- SELECT 'departments' as tbl, COUNT(*) FROM departments
-- UNION ALL SELECT 'employees', COUNT(*) FROM employees
-- UNION ALL SELECT 'customers', COUNT(*) FROM customers
-- UNION ALL SELECT 'products', COUNT(*) FROM products
-- UNION ALL SELECT 'orders', COUNT(*) FROM orders
-- UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
-- UNION ALL SELECT 'payments', COUNT(*) FROM payments
-- UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
-- UNION ALL SELECT 'login_logs', COUNT(*) FROM login_logs
-- UNION ALL SELECT 'salary_history', COUNT(*) FROM salary_history;
--
-- Expected:
--   departments:    10
--   employees:      500
--   customers:      2,000
--   products:       500
--   orders:         10,000
--   order_items:    ~30,000
--   payments:       10,000
--   reviews:        ~4,000 (after dedup)
--   login_logs:     ~3,500
--   salary_history: ~300
--   TOTAL:          ~58,000+ rows
