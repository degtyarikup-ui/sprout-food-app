import 'dart:convert';

class ApiConfig {
  // Encoded with Google AI Studio Gemini API Key
  static const String _k = 'QVEuQWI4Uk42Si1RNTBickVQMXR1Wmx0RHFaX240c2VoTVdEbzRUUVRqQXhSQWh1MkZiRUE=';

  static String get geminiApiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return utf8.decode(base64Decode(_k));
    } catch (_) {
      return '';
    }
  }
}
