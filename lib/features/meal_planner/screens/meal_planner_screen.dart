import 'dart:ui';
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

    if (mealPlan.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    final currentDay = mealPlan[selectedDayIndex.clamp(0, mealPlan.length - 1)];
    final nextUncompletedSlot = currentDay.slots.firstWhere(
      (s) => !s.isCompleted && s.recipe != null,
      orElse: () => currentDay.slots.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('План питания', style: AppTypography.displayMedium),
        actions: [
          // Eco Savings Minimal Capsule
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EcoAnalyticsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${ecoStats.savedMoneyRub.round()} ₽ сэкономлено',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Оптимизировать рацион',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(mealPlannerProvider.notifier).generateZeroWastePlan();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Рацион оптимизирован под свежесть холодильника'),
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
          // 7-Day Horizontal Minimal Selector
          SliverToBoxAdapter(
            child: Container(
              height: 72,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
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
                    child: Container(
                      width: 52,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'Сегодня' : dayFormat.format(day.date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            numFormat.format(day.date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
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

          // Daily Macro Summary Bar (Reference 4 Minimal Style)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMinimalMacroStat('${currentDay.totalCalories}', 'ккал'),
                    _buildMacroSeparator(),
                    _buildMinimalMacroStat('${currentDay.totalProtein} г', 'белки'),
                    _buildMacroSeparator(),
                    _buildMinimalMacroStat('${currentDay.totalFat} г', 'жиры'),
                    _buildMacroSeparator(),
                    _buildMinimalMacroStat('${currentDay.totalCarbs} г', 'углеводы'),
                  ],
                ),
              ),
            ),
          ),

          // Next Meal Full-Bleed Hero Card
          if (nextUncompletedSlot.recipe != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildHeroNextMealCard(context, nextUncompletedSlot, currentDay.date, ref),
              ),
            ),

          // Meal Slots List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed Photo Hero
            recipe.imageUrl.startsWith('assets/')
                ? Image.asset(recipe.imageUrl, fit: BoxFit.cover)
                : Image.network(recipe.imageUrl, fit: BoxFit.cover),

            // Seamless Gradient: Darkening bottom ~20-25%
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.18, 0.58, 0.78, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),

            // Next Meal Pill on Top
            Positioned(
              top: 14,
              left: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Следующий: ${slot.type.label}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Text & Action: Directly on the seamless gradient without any hard box
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recipe.title,
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      child: const Text('Готовить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Checkbox for completion
          Checkbox(
            value: slot.isCompleted,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            onChanged: (_) {
              HapticFeedback.lightImpact();
              ref.read(mealPlannerProvider.notifier).completeMealSlot(dayDate, slot.id);
            },
          ),

          // Recipe Thumbnail
          if (recipe != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: recipe.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      recipe.imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      recipe.imageUrl,
                      width: 52,
                      height: 52,
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
                  Text(
                    slot.type.label,
                    style: AppTypography.labelSmall,
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
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Swap Action
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.textTertiary),
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

  Widget _buildMinimalMacroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('•', style: TextStyle(color: AppColors.divider)),
    );
  }
}
