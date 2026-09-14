import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';

class BackupHelper {
  /// EXPORT / BACKUP DATA
  static Future<bool> exportBackup() async {
    try {
      // 1. Ambil semua data dari database
      final txs = await DatabaseHelper.instance.getAllTransactions();
      if (txs.isEmpty) return false;

      // 2. Ubah data ke bentuk JSON
      final List<Map<String, dynamic>> jsonData = txs.map((tx) => tx.toMap()).toList();
      final String jsonString = jsonEncode(jsonData);

      // 3. Buat file .json sementara
      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final File file = File('${directory.path}/Backup_UMKM_$timestamp.json');
      await file.writeAsString(jsonString);

      // 4. Buka dialog Share (Save to Drive / WhatsApp)
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Backup Data Pembukuan UMKM');
      
      return true;
    } catch (e) {
      print('Error Export Backup: $e');
      return false;
    }
  }

  /// IMPORT / RESTORE DATA
  static Future<bool> restoreBackup() async {
    try {
      // 1. Minta user memilih file .json
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
      );

      if (result != null && result.files.single.path != null) {
        // 2. Baca isi file JSON
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        List<dynamic> decodedData = jsonDecode(jsonString);

        // 3. Ubah kembali JSON menjadi List<TransactionModel>
        List<TransactionModel> backupData = decodedData.map((e) {
          return TransactionModel.fromMap(e as Map<String, dynamic>);
        }).toList();

        // 4. Masukkan ke database jika datanya valid
        if (backupData.isNotEmpty) {
          await DatabaseHelper.instance.clearAllTransactions(); 
          await DatabaseHelper.instance.insertBatchTransactions(backupData); 
          return true;
        }
      }
      return false; 
    } catch (e) {
      print('Error Restore Backup: $e');
      return false;
    }
  }
}