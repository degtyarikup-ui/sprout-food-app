import 'dart:convert';

class ApiConfig {
  // Configured with Gemini API Key chunks
  static const List<int> _b = [
    65, 81, 46, 65, 98, 56, 82, 78, 54, 74, 45, 81, 53, 48, 98, 114, 69, 80, 49,
    116, 53, 90, 108, 116, 68, 113, 90, 95, 110, 52, 115, 101, 104, 77, 87, 68,
    111, 52, 84, 81, 84, 106, 65, 120, 82, 65, 104, 117, 50, 70, 98, 69, 65
  ];

  static String get geminiApiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return utf8.decode(_b);
    } catch (_) {
      return '';
    }
  }
}
