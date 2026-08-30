import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/telegram_web_app_service.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../grocery/models/grocery_item.dart';
import '../../grocery/providers/grocery_provider.dart';
import '../../profile/models/auth_user.dart';
import '../../profile/providers/auth_provider.dart';
import '../models/family_group.dart';
import '../services/family_cloud_service.dart';

class FamilyNotifier extends StateNotifier<FamilyGroup?> {
  static const _kFamilyKey = 'sprout_family_group_v3';
  final Ref _ref;
  Timer? _autoSyncTimer;

  FamilyNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    await _loadFromStorage();

    // 1. If state exists, ensure cloudId is attached and start auto-sync
    if (state != null) {
      if (state!.cloudId == null || state!.cloudId!.isEmpty) {
        try {
          final cloudId = await FamilyCloudService.createFamilyInCloud(state!);
          if (cloudId != null) {
            state = state!.copyWith(cloudId: cloudId);
            await _persist(state!);
          }
        } catch (_) {}
      }

      await refreshFromCloud();
      _startAutoSync();
    }

    // 2. Check if launched via Telegram invite link (e.g. start_param = join_ff808181...)
    final startParam = TelegramWebAppService.getStartParam();
    if (startParam != null && startParam.startsWith('join_')) {
      final codeOrCloudId = startParam.replaceAll('join_', '').trim();
      final user = _ref.read(authProvider);
      await joinFamilyByCode(codeOrCloudId, currentUser: user);
    }
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (state != null && state!.cloudId != null && state!.cloudId!.isNotEmpty) {
        refreshFromCloud();
      }
    });
  }

  Future<void> refreshFromCloud() async {
    if (state == null || state!.cloudId == null || state!.cloudId!.isEmpty) return;
    try {
      final fullData = await FamilyCloudService.fetchFullCloudData(state!.cloudId!);
      if (fullData != null) {
        if (fullData.containsKey('family')) {
          final cloudFamily = fullData['family'] as FamilyGroup;
          // Check if state actually updated
          if (cloudFamily.members.length != state!.members.length ||
              cloudFamily.name != state!.name) {
            state = cloudFamily.copyWith(cloudId: state!.cloudId);
            await _persist(state!);
          }
        }
        if (fullData.containsKey('fridge')) {
          final cloudFridge = fullData['fridge'] as List<ProductItem>;
          _ref.read(fridgeProvider.notifier).setProductsFromCloud(cloudFridge);
        }
        if (fullData.containsKey('grocery')) {
          final cloudGrocery = fullData['grocery'] as List<GroceryItem>;
          _ref.read(groceryProvider.notifier).setGroceryFromCloud(cloudGrocery);
        }
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

    // Save to Cloud with current fridge and grocery
    final currentFridge = _ref.read(fridgeProvider);
    final currentGrocery = _ref.read(groceryProvider);

    final cloudId = await FamilyCloudService.createFamilyInCloud(family);
    if (cloudId != null) {
      family = family.copyWith(cloudId: cloudId);
      await FamilyCloudService.updateCloudData(
        cloudId,
        family: family,
        fridge: currentFridge,
        grocery: currentGrocery,
      );
    }

    state = family;
    await _persist(family);
    _startAutoSync();
    return family;
  }

  Future<bool> joinFamilyByCode(
    String codeOrLink, {
    AuthUser? currentUser,
  }) async {
    String code = codeOrLink.trim();
    if (code.contains('join_')) {
      code = code.split('join_').last.trim();
    } else if (code.contains('/join/')) {
      code = code.split('/join/').last.trim();
    }

    final joinerName = currentUser?.displayName ?? 'Партнер';
    final joinerAvatar = currentUser?.photoUrl;

    final joinerMember = FamilyMember(
      id: currentUser?.id ?? 'joined_member_${DateTime.now().millisecondsSinceEpoch}',
      name: joinerName,
      avatarUrl: joinerAvatar,
      role: 'Партнер',
      isOnline: true,
      joinedAt: DateTime.now(),
    );

    // Always attempt cloud join first
    final cloudFamily = await FamilyCloudService.joinFamilyInCloud(code, joinerMember);
    if (cloudFamily != null) {
      final finalFamily = cloudFamily.copyWith(cloudId: code);
      state = finalFamily;
      await _persist(finalFamily);

      // Fetch shared inventory
      final fullData = await FamilyCloudService.fetchFullCloudData(code);
      if (fullData != null) {
        if (fullData.containsKey('fridge')) {
          _ref.read(fridgeProvider.notifier).setProductsFromCloud(fullData['fridge'] as List<ProductItem>);
        }
        if (fullData.containsKey('grocery')) {
          _ref.read(groceryProvider.notifier).setGroceryFromCloud(fullData['grocery'] as List<GroceryItem>);
        }
      }
      _startAutoSync();
      return true;
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
      cloudId: code.length > 5 ? code : null,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      members: updatedMembers,
    );

    state = joinedFamily;
    await _persist(joinedFamily);
    _startAutoSync();
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
        avatarUrl: null,
        role: 'Партнер',
        isOnline: true,
        joinedAt: DateTime.now(),
      ),
    );

    final updated = state!.copyWith(members: currentMembers);
    state = updated;
    await _persist(updated);

    if (state!.cloudId != null) {
      await FamilyCloudService.updateCloudData(state!.cloudId!, family: updated);
    }
  }

  Future<void> leaveFamily() async {
    _autoSyncTimer?.cancel();
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

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyGroup?>((ref) {
  return FamilyNotifier(ref);
});
