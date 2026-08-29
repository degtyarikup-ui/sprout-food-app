enum DietType {
  omnivore,    // Всеядный
  vegetarian,  // Вегетарианство
  vegan,       // Веганство
  keto,        // Кето
  lowCarb,     // Низкоуглеводная
  noSugar,     // Без сахара
}

extension DietTypeExtension on DietType {
  String get label {
    switch (this) {
      case DietType.omnivore:
        return 'Без ограничений';
      case DietType.vegetarian:
        return 'Вегетарианство';
      case DietType.vegan:
        return 'Веганство';
      case DietType.keto:
        return 'Кето';
      case DietType.lowCarb:
        return 'Низкоуглеводная';
      case DietType.noSugar:
        return 'Без сахара';
    }
  }

  String get shortDescription {
    switch (this) {
      case DietType.omnivore:
        return 'Все виды продуктов';
      case DietType.vegetarian:
        return 'Без мяса и рыбы';
      case DietType.vegan:
        return 'Только растительное';
      case DietType.keto:
        return 'Жиры вместо углеводов';
      case DietType.lowCarb:
        return 'Минимум углеводов';
      case DietType.noSugar:
        return 'Без добавленного сахара';
    }
  }
}

class UserPreferences {
  final int defaultServings; // 1, 2, 4, 6
  final DietType diet;
  final List<String> allergies;
  final List<String> goals;
  final bool autoSyncFridgeOnCooking;

  const UserPreferences({
    this.defaultServings = 2,
    this.diet = DietType.omnivore,
    this.allergies = const [],
    this.goals = const [],
    this.autoSyncFridgeOnCooking = true,
  });

  UserPreferences copyWith({
    int? defaultServings,
    DietType? diet,
    List<String>? allergies,
    List<String>? goals,
    bool? autoSyncFridgeOnCooking,
  }) {
    return UserPreferences(
      defaultServings: defaultServings ?? this.defaultServings,
      diet: diet ?? this.diet,
      allergies: allergies ?? this.allergies,
      goals: goals ?? this.goals,
      autoSyncFridgeOnCooking: autoSyncFridgeOnCooking ?? this.autoSyncFridgeOnCooking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultServings': defaultServings,
      'diet': diet.name,
      'allergies': allergies,
      'goals': goals,
      'autoSyncFridgeOnCooking': autoSyncFridgeOnCooking,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    DietType parsedDiet = DietType.omnivore;
    if (json['diet'] != null) {
      parsedDiet = DietType.values.firstWhere(
        (d) => d.name == json['diet'],
        orElse: () => DietType.omnivore,
      );
    }

    return UserPreferences(
      defaultServings: (json['defaultServings'] as num?)?.toInt() ?? 2,
      diet: parsedDiet,
      allergies: (json['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      goals: (json['goals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      autoSyncFridgeOnCooking: json['autoSyncFridgeOnCooking'] as bool? ?? true,
    );
  }
}
