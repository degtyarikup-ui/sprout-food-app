import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/premium_state.dart';

class PremiumNotifier extends StateNotifier<PremiumState> {
  static const _kStorageKey = 'sprout_premium_state_v1';

  PremiumNotifier() : super(const PremiumState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = PremiumState.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<void> activatePremium({String plan = 'Годовой'}) async {
    state = state.copyWith(
      isPremium: true,
      planName: plan,
      expiresAt: DateTime.now().add(plan == 'Годовой' ? const Duration(days: 365) : const Duration(days: 30)),
    );
    await _persist();
  }

  Future<void> deactivatePremium() async {
    state = const PremiumState(isPremium: false);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorageKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier();
});
