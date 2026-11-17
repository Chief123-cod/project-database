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
