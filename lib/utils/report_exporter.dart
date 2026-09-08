import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import 'formatters.dart';

/// Kumpulan fungsi untuk membuat file laporan (PDF & CSV/Excel) dari data
/// transaksi pada satu periode, lalu membuka dialog "share/save" bawaan HP
/// supaya user bisa simpan ke Download, kirim WhatsApp/Email, dll.
class ReportExporter {
  /// Generate & buka dialog share untuk laporan PDF.
  static Future<void> exportPdf({
    required String periodLabel,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final doc = pw.Document();
    final net = totalIncome - totalExpense;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Pembukuan UMKM',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Periode: $periodLabel'),
          pw.SizedBox(height: 16),

          // Ringkasan
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _summaryRow('Total Pemasukan', formatRupiah(totalIncome)),
              _summaryRow('Total Pengeluaran', formatRupiah(totalExpense)),
              _summaryRow('Selisih (Laba/Rugi)', formatRupiah(net), bold: true),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text('Rincian Transaksi',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.5),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(2),
            },
            children: [
              _headerRow(['Tanggal', 'Jenis', 'Kategori', 'Nominal', 'Catatan']),
              ...transactions.map((tx) => pw.TableRow(
                    children: [
                      _cell(formatDate(tx.date)),
                      _cell(tx.type.label),
                      _cell(tx.category),
                      _cell(formatRupiah(tx.amount)),
                      _cell(tx.note),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final file = await _writeTempFile(
      bytes: bytes,
      filename: 'laporan_${_slug(periodLabel)}.pdf',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Laporan Pembukuan UMKM - $periodLabel',
      ),
    );
  }

  /// Generate & buka dialog share untuk laporan CSV (bisa dibuka di Excel).
  static Future<void> exportCsv({
    required String periodLabel,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final net = totalIncome - totalExpense;
    final buffer = StringBuffer();

    buffer.writeln('Laporan Pembukuan UMKM');
    buffer.writeln('Periode,$periodLabel');
    buffer.writeln();
    buffer.writeln('Total Pemasukan,${totalIncome.toStringAsFixed(0)}');
    buffer.writeln('Total Pengeluaran,${totalExpense.toStringAsFixed(0)}');
    buffer.writeln('Selisih,${net.toStringAsFixed(0)}');
    buffer.writeln();
    buffer.writeln('Tanggal,Jenis,Kategori,Nominal,Catatan');

    for (final tx in transactions) {
      final note = tx.note.replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln(
        '${formatDate(tx.date)},${tx.type.label},${tx.category},${tx.amount.toStringAsFixed(0)},$note',
      );
    }

    final file = await _writeTempFile(
      bytes: buffer.toString().codeUnits,
      filename: 'laporan_${_slug(periodLabel)}.csv',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Laporan Pembukuan UMKM - $periodLabel',
      ),
    );
  }

  static pw.TableRow _headerRow(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: labels
          .map((l) => pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.TableRow _summaryRow(String label, String value, {bool bold = false}) {
    final style = bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(label, style: style)),
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(value, style: style)),
    ]);
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static String _slug(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  static Future<File> _writeTempFile({
    required List<int> bytes,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}
