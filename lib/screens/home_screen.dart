import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  Key _refreshKey = UniqueKey();
  Offset? _fabPosition; 

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Riwayat', 'Laporan'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _refresh();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final defaultX = constraints.maxWidth - 72.0;
          final defaultY = constraints.maxHeight - 80.0;

          return Stack(
            fit: StackFit.expand, 
            children: [
              _buildBody(),
              
              Positioned(
                left: _fabPosition?.dx ?? defaultX,
                top: _fabPosition?.dy ?? defaultY,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      double newX = (_fabPosition?.dx ?? defaultX) + details.delta.dx;
                      double newY = (_fabPosition?.dy ?? defaultY) + details.delta.dy;

                      newX = newX.clamp(16.0, constraints.maxWidth - 72.0);
                      newY = newY.clamp(16.0, constraints.maxHeight - 72.0);

                      _fabPosition = Offset(newX, newY);
                    });
                  },
                  child: FloatingActionButton(
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
                      );
                      if (changed == true) {
                        _refresh();
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          );
        },
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

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _DashboardTab(key: _refreshKey);
      case 1:
        return HistoryScreen(key: _refreshKey);
      case 2:
        return ReportScreen(key: _refreshKey);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({super.key});

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