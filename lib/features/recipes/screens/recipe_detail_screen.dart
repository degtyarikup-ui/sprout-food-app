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
import '../models/recipe.dart';
import '../providers/recipes_provider.dart';
import 'short_cooking_reel_modal.dart';
import 'smart_cooking_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late Recipe _currentRecipe;
  late int _servings;
  bool _showFullIngredients = false;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _servings = widget.recipe.defaultServings;
  }

  void _showAiTransformerModal() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🪄 ', style: TextStyle(fontSize: 24)),
                Text('AI Recipe Transformer', style: AppTypography.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Укажите, как адаптировать блюдо (например: «заменить сливки на кокосовые», «сделать кето», «без лактозы»)',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ваши пожелания к рецепту...',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);

                  final transformed = await GeminiAIService.transformRecipe(
                    originalRecipe: _currentRecipe,
                    modificationGoal: text,
                  );
                  ref.read(recipesProvider.notifier).addRecipe(transformed);
                  setState(() {
                    _currentRecipe = transformed;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✨ Рецепт адаптирован под ваши остатки!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                child: const Text('Адаптировать с Gemini AI ✨'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMissingToGrocery() {
    final fridge = ref.read(fridgeProvider);
    final fridgeNames = fridge.map((p) => p.name.toLowerCase()).toList();

    int addedCount = 0;
    for (final ing in _currentRecipe.ingredients) {
      final ingName = ing.name.toLowerCase();
      final hasInFridge = fridgeNames.any((f) {
        final words = ingName.split(' ');
        return words.any((w) => w.length > 3 && f.contains(w));
      });

      if (!hasInFridge && !ing.isOptional) {
        ref.read(groceryProvider.notifier).addItem(
              GroceryItem(
                name: ing.name,
                amount: ing.amount * (_servings / _currentRecipe.defaultServings),
                unit: ing.unit,
                department: 'Продукты',
                recipeOriginTitle: _currentRecipe.title,
                estimatedCost: 150,
              ),
            );
        addedCount++;
      }
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(addedCount > 0
            ? 'Добавлено $addedCount ингредиентов в список покупок'
            : 'Все ингредиенты есть в вашем холодильнике! 🎉'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fridge = ref.watch(fridgeProvider);
    final fridgeNames = fridge.map((p) => p.name.toLowerCase()).toList();
    final servingMultiplier = _servings / _currentRecipe.defaultServings;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen Hero Food Photography Background
          Positioned.fill(
            child: _currentRecipe.imageUrl.startsWith('assets/')
                ? Image.asset(_currentRecipe.imageUrl, fit: BoxFit.cover)
                : Image.network(_currentRecipe.imageUrl, fit: BoxFit.cover),
          ),

          // Vignette & Subtle Atmospheric Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Main Interactive Content Overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top App Bar Icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFrostedIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildFrostedIconButton(
                        icon: _currentRecipe.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _currentRecipe.isFavorite ? AppColors.urgentExpiring : Colors.white,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(recipesProvider.notifier).toggleFavorite(_currentRecipe.id);
                          setState(() {
                            _currentRecipe = _currentRecipe.copyWith(
                              isFavorite: !_currentRecipe.isFavorite,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Title & Minimal Macro Header (Exact Reference 4 style!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        _currentRecipe.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Minimal Macros Line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMinimalMacroStat('${(_currentRecipe.calories * servingMultiplier).round()} ккал', 'энергия'),
                          _buildMacroSeparator(),
                          _buildMinimalMacroStat('${(_currentRecipe.proteinGrams * servingMultiplier).toStringAsFixed(1)} г', 'белки'),
                          _buildMacroSeparator(),
                          _buildMinimalMacroStat('${(_currentRecipe.fatGrams * servingMultiplier).toStringAsFixed(1)} г', 'жиры'),
                          _buildMacroSeparator(),
                          _buildMinimalMacroStat('${(_currentRecipe.carbsGrams * servingMultiplier).toStringAsFixed(1)} г', 'углеводы'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Translucent "Состав ∨" Capsule Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showFullIngredients = !_showFullIngredients);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _showFullIngredients ? 'Скрыть состав' : 'Состав',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _showFullIngredients
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Collapsible Full Ingredients Glass Panel
                if (_showFullIngredients) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ингредиенты (${_currentRecipe.ingredients.length})',
                              style: AppTypography.labelMedium.copyWith(color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: _addMissingToGrocery,
                              child: Text(
                                '+ В список покупок',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 12),
                        Expanded(
                          child: ListView(
                            children: _currentRecipe.ingredients.map((ing) {
                              final ingName = ing.name.toLowerCase();
                              final isAvailable = fridgeNames.any((f) {
                                final words = ingName.split(' ');
                                return words.any((w) => w.length > 3 && f.contains(w));
                              });
                              final scaled = ing.amount * servingMultiplier;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Icon(
                                      isAvailable ? Icons.check_circle_rounded : Icons.circle_outlined,
                                      color: isAvailable ? AppColors.freshGood : Colors.white38,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ing.name,
                                        style: TextStyle(
                                          color: isAvailable ? Colors.white : Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${scaled.toStringAsFixed(scaled % 1 == 0 ? 0 : 1)} ${ing.unit}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Watch Short Cooking Reel Button (Center trigger)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShortCookingReelModal(recipe: _currentRecipe),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Смотреть ролик готовки • 15 сек',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom Frosted Bento Modifiers Row (Reference 4 style!)
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFrostedModifierCard(
                        title: 'AI Адаптация',
                        subtitle: 'Под остатки',
                        icon: Icons.auto_awesome_rounded,
                        onTap: _showAiTransformerModal,
                      ),
                      _buildFrostedModifierCard(
                        title: 'Для семьи',
                        subtitle: _currentRecipe.familySplitTip != null ? 'Split Mode' : 'Без специй',
                        icon: Icons.family_restroom_rounded,
                        onTap: () {
                          if (_currentRecipe.familySplitTip != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('👶 ${_currentRecipe.familySplitTip!}')),
                            );
                          }
                        },
                      ),
                      _buildFrostedModifierCard(
                        title: 'Zero-Waste',
                        subtitle: 'Спасаем еду',
                        icon: Icons.eco_rounded,
                        onTap: () {
                          if (_currentRecipe.zeroWasteTip != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🌱 ${_currentRecipe.zeroWasteTip!}')),
                            );
                          }
                        },
                      ),
                      _buildFrostedModifierCard(
                        title: 'Порции',
                        subtitle: '$_servings порц.',
                        icon: Icons.people_outline_rounded,
                        onTap: () {
                          setState(() {
                            _servings = _servings == 1 ? 2 : (_servings == 2 ? 4 : 1);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom Floating Action Capsule Bar (Reference 4 style: volume/time on left, action on right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Servings / Time Pill
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_currentRecipe.totalTimeMinutes} мин',
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Start Hands-Free Cooking Capsule Button
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SmartCookingScreen(recipe: _currentRecipe),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.restaurant_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Начать готовку 👨‍🍳',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 20),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalMacroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
    );
  }

  Widget _buildFrostedModifierCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 96,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
