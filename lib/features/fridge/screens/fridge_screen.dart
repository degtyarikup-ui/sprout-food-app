import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../ai_scanner/screens/ai_magic_scan_screen.dart';
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
  FreshnessCategory? _selectedFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final fridgeItems = ref.watch(fridgeProvider);

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Холодильник', style: AppTypography.displayMedium),
            Text(
              '${fridgeItems.length} позиций в наличии',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
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
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Secondary Non-Accented Manual Add Button (+)
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

          // Primary Accented Scanning Button (Icon only)
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
      ),
      body: CustomScrollView(
        slivers: [
          // Filter Chips (Clean monochromatic pills with zero borders)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          filteredItems.isEmpty
              ? SliverFillRemaining(
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
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
          // Zero borders as per design system rule
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
          // Zero borders as per design system rule
        ),
        child: Row(
          children: [
            // Emoji Food Icon
            Text(item.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),

            // Name, Amount, Category
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

            // Expiry pill
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

            // Quick Done / Consume action with 5-second undo
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
