import 'package:flutter/material.dart';
import '../utils/backup_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Keamanan Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Colors.blue),
            title: const Text('Cadangkan Data (Backup)'),
            subtitle: const Text('Simpan data transaksi ke file .json'),
            onTap: () async {
              bool success = await BackupHelper.exportBackup();
              if (success) {
                _showSnackBar(context, 'Berhasil menyiapkan file backup!', isError: false);
              } else {
                _showSnackBar(context, 'Gagal membuat backup / Data kosong', isError: true);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.red),
            title: const Text('Pulihkan Data (Restore)'),
            subtitle: const Text('Ambil data dari file backup (.json)'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Peringatan'),
                  content: const Text(
                      'Memulihkan data akan MENGHAPUS data saat ini dan menggantinya dengan data dari file backup. Lanjutkan?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(context);
                        bool success = await BackupHelper.restoreBackup();
                        if (success) {
                          _showSnackBar(context, 'Data berhasil dipulihkan!', isError: false);
                        } else {
                          _showSnackBar(context, 'Gagal memulihkan data.', isError: true);
                        }
                      },
                      child: const Text('Ya, Pulihkan'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}