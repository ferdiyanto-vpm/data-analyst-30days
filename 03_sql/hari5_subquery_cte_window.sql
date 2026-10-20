##Subquery
#Scalar Subquery
-- Bandingkan sales dengan rata-rata seluruh sales
SELECT order_id, customer_id, sales
FROM superstore 
WHERE sales > (SELECT AVG(sales) FROM superstore) 
ORDER BY sales DESC 
LIMIT 20;
-- Tampilkan sales dan selisihnya dengan rata-rata
SELECT 
	order_id,
	sales,
	ROUND(sales - (SELECT AVG(sales) FROM superstore),2) AS selisih_dari_avg
FROM superstore 
ORDER BY selisih_dari_avg DESC
LIMIT 10;
-- Total sales vs total sales region West
SELECT 
	region,
	SUM(sales) AS total_sales,
	ROUND(SUM(sales) - (SELECT SUM(sales) FROM superstore WHERE region='West'),2) AS selisih_vs_west
FROM superstore
GROUP BY region
ORDER BY total_sales;

#Subquery dengan IN
-- Customer yang pernah beli kategori Technology
SELECT customer_id, customer_name, segment
FROM customers
WHERE customer_id IN (
	SELECT DISTINCT customer_id
	FROM superstore
	WHERE category = 'Technology')
LIMIT 20;
-- Customer yang BELUM pernah beli kategori Technology
SELECT customer_id customer_name, segment
FROM customers 
WHERE customer_id NOT IN (
	SELECT DISTINCT customer_id
	FROM superstore
	WHERE category = 'Technology' AND customer_id IS NOT NULL) #NOT IN bisa salah jika ada NULL di dalam hasil subquery. Karena itu tambahkan WHERE customer_id IS NOT NULL di dalam subquery.
LIMIT 20;

#Subquery dengan EXISTS (EXISTS lebih efisien untuk cek keberadaan. Cocok untuk data besar.)
-- Customer yang punya minimal 1 order dengan profit > 500
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE EXISTS (
	SELECT 1 
	FROM superstore s
	WHERE s.customer_id = c.customer_id
	 	AND profit > 500)
LIMIT 20;
-- Customer yang TIDAK punya order profit > 500
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE NOT EXISTS (
	SELECT 1
	FROM superstore s
	WHERE s.customer_id = c.customer_id 
		AND s.profit >500)
LIMIT 20;

#Correlated Subquery
-- Order dengan sales di atas rata-rata region-nya sendiri
SELECT 
	s.order_id,
	s.region,
	s.sales,
	ROUND((
		SELECT AVG(s2.sales)
		FROM superstore s2
		WHERE s2.region = s.region
		),2) AS avg_sales_region
FROM superstore s
WHERE s.sales > (
    SELECT AVG(s2.sales)
    FROM superstore s2
    WHERE s2.region = s.region)
ORDER BY s.region, s.sales desc 
LIMIT 20;

#Latihan Cepat
-- 1 Tampilkan order dengan profit di bawah rata-rata profit seluruh data.
SELECT 
	order_id,
	profit
FROM superstore
WHERE profit < (SELECT AVG(profit) FROM superstore)
ORDER BY profit;
-- 2 Tampilkan produk (dari tabel products) yang pernah terjual di region 'West'.
SELECT 
	product_id
FROM products
WHERE product_id  IN (
	SELECT DISTINCT product_id
	FROM superstore
	WHERE region = 'West')
ORDER BY product_id DESC
LIMIT 20;
#/ ATAU
SELECT DISTINCT p.product_id, p.product_name
FROM products p
WHERE p.product_id IN (
    SELECT product_id FROM superstore WHERE region = 'West'
)
ORDER BY p.product_id DESC
LIMIT 20;
-- 3 Customer yang total salesnya di atas rata-rata total sales seluruh customer.
SELECT 
	c.customer_name,
	SUM(s.sales) AS total_sales
FROM customers c
INNER JOIN superstore s ON s.customer_id = c.customer_id 
GROUP BY c.customer_name 
HAVING total_sales > AVG(s.sales )
ORDER BY total_sales 
LIMIT 10;
#benar bawah
SELECT customer_id, customer_name, SUM(sales) AS total_sales
FROM superstore
GROUP BY customer_id, customer_name
HAVING SUM(sales) > (
    SELECT AVG(total) FROM (
        SELECT SUM(sales) AS total
        FROM superstore
        GROUP BY customer_id
    ) sub
)
ORDER BY total_sales
LIMIT 10;

##CTE (WITH) + Kombinasi dengan JOIN
#Konsep CTE (CTE (Common Table Expression) = subquery yang diberi nama dan ditempatkan di awal. Lebih mudah dibaca daripada subquery bertingkat.)
-- WITH name_cte AS(SELECT ...) SELECT ... FROM nama_cte;

#CTE Sederhana
-- Total sales per customer, urut menurun
WITH total_per_customer AS ( 
	SELECT 
		customer_id,
		SUM(sales) AS total_sales,
		SUM(profit) AS total_profit,
		COUNT(DISTINCT order_id) AS jumlah_order
	FROM superstore
	GROUP BY customer_id)
SELECT * 
FROM total_per_customer 
ORDER BY total_sales DESC 
LIMIT 10;

#CTE Bertingkat
-- Customer dengan total sales di atas rata-rata
WITH total_per_customer AS(
	SELECT 
		customer_id,
		SUM(sales) AS total_sales
	FROM superstore
	GROUP BY customer_id),
rata_rata AS (
	SELECT AVG(total_sales) AS rerata_sales
	FROM total_per_customer)
SELECT t.customer_id , c.customer_name , t.total_sales 
FROM total_per_customer t
INNER JOIN customers c ON t.customer_id = c.customer_id 
CROSS JOIN rata_rata r       #(CROSS JOIN memasangkan setiap baris dengan nilai avg_sales (hanya 1 baris).)
WHERE t.total_sales > r.rerata_sales 
ORDER BY t.total_sales desc 
LIMIT 20;

#CTE + JOIN + Agregasi
-- Total profit per manager per category
WITH profit_per_kategori AS( 
	SELECT 
		s.region,
		p.category,
		SUM(s.profit) AS total_profit,
		SUM(s.sales) AS total_sales
	FROM superstore s
	INNER JOIN products p ON p.product_id = s.product_id 
	GROUP BY s.region , p.category )
SELECT 
	m.manager_name ,
	pk.category ,
	pk.total_sales ,
	pk.total_profit ,
	ROUND(pk.total_profit / pk.total_sales *100,2) AS margin_persen
FROM profit_per_kategori pk
INNER JOIN managers m ON pk.region = m.region 
ORDER BY m.manager_name , pk.total_sales DESC;

#CTE untuk Analisis Diskon
-- Pengaruh diskon terhadap profit
WITH diskon_bucket AS (
 	SELECT 
 		CASE 
 			WHEN discount = 0.0 THEN '0%'
 			WHEN discount <= 0.1 THEN '1-10%'
 			WHEN discount <= 0.2 THEN '11-20%'
 			WHEN discount <= 0.3 THEN '21-30%'
 			WHEN discount <= 0.4 THEN '31-40%'
 			ELSE '>40%'
 		END AS bucket,
 		sales,
 		profit
 	FROM superstore)
SELECT 
	bucket,
	COUNT(*) AS jumlah_transaksi,
	ROUND(AVG (sales),2 ) AS rerata_sales,
	ROUND(AVG(profit), 2) AS rerata_profit,
	ROUND(SUM(profit) / NULLIF(SUM(sales),0) * 100,2) AS margin_persen
FROM diskon_bucket 
GROUP BY bucket 
ORDER BY bucket ;

#Latihan Cepat
-- Buat CTE sales_per_kota yang berisi total sales per city. Tampilkan 10 kota dengan sales tertinggi.
WITH sales_per_kota AS (
	SELECT city, state, SUM(sales) AS total_sales 
 	FROM superstore
 	GROUP BY city, state)
SELECT *
FROM sales_per_kota
ORDER BY total_sales DESC 
LIMIT 10;

-- Buat CTE profit_per_subcat, lalu filter hanya yang total profitnya negatif.
WITH profit_per_subcat AS (
	SELECT 
		sub_category, 
		SUM(profit) AS total_profit,
		SUM(sales) AS total_sales
	FROM superstore
	GROUP BY sub_category)
SELECT *, ROUND(total_profit / total_sales *100, 2) AS margin_persen
FROM profit_per_subcat 
WHERE total_profit < 0 
ORDER BY total_profit ;

##Window Function
#Konsep Window Function (Window function menghitung nilai tanpa menghilangkan baris (beda dengan GROUP BY).)
#FUNGSI() OVER (
#    PARTITION BY kolom_grup
#    ORDER BY kolom_urut
#)
#ROW_NUMBER() — nomor unik per baris (1, 2, 3, 4).
#RANK() — ranking dengan lompatan (1, 2, 2, 4).
#DENSE_RANK() — ranking tanpa lompatan (1, 2, 2, 3).
#LAG() / LEAD() — akses baris sebelumnya/sesudahnya.
#SUM() OVER (...) — running total.
#AVG() OVER (...) — rata-rata bergulir.

#ROW_NUMBER, RANK, DENSE_RANK
-- Ranking produk berdasarkan sales di tiap kategori
SELECT 
	p.category,
	p.product_name,
	SUM(s.sales) AS total_sales,
	ROW_NUMBER()  OVER (PARTITION BY p.category ORDER BY SUM(s.sales) DESC) AS rn,
	RANK() 		  OVER (PARTITION BY p.category ORDER BY SUM(s.sales) DESC) AS rnk,
	DENSE_RANK()  OVER (PARTITION BY p.category ORDER BY SUM(s.sales) DESC) AS drnk
FROM superstore s
INNER JOIN products  p ON p.product_id = s.product_id 
GROUP BY p.category , p.product_name 
ORDER BY p.category , total_sales DESC;

#Top-N per Grup (Pertanyaan Interview Favorit)
-- Top 3 produk per kategori berdasarkan sales
WITH ranked AS (
	SELECT 
		p.category,
		p.product_name ,
		SUM(s.sales) AS total_sales,
		ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(s.sales) DESC) AS rn
	FROM superstore s
	INNER JOIN products p ON p.product_id = s.product_id 
	GROUP BY p.category , p.product_name)
SELECT category, product_name, total_sales
FROM ranked 
WHERE rn <= 3
ORDER BY category, total_sales DESC;
-- Top 5 customer per region berdasarkan profit
WITH ranked AS (
	SELECT 
		s.region,
		c.customer_name ,
		SUM(s.profit) AS total_profit,
		ROW_NUMBER() OVER (PARTITION BY s.region ORDER BY SUM(s.profit) DESC) AS rn
	FROM superstore s
	INNER JOIN customers c ON c.customer_id =s.customer_id 
	GROUP BY s.region , c.customer_name)
SELECT *
FROM ranked 
WHERE rn <= 5
ORDER BY region, total_profit DESC;

#4 LAG & LEAD LAG melihat nilai sebelumnya; LEAD melihat nilai sesudahnya. Berguna untuk analisis tren bulanan.
-- Sales bulanan + pertumbuhan vs bulan sebelumnya
WITH bulanan AS ( 
	SELECT 
 	 	DATE_FORMAT(order_date, '%Y-%m-01') AS bulan,
 	 	SUM(sales) AS total_sales
 	FROM superstore
 	GROUP BY bulan )
SELECT 
	*,
	LAG(total_sales) OVER (ORDER BY bulan) AS sales_bulan_lalu,
	ROUND((total_sales - LAG(total_sales) OVER (ORDER BY bulan))
	 	 /NULLIF(LAG(total_sales) OVER (ORDER BY bulan),0) * 100, 2) AS pertumbuhan_persen
FROM bulanan
ORDER BY bulan;
-- Profit bulanan + LEAD
WITH bulanan AS (
	SELECT 
		DATE_FORMAT(order_date, '%Y-%M-01') AS bulan,
		SUM(sales) AS total_sales
	FROM superstore
	GROUP BY bulan)
SELECT 
	*, SUM(total_sales) OVER (ORDER BY bulan) AS running_total
FROM bulanan 
ORDER BY bulan;
-- Running total sales per region
WITH bulanan_region AS (
	SELECT 
		region,
		DATE_FORMAT(order_date, '%Y-%M-01') AS bulan,
		SUM(sales) AS total_sales
	FROM superstore
	GROUP BY region, bulan )
SELECT *, SUM(total_sales) OVER (PARTITION BY region ORDER BY bulan) AS running_total_region
FROM bulanan_region 
ORDER BY region, bulan; 

#==========================================================LATIHAN================================================================#
##Level 1 — Subquery

#Tampilkan order dengan sales di atas rata-rata sales seluruh data.
SELECT 
	order_id,
	sales
FROM superstore 
WHERE sales > (SELECT AVG(sales) FROM superstore)
ORDER BY sales DESC;

#Tampilkan product yang pernah terjual di region 'West' (pakai IN).
SELECT 
	product_id,
	product_name
FROM products  
WHERE product_id IN (SELECT DISTINCT product_id FROM superstore WHERE region = 'West')
ORDER BY product_name ;
-- ATAU
SELECT DISTINCT p.product_id, p.product_name
FROM products p
WHERE p.product_id IN (
    SELECT product_id FROM superstore WHERE region = 'West'
)
ORDER BY p.product_name ;

#Tampilkan customer yang belum pernah beli category 'Furniture' (pakai NOT EXISTS).
SELECT c.customer_name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM superstore s WHERE s.customer_id = c.customer_id  AND s.category = 'Furniture')
LIMIT 20;

##Level 2 — CTE
#Buat CTE sales_per_region berisi total sales & profit per region.
WITH sales_per_region AS ( 
		SELECT region, SUM(sales) AS total_sales, SUM(profit) AS total_profit
		FROM superstore
		GROUP BY region)
SELECT * 
FROM sales_per_region 
LIMIT 20;

#Buat CTE diskon_rugi berisi transaksi dengan discount > 0.4. Tampilkan total kerugiannya.
WITH diskon_rugi AS (
    SELECT *
    FROM superstore
    WHERE discount > 0.4 AND profit < 0)
SELECT
	COUNT(*) AS jumlah_transaksi_rugi,
    ROUND(SUM(profit), 2) AS total_kerugian
FROM diskon_rugi;   #### penerapan: buat tabel untuk memfillter baru dihitung sum/avg dan sebagainya
		
#Buat CTE top_segment berisi segment dengan total sales > 500.000.
WITH top_segment AS ( 
	SELECT segment , SUM(sales) AS total_sales
	FROM superstore 
	GROUP BY segment)
SELECT segment, total_sales 
FROM top_segment 
WHERE total_sales  > 500000
ORDER BY total_sales DESC;

##Level 3 — Window Function (Ranking)

#Ranking customer berdasarkan total profit di tiap segment.
WITH ranked AS (
	SELECT 
		customer_name,
		segment,
		SUM(profit) AS total_profit,
		RANK() OVER (PARTITION BY segment ORDER BY SUM(profit) DESC) AS rn
	FROM superstore
	GROUP BY segment, customer_name)
SELECT *
FROM ranked;
-- ATAU
SELECT
    c.segment,
    c.customer_name,
    SUM(s.profit) AS total_profit,
    RANK() OVER (PARTITION BY c.segment ORDER BY SUM(s.profit) DESC) AS rnk
FROM superstore s
INNER JOIN customers c ON s.customer_id = c.customer_id
GROUP BY c.segment, c.customer_name
ORDER BY c.segment, rnk
LIMIT 30;

#Top 3 product per category berdasarkan profit.
WITH ranked AS (SELECT 
		product_name,
		category,
		SUM(profit) AS total_profit,
		RANK() OVER (PARTITION BY category ORDER BY SUM(profit) DESC) AS rnk
	FROM superstore 
	GROUP BY category, product_name)
SELECT *
FROM ranked 
WHERE rnk < 4 ; 
-- ATAU	
WITH ranked AS (
    SELECT
        p.category,
        p.product_name,
        SUM(s.profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(s.profit) DESC) AS rn
    FROM superstore s
    INNER JOIN products p ON s.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT category, product_name, total_profit
FROM ranked
WHERE rn <= 3
ORDER BY category, total_profit DESC;

#Top 5 city per region berdasarkan sales.
WITH ranked AS(SELECT 
		city,
		region,
		SUM(sales) AS total_sales,
		RANK() OVER (PARTITION BY REGION ORDER BY SUM(sales) DESC) AS rnk
	FROM superstore
	GROUP BY region, city)
SELECT *
FROM ranked 
WHERE rnk < 6;
-- ATAU
WITH ranked AS (
    SELECT
        region,
        city,
        SUM(sales) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales) DESC) AS rn
    FROM superstore
    GROUP BY region, city
)
SELECT region, city, total_sales
FROM ranked
WHERE rn <= 5
ORDER BY region, total_sales DESC;

##Level 4 — Window Function (Lanjutan)

#Sales bulanan + pertumbuhan (%) vs bulan sebelumnya (pakai LAG).
WITH bulanan AS ( 
		SELECT 
			DATE_FORMAT(order_date,'%Y-%M-%1') AS bulan,
			SUM(sales) AS total_sales
		FROM superstore
		GROUP BY bulan)
SELECT *,
	LAG(total_sales) OVER (ORDER BY bulan) AS sales_bulan_lalu,
	ROUND((total_sales - LAG(total_sales) OVER (ORDER BY bulan))/ NULLIF(LAG(total_sales) OVER (ORDER BY bulan),0) *100,2) AS pertumbuhan_persen 
FROM bulanan
GROUP BY bulan;

#Running total profit per region per bulan.
WITH bulanan AS (
		SELECT 
			DATE_FORMAT(order_date, '%Y-%M-%1') AS bulan,
			SUM(profit) AS total_profit,
			region
		FROM superstore 
		GROUP BY region, bulan)
SELECT *, SUM(total_profit) OVER (PARTITION BY region ORDER BY bulan) AS running_total_region
FROM bulanan 
ORDER BY region, bulan;

#Bandingkan RANK dan DENSE_RANK pada top 10 sub-category by sales.
WITH ranked AS ( 
	SELECT
		sub_category,
		SUM(sales) AS total_sales,
		RANK() OVER (ORDER BY SUM(sales) DESC) AS rnk,
		DENSE_RANK() OVER (ORDER BY SUM(sales) DESC) AS drnk
	FROM superstore
	GROUP BY sub_category)
SELECT *
FROM ranked
ORDER BY total_sales DESC
LIMIT 10;

##Level 5 — Kombinasi

#Top 3 manager berdasarkan profit, dengan margin persen.
WITH manager_profit AS (
		SELECT 
			m.manager_name,
			SUM(s.profit) AS total_profit,
			SUM(s.sales) AS total_sales,
			RANK() OVER (ORDER BY SUM(s.sales)  DESC) AS rnk
		FROM superstore s
		INNER JOIN managers m ON m.region = s.region
		GROUP BY m.manager_name )
SELECT *, 
	ROUND(total_profit/total_sales * 100,2) AS margin_persen
FROM manager_profit 
WHERE rnk <4 
ORDER BY total_profit DESC;		

#Top 5 customer per manager berdasarkan total sales.
WITH cus_mng AS (
		SELECT 
			m.manager_name,
			s.customer_name,
			SUM(s.sales) AS total_sales,
			RANK() OVER (PARTITION BY m.manager_name ORDER BY SUM(s.sales) DESC) AS rnk
		FROM superstore s
		INNER JOIN managers m ON m.region = s.region 
		GROUP BY s.customer_name,m.manager_name)
	SELECT *
	FROM cus_mng 
	WHERE rnk < 6
	ORDER BY manager_name;

#Sub-category yang pernah rugi (profit < 0) dan total kerugiannya, diurut dari terburuk, hanya tampilkan yang kerugiannya > 1000.
WITH kerugian AS (
    SELECT
        sub_category,
        SUM(profit) AS total_profit,
        COUNT(*) AS jumlah_transaksi_rugi
    FROM superstore
    WHERE profit < 0
    GROUP BY sub_category
)
SELECT
    sub_category,
    total_profit,
    jumlah_transaksi_rugi
FROM kerugian
WHERE total_profit < -1000
ORDER BY total_profit ASC;