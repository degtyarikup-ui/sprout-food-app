import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
  FreshnessCategory? _selectedFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final fridgeItems = ref.watch(fridgeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter items
    final filteredItems = fridgeItems.where((item) {
      if (_selectedFilter != null && item.freshness != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    // Sort: Urgent items first
    filteredItems.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    final urgentCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.urgent).length;
    final soonCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.soon).length;
    final goodCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.good).length;
    final pantryCount = fridgeItems.where((i) => i.freshness == FreshnessCategory.pantry).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Мой Холодильник', style: AppTypography.displayMedium),
            Text(
              '${fridgeItems.length} продуктов в наличии',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddProductSheet(),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Freshness Radar Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Радар свежести', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildRadarCard(
                        context: context,
                        label: 'Срочно',
                        count: urgentCount,
                        category: FreshnessCategory.urgent,
                        icon: '🔥',
                        color: AppColors.urgentExpiring,
                        bgColor: const Color(0xFFFDECEE),
                      ),
                      const SizedBox(width: 8),
                      _buildRadarCard(
                        context: context,
                        label: '3-5 дней',
                        count: soonCount,
                        category: FreshnessCategory.soon,
                        icon: '⏳',
                        color: AppColors.soonExpiring,
                        bgColor: const Color(0xFFFEF5E7),
                      ),
                      const SizedBox(width: 8),
                      _buildRadarCard(
                        context: context,
                        label: 'Свежее',
                        count: goodCount,
                        category: FreshnessCategory.good,
                        icon: '🌱',
                        color: AppColors.freshGood,
                        bgColor: const Color(0xFFEAF8EF),
                      ),
                      const SizedBox(width: 8),
                      _buildRadarCard(
                        context: context,
                        label: 'Запас',
                        count: pantryCount,
                        category: FreshnessCategory.pantry,
                        icon: '❄️',
                        color: AppColors.frozenPantry,
                        bgColor: const Color(0xFFEBF5FB),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Box
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Поиск по холодильнику...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiaryLight),
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

          // Product List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilter == null ? 'Все продукты' : _selectedFilter!.label,
                    style: AppTypography.titleSmall,
                  ),
                  if (_selectedFilter != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = null),
                      child: Text(
                        'Сбросить фильтр',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Products List
          filteredItems.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🥑', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Холодильник пуст', style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text('Отсканируйте чек или добавьте вручную', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
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
      ),
    );
  }

  Widget _buildRadarCard({
    required BuildContext context,
    required String label,
    required int count,
    required FreshnessCategory category,
    required String icon,
    required Color color,
    required Color bgColor,
  }) {
    final isSelected = _selectedFilter == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = isSelected ? null : category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevatedDark : (isSelected ? bgColor : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: AppTypography.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = item.daysUntilExpiry;

    String daysText;
    if (days < 0) {
      daysText = 'Истек срок';
    } else if (days == 0) {
      daysText = 'Истекает сегодня';
    } else if (days == 1) {
      daysText = 'Остался 1 день';
    } else if (days < 5) {
      daysText = 'Осталось $days дня';
    } else {
      daysText = 'Осталось $days дней';
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.urgentExpiring,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(fridgeProvider.notifier).removeProduct(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} удален из холодильника'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.freshness == FreshnessCategory.urgent
                ? AppColors.urgentExpiring.withOpacity(0.4)
                : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji Icon Box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.freshness.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),

            // Name, Category, Days left
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.titleSmall),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unit} • ${item.category}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Expiry badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.freshness.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysText,
                      style: AppTypography.labelSmall.copyWith(
                        color: item.freshness.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Mark as Used / Cooked
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Использовано в готовке',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(fridgeProvider.notifier).removeProduct(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✨ ${item.name} использован! Продукт спасен.'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
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
