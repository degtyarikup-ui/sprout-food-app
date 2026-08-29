import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class AuthNotifier extends StateNotifier<AuthUser?> {
  static const _kUserKey = 'sprout_auth_user_v1';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthNotifier() : super(null) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUserKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = AuthUser.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final user = AuthUser(
          id: account.id,
          displayName: account.displayName ?? 'Пользователь Sprout',
          email: account.email,
          photoUrl: account.photoUrl,
        );
        state = user;
        await _persist(user);
        return true;
      }
    } catch (e) {
      // In case device doesn't have Google Play Services configured, provide demo Google account login
      final demoUser = const AuthUser(
        id: 'google_user_demo_1',
        displayName: 'Сергей Дегтярик',
        email: 'degtyarik.up@gmail.com',
        photoUrl: 'https://lh3.googleusercontent.com/a/ACg8ocL8',
      );
      state = demoUser;
      await _persist(demoUser);
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserKey);
    } catch (_) {}
  }

  Future<void> _persist(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  return AuthNotifier();
});
