A. Ceklis Excel (Hari 2)
Apa bedanya VLOOKUP dan INDEX-MATCH? Kapan pakai yang mana? *buka catatan
- Kegunaan kurang lebih sama, pembedanya hanya format fungsi yang berbeda. Sejauh pemahaman saya tentang rumusnya tidak ada kondisi spesifik yang signifikan untuk kapan penggunaannya.

Bagaimana cara membuat Pivot Table yang otomatis mengikuti data baru? (Jawab: jadikan data sebagai Table Ctrl+T).
- pertama data harus bentuk table (ctrl+T), kemudian pada tab insert terdapat pilihan pivot table. setelah muncul pop up atur tabel range yang ingin digunakan dan pilih
  tempat untuk pivot table, selanjut pengaturan menentukan nilai apa saja yang ingin dimunculkan

Apa fungsi IFERROR dan mengapa penting saat menggunakan VLOOKUP?
- untuk mencegah terjadinya error (no value) dengan mengganti null dengan definisi yang ditetapkan

Bagaimana cara membuat Slicer terhubung ke banyak Pivot Table sekaligus? (Jawab: Report Connections).
- tab insert bagian fillter (sebelah kanan)

B. Ceklis SQL (Hari 3–6)
Apa perbedaan WHERE dan HAVING?
- WHERE untuk memfillter baris sebelum dilakukan group,
  HAVING untuk memfillter value group

Jika saya ingin mencari top 3 produk per kategori, fungsi window apa yang dipakai? (Jawab: ROW_NUMBER() OVER (PARTITION BY...)).
- Untuk data besar gunakan RANK() ... jika ada valuenya atau ROW_NUMBER() ... jika hanya ingin memberi nomer
  DATA kecil cukup gunakan LIMIT.

Apa itu CTE dan mengapa lebih baik daripada subquery bertingkat?
- CTE membuat table bayangan sehingga memudahkan penghitungan pada kolom baru, sedangkan sub_query menggunakan konsep query dalam query yang memerlukan lebih banyak waktu running data

Di MySQL, bagaimana cara memotong tanggal menjadi format Tahun-Bulan? (Jawab: DATE_FORMAT(order_date, '%Y-%m')).
- DATE_FORMAT(kolom tanggal, 'format tanggal')
