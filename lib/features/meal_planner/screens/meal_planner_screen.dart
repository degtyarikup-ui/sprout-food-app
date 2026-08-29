import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../../analytics/screens/eco_analytics_screen.dart';
import '../../recipes/screens/recipe_detail_screen.dart';
import '../../recipes/screens/smart_cooking_screen.dart';
import '../models/meal_slot.dart';
import '../providers/meal_planner_provider.dart';
import 'ai_swap_modal.dart';

class MealPlannerScreen extends ConsumerWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(mealPlannerProvider);
    final selectedDayIndex = ref.watch(selectedDayIndexProvider);
    final ecoStats = ref.watch(ecoSavingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (mealPlan.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentDay = mealPlan[selectedDayIndex.clamp(0, mealPlan.length - 1)];
    final nextUncompletedSlot = currentDay.slots.firstWhere(
      (s) => !s.isCompleted && s.recipe != null,
      orElse: () => currentDay.slots.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🥑', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Text('Sprout', style: AppTypography.displayMedium.copyWith(fontSize: 22)),
          ],
        ),
        actions: [
          // Eco Savings Top Pill
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EcoAnalyticsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '${ecoStats.savedMoneyRub.round()} ₽',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
            tooltip: 'Пересобрать план Zero Waste',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(mealPlannerProvider.notifier).generateZeroWastePlan();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Недельное меню оптимизировано под свежесть холодильника!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 7-Day Horizontal Scroll Calendar
          SliverToBoxAdapter(
            child: Container(
              height: 84,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mealPlan.length,
                itemBuilder: (context, index) {
                  final day = mealPlan[index];
                  final isSelected = selectedDayIndex == index;
                  final isToday = index == 0;
                  final dayFormat = DateFormat('E', 'ru');
                  final numFormat = DateFormat('d');

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(selectedDayIndexProvider.notifier).state = index;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'Сегодня' : dayFormat.format(day.date).toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            numFormat.format(day.date),
                            style: AppTypography.titleLarge.copyWith(
                              color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Next Meal Hero Card (if on today or has next meal)
          if (nextUncompletedSlot.recipe != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildHeroNextMealCard(context, nextUncompletedSlot, currentDay.date, ref),
              ),
            ),

          // Daily Zero-Waste Chef Advice Banner
          if (currentDay.chefAdvice != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      const Text('🌱', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zero-Waste Совет шефа:',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.ecoGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentDay.chefAdvice!,
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF1B5E20),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Daily Macro summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDailyMacro('Калории', '${currentDay.totalCalories}', 'ккал', AppColors.caloriesColor),
                    _buildDailyMacro('Белки', '${currentDay.totalProtein}', 'г', AppColors.proteinColor),
                    _buildDailyMacro('Жиры', '${currentDay.totalFat}', 'г', AppColors.fatColor),
                    _buildDailyMacro('Углеводы', '${currentDay.totalCarbs}', 'г', AppColors.carbColor),
                  ],
                ),
              ),
            ),
          ),

          // Meal Slots List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final slot = currentDay.slots[index];
                  return _buildMealSlotCard(context, slot, currentDay.date, ref);
                },
                childCount: currentDay.slots.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroNextMealCard(
    BuildContext context,
    MealSlot slot,
    DateTime dayDate,
    WidgetRef ref,
  ) {
    final recipe = slot.recipe!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top
          Stack(
            children: [
              recipe.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      recipe.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      recipe.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(slot.type.emoji),
                      const SizedBox(width: 4),
                      Text(
                        'Следующий: ${slot.type.label}',
                        style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал • 2 порции',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                ),
                if (slot.prepAlert != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      slot.prepAlert!,
                      style: AppTypography.labelSmall.copyWith(color: const Color(0xFF943126)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SmartCookingScreen(recipe: recipe),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant_rounded, size: 18),
                        label: const Text('Готовить сейчас 👨‍🍳'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AiSwapModal(dayDate: dayDate, slot: slot),
                          );
                        },
                        child: const Text('Заменить ⚡'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlotCard(
    BuildContext context,
    MealSlot slot,
    DateTime dayDate,
    WidgetRef ref,
  ) {
    final recipe = slot.recipe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: slot.isCompleted
              ? AppColors.primary.withOpacity(0.3)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          // Checkbox for completion
          Checkbox(
            value: slot.isCompleted,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (_) {
              HapticFeedback.lightImpact();
              ref.read(mealPlannerProvider.notifier).completeMealSlot(dayDate, slot.id);
            },
          ),
          const SizedBox(width: 8),

          // Recipe Thumbnail or Placeholder
          if (recipe != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: recipe.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      recipe.imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      recipe.imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
            ),
          const SizedBox(width: 12),

          // Title & Slot Type
          Expanded(
            child: InkWell(
              onTap: recipe != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    }
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(slot.type.emoji),
                      const SizedBox(width: 4),
                      Text(
                        slot.type.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe?.title ?? 'Блюдо не назначено',
                    style: AppTypography.titleSmall.copyWith(
                      decoration: slot.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipe != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Swap Action
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
            tooltip: 'AI Замена',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AiSwapModal(dayDate: dayDate, slot: slot),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMacro(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.textTertiaryLight)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: value,
            style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: ' $unit',
                style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.textTertiaryLight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
