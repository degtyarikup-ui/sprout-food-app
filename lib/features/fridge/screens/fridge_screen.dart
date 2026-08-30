import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../ai_scanner/screens/ai_magic_scan_screen.dart';
import '../../family/providers/family_provider.dart';
import '../../grocery/models/grocery_item.dart';
import '../../grocery/providers/grocery_provider.dart';
import '../../profile/screens/preferences_modal.dart';
import '../models/freshness_category.dart';
import '../models/product_item.dart';
import '../providers/fridge_provider.dart';
import 'add_product_sheet.dart';

class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({super.key});

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen> {
  int _selectedTab = 0; // 0 = В наличии, 1 = Список покупок
  FreshnessCategory? _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyProvider.notifier).refreshFromCloud();
    });
  }

  // ── Transfer Purchased to Fridge ──────────────────────────────────────────
  void _transferPurchasedToFridge(List<GroceryItem> checkedItems) {
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

    for (final item in checkedItems) {
      ref.read(groceryProvider.notifier).removeItem(item.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('Купленные продукты (${checkedItems.length} поз.) добавлены в холодильник!'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Clear Entire Fridge Confirmation ──────────────────────────────────────
  void _confirmClearFridge() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Очистить холодильник?'),
        content: const Text('Все продукты будут удалены из списка запасов.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusUrgent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              ref.read(fridgeProvider.notifier).clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  content: Text('Холодильник полностью очищен'),
                ),
              );
            },
            child: const Text('Очистить', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Add Custom Grocery Item ───────────────────────────────────────────────
  void _showAddGroceryDialog() {
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
                          if (val != null) setState(() => unit = val);
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

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final fridgeItems = ref.watch(fridgeProvider);
    final groceryItems = ref.watch(groceryProvider);
    final groupedGrocery = ref.watch(groupedGroceryProvider);
    final family = ref.watch(familyProvider);

    final checkedGrocery = groceryItems.where((i) => i.isChecked).toList();
    final unboughtGroceryCount = groceryItems.where((i) => !i.isChecked).length;
    final totalGroceryCost = groceryItems
        .where((i) => !i.isChecked)
        .fold(0.0, (sum, i) => sum + (i.estimatedCost ?? 0));

    // Filtered Fridge Items
    final filteredFridgeItems = fridgeItems.where((item) {
      if (_selectedFilter != null && item.freshness != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    filteredFridgeItems.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    final urgentCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.urgent).length;
    final soonCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.soon).length;
    final goodCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.good).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Продукты', style: AppTypography.displayMedium),
            Text(
              _selectedTab == 0
                  ? '${fridgeItems.length} позиций в наличии'
                  : 'Купить: $unboughtGroceryCount поз. • ~${totalGroceryCost.round()} ₽',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          if (_selectedTab == 0) ...[
            if (family != null)
              IconButton(
                icon: const Icon(Icons.sync_rounded, size: 22, color: AppColors.primary),
                tooltip: 'Синхронизировать с семьей',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(familyProvider.notifier).refreshFromCloud();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Холодильник и покупки синхронизированы с семьей!'),
                        backgroundColor: AppColors.primary,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            if (fridgeItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, size: 22, color: AppColors.textTertiary),
                tooltip: 'Очистить холодильник',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _confirmClearFridge();
                },
              ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 22),
              tooltip: 'Настройки питания и порций',
              onPressed: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const PreferencesModal(),
                );
              },
            ),
          ]
          else ...[
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
              tooltip: 'Добавить покупку',
              onPressed: _showAddGroceryDialog,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Secondary Manual Add (+)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddProductSheet(),
                    );
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Primary Accented Scanning Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiMagicScanScreen()),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: AppColors.primaryForeground,
                      size: 26,
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // ── Subtle Top Segmented Control (В наличии / Покупки) ───────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      index: 0,
                      label: 'В наличии',
                      count: fridgeItems.length,
                      icon: Icons.kitchen_rounded,
                      isSelected: _selectedTab == 0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 1,
                      label: 'Список покупок',
                      count: unboughtGroceryCount,
                      icon: Icons.shopping_bag_rounded,
                      isSelected: _selectedTab == 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Active View Body ─────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedTab == 0
                  ? _buildFridgeView(
                      fridgeItems: fridgeItems,
                      filteredItems: filteredFridgeItems,
                      urgentCount: urgentCount,
                      soonCount: soonCount,
                      goodCount: goodCount,
                    )
                  : _buildGroceryView(
                      groceryItems: groceryItems,
                      groupedGrocery: groupedGrocery,
                      checkedGrocery: checkedGrocery,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segment Button ────────────────────────────────────────────────────────
  Widget _buildSegmentButton({
    required int index,
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryForeground : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryForeground : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  1. FRIDGE VIEW (В наличии)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildFridgeView({
    required List<ProductItem> fridgeItems,
    required List<ProductItem> filteredItems,
    required int urgentCount,
    required int soonCount,
    required int goodCount,
  }) {
    return CustomScrollView(
      key: const ValueKey('fridge_view'),
      slivers: [
        // Filter Chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Все (${fridgeItems.length})',
                    isSelected: _selectedFilter == null,
                    onTap: () => setState(() => _selectedFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Срочно ($urgentCount)',
                    isSelected: _selectedFilter == FreshnessCategory.urgent,
                    onTap: () => setState(() => _selectedFilter = FreshnessCategory.urgent),
                    isUrgent: true,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '3-5 дней ($soonCount)',
                    isSelected: _selectedFilter == FreshnessCategory.soon,
                    onTap: () => setState(() => _selectedFilter = FreshnessCategory.soon),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Свежее ($goodCount)',
                    isSelected: _selectedFilter == FreshnessCategory.good,
                    onTap: () => setState(() => _selectedFilter = FreshnessCategory.good),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Search Box
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Поиск по продуктам...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Products List
        if (filteredItems.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.kitchen_outlined, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text('Холодильник пуст', style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text('Отсканируйте продукты или добавьте вручную', style: AppTypography.bodySmall),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredItems[index];
                  return _buildProductCard(context, item);
                },
                childCount: filteredItems.length,
              ),
            ),
          ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  2. GROCERY VIEW (Список покупок)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildGroceryView({
    required List<GroceryItem> groceryItems,
    required Map<String, List<GroceryItem>> groupedGrocery,
    required List<GroceryItem> checkedGrocery,
  }) {
    return CustomScrollView(
      key: const ValueKey('grocery_view'),
      slivers: [
        // Transfer to Fridge Banner (when items are checked)
        if (checkedGrocery.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                            'Куплено ${checkedGrocery.length} поз.',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                          ),
                          const Text(
                            'Перенести в запасы холодильника?',
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
                      onPressed: () => _transferPurchasedToFridge(checkedGrocery),
                      child: const Text('В холодильник', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (groceryItems.isEmpty)
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
                  Text('Нажмите кнопку синхронизации сверху для авто-генерации', style: AppTypography.bodySmall),
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
                  final department = groupedGrocery.keys.elementAt(index);
                  final items = groupedGrocery[department]!;

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
                            Text('${items.length} поз.', style: AppTypography.labelSmall),
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
                                        if (item.recipeOriginTitle != null)
                                          Text(
                                            'для: ${item.recipeOriginTitle}',
                                            style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                          ),
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
                childCount: groupedGrocery.keys.length,
              ),
            ),
          ),
      ],
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isUrgent = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryForeground
                : (isUrgent ? AppColors.statusUrgent : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductItem item) {
    final days = item.daysUntilExpiry;

    String daysText;
    if (days < 0) {
      daysText = 'Истек срок';
    } else if (days == 0) {
      daysText = 'Истекает сегодня';
    } else if (days == 1) {
      daysText = '1 день';
    } else {
      daysText = '$days дн.';
    }

    final isUrgent = days <= 2;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.statusUrgent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(fridgeProvider.notifier).removeProduct(item.id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} удален'),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Отменить',
              textColor: Colors.white,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(fridgeProvider.notifier).undoLastDeletedProduct();
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit} • ${item.category}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUrgent ? const Color(0xFFFDECEE) : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                daysText,
                style: AppTypography.labelSmall.copyWith(
                  color: isUrgent ? AppColors.statusUrgent : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.textTertiary),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(fridgeProvider.notifier).removeProduct(item.id);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} приготовлен / использован!'),
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    action: SnackBarAction(
                      label: 'Отменить',
                      textColor: Colors.white,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(fridgeProvider.notifier).undoLastDeletedProduct();
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
