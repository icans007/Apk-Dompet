import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/savings_model.dart';

/// Service untuk mengelola tabungan/savings goals
class SavingsService extends ChangeNotifier {
  late Box<SavingsModel> _savingsBox;

  SavingsService() {
    _savingsBox = Hive.box<SavingsModel>('savings');
  }

  /// Ambil semua tabungan aktif (belum diarsipkan) untuk pengguna
  List<SavingsModel> getActiveSavings(String userId) {
    return _savingsBox.values
        .where((s) => s.userId == userId && !s.isArchived)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Ambil tabungan yang sudah diarsipkan
  List<SavingsModel> getArchivedSavings(String userId) {
    return _savingsBox.values
        .where((s) => s.userId == userId && s.isArchived)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Tambah tabungan baru
  Future<void> addSavings({
    required String userId,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    String emoji = '🎯',
    String colorHex = '#6366F1',
  }) async {
    final savings = SavingsModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      emoji: emoji,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    await _savingsBox.put(savings.id, savings);
    notifyListeners();
  }

  /// Tambah setoran ke tabungan
  Future<void> addDeposit({
    required String savingsId,
    required double amount,
    String? note,
  }) async {
    final savings = _savingsBox.get(savingsId);
    if (savings == null) return;

    savings.addDeposit(amount, note: note);
    await savings.save();
    notifyListeners();
  }

  /// Perbarui data tabungan
  Future<void> updateSavings(SavingsModel updated) async {
    await _savingsBox.put(updated.id, updated);
    notifyListeners();
  }

  /// Arsipkan tabungan yang sudah selesai
  Future<void> archiveSavings(String savingsId) async {
    final savings = _savingsBox.get(savingsId);
    if (savings == null) return;

    savings.isArchived = true;
    await savings.save();
    notifyListeners();
  }

  /// Hapus tabungan
  Future<void> deleteSavings(String savingsId) async {
    await _savingsBox.delete(savingsId);
    notifyListeners();
  }

  /// Hitung total yang sudah ditabung dari semua tabungan aktif
  double getTotalSaved(String userId) {
    return getActiveSavings(userId)
        .fold(0, (sum, s) => sum + s.currentAmount);
  }
}
