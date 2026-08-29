import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../data/curated_recipes.dart';
import '../models/recipe.dart';

class RecipesNotifier extends StateNotifier<List<Recipe>> {
  RecipesNotifier() : super(kCuratedRecipes);

  void addRecipe(Recipe recipe) {
    state = [recipe, ...state];
  }

  void addRecipes(List<Recipe> recipes) {
    state = [...recipes, ...state];
  }

  void toggleFavorite(String recipeId) {
    state = state.map((r) {
      if (r.id == recipeId) {
        return r.copyWith(isFavorite: !r.isFavorite);
      }
      return r;
    }).toList();
  }
}

final recipesProvider = StateNotifierProvider<RecipesNotifier, List<Recipe>>((ref) {
  return RecipesNotifier();
});

/// 0 = Все (Лента), 1 = Из холодильника, 2 = Моя подборка (❤️)
final recipeFeedFilterProvider = StateProvider<int>((ref) => 0);

/// 0 = Reels (Лента), 1 = Сетка / Список
final recipeViewModeProvider = StateProvider<int>((ref) => 0);

final selectedRecipeCategoryProvider = StateProvider<String>((ref) => 'Все');
final searchQueryProvider = StateProvider<String>((ref) => '');
final isAiGeneratingRecipesProvider = StateProvider<bool>((ref) => false);

/// Model representing a recipe scored with fridge availability
class RecipeWithMatchScore {
  final Recipe recipe;
  final int totalIngredients;
  final int availableIngredients;
  final double matchPercentage;
  final List<String> missingIngredients;

  RecipeWithMatchScore({
    required this.recipe,
    required this.totalIngredients,
    required this.availableIngredients,
    required this.matchPercentage,
    required this.missingIngredients,
  });
}

/// Computes recipe match score against items in the user's fridge
final scoredRecipesProvider = Provider<List<RecipeWithMatchScore>>((ref) {
  final recipes = ref.watch(recipesProvider);
  final fridge = ref.watch(fridgeProvider);
  final selectedCategory = ref.watch(selectedRecipeCategoryProvider);
  final feedFilter = ref.watch(recipeFeedFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  final fridgeNames = fridge.map((p) => p.name.toLowerCase()).toList();

  final List<RecipeWithMatchScore> scored = [];

  for (final recipe in recipes) {
    // Filter by Favorite if feedFilter == 2
    if (feedFilter == 2 && !recipe.isFavorite) {
      continue;
    }

    // Filter by category
    if (selectedCategory != 'Все' && recipe.category != selectedCategory) {
      continue;
    }

    // Filter by search query
    if (query.isNotEmpty) {
      final inTitle = recipe.title.toLowerCase().contains(query);
      final inTags = recipe.tags.any((t) => t.toLowerCase().contains(query));
      final inDesc = recipe.description.toLowerCase().contains(query);
      if (!inTitle && !inTags && !inDesc) continue;
    }

    int availableCount = 0;
    final List<String> missing = [];

    for (final ing in recipe.ingredients) {
      final ingName = ing.name.toLowerCase();
      // Check if any fridge item matches ingredient name
      final isAvailable = fridgeNames.any((f) {
        final words = ingName.split(' ');
        return words.any((w) => w.length >= 3 && f.contains(w)) || f.contains(ingName);
      });

      if (isAvailable || ing.isOptional) {
        availableCount++;
      } else {
        missing.add(ing.name);
      }
    }

    final total = recipe.ingredients.length;
    final percentage = total > 0 ? (availableCount / total) * 100 : 100.0;

    // Filter by Fridge match if feedFilter == 1 (only recipes with >= 30% or available ingredients)
    if (feedFilter == 1 && availableCount == 0 && fridge.isNotEmpty) {
      continue;
    }

    scored.add(
      RecipeWithMatchScore(
        recipe: recipe,
        totalIngredients: total,
        availableIngredients: availableCount,
        matchPercentage: percentage,
        missingIngredients: missing,
      ),
    );
  }

  // If viewing "Из холодильника", sort by highest match percentage
  if (feedFilter == 1) {
    scored.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
  }

  return scored;
});

/// Count of available fridge matched recipes
final fridgeMatchCountProvider = Provider<int>((ref) {
  final recipes = ref.watch(recipesProvider);
  final fridge = ref.watch(fridgeProvider);
  if (fridge.isEmpty) return 0;
  final fridgeNames = fridge.map((p) => p.name.toLowerCase()).toList();

  int count = 0;
  for (final recipe in recipes) {
    final hasMatch = recipe.ingredients.any((ing) {
      final ingName = ing.name.toLowerCase();
      return fridgeNames.any((f) {
        final words = ingName.split(' ');
        return words.any((w) => w.length >= 3 && f.contains(w)) || f.contains(ingName);
      });
    });
    if (hasMatch) count++;
  }
  return count;
});

/// Count of favorite liked recipes
final favoriteRecipesCountProvider = Provider<int>((ref) {
  final recipes = ref.watch(recipesProvider);
  return recipes.where((r) => r.isFavorite).length;
});
