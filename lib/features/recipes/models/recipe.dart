import 'package:uuid/uuid.dart';
import 'cooking_step.dart';
import 'ingredient.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String category; // 'Завтрак', 'Обед', 'Ужин', 'Перекус', 'Десерт'
  final List<String> tags; // 'Быстро (15 мин)', 'Высокий белок', 'Кето', 'Без глютена'
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int defaultServings;
  
  // Macros per serving
  final int calories;
  final int proteinGrams;
  final int fatGrams;
  final int carbsGrams;

  final List<Ingredient> ingredients;
  final List<CookingStep> steps;
  final String imageUrl;
  final String? videoUrl;
  final String source; // 'Шеф-база', 'AI Адаптация', 'Instagram @chef'
  final String difficulty; // 'Легко', 'Средне', 'Шеф'
  final bool isFavorite;

  // Differentiator fields
  final String? zeroWasteTip; // e.g. "Оставшийся желток используйте в завтрашнем омлете"
  final String? familySplitTip; // e.g. "Для детей подавайте соус отдельно"

  Recipe({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.defaultServings,
    required this.calories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.ingredients,
    required this.steps,
    this.imageUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
    this.videoUrl,
    this.source = 'Шеф-база',
    this.difficulty = 'Легко',
    this.isFavorite = false,
    this.zeroWasteTip,
    this.familySplitTip,
  }) : id = id ?? const Uuid().v4();

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? defaultServings,
    int? calories,
    int? proteinGrams,
    int? fatGrams,
    int? carbsGrams,
    List<Ingredient>? ingredients,
    List<CookingStep>? steps,
    String? imageUrl,
    String? videoUrl,
    String? source,
    String? difficulty,
    bool? isFavorite,
    String? zeroWasteTip,
    String? familySplitTip,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      defaultServings: defaultServings ?? this.defaultServings,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      source: source ?? this.source,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
      zeroWasteTip: zeroWasteTip ?? this.zeroWasteTip,
      familySplitTip: familySplitTip ?? this.familySplitTip,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'defaultServings': defaultServings,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'fatGrams': fatGrams,
      'carbsGrams': carbsGrams,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'source': source,
      'difficulty': difficulty,
      'isFavorite': isFavorite,
      'zeroWasteTip': zeroWasteTip,
      'familySplitTip': familySplitTip,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      prepTimeMinutes: json['prepTimeMinutes'] as int,
      cookTimeMinutes: json['cookTimeMinutes'] as int,
      defaultServings: json['defaultServings'] as int,
      calories: json['calories'] as int,
      proteinGrams: json['proteinGrams'] as int,
      fatGrams: json['fatGrams'] as int,
      carbsGrams: json['carbsGrams'] as int,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => CookingStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      videoUrl: json['videoUrl'] as String?,
      source: json['source'] as String? ?? 'Шеф-база',
      difficulty: json['difficulty'] as String? ?? 'Легко',
      isFavorite: json['isFavorite'] as bool? ?? false,
      zeroWasteTip: json['zeroWasteTip'] as String?,
      familySplitTip: json['familySplitTip'] as String?,
    );
  }
}
