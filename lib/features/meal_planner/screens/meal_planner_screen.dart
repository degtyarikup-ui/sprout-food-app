import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../../analytics/screens/eco_analytics_screen.dart';
import '../../recipes/models/recipe.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../../recipes/screens/recipe_detail_screen.dart';
import '../../recipes/screens/smart_cooking_screen.dart';
import '../models/meal_slot.dart';
import '../providers/meal_planner_provider.dart';

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  void _showRecipePickerSheet(BuildContext context, DateTime dayDate, MealSlot slot) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecipePickerModal(
        slot: slot,
        onRecipeSelected: (recipe) {
          ref.read(mealPlannerProvider.notifier).assignRecipeToSlot(dayDate, slot.id, recipe);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Text('«${recipe.title}» добавлено в ${slot.type.label.toLowerCase()}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomSlotSheet(BuildContext context, DateTime dayDate) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Добавить прием пищи', style: AppTypography.titleMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildSlotTypeChoice(ctx, 'Перекус', MealType.snack, dayDate),
                const SizedBox(width: 8),
                _buildSlotTypeChoice(ctx, 'Полдник', MealType.snack, dayDate),
                const SizedBox(width: 8),
                _buildSlotTypeChoice(ctx, 'Поздний ужин', MealType.dinner, dayDate),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTypeChoice(BuildContext ctx, String title, MealType type, DateTime dayDate) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(ctx);
          ref.read(mealPlannerProvider.notifier).addMealSlot(dayDate, type, null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _confirmClearPlan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Очистить план питания?'),
        content: const Text('Все блюда будут убраны из слотов, и вы сможете составить рацион с чистого листа.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusUrgent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(mealPlannerProvider.notifier).clearEntirePlan();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('План питания очищен'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.textPrimary,
                ),
              );
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final hasAnyMealsInDay = currentDay.slots.any((s) => s.recipe != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('План питания', style: AppTypography.displayMedium),
        actions: [
          // Auto-Plan AI Chef Button
          Container(
            margin: const EdgeInsets.only(right: 6),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text(
                'Автоплан',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(mealPlannerProvider.notifier).generateZeroWastePlan();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.primaryForeground, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Шеф-ИИ составил меню на неделю под продукты в холодильнике',
                            style: TextStyle(color: AppColors.primaryForeground, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Clear Plan Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textTertiary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'clear') _confirmClearPlan();
              if (val == 'eco') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EcoAnalyticsScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusUrgent),
                    SizedBox(width: 10),
                    Text('Очистить весь план', style: TextStyle(color: AppColors.statusUrgent)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'eco',
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('Эко-статистика (${ecoStats.savedMoneyRub.round()} ₽)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 7-Day Horizontal Selector (Zero Borders)
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
                  final dayFilledCount = day.slots.where((s) => s.recipe != null).length;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(selectedDayIndexProvider.notifier).state = index;
                    },
                    child: Container(
                      width: 54,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'Сегодня' : dayFormat.format(day.date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white70 : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            numFormat.format(day.date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          if (dayFilledCount > 0) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Daily Macro Summary Bar (if meals present)
          if (hasAnyMealsInDay)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
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

          // Next Meal Hero Card (if has a recipe)
          if (nextUncompletedSlot.recipe != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildHeroNextMealCard(context, nextUncompletedSlot, currentDay.date),
              ),
            )
          else if (!hasAnyMealsInDay)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.restaurant_menu_rounded, size: 36, color: AppColors.textTertiary),
                      const SizedBox(height: 10),
                      Text(
                        'День пока не распланирован',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Нажмите «+» в слотах ниже, чтобы выбрать блюда вручную, или нажмите «Автоплан» вверху.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Meal Slots List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final slot = currentDay.slots[index];
                  return _buildMealSlotCard(context, slot, currentDay.date);
                },
                childCount: currentDay.slots.length,
              ),
            ),
          ),

          // Add Extra Meal Slot Button (+)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showAddCustomSlotSheet(context, currentDay.date),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Добавить перекус или прием пищи',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
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
  ) {
    final recipe = slot.recipe!;

    return Container(
      height: 230,
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
            recipe.imageUrl.startsWith('assets/')
                ? Image.asset(recipe.imageUrl, fit: BoxFit.cover)
                : Image.network(recipe.imageUrl, fit: BoxFit.cover),

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
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                      child: const Text('Готовить', style: TextStyle(fontWeight: FontWeight.w700)),
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
  ) {
    final recipe = slot.recipe;

    if (recipe == null) {
      // Empty Slot Card with prominent add trigger
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.type.label, style: AppTypography.titleSmall),
                  const SizedBox(height: 2),
                  const Text(
                    'Блюдо не назначено • Нажмите, чтобы выбрать',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceMuted,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showRecipePickerSheet(context, dayDate, slot),
              child: const Text('+ Добавить', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    // Filled Meal Slot Card with Checkbox, Swap, and Clear actions
    return Dismissible(
      key: Key('slot_${slot.id}_${recipe.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.statusUrgent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(mealPlannerProvider.notifier).removeRecipeFromSlot(dayDate, slot.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recipe.title} убрано из плана'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: 'Отменить',
              textColor: Colors.white,
              onPressed: () {
                ref.read(mealPlannerProvider.notifier).assignRecipeToSlot(dayDate, slot.id, recipe);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: recipe.imageUrl.startsWith('assets/')
                    ? Image.asset(recipe.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                    : Image.network(recipe.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Slot Type
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.type.label,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipe.title,
                      style: AppTypography.titleSmall.copyWith(
                        decoration: slot.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            // Swap Recipe Button
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.textSecondary),
              tooltip: 'Заменить блюдо',
              onPressed: () => _showRecipePickerSheet(context, dayDate, slot),
            ),

            // Remove from slot button (Trash)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
              tooltip: 'Убрать из плана',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(mealPlannerProvider.notifier).removeRecipeFromSlot(dayDate, slot.id);
              },
            ),
          ],
        ),
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

class _RecipePickerModal extends ConsumerStatefulWidget {
  final MealSlot slot;
  final ValueChanged<Recipe> onRecipeSelected;

  const _RecipePickerModal({
    required this.slot,
    required this.onRecipeSelected,
  });

  @override
  ConsumerState<_RecipePickerModal> createState() => _RecipePickerModalState();
}

class _RecipePickerModalState extends ConsumerState<_RecipePickerModal> {
  int _filterIndex = 0; // 0 = Все, 1 = В наличии, 2 = Избранное
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scoredRecipes = ref.watch(scoredRecipesProvider);
    final fridgeCount = ref.watch(fridgeMatchCountProvider);
    final favCount = ref.watch(favoriteRecipesCountProvider);

    List<RecipeWithMatchScore> filtered = scoredRecipes;
    if (_filterIndex == 1) {
      filtered = filtered.where((r) => r.availableIngredients > 0).toList();
    } else if (_filterIndex == 2) {
      filtered = filtered.where((r) => r.recipe.isFavorite).toList();
    }

    if (_query.isNotEmpty) {
      filtered = filtered
          .where((r) => r.recipe.title.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выбрать блюдо: ${widget.slot.type.label}',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              onChanged: (val) => setState(() => _query = val),
              decoration: const InputDecoration(
                hintText: 'Поиск рецептов...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
              ),
            ),
          ),

          // Filter Pills: [ Все | В наличии | Избранное ]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterPill('Все блюда', 0),
                const SizedBox(width: 8),
                _buildFilterPill('В наличии ($fridgeCount)', 1),
                const SizedBox(width: 8),
                _buildFilterPill('Избранное ($favCount)', 2),
              ],
            ),
          ),

          // Recipes List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Нет подходящих блюд', style: TextStyle(color: AppColors.textTertiary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final recipe = item.recipe;

                      return GestureDetector(
                        onTap: () => widget.onRecipeSelected(recipe),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: recipe.imageUrl.startsWith('assets/')
                                    ? Image.asset(recipe.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                                    : Image.network(recipe.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.title,
                                      style: AppTypography.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал',
                                      style: AppTypography.bodySmall,
                                    ),
                                    if (item.availableIngredients > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'В наличии ${item.availableIngredients} из ${item.totalIngredients} продуктов',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, int index) {
    final isSelected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryForeground : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
