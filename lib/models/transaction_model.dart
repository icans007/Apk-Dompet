import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

/// Tipe transaksi: Pemasukan atau Pengeluaran
@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income, // Pemasukan

  @HiveField(1)
  expense, // Pengeluaran
}

/// Kategori transaksi yang tersedia
@HiveType(typeId: 2)
enum TransactionCategory {
  @HiveField(0)
  food, // Makan & Minum

  @HiveField(1)
  transport, // Transportasi

  @HiveField(2)
  shopping, // Belanja

  @HiveField(3)
  entertainment, // Hiburan

  @HiveField(4)
  bill, // Tagihan

  @HiveField(5)
  salary, // Gaji

  @HiveField(6)
  health, // Kesehatan

  @HiveField(7)
  education, // Pendidikan

  @HiveField(8)
  other, // Lainnya
}

/// Extension untuk mendapatkan informasi kategori
extension TransactionCategoryExt on TransactionCategory {
  /// Nama tampilan kategori dalam Bahasa Indonesia
  String get displayName {
    switch (this) {
      case TransactionCategory.food:
        return 'Makan & Minum';
      case TransactionCategory.transport:
        return 'Transportasi';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.entertainment:
        return 'Hiburan';
      case TransactionCategory.bill:
        return 'Tagihan';
      case TransactionCategory.salary:
        return 'Gaji';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.education:
        return 'Pendidikan';
      case TransactionCategory.other:
        return 'Lainnya';
    }
  }

  /// Ikon emoji untuk kategori
  String get emoji {
    switch (this) {
      case TransactionCategory.food:
        return '🍽️';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.entertainment:
        return '🎮';
      case TransactionCategory.bill:
        return '📄';
      case TransactionCategory.salary:
        return '💰';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.other:
        return '📦';
    }
  }
}

/// Model data transaksi keuangan
@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late TransactionType type; // Pemasukan atau Pengeluaran

  @HiveField(3)
  late double amount; // Nominal transaksi

  @HiveField(4)
  late TransactionCategory category; // Kategori transaksi

  @HiveField(5)
  late DateTime date; // Tanggal & waktu transaksi

  @HiveField(6)
  String? note; // Catatan/keterangan (opsional)

  @HiveField(7)
  late DateTime createdAt; // Waktu data dibuat

  @HiveField(8)
  DateTime? updatedAt; // Waktu data terakhir diperbarui

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  /// Cek apakah ini transaksi pemasukan
  bool get isIncome => type == TransactionType.income;

  /// Cek apakah ini transaksi pengeluaran
  bool get isExpense => type == TransactionType.expense;

  /// Salin model dengan perubahan tertentu
  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, category: $category)';
  }
}
