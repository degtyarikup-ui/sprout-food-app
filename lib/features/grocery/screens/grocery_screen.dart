import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';

class GroceryScreen extends ConsumerWidget {
  const GroceryScreen({super.key});

  void _showAddCustomItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController(text: '1');
    String unit = 'шт';
    String department = 'Овощи и зелень';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text('Добавить покупку', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Что купить?'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Количество'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(labelText: 'Ед. изм.'),
                    items: ['шт', 'г', 'кг', 'мл', 'л', 'уп']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) unit = val;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final amount = double.tryParse(amountController.text) ?? 1.0;
                  ref.read(groceryProvider.notifier).addItem(
                        GroceryItem(
                          name: name,
                          amount: amount,
                          unit: unit,
                          department: department,
                          estimatedCost: 120,
                        ),
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Добавить в список'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedItems = ref.watch(groupedGroceryProvider);
    final allItems = ref.watch(groceryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final checkedCount = allItems.where((i) => i.isChecked).length;
    final totalCount = allItems.length;
    final totalCost = allItems
        .where((i) => !i.isChecked)
        .fold(0.0, (sum, i) => sum + (i.estimatedCost ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Список покупок', style: AppTypography.displayMedium),
            Text(
              'Сгруппировано по отделам супермаркета',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
            tooltip: 'Синхронизировать с меню недели',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(groceryProvider.notifier).syncFromMealPlan();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Список обновлен на основе недостающих продуктов!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Добавить вручную',
            onPressed: () => _showAddCustomItemDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Progress & Cost Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Куплено $checkedCount из $totalCount',
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Осталось купить на ~${totalCost.round()} ₽',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                        if (checkedCount > 0)
                          TextButton.icon(
                            onPressed: () {
                              ref.read(groceryProvider.notifier).clearChecked();
                            },
                            icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                            label: const Text('Очистить купленное', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? checkedCount / totalCount : 0,
                        minHeight: 8,
                        backgroundColor: AppColors.cardBorder,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Auto Move to Fridge Hint
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        'При вычеркивании продукт автоматически попадает в «Мой Холодильник» со сроком годности.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Department Grouped Sections
          if (allItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🛒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Список покупок пуст', style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text('Нажмите синхронизацию для генерации из меню', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final department = groupedItems.keys.elementAt(index);
                    final items = groupedItems[department]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_getDepartmentEmoji(department), style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(department, style: AppTypography.titleSmall),
                              const Spacer(),
                              Text(
                                '${items.length} шт',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          ...items.map((item) {
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.urgentExpiring,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                ref.read(groceryProvider.notifier).removeItem(item.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item.isChecked,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      onChanged: (_) {
                                        HapticFeedback.lightImpact();
                                        ref.read(groceryProvider.notifier).toggleItem(item.id);
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: AppTypography.bodyMedium.copyWith(
                                              decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                              color: item.isChecked
                                                  ? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                                                  : null,
                                            ),
                                          ),
                                          if (item.recipeOriginTitle != null) ...[
                                            Text(
                                              'для: ${item.recipeOriginTitle}',
                                              style: AppTypography.bodySmall.copyWith(
                                                fontSize: 11,
                                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  childCount: groupedItems.keys.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDepartmentEmoji(String department) {
    if (department.contains('Овощи')) return '🥦';
    if (department.contains('Молочные')) return '🧀';
    if (department.contains('Мясо')) return '🥩';
    if (department.contains('Бакалея')) return '🌾';
    return '🛒';
  }
}
