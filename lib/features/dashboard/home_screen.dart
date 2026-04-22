import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/currency_formatter.dart';
import '../transaction/widgets/transaction_item_widget.dart';

/// Halaman Dashboard Utama DompetKu
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Index tab navigasi bawah

  // Filter tampilan: 0=Bulan Ini, 1=Minggu Ini, 2=Tahun Ini
  int _filterIndex = 0;
  final List<String> _filterLabels = ['Bulan Ini', 'Minggu Ini', 'Tahun Ini'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),
      // FAB untuk tambah transaksi cepat
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Widget utama berdasarkan tab yang dipilih
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildTransactionTab();
      case 2:
        return _buildSavingsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboard();
    }
  }

  /// Konten dashboard utama
  Widget _buildDashboard() {
    final auth = context.watch<AuthService>();
    final transactionService = context.watch<TransactionService>();
    final userId = auth.currentUser?.id ?? '';
    final now = DateTime.now();

    // Ambil data berdasarkan filter
    final totalIncome =
        transactionService.getTotalIncomeByMonth(userId, now.year, now.month);
    final totalExpense =
        transactionService.getTotalExpenseByMonth(userId, now.year, now.month);
    final balance = transactionService.getTotalBalance(userId);
    final recentTransactions = transactionService.getRecentTransactions(userId);
    final expenseByCategory =
        transactionService.getExpenseByCategory(userId, now.year, now.month);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header dengan greeting dan info saldo
          SliverToBoxAdapter(
            child: _buildHeader(auth, balance),
          ),

          // Kartu ringkasan pemasukan & pengeluaran
          SliverToBoxAdapter(
            child: _buildSummaryCards(totalIncome, totalExpense),
          ),

          // Filter tampilan
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),

          // Grafik pengeluaran per kategori
          if (expenseByCategory.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildExpenseChart(expenseByCategory),
            ),

          // Transaksi terbaru
          SliverToBoxAdapter(
            child: _buildRecentTransactions(recentTransactions),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Header dashboard dengan greeting dan saldo
  Widget _buildHeader(AuthService auth, double balance) {
    final hour = DateTime.now().hour;
    String greeting;
    String greetingEmoji;

    // Greeting berdasarkan waktu
    if (hour < 11) {
      greeting = 'Selamat Pagi';
      greetingEmoji = '☀️';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
      greetingEmoji = '🌤️';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
      greetingEmoji = '🌅';
    } else {
      greeting = 'Selamat Malam';
      greetingEmoji = '🌙';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + nama pengguna
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greetingEmoji $greeting,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.currentUser?.name ?? 'Pengguna',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Avatar pengguna
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (auth.currentUser?.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Kartu saldo total
          _buildBalanceCard(balance),
        ],
      ),
    );
  }

  /// Kartu saldo total dengan gradasi
  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Saldo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatRupiah(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormatter.formatMonthYear(DateTime.now()),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Kartu ringkasan pemasukan & pengeluaran
  Widget _buildSummaryCards(double totalIncome, double totalExpense) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Kartu Pemasukan
          Expanded(
            child: _buildSummaryCard(
              label: 'Pemasukan',
              amount: totalIncome,
              icon: Icons.arrow_downward_rounded,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          // Kartu Pengeluaran
          Expanded(
            child: _buildSummaryCard(
              label: 'Pengeluaran',
              amount: totalExpense,
              icon: Icons.arrow_upward_rounded,
              color: AppTheme.accentRed,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget kartu summary individual
  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.formatRupiah(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Filter chip pilihan periode
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(
          _filterLabels.length,
          (index) => Padding(
            padding: EdgeInsets.only(
                right: index < _filterLabels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _filterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _filterIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filterLabels[index],
                  style: TextStyle(
                    color: _filterIndex == index
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Grafik donat pengeluaran per kategori
  Widget _buildExpenseChart(Map<TransactionCategory, double> data) {
    // Konversi data ke format fl_chart
    final sections = data.entries.map((entry) {
      final colors = {
        TransactionCategory.food: AppTheme.catFood,
        TransactionCategory.transport: AppTheme.catTransport,
        TransactionCategory.shopping: AppTheme.catShopping,
        TransactionCategory.entertainment: AppTheme.catEntertainment,
        TransactionCategory.bill: AppTheme.catBill,
        TransactionCategory.salary: AppTheme.catSalary,
        TransactionCategory.health: AppTheme.catHealth,
        TransactionCategory.education: AppTheme.catEducation,
        TransactionCategory.other: AppTheme.catOther,
      };

      final total = data.values.fold(0.0, (a, b) => a + b);
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[entry.key] ?? AppTheme.catOther,
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengeluaran per Kategori',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie chart
              SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legenda kategori
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.entries.take(5).map((entry) {
                    final colors = {
                      TransactionCategory.food: AppTheme.catFood,
                      TransactionCategory.transport: AppTheme.catTransport,
                      TransactionCategory.shopping: AppTheme.catShopping,
                      TransactionCategory.entertainment:
                          AppTheme.catEntertainment,
                      TransactionCategory.bill: AppTheme.catBill,
                      TransactionCategory.salary: AppTheme.catSalary,
                      TransactionCategory.health: AppTheme.catHealth,
                      TransactionCategory.education: AppTheme.catEducation,
                      TransactionCategory.other: AppTheme.catOther,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[entry.key] ?? AppTheme.catOther,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.key.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget daftar transaksi terbaru
  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Terbaru',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            _buildEmptyTransactions()
          else
            ...transactions.map(
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
      ),
    );
  }

  /// Widget kosong jika tidak ada transaksi
  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Belum ada transaksi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai catat pemasukan & pengeluaran Anda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index != 2) {
          // Index 2 adalah FAB
          setState(() => _currentIndex = index > 2 ? index - 1 : index);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Transaksi',
        ),
        BottomNavigationBarItem(
          icon: SizedBox.shrink(), // Placeholder untuk FAB
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.savings_outlined),
          activeIcon: Icon(Icons.savings_rounded),
          label: 'Tabungan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }

  /// Floating Action Button untuk tambah transaksi
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  // Placeholder untuk tab lainnya (akan diganti dengan widget screen terpisah)
  Widget _buildTransactionTab() {
    // Navigasi ke TransactionListScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, AppRoutes.transactionList);
      setState(() => _currentIndex = 0);
    });
    return const SizedBox.shrink();
  }

  Widget _buildSavingsTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, AppRoutes.savings);
      setState(() => _currentIndex = 0);
    });
    return const SizedBox.shrink();
  }

  Widget _buildProfileTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, AppRoutes.profile);
      setState(() => _currentIndex = 0);
    });
    return const SizedBox.shrink();
  }
}
