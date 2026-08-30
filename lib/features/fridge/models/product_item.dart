import 'package:uuid/uuid.dart';
import 'freshness_category.dart';

class ProductItem {
  final String id;
  final String name;
  final double amount;
  final String unit; // 'г', 'мл', 'шт', 'уп'
  final String category; // 'Овощи и фрукты', 'Молочные', 'Мясо/Рыба', 'Бакалея', 'Соусы/Специи'
  final DateTime addedDate;
  final DateTime expiryDate;
  final String emoji;
  final bool isOpened;
  final double? estimatedPrice; // For money saving analytics
  final List<double>? box2d; // [ymin, xmin, ymax, xmax] in range 0..1000 for visual AR detection

  ProductItem({
    String? id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.category,
    required this.addedDate,
    required this.expiryDate,
    this.emoji = '🥑',
    this.isOpened = false,
    this.estimatedPrice,
    this.box2d,
  }) : id = id ?? const Uuid().v4();

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  FreshnessCategory get freshness {
    final days = daysUntilExpiry;
    if (days <= 2) {
      return FreshnessCategory.urgent;
    } else if (days <= 5) {
      return FreshnessCategory.soon;
    } else if (days <= 14) {
      return FreshnessCategory.good;
    } else {
      return FreshnessCategory.pantry;
    }
  }

  ProductItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    String? category,
    DateTime? addedDate,
    DateTime? expiryDate,
    String? emoji,
    bool? isOpened,
    double? estimatedPrice,
    List<double>? box2d,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      addedDate: addedDate ?? this.addedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      emoji: emoji ?? this.emoji,
      isOpened: isOpened ?? this.isOpened,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      box2d: box2d ?? this.box2d,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'category': category,
      'addedDate': addedDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'emoji': emoji,
      'isOpened': isOpened,
      'estimatedPrice': estimatedPrice,
      if (box2d != null) 'box2d': box2d,
    };
  }

  factory ProductItem.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = Map<String, dynamic>.from(rawJson);
    return ProductItem(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Продукт',
      amount: (json['amount'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'шт',
      category: json['category'] as String? ?? 'Разное',
      addedDate: json['addedDate'] != null
          ? DateTime.tryParse(json['addedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString()) ?? DateTime.now().add(const Duration(days: 5))
          : DateTime.now().add(const Duration(days: 5)),
      emoji: json['emoji'] as String? ?? '🥑',
      isOpened: json['isOpened'] as bool? ?? false,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      box2d: (json['box2d'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
    );
  }
}
