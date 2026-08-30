import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'telegram_web_helper_stub.dart'
    if (dart.library.js_interop) 'telegram_web_helper_web.dart' as tma_helper;

class TelegramUserData {
  final int id;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? photoUrl;
  final String? languageCode;
  final String? startParam;

  const TelegramUserData({
    required this.id,
    required this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    this.languageCode,
    this.startParam,
  });

  String get fullName => lastName != null && lastName!.isNotEmpty
      ? '$firstName $lastName'
      : firstName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'photo_url': photoUrl,
        'language_code': languageCode,
        'start_param': startParam,
      };

  factory TelegramUserData.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = Map<String, dynamic>.from(rawJson);

    String? photo = json['photo_url'] as String?;
    if (photo == null || photo.trim().isEmpty) {
      photo = tma_helper.getTelegramPhotoParam();
    }

    String? uname = json['username'] as String?;
    if (uname == null || uname.trim().isEmpty) {
      uname = tma_helper.getTelegramUsernameParam();
    }

    return TelegramUserData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['first_name'] as String? ?? 'Пользователь Telegram',
      lastName: json['last_name'] as String?,
      username: uname,
      photoUrl: (photo != null && photo.trim().isNotEmpty) ? photo.trim() : null,
      languageCode: json['language_code'] as String?,
      startParam: json['start_param'] as String? ?? tma_helper.getTelegramStartParam(),
    );
  }
}

class TelegramWebAppService {
  static bool get isTelegramWebApp {
    if (!kIsWeb) return false;
    return tma_helper.isInsideTelegram() || tma_helper.getTelegramUserJson() != null;
  }

  static void init() {
    if (!kIsWeb) return;
    tma_helper.initTelegramApp();
  }

  static TelegramUserData? getTelegramUser() {
    if (!kIsWeb) return null;
    final rawJson = tma_helper.getTelegramUserJson();
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as Map<dynamic, dynamic>;
        return TelegramUserData.fromJson(decoded);
      } catch (_) {}
    }

    // If initDataUnsafe wasn't available, but we have URL params from bot
    final photoParam = tma_helper.getTelegramPhotoParam();
    final usernameParam = tma_helper.getTelegramUsernameParam();
    if (photoParam != null || usernameParam != null) {
      return TelegramUserData(
        id: 0,
        firstName: usernameParam ?? 'Пользователь',
        username: usernameParam,
        photoUrl: photoParam,
      );
    }

    return null;
  }

  static String? getStartParam() {
    if (!kIsWeb) return null;
    return tma_helper.getTelegramStartParam();
  }
}
