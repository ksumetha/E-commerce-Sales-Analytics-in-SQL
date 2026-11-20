-- 04_advanced_analytics.sql (MySQL 8.0+)
USE ecommerce_db;

-- A1. Monthly revenue with month-over-month growth
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
           SUM(oi.quantity * oi.unit_price)   AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT order_month,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
             / LAG(revenue) OVER (ORDER BY order_month), 1) AS mom_growth_pct,
       ROUND(SUM(revenue) OVER (ORDER BY order_month), 2)   AS running_total
FROM monthly;

-- A2. Top product in each category
WITH sales AS (
    SELECT c.category_name, p.product_name,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN orders o     ON o.order_id = oi.order_id AND o.status = 'Completed'
    JOIN products p   ON p.product_id = oi.product_id
    JOIN categories c ON c.category_id = p.category_id
    GROUP BY c.category_name, p.product_name
),
ranked AS (
    SELECT category_name, product_name, revenue,
           RANK() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS rnk
    FROM sales
)
SELECT category_name, product_name, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rnk = 1;

-- A3. Customer lifetime value (top 10)
SELECT cu.customer_id, cu.full_name,
       COUNT(DISTINCT o.order_id)                 AS orders,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS lifetime_value,
       DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS spend_rank
FROM customers cu
JOIN orders o       ON o.customer_id = cu.customer_id AND o.status = 'Completed'
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY cu.customer_id, cu.full_name
ORDER BY lifetime_value DESC
LIMIT 10;

-- A4. RFM segmentation (Recency, Frequency, Monetary)
WITH rfm_base AS (
    SELECT o.customer_id,
           DATEDIFF('2025-12-31', MAX(o.order_date)) AS recency_days,
           COUNT(DISTINCT o.order_id)                AS frequency,
           SUM(oi.quantity * oi.unit_price)          AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY o.customer_id
),
scored AS (
    SELECT customer_id, recency_days, frequency, monetary,
           NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(4) OVER (ORDER BY frequency)         AS f_score,
           NTILE(4) OVER (ORDER BY monetary)          AS m_score
    FROM rfm_base
)
SELECT customer_id, recency_days, frequency,
       ROUND(monetary, 2) AS monetary,
       r_score, f_score, m_score,
       CASE
         WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champion'
         WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal'
         WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
         WHEN r_score = 1  AND f_score = 1                   THEN 'Lost'
         ELSE 'Regular'
       END AS segment
FROM scored
ORDER BY monetary DESC;

-- A5. Cohort retention (months 0-3 after signup)
WITH cohort AS (
    SELECT customer_id,
           DATE_FORMAT(signup_date, '%Y-%m-01') AS cohort_month
    FROM customers
),
activity AS (
    SELECT DISTINCT o.customer_id,
           DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month
    FROM orders o
    WHERE o.status = 'Completed'
),
joined AS (
    SELECT c.cohort_month, c.customer_id,
           TIMESTAMPDIFF(MONTH, c.cohort_month, a.order_month) AS month_number
    FROM cohort c
    JOIN activity a ON a.customer_id = c.customer_id
),
sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohort
    GROUP BY cohort_month
)
SELECT DATE_FORMAT(j.cohort_month, '%Y-%m') AS cohort_month,
       s.cohort_size,
       j.month_number,
       COUNT(DISTINCT j.customer_id) AS active_customers,
       ROUND(100.0 * COUNT(DISTINCT j.customer_id) / s.cohort_size, 1) AS retention_pct
FROM joined j
JOIN sizes s ON s.cohort_month = j.cohort_month
WHERE j.month_number BETWEEN 0 AND 3
GROUP BY j.cohort_month, s.cohort_size, j.month_number
ORDER BY j.cohort_month, j.month_number;

-- A6. Products frequently bought together
SELECT p1.product_name AS product_a,
       p2.product_name AS product_b,
       COUNT(*)        AS times_together
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
JOIN products p1   ON p1.product_id = a.product_id
JOIN products p2   ON p2.product_id = b.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_together DESC
LIMIT 10;
