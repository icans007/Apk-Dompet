import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';

/// Service untuk mengelola transaksi keuangan
class TransactionService extends ChangeNotifier {
  late Box<TransactionModel> _transactionBox;

  TransactionService() {
    _transactionBox = Hive.box<TransactionModel>('transactions');
  }

  /// Ambil semua transaksi untuk pengguna tertentu
  List<TransactionModel> getTransactions(String userId) {
    return _transactionBox.values
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Urutkan terbaru duluan
  }

  /// Ambil transaksi berdasarkan filter bulan dan tahun
  List<TransactionModel> getTransactionsByMonth(
    String userId,
    int year,
    int month,
  ) {
    return _transactionBox.values
        .where((t) =>
            t.userId == userId &&
            t.date.year == year &&
            t.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Ambil 5 transaksi terbaru
  List<TransactionModel> getRecentTransactions(String userId, {int limit = 5}) {
    final all = getTransactions(userId);
    return all.take(limit).toList();
  }

  /// Hitung total pemasukan bulan ini
  double getTotalIncomeByMonth(String userId, int year, int month) {
    return getTransactionsByMonth(userId, year, month)
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Hitung total pengeluaran bulan ini
  double getTotalExpenseByMonth(String userId, int year, int month) {
    return getTransactionsByMonth(userId, year, month)
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Hitung saldo total (semua pemasukan - semua pengeluaran)
  double getTotalBalance(String userId) {
    final transactions = getTransactions(userId);
    double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
    double totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
    return totalIncome - totalExpense;
  }

  /// Hitung pengeluaran per kategori untuk bulan tertentu
  Map<TransactionCategory, double> getExpenseByCategory(
    String userId,
    int year,
    int month,
  ) {
    final expenses = getTransactionsByMonth(userId, year, month)
        .where((t) => t.type == TransactionType.expense);

    final Map<TransactionCategory, double> categoryTotals = {};
    for (final t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    return categoryTotals;
  }

  /// Data tren pengeluaran 6 bulan terakhir
  List<Map<String, dynamic>> getExpenseTrend(String userId) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> trend = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final total = getTotalExpenseByMonth(userId, date.year, date.month);
      trend.add({
        'year': date.year,
        'month': date.month,
        'total': total,
      });
    }
    return trend;
  }

  /// Kelompokkan transaksi berdasarkan hari
  Map<DateTime, List<TransactionModel>> groupTransactionsByDay(
    List<TransactionModel> transactions,
  ) {
    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (final transaction in transactions) {
      // Normalisasi tanggal (hapus jam/menit/detik)
      final dayKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(transaction);
    }

    // Urutkan berdasarkan tanggal terbaru
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  /// Tambah transaksi baru
  Future<void> addTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    required TransactionCategory category,
    required DateTime date,
    String? note,
  }) async {
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );

    await _transactionBox.put(transaction.id, transaction);
    notifyListeners();
  }

  /// Perbarui transaksi yang sudah ada
  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    final transaction = updatedTransaction.copyWith(
      updatedAt: DateTime.now(),
    );
    await _transactionBox.put(transaction.id, transaction);
    notifyListeners();
  }

  /// Hapus transaksi
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionBox.delete(transactionId);
    notifyListeners();
  }

  /// Filter transaksi berdasarkan kategori
  List<TransactionModel> filterByCategory(
    List<TransactionModel> transactions,
    TransactionCategory? category,
  ) {
    if (category == null) return transactions;
    return transactions.where((t) => t.category == category).toList();
  }
}
