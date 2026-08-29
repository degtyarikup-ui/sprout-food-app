import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../data/curated_recipes.dart';
import '../models/recipe.dart';

class RecipesNotifier extends StateNotifier<List<Recipe>> {
  RecipesNotifier() : super(kCuratedRecipes);

  void addRecipe(Recipe recipe) {
    state = [recipe, ...state];
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

final selectedRecipeCategoryProvider = StateProvider<String>((ref) => 'Все');
final searchQueryProvider = StateProvider<String>((ref) => '');

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
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  final fridgeNames = fridge.map((p) => p.name.toLowerCase()).toList();

  final List<RecipeWithMatchScore> scored = [];

  for (final recipe in recipes) {
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
      // Check if any fridge item contains or matches ingredient name keywords
      final isAvailable = fridgeNames.any((f) {
        final words = ingName.split(' ');
        return words.any((w) => w.length > 3 && f.contains(w));
      });

      if (isAvailable || ing.isOptional) {
        availableCount++;
      } else {
        missing.add(ing.name);
      }
    }

    final total = recipe.ingredients.length;
    final percentage = total > 0 ? (availableCount / total) * 100 : 100.0;

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

  // Sort by highest ingredient match percentage first
  scored.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
  return scored;
});
