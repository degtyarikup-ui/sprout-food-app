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
    if (saved != null) {
      state = saved;
    } else {
      // Clean empty fridge for new users
      state = [];
      await _persist();
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

  Future<void> clearAll() async {
    state = [];
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
