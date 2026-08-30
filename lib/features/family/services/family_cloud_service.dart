import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../fridge/models/product_item.dart';
import '../../grocery/models/grocery_item.dart';
import '../../meal_planner/models/meal_plan_day.dart';
import '../models/family_group.dart';

class FamilyCloudService {
  static const _baseUrl = 'https://api.restful-api.dev/objects';

  static String cleanCloudId(String rawId) {
    String id = rawId.trim();
    if (id.contains('join_')) {
      id = id.split('join_').last.trim();
    } else if (id.contains('/join/')) {
      id = id.split('/join/').last.trim();
    }
    if (id.contains('startapp=')) {
      id = id.split('startapp=').last.split('&').first.trim();
      if (id.startsWith('join_')) {
        id = id.substring(5).trim();
      }
    }
    if (id.contains('?')) {
      id = id.split('?').first.trim();
    }
    return id;
  }

  /// Save newly created family to cloud and return the cloud object ID
  static Future<String?> createFamilyInCloud(
    FamilyGroup family, {
    List<ProductItem>? fridge,
    List<GroceryItem>? grocery,
    List<MealPlanDay>? mealPlan,
  }) async {
    try {
      final payload = {
        'name': 'sprout_fam_${family.inviteCode}',
        'data': {
          ...family.toJson(),
          'fridge': (fridge ?? []).map((p) => p.toJson()).toList(),
          'grocery': (grocery ?? []).map((g) => g.toJson()).toList(),
          'mealPlan': (mealPlan ?? []).map((m) => m.toJson()).toList(),
          'version': 1,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<dynamic, dynamic>;
        final id = decoded['id'] as String?;
        return id;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FamilyCloudService] createFamilyInCloud error: $e');
    }
    return null;
  }

  /// Fetch full cloud package: family, fridge, grocery, mealPlan
  static Future<Map<String, dynamic>?> fetchFullCloudData(String rawCloudId) async {
    final cloudId = cleanCloudId(rawCloudId);
    if (cloudId.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$cloudId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<dynamic, dynamic>;
        if (decoded.containsKey('data')) {
          final data = Map<String, dynamic>.from(decoded['data'] as Map);
          final family = FamilyGroup.fromJson(data).copyWith(cloudId: cloudId);

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
            'lastUpdated': (data['lastUpdated'] as num?)?.toInt() ?? 0,
          };
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FamilyCloudService] fetchFullCloudData error for $cloudId: $e');
    }
    return null;
  }

  /// Update family, shared inventory, and meal plan in cloud without losing concurrent data
  static Future<bool> updateCloudData(
    String rawCloudId, {
    FamilyGroup? family,
    List<ProductItem>? fridge,
    List<GroceryItem>? grocery,
    List<MealPlanDay>? mealPlan,
  }) async {
    final cloudId = cleanCloudId(rawCloudId);
    if (cloudId.isEmpty) return false;

    try {
      // 1. Always fetch latest cloud state to avoid overwriting partner's concurrent changes
      final existingData = await fetchFullCloudData(cloudId);

      // 2. Resolve family and merge members
      FamilyGroup currentFamily;
      if (family != null) {
        if (existingData != null && existingData.containsKey('family')) {
          final cloudFamily = existingData['family'] as FamilyGroup;
          // Union members by ID or name
          final memberMap = <String, FamilyMember>{};
          for (final m in cloudFamily.members) {
            final key = m.id.isNotEmpty ? m.id : m.name;
            memberMap[key] = m;
          }
          for (final m in family.members) {
            final key = m.id.isNotEmpty ? m.id : m.name;
            memberMap[key] = m;
          }
          currentFamily = family.copyWith(
            cloudId: cloudId,
            members: memberMap.values.toList(),
          );
        } else {
          currentFamily = family.copyWith(cloudId: cloudId);
        }
      } else if (existingData != null && existingData.containsKey('family')) {
        currentFamily = existingData['family'] as FamilyGroup;
      } else {
        return false;
      }

      // 3. Resolve stores (keep existing if null, update if provided)
      final currentFridge = fridge ?? (existingData?['fridge'] as List<ProductItem>? ?? []);
      final currentGrocery = grocery ?? (existingData?['grocery'] as List<GroceryItem>? ?? []);
      final currentMealPlan = mealPlan ?? (existingData?['mealPlan'] as List<MealPlanDay>? ?? []);
      final currentVersion = ((existingData?['version'] as num?)?.toInt() ?? 1) + 1;

      final payload = {
        'name': 'sprout_fam_${currentFamily.inviteCode}',
        'data': {
          ...currentFamily.toJson(),
          'cloudId': cloudId,
          'fridge': currentFridge.map((p) => p.toJson()).toList(),
          'grocery': currentGrocery.map((g) => g.toJson()).toList(),
          'mealPlan': currentMealPlan.map((m) => m.toJson()).toList(),
          'version': currentVersion,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/$cloudId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('[FamilyCloudService] updateCloudData error for $cloudId: $e');
      return false;
    }
  }

  /// Join a member to an existing cloud family
  static Future<FamilyGroup?> joinFamilyInCloud(String rawCloudId, FamilyMember newMember) async {
    final cloudId = cleanCloudId(rawCloudId);
    if (cloudId.isEmpty) return null;

    try {
      final full = await fetchFullCloudData(cloudId);
      if (full == null) return null;

      final existing = full['family'] as FamilyGroup;
      final members = List<FamilyMember>.from(existing.members);

      final existingIndex = members.indexWhere((m) =>
          (m.id.isNotEmpty && m.id == newMember.id) ||
          m.name.trim().toLowerCase() == newMember.name.trim().toLowerCase());

      if (existingIndex != -1) {
        members[existingIndex] = newMember;
      } else {
        members.add(newMember);
      }

      final updatedFamily = existing.copyWith(
        cloudId: cloudId,
        members: members,
      );

      final success = await updateCloudData(
        cloudId,
        family: updatedFamily,
        fridge: full['fridge'] as List<ProductItem>?,
        grocery: full['grocery'] as List<GroceryItem>?,
        mealPlan: full['mealPlan'] as List<MealPlanDay>?,
      );

      if (success) {
        return updatedFamily;
      }
      return updatedFamily;
    } catch (e) {
      // ignore: avoid_print
      print('[FamilyCloudService] joinFamilyInCloud error for $cloudId: $e');
      return null;
    }
  }
}
