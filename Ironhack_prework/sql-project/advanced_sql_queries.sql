 .
-- Advanced SQL Techniques Lab

-- STEP 1: ENHANCED DATABASE SETUP
 .

INSERT INTO orders VALUES
(9, 1, 2, '2023-12-01', 1, 25.50, 'completed'),
(10, 2, 1, '2023-12-15', 1, 999.99, 'completed'),
(11, 3, 4, '2024-01-05', 1, 299.99, 'completed'),
(12, 4, 3, '2024-01-20', 2, 159.98, 'completed'),
(13, 5, 5, '2024-02-01', 1, 199.99, 'completed');

CREATE TABLE customer_segments (
    segment_id INTEGER PRIMARY KEY,
    segment_name TEXT,
    min_spend DECIMAL(10, 2),
    max_spend DECIMAL(10, 2)
);

INSERT INTO customer_segments VALUES
(1, 'Bronze', 0, 500),
(2, 'Silver', 500, 1000),
(3, 'Gold', 1000, 5000),
(4, 'Platinum', 5000, 999999);

 .
-- STEP 2: SCALAR SUBQUERIES
 .

-- Task 1: Find all orders greater than average order amount
SELECT 
    o.order_id,
    o.customer_id,
    o.total_amount,
    (SELECT AVG(total_amount) FROM orders) AS avg_order_amount,
    ROUND(o.total_amount - (SELECT AVG(total_amount) FROM orders), 2) AS difference_from_avg
FROM orders o
WHERE o.total_amount > (SELECT AVG(total_amount) FROM orders)
ORDER BY o.total_amount DESC;

-- Task 2: For each order, show customer's registration date
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.total_amount,
    (SELECT registration_date FROM customers WHERE customer_id = o.customer_id) AS customer_registration_date
FROM orders o;

-- Task 3: Find products priced above average
SELECT 
    product_id,
    product_name,
    price,
    (SELECT AVG(price) FROM products) AS avg_product_price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;

 .
-- STEP 3: INLINE SUBQUERIES (DERIVED TABLES)
 .

-- Task 1: Top 3 customers by total spending
SELECT 
    customer_name,
    total_spent,
    order_count
FROM (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
) AS customer_spending
ORDER BY total_spent DESC
LIMIT 3;

-- Task 2: Compare customer spending to category averages
SELECT 
    cs.customer_name,
    cs.total_spent,
    ca.category_avg_revenue
FROM (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
) AS cs
CROSS JOIN (
    SELECT AVG(category_revenue) AS category_avg_revenue
    FROM (
        SELECT 
            cat.category_name,
            SUM(oi.quantity * oi.unit_price) AS category_revenue
        FROM categories cat
        LEFT JOIN products p ON cat.category_id = p.category_id
        LEFT JOIN order_items oi ON p.product_id = oi.product_id
        GROUP BY cat.category_id, cat.category_name
    ) AS cat_revenue
) AS ca;

-- Task 3: Find customers above average spending
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
HAVING SUM(o.total_amount) > (SELECT AVG(total_spent) FROM (
    SELECT SUM(o2.total_amount) AS total_spent
    FROM customers c2
    LEFT JOIN orders o2 ON c2.customer_id = o2.customer_id
    GROUP BY c2.customer_id
))
ORDER BY total_spent DESC;

 .
-- STEP 4: CORRELATED SUBQUERIES
 .

-- Task 1: For each customer, find orders above their personal average
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    (SELECT AVG(o2.total_amount) FROM orders o2 WHERE o2.customer_id = c.customer_id) AS customer_avg_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > (
    SELECT AVG(o2.total_amount) 
    FROM orders o2 
    WHERE o2.customer_id = c.customer_id
)
ORDER BY c.customer_id, o.total_amount DESC;

-- Task 2: Find customers with at least one order (using EXISTS)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;

-- Task 3: For each category, find products above category average price
SELECT 
    p.product_id,
    p.product_name,
    ca.category_name,
    p.price,
    (SELECT AVG(p2.price) FROM products p2 WHERE p2.category_id = ca.category_id) AS category_avg_price
FROM products p
LEFT JOIN categories ca ON p.category_id = ca.category_id
WHERE p.price > (
    SELECT AVG(p2.price) 
    FROM products p2 
    WHERE p2.category_id = ca.category_id
)
ORDER BY ca.category_name, p.price DESC;

 .
-- STEP 5: COMMON TABLE EXPRESSIONS (CTEs)
 .

-- Task 1: Customer spending CTE to find high-value customers
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.country,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT 
    customer_name,
    country,
    order_count,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent > 500 THEN 'Medium Value'
        WHEN total_spent > 0 THEN 'Low Value'
        ELSE 'No Orders'
    END AS value_segment
FROM customer_spending
ORDER BY total_spent DESC;

-- Task 2: Multiple CTEs with comprehensive report
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        ca.category_name,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    LEFT JOIN categories ca ON p.category_id = ca.category_id
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, ca.category_name
),
category_revenue AS (
    SELECT 
        category_name,
        SUM(total_revenue) AS category_total_revenue
    FROM product_sales
    GROUP BY category_name
)
SELECT 
    ps.product_name,
    ps.category_name,
    ps.total_quantity_sold,
    ps.total_revenue,
    cr.category_total_revenue,
    ROUND(ps.total_revenue * 100.0 / cr.category_total_revenue, 2) AS percent_of_category
FROM product_sales ps
LEFT JOIN category_revenue cr ON ps.category_name = cr.category_name
ORDER BY ps.category_name, ps.total_revenue DESC;

 .
-- STEP 6: WINDOW FUNCTIONS - RANKING
 .

-- Task 1: ROW_NUMBER - Assign row numbers to orders within each customer
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date ASC) AS order_sequence
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, order_sequence;

-- Task 2: RANK - Rank customers by total spending
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(o.total_amount) AS total_spent,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS spending_rank
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY spending_rank;

-- Task 3: DENSE_RANK - Rank products by total sales
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    RANK() OVER (ORDER BY SUM(oi.quantity) DESC) AS sales_rank,
    DENSE_RANK() OVER (ORDER BY SUM(oi.quantity) DESC) AS dense_sales_rank
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY sales_rank;

-- Task 4: Top 2 orders for each customer
SELECT 
    customer_id,
    customer_name,
    order_id,
    order_date,
    total_amount,
    order_rank
FROM (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        o.order_id,
        o.order_date,
        o.total_amount,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.total_amount DESC) AS order_rank
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
) AS ranked_orders
WHERE order_rank <= 2
ORDER BY customer_id, order_rank;

 .
-- STEP 7: WINDOW FUNCTIONS - VALUE FUNCTIONS
 .

-- Task 1: LAG - Show previous order date and calculate days between orders
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS previous_order_date,
    CAST(o.order_date AS INTEGER) - CAST(LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS INTEGER) AS days_since_previous_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_date;

-- Task 2: LEAD - Show next order and calculate order amount change
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    LEAD(o.total_amount) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS next_order_amount,
    LEAD(o.total_amount) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) - o.total_amount AS order_amount_change
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_date;

-- Task 3: Running total of order amounts per customer
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS running_total
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_date;

 .
-- STEP 8: CASE STATEMENTS
 .

-- Task 1: Simple CASE - Categorize orders by size
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    CASE 
        WHEN total_amount < 100 THEN 'Small'
        WHEN total_amount < 500 THEN 'Medium'
        ELSE 'Large'
    END AS order_size,
    CASE 
        WHEN total_amount < 100 THEN 1
        WHEN total_amount < 500 THEN 2
        ELSE 3
    END AS size_code
FROM orders
ORDER BY total_amount DESC;

-- Task 2: Searched CASE - Assign customer segments based on spending
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(o.total_amount) AS total_spent,
    CASE 
        WHEN SUM(o.total_amount) >= 5000 THEN 'Platinum'
        WHEN SUM(o.total_amount) >= 1000 THEN 'Gold'
        WHEN SUM(o.total_amount) >= 500 THEN 'Silver'
        WHEN SUM(o.total_amount) > 0 THEN 'Bronze'
        ELSE 'No Activity'
    END AS customer_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- Task 3: CASE in aggregation - Count orders by status
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending_orders,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS null_status_orders,
    SUM(CASE WHEN status = 'completed' THEN total_amount ELSE 0 END) AS completed_revenue,
    SUM(CASE WHEN status = 'pending' THEN total_amount ELSE 0 END) AS pending_revenue
FROM orders;

-- Task 4: Nested CASE - Complex categorization
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    status,
    CASE 
        WHEN status IS NULL THEN 'Unknown Status'
        WHEN status = 'completed' THEN 
            CASE 
                WHEN total_amount >= 1000 THEN 'High Value Completed'
                WHEN total_amount >= 500 THEN 'Medium Value Completed'
                ELSE 'Low Value Completed'
            END
        WHEN status = 'pending' THEN 'Pending Fulfillment'
        ELSE 'Other Status'
    END AS order_category
FROM orders
ORDER BY order_date DESC;

 .
-- STEP 9: ADVANCED DATA CLEANING FUNCTIONS
 .

-- Task 1: String manipulation - Extract and clean data
SELECT 
    customer_id,
    email,
    SUBSTR(email, INSTR(email, '@') + 1) AS email_domain,
    first_name || ' ' || last_name AS full_name,
    SUBSTR(first_name || ' ' || last_name, 1, INSTR(first_name || ' ' || last_name, ' ') - 1) AS first_name_extracted,
    REPLACE(product_name, ' ', '_') AS product_name_underscore
FROM customers c
LEFT JOIN products p ON 1=1
WHERE p.product_id = 1
LIMIT 1;

-- Task 2: Date functions - Calculate tenure and extract date parts
SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    registration_date,
    DATE('now') AS current_date,
    CAST(JULIANDAY('now') - JULIANDAY(registration_date) AS INTEGER) AS days_since_registration,
    CAST((CAST(JULIANDAY('now') - JULIANDAY(registration_date) AS INTEGER) / 365.25) AS INTEGER) AS years_since_registration
FROM customers
WHERE registration_date IS NOT NULL
ORDER BY days_since_registration DESC;

-- Task 3: Numeric functions - Round and calculate percentages
SELECT 
    order_id,
    total_amount,
    ROUND(total_amount, 0) AS rounded_to_nearest_dollar,
    ROUND(total_amount / 10) * 10 AS rounded_to_nearest_10,
    SUM(total_amount) OVER () AS total_all_orders,
    ROUND(total_amount * 100.0 / SUM(total_amount) OVER (), 2) AS percent_of_total
FROM orders
ORDER BY total_amount DESC;

-- Task 4: NULL handling - Replace nulls and count
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    COALESCE(email, 'no-email@unknown.com') AS email_with_default,
    registration_date,
    COALESCE(registration_date, '1900-01-01') AS registration_with_default,
    CASE WHEN email IS NULL THEN 'Missing' ELSE 'Valid' END AS email_status,
    CASE WHEN registration_date IS NULL THEN 'Missing' ELSE 'Valid' END AS registration_status
FROM customers
ORDER BY customer_id;

 .
-- STEP 10: COMPLEX QUERIES - COMBINING TECHNIQUES
 .

-- Task 1: Customer segment analysis with ranking and CASE
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.country,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS total_spent,
        AVG(o.total_amount) AS avg_order_amount,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT 
    customer_id,
    customer_name,
    country,
    order_count,
    total_spent,
    avg_order_amount,
    first_order_date,
    last_order_date,
    CASE 
        WHEN total_spent >= 1000 THEN 'Gold'
        WHEN total_spent >= 500 THEN 'Silver'
        WHEN total_spent > 0 THEN 'Bronze'
        ELSE 'No Orders'
    END AS segment,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank,
    RANK() OVER (ORDER BY order_count DESC) AS order_frequency_rank
FROM customer_metrics
ORDER BY total_spent DESC;

-- Task 2: Product performance dashboard
WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        ca.category_name,
        p.price,
        COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
    FROM products p
    LEFT JOIN categories ca ON p.category_id = ca.category_id
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, ca.category_name, p.price
)
SELECT 
    product_id,
    product_name,
    category_name,
    price,
    total_quantity_sold,
    total_revenue,
    CASE 
        WHEN total_revenue > 1000 THEN 'High Performer'
        WHEN total_revenue > 500 THEN 'Medium Performer'
        WHEN total_revenue > 0 THEN 'Low Performer'
        ELSE 'No Sales'
    END AS performance_category,
    RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rank_in_category,
    RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank
FROM product_metrics
ORDER BY total_revenue DESC;

-- Task 3: Customer journey analysis
WITH customer_orders AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        o.order_id,
        o.order_date,
        o.total_amount,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS order_sequence,
        LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS previous_order_date,
        LEAD(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS next_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
)
SELECT 
    customer_id,
    customer_name,
    order_id,
    order_date,
    total_amount,
    order_sequence,
    CASE 
        WHEN order_sequence = 1 THEN 'First Time'
        ELSE 'Repeat'
    END AS customer_type,
    CAST(order_date AS INTEGER) - CAST(previous_order_date AS INTEGER) AS days_since_previous,
    CAST(next_order_date AS INTEGER) - CAST(order_date AS INTEGER) AS days_until_next
FROM customer_orders
WHERE order_id IS NOT NULL
ORDER BY customer_id, order_sequence;

 .
-- STEP 11: OPTIMIZATION NOTES
 .

-- Performance Considerations:
-- 1. CTEs vs Subqueries: CTEs are more readable but not always faster
--    Use CTEs for readability when performance is similar
--    Use joins instead of correlated subqueries when possible
-- 2. Window Functions: Efficient for calculations across groups
--    Better than self-joins for ranking and running totals
--    Partition wisely to avoid processing unnecessary data
-- 3. Indexes: Would improve performance on:
--    customer_id (used in many joins)
--    order_date (used in sorting and filtering)
--    category_id (used in grouping)
-- 4. Query Optimization: 
--    Filter early with WHERE clauses before aggregation
--    Use LIMIT when you only need top N results
--    Avoid functions on indexed columns in WHERE clauses
