-- 03_basic_queries.sql (MySQL)
USE ecommerce_db;

-- Q1. Total revenue, orders and average order value (completed only)
SELECT COUNT(DISTINCT o.order_id)                         AS total_orders,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)         AS total_revenue,
       ROUND(SUM(oi.quantity * oi.unit_price)
             / COUNT(DISTINCT o.order_id), 2)             AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Completed';

-- Q2. Revenue and profit by category
SELECT c.category_name,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)                    AS revenue,
       ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price)), 2)   AS profit
FROM order_items oi
JOIN orders o     ON o.order_id = oi.order_id AND o.status = 'Completed'
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;

-- Q3. Top 5 best-selling products by units sold
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id AND o.status = 'Completed'
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 5;

-- Q4. Revenue by city
SELECT cu.city, ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM customers cu
JOIN orders o       ON o.customer_id = cu.customer_id AND o.status = 'Completed'
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY cu.city
ORDER BY revenue DESC;

-- Q5. Customers who never ordered
SELECT cu.customer_id, cu.full_name
FROM customers cu
LEFT JOIN orders o ON o.customer_id = cu.customer_id
WHERE o.order_id IS NULL;

-- Q6. Order status breakdown with percentage
SELECT status, COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM orders
GROUP BY status;
