import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';
import '../../family/providers/family_provider.dart';
import '../../family/services/family_cloud_service.dart';
import '../models/freshness_category.dart';
import '../models/product_item.dart';

class FridgeNotifier extends StateNotifier<List<ProductItem>> {
  final Ref _ref;

  FridgeNotifier(this._ref) : super([]) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final saved = await LocalStorageService.loadFridgeItems();
    if (saved != null) {
      state = saved;
    } else {
      state = [];
      await _persist();
    }

    // Attempt cloud pull if part of a family
    await pullFromCloud();
  }

  Future<void> pullFromCloud() async {
    try {
      final family = _ref.read(familyProvider);
      if (family == null || family.cloudId == null) return;
      final data = await FamilyCloudService.fetchFullCloudData(family.cloudId!);
      if (data != null && data.containsKey('fridge')) {
        final cloudFridge = data['fridge'] as List<ProductItem>;
        state = cloudFridge;
        await LocalStorageService.saveFridgeItems(state);
      }
    } catch (_) {}
  }

  void setProductsFromCloud(List<ProductItem> items) {
    state = items;
    LocalStorageService.saveFridgeItems(state);
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
          updatedList.add(item.copyWith(amount: newAmount));
        }
      } else {
        updatedList.add(item);
      }
    }

    state = updatedList;
    await _persist();
  }

  Future<void> _persist() async {
    await LocalStorageService.saveFridgeItems(state);

    // Sync to Cloud if part of a family
    try {
      final family = _ref.read(familyProvider);
      if (family != null && family.cloudId != null && family.cloudId!.isNotEmpty) {
        await FamilyCloudService.updateCloudData(
          family.cloudId!,
          fridge: state,
        );
      }
    } catch (_) {}
  }
}

final fridgeProvider = StateNotifierProvider<FridgeNotifier, List<ProductItem>>((ref) {
  return FridgeNotifier(ref);
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
