-- =====================================================
-- QUERY - SISTEM PEMESANAN CLOUD KITCHEN
-- =====================================================
USE db_cloud_kitchen;

-- -----------------------------------------------------
-- A. SELECT, WHERE, ORDER BY
-- Menu dengan harga di atas Rp20.000, urut dari termahal
-- -----------------------------------------------------
SELECT id_menu, nama_menu, harga
FROM Menu
WHERE harga > 20000
ORDER BY harga DESC;

-- -----------------------------------------------------
-- B. LIKE
-- Mencari semua menu yang mengandung kata 'Ayam'
-- -----------------------------------------------------
SELECT id_menu, nama_menu, harga
FROM Menu
WHERE nama_menu LIKE '%Ayam%';

-- -----------------------------------------------------
-- C. INNER JOIN (3 tabel)
-- Riwayat pesanan lengkap dengan nama pelanggan dan driver
-- -----------------------------------------------------
SELECT p.no_pesanan, p.tanggal, pel.nama_pel, d.nama_driver, p.status
FROM Pesanan p
JOIN Pelanggan pel ON p.id_pel = pel.id_pel
JOIN Driver d      ON p.id_driver = d.id_driver
ORDER BY p.tanggal;

-- -----------------------------------------------------
-- D. MULTI JOIN (5 tabel) + kolom hitung
-- Rincian nota pesanan ORD-001 (subtotal dihitung, tidak disimpan)
-- -----------------------------------------------------
SELECT dp.no_pesanan, pel.nama_pel, b.nama_brand, m.nama_menu,
       dp.harga_satuan, dp.qty,
       dp.qty * dp.harga_satuan AS subtotal
FROM Detail_Pesanan dp
JOIN Pesanan p     ON dp.no_pesanan = p.no_pesanan
JOIN Pelanggan pel ON p.id_pel = pel.id_pel
JOIN Menu m        ON dp.id_menu = m.id_menu
JOIN Brand b       ON m.id_brand = b.id_brand
WHERE dp.no_pesanan = 'ORD-001';

-- -----------------------------------------------------
-- E. GROUP BY + SUM
-- Total tagihan setiap pesanan (total makanan + ongkir)
-- -----------------------------------------------------
SELECT p.no_pesanan,
       SUM(dp.qty)                              AS total_item,
       SUM(dp.qty * dp.harga_satuan)            AS total_makanan,
       p.ongkir,
       SUM(dp.qty * dp.harga_satuan) + p.ongkir AS total_bayar
FROM Pesanan p
JOIN Detail_Pesanan dp ON p.no_pesanan = dp.no_pesanan
GROUP BY p.no_pesanan, p.ongkir;

-- -----------------------------------------------------
-- F. AGGREGATE FUNCTION (COUNT, MIN, MAX, AVG)
-- Statistik harga menu untuk setiap brand
-- -----------------------------------------------------
SELECT b.nama_brand,
       COUNT(m.id_menu)   AS jumlah_menu,
       MIN(m.harga)       AS harga_termurah,
       MAX(m.harga)       AS harga_termahal,
       ROUND(AVG(m.harga)) AS rata_rata_harga
FROM Brand b
JOIN Menu m ON b.id_brand = m.id_brand
GROUP BY b.id_brand, b.nama_brand;

-- -----------------------------------------------------
-- G. GROUP BY + HAVING
-- Pelanggan yang sudah memesan minimal 2 kali
-- -----------------------------------------------------
SELECT pel.id_pel, pel.nama_pel, COUNT(p.no_pesanan) AS jumlah_pesanan
FROM Pelanggan pel
JOIN Pesanan p ON pel.id_pel = p.id_pel
GROUP BY pel.id_pel, pel.nama_pel
HAVING COUNT(p.no_pesanan) >= 2;

-- -----------------------------------------------------
-- H. Pendapatan per brand (pesanan yang dibatalkan tidak dihitung)
-- -----------------------------------------------------
SELECT b.nama_brand,
       SUM(dp.qty)                   AS porsi_terjual,
       SUM(dp.qty * dp.harga_satuan) AS pendapatan
FROM Brand b
JOIN Menu m            ON b.id_brand = m.id_brand
JOIN Detail_Pesanan dp ON m.id_menu = dp.id_menu
JOIN Pesanan p         ON dp.no_pesanan = p.no_pesanan
WHERE p.status <> 'Dibatalkan'
GROUP BY b.id_brand, b.nama_brand
ORDER BY pendapatan DESC;

-- -----------------------------------------------------
-- I. LEFT JOIN
-- I.1 Semua pesanan, termasuk yang belum mendapat driver
-- -----------------------------------------------------
SELECT p.no_pesanan, p.status,
       IFNULL(d.nama_driver, 'Belum ada driver') AS driver
FROM Pesanan p
LEFT JOIN Driver d ON p.id_driver = d.id_driver;

-- I.2 Pelanggan yang belum pernah memesan sama sekali
SELECT pel.id_pel, pel.nama_pel
FROM Pelanggan pel
LEFT JOIN Pesanan p ON pel.id_pel = p.id_pel
WHERE p.no_pesanan IS NULL;

-- -----------------------------------------------------
-- J. SUBQUERY
-- J.1 Menu yang belum pernah dipesan
-- -----------------------------------------------------
SELECT id_menu, nama_menu
FROM Menu
WHERE id_menu NOT IN (SELECT id_menu FROM Detail_Pesanan);

-- J.2 Menu dengan harga di atas rata-rata seluruh menu
SELECT nama_menu, harga
FROM Menu
WHERE harga > (SELECT AVG(harga) FROM Menu);

-- -----------------------------------------------------
-- K. VIEW
-- View nota agar laporan tagihan mudah dipanggil ulang
-- -----------------------------------------------------
CREATE OR REPLACE VIEW v_tagihan AS
SELECT p.no_pesanan, p.tanggal, pel.nama_pel, p.status,
       SUM(dp.qty * dp.harga_satuan) + p.ongkir AS total_bayar
FROM Pesanan p
JOIN Pelanggan pel     ON p.id_pel = pel.id_pel
JOIN Detail_Pesanan dp ON p.no_pesanan = dp.no_pesanan
GROUP BY p.no_pesanan, p.tanggal, pel.nama_pel, p.status, p.ongkir;

SELECT * FROM v_tagihan WHERE status = 'Selesai';

-- -----------------------------------------------------
-- L. UPDATE
-- -----------------------------------------------------
-- L.1 Driver D03 mengambil pesanan ORD-006
UPDATE Pesanan SET id_driver = 'D03', status = 'Dikirim' WHERE no_pesanan = 'ORD-006';

-- L.2 Pesanan ORD-005 sudah sampai
UPDATE Pesanan SET status = 'Selesai' WHERE no_pesanan = 'ORD-005';

SELECT no_pesanan, id_driver, status FROM Pesanan WHERE no_pesanan IN ('ORD-005', 'ORD-006');

-- L.3 Harga Nasi Goreng naik -> total nota lama TIDAK berubah,
--     karena Detail_Pesanan menyimpan harga_satuan saat transaksi
UPDATE Menu SET harga = 27000 WHERE id_menu = 'M01';
SELECT * FROM v_tagihan WHERE no_pesanan = 'ORD-001';   -- tetap 95000

-- -----------------------------------------------------
-- M. DELETE + ON DELETE CASCADE
-- Menghapus pesanan yang dibatalkan -> detailnya otomatis ikut terhapus
-- -----------------------------------------------------
SELECT COUNT(*) AS detail_sebelum FROM Detail_Pesanan WHERE no_pesanan = 'ORD-004';
DELETE FROM Pesanan WHERE no_pesanan = 'ORD-004';
SELECT COUNT(*) AS detail_sesudah FROM Detail_Pesanan WHERE no_pesanan = 'ORD-004';

-- =====================================================
-- N. DEMO CONSTRAINT (sengaja ERROR)
-- Hapus tanda komentar satu per satu saat live demo.
-- =====================================================

-- N.1 CHECK: qty harus > 0
-- INSERT INTO Detail_Pesanan VALUES ('ORD-001', 'M03', 0, 20000);

-- N.2 UNIQUE: no_hp tidak boleh kembar
-- INSERT INTO Pelanggan VALUES ('P06', 'Joko', '08123456789');

-- N.3 PRIMARY KEY: id tidak boleh kembar
-- INSERT INTO Menu VALUES ('M01', 'B01', 'Mie Goreng', 20000);

-- N.4 FOREIGN KEY: pelanggan P99 tidak ada
-- INSERT INTO Pesanan VALUES ('ORD-007', '2026-11-14', 'P99', 'D01', 'Jl. Kenanga 1', 5000, 'Diproses');

-- N.5 ON DELETE RESTRICT: pelanggan yang punya riwayat pesanan tidak bisa dihapus
-- DELETE FROM Pelanggan WHERE id_pel = 'P01';

-- N.6 ENUM: status di luar pilihan ditolak (berlaku jika STRICT mode aktif)
-- UPDATE Pesanan SET status = 'Hilang' WHERE no_pesanan = 'ORD-001';
