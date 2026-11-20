-- 05_views.sql (MySQL)
USE ecommerce_db;

CREATE OR REPLACE VIEW vw_order_totals AS
SELECT o.order_id, o.customer_id, o.order_date, o.status,
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.customer_id, o.order_date, o.status;

CREATE OR REPLACE VIEW vw_product_performance AS
SELECT p.product_id, p.product_name, c.category_name,
       COALESCE(SUM(oi.quantity), 0)                                  AS units_sold,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0)                  AS revenue,
       COALESCE(SUM(oi.quantity * (oi.unit_price - p.cost_price)), 0) AS profit
FROM products p
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id AND o.status = 'Completed'
GROUP BY p.product_id, p.product_name, c.category_name;

-- Usage:
-- SELECT * FROM vw_product_performance ORDER BY profit DESC;
-- SELECT * FROM vw_order_totals WHERE order_total > 200;
