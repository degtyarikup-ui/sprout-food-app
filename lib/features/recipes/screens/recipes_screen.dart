import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/recipes_provider.dart';
import 'recipe_detail_screen.dart';
import 'social_importer_modal.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoredRecipes = ref.watch(scoredRecipesProvider);
    final selectedCategory = ref.watch(selectedRecipeCategoryProvider);

    final categories = ['Все', 'Завтрак', 'Обед', 'Ужин', 'Перекус'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Рецепты', style: AppTypography.displayMedium),
        actions: [
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
      body: CustomScrollView(
        slivers: [
          // Category Pills Selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
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

          // Recipe Cards List (Food-First Editorial)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = scoredRecipes[index];
                  return _buildRecipeCard(context, item, ref);
                },
                childCount: scoredRecipes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeWithMatchScore item, WidgetRef ref) {
    final recipe = item.recipe;
    final matchPercent = item.matchPercentage.round();

    String matchText;
    if (matchPercent == 100) {
      matchText = 'Все ингредиенты в наличии';
    } else if (matchPercent >= 60) {
      matchText = 'Есть ${item.availableIngredients} из ${item.totalIngredients} продуктов';
    } else {
      matchText = 'Не хватает ${item.missingIngredients.length} продуктов';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with Badges
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: recipe.imageUrl.startsWith('assets/')
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
                ),
                // Time & Calories Capsule on Image
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${recipe.totalTimeMinutes} мин • ${recipe.calories} ккал',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Favorite Circle
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(recipesProvider.notifier).toggleFavorite(recipe.id);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
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
              ],
            ),

            // Card Text Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: matchPercent == 100 ? const Color(0xFFEAF8EF) : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      matchText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: matchPercent == 100 ? AppColors.statusFresh : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(recipe.title, style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
