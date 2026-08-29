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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badges = [
      {'emoji': '🥑', 'title': 'Первый скан', 'desc': 'Оцифровано более 10 продуктов', 'unlocked': true},
      {'emoji': '🔥', 'title': 'Спасатель свежести', 'desc': 'Приготовлено блюдо из срочных остатков', 'unlocked': true},
      {'emoji': '🌿', 'title': 'Zero-Waste Стрик', 'desc': '12 дней без выброшенной еды', 'unlocked': true},
      {'emoji': '👨‍🍳', 'title': 'Шеф Голоса', 'desc': 'Готовка в Hands-Free режиме', 'unlocked': true},
      {'emoji': '💰', 'title': 'Эко-Инвестор', 'desc': 'Сэкономлено более 5 000 ₽', 'unlocked': false},
      {'emoji': '🌍', 'title': 'Планетарный страж', 'desc': 'Спас рекордные 10 кг еды', 'unlocked': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Эко-импакт & Экономия', style: AppTypography.displayMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level / Rank Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏆', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Уровень 4: Шеф Осознанности',
                          style: AppTypography.titleMedium.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Вы вошли в топ 5% самых экономных кулинаров этого месяца!',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Big 4 Metrics Grid
            Row(
              children: [
                _buildMetricTile(
                  context: context,
                  label: 'Сэкономлено денег',
                  value: '${stats.savedMoneyRub.round()} ₽',
                  sub: '~17 400 ₽ в год',
                  icon: '💰',
                  color: AppColors.savingsGold,
                ),
                const SizedBox(width: 12),
                _buildMetricTile(
                  context: context,
                  label: 'Спасенная еда',
                  value: '${stats.savedFoodKg.toStringAsFixed(1)} кг',
                  sub: '${stats.recipesZeroWasted} блюд приготовлено',
                  icon: '🥑',
                  color: AppColors.ecoGreen,
                ),
              ],
            ),
            const SizedBox(width: 12, height: 12),
            Row(
              children: [
                _buildMetricTile(
                  context: context,
                  label: 'Ударный стрик',
                  value: '${stats.streakDays} дней',
                  sub: 'без отходов',
                  icon: '🔥',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _buildMetricTile(
                  context: context,
                  label: 'Предотвращен CO2',
                  value: '${stats.co2SavedKg.toStringAsFixed(1)} кг',
                  sub: 'эквивалент 35 км авто',
                  icon: '🌱',
                  color: AppColors.freshGood,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Badges Section
            Text('Достижения & Бейджи', style: AppTypography.titleLarge),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final b = badges[index];
                final isUnlocked = b['unlocked'] as bool;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isUnlocked ? AppColors.primary.withOpacity(0.3) : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b['emoji'] as String, style: const TextStyle(fontSize: 26)),
                          if (isUnlocked)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)
                          else
                            const Icon(Icons.lock_outline_rounded, color: AppColors.textTertiaryLight, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b['title'] as String,
                        style: AppTypography.titleSmall.copyWith(
                          color: isUnlocked ? null : AppColors.textTertiaryLight,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b['desc'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
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
    required BuildContext context,
    required String label,
    required String value,
    required String sub,
    required String icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSmall),
            const SizedBox(height: 2),
            Text(
              sub,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
