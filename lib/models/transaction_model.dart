/// Jenis transaksi: pemasukan atau pengeluaran
enum TransactionType { income, expense }

/// Konversi enum ke/dari String supaya gampang disimpan di SQLite
extension TransactionTypeX on TransactionType {
  String get dbValue => this == TransactionType.income ? 'income' : 'expense';

  static TransactionType fromDb(String value) {
    return value == 'income' ? TransactionType.income : TransactionType.expense;
  }

  String get label => this == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
}

/// Daftar kategori bawaan, dipisah antara pemasukan & pengeluaran.
/// User tidak perlu bikin kategori sendiri dulu (biar tetap simpel),
/// tapi struktur ini gampang dikembangkan kalau nanti mau custom kategori.
class TransactionCategories {
  static const List<String> income = [
    'Penjualan',
    'Modal',
    'Lain-lain',
  ];

  static const List<String> expense = [
    'Bahan Baku',
    'Operasional',
    'Gaji',
    'Transportasi',
    'Lain-lain',
  ];

  static List<String> forType(TransactionType type) {
    return type == TransactionType.income ? income : expense;
  }
}

class TransactionModel {
  final int? id;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String note;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note = '',
  });

  /// Untuk disimpan ke SQLite (tanggal disimpan sebagai ISO8601 string)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.dbValue,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionTypeX.fromDb(map['type'] as String),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  TransactionModel copyWith({
    int? id,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
