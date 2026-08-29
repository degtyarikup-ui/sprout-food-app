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
  static const String _prefKey = 'user_gemini_api_key';

  static Future<void> loadSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) {
        _customApiKey = saved;
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
1. Если на фото НЕТ кассового чека, списка покупок или продуктов питания (например, пустая комната, мебель, стена, улица, человек, случайный предмет), верни ТОЛЬКО пустой JSON-массив: []
2. Если продукты или позиции чека найдены, распознай их и верни строго JSON массив объектов:
[
  {
    "name": "Томаты",
    "amount": 500,
    "unit": "г",
    "category": "Овощи и зелень",
    "shelfLifeDays": 3,
    "emoji": "🍅",
    "estimatedPrice": 180.0
  }
]
3. Не пиши никакого текста, объяснений или markdown кроме чистого JSON массива.
'''
        : '''
Ты — компьютерное зрение для холодильника в приложении Sprout.
Твоя задача — внимательно определить ВСЕ реальные продукты питания на фото.

ПРАВИЛА:
1. ВНИМАНИЕ: Если на фото НЕТ продуктов питания, открытого холодильника или еды (например: пустая комната, мебель, стена, пол, человек, автомобиль, бытовые приборы), ты ОБЯЗАН вернуть ТОЛЬКО пустой JSON массив: []
2. Не придумывай продукты, если их нет на изображении.
3. Если продукты обнаружены, верни JSON массив:
[
  {
    "name": "Молоко",
    "amount": 1,
    "unit": "л",
    "category": "Молочные продукты",
    "shelfLifeDays": 4,
    "emoji": "🥛",
    "estimatedPrice": 95.0
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
      return ProductItem(
        name: item['name'] as String? ?? 'Продукт',
        amount: (item['amount'] as num?)?.toDouble() ?? 1.0,
        unit: item['unit'] as String? ?? 'шт',
        category: item['category'] as String? ?? 'Продукты',
        addedDate: now,
        expiryDate: now.add(Duration(days: shelfDays)),
        emoji: item['emoji'] as String? ?? '🥑',
        estimatedPrice: (item['estimatedPrice'] as num?)?.toDouble() ?? 120.0,
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

  /// AI Social Video / Link Importer using Gemini Flash
  static Future<Recipe> importRecipeFromSocialMedia({
    required String linkOrText,
  }) async {
    final prompt = '''
Ты — ИИ-распознаватель видеорецептов Sprout.
Пользователь передал ссылку/текст видео: "$linkOrText".
Создай структурированный пошаговый рецепт.
Верни ТОЛЬКО валидный JSON:
{
  "title": "Хрустящий авокадо-тост с яйцом пашот",
  "description": "Аппетитный рецепт из соцсетей за 10 минут",
  "category": "Завтрак",
  "prepTimeMinutes": 5,
  "cookTimeMinutes": 5,
  "calories": 410,
  "proteinGrams": 22,
  "fatGrams": 24,
  "carbsGrams": 20,
  "ingredients": [
    {"name": "Яйцо куриное", "amount": 1.0, "unit": "шт"},
    {"name": "Авокадо", "amount": 0.5, "unit": "шт"},
    {"name": "Цельнозерновой хлеб", "amount": 1.0, "unit": "ломтик"}
  ],
  "steps": [
    {"stepNumber": 1, "title": "Поджарка тоста", "instruction": "Обжарьте хлеб до золотистой корочки.", "timerDurationSeconds": 120},
    {"stepNumber": 2, "title": "Яйцо пашот", "instruction": "Варите яйцо 3 минуты в слабо кипящей воде.", "timerDurationSeconds": 180},
    {"stepNumber": 3, "title": "Сборка", "instruction": "Выложите авокадо на тост и положите сверху яйцо."}
  ]
}
Только JSON.
''';

    final response = await _callGeminiMultimodal(prompt: prompt);
    final Map<String, dynamic> decoded = jsonDecode(_cleanJsonResponse(response));

    final ingredientsRaw = (decoded['ingredients'] as List<dynamic>?) ?? [];
    final stepsRaw = (decoded['steps'] as List<dynamic>?) ?? [];

    return Recipe(
      id: 'r_import_${DateTime.now().millisecondsSinceEpoch}',
      title: decoded['title'] as String? ?? 'Рецепт из соцсетей',
      description: decoded['description'] as String? ?? 'Импортировано из видео',
      category: decoded['category'] as String? ?? 'Завтрак',
      tags: ['Быстро', 'Из видео', '10 мин'],
      prepTimeMinutes: (decoded['prepTimeMinutes'] as num?)?.toInt() ?? 5,
      cookTimeMinutes: (decoded['cookTimeMinutes'] as num?)?.toInt() ?? 5,
      defaultServings: 1,
      calories: (decoded['calories'] as num?)?.toInt() ?? 410,
      proteinGrams: (decoded['proteinGrams'] as num?)?.toInt() ?? 22,
      fatGrams: (decoded['fatGrams'] as num?)?.toInt() ?? 24,
      carbsGrams: (decoded['carbsGrams'] as num?)?.toInt() ?? 20,
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
      source: 'Импортировано из видео',
      difficulty: 'Легко',
      zeroWasteTip: 'Храните половинку авокадо с косточкой в контейнере.',
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
    );
  }

  /// Calls Gemini 1.5 Flash REST API (High performance, lowest cost)
  static Future<String> _callGeminiMultimodal({
    required String prompt,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final key = apiKey;
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key');

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
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
            'Ошибка авторизации Gemini ($response.statusCode). Требуется API-ключ Gemini (начинается на AIzaSy...) из https://aistudio.google.com/app/apikey');
      }
      throw Exception('Ошибка Gemini API (${response.statusCode}): $errBody');
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
