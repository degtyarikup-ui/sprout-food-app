import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  static const _kStorageKey = 'sprout_user_preferences';

  UserPreferencesNotifier() : super(const UserPreferences()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = UserPreferences.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<void> setServings(int servings) async {
    state = state.copyWith(defaultServings: servings);
    await _persist();
  }

  Future<void> setDiet(DietType diet) async {
    state = state.copyWith(diet: diet);
    await _persist();
  }

  Future<void> toggleAllergy(String allergy) async {
    final current = List<String>.from(state.allergies);
    if (current.contains(allergy)) {
      current.remove(allergy);
    } else {
      current.add(allergy);
    }
    state = state.copyWith(allergies: current);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorageKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});
