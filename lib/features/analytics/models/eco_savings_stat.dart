class EcoSavingsStat {
  final double savedMoneyRub;
  final double savedFoodKg;
  final int streakDays;
  final int recipesZeroWasted;
  final int totalProductsTracked;
  final double co2SavedKg;

  const EcoSavingsStat({
    this.savedMoneyRub = 4350.0,
    this.savedFoodKg = 3.6,
    this.streakDays = 12,
    this.recipesZeroWasted = 18,
    this.totalProductsTracked = 42,
    this.co2SavedKg = 8.4,
  });

  EcoSavingsStat copyWith({
    double? savedMoneyRub,
    double? savedFoodKg,
    int? streakDays,
    int? recipesZeroWasted,
    int? totalProductsTracked,
    double? co2SavedKg,
  }) {
    return EcoSavingsStat(
      savedMoneyRub: savedMoneyRub ?? this.savedMoneyRub,
      savedFoodKg: savedFoodKg ?? this.savedFoodKg,
      streakDays: streakDays ?? this.streakDays,
      recipesZeroWasted: recipesZeroWasted ?? this.recipesZeroWasted,
      totalProductsTracked: totalProductsTracked ?? this.totalProductsTracked,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'savedMoneyRub': savedMoneyRub,
      'savedFoodKg': savedFoodKg,
      'streakDays': streakDays,
      'recipesZeroWasted': recipesZeroWasted,
      'totalProductsTracked': totalProductsTracked,
      'co2SavedKg': co2SavedKg,
    };
  }

  factory EcoSavingsStat.fromJson(Map<String, dynamic> json) {
    return EcoSavingsStat(
      savedMoneyRub: (json['savedMoneyRub'] as num?)?.toDouble() ?? 4350.0,
      savedFoodKg: (json['savedFoodKg'] as num?)?.toDouble() ?? 3.6,
      streakDays: json['streakDays'] as int? ?? 12,
      recipesZeroWasted: json['recipesZeroWasted'] as int? ?? 18,
      totalProductsTracked: json['totalProductsTracked'] as int? ?? 42,
      co2SavedKg: (json['co2SavedKg'] as num?)?.toDouble() ?? 8.4,
    );
  }
}
