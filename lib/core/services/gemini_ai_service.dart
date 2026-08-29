import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../features/fridge/models/product_item.dart';
import '../../features/recipes/models/cooking_step.dart';
import '../../features/recipes/models/ingredient.dart';
import '../../features/recipes/models/recipe.dart';

class GeminiAIService {
  static String? _customApiKey;
  static const String _prefKey = 'user_gemini_api_key_v2';

  static Future<void> loadSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customApiKey = saved.trim();
      } else {
        _customApiKey = null;
      }
    } catch (_) {}
  }

  static Future<void> setApiKey(String key) async {
    _customApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _customApiKey!);
    } catch (_) {}
  }

  static String get apiKey => _customApiKey ?? ApiConfig.geminiApiKey;

  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Multimodal Receipt & Fridge Shelf Scanner with Real Vision & OCR
  static Future<List<ProductItem>> scanReceiptOrFridge({
    Uint8List? imageBytes,
    String? mimeType,
    String? rawOcrText,
    bool isReceipt = true,
  }) async {
    if (!hasApiKey) {
      throw Exception('API-ключ не указан. Добавьте ключ Gemini API.');
    }

    final prompt = isReceipt
        ? '''
Ты — компьютерное зрение и OCR-сканер в кулинарном приложении Sprout.
Твоя задача — внимательно изучить изображение чека или текст: "${rawOcrText ?? ''}".

ПРАВИЛА:
1. Если на фото НЕТ кассового чека, списка покупок или продуктов питания (например, пустая комната, мебель, стена, улица, человек, мышка, ноутбук, случайный предмет), верни ТОЛЬКО пустой JSON-массив: []
2. Если продукты или позиции чека найдены, распознай их и верни строго JSON массив объектов с 2D координатами рамки [ymin, xmin, ymax, xmax] в масштабе от 0 до 1000:
[
  {
    "name": "Томаты",
    "amount": 500,
    "unit": "г",
    "category": "Овощи и зелень",
    "shelfLifeDays": 3,
    "emoji": "🍅",
    "estimatedPrice": 180.0,
    "box2d": [200, 150, 450, 600]
  }
]
3. Не пиши никакого текста, объяснений или markdown кроме чистого JSON массива.
'''
        : '''
Ты — компьютерное зрение для умного холодильника в приложении Sprout.
Твоя задача — найти ВСЕ реальные продукты питания на фото и указать их 2D координаты рамки [ymin, xmin, ymax, xmax] в масштабе от 0 до 1000.

ПРАВИЛА:
1. ВНИМАНИЕ: Если на фото НЕТ продуктов питания, открытого холодильника или еды (например: пустая комната, рабочий стол, мышка, ноутбук, мебель, стена, пол, человек, автомобиль, бытовые приборы), ты ОБЯЗАН вернуть ТОЛЬКО пустой JSON массив: []
2. Не придумывай продукты, если их нет на изображении.
3. Если продукты обнаружены, верни JSON массив с координатами обнаруженного объекта:
[
  {
    "name": "Молоко",
    "amount": 1,
    "unit": "л",
    "category": "Молочные продукты",
    "shelfLifeDays": 4,
    "emoji": "🥛",
    "estimatedPrice": 95.0,
    "box2d": [180, 240, 520, 480]
  }
]
4. Только чистый JSON массив.
''';

    final response = await _callGeminiMultimodal(
      prompt: prompt,
      imageBytes: imageBytes,
      mimeType: mimeType ?? 'image/jpeg',
    );

    final cleanJson = _cleanJsonResponse(response);
    final dynamic decoded = jsonDecode(cleanJson);

    if (decoded is! List) {
      return [];
    }

    final now = DateTime.now();
    return decoded.map((item) {
      final shelfDays = (item['shelfLifeDays'] as num?)?.toInt() ?? 4;
      List<double>? box2d;
      if (item['box2d'] != null && item['box2d'] is List) {
        box2d = (item['box2d'] as List).map((n) => (n as num).toDouble()).toList();
      }

      return ProductItem(
        name: item['name'] as String? ?? 'Продукт',
        amount: (item['amount'] as num?)?.toDouble() ?? 1.0,
        unit: item['unit'] as String? ?? 'шт',
        category: item['category'] as String? ?? 'Продукты',
        addedDate: now,
        expiryDate: now.add(Duration(days: shelfDays)),
        emoji: item['emoji'] as String? ?? '🥑',
        estimatedPrice: (item['estimatedPrice'] as num?)?.toDouble() ?? 120.0,
        box2d: box2d,
      );
    }).toList();
  }

  /// AI Recipe Transformer / Swap using Gemini Flash
  static Future<Recipe> transformRecipe({
    required Recipe originalRecipe,
    required String modificationGoal,
    List<ProductItem>? availableProducts,
  }) async {
    final prompt = '''
Ты — шеф-повар Sprout. Адаптируй рецепт под запрос: "$modificationGoal".
Исходный рецепт: "${originalRecipe.title}".
Ингредиенты: ${originalRecipe.ingredients.map((i) => '${i.name} ${i.amount}${i.unit}').join(', ')}.

Верни ТОЛЬКО валидный JSON:
{
  "title": "${originalRecipe.title} ($modificationGoal)",
  "description": "Краткое аппетитное описание адаптированного блюда",
  "calories": ${originalRecipe.calories},
  "proteinGrams": ${originalRecipe.proteinGrams},
  "fatGrams": ${originalRecipe.fatGrams},
  "carbsGrams": ${originalRecipe.carbsGrams},
  "zeroWasteTip": "Совет по сохранению продуктов"
}
Только чистый JSON.
''';

    final response = await _callGeminiMultimodal(prompt: prompt);
    final Map<String, dynamic> decoded = jsonDecode(_cleanJsonResponse(response));

    return originalRecipe.copyWith(
      id: 'r_trans_${DateTime.now().millisecondsSinceEpoch}',
      title: decoded['title'] as String? ?? '${originalRecipe.title} ($modificationGoal)',
      description: decoded['description'] as String? ?? originalRecipe.description,
      calories: (decoded['calories'] as num?)?.toInt() ?? originalRecipe.calories,
      proteinGrams: (decoded['proteinGrams'] as num?)?.toInt() ?? originalRecipe.proteinGrams,
      fatGrams: (decoded['fatGrams'] as num?)?.toInt() ?? originalRecipe.fatGrams,
      carbsGrams: (decoded['carbsGrams'] as num?)?.toInt() ?? originalRecipe.carbsGrams,
      zeroWasteTip: decoded['zeroWasteTip'] as String? ?? 'Оптимизировано под остатки в холодильнике.',
    );
  }

  /// Generates custom chef recipes from current fridge products
  static Future<List<Recipe>> generateRecipesFromFridge(List<ProductItem> fridgeItems) async {
    if (!hasApiKey) {
      throw Exception('API-ключ не указан. Добавьте ключ Gemini API.');
    }

    final productNames = fridgeItems.map((p) => '${p.name} (${p.amount} ${p.unit})').join(', ');
    final prompt = '''
Ты — профессиональный шеф-повар и нутрициолог в кулинарном приложении Sprout.
У пользователя в холодильнике сейчас есть следующие продукты:
$productNames

Придумай 2-3 аппетитных, простых и реалистичных блюда, которые можно приготовить ПРЕИМУЩЕСТВЕННО из этих продуктов (с минимальным добавлением базовых ингредиентов вроде соли, перца, масла, воды).
Удели особое внимание продуктам с коротким сроком годности (Zero-Waste подход).

Верни строго JSON массив объектов:
[
  {
    "title": "Название блюда",
    "description": "Краткое аппетитное описание (1-2 предложения)",
    "category": "Завтрак",
    "tags": ["Быстро (15 мин)", "Высокий белок", "Zero-Waste"],
    "prepTimeMinutes": 10,
    "cookTimeMinutes": 15,
    "defaultServings": 2,
    "calories": 420,
    "proteinGrams": 28,
    "fatGrams": 18,
    "carbsGrams": 32,
    "imageUrl": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
    "difficulty": "Легко",
    "zeroWasteTip": "Полезный совет по безотходному использованию остатков",
    "ingredients": [
      { "name": "Куриные яйца", "amount": 2, "unit": "шт" }
    ],
    "steps": [
      { "stepNumber": 1, "title": "Подготовка", "instruction": "Что делать", "timerDurationSeconds": 180 }
    ]
  }
]
Только чистый JSON массив без Markdown.
''';

    final response = await _callGeminiMultimodal(prompt: prompt);
    final List<dynamic> decodedList = jsonDecode(_cleanJsonResponse(response));

    final List<Recipe> recipes = [];
    for (final decoded in decodedList) {
      final ingredientsRaw = (decoded['ingredients'] as List<dynamic>?) ?? [];
      final stepsRaw = (decoded['steps'] as List<dynamic>?) ?? [];

      recipes.add(
        Recipe(
          id: 'r_ai_${DateTime.now().millisecondsSinceEpoch}_${recipes.length}',
          title: decoded['title'] as String? ?? 'Блюдо от Шеф-ИИ',
          description: decoded['description'] as String? ?? 'Приготовлено из продуктов вашего холодильника',
          category: decoded['category'] as String? ?? 'Обед',
          tags: (decoded['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? ['Шеф-ИИ', 'Быстро'],
          prepTimeMinutes: (decoded['prepTimeMinutes'] as num?)?.toInt() ?? 5,
          cookTimeMinutes: (decoded['cookTimeMinutes'] as num?)?.toInt() ?? 15,
          defaultServings: (decoded['defaultServings'] as num?)?.toInt() ?? 2,
          calories: (decoded['calories'] as num?)?.toInt() ?? 400,
          proteinGrams: (decoded['proteinGrams'] as num?)?.toInt() ?? 25,
          fatGrams: (decoded['fatGrams'] as num?)?.toInt() ?? 15,
          carbsGrams: (decoded['carbsGrams'] as num?)?.toInt() ?? 30,
          imageUrl: decoded['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
          source: '✨ Шеф-ИИ Sprout',
          difficulty: decoded['difficulty'] as String? ?? 'Легко',
          zeroWasteTip: decoded['zeroWasteTip'] as String?,
          ingredients: ingredientsRaw.map((i) {
            return Ingredient(
              name: i['name'] as String,
              amount: (i['amount'] as num?)?.toDouble() ?? 1.0,
              unit: i['unit'] as String? ?? 'шт',
            );
          }).toList(),
          steps: stepsRaw.map((s) {
            return CookingStep(
              stepNumber: (s['stepNumber'] as num?)?.toInt() ?? 1,
              title: s['title'] as String? ?? 'Шаг',
              instruction: s['instruction'] as String? ?? '',
              timerDurationSeconds: (s['timerDurationSeconds'] as num?)?.toInt(),
            );
          }).toList(),
        ),
      );
    }
    return recipes;
  }

  /// Calls Gemini 3.6 Flash REST API (High performance, lowest cost)
  static Future<String> _callGeminiMultimodal({
    required String prompt,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final key = apiKey;
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$key');

    final List<Map<String, dynamic>> parts = [
      {'text': prompt}
    ];

    if (imageBytes != null) {
      parts.add({
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Encode(imageBytes),
        }
      });
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': key,
      },
      body: jsonEncode({
        'contents': [
          {'parts': parts}
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text;
    } else {
      final errBody = response.body;
      final code = response.statusCode;
      if (code == 401 || code == 403) {
        throw Exception(
            'Ошибка авторизации Gemini ($code). Проверьте ключ API в настройках.');
      }
      throw Exception('Ошибка Gemini API ($code): $errBody');
    }
  }

  static String _cleanJsonResponse(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
