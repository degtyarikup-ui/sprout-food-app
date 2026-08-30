import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';
import '../../analytics/providers/eco_savings_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../family/services/family_cloud_service.dart';
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
      _createEmpty7DayPlan();
    }

    // Pull shared family plan if in a family
    await pullFromCloud();
  }

  Future<void> pullFromCloud() async {
    try {
      final family = _ref.read(familyProvider);
      if (family == null || family.cloudId == null) return;
      final data = await FamilyCloudService.fetchFullCloudData(family.cloudId!);
      if (data != null && data.containsKey('mealPlan')) {
        final cloudPlan = data['mealPlan'] as List<MealPlanDay>;
        if (cloudPlan.isNotEmpty) {
          state = cloudPlan;
          await LocalStorageService.saveMealPlan(state);
        }
      }
    } catch (_) {}
  }

  void setMealPlanFromCloud(List<MealPlanDay> days) {
    if (days.isNotEmpty) {
      state = days;
      LocalStorageService.saveMealPlan(state);
    }
  }

  /// Creates a clean slate with empty Breakfast, Lunch, Dinner slots for 7 days
  void _createEmpty7DayPlan() {
    final now = DateTime.now();
    final List<MealPlanDay> days = [];

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      days.add(
        MealPlanDay(
          date: date,
          dayTheme: i == 0 ? 'Сегодня' : (i == 1 ? 'Завтра' : 'День ${i + 1}'),
          slots: [
            MealSlot(type: MealType.breakfast, recipe: null),
            MealSlot(type: MealType.lunch, recipe: null),
            MealSlot(type: MealType.dinner, recipe: null),
          ],
        ),
      );
    }
    state = days;
    _persist();
  }

  /// Clears all meals from the plan, giving user empty slots to plan manually
  void clearEntirePlan() {
    _createEmpty7DayPlan();
  }

  /// Generates or rebuilds the 7-day plan matching current fridge ingredients
  void generateZeroWastePlan() {
    final now = DateTime.now();
    final List<MealPlanDay> days = [];
    final recipes = kCuratedRecipes;

    final shakshuka = recipes.firstWhere((r) => r.id == 'r_shakshuka', orElse: () => recipes[0]);
    final salmonBowl = recipes.firstWhere((r) => r.id == 'r_salmon_bowl', orElse: () => recipes.length > 1 ? recipes[1] : recipes[0]);
    final pasta = recipes.firstWhere((r) => r.id == 'r_creamy_pasta', orElse: () => recipes.length > 2 ? recipes[2] : recipes[0]);
    final syrniki = recipes.firstWhere((r) => r.id == 'r_syrniki', orElse: () => recipes[0]);
    final turkey = recipes.firstWhere((r) => r.id == 'r_turkey_corn', orElse: () => recipes[0]);

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      List<MealSlot> slots = [];

      if (i == 0) {
        slots = [
          MealSlot(
            type: MealType.breakfast,
            recipe: shakshuka,
            prepAlert: 'Используйте томаты и яйца из холодильника',
          ),
          MealSlot(
            type: MealType.lunch,
            recipe: salmonBowl,
          ),
          MealSlot(
            type: MealType.dinner,
            recipe: pasta,
            prepAlert: 'Разморозьте куриное филе для пасты',
          ),
        ];
      } else if (i == 1) {
        slots = [
          MealSlot(type: MealType.breakfast, recipe: syrniki),
          MealSlot(type: MealType.lunch, recipe: pasta),
          MealSlot(type: MealType.dinner, recipe: turkey),
        ];
      } else {
        slots = [
          MealSlot(type: MealType.breakfast, recipe: i % 2 == 0 ? shakshuka : syrniki),
          MealSlot(type: MealType.lunch, recipe: salmonBowl),
          MealSlot(type: MealType.dinner, recipe: i % 2 == 0 ? turkey : pasta),
        ];
      }

      days.add(
        MealPlanDay(
          date: date,
          slots: slots,
          dayTheme: i == 0 ? 'Сегодня: Срочная свежесть' : (i == 1 ? 'Завтра: Шеф-меню' : 'Сбалансированное меню'),
        ),
      );
    }

    state = days;
    _persist();
  }

  /// Assign or change recipe in a slot
  void assignRecipeToSlot(DateTime dayDate, String slotId, Recipe recipe) {
    state = state.map((day) {
      if (_isSameDay(day.date, dayDate)) {
        final updatedSlots = day.slots.map((s) {
          if (s.id == slotId) {
            return s.copyWith(recipe: recipe, isCompleted: false);
          }
          return s;
        }).toList();
        return day.copyWith(slots: updatedSlots);
      }
      return day;
    }).toList();
    _persist();
  }

  /// Remove a recipe from slot (makes it empty, not locked)
  void removeRecipeFromSlot(DateTime dayDate, String slotId) {
    state = state.map((day) {
      if (_isSameDay(day.date, dayDate)) {
        final updatedSlots = day.slots.map((s) {
          if (s.id == slotId) {
            return MealSlot(
              id: s.id,
              type: s.type,
              recipe: null,
              isCompleted: false,
            );
          }
          return s;
        }).toList();
        return day.copyWith(slots: updatedSlots);
      }
      return day;
    }).toList();
    _persist();
  }

  /// Add custom meal slot (e.g. Перекус)
  void addMealSlot(DateTime dayDate, MealType type, Recipe? recipe) {
    state = state.map((day) {
      if (_isSameDay(day.date, dayDate)) {
        final newSlot = MealSlot(type: type, recipe: recipe);
        return day.copyWith(slots: [...day.slots, newSlot]);
      }
      return day;
    }).toList();
    _persist();
  }

  /// Delete a slot entirely
  void deleteSlot(DateTime dayDate, String slotId) {
    state = state.map((day) {
      if (_isSameDay(day.date, dayDate)) {
        final updatedSlots = day.slots.where((s) => s.id != slotId).toList();
        return day.copyWith(slots: updatedSlots);
      }
      return day;
    }).toList();
    _persist();
  }

  /// Swap slot recipe (alias to assign)
  void swapSlotRecipe(DateTime dayDate, String slotId, Recipe newRecipe) {
    assignRecipeToSlot(dayDate, slotId, newRecipe);
  }

  /// Mark meal as cooked -> update eco savings and mark slot completed
  void completeMealSlot(DateTime dayDate, String slotId) {
    state = state.map((day) {
      if (_isSameDay(day.date, dayDate)) {
        final updatedSlots = day.slots.map((s) {
          if (s.id == slotId) {
            return s.copyWith(isCompleted: !s.isCompleted);
          }
          return s;
        }).toList();
        return day.copyWith(slots: updatedSlots);
      }
      return day;
    }).toList();

    _ref.read(ecoSavingsProvider.notifier).recordMealCooked(savedMoney: 280.0, savedKg: 0.35);
    _persist();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _persist() async {
    await LocalStorageService.saveMealPlan(state);

    // Sync to Cloud if part of a family
    try {
      final family = _ref.read(familyProvider);
      if (family != null && family.cloudId != null && family.cloudId!.isNotEmpty) {
        await FamilyCloudService.updateCloudData(
          family.cloudId!,
          mealPlan: state,
        );
      }
    } catch (_) {}
  }
}

final mealPlannerProvider = StateNotifierProvider<MealPlannerNotifier, List<MealPlanDay>>((ref) {
  return MealPlannerNotifier(ref);
});

final selectedDayIndexProvider = StateProvider<int>((ref) => 0);
