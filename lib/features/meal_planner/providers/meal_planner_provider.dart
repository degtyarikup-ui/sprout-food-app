import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../../recipes/data/curated_recipes.dart';
import '../../recipes/models/recipe.dart';
import '../models/meal_plan_day.dart';
import '../models/meal_slot.dart';

class MealPlannerNotifier extends StateNotifier<List<MealPlanDay>> {
  final Ref _ref;

  MealPlannerNotifier(this._ref) : super([]) {
    _initPlan();
  }

  Future<void> _initPlan() async {
    final saved = await LocalStorageService.loadMealPlan();
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    } else {
      generateZeroWastePlan();
    }
  }

  /// Generates or rebuilds the 7-day plan optimizing for zero food waste
  void generateZeroWastePlan() {
    final now = DateTime.now();
    final List<MealPlanDay> days = [];

    final recipes = kCuratedRecipes;
    final shakshuka = recipes.firstWhere((r) => r.id == 'r_shakshuka');
    final salmonBowl = recipes.firstWhere((r) => r.id == 'r_salmon_bowl');
    final pasta = recipes.firstWhere((r) => r.id == 'r_creamy_pasta');
    final chia = recipes.firstWhere((r) => r.id == 'r_chia_pudding');
    final bakedVeggies = recipes.firstWhere((r) => r.id == 'r_baked_veggies_feta');

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      List<MealSlot> slots = [];

      if (i == 0) {
        // Today: Focus on urgent expiring items (Tomatoes + Feta + Spinach)
        slots = [
          MealSlot(
            type: MealType.breakfast,
            recipe: shakshuka,
            prepAlert: '🔥 Используйте томаты и шпинат из холодильника (истекают сегодня)',
          ),
          MealSlot(
            type: MealType.lunch,
            recipe: salmonBowl,
          ),
          MealSlot(
            type: MealType.dinner,
            recipe: pasta,
            prepAlert: 'Совет: Разморозьте куриное филе для пасты',
          ),
        ];
      } else if (i == 1) {
        // Tomorrow: Leftover loop (Feta cheese + Veggies)
        slots = [
          MealSlot(
            type: MealType.breakfast,
            recipe: chia,
          ),
          MealSlot(
            type: MealType.lunch,
            recipe: pasta, // Batch cooking leftover
          ),
          MealSlot(
            type: MealType.dinner,
            recipe: bakedVeggies,
            prepAlert: '🔥 Доиспользуем остатки феты и сезонные овощи',
          ),
        ];
      } else {
        // Days 3-7
        slots = [
          MealSlot(
            type: MealType.breakfast,
            recipe: i % 2 == 0 ? shakshuka : chia,
          ),
          MealSlot(
            type: MealType.lunch,
            recipe: salmonBowl,
          ),
          MealSlot(
            type: MealType.dinner,
            recipe: i % 2 == 0 ? bakedVeggies : pasta,
          ),
        ];
      }

      days.add(
        MealPlanDay(
          date: date,
          slots: slots,
          dayTheme: i == 0 ? 'День 1: Срочная свежесть' : (i == 1 ? 'День 2: Zero Waste Loop' : 'Сбалансированное меню'),
          chefAdvice: i == 0
              ? 'Сегодня спасаем томаты и шпинат — они на пике вкуса!'
              : 'Вторая половина феты идеально подойдет для запекания с овощами завтра вечером.',
        ),
      );
    }

    state = days;
    _persist();
  }

  /// Swap a meal slot with another recipe
  void swapSlotRecipe(DateTime dayDate, String slotId, Recipe newRecipe) {
    state = state.map((day) {
      if (day.date.year == dayDate.year &&
          day.date.month == dayDate.month &&
          day.date.day == dayDate.day) {
        final updatedSlots = day.slots.map((s) {
          if (s.id == slotId) {
            return s.copyWith(recipe: newRecipe);
          }
          return s;
        }).toList();
        return day.copyWith(slots: updatedSlots);
      }
      return day;
    }).toList();
    _persist();
  }

  /// Mark meal as cooked -> update eco savings and mark slot completed
  void completeMealSlot(DateTime dayDate, String slotId) {
    state = state.map((day) {
      if (day.date.year == dayDate.year &&
          day.date.month == dayDate.month &&
          day.date.day == dayDate.day) {
        final updatedSlots = day.slots.map((s) {
          if (s.id == slotId) {
            return s.copyWith(isCompleted: true);
          }
          return s;
        }).toList();
        return day.copyWith(slots: updatedSlots);
      }
      return day;
    }).toList();

    // Reward user in eco-savings
    _ref.read(ecoSavingsProvider.notifier).recordMealCooked(savedMoney: 280.0, savedKg: 0.35);
    _persist();
  }

  Future<void> _persist() async {
    await LocalStorageService.saveMealPlan(state);
  }
}

final mealPlannerProvider = StateNotifierProvider<MealPlannerNotifier, List<MealPlanDay>>((ref) {
  return MealPlannerNotifier(ref);
});

final selectedDayIndexProvider = StateProvider<int>((ref) => 0);
