import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/eco_savings_provider.dart';

class EcoAnalyticsScreen extends ConsumerWidget {
  const EcoAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(ecoSavingsProvider);

    final badges = [
      {'title': 'Первый скан', 'desc': 'Оцифровано более 10 продуктов', 'unlocked': true, 'icon': Icons.qr_code_scanner_rounded},
      {'title': 'Контроль свежести', 'desc': 'Приготовлено блюдо из срочных остатков', 'unlocked': true, 'icon': Icons.kitchen_rounded},
      {'title': 'Zero-Waste Стрик', 'desc': '12 дней без выброшенной еды', 'unlocked': true, 'icon': Icons.eco_rounded},
      {'title': 'Шеф-режим', 'desc': 'Готовка с голосовым таймером', 'unlocked': true, 'icon': Icons.timer_outlined},
      {'title': 'Экономия', 'desc': 'Сэкономлено более 5 000 ₽', 'unlocked': false, 'icon': Icons.account_balance_wallet_outlined},
      {'title': 'Эко-баланс', 'desc': 'Спас рекордные 10 кг еды', 'unlocked': false, 'icon': Icons.public_rounded},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Аналитика & Экономия', style: AppTypography.displayMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big 4 Metrics Grid (Clean White Cards)
            Row(
              children: [
                _buildMetricTile(
                  label: 'Сэкономлено',
                  value: '${stats.savedMoneyRub.round()} ₽',
                  sub: '~17 400 ₽ в год',
                  icon: Icons.savings_outlined,
                ),
                const SizedBox(width: 10),
                _buildMetricTile(
                  label: 'Спасенная еда',
                  value: '${stats.savedFoodKg.toStringAsFixed(1)} кг',
                  sub: '${stats.recipesZeroWasted} блюд приготовлено',
                  icon: Icons.eco_outlined,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricTile(
                  label: 'Стрик без отходов',
                  value: '${stats.streakDays} дн.',
                  sub: 'непрерывно',
                  icon: Icons.repeat_rounded,
                ),
                const SizedBox(width: 10),
                _buildMetricTile(
                  label: 'Предотвращен CO2',
                  value: '${stats.co2SavedKg.toStringAsFixed(1)} кг',
                  sub: 'эквивалент 35 км авто',
                  icon: Icons.cloud_done_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Achievements Section
            Text('Достижения', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final b = badges[index];
                final isUnlocked = b['unlocked'] as bool;
                final icon = b['icon'] as IconData;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(icon, size: 22, color: isUnlocked ? AppColors.primary : AppColors.textTertiary),
                          if (isUnlocked)
                            const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary)
                          else
                            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textTertiary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b['title'] as String,
                        style: AppTypography.titleSmall.copyWith(
                          color: isUnlocked ? AppColors.textPrimary : AppColors.textTertiary,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b['desc'] as String,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.numberMetric,
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSmall),
            const SizedBox(height: 2),
            Text(
              sub,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
