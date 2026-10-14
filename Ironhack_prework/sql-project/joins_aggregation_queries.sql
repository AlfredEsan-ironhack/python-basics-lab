 .
-- SQL Joins and Aggregation Lab

-- STEP 1: EXTENDED DATABASE SETUP
 .

-- Create categories table
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT,
    description TEXT
);

-- Create order_items table
CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Add category_id to products table
ALTER TABLE products ADD COLUMN category_id INTEGER;
UPDATE products SET category_id = 1 WHERE category = 'Electronics';
UPDATE products SET category_id = 2 WHERE category = 'Furniture';

-- Insert categories
INSERT INTO categories VALUES
(1, 'Electronics', 'Electronic devices and accessories'),
(2, 'Furniture', 'Office and home furniture');

-- Insert order_items
INSERT INTO order_items VALUES
(1, 1, 1, 1, 999.99),
(2, 1, 2, 2, 25.50),
(3, 2, 3, 1, 79.99),
(4, 3, 1, 1, 999.99),
(5, 4, 4, 2, 299.99),
(6, 5, 2, 5, 25.50),
(7, 6, 5, 1, 199.99),
(8, 7, 3, 3, 79.99);

 .
-- STEP 3: INNER JOIN QUERIES
 .

-- Task 1: Join customers and orders
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- Task 2: Join multiple tables 
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id;

-- Task 3: Join products with categories

SELECT 
    p.product_name,
    c.category_name,
    p.price,
    p.stock_quantity
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id;

 .
-- STEP 4: LEFT JOIN QUERIES
 .

-- Task 1: Find customers without orders

SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Task 2: Find products never ordered

SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(oi.order_item_id) AS times_ordered
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY times_ordered ASC;

-- Task 3: Complete customer order history

SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY total_spent DESC;

 .
-- STEP 5: RIGHT JOIN SIMULATION (SQLite doesn't support RIGHT JOIN)
 .

-- Simulate RIGHT JOIN with LEFT JOIN (reversed table order)

SELECT 
    o.order_id,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_date,
    o.total_amount
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;

-- Simulate FULL OUTER JOIN using UNION

SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
UNION
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

 .
-- STEP 6: BASIC AGGREGATION FUNCTIONS
 .

-- Task 1: Count total number of customers
SELECT COUNT(*) AS total_customers FROM customers;

-- Task 2: Count total number of orders
SELECT COUNT(*) AS total_orders FROM orders;

-- Task 3: Count orders per customer
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Task 4: Calculate total revenue from all orders
SELECT SUM(total_amount) AS total_revenue FROM orders;

-- Task 5: Calculate total quantity of products ordered
SELECT SUM(quantity) AS total_quantity_ordered FROM order_items;

-- Task 6: Calculate average order amount
SELECT AVG(total_amount) AS average_order_amount FROM orders;

-- Task 7: Calculate average quantity per order
SELECT AVG(quantity) AS average_quantity_per_order FROM order_items;

-- Task 8: Find the most expensive order
SELECT 
    order_id,
    total_amount,
    order_date
FROM orders
WHERE total_amount = (SELECT MAX(total_amount) FROM orders);

-- Task 9: Find the least expensive order
SELECT 
    order_id,
    total_amount,
    order_date
FROM orders
WHERE total_amount = (SELECT MIN(total_amount) FROM orders);

-- Task 10: Find the earliest and latest order dates
SELECT 
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM orders;

 .
-- STEP 7: GROUP BY QUERIES
 .

-- Task 1: Count orders per customer
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Task 2: Calculate total revenue per customer
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(o.total_amount) AS total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- Task 3: Count products per category
SELECT 
    ca.category_name,
    COUNT(p.product_id) AS product_count
FROM categories ca
LEFT JOIN products p ON ca.category_id = p.category_id
GROUP BY ca.category_id, ca.category_name;

-- Task 4: Calculate total revenue per category
SELECT 
    ca.category_name,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM categories ca
LEFT JOIN products p ON ca.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY ca.category_id, ca.category_name
ORDER BY total_revenue DESC;

-- Task 5: Count orders per country
SELECT 
    c.country,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS country_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country
ORDER BY country_revenue DESC;

 .
-- STEP 8: HAVING CLAUSE QUERIES
 .

-- Task 1: Find customers who have placed more than 2 orders
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > 2;

-- Task 2: Find categories with total revenue greater than 1000
SELECT 
    ca.category_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM categories ca
LEFT JOIN products p ON ca.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY ca.category_id, ca.category_name
HAVING SUM(oi.quantity * oi.unit_price) > 1000;

-- Task 3: Find customers with average order amount greater than 500
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count,
    AVG(o.total_amount) AS average_order_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING AVG(o.total_amount) > 500;

-- Task 4: Find customers from USA who have placed more than 1 order
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'USA'
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
HAVING COUNT(o.order_id) > 1;

 .
-- STEP 9: COMPLEX QUERIES - COMBINING CONCEPTS
 .

-- Task 1: Customer
-- For each customer: name, total orders, total spent, average order amount
-- Include customers with no orders (show 0)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    CASE 
        WHEN COUNT(o.order_id) = 0 THEN 0
        ELSE AVG(o.total_amount)
    END AS average_order_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY total_spent DESC;

-- Task 2: Product performance
-- For each product: name, category, total quantity sold, total revenue
SELECT 
    p.product_id,
    p.product_name,
    ca.category_name,
    COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM products p
LEFT JOIN categories ca ON p.category_id = ca.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, ca.category_name
ORDER BY total_revenue DESC;

-- Task 3: Category analysis
-- For each category: name, number of products, total revenue, average product price
SELECT 
    ca.category_id,
    ca.category_name,
    COUNT(DISTINCT p.product_id) AS number_of_products,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue,
    AVG(p.price) AS average_product_price
FROM categories ca
LEFT JOIN products p ON ca.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY ca.category_id, ca.category_name
ORDER BY total_revenue DESC;

-- Task 4: Customer segmentation
-- Categorize customers as High/Medium/Low value based on total spent
SELECT 
    CASE 
        WHEN SUM(o.total_amount) > 1000 THEN 'High Value'
        WHEN SUM(o.total_amount) >= 500 THEN 'Medium Value'
        WHEN SUM(o.total_amount) > 0 THEN 'Low Value'
        ELSE 'No Orders'
    END AS customer_segment,
    COUNT(DISTINCT c.customer_id) AS customer_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_segment
ORDER BY customer_segment;