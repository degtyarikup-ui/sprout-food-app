class Ingredient {
  final String name;
  final double amount;
  final String unit; // 'г', 'мл', 'шт', 'ст. л.', 'ч. л.', 'зубчик'
  final String? notes; // 'мелко нарезать', 'комнатной температуры'
  final bool isOptional;
  final String? substitute; // Alternative if not available

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.notes,
    this.isOptional = false,
    this.substitute,
  });

  Ingredient copyWith({
    String? name,
    double? amount,
    String? unit,
    String? notes,
    bool? isOptional,
    String? substitute,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      isOptional: isOptional ?? this.isOptional,
      substitute: substitute ?? this.substitute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'notes': notes,
      'isOptional': isOptional,
      'substitute': substitute,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
      isOptional: json['isOptional'] as bool? ?? false,
      substitute: json['substitute'] as String?,
    );
  }
}
