import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/recipes_provider.dart';
import 'recipe_detail_screen.dart';
import 'recipe_reels_view.dart';
import 'social_importer_modal.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoredRecipes = ref.watch(scoredRecipesProvider);
    final selectedCategory = ref.watch(selectedRecipeCategoryProvider);
    final viewMode = ref.watch(recipeViewModeProvider);
    final feedFilter = ref.watch(recipeFeedFilterProvider);
    final fridgeCount = ref.watch(fridgeMatchCountProvider);
    final favCount = ref.watch(favoriteRecipesCountProvider);

    final topPadding = MediaQuery.of(context).padding.top;
    final categories = ['Все', 'Завтрак', 'Обед', 'Ужин', 'Перекус'];

    if (viewMode == 0) {
      // Full-Bleed Reels Mode (TikTok / Instagram style edge-to-edge)
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full-Bleed Reels Feed (Behind Status Bar and Bottom Nav)
              Positioned.fill(
                child: RecipeReelsView(recipes: scoredRecipes),
              ),

              // Floating Frosted Top Bar
              Positioned(
                top: topPadding + 6,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Title + Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Рецепты',
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // View Mode Toggle (Frosted Glass)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildModeIconBtn(
                                        icon: Icons.movie_filter_outlined,
                                        isSelected: true,
                                        onTap: () {},
                                      ),
                                      _buildModeIconBtn(
                                        icon: Icons.grid_view_rounded,
                                        isSelected: false,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          ref.read(recipeViewModeProvider.notifier).state = 1;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Import Link Button (Frosted Glass)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const SocialImporterModal(),
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.link_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Filter Pills: [ Все блюда | В наличии (N) | Избранное (N) ]
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFrostedFilterPill(
                            label: 'Все блюда',
                            isSelected: feedFilter == 0,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(recipeFeedFilterProvider.notifier).state = 0;
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFrostedFilterPill(
                            icon: Icons.kitchen_outlined,
                            label: 'В наличии ($fridgeCount)',
                            isSelected: feedFilter == 1,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(recipeFeedFilterProvider.notifier).state = 1;
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFrostedFilterPill(
                            icon: Icons.favorite_border_rounded,
                            label: 'Избранное ($favCount)',
                            isSelected: feedFilter == 2,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(recipeFeedFilterProvider.notifier).state = 2;
                            },
                          ),
                        ],
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

    // Classic Grid / List View Mode
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Рецепты', style: AppTypography.displayMedium),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeIconBtn(
                  icon: Icons.movie_filter_outlined,
                  isSelected: false,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(recipeViewModeProvider.notifier).state = 0;
                  },
                ),
                _buildModeIconBtn(
                  icon: Icons.grid_view_rounded,
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded, size: 22),
            tooltip: 'Импорт из видео',
            onPressed: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const SocialImporterModal(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs in Grid Mode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLightFilterPill(
                    label: 'Все блюда',
                    isSelected: feedFilter == 0,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(recipeFeedFilterProvider.notifier).state = 0;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildLightFilterPill(
                    icon: Icons.kitchen_outlined,
                    label: 'В наличии ($fridgeCount)',
                    isSelected: feedFilter == 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(recipeFeedFilterProvider.notifier).state = 1;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildLightFilterPill(
                    icon: Icons.favorite_border_rounded,
                    label: 'Избранное ($favCount)',
                    isSelected: feedFilter == 2,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(recipeFeedFilterProvider.notifier).state = 2;
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: CustomScrollView(
              slivers: [
                // Category Pills
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(selectedRecipeCategoryProvider.notifier).state = cat;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryForeground : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Search Box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                      decoration: const InputDecoration(
                        hintText: 'Поиск блюд и ингредиентов...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),

                // Full-Bleed Food Cards
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = scoredRecipes[index];
                        return _buildSeamlessRecipeCard(context, item, ref);
                      },
                      childCount: scoredRecipes.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIconBtn({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppColors.primaryForeground : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildFrostedFilterPill({
    IconData? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLightFilterPill({
    IconData? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : AppColors.textPrimary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.black : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeamlessRecipeCard(BuildContext context, RecipeWithMatchScore item, WidgetRef ref) {
    final recipe = item.recipe;
    final matchPercent = item.matchPercentage.round();

    String matchText;
    if (matchPercent == 100) {
      matchText = 'Все ингредиенты есть';
    } else if (matchPercent >= 60) {
      matchText = 'Есть ${item.availableIngredients} из ${item.totalIngredients}';
    } else {
      matchText = 'Не хватает ${item.missingIngredients.length} продуктов';
    }

    return Container(
      height: 260,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
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
                : Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceMuted,
                      child: const Center(
                        child: Icon(Icons.restaurant_outlined, size: 36, color: AppColors.textTertiary),
                      ),
                    ),
                  ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.18, 0.58, 0.80, 1.0],
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
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
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
                          '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(recipesProvider.notifier).toggleFavorite(recipe.id);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: recipe.isFavorite ? AppColors.statusUrgent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.title,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: 21,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: matchPercent == 100
                              ? Colors.white.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          matchText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
