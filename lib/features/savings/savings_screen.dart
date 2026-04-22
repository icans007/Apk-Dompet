import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/savings_model.dart';
import '../../services/auth_service.dart';
import '../../services/savings_service.dart';
import '../../widgets/currency_formatter.dart';

/// Halaman Tabungan / Savings Goals
class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final savingsService = context.watch<SavingsService>();
    final userId = auth.currentUser?.id ?? '';

    final activeSavings = savingsService.getActiveSavings(userId);
    final archivedSavings = savingsService.getArchivedSavings(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabungan Saya'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addSavings),
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Aktif
          _buildSavingsList(context, activeSavings, isArchived: false),
          // Tab Selesai/Arsip
          _buildSavingsList(context, archivedSavings, isArchived: true),
        ],
      ),
    );
  }

  /// Daftar tabungan
  Widget _buildSavingsList(BuildContext context, List<SavingsModel> savings,
      {required bool isArchived}) {
    if (savings.isEmpty) {
      return _buildEmptyState(context, isArchived);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: savings.length,
      itemBuilder: (context, i) {
        return _buildSavingsCard(context, savings[i]);
      },
    );
  }

  /// Kartu item tabungan
  Widget _buildSavingsCard(BuildContext context, SavingsModel savings) {
    // Parse warna dari hex string
    Color cardColor;
    try {
      final hex = savings.colorHex.replaceAll('#', '');
      cardColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      cardColor = AppTheme.primaryColor;
    }

    final progress = savings.progressPercentage;
    final daysLeft = savings.targetDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.savingsDetail,
        arguments: savings,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ikon tabungan
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(savings.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savings.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        savings.isCompleted
                            ? '✅ Tercapai!'
                            : daysLeft > 0
                                ? '$daysLeft hari lagi'
                                : 'Sudah lewat target',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: savings.isCompleted
                                  ? AppTheme.accentGreen
                                  : daysLeft < 0
                                      ? AppTheme.accentRed
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                // Persentase
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: cardColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 10),

            // Nominal terkumpul vs target
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatRupiah(savings.currentAmount),
                  style: TextStyle(
                    color: cardColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'dari ${CurrencyFormatter.formatRupiah(savings.targetAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isArchived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isArchived ? '🏆' : '🎯',
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 16),
          Text(
            isArchived
                ? 'Belum ada tabungan selesai'
                : 'Belum ada tabungan aktif',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isArchived
                ? 'Tabungan yang sudah 100%\nakan muncul di sini'
                : 'Mulai buat target tabungan\npertama Anda!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          if (!isArchived) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addSavings),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Tabungan Baru'),
            ),
          ],
        ],
      ),
    );
  }
}
