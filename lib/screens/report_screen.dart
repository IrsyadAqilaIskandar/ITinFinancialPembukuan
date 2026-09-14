import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../utils/report_exporter.dart';
import '../widgets/chart_widget.dart';

enum ReportPeriod { weekly, monthly }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _period = ReportPeriod.weekly;
  int _offset = 0;
  bool _loading = true;
  bool _exporting = false;
  List<TransactionModel> _txs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  ({DateTime start, DateTime end, String label}) _resolveRange() {
    final now = DateTime.now();

    if (_period == ReportPeriod.weekly) {
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(currentWeekStart.year, currentWeekStart.month,
              currentWeekStart.day)
          .add(Duration(days: 7 * _offset));
      final end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      final label = '${formatDate(start)} - ${formatDate(end)}';
      return (start: start, end: end, label: label);
    } else {
      final targetMonth = DateTime(now.year, now.month + _offset, 1);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month + 1, 1)
          .subtract(const Duration(milliseconds: 1));
      const monthNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final label = '${monthNames[start.month - 1]} ${start.year}';
      return (start: start, end: end, label: label);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final range = _resolveRange();
    final txs = await DatabaseHelper.instance
        .getTransactionsBetween(range.start, range.end);
    setState(() {
      _txs = txs;
      _loading = false;
    });
  }

  void _changePeriodType(ReportPeriod newPeriod) {
    setState(() {
      _period = newPeriod;
      _offset = 0;
    });
    _load();
  }

  void _shift(int delta) {
    setState(() => _offset += delta);
    _load();
  }

  Future<void> _export(bool asPdf) async {
    if (_txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi untuk diexport pada periode ini.')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final range = _resolveRange();
      final totalIncome = _txs
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final totalExpense = _txs
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);

      if (asPdf) {
        await ReportExporter.exportPdf(
          periodLabel: range.label,
          transactions: _txs,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        );
      } else {
        await ReportExporter.exportCsv(
          periodLabel: range.label,
          transactions: _txs,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat laporan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Map<String, double> _totalsByCategory(TransactionType type) {
    final Map<String, double> totals = {};
    for (final tx in _txs.where((t) => t.type == type)) {
      totals.update(tx.category, (v) => v + tx.amount, ifAbsent: () => tx.amount);
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final range = _resolveRange();
    final totalIncome = _txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = _txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final net = totalIncome - totalExpense;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<ReportPeriod>(
            segments: const [
              ButtonSegment(value: ReportPeriod.weekly, label: Text('Mingguan')),
              ButtonSegment(value: ReportPeriod.monthly, label: Text('Bulanan')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => _changePeriodType(s.first),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Text(
                range.label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(true),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(false),
                  icon: const Icon(Icons.table_chart, size: 18),
                  label: const Text('Download Excel'),
                ),
              ),
            ],
          ),
        ),

        if (_exporting)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),

        const SizedBox(height: 8),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IncomeExpenseChart(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _summaryRow('Total Pemasukan', totalIncome, Colors.green),
                        const Divider(),
                        _summaryRow('Total Pengeluaran', totalExpense, Colors.red),
                        const Divider(),
                        _summaryRow(
                          'Selisih (Laba/Rugi)',
                          net,
                          net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Tidak ada transaksi pada periode ini.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  Text('Rincian Pengeluaran per Kategori',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._buildCategoryBreakdown(_totalsByCategory(TransactionType.expense), Colors.red),
                  const SizedBox(height: 20),
                  Text('Rincian Pemasukan per Kategori',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._buildCategoryBreakdown(_totalsByCategory(TransactionType.income), Colors.green),
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCategoryBreakdown(Map<String, double> totals, MaterialColor color) {
    if (totals.isEmpty) {
      return [Text('Tidak ada data.', style: TextStyle(color: Colors.grey.shade600))];
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text(
                    formatRupiah(e.value),
                    style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _summaryRow(String label, double value, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(
          formatRupiah(value),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}