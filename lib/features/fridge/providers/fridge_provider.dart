import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';
import '../models/freshness_category.dart';
import '../models/product_item.dart';

class FridgeNotifier extends StateNotifier<List<ProductItem>> {
  FridgeNotifier() : super([]) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final saved = await LocalStorageService.loadFridgeItems();
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    } else {
      // Default initial fridge demo data
      final now = DateTime.now();
      state = [
        ProductItem(
          name: 'Сыр Фета',
          amount: 180,
          unit: 'г',
          category: 'Молочные продукты',
          addedDate: now.subtract(const Duration(days: 3)),
          expiryDate: now.add(const Duration(days: 1)), // Urgent!
          emoji: '🧀',
          estimatedPrice: 210,
        ),
        ProductItem(
          name: 'Томаты спелые',
          amount: 400,
          unit: 'г',
          category: 'Овощи и зелень',
          addedDate: now.subtract(const Duration(days: 2)),
          expiryDate: now.add(const Duration(days: 2)), // Urgent!
          emoji: '🍅',
          estimatedPrice: 150,
        ),
        ProductItem(
          name: 'Куриные яйца (С0)',
          amount: 6,
          unit: 'шт',
          category: 'Молочные и яйца',
          addedDate: now.subtract(const Duration(days: 4)),
          expiryDate: now.add(const Duration(days: 4)), // Soon
          emoji: '🥚',
          estimatedPrice: 120,
        ),
        ProductItem(
          name: 'Куриное филе',
          amount: 400,
          unit: 'г',
          category: 'Мясо и птица',
          addedDate: now.subtract(const Duration(days: 1)),
          expiryDate: now.add(const Duration(days: 3)), // Soon
          emoji: '🍗',
          estimatedPrice: 240,
        ),
        ProductItem(
          name: 'Свежий шпинат',
          amount: 80,
          unit: 'г',
          category: 'Овощи и зелень',
          addedDate: now,
          expiryDate: now.add(const Duration(days: 2)), // Urgent!
          emoji: '🥬',
          estimatedPrice: 90,
        ),
        ProductItem(
          name: 'Авокадо Хасс',
          amount: 1,
          unit: 'шт',
          category: 'Овощи и зелень',
          addedDate: now.subtract(const Duration(days: 1)),
          expiryDate: now.add(const Duration(days: 3)),
          emoji: '🥑',
          estimatedPrice: 140,
        ),
        ProductItem(
          name: 'Оливковое масло Extra Virgin',
          amount: 450,
          unit: 'мл',
          category: 'Бакалея',
          addedDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.add(const Duration(days: 90)), // Good / Pantry
          emoji: '🫒',
          estimatedPrice: 650,
        ),
        ProductItem(
          name: 'Паста Пенне',
          amount: 350,
          unit: 'г',
          category: 'Бакалея',
          addedDate: now.subtract(const Duration(days: 5)),
          expiryDate: now.add(const Duration(days: 180)), // Pantry
          emoji: '🍝',
          estimatedPrice: 110,
        ),
      ];
      _persist();
    }
  }

  Future<void> addProduct(ProductItem item) async {
    state = [item, ...state];
    await _persist();
  }

  ProductItem? _lastDeletedProduct;
  int? _lastDeletedIndex;

  ProductItem? get lastDeletedProduct => _lastDeletedProduct;

  Future<ProductItem?> removeProduct(String id) async {
    final index = state.indexWhere((item) => item.id == id);
    if (index != -1) {
      _lastDeletedProduct = state[index];
      _lastDeletedIndex = index;
    }
    state = state.where((item) => item.id != id).toList();
    await _persist();
    return _lastDeletedProduct;
  }

  Future<void> undoLastDeletedProduct() async {
    if (_lastDeletedProduct == null) return;
    final item = _lastDeletedProduct!;
    final index = (_lastDeletedIndex != null && _lastDeletedIndex! <= state.length)
        ? _lastDeletedIndex!
        : 0;
    final updated = List<ProductItem>.from(state);
    updated.insert(index, item);
    state = updated;
    _lastDeletedProduct = null;
    _lastDeletedIndex = null;
    await _persist();
  }

  Future<void> addMultipleProducts(List<ProductItem> items) async {
    state = [...items, ...state];
    await _persist();
  }

  /// Deduct specific quantities of ingredients used during cooking
  Future<void> deductIngredients(Map<String, double> deductions) async {
    final List<ProductItem> updatedList = [];

    for (final item in state) {
      final key = deductions.keys.firstWhere(
        (k) => item.name.toLowerCase().contains(k.toLowerCase()) || k.toLowerCase().contains(item.name.toLowerCase()),
        orElse: () => '',
      );

      if (key.isNotEmpty) {
        final deductAmount = deductions[key]!;
        final newAmount = item.amount - deductAmount;

        if (newAmount > 0.05) {
          // Reduce amount
          updatedList.add(item.copyWith(amount: newAmount));
        }
        // If <= 0, item is fully consumed and removed from fridge!
      } else {
        updatedList.add(item);
      }
    }

    state = updatedList;
    await _persist();
  }

  Future<void> _persist() async {
    await LocalStorageService.saveFridgeItems(state);
  }
}

final fridgeProvider = StateNotifierProvider<FridgeNotifier, List<ProductItem>>((ref) {
  return FridgeNotifier();
});

/// Urgent items provider (expiring in 1-2 days)
final urgentFridgeItemsProvider = Provider<List<ProductItem>>((ref) {
  final items = ref.watch(fridgeProvider);
  return items.where((i) => i.freshness == FreshnessCategory.urgent).toList();
});

/// Soon items provider (expiring in 3-5 days)
final soonFridgeItemsProvider = Provider<List<ProductItem>>((ref) {
  final items = ref.watch(fridgeProvider);
  return items.where((i) => i.freshness == FreshnessCategory.soon).toList();
});
