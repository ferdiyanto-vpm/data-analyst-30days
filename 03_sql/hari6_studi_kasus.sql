##Context Setting & Q1–Q2 (60 menit)
-- Skenario: Anda baru bergabung sebagai Data Analyst di Superstore. Manajer Operasional dan Manajer Sales ingin 
-- tahu kondisi bisnis secara makro dan area mana yang bermasalah.

#Q1: Health Check (Ringkasan Kinerja Utama)
-- Pertanyaan Bisnis: "Tolong berikan ringkasan performa bisnis kita secara keseluruhan: Berapa total penjualan, total profit, 
-- margin profit, total pesanan, dan rata-rata nilai pesanan (AOV)?"
SELECT 
	SUM(sales) AS Total_Penjualan,
	SUM(profit) AS Total_Keuntungan,
	ROUND( SUM(profit)/SUM(sales) *100, 2 ) AS Margin_Profit,
	COUNT(DISTINCT order_id) AS Total_Pesanan,
	ROUND(SUM(sales)/COUNT(DISTINCT order_id)) AS Avg_Nilai_Pesanan,
	COUNT(DISTINCT customer_id) AS Total_Customer
FROM superstore;

#Q2: Profitabilitas Kategori & Sub-Kategori
-- Pertanyaan Bisnis: "Kategori mana yang paling menguntungkan? Dan sub-kategori mana yang
-- justru mengalami kerugian (profit negatif) sehingga perlu dievaluasi?"

-- kategori
SELECT 
	category,
	SUM(profit) AS total_profit
FROM superstore 
GROUP BY category 
ORDER BY total_profit DESC 
LIMIT 3;
-- ATAU lebih lengkap
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_persen
FROM superstore
GROUP BY category
ORDER BY total_profit DESC;
-- sub kategory
SELECT 
	sub_category,
	SUM(profit) AS total_profit
FROM superstore 
GROUP BY sub_category 
HAVING total_profit < 0
ORDER BY total_profit;
-- ATAU lebih lengkap
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

#Q3: Segmentasi Pelanggan (Customer Analysis)
-- Pertanyaan Bisnis: "Bagaimana distribusi penjualan berdasarkan tipe pelanggan (Consumer, Corporate, Home Office)?
-- Siapa Top 10 pelanggan yang paling banyak menyumbang profit, dan region mana asal mereka?"

-- distribusi penjualan
SELECT 
	segment,
	COUNT(DISTINCT order_id) AS jumlah_order,
	SUM(sales) AS total_penjualan,
	SUM(profit) AS total_profit,
	ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS aov
FROM superstore
GROUP BY segment;
-- top 10 pelanggan (bisa begini tapi karena dummynya ada duplikat pada customer_name pada region berbeda jadi gunaan yang kedua)
SELECT 
	region,
	customer_name,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profit
FROM superstore 
GROUP BY customer_name, region
ORDER BY total_profit DESC
LIMIT 10;
-- ATAU 
SELECT
    c.customer_name,
    c.segment,
    c.region,
    ROUND(SUM(s.sales), 2) AS total_sales,
    ROUND(SUM(s.profit), 2) AS total_profit
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
GROUP BY c.customer_name, c.segment, c.region
ORDER BY total_profit DESC
LIMIT 10;	

#Q4: Analisis Diskon vs Profit (Korelasi)
-- Pertanyaan Bisnis: "Manajemen curiga kita terlalu banyak memberikan diskon. Tolong buktikan: 
-- Apakah pemberian diskon besar benar-benar menggerus profit? Buatkan ringkasan rata-rata profit berdasarkan tingkatan diskon."
SELECT 
	SUM(profit) AS total_profit,
	ROUND(AVG(profit),2) AS avg_profit,
	CASE 
		WHEN discount = 0.0 THEN '0%'
		WHEN discount <= 0.1 THEN '1-10%'
		WHEN discount <= 0.2 THEN '11-20%'
		WHEN discount <= 0.3 THEN '21-30%'
		WHEN discount <= 0.4 THEN '31-40%'
		ELSE '40%'
	END AS diskon_list
FROM superstore 
GROUP BY diskon_list 
ORDER BY diskon_list ;
-- ATAU lebih detail
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

#Q5 Tren Waktu (Time-Series)
-- Pertanyaan Bisnis: "Bagaimana pertumbuhan penjualan kita dari bulan ke bulan sepanjang tahun?
-- Bulan apa yang menjadi puncak penjualan dan apakah margin kita membaik atau memburuk?"

WITH bulanan AS (
		SELECT 
			SUM(sales) AS total_sales,
			SUM(profit) AS total_profit,
			ROUND(SUM(profit)/SUM(sales)*100,2) AS margin_persen,
			DATE_FORMAT(order_date,'%Y-%M') AS tahun_bulan
		FROM superstore
		GROUP BY tahun_bulan
		ORDER BY tahun_bulan )
SELECT *,
	LAG(total_sales) OVER (ORDER BY tahun_bulan) AS sales_bulan_sebelumnya,
	ROUND((total_sales - LAG(total_sales) OVER (ORDER BY tahun_bulan)) 
            / NULLIF(LAG(total_sales) OVER (ORDER BY tahun_bulan), 0) * 100, 
            2
        ) AS pertumbuhan_persen
FROM bulanan 
ORDER BY tahun_bulan;
-- ATAU
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
			
			

	
	
