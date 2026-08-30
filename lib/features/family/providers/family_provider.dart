import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/telegram_web_app_service.dart';
import '../../profile/models/auth_user.dart';
import '../../profile/providers/auth_provider.dart';
import '../models/family_group.dart';

class FamilyNotifier extends StateNotifier<FamilyGroup?> {
  static const _kFamilyKey = 'sprout_family_group_v1';

  FamilyNotifier(Ref ref) : super(null) {
    _init(ref);
  }

  Future<void> _init(Ref ref) async {
    await _loadFromStorage();

    // Check if launched via Telegram invite link (e.g. start_param = join_SPROUT-882)
    final startParam = TelegramWebAppService.getStartParam();
    if (startParam != null && startParam.startsWith('join_')) {
      final code = startParam.replaceAll('join_', '').trim();
      final user = ref.read(authProvider);
      await joinFamilyByCode(code, currentUser: user);
    }
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

    final family = FamilyGroup(
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
    code = code.toUpperCase();

    final joinerName = currentUser?.displayName ?? 'Партнер';
    final joinerAvatar = currentUser?.photoUrl ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=$joinerName';

    // Create or join shared family instance
    final updatedMembers = [
      FamilyMember(
        id: 'creator_partner_1',
        name: 'Сергей Дегтярик',
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=SergeiDegtyarik',
        role: 'Создатель',
        isOnline: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      FamilyMember(
        id: currentUser?.id ?? 'joined_member_${DateTime.now().millisecondsSinceEpoch}',
        name: joinerName,
        avatarUrl: joinerAvatar,
        role: 'Партнер',
        isOnline: true,
        joinedAt: DateTime.now(),
      ),
    ];

    final joinedFamily = FamilyGroup(
      id: 'fam_shared_882',
      name: 'Наша семья',
      inviteCode: code.isNotEmpty ? code : 'SPROUT-882',
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
        name: 'Анна',
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Anna',
        role: 'Партнер',
        isOnline: true,
        joinedAt: DateTime.now(),
      ),
    );

    final updated = state!.copyWith(members: currentMembers);
    state = updated;
    await _persist(updated);
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
