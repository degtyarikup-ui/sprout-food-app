import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../fridge/screens/fridge_screen.dart';
import '../grocery/screens/grocery_screen.dart';
import '../meal_planner/screens/meal_planner_screen.dart';
import '../recipes/screens/recipes_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 1); // Default to Лента or 0

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final isDarkScreen = currentTab == 1; // Tab 1 = Лента (Recipes)

    // 4 items: План, Лента, Продукты, Покупки
    final List<Widget> screens = const [
      MealPlannerScreen(), // 0: План
      RecipesScreen(),     // 1: Лента
      FridgeScreen(),      // 2: Продукты
      GroceryScreen(),     // 3: Покупки
    ];

    return Scaffold(
      backgroundColor: isDarkScreen ? Colors.black : AppColors.background,
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDarkScreen ? Colors.black : AppColors.surface,
          // Zero borders as per design system rule: strictly background colors only
        ),
        child: SafeArea(
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  ref: ref,
                  index: 0,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'План',
                  isSelected: currentTab == 0,
                  isDarkScreen: isDarkScreen,
                ),
                _buildNavItem(
                  ref: ref,
                  index: 1,
                  icon: Icons.movie_filter_outlined,
                  activeIcon: Icons.movie_filter_rounded,
                  label: 'Лента',
                  isSelected: currentTab == 1,
                  isDarkScreen: isDarkScreen,
                ),
                _buildNavItem(
                  ref: ref,
                  index: 2,
                  icon: Icons.kitchen_outlined,
                  activeIcon: Icons.kitchen_rounded,
                  label: 'Продукты',
                  isSelected: currentTab == 2,
                  isDarkScreen: isDarkScreen,
                ),
                _buildNavItem(
                  ref: ref,
                  index: 3,
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Покупки',
                  isSelected: currentTab == 3,
                  isDarkScreen: isDarkScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required bool isDarkScreen,
  }) {
    final Color activeColor = isDarkScreen
        ? Colors.white
        : AppColors.primary;

    final Color inactiveColor = isDarkScreen
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.textTertiary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(currentTabProvider.notifier).state = index;
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
