import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';

enum ScanMode { receipt, fridgeShelf }

class AiMagicScanScreen extends ConsumerStatefulWidget {
  const AiMagicScanScreen({super.key});

  @override
  ConsumerState<AiMagicScanScreen> createState() => _AiMagicScanScreenState();
}

class _AiMagicScanScreenState extends ConsumerState<AiMagicScanScreen>
    with SingleTickerProviderStateMixin {
  ScanMode _mode = ScanMode.receipt;
  bool _isScanning = false;
  List<ProductItem>? _recognizedProducts;
  final Set<String> _selectedIds = {};
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _performScan() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
      _recognizedProducts = null;
    });

    final results = await GeminiAIService.scanReceiptOrFridge(
      rawOcrText: _mode == ScanMode.receipt
          ? 'Чек Пятерочка: Томаты черри 250г 160р, Филе цыпленка 500г 280р, Сыр Фета 200г 220р, Шпинат свежий 100г 110р, Авокадо Хасс 2шт 240р'
          : 'Фото открытого холодильника: упаковка томатов, куриное филе на полке, сыр фета, пучок шпината, авокадо',
    );

    setState(() {
      _isScanning = false;
      _recognizedProducts = results;
      _selectedIds.addAll(results.map((r) => r.id));
    });
    HapticFeedback.heavyImpact();
  }

  void _saveRecognizedToFridge() {
    if (_recognizedProducts == null) return;
    final toAdd = _recognizedProducts!.where((p) => _selectedIds.contains(p.id)).toList();

    ref.read(fridgeProvider.notifier).addMultipleProducts(toAdd);
    ref.read(ecoSavingsProvider.notifier).recordProductScanned(toAdd.length);

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Добавлено ${toAdd.length} продуктов в Холодильник!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Magic Scan ✨',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Segmented Switcher
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: '🧾 Чек из магазина',
                      isSelected: _mode == ScanMode.receipt,
                      onTap: () => setState(() => _mode = ScanMode.receipt),
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      label: '🧊 Полки холодильника',
                      isSelected: _mode == ScanMode.fridgeShelf,
                      onTap: () => setState(() => _mode = ScanMode.fridgeShelf),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder Camera Frame or Recognized Checklist
            Expanded(
              child: _recognizedProducts == null
                  ? _buildCameraViewfinder()
                  : _buildResultsChecklist(isDark),
            ),

            // Bottom Scan Controls
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black,
              child: _recognizedProducts == null
                  ? SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _isScanning ? null : _performScan,
                        child: _isScanning
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Gemini Vision распознает...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _mode == ScanMode.receipt ? 'Сканировать чек 📸' : 'Сделать фото полок 📸',
                                    style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _saveRecognizedToFridge,
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          'Добавить ${_selectedIds.length} прод. в холодильник',
                          style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle simulated lens view
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C2833),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mode == ScanMode.receipt ? Icons.receipt_long_rounded : Icons.kitchen_rounded,
                    size: 72,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _mode == ScanMode.receipt
                        ? 'Наведите камеру на чек'
                        : 'Сфотографируйте полки холодильника',
                    style: AppTypography.titleMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ИИ определит названия, вес и сроки хранения',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),

          // Animated Laser Scanner Line when active
          if (_isScanning)
            AnimatedBuilder(
              animation: _laserController,
              builder: (context, child) {
                return Positioned(
                  top: 40 + (_laserController.value * 280),
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.8),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultsChecklist(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Распознано ИИ (5 продуктов)', style: AppTypography.titleMedium),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIds.length == _recognizedProducts!.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_recognizedProducts!.map((p) => p.id));
                    }
                  });
                },
                child: Text(_selectedIds.length == _recognizedProducts!.length ? 'Снять все' : 'Выбрать все'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _recognizedProducts!.length,
              itemBuilder: (context, index) {
                final item = _recognizedProducts![index];
                final isSelected = _selectedIds.contains(item.id);

                return CheckboxListTile(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(item.id);
                      } else {
                        _selectedIds.remove(item.id);
                      }
                    });
                  },
                  secondary: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(item.name, style: AppTypography.titleSmall),
                  subtitle: Text(
                    '${item.amount.toStringAsFixed(0)} ${item.unit} • Срок: ${item.daysUntilExpiry} дн. • ~${item.estimatedPrice?.round()} ₽',
                    style: AppTypography.bodySmall,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
