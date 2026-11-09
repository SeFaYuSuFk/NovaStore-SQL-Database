-- ====================================================================
-- PROJE ADI: NovaStore E-Ticaret Veri Yönetim Sistemi
-- HAZIRLAYAN: Sefa Yusuf Kütük
-- VERİTABANI MOTORU: Microsoft SQL Server (T-SQL)
-- KONSEPT: Gaming & Yazılımcı Ekipmanları E-Ticaret Platformu
-- ====================================================================

-- ====================================================================
-- BÖLÜM 1: Veri Tabanı Tasarımı (Logical Design ve DDL)
-- ====================================================================

-- 1. Veritabanının Temiz Sıfırdan Kurulması (Her F5'te Sorunsuz Çalışır)
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'NovaStoreDB')
BEGIN
    ALTER DATABASE NovaStoreDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NovaStoreDB;
END
GO

CREATE DATABASE NovaStoreDB;
GO

USE NovaStoreDB;
GO

-- 2. Tablo Tasarımları

-- A. Tablo: Categories (Kategoriler)
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL
);
GO

-- B. Tablo: Products (Ürünler)
-- Mühendislik Dokunuşu: CHECK kısıtlamaları ile veri bütünlüğü koruması
-- Fiyat 0 veya eksi olamaz (Price > 0), Stok eksiye düşemez (Stock >= 0)
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Stock INT DEFAULT 0,
    CategoryID INT NOT NULL,
    CONSTRAINT CK_Products_Price CHECK (Price > 0),
    CONSTRAINT CK_Products_Stock CHECK (Stock >= 0),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
GO

-- C. Tablo: Customers (Müşteriler)
-- Email alanı UNIQUE tanımlanarak mükerrer kullanıcı kaydı engellenmiştir.
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    City VARCHAR(20) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE
);
GO

-- D. Tablo: Orders (Siparişler)
-- Mühendislik Dokunuşu: OrderStatus (Sipariş Durumu) ve CHECK kısıtlaması
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL,
    OrderStatus VARCHAR(20) DEFAULT 'Hazırlanıyor',
    CONSTRAINT CK_Orders_Status CHECK (OrderStatus IN ('Hazırlanıyor', 'Kargoya Verildi', 'Teslim Edildi', 'İptal Edildi')),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

-- E. Tablo: OrderDetails (Sipariş Detayları - Çoka Çok İlişkiyi Çözen Ara Tablo)
-- Mühendislik Dokunuşu: Sipariş adedi en az 1 olmalıdır (Quantity > 0)
CREATE TABLE OrderDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO


-- ====================================================================
-- BÖLÜM 2: Veri Girişi (DML - Insert)
-- ====================================================================

-- Görev 1: 5 Adet Gaming & Tech Kategorisi Ekleme
INSERT INTO Categories (CategoryName) VALUES 
('Gaming Ekipmanları'),
('Monitör & Ekran'),
('Donanım & Bileşen'),
('Yazılımcı Kitapları'),
('Yayıncı & Stüdyo');
GO

-- Görev 2: Her Kategoriye Ait Toplam 15 Gerçekçi Ürün Ekleme
INSERT INTO Products (ProductName, Price, Stock, CategoryID) VALUES 
-- Gaming Ekipmanları (CategoryID: 1)
('SteelSeries Apex Pro Mekanik Klavye', 6499.00, 25, 1),
('Logitech G Pro X Superlight 2 Mouse', 4899.00, 15, 1),
('Razer BlackShark V2 Pro Kulaklık', 5250.00, 8, 1),

-- Monitör & Ekran (CategoryID: 2)
('ASUS ROG Swift 27" 240Hz Gaming Monitör', 18500.00, 10, 2),
('Dell UltraSharp 34" Kavisli Yazılımcı Monitörü', 24900.00, 5, 2),
('Samsung Odyssey G7 28" 4K Monitör', 16200.00, 14, 2),

-- Donanım & Bileşen (CategoryID: 3)
('NVIDIA GeForce RTX 4070 Ti Super 16GB', 33500.00, 12, 3),
('AMD Ryzen 7 7800X3D İşlemci', 15200.00, 30, 3),
('Corsair Vengeance 32GB (2x16) DDR5 6000MHz RAM', 4650.00, 45, 3),

-- Yazılımcı Kitapları (CategoryID: 4)
('Clean Code (Temiz Kod) - Robert C. Martin', 450.00, 50, 4),
('T-SQL ile İleri Seviye Veritabanı Programlama', 380.00, 60, 4),
('Yapay Zeka ve Derin Öğrenme Mimarileri', 520.00, 18, 4),

-- Yayıncı & Stüdyo (CategoryID: 5)
('Elgato Stream Deck MK.2', 5999.00, 22, 5),
('Shure SM7B Dinamik Vokal Mikrofonu', 14800.00, 7, 5),
('Elgato Key Light Air Profesyonel Işık', 4750.00, 16, 5);
GO

-- Görev 3: 6 Adet Müşteri Kaydı Oluşturma
INSERT INTO Customers (FullName, City, Email) VALUES 
('Ahmet Yılmaz', 'İstanbul', 'ahmet.yilmaz@devmail.com'),
('Sefa Yusuf Kütük', 'Ankara', 'sefa.kutuk@devmail.com'),
('Ayşe Kaya', 'İzmir', 'ayse.kaya@devmail.com'),
('Mehmet Demir', 'Bursa', 'mehmet.demir@devmail.com'),
('Zeynep Çelik', 'Antalya', 'zeynep.celik@devmail.com'),
('Caner Özkan', 'İstanbul', 'caner.ozkan@devmail.com');
GO

-- Görev 4: Farklı Tarihlerde 8 Adet Sipariş ve Detay Kaydı
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, OrderStatus) VALUES 
(1, DATEADD(DAY, -45, GETDATE()), 11398.00, 'Teslim Edildi'),
(2, DATEADD(DAY, -30, GETDATE()), 33500.00, 'Teslim Edildi'),
(3, DATEADD(DAY, -20, GETDATE()), 18500.00, 'Teslim Edildi'),
(1, DATEADD(DAY, -12, GETDATE()), 830.00, 'Teslim Edildi'),
(4, DATEADD(DAY, -7, GETDATE()), 19850.00, 'Kargoya Verildi'),
(5, DATEADD(DAY, -3, GETDATE()), 5999.00, 'Kargoya Verildi'),
(2, DATEADD(DAY, -1, GETDATE()), 6499.00, 'Hazırlanıyor'),
(6, GETDATE(), 4899.00, 'Hazırlanıyor');
GO

INSERT INTO OrderDetails (OrderID, ProductID, Quantity) VALUES 
(1, 1, 1),
(1, 2, 1),
(2, 7, 1),
(3, 4, 1),
(4, 10, 1),
(4, 11, 1),
(5, 8, 1),
(5, 9, 1),
(6, 13, 1),
(7, 1, 1),
(8, 2, 1);
GO


-- ====================================================================
-- BÖLÜM 3: Sorgulama ve Analiz (DQL - Select ve Joins)
-- ====================================================================

-- 1. Temel Listeleme (Stok < 20 olan ürünlerin azalan sırada listesi)
SELECT 
    ProductName AS [Ürün Adı],
    Stock AS [Mevcut Stok],
    Price AS [Fiyat (TL)]
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;
GO

-- 2. Veri Birleştirme (JOIN: Müşteri Adı, Şehir, Sipariş Tarihi ve Toplam Tutar)
SELECT 
    c.FullName AS [Müşteri Adı],
    c.City AS [Şehir],
    o.OrderDate AS [Sipariş Tarihi],
    o.TotalAmount AS [Toplam Tutar (TL)],
    o.OrderStatus AS [Sipariş Durumu]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate DESC;
GO

-- 3. Çoklu Birleştirme ve Detay Raporu (5 Tablolu Zincirleme JOIN)
SELECT 
    c.FullName AS [Müşteri],
    p.ProductName AS [Satın Alınan Ürün],
    cat.CategoryName AS [Kategori],
    p.Price AS [Birim Fiyat (TL)],
    od.Quantity AS [Adet]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.FullName = 'Ahmet Yılmaz';
GO

-- 4. Gruplama ve Aggregate Fonksiyonlar (Kategori Başına Ürün Çeşidi Sayısı)
SELECT 
    c.CategoryName AS [Kategori Adı],
    COUNT(p.ProductID) AS [Toplam Ürün Çeşidi]
FROM Categories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY [Toplam Ürün Çeşidi] DESC;
GO

-- 5. Ciro Analizi (En Çok Harcayan Müşteriden En Aza Doğru Sıralama)
SELECT 
    c.FullName AS [Müşteri Adı],
    c.City AS [Şehir],
    COUNT(o.OrderID) AS [Sipariş Sayısı],
    SUM(o.TotalAmount) AS [Toplam Kazandırdığı Ciro (TL)]
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.FullName, c.City
ORDER BY [Toplam Kazandırdığı Ciro (TL)] DESC;
GO

-- 6. Zaman Analizi (Bugünün Tarihine Göre Siparişlerin Üzerinden Kaç Gün Geçti?)
SELECT 
    o.OrderID AS [Sipariş No],
    c.FullName AS [Müşteri],
    o.OrderDate AS [Sipariş Tarihi],
    DATEDIFF(DAY, o.OrderDate, GETDATE()) AS [Geçen Gün Sayısı],
    o.OrderStatus AS [Güncel Durum]
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY [Geçen Gün Sayısı] DESC;
GO


-- ====================================================================
-- BÖLÜM 4: İleri Seviye Veri Tabanı Nesneleri
-- ====================================================================

-- 1. View (Görünüm) Oluşturma: vw_SiparisOzet
IF OBJECT_ID('vw_SiparisOzet', 'V') IS NOT NULL
    DROP VIEW vw_SiparisOzet;
GO

CREATE VIEW vw_SiparisOzet AS
SELECT 
    c.FullName AS [Müşteri Adı],
    o.OrderDate AS [Sipariş Tarihi],
    p.ProductName AS [Ürün Adı],
    od.Quantity AS [Adet],
    p.Price AS [Birim Fiyat (TL)],
    (od.Quantity * p.Price) AS [Satır Toplamı (TL)],
    o.OrderStatus AS [Sipariş Durumu]
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;
GO

-- View Testi
SELECT * FROM vw_SiparisOzet;
GO

-- 2. Yedekleme (Backup) Komutu
-- C:\Yedek klasörüne NovaStoreDB.bak olarak yedekler
BACKUP DATABASE NovaStoreDB
TO DISK = 'C:\Yedek\NovaStoreDB.bak'
WITH FORMAT,
     MEDIANAME = 'NovaStore_SQL_Backup',
     NAME = 'NovaStoreDB Tam Sistem Yedegi';
GO


-- ====================================================================
-- MÜHENDİSLİK FARKI: OTOMASYON, TRIGGER VE AKILLI HATA YÖNETİMİ
-- ====================================================================

-- A. Otomatik Stok Düşürme Tetikleyicisi (TRIGGER)
IF OBJECT_ID('trg_StokOtomatikDusur', 'TR') IS NOT NULL
    DROP TRIGGER trg_StokOtomatikDusur;
GO

CREATE TRIGGER trg_StokOtomatikDusur
ON OrderDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET p.Stock = p.Stock - i.Quantity
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    PRINT '>> [OTOMASYON BİLDİRİMİ]: Ürün stoğu sipariş adedi kadar otomatik düşürüldü.';
END;
GO

-- B. Tüm Hataları Ayrı Bildiren ve Siparişi Güvenle Yöneten STORED PROCEDURE
IF OBJECT_ID('sp_AkilliSiparisVer', 'P') IS NOT NULL
    DROP PROCEDURE sp_AkilliSiparisVer;
GO

CREATE PROCEDURE sp_AkilliSiparisVer
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Kontrol 1: Adet pozitif mi?
        IF @Quantity <= 0
        BEGIN
            RAISERROR('HATA BİLDİRİMİ: Sipariş adedi en az 1 olmalıdır!', 16, 1);
            RETURN;
        END

        -- Kontrol 2: Müşteri sistemde kayıtlı mı?
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = @CustomerID)
        BEGIN
            DECLARE @HataCust VARCHAR(100) = 'HATA BİLDİRİMİ: ' + CAST(@CustomerID AS VARCHAR) + ' numaralı Müşteri sistemde kayıtlı değildir!';
            RAISERROR(@HataCust, 16, 1);
            RETURN;
        END

        -- Kontrol 3: Ürün sistemde var mı?
        IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
        BEGIN
            DECLARE @HataProd VARCHAR(100) = 'HATA BİLDİRİMİ: ' + CAST(@ProductID AS VARCHAR) + ' numaralı Ürün sistemde bulunamadı!';
            RAISERROR(@HataProd, 16, 1);
            RETURN;
        END

        -- Kontrol 4: Stok yeterli mi?
        DECLARE @MevcutStok INT;
        DECLARE @BirimFiyat DECIMAL(10,2);
        DECLARE @UrunAdi VARCHAR(100);

        SELECT @MevcutStok = Stock, @BirimFiyat = Price, @UrunAdi = ProductName
        FROM Products 
        WHERE ProductID = @ProductID;

        IF @MevcutStok < @Quantity
        BEGIN
            DECLARE @HataStok VARCHAR(250);
            SET @HataStok = 'HATA BİLDİRİMİ: "' + @UrunAdi + '" için yetersiz stok! Mevcut Stok: ' + CAST(@MevcutStok AS VARCHAR) + ', Talep Edilen: ' + CAST(@Quantity AS VARCHAR);
            RAISERROR(@HataStok, 16, 1);
            RETURN;
        END

        -- Kontroller geçildiyse siparişi TRANSACTION ile güvenle oluştur
        BEGIN TRANSACTION;
            DECLARE @YeniOrderID INT;
            DECLARE @ToplamTutar DECIMAL(10,2) = @BirimFiyat * @Quantity;

            INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, OrderStatus)
            VALUES (@CustomerID, GETDATE(), @ToplamTutar, 'Hazırlanıyor');

            SET @YeniOrderID = SCOPE_IDENTITY();

            -- Tetikleyici (Trigger) burada devreye girip stoğu düşecektir
            INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
            VALUES (@YeniOrderID, @ProductID, @Quantity);

        COMMIT TRANSACTION;

        SELECT 
            'BAŞARILI' AS [İşlem Durumu],
            'Siparişiniz başarıyla oluşturuldu ve stok trigger tarafından düşürüldü.' AS [Bilgilendirme],
            @YeniOrderID AS [Yeni Sipariş No],
            @UrunAdi AS [Satın Alınan Ürün],
            @Quantity AS [Adet],
            @ToplamTutar AS [Toplam Ödenen (TL)];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 
            'İŞLEM BAŞARISIZ' AS [İşlem Durumu],
            ERROR_MESSAGE() AS [Hata Açıklaması];
    END CATCH
END;
GO
