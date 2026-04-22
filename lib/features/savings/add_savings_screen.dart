import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/savings_model.dart';
import '../../services/auth_service.dart';
import '../../services/savings_service.dart';
import '../../widgets/currency_formatter.dart';

/// Halaman tambah atau edit tabungan
class AddSavingsScreen extends StatefulWidget {
  final SavingsModel? existingSavings;

  const AddSavingsScreen({super.key, this.existingSavings});

  @override
  State<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends State<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  String _selectedEmoji = '🎯';
  String _selectedColorHex = '#6366F1';
  bool _isLoading = false;

  bool get _isEditMode => widget.existingSavings != null;

  // Pilihan emoji untuk tabungan
  final List<String> _emojiOptions = [
    '🎯',
    '💰',
    '🏠',
    '🚗',
    '✈️',
    '💻',
    '📱',
    '🎓',
    '💍',
    '🏖️',
    '🎮',
    '👗',
    '🏋️',
    '🎨',
    '📸',
    '🌟',
  ];

  // Pilihan warna
  final List<String> _colorOptions = [
    '#6366F1',
    '#10B981',
    '#EF4444',
    '#F59E0B',
    '#3B82F6',
    '#EC4899',
    '#8B5CF6',
    '#14B8A6',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = widget.existingSavings!;
      _nameController.text = s.name;
      _targetController.text = CurrencyFormatter.formatNumber(s.targetAmount);
      _targetDate = s.targetDate;
      _selectedEmoji = s.emoji;
      _selectedColorHex = s.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthService>().currentUser!.id;
      final savingsService = context.read<SavingsService>();
      final target = CurrencyFormatter.parseRupiah(_targetController.text);

      if (_isEditMode) {
        final updated = widget.existingSavings!.copyWith(
          name: _nameController.text,
          targetAmount: target,
          targetDate: _targetDate,
          emoji: _selectedEmoji,
          colorHex: _selectedColorHex,
        );
        await savingsService.updateSavings(updated);
      } else {
        await savingsService.addSavings(
          userId: userId,
          name: _nameController.text,
          targetAmount: target,
          targetDate: _targetDate,
          emoji: _selectedEmoji,
          colorHex: _selectedColorHex,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Tabungan berhasil diperbarui'
                : 'Tabungan baru berhasil dibuat'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Tabungan' : 'Tabungan Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview kartu tabungan
              _buildPreviewCard(),
              const SizedBox(height: 24),

              // Field nama tabungan
              _buildLabel('Nama Tabungan'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Beli Laptop, Liburan Bali',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama tabungan tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Field target nominal
              _buildLabel('Target Nominal'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RupiahInputFormatter(),
                ],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Target nominal tidak boleh kosong';
                  }
                  final amount = CurrencyFormatter.parseRupiah(v);
                  if (amount <= 0) return 'Target harus lebih dari 0';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pilih tanggal target
              _buildLabel('Target Tanggal Selesai'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 12),
                      Text(DateFormatter.formatDayDate(_targetDate)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pilih emoji
              _buildLabel('Pilih Ikon'),
              const SizedBox(height: 8),
              _buildEmojiSelector(),

              const SizedBox(height: 20),

              // Pilih warna
              _buildLabel('Pilih Warna'),
              const SizedBox(height: 8),
              _buildColorSelector(),

              const SizedBox(height: 32),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Buat Tabungan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  /// Preview kartu tabungan secara live
  Widget _buildPreviewCard() {
    Color cardColor;
    try {
      final hex = _selectedColorHex.replaceAll('#', '');
      cardColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      cardColor = AppTheme.primaryColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withValues(alpha: 0.8), cardColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(_selectedEmoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? 'Nama Tabungan'
                      : _nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${DateFormatter.formatDate(_targetDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _emojiOptions.map((emoji) {
        final isSelected = _selectedEmoji == emoji;
        return GestureDetector(
          onTap: () => setState(() => _selectedEmoji = emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 10,
      children: _colorOptions.map((hex) {
        final isSelected = _selectedColorHex == hex;
        Color color;
        try {
          color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
        } catch (_) {
          color = AppTheme.primaryColor;
        }

        return GestureDetector(
          onTap: () => setState(() => _selectedColorHex = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// Formatter Rupiah reusable
class _RupiahInputFormatter extends TextInputFormatter {
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
