import 'meal_slot.dart';

class MealPlanDay {
  final DateTime date;
  final List<MealSlot> slots;
  final String? dayTheme; // e.g. "Рыбный четверг", "Быстрый ужин"
  final String? chefAdvice; // Daily anti-waste advice

  MealPlanDay({
    required this.date,
    required this.slots,
    this.dayTheme,
    this.chefAdvice,
  });

  int get totalCalories => slots.fold(
      0, (sum, slot) => sum + ((slot.recipe?.calories ?? 0) * (slot.servings / 2)).round());

  int get totalProtein => slots.fold(
      0, (sum, slot) => sum + ((slot.recipe?.proteinGrams ?? 0) * (slot.servings / 2)).round());

  int get totalFat => slots.fold(
      0, (sum, slot) => sum + ((slot.recipe?.fatGrams ?? 0) * (slot.servings / 2)).round());

  int get totalCarbs => slots.fold(
      0, (sum, slot) => sum + ((slot.recipe?.carbsGrams ?? 0) * (slot.servings / 2)).round());

  MealPlanDay copyWith({
    DateTime? date,
    List<MealSlot>? slots,
    String? dayTheme,
    String? chefAdvice,
  }) {
    return MealPlanDay(
      date: date ?? this.date,
      slots: slots ?? this.slots,
      dayTheme: dayTheme ?? this.dayTheme,
      chefAdvice: chefAdvice ?? this.chefAdvice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'slots': slots.map((s) => s.toJson()).toList(),
      'dayTheme': dayTheme,
      'chefAdvice': chefAdvice,
    };
  }

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    return MealPlanDay(
      date: DateTime.parse(json['date'] as String),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => MealSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      dayTheme: json['dayTheme'] as String?,
      chefAdvice: json['chefAdvice'] as String?,
    );
  }
}
