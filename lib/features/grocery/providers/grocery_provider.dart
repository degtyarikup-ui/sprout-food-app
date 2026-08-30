import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../meal_planner/providers/meal_planner_provider.dart';
import '../models/grocery_item.dart';

class GroceryNotifier extends StateNotifier<List<GroceryItem>> {
  final Ref _ref;

  GroceryNotifier(this._ref) : super([]) {
    _initList();
  }

  Future<void> _initList() async {
    final saved = await LocalStorageService.loadGroceryItems();
    if (saved != null) {
      state = saved;
    } else {
      state = [];
      await _persist();
    }
  }

  void toggleItem(String id) {
    state = state.map((item) {
      if (item.id == id) {
        final updated = item.copyWith(isChecked: !item.isChecked);
        
        // If checked, automatically offer/add to fridge with estimated shelf life
        if (updated.isChecked) {
          final now = DateTime.now();
          _ref.read(fridgeProvider.notifier).addProduct(
                ProductItem(
                  name: item.name,
                  amount: item.amount,
                  unit: item.unit,
                  category: item.department,
                  addedDate: now,
                  expiryDate: now.add(const Duration(days: 5)),
                  emoji: item.emoji,
                  estimatedPrice: item.estimatedCost,
                ),
              );
        }
        return updated;
      }
      return item;
    }).toList();
    _persist();
  }

  void addItem(GroceryItem item) {
    state = [item, ...state];
    _persist();
  }

  GroceryItem? _lastDeletedItem;
  int? _lastDeletedIndex;

  GroceryItem? get lastDeletedItem => _lastDeletedItem;

  void removeItem(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index != -1) {
      _lastDeletedItem = state[index];
      _lastDeletedIndex = index;
    }
    state = state.where((item) => item.id != id).toList();
    _persist();
  }

  void undoLastDeletedItem() {
    if (_lastDeletedItem == null) return;
    final item = _lastDeletedItem!;
    final index = (_lastDeletedIndex != null && _lastDeletedIndex! <= state.length)
        ? _lastDeletedIndex!
        : 0;
    final updated = List<GroceryItem>.from(state);
    updated.insert(index, item);
    state = updated;
    _lastDeletedItem = null;
    _lastDeletedIndex = null;
    _persist();
  }

  void clearChecked() {
    state = state.where((item) => !item.isChecked).toList();
    _persist();
  }

  /// Regenerates shopping list based on the whole week meal plan vs current fridge inventory
  void syncFromMealPlan() {
    final mealPlan = _ref.read(mealPlannerProvider);
    final fridge = _ref.read(fridgeProvider);
    final fridgeNames = fridge.map((p) => p.name.toLowerCase()).toList();

    final List<GroceryItem> newItems = [];

    for (final day in mealPlan) {
      for (final slot in day.slots) {
        if (slot.recipe == null) continue;
        for (final ing in slot.recipe!.ingredients) {
          final ingName = ing.name.toLowerCase();
          final isPresent = fridgeNames.any((f) {
            final words = ingName.split(' ');
            return words.any((w) => w.length > 3 && f.contains(w));
          });

          if (!isPresent && !ing.isOptional) {
            // Check if already in list
            final alreadyInList = state.any((g) => g.name.toLowerCase() == ingName);
            if (!alreadyInList) {
              newItems.add(
                GroceryItem(
                  name: ing.name,
                  amount: ing.amount,
                  unit: ing.unit,
                  department: _mapToDepartment(ing.name),
                  recipeOriginTitle: slot.recipe!.title,
                  estimatedCost: 150,
                  emoji: _pickEmoji(ing.name),
                ),
              );
            }
          }
        }
      }
    }

    if (newItems.isNotEmpty) {
      state = [...newItems, ...state];
      _persist();
    }
  }

  String _mapToDepartment(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('филе') || lower.contains('лосось') || lower.contains('куриц') || lower.contains('мясо')) {
      return 'Мясо и рыба';
    }
    if (lower.contains('молок') || lower.contains('сливк') || lower.contains('сыр') || lower.contains('яйц') || lower.contains('йогурт')) {
      return 'Молочные продукты';
    }
    if (lower.contains('томат') || lower.contains('перец') || lower.contains('шпинат') || lower.contains('огур') || lower.contains('авокадо') || lower.contains('зелен')) {
      return 'Овощи и зелень';
    }
    return 'Бакалея';
  }

  String _pickEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('томат')) return '🍅';
    if (lower.contains('лосось') || lower.contains('рыб')) return '🐟';
    if (lower.contains('куриц')) return '🍗';
    if (lower.contains('сыр')) return '🧀';
    if (lower.contains('яйц')) return '🥚';
    if (lower.contains('молок') || lower.contains('сливк')) return '🥛';
    if (lower.contains('шпинат') || lower.contains('салат')) return '🥬';
    if (lower.contains('авокадо')) return '🥑';
    if (lower.contains('паста')) return '🍝';
    return '🛒';
  }

  Future<void> _persist() async {
    await LocalStorageService.saveGroceryItems(state);
  }
}

final groceryProvider = StateNotifierProvider<GroceryNotifier, List<GroceryItem>>((ref) {
  return GroceryNotifier(ref);
});

/// Groups grocery items by department for supermarket navigation
final groupedGroceryProvider = Provider<Map<String, List<GroceryItem>>>((ref) {
  final items = ref.watch(groceryProvider);
  final Map<String, List<GroceryItem>> grouped = {};

  for (final item in items) {
    grouped.putIfAbsent(item.department, () => []).add(item);
  }

  return grouped;
});
