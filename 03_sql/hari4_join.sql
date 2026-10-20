## Buat Tabel Tambahan (buat 3 tabel: customers, products, orders, dan managers.)

#TABEL customers
-- Cek Duplikasi customer_id
SELECT customer_id, COUNT(DISTINCT city) AS jml_kota
FROM superstore
GROUP BY customer_id
HAVING COUNT(DISTINCT city) > 1
ORDER BY jml_kota DESC
LIMIT 10;
-- Buat Tabel customers
DROP TABLE IF EXISTS customers;
CREATE TABLE customers AS
SELECT customer_id, customer_name, segment, city, state, region
FROM (
    SELECT
        customer_id, customer_name, segment, city, state, region,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM superstore
) sub
WHERE rn = 1;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);
SELECT COUNT(*) FROM customers;

#Tabel products
DROP TABLE IF EXISTS products;
CREATE TABLE products AS
SELECT product_id, product_name, category, sub_category
FROM (
    SELECT
        product_id, product_name, category, sub_category,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY order_date DESC) AS rn
    FROM superstore
) sub
WHERE rn = 1;
ALTER TABLE products ADD PRIMARY KEY (product_id);
SELECT COUNT(*) FROM products;

#Tabel orders
DROP TABLE IF EXISTS orders;
CREATE TABLE orders AS
SELECT order_id, order_date, ship_date, ship_mode, customer_id
FROM (
    SELECT
        order_id, order_date, ship_date, ship_mode, customer_id,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date DESC) AS rn
    FROM superstore
) sub
WHERE rn = 1;
ALTER TABLE orders ADD PRIMARY KEY (order_id);
SELECT COUNT(*) FROM orders;

#Tabel managers
DROP TABLE IF EXISTS managers;
CREATE TABLE managers (
    region VARCHAR(20) PRIMARY KEY,
    manager_name VARCHAR(50),
    manager_email VARCHAR(100)
);
INSERT INTO managers VALUES
    ('West',    'Andi Wijaya',  'andi@company.com'),
    ('East',    'Budi Santoso', 'budi@company.com'),
    ('Central', 'Citra Dewi',   'citra@company.com'),
    ('South',   'Dewi Lestari', 'dewi@company.com');
SELECT * FROM managers;

##INNER JOIN & LEFT JOIN dengan Kolom Asli
#INNER JOIN
--  Gabungkan orders dengan customers
SELECT
    o.order_id,
    o.order_date,
    c.customer_name,
    c.segment,
    c.region
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LIMIT 10;
-- Gabungkan superstore dengan products
SELECT
    s.order_id,
    s.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    s.sales
FROM superstore s
INNER JOIN products p ON s.product_id = p.product_id
LIMIT 10;
-- Gabungkan superstore dengan managers
SELECT
    s.order_id,
    s.region,
    m.manager_name,
    s.sales
FROM superstore s
INNER JOIN managers m ON s.region = m.region
LIMIT 10;
-- INNER JOIN + agregasi (total sales per manager)
SELECT
    m.manager_name,
    SUM(s.sales)  AS total_sales,
    SUM(s.profit) AS total_profit
FROM superstore s
INNER JOIN managers m ON s.region = m.region
GROUP BY m.manager_name
ORDER BY total_sales DESC;

#LEFT JOIN
-- Semua customer, termasuk yang belum pernah order
SELECT
    c.customer_id,
    c.customer_name,
    o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LIMIT 20;
-- Cari customer yang belum pernah order
SELECT
    c.customer_id,
    c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
-- LEFT JOIN + COUNT (termasuk customer dengan 0 order)
SELECT
    c.customer_name,
    COUNT(o.order_id) AS jumlah_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY jumlah_order ASC
LIMIT 10;

# Bandingkan INNER vs LEFT
-- Hanya order yang punya customer valid
SELECT COUNT(*) FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
-- Semua order (termasuk yang tidak punya customer — jika ada)
SELECT COUNT(*) FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;

##Multi-Join 3–4 Tabel + Agregasi
-- 3 tabel: superstore + customers + managers
SELECT
    s.order_id,
    s.order_date,
    c.customer_name,
    m.manager_name,
    s.sales
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN managers m ON s.region = m.region
LIMIT 20;
-- 4 tabel: superstore + customers + products + managers
SELECT
    s.order_id,
    c.customer_name,
    m.manager_name,
    p.product_name,
    p.category,
    p.sub_category,
    s.sales,
    s.profit
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN products  p ON s.product_id  = p.product_id
INNER JOIN managers  m ON s.region      = m.region
LIMIT 20;
-- Agregasi lintas tabel (sales & profit per manager)
SELECT
    m.manager_name,
    COUNT(DISTINCT s.customer_id) AS jumlah_customer,
    SUM(s.sales)  AS total_sales,
    SUM(s.profit) AS total_profit,
    ROUND(SUM(s.profit) / SUM(s.sales) * 100, 2) AS margin_persen
FROM superstore s
INNER JOIN managers m ON s.region = m.region
GROUP BY m.manager_name
ORDER BY total_sales DESC;
-- Customer dengan jumlah order > 10 + manager regionnya
SELECT
    c.customer_name,
    m.manager_name,
    COUNT(DISTINCT s.order_id) AS jumlah_order
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN managers  m ON s.region      = m.region
GROUP BY c.customer_name, m.manager_name
HAVING COUNT(DISTINCT s.order_id) > 10
ORDER BY jumlah_order DESC;
-- Sales per category per manager
SELECT
    m.manager_name,
    p.category,
    SUM(s.sales) AS total_sales
FROM superstore s
INNER JOIN products p ON s.product_id = p.product_id
INNER JOIN managers m ON s.region     = m.region
GROUP BY m.manager_name, p.category
ORDER BY m.manager_name, total_sales DESC;
-- Sub-category yang rugi, plus nama manager yang menanganinya
SELECT
    s.sub_category,
    m.manager_name,
    SUM(s.profit) AS total_profit
FROM superstore s
INNER JOIN managers m ON s.region = m.region
GROUP BY s.sub_category, m.manager_name
HAVING SUM(s.profit) < 0
ORDER BY total_profit ASC;
-- Total profit per customer + nama manager
SELECT
    c.customer_name,
    m.manager_name,
    SUM(s.profit) AS total_profit
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN managers  m ON s.region      = m.region
GROUP BY c.customer_name, m.manager_name
ORDER BY total_profit DESC
LIMIT 10;

##===========================================================LATIHAN=========================================================##

#Level 1 — INNER JOIN (dasar)
-- Tampilkan order_id, customer_name, sales untuk 20 order pertama.
SELECT s.order_id, c.customer_name, s.sales
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
LIMIT 20;
-- Tampilkan order_id, product_name, category, sales untuk category 'Technology'.
SELECT s.order_id, p.product_name, p.category, s.sales
FROM superstore s
INNER JOIN products p ON s.product_id = p.product_id
WHERE p.category = 'Technology';
-- Tampilkan order_id, manager_name, sales untuk region 'West'.
SELECT s.order_id, m.manager_name, s.sales
FROM superstore s
INNER JOIN managers m ON s.region = m.region
WHERE s.region = 'West';

#Level 2 — Agregasi + JOIN
-- Hitung total sales per manager.
SELECT m.manager_name, SUM(s.sales) AS total_sales
FROM superstore s
INNER JOIN managers m ON s.region = m.region
GROUP BY m.manager_name
ORDER BY total_sales DESC;
-- Hitung rata-rata profit per category (join dengan products).
SELECT p.category, ROUND(AVG(s.profit), 2) AS avg_profit
FROM superstore s
INNER JOIN products p ON s.product_id = p.product_id
GROUP BY p.category;
-- Hitung jumlah order per segment customer.
SELECT c.segment, COUNT(DISTINCT s.order_id) AS jumlah_order
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
GROUP BY c.segment;

#Level 3 — LEFT JOIN
-- Tampilkan semua customer + jumlah order (termasuk yang 0).
SELECT c.customer_name, COUNT(o.order_id) AS jumlah_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY jumlah_order ASC;
-- Tampilkan semua product_id + total sales (NULL jika belum pernah terjual).
SELECT p.product_id, p.product_name, SUM(s.sales) AS total_sales
FROM products p
LEFT JOIN superstore s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_sales DESC NULLS LAST
LIMIT 20;
-- Cari customer yang belum pernah melakukan order.
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

#Level 4 — Multi-join
-- Tampilkan customer_name, manager_name, product_name, sales (4 tabel).
SELECT c.customer_name, m.manager_name, p.product_name, s.sales
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN products  p ON s.product_id  = p.product_id
INNER JOIN managers  m ON s.region      = m.region
LIMIT 20;
-- Total sales per manager per category, urut manager lalu sales.
SELECT m.manager_name, p.category, SUM(s.sales) AS total_sales
FROM superstore s
INNER JOIN products p ON s.product_id = p.product_id
INNER JOIN managers m ON s.region     = m.region
GROUP BY m.manager_name, p.category
ORDER BY m.manager_name, total_sales DESC;
-- Top 5 product_name dengan total profit tertinggi.
SELECT p.product_name, SUM(s.profit) AS total_profit
FROM superstore s
INNER JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 5;
-- Jumlah order per manager per segment.
SELECT m.manager_name, c.segment, COUNT(DISTINCT s.order_id) AS jumlah_order
FROM superstore s
INNER JOIN managers  m ON s.region      = m.region
INNER JOIN customers c ON s.customer_id = c.customer_id
GROUP BY m.manager_name, c.segment
ORDER BY m.manager_name, c.segment;
-- Sub-category dengan total profit negatif + nama manager yang menanganinya.
SELECT s.sub_category, m.manager_name, SUM(s.profit) AS total_profit
FROM superstore s
INNER JOIN managers m ON s.region = m.region
GROUP BY s.sub_category, m.manager_name
HAVING SUM(s.profit) < 0
ORDER BY total_profit ASC;
-- Customer yang ordernya ditangani manager 'Andi Wijaya' dengan total sales > 10.000.
SELECT c.customer_name, SUM(s.sales) AS total_sales
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN managers  m ON s.region      = m.region
WHERE m.manager_name = 'Andi Wijaya'
GROUP BY c.customer_name
HAVING SUM(s.sales) > 10000
ORDER BY total_sales DESC;
