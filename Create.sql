/* =====================================================
   WEBSITE BÁN XE MOTO - SQL Server (T-SQL)
   Chạy toàn bộ file trong SSMS. Gồm: tạo bảng, trigger, dữ liệu mẫu.
   ===================================================== */
IF DB_ID(N'WebBanXeMoto') IS NULL CREATE DATABASE WebBanXeMoto;
GO
USE WebBanXeMoto;
GO

/* ---------- 1. DANH MỤC XE ---------- */
CREATE TABLE HangXe (
    MaHang  INT IDENTITY(1,1) PRIMARY KEY,
    TenHang NVARCHAR(100) NOT NULL UNIQUE,
    QuocGia NVARCHAR(100), Logo NVARCHAR(255), MoTa NVARCHAR(500)
);
CREATE TABLE LoaiXe (
    MaLoai  INT IDENTITY(1,1) PRIMARY KEY,
    TenLoai NVARCHAR(100) NOT NULL UNIQUE,
    MoTa    NVARCHAR(500)
);
CREATE TABLE Xe (
    MaXe        INT IDENTITY(1,1) PRIMARY KEY,
    MaHang      INT NOT NULL REFERENCES HangXe(MaHang),
    MaLoai      INT NOT NULL REFERENCES LoaiXe(MaLoai),
    TenXe       NVARCHAR(200) NOT NULL,
    NamSanXuat  INT CHECK (NamSanXuat BETWEEN 1990 AND 2100),
    GiaNiemYet  DECIMAL(18,0) NOT NULL CHECK (GiaNiemYet >= 0),
    DungTichCC  INT CHECK (DungTichCC > 0),
    CongSuatKW  DECIMAL(6,1) CHECK (CongSuatKW > 0),
    HopSo       NVARCHAR(50), KieuDanDong NVARCHAR(50),
    SoCho       INT NOT NULL DEFAULT 2 CHECK (SoCho > 0),
    MoTa        NVARCHAR(500),
    HienThi     BIT NOT NULL DEFAULT 1
);
CREATE TABLE MauXe (
    MaMau  INT IDENTITY(1,1) PRIMARY KEY,
    MaXe   INT NOT NULL REFERENCES Xe(MaXe),
    TenMau NVARCHAR(50) NOT NULL,
    MaHex  VARCHAR(7),
    UNIQUE (MaXe, TenMau),
    UNIQUE (MaMau, MaXe)          -- để các bảng khác ràng buộc "màu phải thuộc đúng mẫu xe"
);
CREATE TABLE AnhXe (
    MaAnh      INT IDENTITY(1,1) PRIMARY KEY,
    MaXe       INT NOT NULL REFERENCES Xe(MaXe),
    MaMau      INT NULL,
    DuongDan   NVARCHAR(255) NOT NULL,
    LaAnhChinh BIT NOT NULL DEFAULT 0,
    ThuTu      INT NOT NULL DEFAULT 0,
    FOREIGN KEY (MaMau, MaXe) REFERENCES MauXe(MaMau, MaXe)
);
CREATE UNIQUE INDEX UX_AnhXe_AnhChinh ON AnhXe(MaXe) WHERE LaAnhChinh = 1;   -- mỗi xe 1 ảnh chính

/* ---------- 2. NHÂN SỰ, TÀI KHOẢN, PHÂN QUYỀN ---------- */
CREATE TABLE ChucVu (
    MaChucVu   INT IDENTITY(1,1) PRIMARY KEY,
    TenChucVu  NVARCHAR(100) NOT NULL UNIQUE,
    LuongCoBan DECIMAL(18,0) NOT NULL CHECK (LuongCoBan >= 0),
    ToanQuyen  BIT NOT NULL DEFAULT 0,          -- 1 = quản lý, toàn quyền
    MoTa       NVARCHAR(500)
);
CREATE TABLE NhanVien (
    MaNV        INT IDENTITY(1,1) PRIMARY KEY,
    MaChucVu    INT NOT NULL REFERENCES ChucVu(MaChucVu),
    MaQuanLy    INT NULL REFERENCES NhanVien(MaNV),   -- quản lý trực tiếp, người đứng đầu để NULL
    HoTen       NVARCHAR(100) NOT NULL,
    NgaySinh    DATE, SoDienThoai VARCHAR(15),
    Email       VARCHAR(150) NOT NULL UNIQUE,
    DiaChi      NVARCHAR(255),
    NgayVaoLam  DATE NOT NULL DEFAULT (CONVERT(DATE, GETDATE())),
    HeSoLuong   DECIMAL(4,2) NOT NULL DEFAULT 1 CHECK (HeSoLuong > 0),   -- lương = LuongCoBan x HeSoLuong
    TrangThai   NVARCHAR(20) NOT NULL DEFAULT N'DangLam' CHECK (TrangThai IN (N'DangLam', N'NghiViec')),
    CHECK (MaQuanLy IS NULL OR MaQuanLy <> MaNV)
);
CREATE TABLE TaiKhoanNhanVien (
    MaTKNV            INT IDENTITY(1,1) PRIMARY KEY,
    MaNV              INT NOT NULL UNIQUE REFERENCES NhanVien(MaNV),
    MaNguoiCap        INT NULL REFERENCES NhanVien(MaNV),   -- NULL chỉ cho tài khoản quản lý đầu tiên
    TenDangNhap       VARCHAR(50) NOT NULL UNIQUE,
    MatKhauHash       VARCHAR(255) NOT NULL,                -- chỉ lưu hash, không lưu mật khẩu thật
    NgayCap           DATETIME NOT NULL DEFAULT GETDATE(),
    BatBuocDoiMatKhau BIT NOT NULL DEFAULT 1,               -- 1 khi mới cấp, nhân viên phải tự đổi
    NgayDoiMatKhau    DATETIME NULL,
    TrangThai         BIT NOT NULL DEFAULT 1
);
CREATE TABLE Quyen (
    MaQuyen      INT IDENTITY(1,1) PRIMARY KEY,
    KyHieu       VARCHAR(50) NOT NULL UNIQUE,
    TenQuyen     NVARCHAR(100) NOT NULL,
    NhomChucNang NVARCHAR(50),
    MoTa         NVARCHAR(255)
);
CREATE TABLE NhanVienQuyen (
    MaNV       INT NOT NULL REFERENCES NhanVien(MaNV),
    MaQuyen    INT NOT NULL REFERENCES Quyen(MaQuyen),
    MaNguoiCap INT NOT NULL REFERENCES NhanVien(MaNV),
    NgayCap    DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (MaNV, MaQuyen)
);

/* ---------- 3. KHÁCH HÀNG ---------- */
CREATE TABLE KhachHang (
    MaKH        INT IDENTITY(1,1) PRIMARY KEY,
    HoTen       NVARCHAR(100) NOT NULL,
    Email       VARCHAR(150) NOT NULL UNIQUE,
    SoDienThoai VARCHAR(15),
    DiaChi      NVARCHAR(255),
    NgaySinh    DATE,
    NgayDangKy  DATETIME NOT NULL DEFAULT GETDATE()
);
CREATE TABLE TaiKhoanKhachHang (
    MaTKKH      INT IDENTITY(1,1) PRIMARY KEY,
    MaKH        INT NOT NULL UNIQUE REFERENCES KhachHang(MaKH),
    TenDangNhap VARCHAR(50) NOT NULL UNIQUE,
    MatKhauHash VARCHAR(255) NOT NULL,
    NgayTao     DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai   BIT NOT NULL DEFAULT 1
);

/* ---------- 4. NHẬP KHO ---------- */
CREATE TABLE NhaCungCap (
    MaNCC       INT IDENTITY(1,1) PRIMARY KEY,
    TenNCC      NVARCHAR(150) NOT NULL UNIQUE,
    SoDienThoai VARCHAR(15), Email VARCHAR(150), DiaChi NVARCHAR(255),
    TrangThai   BIT NOT NULL DEFAULT 1
);
CREATE TABLE PhieuNhap (
    MaPN     INT IDENTITY(1,1) PRIMARY KEY,
    MaNCC    INT NOT NULL REFERENCES NhaCungCap(MaNCC),
    MaNV     INT NOT NULL REFERENCES NhanVien(MaNV),
    NgayNhap DATE NOT NULL DEFAULT (CONVERT(DATE, GETDATE())),
    GhiChu   NVARCHAR(500)
);
CREATE TABLE XeThucTe (
    MaXeThucTe INT IDENTITY(1,1) PRIMARY KEY,
    MaXe       INT NOT NULL,
    MaMau      INT NOT NULL,
    MaPN       INT NOT NULL REFERENCES PhieuNhap(MaPN),
    SoKhung    VARCHAR(30) NOT NULL UNIQUE,
    SoMay      VARCHAR(30) NOT NULL UNIQUE,
    BienSo     VARCHAR(15) NULL,
    GiaNhap    DECIMAL(18,0) NOT NULL CHECK (GiaNhap >= 0),   -- chỉ quản lý / quyền XEM_GIA_NHAP mới được xem
    TrangThai  NVARCHAR(20) NOT NULL DEFAULT N'ConHang' CHECK (TrangThai IN (N'ConHang', N'DaBan', N'BaoTri')),
    FOREIGN KEY (MaMau, MaXe) REFERENCES MauXe(MaMau, MaXe)
);
CREATE UNIQUE INDEX UX_XeThucTe_BienSo ON XeThucTe(BienSo) WHERE BienSo IS NOT NULL;

/* ---------- 5. ĐƠN HÀNG, THANH TOÁN, HÓA ĐƠN ---------- */
CREATE TABLE KhuyenMai (
    MaKM       INT IDENTITY(1,1) PRIMARY KEY,
    MaCode     VARCHAR(30) NOT NULL UNIQUE,
    LoaiGiam   NVARCHAR(20) NOT NULL CHECK (LoaiGiam IN (N'PhanTram', N'SoTien')),
    GiaTri     DECIMAL(18,2) NOT NULL CHECK (GiaTri > 0),
    NgayBatDau DATE NOT NULL, NgayKetThuc DATE NOT NULL,
    TrangThai  BIT NOT NULL DEFAULT 1,
    CHECK (NgayKetThuc >= NgayBatDau)
);
CREATE TABLE DonHang (
    MaDonHang    INT IDENTITY(1,1) PRIMARY KEY,
    MaKH         INT NOT NULL REFERENCES KhachHang(MaKH),
    MaKM         INT NULL REFERENCES KhuyenMai(MaKM),
    MaNV         INT NULL REFERENCES NhanVien(MaNV),          -- nhân viên xử lý
    NgayDat      DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai    NVARCHAR(30) NOT NULL DEFAULT N'ChoXacNhan'
                 CHECK (TrangThai IN (N'ChoXacNhan', N'DaXacNhan', N'DangGiao', N'HoanTat', N'DaHuy')),
    TenNguoiNhan NVARCHAR(100) NOT NULL,
    SDTNguoiNhan VARCHAR(15) NOT NULL,
    DiaChiGiao   NVARCHAR(255) NOT NULL,
    PhiVanChuyen DECIMAL(18,0) NOT NULL DEFAULT 0 CHECK (PhiVanChuyen >= 0),
    GiamGia      DECIMAL(18,0) NOT NULL DEFAULT 0 CHECK (GiamGia >= 0),
    TongTien     DECIMAL(18,0) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),   -- trigger tự tính
    GhiChu       NVARCHAR(500)
);
CREATE TABLE ChiTietDonHang (
    MaCT      INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL REFERENCES DonHang(MaDonHang),
    MaXe      INT NOT NULL,
    MaMau     INT NOT NULL,
    SoLuong   INT NOT NULL CHECK (SoLuong > 0),
    DonGia    DECIMAL(18,0) NOT NULL CHECK (DonGia >= 0),     -- giá chốt lúc đặt
    ThanhTien AS (SoLuong * DonGia) PERSISTED,
    FOREIGN KEY (MaMau, MaXe) REFERENCES MauXe(MaMau, MaXe)
);
CREATE TABLE LichSuDonHang (
    MaLS      INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL REFERENCES DonHang(MaDonHang),
    MaNV      INT NULL REFERENCES NhanVien(MaNV),
    TrangThai NVARCHAR(30) NOT NULL,
    ThoiGian  DATETIME NOT NULL DEFAULT GETDATE(),
    GhiChu    NVARCHAR(500)
);
CREATE TABLE ThanhToan (
    MaThanhToan   INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang     INT NOT NULL REFERENCES DonHang(MaDonHang),
    LoaiThanhToan NVARCHAR(30) NOT NULL CHECK (LoaiThanhToan IN (N'DatCoc', N'ThanhToanDu')),
    PhuongThuc    NVARCHAR(50) NOT NULL,
    SoTien        DECIMAL(18,0) NOT NULL CHECK (SoTien > 0),
    NgayThanhToan DATETIME NOT NULL DEFAULT GETDATE(),
    MaGiaoDich    VARCHAR(100) NULL,
    TrangThai     NVARCHAR(30) NOT NULL DEFAULT N'ThanhCong'
                  CHECK (TrangThai IN (N'ChoXuLy', N'ThanhCong', N'ThatBai', N'HoanTien'))
);
CREATE TABLE HoaDon (
    MaHD      INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL UNIQUE REFERENCES DonHang(MaDonHang),   -- mỗi đơn tối đa 1 hóa đơn
    MaNV      INT NOT NULL REFERENCES NhanVien(MaNV),
    SoHoaDon  VARCHAR(30) NOT NULL UNIQUE,
    NgayLap   DATETIME NOT NULL DEFAULT GETDATE(),
    TongTien  DECIMAL(18,0) NOT NULL CHECK (TongTien >= 0)
);
CREATE TABLE ChiTietHoaDon (
    MaCTHD     INT IDENTITY(1,1) PRIMARY KEY,
    MaHD       INT NOT NULL REFERENCES HoaDon(MaHD),
    MaCT       INT NOT NULL REFERENCES ChiTietDonHang(MaCT),
    MaXeThucTe INT NOT NULL UNIQUE REFERENCES XeThucTe(MaXeThucTe),   -- một chiếc chỉ bán một lần
    DonGia     DECIMAL(18,0) NOT NULL CHECK (DonGia >= 0)             -- giá bán thực tế
);

/* ---------- 6. BẢO HÀNH ---------- */
CREATE TABLE GoiBaoHanh (
    MaGoiBH INT IDENTITY(1,1) PRIMARY KEY,
    TenGoi  NVARCHAR(100) NOT NULL,
    SoThang INT NOT NULL CHECK (SoThang > 0),
    SoKm    INT NULL CHECK (SoKm > 0),
    GiaTien DECIMAL(18,0) NOT NULL DEFAULT 0 CHECK (GiaTien >= 0),
    MoTa    NVARCHAR(500)
);
CREATE TABLE BaoHanh (
    MaBH       INT IDENTITY(1,1) PRIMARY KEY,
    MaXeThucTe INT NOT NULL REFERENCES XeThucTe(MaXeThucTe),
    MaGoiBH    INT NOT NULL REFERENCES GoiBaoHanh(MaGoiBH),
    NgayBatDau DATE NOT NULL, NgayKetThuc DATE NOT NULL,
    TrangThai  NVARCHAR(30) NOT NULL DEFAULT N'ConHan' CHECK (TrangThai IN (N'ConHan', N'HetHan', N'Huy')),
    GhiChu     NVARCHAR(500),
    CHECK (NgayKetThuc >= NgayBatDau)
);
CREATE TABLE PhieuBaoHanh (
    MaPBH         INT IDENTITY(1,1) PRIMARY KEY,
    MaBH          INT NOT NULL REFERENCES BaoHanh(MaBH),
    MaNV          INT NULL REFERENCES NhanVien(MaNV),          -- người tiếp nhận
    NgayTiepNhan  DATETIME NOT NULL DEFAULT GETDATE(),
    NoiDungLoi    NVARCHAR(500) NOT NULL,
    KetQuaXuLy    NVARCHAR(500),
    ChiPhi        DECIMAL(18,0) NOT NULL DEFAULT 0 CHECK (ChiPhi >= 0),   -- 0 nếu trong bảo hành
    NgayHoanThanh DATETIME NULL,
    TrangThai     NVARCHAR(30) NOT NULL DEFAULT N'DaTiepNhan'
                  CHECK (TrangThai IN (N'DaTiepNhan', N'DangSua', N'HoanThanh'))
);

/* ---------- 7. TƯƠNG TÁC KHÁCH HÀNG & NHẬT KÝ ---------- */
CREATE TABLE YeuThich (
    MaKH    INT NOT NULL REFERENCES KhachHang(MaKH),
    MaXe    INT NOT NULL REFERENCES Xe(MaXe),
    NgayThem DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (MaKH, MaXe)
);
CREATE TABLE DanhGia (
    MaDanhGia   INT IDENTITY(1,1) PRIMARY KEY,
    MaKH        INT NOT NULL REFERENCES KhachHang(MaKH),
    MaXe        INT NOT NULL REFERENCES Xe(MaXe),
    MaCT        INT NULL REFERENCES ChiTietDonHang(MaCT),     -- có giá trị = đã mua xe
    SoSao       INT NOT NULL CHECK (SoSao BETWEEN 1 AND 5),
    NoiDung     NVARCHAR(1000),
    NgayDanhGia DATETIME NOT NULL DEFAULT GETDATE(),
    UNIQUE (MaKH, MaXe)
);
CREATE UNIQUE INDEX UX_DanhGia_MaCT ON DanhGia(MaCT) WHERE MaCT IS NOT NULL;
CREATE TABLE LichLaiThu (
    MaLich    INT IDENTITY(1,1) PRIMARY KEY,
    MaKH      INT NOT NULL REFERENCES KhachHang(MaKH),
    MaXe      INT NOT NULL REFERENCES Xe(MaXe),
    NgayHen   DATETIME NOT NULL,
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'ChoXacNhan'
              CHECK (TrangThai IN (N'ChoXacNhan', N'DaXacNhan', N'HoanThanh', N'DaHuy')),
    GhiChu    NVARCHAR(500)
);
CREATE TABLE NhatKyHeThong (
    MaNK        INT IDENTITY(1,1) PRIMARY KEY,
    MaNV        INT NULL REFERENCES NhanVien(MaNV),
    HanhDong    NVARCHAR(50) NOT NULL,
    BangTacDong NVARCHAR(50),
    MaBanGhi    INT NULL,
    ChiTiet     NVARCHAR(1000),
    ThoiGian    DATETIME NOT NULL DEFAULT GETDATE()
);
GO

/* =====================================================
   TRIGGER - các quy tắc bảng không tự ép được
   ===================================================== */

-- Quy tắc: DonHang.TongTien = tổng ThanhTien các dòng + phí vận chuyển - giảm giá
CREATE TRIGGER TR_ChiTietDonHang_TongTien ON ChiTietDonHang AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE d SET TongTien = ISNULL((SELECT SUM(c.ThanhTien) FROM ChiTietDonHang c WHERE c.MaDonHang = d.MaDonHang), 0)
                            + d.PhiVanChuyen - d.GiamGia
    FROM DonHang d
    WHERE d.MaDonHang IN (SELECT MaDonHang FROM inserted UNION SELECT MaDonHang FROM deleted);
END
GO

-- Quy tắc 1, 2: lập ChiTietHoaDon
CREATE TRIGGER TR_ChiTietHoaDon_Insert ON ChiTietHoaDon AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN HoaDon h ON h.MaHD = i.MaHD
               JOIN ChiTietDonHang c ON c.MaCT = i.MaCT WHERE c.MaDonHang <> h.MaDonHang)
    BEGIN RAISERROR(N'Dòng đơn hàng không thuộc đơn hàng của hóa đơn này.', 16, 1); ROLLBACK TRANSACTION; RETURN; END

    IF EXISTS (SELECT 1 FROM inserted i JOIN ChiTietDonHang c ON c.MaCT = i.MaCT
               JOIN XeThucTe x ON x.MaXeThucTe = i.MaXeThucTe
               WHERE x.MaXe <> c.MaXe OR x.MaMau <> c.MaMau OR x.TrangThai <> N'ConHang')
    BEGIN RAISERROR(N'Xe phải đúng mẫu, đúng màu của dòng đơn và đang ở trạng thái ConHang.', 16, 1); ROLLBACK TRANSACTION; RETURN; END

    IF EXISTS (SELECT 1 FROM ChiTietDonHang c WHERE c.MaCT IN (SELECT MaCT FROM inserted)
               AND (SELECT COUNT(*) FROM ChiTietHoaDon h WHERE h.MaCT = c.MaCT) > c.SoLuong)
    BEGIN RAISERROR(N'Số xe lập hóa đơn vượt quá số lượng đã đặt.', 16, 1); ROLLBACK TRANSACTION; RETURN; END

    UPDATE XeThucTe SET TrangThai = N'DaBan' WHERE MaXeThucTe IN (SELECT MaXeThucTe FROM inserted);
END
GO

-- Quy tắc 3, 4: lập HoaDon (phải thanh toán đủ, tổng tiền khớp đơn hàng)
CREATE TRIGGER TR_HoaDon_Insert ON HoaDon AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN DonHang d ON d.MaDonHang = i.MaDonHang WHERE i.TongTien <> d.TongTien)
    BEGIN RAISERROR(N'Tổng tiền hóa đơn phải bằng tổng tiền đơn hàng.', 16, 1); ROLLBACK TRANSACTION; RETURN; END

    IF EXISTS (SELECT 1 FROM inserted i JOIN DonHang d ON d.MaDonHang = i.MaDonHang
               WHERE ISNULL((SELECT SUM(t.SoTien) FROM ThanhToan t
                             WHERE t.MaDonHang = d.MaDonHang AND t.TrangThai = N'ThanhCong'), 0) < d.TongTien)
    BEGIN RAISERROR(N'Đơn hàng chưa thanh toán đủ, chưa thể lập hóa đơn.', 16, 1); ROLLBACK TRANSACTION; RETURN; END
END
GO

-- Quy tắc 5: luôn còn ít nhất một quản lý đang hoạt động (có tài khoản đang mở)
CREATE FUNCTION dbo.fn_SoQuanLyHoatDong() RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM NhanVien n
            JOIN ChucVu c ON c.MaChucVu = n.MaChucVu
            JOIN TaiKhoanNhanVien t ON t.MaNV = n.MaNV
            WHERE c.ToanQuyen = 1 AND n.TrangThai = N'DangLam' AND t.TrangThai = 1);
END
GO
CREATE TRIGGER TR_NhanVien_GiuQuanLy ON NhanVien AFTER UPDATE, DELETE AS
BEGIN
    IF dbo.fn_SoQuanLyHoatDong() = 0
    BEGIN RAISERROR(N'Hệ thống phải còn ít nhất một quản lý đang hoạt động.', 16, 1); ROLLBACK TRANSACTION; END
END
GO
CREATE TRIGGER TR_TaiKhoanNhanVien_GiuQuanLy ON TaiKhoanNhanVien AFTER UPDATE, DELETE AS
BEGIN
    IF dbo.fn_SoQuanLyHoatDong() = 0
    BEGIN RAISERROR(N'Hệ thống phải còn ít nhất một quản lý đang hoạt động.', 16, 1); ROLLBACK TRANSACTION; END
END
GO
CREATE TRIGGER TR_ChucVu_GiuQuanLy ON ChucVu AFTER UPDATE, DELETE AS
BEGIN
    IF dbo.fn_SoQuanLyHoatDong() = 0
    BEGIN RAISERROR(N'Hệ thống phải còn ít nhất một quản lý đang hoạt động.', 16, 1); ROLLBACK TRANSACTION; END
END
GO

-- Quy tắc 6: người cấp tài khoản / cấp quyền phải là quản lý (ChucVu.ToanQuyen = 1)
CREATE TRIGGER TR_TaiKhoanNhanVien_NguoiCap ON TaiKhoanNhanVien AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted i WHERE i.MaNguoiCap IS NOT NULL AND NOT EXISTS
               (SELECT 1 FROM NhanVien n JOIN ChucVu c ON c.MaChucVu = n.MaChucVu
                WHERE n.MaNV = i.MaNguoiCap AND c.ToanQuyen = 1))
    BEGIN RAISERROR(N'Chỉ quản lý mới được cấp tài khoản cho nhân viên.', 16, 1); ROLLBACK TRANSACTION; END
END
GO
CREATE TRIGGER TR_NhanVienQuyen_NguoiCap ON NhanVienQuyen AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS
               (SELECT 1 FROM NhanVien n JOIN ChucVu c ON c.MaChucVu = n.MaChucVu
                WHERE n.MaNV = i.MaNguoiCap AND c.ToanQuyen = 1))
    BEGIN RAISERROR(N'Chỉ quản lý mới được cấp quyền cho nhân viên.', 16, 1); ROLLBACK TRANSACTION; END
END
GO

/* =====================================================
   DỮ LIỆU MẪU TỐI THIỂU (chạy sau khi tạo xong trigger)
   ===================================================== */
INSERT INTO ChucVu (TenChucVu, LuongCoBan, ToanQuyen, MoTa) VALUES
    (N'Quản lý',            20000000, 1, N'Toàn quyền điều hành website'),
    (N'Nhân viên bán hàng',  9000000, 0, N'Xử lý đơn hàng, tư vấn khách'),
    (N'Nhân viên kho',       8000000, 0, N'Nhập kho, quản lý xe thực tế');

-- Quản lý đầu tiên (MaQuanLy và MaNguoiCap để NULL). Thay MatKhauHash bằng hash thật do ứng dụng tạo.
INSERT INTO NhanVien (MaChucVu, HoTen, Email) VALUES
    ((SELECT MaChucVu FROM ChucVu WHERE TenChucVu = N'Quản lý'), N'Quản lý hệ thống', 'quanly@example.com');
INSERT INTO TaiKhoanNhanVien (MaNV, TenDangNhap, MatKhauHash)
    VALUES ((SELECT MaNV FROM NhanVien WHERE Email = 'quanly@example.com'), 'admin', 'THAY_BANG_HASH_THAT');

INSERT INTO Quyen (KyHieu, TenQuyen, NhomChucNang, MoTa) VALUES
    ('QUAN_LY_XE',          N'Quản lý xe',          N'Xe',        N'Thêm, sửa mẫu xe, màu, ảnh, hãng, loại'),
    ('QUAN_LY_KHO',         N'Quản lý kho',         N'Xe',        N'Lập phiếu nhập, quản lý xe thực tế, nhà cung cấp'),
    ('XEM_GIA_NHAP',        N'Xem giá nhập',        N'Xe',        N'Xem giá nhập và lợi nhuận'),
    ('XU_LY_DON',           N'Xử lý đơn hàng',      N'Bán hàng',  N'Duyệt đơn, cập nhật trạng thái, lập hóa đơn và giao xe'),
    ('QUAN_LY_THANH_TOAN',  N'Quản lý thanh toán',  N'Bán hàng',  N'Ghi nhận đặt cọc và thanh toán'),
    ('QUAN_LY_KHUYEN_MAI',  N'Quản lý khuyến mãi',  N'Bán hàng',  N'Tạo và sửa khuyến mãi'),
    ('QUAN_LY_BAO_HANH',    N'Quản lý bảo hành',    N'Hậu mãi',   N'Tạo và cập nhật bảo hành, gói bảo hành'),
    ('QUAN_LY_KHACH_HANG',  N'Quản lý khách hàng',  N'Khách hàng',N'Xem, sửa thông tin khách, khóa tài khoản khách'),
    ('QUAN_LY_LICH_LAI_THU',N'Quản lý lịch lái thử',N'Khách hàng',N'Xử lý lịch hẹn lái thử'),
    ('XEM_BAO_CAO',         N'Xem báo cáo',         N'Báo cáo',   N'Xem doanh thu, tồn kho');

INSERT INTO HangXe (TenHang, QuocGia) VALUES (N'Honda', N'Nhật Bản'), (N'Yamaha', N'Nhật Bản'), (N'Suzuki', N'Nhật Bản');
INSERT INTO LoaiXe (TenLoai) VALUES (N'Xe số'), (N'Xe tay ga'), (N'Xe côn tay'), (N'Xe phân khối lớn');
GO