-- SQL Practice Project — Schema
-- Run: psql -U postgres -f schema.sql

DROP DATABASE IF EXISTS sql_practice;
CREATE DATABASE sql_practice;
\c sql_practice;

-- Departments
CREATE TABLE departments (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    budget      DECIMAL(12,2),
    location    VARCHAR(50)
);

-- Employees (self-referencing for manager hierarchy)
CREATE TABLE employees (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    dept_id     INT REFERENCES departments(id),
    manager_id  INT REFERENCES employees(id),
    salary      DECIMAL(10,2) NOT NULL,
    bonus       DECIMAL(10,2) DEFAULT NULL,
    hire_date   DATE NOT NULL,
    status      VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','ON_LEAVE'))
);

-- Customers
CREATE TABLE customers (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    phone       VARCHAR(20),
    city        VARCHAR(50),
    country     VARCHAR(50) DEFAULT 'India',
    created_at  TIMESTAMP DEFAULT NOW(),
    is_premium  BOOLEAN DEFAULT FALSE
);

-- Products
CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    category    VARCHAR(50) NOT NULL,
    price       DECIMAL(10,2) NOT NULL CHECK (price > 0),
    cost        DECIMAL(10,2),
    stock       INT DEFAULT 0,
    rating      DECIMAL(2,1) DEFAULT 0,
    created_at  TIMESTAMP DEFAULT NOW(),
    is_active   BOOLEAN DEFAULT TRUE
);

-- Orders
CREATE TABLE orders (
    id              SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES customers(id),
    order_date      DATE NOT NULL,
    status          VARCHAR(20) NOT NULL CHECK (status IN ('PENDING','CONFIRMED','SHIPPED','DELIVERED','CANCELLED','RETURNED')),
    total_amount    DECIMAL(10,2),
    discount        DECIMAL(10,2) DEFAULT 0,
    shipping_city   VARCHAR(50),
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Order Items (many-to-many: orders <-> products)
CREATE TABLE order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INT NOT NULL REFERENCES orders(id),
    product_id  INT NOT NULL REFERENCES products(id),
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10,2) NOT NULL
);

-- Payments
CREATE TABLE payments (
    id              SERIAL PRIMARY KEY,
    order_id        INT NOT NULL REFERENCES orders(id),
    amount          DECIMAL(10,2) NOT NULL,
    method          VARCHAR(20) NOT NULL CHECK (method IN ('CARD','UPI','WALLET','COD','BANK_TRANSFER')),
    status          VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS','FAILED','PENDING','REFUNDED')),
    paid_at         TIMESTAMP,
    transaction_ref VARCHAR(50)
);

-- Reviews
CREATE TABLE reviews (
    id          SERIAL PRIMARY KEY,
    product_id  INT NOT NULL REFERENCES products(id),
    customer_id INT NOT NULL REFERENCES customers(id),
    rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP DEFAULT NOW(),
    UNIQUE(product_id, customer_id)  -- one review per customer per product
);

-- Login logs (for consecutive days / gaps & islands problems)
CREATE TABLE login_logs (
    id          SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id),
    login_date  DATE NOT NULL,
    UNIQUE(customer_id, login_date)
);

-- Salary history (for temporal / change tracking queries)
CREATE TABLE salary_history (
    id          SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(id),
    old_salary  DECIMAL(10,2),
    new_salary  DECIMAL(10,2) NOT NULL,
    changed_at  DATE NOT NULL
);

-- Indexes for performance section
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_login_logs_customer_date ON login_logs(customer_id, login_date);
