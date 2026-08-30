import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../fridge/models/product_item.dart';
import '../../grocery/models/grocery_item.dart';
import '../../meal_planner/models/meal_plan_day.dart';
import '../models/family_group.dart';

class FamilyCloudService {
  static const _baseUrl = 'https://api.restful-api.dev/objects';

  /// Save newly created family to cloud and return the cloud object ID
  static Future<String?> createFamilyInCloud(
    FamilyGroup family, {
    List<ProductItem>? fridge,
    List<GroceryItem>? grocery,
    List<MealPlanDay>? mealPlan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'sprout_fam_${family.inviteCode}',
          'data': {
            ...family.toJson(),
            'fridge': (fridge ?? []).map((p) => p.toJson()).toList(),
            'grocery': (grocery ?? []).map((g) => g.toJson()).toList(),
            'mealPlan': (mealPlan ?? []).map((m) => m.toJson()).toList(),
            'version': 1,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          },
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<dynamic, dynamic>;
        return decoded['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch full cloud package: family, fridge, grocery, mealPlan
  static Future<Map<String, dynamic>?> fetchFullCloudData(String cloudId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$cloudId'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<dynamic, dynamic>;
        if (decoded.containsKey('data')) {
          final data = Map<String, dynamic>.from(decoded['data'] as Map);
          final family = FamilyGroup.fromJson(data);

          final List<ProductItem> fridge = (data['fridge'] as List<dynamic>?)
                  ?.map((item) => ProductItem.fromJson(item as Map))
                  .toList() ??
              [];

          final List<GroceryItem> grocery = (data['grocery'] as List<dynamic>?)
                  ?.map((item) => GroceryItem.fromJson(item as Map))
                  .toList() ??
              [];

          final List<MealPlanDay> mealPlan = (data['mealPlan'] as List<dynamic>?)
                  ?.map((item) => MealPlanDay.fromJson(item as Map))
                  .toList() ??
              [];

          return {
            'family': family,
            'fridge': fridge,
            'grocery': grocery,
            'mealPlan': mealPlan,
            'version': (data['version'] as num?)?.toInt() ?? 1,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Update family, shared inventory, and meal plan in cloud
  static Future<bool> updateCloudData(
    String cloudId, {
    FamilyGroup? family,
    List<ProductItem>? fridge,
    List<GroceryItem>? grocery,
    List<MealPlanDay>? mealPlan,
  }) async {
    try {
      Map<String, dynamic>? existingData;
      if (family == null || fridge == null || grocery == null || mealPlan == null) {
        existingData = await fetchFullCloudData(cloudId);
      }

      final currentFamily = family ?? existingData?['family'] as FamilyGroup?;
      final currentFridge = fridge ?? existingData?['fridge'] as List<ProductItem>? ?? [];
      final currentGrocery = grocery ?? existingData?['grocery'] as List<GroceryItem>? ?? [];
      final currentMealPlan = mealPlan ?? existingData?['mealPlan'] as List<MealPlanDay>? ?? [];
      final currentVersion = ((existingData?['version'] as num?)?.toInt() ?? 1) + 1;

      if (currentFamily == null) return false;

      final response = await http.put(
        Uri.parse('$_baseUrl/$cloudId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'sprout_fam_${currentFamily.inviteCode}',
          'data': {
            ...currentFamily.toJson(),
            'fridge': currentFridge.map((p) => p.toJson()).toList(),
            'grocery': currentGrocery.map((g) => g.toJson()).toList(),
            'mealPlan': currentMealPlan.map((m) => m.toJson()).toList(),
            'version': currentVersion,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          },
        }),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Join a member to an existing cloud family
  static Future<FamilyGroup?> joinFamilyInCloud(String cloudId, FamilyMember newMember) async {
    try {
      final full = await fetchFullCloudData(cloudId);
      if (full == null) return null;

      final existing = full['family'] as FamilyGroup;
      final members = List<FamilyMember>.from(existing.members);

      final existingIndex = members.indexWhere((m) => m.id == newMember.id || m.name == newMember.name);
      if (existingIndex != -1) {
        members[existingIndex] = newMember;
      } else {
        members.add(newMember);
      }

      final updatedFamily = existing.copyWith(members: members);
      await updateCloudData(
        cloudId,
        family: updatedFamily,
        fridge: full['fridge'] as List<ProductItem>?,
        grocery: full['grocery'] as List<GroceryItem>?,
        mealPlan: full['mealPlan'] as List<MealPlanDay>?,
      );
      return updatedFamily;
    } catch (_) {
      return null;
    }
  }
}
