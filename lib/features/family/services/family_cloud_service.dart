import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../fridge/models/product_item.dart';
import '../../grocery/models/grocery_item.dart';
import '../models/family_group.dart';

class FamilyCloudService {
  static const _baseUrl = 'https://api.restful-api.dev/objects';

  /// Save newly created family to cloud and return the cloud object ID
  static Future<String?> createFamilyInCloud(FamilyGroup family) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'sprout_fam_${family.inviteCode}',
          'data': {
            ...family.toJson(),
            'fridge': [],
            'grocery': [],
          },
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch family from cloud by cloudId
  static Future<FamilyGroup?> fetchFamilyFromCloud(String cloudId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$cloudId'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded.containsKey('data')) {
          final data = decoded['data'] as Map<String, dynamic>;
          return FamilyGroup.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch full cloud package: family, fridge, grocery
  static Future<Map<String, dynamic>?> fetchFullCloudData(String cloudId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$cloudId'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded.containsKey('data')) {
          final data = decoded['data'] as Map<String, dynamic>;
          final family = FamilyGroup.fromJson(data);

          final List<ProductItem> fridge = (data['fridge'] as List<dynamic>?)
                  ?.map((item) => ProductItem.fromJson(item as Map<String, dynamic>))
                  .toList() ??
              [];

          final List<GroceryItem> grocery = (data['grocery'] as List<dynamic>?)
                  ?.map((item) => GroceryItem.fromJson(item as Map<String, dynamic>))
                  .toList() ??
              [];

          return {
            'family': family,
            'fridge': fridge,
            'grocery': grocery,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Update family and shared inventory in cloud
  static Future<bool> updateCloudData(
    String cloudId, {
    FamilyGroup? family,
    List<ProductItem>? fridge,
    List<GroceryItem>? grocery,
  }) async {
    try {
      // First fetch current data to avoid overwriting unchanged sections
      final existingData = await fetchFullCloudData(cloudId);
      final currentFamily = family ?? existingData?['family'] as FamilyGroup?;
      final currentFridge = fridge ?? existingData?['fridge'] as List<ProductItem>? ?? [];
      final currentGrocery = grocery ?? existingData?['grocery'] as List<GroceryItem>? ?? [];

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
      await updateCloudData(cloudId, family: updatedFamily);
      return updatedFamily;
    } catch (_) {
      return null;
    }
  }
}
