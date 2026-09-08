import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Riwayat', 'Laporan'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_tabIndex])),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
          );
          if (changed == true) {
            // Trigger rebuild supaya dashboard & tab lain refresh datanya
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }

  /// Sengaja TIDAK pakai IndexedStack: setiap kali pindah tab, widget tab
  /// tujuan dibuat baru (bukan disimpan di background), jadi datanya selalu
  /// diambil ulang dari database dan tidak ada risiko data basi/stale
  /// (ini yang menyebabkan Riwayat sebelumnya tidak menampilkan transaksi baru).
  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _DashboardTab();
      case 1:
        return HistoryScreen();
      case 2:
        return ReportScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  double _balance = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;
  List<TransactionModel> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final balance = await db.getTotalBalance();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    final monthTxs = await db.getTransactionsBetween(monthStart, monthEnd);

    final income = monthTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = monthTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    final all = await db.getAllTransactions();

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _monthIncome = income;
      _monthExpense = expense;
      _recent = all.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu saldo berjalan
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Saat Ini'),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(_balance),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan bulan ini
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Pemasukan Bulan Ini',
                  value: _monthIncome,
                  color: Colors.green,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: 'Pengeluaran Bulan Ini',
                  value: _monthExpense,
                  color: Colors.red,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Transaksi Terbaru', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada transaksi.'),
            )
          else
            ..._recent.map((tx) => TransactionTile(tx: tx)),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              formatRupiah(value),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
