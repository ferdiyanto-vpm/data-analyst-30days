##Memuat tabel
#Membuat kerangka tabel baru (dengan pengaturan yang disesuaikan)
CREATE DATABASE latihan_analyst;
CREATE TABLE superstore (
    row_id INTEGER,
    order_id VARCHAR(30),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(30),
    customer_name VARCHAR(100),
    segment VARCHAR(30),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(20),
    product_id VARCHAR(30),
    category VARCHAR(30),
    sub_category VARCHAR(30),
    product_name VARCHAR(200),
    sales NUMERIC(10,2),
    quantity INTEGER,
    discount NUMERIC(4,2),
    profit NUMERIC(10,2)
);
-- verifikasi/uji coba
SELECT COUNT(*) FROM superstore;

##SELECT Dasar
-- pilih semua kolom
SELECT * FROM superstore; 
-- pilih beberapa (menggunakan nama kolom)
SELECT order_id, order_date, customer_name, sales, profit
FROM superstore;
-- membatasi tampilan output (LIMIT)
SELECT order_id, customer_name, sales
FROM superstore
LIMIT 10;
-- kolom unik (DISTINCT mengambil nilai unik saja)
SELECT DISTINCT region FROM superstore; 
SELECT DISTINCT category, sub_category FROM superstore;
-- Alias kolom (memberi nama kolom untuk output)
SELECT
    order_id AS id_pesanan,
    customer_name AS nama_pelanggan,
    sales AS total_penjualan
FROM superstore
LIMIT 5;
-- Operasi aritmatika (*/-+)
SELECT
    order_id,
    sales,
    quantity,
    sales / quantity AS harga_per_unit
FROM superstore
LIMIT 10;
-- Kolom baru dari perhitungan (menggunakan AS)
SELECT
    order_id,
    sales,
    profit,
    profit / NULLIF(sales, 0) AS profit_margin   #NULLIF(sales, 0): mencegah error division by zero. Kalau sales = 0, hasilnya NULL, bukan error.
FROM superstore
LIMIT 10;

##Where (WHERE menyaring baris berdasarkan kondisi.)
-- Filter sederhana
SELECT order_id, customer_name, region, sales
FROM superstore
WHERE region = 'West';
-- Filter numerik
SELECT order_id, sales, profit
FROM superstore
WHERE sales > 1000;
-- Kombinasi kondisi (AND  : kondisi harus terpenuhi semua)
SELECT order_id, region, category, sales
FROM superstore
WHERE region = 'West' AND category = 'Technology';
-- Kombinasi kondisi (OR : kondisi hanya perlu salah satu atau sebagian)
SELECT order_id, region, sales
FROM superstore
WHERE region = 'West' OR region = 'East';
-- IN (lebih ringkas dari OR)
SELECT order_id, region
FROM superstore
WHERE region IN ('West', 'East');
-- BETWEEN (kondisi dengan jarak/range)
SELECT order_id, order_date, sales
FROM superstore
WHERE order_date BETWEEN '2016-01-01' AND '2016-12-31';
-- LIKE (pencarian teks) dengan awalan, tengah atau akhran. % = wildcard (bebas berapa karakter). _ = satu karakter.
SELECT customer_name
FROM superstore
WHERE customer_name LIKE 'A%'  
LIMIT 20;
--  IS NULL / IS NOT NULL (Kalau tidak ada NULL, hasilnya kosong — bagus, artinya data bersih.)
SELECT order_id, sales
FROM superstore
WHERE sales IS NULL;
-- NOT 
SELECT order_id, region
FROM superstore
WHERE region NOT IN ('West', 'East');

##ORDER BY (fungsi pengurutan tabel)
-- Urut ascending (default). kecil -> besar
SELECT order_id, sales
FROM superstore
ORDER BY sales ASC
LIMIT 10;
-- Urut descending. besar -> kecil
SELECT order_id, sales
FROM superstore
ORDER BY sales DESC
LIMIT 10;
-- Urut multi kolom
SELECT region, category, sales
FROM superstore
ORDER BY region ASC, sales DESC
LIMIT 20;
-- Urut berdasarkan kolom yang tidak ditampilkan
SELECT customer_name, sales
FROM superstore
ORDER BY profit DESC
LIMIT 10;

##Kombinasi WHERE + ORDER BY + LIMIT
-- Top 5 sales di region West
SELECT order_id, customer_name, sales
FROM superstore
WHERE region = 'West'
ORDER BY sales DESC
LIMIT 5;
-- Transaksi merugi di kategori Furniture
SELECT order_id, sub_category, sales, profit
FROM superstore
WHERE category = 'Furniture' AND profit < 0
ORDER BY profit ASC
LIMIT 20;

##Agregasi & GROUP BY
#Fungsi Agregasi Dasar
--  COUNT (menghitung baris)
SELECT COUNT(*) AS jumlah_baris FROM superstore;
SELECT COUNT(DISTINCT customer_id) AS jumlah_customer FROM superstore;
-- SUM, AVG, MIN, MAX
SELECT
    SUM(sales)   AS total_sales,
    AVG(sales)   AS rata_sales,
    MIN(sales)   AS sales_min,
    MAX(sales)   AS sales_max,
    SUM(profit)  AS total_profit
FROM superstore;
--  Beberapa agregasi sekaligus
SELECT
    ROUND(AVG(sales), 2)         AS avg_sales,
    ROUND(AVG(profit), 2)        AS avg_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_persen
FROM superstore;
#Group BY (GROUP BY mengelompokkan baris, lalu agregasi dilakukan per grup.)
-- Total sales per region
SELECT
    region,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;
-- Rata-rata profit per category
SELECT
    category,
    ROUND(AVG(profit), 2) AS avg_profit,
    SUM(profit) AS total_profit
FROM superstore
GROUP BY category
ORDER BY total_profit DESC;
-- Group by multi kolom
SELECT
    region,
    category,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY region, category
ORDER BY region, total_sales DESC;
-- Menghitung jumlah order per customer
SELECT
    customer_name,
    COUNT(DISTINCT order_id) AS jumlah_order
FROM superstore
GROUP BY customer_name
ORDER BY jumlah_order DESC
LIMIT 10;

##Having (HAVING = filter setelah GROUP BY, sedangkan WHERE filter sebelum GROUP BY.)
-- Region dengan total sales > 500.000
SELECT
    region,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY region
HAVING SUM(sales) > 500000
ORDER BY total_sales DESC;
-- Sub-category yang total profitnya negatif
SELECT
    sub_category,
    SUM(profit) AS total_profit
FROM superstore
GROUP BY sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;
-- Kategori dengan rata-rata diskon > 0.15
SELECT
    category,
    ROUND(AVG(discount), 3) AS avg_discount
FROM superstore
GROUP BY category
HAVING AVG(discount) > 0.15;
--  Region + Category dengan sales > 100.000
SELECT
    region,
    category,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY region, category
HAVING SUM(sales) > 100000
ORDER BY total_sales DESC;
-- Contoh kombo WHERE + HAVING
SELECT
    region,
    SUM(sales) AS total_sales
FROM superstore
WHERE order_date >= '2017-01-01'      -- filter baris dulu
GROUP BY region
HAVING SUM(sales) > 100000             -- filter grup
ORDER BY total_sales DESC;

##===========================================================LATIHAN=========================================================##

#Level 1 — SELECT & Filter
-- Tampilkan 10 order pertama dari tabel superstore.
SELECT * FROM superstore LIMIT 10;
-- Tampilkan semua customer unik yang berasal dari region 'South'.
SELECT DISTINCT customer_name FROM superstore WHERE region = 'South';
-- Tampilkan order_id, customer_name, dan sales untuk sales > 500 di category 'Technology'.
SELECT order_id, customer_name, sales
FROM superstore
WHERE category = 'Technology' AND sales > 500;
--Tampilkan semua produk di sub_category 'Phones' dengan discount > 0.
SELECT product_name, sub_category, discount
FROM superstore
WHERE sub_category = 'Phones' AND discount > 0;

#Level 2 — Sorting
-- Tampilkan 5 customer dengan total sales tertinggi (pakai GROUP BY).
SELECT customer_name, SUM(sales) AS total_sales
FROM superstore
GROUP BY customer_name
ORDER BY total_sales DESC
LIMIT 5;
-- Tampilkan 10 transaksi dengan profit paling negatif (paling rugi).
SELECT order_id, product_name, profit
FROM superstore
ORDER BY profit ASC
LIMIT 10;
-- Tampilkan daftar order di tahun 2017, urut dari tanggal terbaru.
SELECT order_id, order_date, sales
FROM superstore
WHERE order_date BETWEEN '2017-01-01' AND '2017-12-31'
ORDER BY order_date DESC;

#Level 3 — Agregasi
-- Hitung total sales, total profit, dan rata-rata sales seluruh tabel.
SELECT
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit,
  ROUND(AVG(sales), 2) AS avg_sales
FROM superstore;
-- Hitung jumlah order per region.
SELECT region, COUNT(DISTINCT order_id) AS jumlah_order
FROM superstore
GROUP BY region;
-- Hitung rata-rata discount per sub_category, urut dari tertinggi.
SELECT sub_category, ROUND(AVG(discount), 3) AS avg_discount
FROM superstore
GROUP BY sub_category
ORDER BY avg_discount DESC;

#Level 4 — GROUP BY + HAVING
-- Tampilkan sub_category dengan total profit negatif.
SELECT sub_category, SUM(profit) AS total_profit
FROM superstore
GROUP BY sub_category
HAVING SUM(profit) < 0;
-- Tampilkan customer yang melakukan lebih dari 10 order.
SELECT customer_name, COUNT(DISTINCT order_id) AS jumlah_order
FROM superstore
GROUP BY customer_name
HAVING COUNT(DISTINCT order_id) > 10;
-- Tampilkan state yang total sales-nya > 100.000.
SELECT state, SUM(sales) AS total_sales
FROM superstore
GROUP BY state
HAVING SUM(sales) > 100000
ORDER BY total_sales DESC;
-- Tampilkan segment dengan rata-rata profit > 30.
SELECT segment, ROUND(AVG(profit), 2) AS avg_profit
FROM superstore
GROUP BY segment
HAVING AVG(profit) > 30;
-- Tampilkan region + category dengan jumlah order lebih dari 100.
SELECT region, category, COUNT(DISTINCT order_id) AS jumlah_order
FROM superstore
GROUP BY region, category
HAVING COUNT(DISTINCT order_id) > 100;