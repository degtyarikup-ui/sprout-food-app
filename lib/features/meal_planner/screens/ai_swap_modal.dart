import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../recipes/data/curated_recipes.dart';
import '../models/meal_slot.dart';
import '../providers/meal_planner_provider.dart';

class AiSwapModal extends ConsumerWidget {
  final DateTime dayDate;
  final MealSlot slot;

  const AiSwapModal({super.key, required this.dayDate, required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allRecipes = kCuratedRecipes;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 24)),
              Text('AI Замена блюда', style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Выберите альтернативное блюдо для слота «${slot.type.label}»',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: allRecipes.length,
              itemBuilder: (context, index) {
                final r = allRecipes[index];
                final isCurrent = slot.recipe?.id == r.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: r.imageUrl.startsWith('assets/')
                            ? Image.asset(
                                r.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                r.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: AppTypography.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              '${r.totalTimeMinutes} мин • ${r.calories} ккал • ${r.difficulty}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(mealPlannerProvider.notifier).swapSlotRecipe(dayDate, slot.id, r);
                          Navigator.pop(context);
                        },
                        child: Text(isCurrent ? 'Выбрано' : 'Заменить'),
                      ),
                    ],
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
