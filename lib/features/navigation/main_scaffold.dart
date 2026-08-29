import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../ai_scanner/screens/ai_magic_scan_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = const [
      MealPlannerScreen(),
      FridgeScreen(),
      RecipesScreen(),
      GroceryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 62,
        width: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.secondary, Color(0xFFF39C12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiMagicScanScreen()),
              );
            },
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 0,
                  icon: Icons.calendar_today_rounded,
                  label: 'План',
                  isSelected: currentTab == 0,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 1,
                  icon: Icons.kitchen_rounded,
                  label: 'Холодильник',
                  isSelected: currentTab == 1,
                ),
                const SizedBox(width: 48), // Space for centered FAB
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 2,
                  icon: Icons.menu_book_rounded,
                  label: 'Рецепты',
                  isSelected: currentTab == 2,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  index: 3,
                  icon: Icons.shopping_basket_rounded,
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
    required String label,
    required bool isSelected,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(currentTabProvider.notifier).state = index;
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
