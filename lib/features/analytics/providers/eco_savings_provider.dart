import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';
import '../models/eco_savings_stat.dart';

class EcoSavingsNotifier extends StateNotifier<EcoSavingsStat> {
  EcoSavingsNotifier() : super(const EcoSavingsStat()) {
    _init();
  }

  Future<void> _init() async {
    final saved = await LocalStorageService.loadEcoStats();
    if (saved != null) {
      state = saved;
    }
  }

  void recordMealCooked({required double savedMoney, required double savedKg}) {
    state = state.copyWith(
      savedMoneyRub: state.savedMoneyRub + savedMoney,
      savedFoodKg: state.savedFoodKg + savedKg,
      recipesZeroWasted: state.recipesZeroWasted + 1,
      co2SavedKg: state.co2SavedKg + (savedKg * 2.3), // 1 kg food waste ≈ 2.3 kg CO2
    );
    LocalStorageService.saveEcoStats(state);
  }

  void recordProductScanned(int count) {
    state = state.copyWith(
      totalProductsTracked: state.totalProductsTracked + count,
    );
    LocalStorageService.saveEcoStats(state);
  }
}

final ecoSavingsProvider = StateNotifierProvider<EcoSavingsNotifier, EcoSavingsStat>((ref) {
  return EcoSavingsNotifier();
});
