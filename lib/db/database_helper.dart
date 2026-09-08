import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';

/// Kelas ini bertanggung jawab penuh untuk komunikasi ke SQLite.
/// Dibuat sebagai singleton supaya cuma ada 1 koneksi database
/// selama aplikasi berjalan.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'umkm_pembukuan.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  // ---------- CREATE ----------
  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    final map = tx.toMap()..remove('id');
    return db.insert('transactions', map);
  }

  // ---------- READ ----------
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsBetween(
      DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  // ---------- UPDATE ----------
  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await database;
    return db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  // ---------- DELETE ----------
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- SUMMARY HELPERS ----------
  Future<double> getTotalBalance() async {
    final txs = await getAllTransactions();
    double balance = 0;
    for (final tx in txs) {
      balance += tx.type == TransactionType.income ? tx.amount : -tx.amount;
    }
    return balance;
  }
}
