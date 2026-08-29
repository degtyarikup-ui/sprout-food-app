import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/fridge/models/product_item.dart';
import '../../features/grocery/models/grocery_item.dart';
import '../../features/meal_planner/models/meal_plan_day.dart';
import '../../features/analytics/models/eco_savings_stat.dart';

class LocalStorageService {
  static const String _kFridgeKey = 'sprout_fridge_items';
  static const String _kMealPlanKey = 'sprout_meal_plan';
  static const String _kGroceryKey = 'sprout_grocery_items';
  static const String _kEcoStatsKey = 'sprout_eco_stats';
  static const String _kGeminiApiKey = 'sprout_gemini_api_key';

  static Future<void> saveFridgeItems(List<ProductItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_kFridgeKey, jsonEncode(jsonList));
  }

  static Future<List<ProductItem>?> loadFridgeItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFridgeKey);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => ProductItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGroceryItems(List<GroceryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_kGroceryKey, jsonEncode(jsonList));
  }

  static Future<List<GroceryItem>?> loadGroceryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGroceryKey);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMealPlan(List<MealPlanDay> days) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = days.map((e) => e.toJson()).toList();
    await prefs.setString(_kMealPlanKey, jsonEncode(jsonList));
  }

  static Future<List<MealPlanDay>?> loadMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMealPlanKey);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => MealPlanDay.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveEcoStats(EcoSavingsStat stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEcoStatsKey, jsonEncode(stats.toJson()));
  }

  static Future<EcoSavingsStat?> loadEcoStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kEcoStatsKey);
    if (raw == null) return null;
    try {
      return EcoSavingsStat.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGeminiApiKey, key);
  }

  static Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kGeminiApiKey);
  }
}
