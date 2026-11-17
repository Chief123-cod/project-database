-- =====================================================
-- FINAL PROJECT - INTRODUCTION TO DATABASE
-- Studi Kasus : Sistem Pemesanan Cloud Kitchen
-- Isi        : DDL (tabel) + DML (sample data) + Query
-- Cara pakai : jalankan seluruh file ini di MySQL / phpMyAdmin
-- =====================================================

-- =====================================================
-- DDL - SISTEM PEMESANAN CLOUD KITCHEN
-- =====================================================

-- Hapus database lama agar script bisa dijalankan ulang saat live demo
DROP DATABASE IF EXISTS db_cloud_kitchen;
CREATE DATABASE db_cloud_kitchen;
USE db_cloud_kitchen;

-- 1. Tabel Pelanggan (Master)
CREATE TABLE Pelanggan (
    id_pel   VARCHAR(5)  PRIMARY KEY,
    nama_pel VARCHAR(50) NOT NULL,
    no_hp    VARCHAR(15) NOT NULL UNIQUE
);

-- 2. Tabel Driver (Master)
CREATE TABLE Driver (
    id_driver   VARCHAR(5)  PRIMARY KEY,
    nama_driver VARCHAR(50) NOT NULL,
    plat_nomor  VARCHAR(15) NOT NULL UNIQUE
);

-- 3. Tabel Brand (Master) - brand makanan yang beroperasi di dapur cloud kitchen
CREATE TABLE Brand (
    id_brand   VARCHAR(5)  PRIMARY KEY,
    nama_brand VARCHAR(50) NOT NULL UNIQUE,
    kategori   VARCHAR(30) NOT NULL
);

-- 4. Tabel Menu (Master) - setiap menu dimiliki oleh satu brand
CREATE TABLE Menu (
    id_menu   VARCHAR(5)  PRIMARY KEY,
    id_brand  VARCHAR(5)  NOT NULL,
    nama_menu VARCHAR(50) NOT NULL,
    harga     INT         NOT NULL CHECK (harga > 0),   -- harga jual saat ini
    FOREIGN KEY (id_brand) REFERENCES Brand(id_brand)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5. Tabel Pesanan (Transaksi / Header)
CREATE TABLE Pesanan (
    no_pesanan  VARCHAR(10)  PRIMARY KEY,
    tanggal     DATE         NOT NULL,
    id_pel      VARCHAR(5)   NOT NULL,
    id_driver   VARCHAR(5)   NULL,          -- NULL = belum ada driver yang mengambil
    alamat_kirim VARCHAR(100) NOT NULL,
    ongkir      INT          NOT NULL DEFAULT 0 CHECK (ongkir >= 0),
    status      ENUM('Diproses', 'Dikirim', 'Selesai', 'Dibatalkan') NOT NULL DEFAULT 'Diproses',
    -- RESTRICT: pelanggan/driver yang punya riwayat pesanan tidak boleh dihapus
    FOREIGN KEY (id_pel) REFERENCES Pelanggan(id_pel)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_driver) REFERENCES Driver(id_driver)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 6. Tabel Detail_Pesanan (Transaksi / Item - tabel jembatan Pesanan <-> Menu)
CREATE TABLE Detail_Pesanan (
    no_pesanan   VARCHAR(10) NOT NULL,
    id_menu      VARCHAR(5)  NOT NULL,
    qty          INT         NOT NULL CHECK (qty > 0),
    harga_satuan INT         NOT NULL CHECK (harga_satuan > 0),  -- harga saat transaksi terjadi
    PRIMARY KEY (no_pesanan, id_menu),        -- Composite Primary Key
    FOREIGN KEY (no_pesanan) REFERENCES Pesanan(no_pesanan)
        ON DELETE CASCADE ON UPDATE CASCADE,   -- hapus pesanan -> detailnya ikut terhapus
    FOREIGN KEY (id_menu) REFERENCES Menu(id_menu)
        ON DELETE RESTRICT ON UPDATE CASCADE   -- menu yang pernah dipesan tidak boleh dihapus
);


-- =====================================================
-- DML - SAMPLE DATA
-- =====================================================
USE db_cloud_kitchen;

-- Pelanggan (P05 sengaja belum pernah memesan -> untuk demo LEFT JOIN)
INSERT INTO Pelanggan (id_pel, nama_pel, no_hp) VALUES
('P01', 'Budi Santoso', '08123456789'),
('P02', 'Siti Aminah',  '08998765432'),
('P03', 'Andi Wijaya',  '08551231231'),
('P04', 'Dewi Lestari', '08134567890'),
('P05', 'Rina Marlina', '08777123456');

-- Driver
INSERT INTO Driver (id_driver, nama_driver, plat_nomor) VALUES
('D01', 'Anton Supriadi', 'B 1234 AB'),
('D02', 'Rudi Gunawan',   'D 5678 CD'),
('D03', 'Hendra',         'B 9999 XYZ');

-- Brand yang beroperasi di dalam cloud kitchen
INSERT INTO Brand (id_brand, nama_brand, kategori) VALUES
('B01', 'Dapur Nusantara', 'Makanan Indonesia'),
('B02', 'Geprek Juara',    'Ayam'),
('B03', 'Kopi Senja',      'Minuman'),
('B04', 'Dimsum Mania',    'Chinese Food');

-- Menu (M08 sengaja belum pernah dipesan -> untuk demo subquery / LEFT JOIN)
INSERT INTO Menu (id_menu, id_brand, nama_menu, harga) VALUES
('M01', 'B01', 'Nasi Goreng Spesial', 25000),
('M02', 'B03', 'Es Teh Manis',         5000),
('M03', 'B02', 'Ayam Geprek',         20000),
('M04', 'B03', 'Kopi Susu Gula Aren', 18000),
('M05', 'B04', 'Dimsum Ayam',         20000),
('M06', 'B01', 'Soto Ayam',           22000),
('M07', 'B02', 'Ayam Geprek Keju',    25000),
('M08', 'B04', 'Hakau Udang',         28000);

-- Pesanan (header nota)
-- ORD-006 belum mendapat driver (id_driver NULL) karena masih diproses dapur
INSERT INTO Pesanan (no_pesanan, tanggal, id_pel, id_driver, alamat_kirim, ongkir, status) VALUES
('ORD-001', '2026-11-10', 'P01', 'D01', 'Jl. Merdeka No. 10',     10000, 'Selesai'),
('ORD-002', '2026-11-10', 'P02', 'D02', 'Jl. Sudirman No. 5',      8000, 'Selesai'),
('ORD-003', '2026-11-11', 'P01', 'D03', 'Jl. Merdeka No. 10',     10000, 'Selesai'),
('ORD-004', '2026-11-12', 'P03', 'D01', 'Jl. Gatot Subroto No. 7', 12000, 'Dibatalkan'),
('ORD-005', '2026-11-13', 'P04', 'D02', 'Jl. Diponegoro No. 21',   9000, 'Dikirim'),
('ORD-006', '2026-11-13', 'P02', NULL,  'Jl. Sudirman No. 5',      8000, 'Diproses');

-- Detail pesanan (rincian item). harga_satuan = harga menu pada saat transaksi.
INSERT INTO Detail_Pesanan (no_pesanan, id_menu, qty, harga_satuan) VALUES
-- ORD-001: Budi pesan Nasi Goreng, Es Teh, Dimsum
('ORD-001', 'M01', 2, 25000),
('ORD-001', 'M02', 3,  5000),
('ORD-001', 'M05', 1, 20000),
-- ORD-002: Siti pesan Es Teh, Nasi Goreng
('ORD-002', 'M02', 1,  5000),
('ORD-002', 'M01', 1, 25000),
-- ORD-003: Budi pesan Ayam Geprek, Kopi Susu
('ORD-003', 'M03', 2, 20000),
('ORD-003', 'M04', 2, 18000),
-- ORD-004: Andi pesan Soto Ayam (dibatalkan)
('ORD-004', 'M06', 1, 22000),
-- ORD-005: Dewi pesan Geprek Keju, Kopi Susu, Dimsum
('ORD-005', 'M07', 2, 25000),
('ORD-005', 'M04', 1, 18000),
('ORD-005', 'M05', 2, 20000),
-- ORD-006: Siti pesan Soto Ayam, Es Teh
('ORD-006', 'M06', 1, 22000),
('ORD-006', 'M02', 2,  5000);


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

