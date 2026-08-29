import 'package:uuid/uuid.dart';
import '../../recipes/models/recipe.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Завтрак';
      case MealType.lunch:
        return 'Обед';
      case MealType.dinner:
        return 'Ужин';
      case MealType.snack:
        return 'Перекус';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🍲';
      case MealType.dinner:
        return '🥗';
      case MealType.snack:
        return '🍎';
    }
  }
}

class MealSlot {
  final String id;
  final MealType type;
  final Recipe? recipe;
  final bool isCompleted;
  final String? prepAlert; // e.g. "Разморозьте курицу с вечера"
  final int servings;

  MealSlot({
    String? id,
    required this.type,
    this.recipe,
    this.isCompleted = false,
    this.prepAlert,
    this.servings = 2,
  }) : id = id ?? const Uuid().v4();

  MealSlot copyWith({
    String? id,
    MealType? type,
    Recipe? recipe,
    bool? isCompleted,
    String? prepAlert,
    int? servings,
  }) {
    return MealSlot(
      id: id ?? this.id,
      type: type ?? this.type,
      recipe: recipe ?? this.recipe,
      isCompleted: isCompleted ?? this.isCompleted,
      prepAlert: prepAlert ?? this.prepAlert,
      servings: servings ?? this.servings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'recipe': recipe?.toJson(),
      'isCompleted': isCompleted,
      'prepAlert': prepAlert,
      'servings': servings,
    };
  }

  factory MealSlot.fromJson(Map<String, dynamic> json) {
    return MealSlot(
      id: json['id'] as String?,
      type: MealType.values.byName(json['type'] as String),
      recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      prepAlert: json['prepAlert'] as String?,
      servings: json['servings'] as int? ?? 2,
    );
  }
}
