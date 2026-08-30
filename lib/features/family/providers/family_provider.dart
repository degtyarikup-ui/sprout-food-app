import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/telegram_web_app_service.dart';
import '../../profile/models/auth_user.dart';
import '../../profile/providers/auth_provider.dart';
import '../models/family_group.dart';
import '../services/family_cloud_service.dart';

class FamilyNotifier extends StateNotifier<FamilyGroup?> {
  static const _kFamilyKey = 'sprout_family_group_v2';
  final Ref _ref;

  FamilyNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    await _loadFromStorage();

    // 1. If we have a cloudId, refresh from cloud
    if (state != null && state!.cloudId != null) {
      await refreshFromCloud();
    }

    // 2. Check if launched via Telegram invite link (e.g. start_param = join_ff808181...)
    final startParam = TelegramWebAppService.getStartParam();
    if (startParam != null && startParam.startsWith('join_')) {
      final codeOrCloudId = startParam.replaceAll('join_', '').trim();
      final user = _ref.read(authProvider);
      await joinFamilyByCode(codeOrCloudId, currentUser: user);
    }
  }

  Future<void> refreshFromCloud() async {
    if (state == null || state!.cloudId == null) return;
    try {
      final cloudFamily = await FamilyCloudService.fetchFamilyFromCloud(state!.cloudId!);
      if (cloudFamily != null) {
        state = cloudFamily.copyWith(cloudId: state!.cloudId);
        await _persist(state!);
      }
    } catch (_) {}
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kFamilyKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = FamilyGroup.fromJson(decoded);
      }
    } catch (_) {}
  }

  String _generateInviteCode() {
    final random = Random();
    final number = 100 + random.nextInt(900);
    return 'SPROUT-$number';
  }

  Future<FamilyGroup> createFamily(
    String familyName, {
    AuthUser? currentUser,
  }) async {
    final creatorName = currentUser?.displayName ?? 'Сергей';
    final creatorAvatar = currentUser?.photoUrl;
    final code = _generateInviteCode();

    var family = FamilyGroup(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
      name: familyName.trim().isNotEmpty ? familyName.trim() : 'Семья $creatorName',
      inviteCode: code,
      createdAt: DateTime.now(),
      members: [
        FamilyMember(
          id: currentUser?.id ?? 'creator_user_1',
          name: creatorName,
          avatarUrl: creatorAvatar,
          role: 'Создатель',
          isOnline: true,
          joinedAt: DateTime.now(),
        ),
      ],
    );

    // Save to Cloud
    final cloudId = await FamilyCloudService.createFamilyInCloud(family);
    if (cloudId != null) {
      family = family.copyWith(cloudId: cloudId);
    }

    state = family;
    await _persist(family);
    return family;
  }

  Future<bool> joinFamilyByCode(
    String codeOrLink, {
    AuthUser? currentUser,
  }) async {
    // Clean input code or extract from full link
    String code = codeOrLink.trim();
    if (code.contains('join_')) {
      code = code.split('join_').last.trim();
    } else if (code.contains('/join/')) {
      code = code.split('/join/').last.trim();
    }

    final joinerName = currentUser?.displayName ?? 'Партнер';
    final joinerAvatar = currentUser?.photoUrl; // null if no photo

    final joinerMember = FamilyMember(
      id: currentUser?.id ?? 'joined_member_${DateTime.now().millisecondsSinceEpoch}',
      name: joinerName,
      avatarUrl: joinerAvatar,
      role: 'Партнер',
      isOnline: true,
      joinedAt: DateTime.now(),
    );

    // Try joining via Cloud if it's a cloud ID
    if (code.length > 10) {
      final cloudFamily = await FamilyCloudService.joinFamilyInCloud(code, joinerMember);
      if (cloudFamily != null) {
        final finalFamily = cloudFamily.copyWith(cloudId: code);
        state = finalFamily;
        await _persist(finalFamily);
        return true;
      }
    }

    // Local fallback if offline
    final updatedMembers = [
      FamilyMember(
        id: 'creator_partner_1',
        name: 'Сергей Дегтярик',
        avatarUrl: null,
        role: 'Создатель',
        isOnline: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      joinerMember,
    ];

    final joinedFamily = FamilyGroup(
      id: 'fam_shared_882',
      name: 'Наша семья',
      inviteCode: code.isNotEmpty ? code : 'SPROUT-882',
      cloudId: code.length > 10 ? code : null,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      members: updatedMembers,
    );

    state = joinedFamily;
    await _persist(joinedFamily);
    return true;
  }

  Future<void> addDemoPartner() async {
    if (state == null) return;
    final currentMembers = List<FamilyMember>.from(state!.members);
    if (currentMembers.length >= 2) return;

    currentMembers.add(
      FamilyMember(
        id: 'partner_demo_2',
        name: 'Партнер',
        avatarUrl: null, // clean initials avatar
        role: 'Партнер',
        isOnline: true,
        joinedAt: DateTime.now(),
      ),
    );

    final updated = state!.copyWith(members: currentMembers);
    state = updated;
    await _persist(updated);

    if (state!.cloudId != null) {
      await FamilyCloudService.updateFamilyInCloud(state!.cloudId!, updated);
    }
  }

  Future<void> leaveFamily() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kFamilyKey);
    } catch (_) {}
  }

  Future<void> _persist(FamilyGroup family) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kFamilyKey, jsonEncode(family.toJson()));
    } catch (_) {}
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyGroup?>((ref) {
  return FamilyNotifier(ref);
});
