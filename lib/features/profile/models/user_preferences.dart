enum DietType {
  omnivore,    // Всеядный
  vegetarian,  // Вегетарианство
  vegan,       // Веганство
  keto,        // Кето
  lowCarb,     // Низкоуглеводная
}

extension DietTypeExtension on DietType {
  String get label {
    switch (this) {
      case DietType.omnivore:
        return 'Всеядный';
      case DietType.vegetarian:
        return 'Вегетарианство';
      case DietType.vegan:
        return 'Веганство';
      case DietType.keto:
        return 'Кето';
      case DietType.lowCarb:
        return 'Low Carb';
    }
  }
}

class UserPreferences {
  final int defaultServings; // 1, 2, 4, 6
  final DietType diet;
  final List<String> allergies; // 'Глютен', 'Лактоза', 'Орехи', 'Морепродукты', 'Сахар', 'Острое'
  final bool autoSyncFridgeOnCooking;

  const UserPreferences({
    this.defaultServings = 2,
    this.diet = DietType.omnivore,
    this.allergies = const [],
    this.autoSyncFridgeOnCooking = true,
  });

  UserPreferences copyWith({
    int? defaultServings,
    DietType? diet,
    List<String>? allergies,
    bool? autoSyncFridgeOnCooking,
  }) {
    return UserPreferences(
      defaultServings: defaultServings ?? this.defaultServings,
      diet: diet ?? this.diet,
      allergies: allergies ?? this.allergies,
      autoSyncFridgeOnCooking: autoSyncFridgeOnCooking ?? this.autoSyncFridgeOnCooking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultServings': defaultServings,
      'diet': diet.name,
      'allergies': allergies,
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
      autoSyncFridgeOnCooking: json['autoSyncFridgeOnCooking'] as bool? ?? true,
    );
  }
}
