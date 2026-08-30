import 'dart:convert';
import 'package:http/http.dart' as http;
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
          'data': family.toJson(),
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

  /// Update family members in cloud
  static Future<bool> updateFamilyInCloud(String cloudId, FamilyGroup family) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$cloudId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'sprout_fam_${family.inviteCode}',
          'data': family.toJson(),
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
      final existing = await fetchFamilyFromCloud(cloudId);
      if (existing == null) return null;

      final members = List<FamilyMember>.from(existing.members);
      // Avoid duplicate by id or name
      final existingIndex = members.indexWhere((m) => m.id == newMember.id || m.name == newMember.name);
      if (existingIndex != -1) {
        // Update member info
        members[existingIndex] = newMember;
      } else {
        members.add(newMember);
      }

      final updatedFamily = existing.copyWith(members: members);
      await updateFamilyInCloud(cloudId, updatedFamily);
      return updatedFamily;
    } catch (_) {
      return null;
    }
  }
}
