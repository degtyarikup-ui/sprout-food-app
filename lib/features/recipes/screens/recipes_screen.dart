import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../fridge/providers/fridge_provider.dart';
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
    final isGenerating = ref.watch(isAiGeneratingRecipesProvider);

    final categories = ['Все', 'Завтрак', 'Обед', 'Ужин', 'Перекус'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Рецепты', style: AppTypography.displayMedium),
        actions: [
          // View Mode Switcher: [ 🎬 Reels | 📋 Сетка ]
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeBtn(
                  icon: Icons.movie_filter_outlined,
                  isSelected: viewMode == 0,
                  tooltip: 'Reels-лента',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(recipeViewModeProvider.notifier).state = 0;
                  },
                ),
                _buildModeBtn(
                  icon: Icons.grid_view_rounded,
                  isSelected: viewMode == 1,
                  tooltip: 'Сетка рецептов',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(recipeViewModeProvider.notifier).state = 1;
                  },
                ),
              ],
            ),
          ),

          // Import Link Button
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
          // Core Feed Filter Tabs: [ 🎬 Все | 🥑 Из холодильника (N) | ❤️ Моя подборка (N) ]
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFeedFilterPill(
                    label: '🎬 Все блюда',
                    isSelected: feedFilter == 0,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(recipeFeedFilterProvider.notifier).state = 0;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFeedFilterPill(
                    label: '🥑 Из холодильника ($fridgeCount)',
                    isSelected: feedFilter == 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(recipeFeedFilterProvider.notifier).state = 1;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFeedFilterPill(
                    label: '❤️ Моя подборка ($favCount)',
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

          // Main View: Reels (Vertical Full-Bleed Feed) OR Classic Grid List
          Expanded(
            child: viewMode == 0
                ? RecipeReelsView(recipes: scoredRecipes)
                : CustomScrollView(
                    slivers: [
                      // Category Selector Pills (only in grid mode)
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

                      // Search Box (in grid mode)
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

                      // Full-Bleed Food Photo Cards
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 3,
        onPressed: isGenerating ? null : () => _generateAiRecipes(context, ref),
        icon: isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(
          isGenerating ? 'Шеф-ИИ думает...' : '✨ Шеф-ИИ по остаткам',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static Future<void> _generateAiRecipes(BuildContext context, WidgetRef ref) async {
    final fridgeItems = ref.read(fridgeProvider);
    if (fridgeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'Сначала добавьте продукты в холодильник или отсканируйте их 📸',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
      return;
    }

    ref.read(isAiGeneratingRecipesProvider.notifier).state = true;
    HapticFeedback.mediumImpact();

    try {
      final aiRecipes = await GeminiAIService.generateRecipesFromFridge(fridgeItems);
      ref.read(recipesProvider.notifier).addRecipes(aiRecipes);
      ref.read(recipeFeedFilterProvider.notifier).state = 0; // Show all in feed

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryForeground, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Шеф-ИИ создал ${aiRecipes.length} авторских рецепта из ваших продуктов!',
                    style: const TextStyle(color: AppColors.primaryForeground, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusUrgent,
            content: Text('Ошибка генерации: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } finally {
      ref.read(isAiGeneratingRecipesProvider.notifier).state = false;
    }
  }

  Widget _buildModeBtn({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? AppColors.primaryForeground : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFeedFilterPill({
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.black : AppColors.textPrimary,
          ),
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
