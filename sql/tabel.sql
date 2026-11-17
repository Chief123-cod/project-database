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
