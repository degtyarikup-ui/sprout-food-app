import 'package:flutter/foundation.dart';
import 'dart:convert';
// Conditional import for web
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

  factory TelegramUserData.fromJson(Map<String, dynamic> json) {
    return TelegramUserData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['first_name'] as String? ?? 'Пользователь Telegram',
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      photoUrl: json['photo_url'] as String?,
      languageCode: json['language_code'] as String?,
      startParam: json['start_param'] as String?,
    );
  }
}

class TelegramWebAppService {
  static bool get isTelegramWebApp {
    if (!kIsWeb) return false;
    return tma_helper.isInsideTelegram();
  }

  static void init() {
    if (!kIsWeb) return;
    tma_helper.initTelegramApp();
  }

  static TelegramUserData? getTelegramUser() {
    if (!kIsWeb) return null;
    final rawJson = tma_helper.getTelegramUserJson();
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      return TelegramUserData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static String? getStartParam() {
    if (!kIsWeb) return null;
    return tma_helper.getTelegramStartParam();
  }
}
