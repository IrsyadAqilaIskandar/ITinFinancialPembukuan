# Pembukuan UMKM

Aplikasi mobile Flutter sederhana untuk pembukuan usaha UMKM: catat pemasukan
dan pengeluaran, lihat saldo berjalan, dan buat laporan mingguan/bulanan.
Semua data disimpan **lokal di HP** (SQLite via `sqflite`) — tidak perlu
internet atau backend.

## Fitur

* **Input Pemasukan & Pengeluaran**: Pencatatan transaksi lengkap dengan nominal, kategori, tanggal, dan catatan.
* **Kategori Transaksi**: Pengelompokan dinamis (Penjualan, Bahan Baku, Operasional, Gaji, dll — dapat disesuaikan di `lib/models/transaction_model.dart`).
* **Edit & Hapus Transaksi**: Manajemen transaksi yang fleksibel (*swipe* untuk hapus, *tap* untuk edit).
* **Auto-Reload Data Instan**: Tampilan Dashboard, Riwayat, dan Laporan langsung diperbarui secara otomatis setelah simpan transaksi.
* **Dashboard Keuangan**: Menampilkan saldo berjalan serta ringkasan pemasukan dan pengeluaran bulan ini.
* **Riwayat Transaksi**: Tampilan riwayat harian yang dikelompokkan rapi berdasarkan tanggal.
* **Laporan Mingguan & Bulanan**: Grafik visualisasi, navigasi periode, dan rincian transaksi per kategori.
* **Ekspor Laporan (PDF & Excel/CSV)**: Cetak atau bagikan laporan keuangan secara langsung lewat *share sheet* HP (Save to Files, WhatsApp, Email, dll).
* **Cadangkan & Pulihkan Data (Backup & Restore)**: Fitur ekspor dan impor seluruh data transaksi menggunakan file `.json` untuk keamanan data.

## Struktur Project

```
lib/
├── main.dart                          # Entry point aplikasi
├── db/
│   └── database_helper.dart           # Operasi CRUD SQLite
├── models/
│   └── transaction_model.dart         # Model data transaksi & kategori
├── screens/
│   ├── home_screen.dart               # Dashboard & navigasi utama
│   ├── add_edit_transaction_screen.dart# Form tambah & edit transaksi
│   ├── history_screen.dart            # Riwayat transaksi
│   ├── report_screen.dart             # Laporan keuangan mingguan/bulanan
│   └── settings_screen.dart           # Pengaturan, backup & restore
├── utils/
│   ├── backup_helper.dart             # Helper ekspor & impor file .json
│   ├── formatters.dart                # Format Rupiah, tanggal & input nominal
│   └── report_exporter.dart           # Helper ekspor laporan PDF & CSV
└── widgets/
    ├── chart_widget.dart              # Grafik visualisasi laporan
    └── transaction_tile.dart          # Widget kartu item transaksi
```

## Cara Menjalankan

Project ini berisi kode Dart-nya saja (folder `lib/` + `pubspec.yaml`).
Folder platform (`android/`, `ios/`, dll) belum digenerate karena dibuat di
luar environment Flutter. Ikuti langkah berikut di komputer kamu yang sudah
terinstall Flutter SDK:

1. **Pastikan Flutter sudah terinstall**
   ```bash
   flutter doctor
   ```

2. **Salin folder project ini**, lalu di dalam foldernya jalankan:
   ```bash
   flutter create .
   ```
   Perintah ini akan menambahkan folder `android/`, `ios/`, dll tanpa
   menimpa `lib/` dan `pubspec.yaml` yang sudah ada.

3. **Install dependency:**
   ```bash
   flutter pub get
   ```

4. **Jalankan aplikasi** (pastikan ada emulator/HP yang terhubung):
   ```bash
   flutter run
   ```

## Catatan Pengembangan Selanjutnya

Fitur yang belum ada tapi mudah ditambahkan ke struktur ini:
- Foto nota/struk per transaksi
- Filter & pencarian transaksi
- Multi-usaha
