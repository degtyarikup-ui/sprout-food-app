import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../grocery/models/grocery_item.dart';
import '../../grocery/providers/grocery_provider.dart';
import '../../premium/widgets/premium_gate.dart';
import '../models/recipe.dart';
import '../providers/recipes_provider.dart';
import 'recipe_detail_screen.dart';

class RecipeReelsView extends ConsumerStatefulWidget {
  final List<RecipeWithMatchScore> recipes;

  const RecipeReelsView({super.key, required this.recipes});

  @override
  ConsumerState<RecipeReelsView> createState() => _RecipeReelsViewState();
}

class _RecipeReelsViewState extends ConsumerState<RecipeReelsView> {
  final PageController _pageController = PageController();
  final Map<int, bool> _showHeartAnimation = {};

  void _triggerDoubleTapLike(int index, Recipe recipe) {
    HapticFeedback.mediumImpact();
    if (!recipe.isFavorite) {
      ref.read(recipesProvider.notifier).toggleFavorite(recipe.id);
    }
    setState(() {
      _showHeartAnimation[index] = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation[index] = false;
        });
      }
    });
  }

  void _addMissingToCart(List<String> missing, BuildContext context) {
    if (missing.isEmpty) return;
    HapticFeedback.lightImpact();
    for (final item in missing) {
      ref.read(groceryProvider.notifier).addItem(
            GroceryItem(
              name: item,
              amount: 1,
              unit: 'уп',
              department: 'Бакалея',
            ),
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Добавлено в список покупок: ${missing.length} поз.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generateAiRecipes() async {
    final hasPremium = await PremiumGate.check(
      context,
      ref,
      featureName: 'Генерация рецептов Шеф-ИИ',
    );
    if (!hasPremium) return;
    if (!mounted) return;

    final fridgeItems = ref.read(fridgeProvider);
    if (fridgeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'Сначала добавьте продукты в холодильник или отсканируйте их',
            style: TextStyle(color: Colors.white),
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

      if (mounted) {
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
                    'Шеф-ИИ придумал ${aiRecipes.length} новых блюда из ваших продуктов',
                    style: const TextStyle(color: AppColors.primaryForeground, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      if (mounted) {
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

  void _openRecipeDetail(Recipe recipe) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGenerating = ref.watch(isAiGeneratingRecipesProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (widget.recipes.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_rounded, size: 44, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'В этой подборке пока пусто',
                  style: AppTypography.titleLarge.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Лайкайте блюда в ленте или попросите Шеф-ИИ придумать рецепт из продуктов холодильника',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: isGenerating ? null : _generateAiRecipes,
                      icon: isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        isGenerating ? 'Шеф-ИИ думает...' : 'Придумать блюдо из продуктов',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.recipes.length,
            itemBuilder: (context, index) {
              final scored = widget.recipes[index];
              final recipe = scored.recipe;
              final isHeartVisible = _showHeartAnimation[index] ?? false;

              return GestureDetector(
                onDoubleTap: () => _triggerDoubleTapLike(index, recipe),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Full Bleed Edge-to-Edge Image
                    _buildRecipeImage(recipe.imageUrl),

                    // Cinematic Dark Vignette & Gradient Overlays (Full Bleed TikTok style)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.92),
                            ],
                            stops: const [0.0, 0.15, 0.45, 0.70, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Animated Double-Tap Heart Burst
                    if (isHeartVisible)
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.elasticOut,
                          builder: (context, val, child) {
                            return Transform.scale(
                              scale: val,
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.redAccent,
                                size: 110,
                              ),
                            );
                          },
                        ),
                      ),

                    // Bottom Recipe Info Area (Fully Tappable to open Recipe Details)
                    Positioned(
                      left: 16,
                      right: 76,
                      bottom: bottomPadding + 14,
                      child: GestureDetector(
                        onTap: () => _openRecipeDetail(recipe),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Fridge Match Badge (No Emojis)
                            _buildMatchBadge(scored),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Description (Tappable with subtle expand indicator)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Metrics Pill Row without Emojis (Time, Calories, Protein, Fats)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildMetricChip(
                                    icon: Icons.access_time_rounded,
                                    label: '${recipe.totalTimeMinutes} мин',
                                  ),
                                  const SizedBox(width: 6),
                                  _buildMetricChip(
                                    icon: Icons.local_fire_department_outlined,
                                    label: '${recipe.calories} ккал',
                                  ),
                                  const SizedBox(width: 6),
                                  _buildMetricChip(
                                    icon: Icons.fitness_center_rounded,
                                    label: '${recipe.proteinGrams}г белка',
                                  ),
                                  if (recipe.fatGrams > 0) ...[
                                    const SizedBox(width: 6),
                                    _buildMetricChip(
                                      label: '${recipe.fatGrams}г жиров',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Side Action Column (Clean Frosted Circles, No text clutter)
                    Positioned(
                      right: 14,
                      bottom: bottomPadding + 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Like Button
                          _buildFrostedCircleButton(
                            icon: recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            iconColor: recipe.isFavorite ? Colors.redAccent : Colors.white,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(recipesProvider.notifier).toggleFavorite(recipe.id);
                            },
                          ),
                          const SizedBox(height: 14),

                          // 2. Add Missing to Grocery List
                          if (scored.missingIngredients.isNotEmpty) ...[
                            _buildFrostedCircleButton(
                              icon: Icons.shopping_bag_outlined,
                              iconColor: Colors.white,
                              badgeCount: scored.missingIngredients.length,
                              onTap: () => _addMissingToCart(scored.missingIngredients, context),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 3. AI Chef Trigger
                          _buildFrostedCircleButton(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: Colors.amberAccent,
                            onTap: _generateAiRecipes,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // AI Loading Overlay with Frosted Glass
          if (isGenerating)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 20),
                            Text(
                              'Шеф-ИИ изучает продукты...',
                              style: AppTypography.titleMedium.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Придумываем авторские рецепты под ваш холодильник',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: Colors.black),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF141517),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(color: const Color(0xFF141517)),
    );
  }

  Widget _buildMatchBadge(RecipeWithMatchScore scored) {
    final isFull = scored.matchPercentage >= 99;
    final hasSome = scored.availableIngredients > 0;

    // Subtle frosted background without bright saturated accent
    final Color badgeBg = isFull
        ? Colors.white.withValues(alpha: 0.18)
        : hasSome
            ? Colors.black.withValues(alpha: 0.38)
            : Colors.black.withValues(alpha: 0.28);

    final IconData icon = isFull
        ? Icons.check_circle_outline_rounded
        : hasSome
            ? Icons.kitchen_outlined
            : Icons.restaurant_outlined;

    final String text = isFull
        ? 'В наличии 100%'
        : hasSome
            ? 'В наличии ${scored.availableIngredients} из ${scored.totalIngredients}'
            : 'Шеф-рецепт';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
            // Zero borders as per design system rule
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({IconData? icon, required String label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(10),
            // Zero borders
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                  // Zero borders as per design system rule
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: AppColors.primaryForeground,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
