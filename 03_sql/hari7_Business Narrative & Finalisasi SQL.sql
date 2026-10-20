-- =========================================================
-- PROYEK: Superstore Profitability Analysis
-- PENULIS: FERDIYANTO VALENTINO
-- TANGGAL: 20/10/2026
-- DATABASE: MySQL 8.0+
-- =========================================================

-- =========================================================
-- 1. Health Check
-- Tujuan: Mengetahui kondisi makro bisnis (Sales, Profit, Margin, AOV)
-- =========================================================
SELECT 
	SUM(sales) AS Total_Penjualan,
	SUM(profit) AS Total_Keuntungan,
	ROUND( SUM(profit)/SUM(sales) *100, 2 ) AS Margin_Profit,
	COUNT(DISTINCT order_id) AS Total_Pesanan,
	ROUND(SUM(sales)/COUNT(DISTINCT order_id)) AS Avg_Nilai_Pesanan,
	COUNT(DISTINCT customer_id) AS Total_Customer
FROM superstore;

-- =========================================================
-- 2. Tren Bulanan Sales dan Profit
-- Tujuan: Mengetahui pola pembelian konsumen berdasarkan bulan (dapat menemukan musim ramai pembeli)
-- =========================================================
WITH tren_bulanan AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS tahun_bulan,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_persen
    FROM superstore
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
tren_dengan_lag AS (
    SELECT
        tahun_bulan,
        total_sales,
        total_profit,
        margin_persen,
        LAG(total_sales) OVER (ORDER BY tahun_bulan) AS sales_bulan_lalu,
        ROUND(
            (total_sales - LAG(total_sales) OVER (ORDER BY tahun_bulan)) 
            / NULLIF(LAG(total_sales) OVER (ORDER BY tahun_bulan), 0) * 100, 
            2
        ) AS pertumbuhan_persen
    FROM tren_bulanan
)
SELECT *
FROM tren_dengan_lag
ORDER BY tahun_bulan;

-- =========================================================
-- 3. Analisis Diskon vs Profit
-- Tujuan: Mengetahui efektivitas pemberian diskon terhadap profit
-- =========================================================
SELECT
    CASE
        WHEN discount = 0 THEN '0% (No Disc)'
        WHEN discount <= 0.1 THEN '1-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        ELSE '>40%'
    END AS diskon_bucket,
    COUNT(*) AS jumlah_transaksi,
    ROUND(AVG(profit), 2) AS rata_rata_profit,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_persen
FROM superstore
GROUP BY diskon_bucket
ORDER BY diskon_bucket;

-- =========================================================
-- 4. Profitabilitas Sub-Kategori.
-- Tujuan: Mengetahui penjualan Sub-Kategori(jenis barang) yang mengalami kerugian
-- =========================================================
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(*) AS jumlah_transaksi
FROM superstore
GROUP BY category, sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;

-- =========================================================
-- 5. Top 10 Customer by Profit .
-- Tujuan: Menyusun strategi meningkatkan dan mempertahankan pelanggan
-- =========================================================
SELECT 
	customer_name,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(*) AS jumlah_transaksi
FROM superstore
GROUP BY customer_name  
ORDER BY total_profit DESC
LIMIT 10;