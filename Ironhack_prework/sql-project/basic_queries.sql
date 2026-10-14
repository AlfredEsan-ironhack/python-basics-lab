
-- Basic SQL Queries Lab


-- STEP 1: DATABASE SETUP


CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    city TEXT,
    country TEXT,
    registration_date DATE
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    price DECIMAL(10, 2),
    stock_quantity INTEGER
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product_id INTEGER,
    order_date DATE,
    quantity INTEGER,
    total_amount DECIMAL(10, 2),
    status TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO customers VALUES
(1, 'John', 'Doe', 'john.doe@email.com', 'New York', 'USA', '2023-01-15'),
(2, 'Jane', 'Smith', 'JANE.SMITH@EMAIL.COM', 'London', 'UK', '2023-02-20'),
(3, 'Bob', 'Johnson', 'bob@email.com', 'Toronto', 'Canada', '2023-03-10'),
(4, 'Alice', 'Brown', NULL, 'Sydney', 'Australia', '2023-04-05'),
(5, 'Charlie', 'Wilson', 'charlie.wilson@email.com', 'Berlin', 'Germany', NULL);

INSERT INTO products VALUES
(1, 'Laptop', 'Electronics', 999.99, 50),
(2, 'Mouse', 'Electronics', 25.50, 200),
(3, 'Keyboard', 'Electronics', 79.99, 150),
(4, 'Monitor', 'Electronics', 299.99, 75),
(5, 'Desk Chair', 'Furniture', 199.99, 30);

INSERT INTO orders VALUES
(1, 1, 1, '2024-01-15', 1, 999.99, 'completed'),
(2, 1, 2, '2024-01-16', 2, 51.00, 'completed'),
(3, 2, 3, '2024-02-01', 1, 79.99, 'pending'),
(4, 3, 1, '2024-02-10', 1, 999.99, 'completed'),
(5, 2, 4, '2024-02-15', 2, 599.98, 'completed'),
(6, 4, 2, '2024-03-01', 5, 127.50, 'completed'),
(7, 1, 5, '2024-03-05', 1, 199.99, 'pending'),
(8, 3, 3, '2024-03-10', 3, 239.97, NULL);


-- STEP 2: BASIC SELECT QUERIES


-- Task 1: Select all customers (retrieve all columns)
SELECT * FROM customers;

-- Task 2: Select specific columns
SELECT customer_id, first_name, last_name, email FROM customers;

-- Task 3: Select with aliases
SELECT customer_id AS ID, 
       first_name AS 'First Name', 
       last_name AS 'Last Name' 
FROM customers;


-- STEP 3: FILTERING WITH WHERE


-- Task 1: Filter by single condition - Find all customers from USA
SELECT * FROM customers 
WHERE country = 'USA';

-- Task 2: Filter with multiple conditions - Find completed orders > 100
SELECT * FROM orders 
WHERE status = 'completed' 
AND total_amount > 100;

-- Task 3: Filter with IN - Find products in Electronics or Furniture
SELECT * FROM products 
WHERE category IN ('Electronics', 'Furniture');

-- Task 4: Filter with LIKE - Find customers with @email.com
SELECT * FROM customers 
WHERE email LIKE '%@email.com%';

-- Task 5: Filter with date range - Orders in February 2024
SELECT * FROM orders 
WHERE order_date >= '2024-02-01' 
AND order_date <= '2024-02-29';


-- STEP 4: HANDLING NULL VALUES


-- Task 1: Find all customers with NULL email addresses
SELECT * FROM customers 
WHERE email IS NULL;

-- Task 2: Find all customers with non-NULL registration dates
SELECT * FROM customers 
WHERE registration_date IS NOT NULL;

-- Task 3: Find all orders where status is NULL
SELECT * FROM orders 
WHERE status IS NULL;

-- Task 4: Use COALESCE - Display 'Unknown' if status is NULL
SELECT order_id, customer_id, product_id, 
       COALESCE(status, 'Unknown') AS status_display 
FROM orders;


-- STEP 5: TEXT CLEANING FUNCTIONS


-- Task 1: LOWER function - Select all customer emails in lowercase
SELECT customer_id, LOWER(email) AS email_lowercase 
FROM customers;

-- Task 2: UPPER function - Select all customer cities in uppercase
SELECT customer_id, UPPER(city) AS city_uppercase 
FROM customers;

-- Task 3: TRIM function - Remove leading/trailing spaces from product names
SELECT product_id, TRIM(product_name) AS product_name_trimmed 
FROM products;

-- Task 4: CONCAT function - Create full name
SELECT customer_id, 
       first_name || ' ' || last_name AS full_name 
FROM customers;


-- STEP 6: DATA TYPE CONVERSION


-- Task 1: Convert customer_id to TEXT
SELECT CAST(customer_id AS TEXT) AS customer_id_text, 
       first_name, last_name 
FROM customers;

-- Task 2: Ensure total_amount displayed as DECIMAL with 2 places
SELECT order_id, 
       CAST(total_amount AS DECIMAL(10, 2)) AS total_formatted 
FROM orders;

-- Task 3: Select order_date as string
SELECT order_id, 
       CAST(order_date AS TEXT) AS order_date_string 
FROM orders;


-- STEP 7: COMBINING FUNCTIONS


-- Task 1: Clean email format - lowercase and trimmed
SELECT customer_id, 
       LOWER(TRIM(email)) AS email_clean 
FROM customers;

-- Task 2: Format customer display - "Last Name, First Name (Email)"
SELECT customer_id,
       last_name || ', ' || first_name || ' (' || 
       COALESCE(LOWER(email), 'no-email') || ')' AS customer_display
FROM customers;

-- Task 3: Calculate and format - "Quantity x Price = Total"
SELECT order_id,
       quantity || ' x $' || CAST(total_amount AS TEXT) || ' = $' || 
       CAST(total_amount AS TEXT) AS order_calculation
FROM orders;


-- STEP 8: SORTING AND LIMITING RESULTS


-- Task 1: Sort customers by last_name alphabetically
SELECT * FROM customers 
ORDER BY last_name ASC;

-- Task 2: Sort orders by date (descending) then amount (descending)
SELECT * FROM orders 
ORDER BY order_date DESC, total_amount DESC;

-- Task 3: Top 3 most expensive orders
SELECT * FROM orders 
ORDER BY total_amount DESC 
LIMIT 3;

