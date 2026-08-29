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
    final allRecipes = kCuratedRecipes;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Замена блюда', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Выберите альтернативное блюдо для «${slot.type.label}»',
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
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : AppColors.cardBorder,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: r.imageUrl.startsWith('assets/')
                            ? Image.asset(
                                r.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                r.imageUrl,
                                width: 56,
                                height: 56,
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
                              '${r.totalTimeMinutes} мин • ${r.calories} ккал',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent ? AppColors.surfaceMuted : AppColors.primary,
                          foregroundColor: isCurrent ? AppColors.textPrimary : AppColors.primaryForeground,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(mealPlannerProvider.notifier).swapSlotRecipe(dayDate, slot.id, r);
                          Navigator.pop(context);
                        },
                        child: Text(isCurrent ? 'Выбрано' : 'Выбрать'),
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
