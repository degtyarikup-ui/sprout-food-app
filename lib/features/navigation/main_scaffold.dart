import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../ai_scanner/screens/ai_magic_scan_screen.dart';
import '../analytics/screens/eco_analytics_screen.dart';
import '../fridge/screens/fridge_screen.dart';
import '../grocery/screens/grocery_screen.dart';
import '../meal_planner/screens/meal_planner_screen.dart';
import '../recipes/screens/recipes_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    final List<Widget> screens = const [
      MealPlannerScreen(),
      FridgeScreen(),
      RecipesScreen(),
      GroceryScreen(),
      EcoAnalyticsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 0,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'План',
                  isSelected: currentTab == 0,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 1,
                  icon: Icons.kitchen_outlined,
                  activeIcon: Icons.kitchen_rounded,
                  label: 'Продукты',
                  isSelected: currentTab == 1,
                ),
                // Center Camera Scanner Trigger
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiMagicScanScreen()),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 2,
                  icon: Icons.restaurant_menu_outlined,
                  activeIcon: Icons.restaurant_menu_rounded,
                  label: 'Рецепты',
                  isSelected: currentTab == 2,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 3,
                  icon: Icons.checklist_rounded,
                  activeIcon: Icons.checklist_rounded,
                  label: 'Покупки',
                  isSelected: currentTab == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textTertiary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(currentTabProvider.notifier).state = index;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
