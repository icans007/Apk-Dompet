import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/savings_model.dart';
import '../../services/savings_service.dart';
import '../../widgets/currency_formatter.dart';

/// Halaman detail tabungan dengan riwayat setoran
class SavingsDetailScreen extends StatefulWidget {
  final SavingsModel savings;

  const SavingsDetailScreen({super.key, required this.savings});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  late SavingsModel _savings;

  @override
  void initState() {
    super.initState();
    _savings = widget.savings;
  }

  Color get _cardColor {
    try {
      final hex = _savings.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh data dari service
    _savings = context
        .watch<SavingsService>()
        .getActiveSavings(widget.savings.userId)
        .firstWhere(
          (s) => s.id == widget.savings.id,
          orElse: () => widget.savings,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_savings.name),
        actions: [
          // Tombol edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.addSavings,
              arguments: _savings,
            ),
          ),
          // Tombol hapus
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppTheme.accentRed,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Kartu progress utama
            _buildProgressCard(context),
            const SizedBox(height: 16),

            // Statistik tabungan
            _buildStatsRow(context),
            const SizedBox(height: 16),

            // Tombol tambah setoran
            if (!_savings.isArchived && !_savings.isCompleted)
              _buildDepositButton(context),
            const SizedBox(height: 16),

            // Notifikasi jika sudah selesai
            if (_savings.isCompleted) _buildCompletedBanner(context),

            // Riwayat setoran
            _buildDepositHistory(context),
          ],
        ),
      ),
    );
  }

  /// Kartu progress utama
  Widget _buildProgressCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardColor.withValues(alpha: 0.85), _cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji + nama
          Row(
            children: [
              Text(_savings.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _savings.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Target: ${DateFormatter.formatDate(_savings.targetDate)}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${(_savings.progressPercentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _savings.progressPercentage,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 12),

          // Nominal terkumpul vs target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terkumpul',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    CurrencyFormatter.formatRupiah(_savings.currentAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Target',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    CurrencyFormatter.formatRupiah(_savings.targetAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Baris statistik tabungan
  Widget _buildStatsRow(BuildContext context) {
    final daysLeft = _savings.targetDate.difference(DateTime.now()).inDays;
    final estimatedMonths = _savings.estimatedMonthsToComplete;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: '📅',
            label: 'Sisa Hari',
            value: daysLeft > 0 ? '$daysLeft hari' : 'Sudah lewat',
            valueColor: daysLeft < 0 ? AppTheme.accentRed : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            icon: '💸',
            label: 'Sisa Target',
            value: CurrencyFormatter.formatRupiah(_savings.remainingAmount),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            icon: '⏱️',
            label: 'Est. Selesai',
            value: estimatedMonths != null ? '~$estimatedMonths bln' : '-',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  /// Tombol tambah setoran
  Widget _buildDepositButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddDepositSheet(context),
        style: ElevatedButton.styleFrom(backgroundColor: _cardColor),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Setoran'),
      ),
    );
  }

  /// Banner notifikasi tabungan selesai
  Widget _buildCompletedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat! Target Tercapai!',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tabungan "${_savings.name}" sudah 100% terpenuhi',
                  style: TextStyle(
                    color: AppTheme.accentGreen.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Riwayat setoran
  Widget _buildDepositHistory(BuildContext context) {
    if (_savings.deposits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'Belum ada setoran',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final deposits = List<SavingsDeposit>.from(_savings.deposits)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Setoran (${deposits.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        ...deposits.map(
          (deposit) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _cardColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: _cardColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit.note ?? 'Setoran tabungan',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormatter.formatDateTime(deposit.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+ ${CurrencyFormatter.formatRupiah(deposit.amount)}',
                  style: TextStyle(
                    color: _cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom sheet untuk tambah setoran
  void _showAddDepositSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Setoran',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _DepositInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nominal Setoran',
                    prefixText: 'Rp ',
                    hintText: '0',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Nominal tidak boleh kosong';
                    }
                    if (CurrencyFormatter.parseRupiah(v) <= 0) {
                      return 'Nominal harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: _cardColor),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final amount =
                          CurrencyFormatter.parseRupiah(amountCtrl.text);
                      await context.read<SavingsService>().addDeposit(
                            savingsId: _savings.id,
                            amount: amount,
                            note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Simpan Setoran'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tabungan?'),
        content: const Text(
            'Semua data tabungan dan riwayat setoran akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SavingsService>().deleteSavings(_savings.id);
              if (context.mounted) Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _DepositInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) return oldValue;

    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
