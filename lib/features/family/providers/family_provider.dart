import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/telegram_web_app_service.dart';
import '../../fridge/models/product_item.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../grocery/models/grocery_item.dart';
import '../../grocery/providers/grocery_provider.dart';
import '../../meal_planner/models/meal_plan_day.dart';
import '../../meal_planner/providers/meal_planner_provider.dart';
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
          final currentFridge = _ref.read(fridgeProvider);
          final currentGrocery = _ref.read(groceryProvider);
          final currentMealPlan = _ref.read(mealPlannerProvider);

          final cloudId = await FamilyCloudService.createFamilyInCloud(
            state!,
            fridge: currentFridge,
            grocery: currentGrocery,
            mealPlan: currentMealPlan,
          );
          if (cloudId != null) {
            state = state!.copyWith(cloudId: cloudId, inviteCode: cloudId);
            await _persist(state!);
          }
        } catch (e) {
          // ignore: avoid_print
          print('[FamilyNotifier] _init create in cloud error: $e');
        }
      }

      await refreshFromCloud();
      _startAutoSync();
    }

    // 2. Check if launched via Telegram invite link (e.g. start_param = join_ff808181... or startapp=join_...)
    final startParam = TelegramWebAppService.getStartParam();
    if (startParam != null && startParam.trim().isNotEmpty) {
      final cleanCode = FamilyCloudService.cleanCloudId(startParam);
      if (cleanCode.isNotEmpty && (state == null || state!.cloudId != cleanCode)) {
        await joinFamilyByCode(cleanCode);
      }
    }
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
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
        // 1. Sync family group & members
        if (fullData.containsKey('family')) {
          final cloudFamily = fullData['family'] as FamilyGroup;
          if (cloudFamily.members.length != state!.members.length ||
              cloudFamily.name != state!.name ||
              _membersChanged(cloudFamily.members, state!.members)) {
            state = cloudFamily.copyWith(
              cloudId: state!.cloudId,
              inviteCode: state!.cloudId,
            );
            await _persist(state!);
          }
        }

        // 2. Sync fridge
        if (fullData.containsKey('fridge')) {
          final cloudFridge = fullData['fridge'] as List<ProductItem>;
          _ref.read(fridgeProvider.notifier).setProductsFromCloud(cloudFridge);
        }

        // 3. Sync grocery
        if (fullData.containsKey('grocery')) {
          final cloudGrocery = fullData['grocery'] as List<GroceryItem>;
          _ref.read(groceryProvider.notifier).setGroceryFromCloud(cloudGrocery);
        }

        // 4. Sync meal plan
        if (fullData.containsKey('mealPlan')) {
          final cloudMealPlan = fullData['mealPlan'] as List<MealPlanDay>;
          if (cloudMealPlan.isNotEmpty) {
            _ref.read(mealPlannerProvider.notifier).setMealPlanFromCloud(cloudMealPlan);
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FamilyNotifier] refreshFromCloud error: $e');
    }
  }

  bool _membersChanged(List<FamilyMember> a, List<FamilyMember> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].name != b[i].name ||
          a[i].avatarUrl != b[i].avatarUrl) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'sprout_family_group_v3',
        'sprout_family_group_v4',
        'sprout_family_group_v2',
        'sprout_family_group_v1'
      ]) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<dynamic, dynamic>;
          state = FamilyGroup.fromJson(decoded);
          if (state != null) {
            await _persist(state!);
            break;
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FamilyNotifier] _loadFromStorage error: $e');
    }
  }

  Future<FamilyGroup> createFamily(
    String familyName, {
    AuthUser? currentUser,
  }) async {
    final authUser = currentUser ?? _ref.read(authProvider);
    final tgUser = TelegramWebAppService.getTelegramUser();

    final creatorName = authUser?.displayName ?? tgUser?.fullName ?? 'Сергей';
    final creatorAvatar = authUser?.photoUrl ?? tgUser?.photoUrl;
    final creatorId = authUser?.id ?? (tgUser != null ? 'tg_${tgUser.id}' : 'creator_user_1');

    var family = FamilyGroup(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
      name: familyName.trim().isNotEmpty ? familyName.trim() : 'Семья $creatorName',
      inviteCode: '',
      createdAt: DateTime.now(),
      members: [
        FamilyMember(
          id: creatorId,
          name: creatorName,
          avatarUrl: creatorAvatar,
          role: 'Создатель',
          isOnline: true,
          joinedAt: DateTime.now(),
        ),
      ],
    );

    // Save to Cloud with current fridge, grocery, and meal plan
    final currentFridge = _ref.read(fridgeProvider);
    final currentGrocery = _ref.read(groceryProvider);
    final currentMealPlan = _ref.read(mealPlannerProvider);

    final cloudId = await FamilyCloudService.createFamilyInCloud(
      family,
      fridge: currentFridge,
      grocery: currentGrocery,
      mealPlan: currentMealPlan,
    );

    if (cloudId != null) {
      family = family.copyWith(cloudId: cloudId, inviteCode: cloudId);
    } else {
      final fallbackId = 'fam_${DateTime.now().millisecondsSinceEpoch}';
      family = family.copyWith(cloudId: fallbackId, inviteCode: fallbackId);
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
    final code = FamilyCloudService.cleanCloudId(codeOrLink);
    if (code.isEmpty) return false;

    final authUser = currentUser ?? _ref.read(authProvider);
    final tgUser = TelegramWebAppService.getTelegramUser();

    final joinerName = authUser?.displayName ?? tgUser?.fullName ?? 'Партнер';
    final joinerAvatar = authUser?.photoUrl ?? tgUser?.photoUrl;
    final joinerId = authUser?.id ?? (tgUser != null ? 'tg_${tgUser.id}' : 'joined_member_${DateTime.now().millisecondsSinceEpoch}');

    final joinerMember = FamilyMember(
      id: joinerId,
      name: joinerName,
      avatarUrl: joinerAvatar,
      role: 'Партнер',
      isOnline: true,
      joinedAt: DateTime.now(),
    );

    // Cloud join
    final cloudFamily = await FamilyCloudService.joinFamilyInCloud(code, joinerMember);
    if (cloudFamily != null) {
      final finalFamily = cloudFamily.copyWith(cloudId: code, inviteCode: code);
      state = finalFamily;
      await _persist(finalFamily);

      // Fetch shared inventory and meal plan into joiner's app
      final fullData = await FamilyCloudService.fetchFullCloudData(code);
      if (fullData != null) {
        if (fullData.containsKey('fridge')) {
          _ref.read(fridgeProvider.notifier).setProductsFromCloud(fullData['fridge'] as List<ProductItem>);
        }
        if (fullData.containsKey('grocery')) {
          _ref.read(groceryProvider.notifier).setGroceryFromCloud(fullData['grocery'] as List<GroceryItem>);
        }
        if (fullData.containsKey('mealPlan')) {
          _ref.read(mealPlannerProvider.notifier).setMealPlanFromCloud(fullData['mealPlan'] as List<MealPlanDay>);
        }
      }
      _startAutoSync();
      return true;
    }

    return false;
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
      for (final key in [
        'sprout_family_group_v3',
        'sprout_family_group_v4',
        'sprout_family_group_v2',
        'sprout_family_group_v1'
      ]) {
        await prefs.remove(key);
      }
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
