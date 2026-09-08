import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';
import '../utils/formatters.dart';
import 'add_edit_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txs = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _transactions = txs;
      _loading = false;
    });
  }

  Future<void> _delete(TransactionModel tx) async {
    await DatabaseHelper.instance.deleteTransaction(tx.id!);
    _load();
  }

  Future<void> _edit(TransactionModel tx) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(existingTransaction: tx),
      ),
    );
    if (changed == true) _load();
  }

  /// Mengelompokkan transaksi berdasarkan tanggal (dibulatkan ke hari)
  /// supaya tampilannya rapi seperti "5 Sep 2026", lalu daftar transaksinya.
  Map<String, List<TransactionModel>> _groupByDate() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in _transactions) {
      final key = formatDate(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada transaksi.\nTekan tombol + untuk menambah transaksi pertama.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final grouped = _groupByDate();
    final dateKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: dateKeys.length,
        itemBuilder: (context, index) {
          final dateKey = dateKeys[index];
          final txsForDate = grouped[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  dateKey,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ),
              ...txsForDate.map(
                (tx) => TransactionTile(
                  tx: tx,
                  onTap: () => _edit(tx),
                  onDelete: () => _delete(tx),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
