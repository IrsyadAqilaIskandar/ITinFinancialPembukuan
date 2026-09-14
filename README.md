# Pembukuan UMKM

Aplikasi mobile Flutter sederhana untuk pembukuan usaha UMKM: catat pemasukan
dan pengeluaran, lihat saldo berjalan, dan buat laporan mingguan/bulanan.
Semua data disimpan **lokal di HP** (SQLite via `sqflite`) — tidak perlu
internet atau backend.

## Fitur

- Input pemasukan & pengeluaran (nominal, kategori, tanggal, catatan)
- Kategori transaksi (Penjualan, Bahan Baku, Operasional, Gaji, dll — bisa
  diedit di `lib/models/transaction_model.dart`)
- Edit & hapus transaksi (swipe kiri untuk hapus, tap untuk edit)
- Riwayat transaksi harian, dikelompokkan per tanggal
- Saldo berjalan di halaman Dashboard
- Laporan Mingguan & Bulanan dengan navigasi periode (sebelumnya/berikutnya)
  dan rincian per kategori
- **Download laporan** dalam format PDF atau Excel (CSV) dari halaman
  Laporan — file dibuat lalu dibuka lewat share sheet HP, jadi user bisa
  pilih "Save to files"/Download, atau langsung kirim ke WhatsApp/Email

## Struktur Project

```
lib/
├── main.dart                          # Entry point
├── models/
│   └── transaction_model.dart         # Model data transaksi + kategori
├── db/
│   └── database_helper.dart           # CRUD SQLite
├── screens/
│   ├── home_screen.dart               # Dashboard + bottom navigation
│   ├── add_edit_transaction_screen.dart
│   ├── history_screen.dart            # Riwayat semua transaksi
│   └── report_screen.dart             # Laporan mingguan/bulanan
├── widgets/
│   └── transaction_tile.dart          # Kartu item transaksi
└── utils/
    └── formatters.dart                # Format Rupiah & tanggal (id_ID)
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
