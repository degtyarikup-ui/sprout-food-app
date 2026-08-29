import 'package:uuid/uuid.dart';

class GroceryItem {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final String department; // 'Овощи и зелень', 'Молочные продукты', 'Мясо и рыба', 'Бакалея', 'Соусы и специи'
  final bool isChecked;
  final String? recipeOriginTitle;
  final double? estimatedCost;
  final String emoji;

  GroceryItem({
    String? id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.department,
    this.isChecked = false,
    this.recipeOriginTitle,
    this.estimatedCost,
    this.emoji = '🛒',
  }) : id = id ?? const Uuid().v4();

  GroceryItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    String? department,
    bool? isChecked,
    String? recipeOriginTitle,
    double? estimatedCost,
    String? emoji,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      department: department ?? this.department,
      isChecked: isChecked ?? this.isChecked,
      recipeOriginTitle: recipeOriginTitle ?? this.recipeOriginTitle,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'department': department,
      'isChecked': isChecked,
      'recipeOriginTitle': recipeOriginTitle,
      'estimatedCost': estimatedCost,
      'emoji': emoji,
    };
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      department: json['department'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
      recipeOriginTitle: json['recipeOriginTitle'] as String?,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      emoji: json['emoji'] as String? ?? '🛒',
    );
  }
}
