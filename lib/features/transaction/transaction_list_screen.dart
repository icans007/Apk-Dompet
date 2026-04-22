import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/currency_formatter.dart';
import 'widgets/transaction_item_widget.dart';

/// Halaman riwayat semua transaksi dengan filter
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTime _selectedMonth = DateTime.now();
  TransactionCategory? _selectedCategory; // null = semua kategori

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final transactionService = context.watch<TransactionService>();
    final userId = auth.currentUser?.id ?? '';

    // Ambil transaksi berdasarkan bulan
    var transactions = transactionService.getTransactionsByMonth(
      userId,
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // Filter berdasarkan kategori
    transactions =
        transactionService.filterByCategory(transactions, _selectedCategory);

    // Total bulan ini
    final totalIncome = transactionService.getTotalIncomeByMonth(
        userId, _selectedMonth.year, _selectedMonth.month);
    final totalExpense = transactionService.getTotalExpenseByMonth(
        userId, _selectedMonth.year, _selectedMonth.month);

    // Kelompokkan per hari
    final grouped = transactionService.groupTransactionsByDay(transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          // Tombol tambah transaksi
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addTransaction),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header filter bulan
          _buildMonthFilter(),

          // Ringkasan bulan ini
          _buildMonthlySummary(totalIncome, totalExpense),

          // Filter kategori
          _buildCategoryFilter(),

          // Daftar transaksi
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionList(grouped),
          ),
        ],
      ),
    );
  }

  /// Filter bulan — navigasi ke bulan sebelumnya/berikutnya
  Widget _buildMonthFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol bulan sebelumnya
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            }),
          ),

          // Label bulan & tahun
          GestureDetector(
            onTap: _showMonthPicker,
            child: Text(
              DateFormatter.formatMonthYear(_selectedMonth),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Tombol bulan berikutnya (disabled jika sudah bulan ini)
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year
                ? null
                : () => setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1);
                    }),
          ),
        ],
      ),
    );
  }

  /// Tampilkan bottom sheet untuk pilih bulan
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Bulan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final month = DateTime(DateTime.now().year, i + 1);
                  final isSelected = _selectedMonth.month == i + 1 &&
                      _selectedMonth.year == DateTime.now().year;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMonth =
                          DateTime(DateTime.now().year, i + 1));
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormatter.formatMonth(month),
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Ringkasan total pemasukan & pengeluaran bulan ini
  Widget _buildMonthlySummary(double income, double expense) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('Pemasukan',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(income),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Text('Pengeluaran',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(expense),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Text('Selisih',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(income - expense),
                  style: TextStyle(
                    color: (income - expense) >= 0
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter chip untuk kategori
  Widget _buildCategoryFilter() {
    final categories = [null, ...TransactionCategory.values];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                  cat == null ? 'Semua' : '${cat.emoji} ${cat.displayName}'),
              onSelected: (_) => setState(() => _selectedCategory = cat),
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Daftar transaksi dikelompokkan per hari
  Widget _buildTransactionList(Map<DateTime, List<TransactionModel>> grouped) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final day = grouped.keys.elementAt(index);
        final dayTransactions = grouped[day]!;

        // Total per hari
        final dayTotal = dayTransactions.fold<double>(
          0,
          (sum, t) => t.isIncome ? sum + t.amount : sum - t.amount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header hari
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatRelative(day),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''} ${CurrencyFormatter.formatRupiah(dayTotal.abs())}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: dayTotal >= 0
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed,
                        ),
                  ),
                ],
              ),
            ),

            // Transaksi per hari
            ...dayTransactions.map(
              (t) => TransactionItemWidget(
                transaction: t,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.transactionDetail,
                  arguments: t,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tampilan kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada transaksi untuk\n${DateFormatter.formatMonthYear(_selectedMonth)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
