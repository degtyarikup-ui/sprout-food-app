import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';

class GroceryScreen extends ConsumerWidget {
  const GroceryScreen({super.key});

  void _transferPurchasedToFridge(BuildContext context, WidgetRef ref, List<GroceryItem> checkedItems) {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();

    final newProducts = checkedItems.map((item) {
      int shelfLifeDays = 7;
      String emoji = '🛒';

      final dept = item.department.toLowerCase();
      final name = item.name.toLowerCase();

      if (dept.contains('молоч') || name.contains('молок') || name.contains('сыр') || name.contains('яйц')) {
        shelfLifeDays = 5;
        emoji = name.contains('яйц') ? '🥚' : (name.contains('сыр') ? '🧀' : '🥛');
      } else if (dept.contains('овощ') || dept.contains('зелен') || name.contains('томат') || name.contains('огур')) {
        shelfLifeDays = 4;
        emoji = name.contains('томат') ? '🍅' : (name.contains('авокадо') ? '🥑' : '🥬');
      } else if (dept.contains('мясо') || dept.contains('рыб') || name.contains('куриц') || name.contains('филе')) {
        shelfLifeDays = 3;
        emoji = name.contains('рыб') ? '🐟' : '🍗';
      } else if (dept.contains('бакале') || name.contains('макарон') || name.contains('круп') || name.contains('масло')) {
        shelfLifeDays = 90;
        emoji = name.contains('масло') ? '🫒' : '🍝';
      }

      return ProductItem(
        name: item.name,
        amount: item.amount,
        unit: item.unit,
        category: item.department,
        addedDate: now,
        expiryDate: now.add(Duration(days: shelfLifeDays)),
        emoji: emoji,
        estimatedPrice: (item.estimatedCost ?? 100).toDouble(),
      );
    }).toList();

    ref.read(fridgeProvider.notifier).addMultipleProducts(newProducts);

    // Remove transferred items from grocery list
    for (final item in checkedItems) {
      ref.read(groceryProvider.notifier).removeItem(item.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('Купленные продукты (${checkedItems.length} поз.) перенесены в холодильник!'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
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
                  color: AppColors.divider,
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
              decoration: const InputDecoration(hintText: 'Наименование'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Кол-во'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: unit,
                        items: ['шт', 'г', 'кг', 'мл', 'л', 'уп']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) unit = val;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
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
                child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.w700)),
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

    final checkedItems = allItems.where((i) => i.isChecked).toList();
    final checkedCount = checkedItems.length;
    final totalCount = allItems.length;
    final totalCost = allItems
        .where((i) => !i.isChecked)
        .fold(0.0, (sum, i) => sum + (i.estimatedCost ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Покупки', style: AppTypography.displayMedium),
            Text(
              'Куплено $checkedCount из $totalCount • ~${totalCost.round()} ₽',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 22),
            tooltip: 'Синхронизировать с меню',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(groceryProvider.notifier).syncFromMealPlan();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Список покупок синхронизирован с меню недели'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () => _showAddCustomItemDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Transfer to Fridge Action Banner (if checked items exist)
          if (checkedCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.kitchen_rounded, color: AppColors.primaryForeground, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Куплено $checkedCount поз.',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                            ),
                            const Text(
                              'Перенести их в запасы холодильника?',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.primaryForeground,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _transferPurchasedToFridge(context, ref, checkedItems),
                        child: const Text('В холодильник', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
                    const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.textTertiary),
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
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final department = groupedItems.keys.elementAt(index);
                    final items = groupedItems[department]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(department, style: AppTypography.titleSmall),
                              const Spacer(),
                              Text(
                                '${items.length} поз.',
                                style: AppTypography.labelSmall,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          ...items.map((item) {
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.statusUrgent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                HapticFeedback.mediumImpact();
                                ref.read(groceryProvider.notifier).removeItem(item.id);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} удален из списка'),
                                    duration: const Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    action: SnackBarAction(
                                      label: 'Отменить',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        ref.read(groceryProvider.notifier).undoLastDeletedItem();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item.isChecked,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                      onChanged: (_) {
                                        HapticFeedback.lightImpact();
                                        ref.read(groceryProvider.notifier).toggleItem(item.id);
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: AppTypography.bodyMedium.copyWith(
                                              decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                              color: item.isChecked ? AppColors.textTertiary : AppColors.textPrimary,
                                            ),
                                          ),
                                          if (item.recipeOriginTitle != null) ...[
                                            Text(
                                              'для: ${item.recipeOriginTitle}',
                                              style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textPrimary,
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
}
