import 'package:hive/hive.dart';

part 'savings_model.g.dart';

/// Model data tabungan/savings goal
@HiveType(typeId: 4)
class SavingsModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late String name; // Nama tabungan (misal: "Beli Laptop")

  @HiveField(3)
  late double targetAmount; // Target nominal yang ingin dicapai

  @HiveField(4)
  late double currentAmount; // Jumlah yang sudah terkumpul

  @HiveField(5)
  late DateTime targetDate; // Tanggal target selesai

  @HiveField(6)
  late String emoji; // Ikon emoji untuk tabungan

  @HiveField(7)
  late String colorHex; // Warna hex untuk tampilan

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  bool isCompleted; // Apakah tabungan sudah selesai/tercapai

  @HiveField(10)
  bool isArchived; // Apakah tabungan sudah diarsipkan

  @HiveField(11)
  List<SavingsDeposit> deposits; // Riwayat setoran

  SavingsModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.targetDate,
    this.emoji = '🎯',
    this.colorHex = '#6366F1',
    required this.createdAt,
    this.isCompleted = false,
    this.isArchived = false,
    List<SavingsDeposit>? deposits,
  }) : deposits = deposits ?? [];

  /// Persentase pencapaian (0.0 - 1.0)
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Sisa yang perlu ditabung
  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  /// Hitung estimasi bulan selesai berdasarkan rata-rata setoran
  int? get estimatedMonthsToComplete {
    if (deposits.isEmpty || remainingAmount <= 0) return null;

    // Hitung rata-rata setoran per bulan
    final totalDeposits = deposits.fold<double>(0, (sum, d) => sum + d.amount);
    final monthsActive = _monthsBetween(createdAt, DateTime.now()).clamp(1, double.infinity);
    final avgPerMonth = totalDeposits / monthsActive;

    if (avgPerMonth <= 0) return null;
    return (remainingAmount / avgPerMonth).ceil();
  }

  /// Helper hitung bulan antara dua tanggal
  double _monthsBetween(DateTime start, DateTime end) {
    return (end.difference(start).inDays / 30).toDouble();
  }

  /// Tambah setoran baru
  void addDeposit(double amount, {String? note}) {
    final deposit = SavingsDeposit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    deposits.add(deposit);
    currentAmount += amount;

    // Tandai sebagai selesai jika target tercapai
    if (currentAmount >= targetAmount) {
      isCompleted = true;
    }
  }

  /// Salin model dengan perubahan
  SavingsModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? emoji,
    String? colorHex,
    DateTime? createdAt,
    bool? isCompleted,
    bool? isArchived,
    List<SavingsDeposit>? deposits,
  }) {
    return SavingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      deposits: deposits ?? this.deposits,
    );
  }
}

/// Model data setoran tabungan
@HiveType(typeId: 5)
class SavingsDeposit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String? note;

  const SavingsDeposit({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });
}
