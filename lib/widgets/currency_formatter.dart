import 'package:intl/intl.dart';

/// Helper class untuk format mata uang Rupiah
class CurrencyFormatter {
  // Formatter untuk Rupiah
  static final _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Formatter tanpa simbol
  static final _numberFormatter = NumberFormat('#,###', 'id_ID');

  /// Format angka menjadi format Rupiah
  /// Contoh: 1000000 → "Rp 1.000.000"
  static String formatRupiah(double amount) {
    return _rupiahFormatter.format(amount);
  }

  /// Format angka dengan pemisah ribuan tanpa simbol
  /// Contoh: 1000000 → "1.000.000"
  static String formatNumber(double amount) {
    return _numberFormatter.format(amount);
  }

  /// Parse string Rupiah kembali ke angka
  /// Contoh: "Rp 1.000.000" → 1000000
  static double parseRupiah(String value) {
    // Hapus semua karakter non-angka
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  /// Format angka saat mengetik (live formatting)
  static String formatInput(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';
    final number = double.tryParse(cleaned) ?? 0;
    return _numberFormatter.format(number);
  }
}

/// Helper untuk format tanggal dalam Bahasa Indonesia
class DateFormatter {
  static final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _monthYearFormatter = DateFormat('MMMM yyyy', 'id_ID');
  static final _dayFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
  static final _shortDateFormatter = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _monthFormatter = DateFormat('MMM', 'id_ID');

  /// Format: "25 Jan 2024"
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Format: "25 Jan 2024, 14:30"
  static String formatDateTime(DateTime date) => _dateTimeFormatter.format(date);

  /// Format: "Januari 2024"
  static String formatMonthYear(DateTime date) => _monthYearFormatter.format(date);

  /// Format: "Senin, 25 Jan 2024"
  static String formatDayDate(DateTime date) => _dayFormatter.format(date);

  /// Format: "25/01/2024"
  static String formatShortDate(DateTime date) => _shortDateFormatter.format(date);

  /// Format: "Jan"
  static String formatMonth(DateTime date) => _monthFormatter.format(date);

  /// Label relatif: "Hari ini", "Kemarin", atau tanggal lengkap
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari ini';
    if (dateOnly == yesterday) return 'Kemarin';
    return formatDayDate(date);
  }
}
