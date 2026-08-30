import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/telegram_web_app_service.dart';
import '../models/auth_user.dart';

class AuthNotifier extends StateNotifier<AuthUser?> {
  static const _kUserKey = 'sprout_auth_user_v3';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    // 1. First check if launched inside Telegram Mini App
    if (TelegramWebAppService.isTelegramWebApp) {
      final tgUser = TelegramWebAppService.getTelegramUser();
      if (tgUser != null) {
        // Use real photo if provided by Telegram, otherwise null for clean initials avatar
        final String? avatar = (tgUser.photoUrl != null && tgUser.photoUrl!.trim().isNotEmpty)
            ? tgUser.photoUrl
            : null;

        final user = AuthUser(
          id: 'tg_${tgUser.id}',
          displayName: tgUser.fullName,
          email: tgUser.username != null && tgUser.username!.isNotEmpty
              ? '@${tgUser.username}'
              : 'ID: ${tgUser.id}',
          photoUrl: avatar,
          authProviderType: 'telegram',
          username: tgUser.username,
        );
        state = user;
        await _persist(user);
        return;
      }
    }

    // 2. Otherwise load saved local session
    await _loadFromStorage();
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
        String? photo = account.photoUrl;
        if (photo != null && photo.contains('=')) {
          photo = photo.replaceAll(RegExp(r'=s\d+(-c)?'), '=s200-c');
        }

        final user = AuthUser(
          id: account.id,
          displayName: account.displayName ?? 'Пользователь Sprout',
          email: account.email,
          photoUrl: photo,
          authProviderType: 'google',
        );
        state = user;
        await _persist(user);
        return true;
      }
    } catch (e) {
      const demoUser = AuthUser(
        id: 'google_user_sergei',
        displayName: 'Сергей Дегтярик',
        email: 'degtyarik.up@gmail.com',
        photoUrl: null, // clean initials avatar
        authProviderType: 'google',
      );
      state = demoUser;
      await _persist(demoUser);
      return true;
    }
    return false;
  }

  Future<void> signInWithTelegramDemo({
    String firstName = 'Сергей',
    String? username = 'degtyarik',
  }) async {
    final user = AuthUser(
      id: 'tg_user_demo',
      displayName: '$firstName Дегтярик',
      email: username != null ? '@$username' : 'telegram_user',
      photoUrl: null, // clean initials avatar
      authProviderType: 'telegram',
      username: username,
    );
    state = user;
    await _persist(user);
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
