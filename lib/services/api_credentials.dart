import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A user's key stays in memory for this session, never in saved profiles.
class ApiCredentials {
  static String _sessionKey = '';
  static bool get hasSessionKey => _sessionKey.isNotEmpty;
  static String get geminiKey => _sessionKey.isNotEmpty
      ? _sessionKey
      : dotenv.isInitialized
          ? dotenv.env['GEMINI_API_KEY']?.trim() ?? ''
          : '';
  static void setGeminiKey(String value) => _sessionKey = value.trim();
  static void clear() => _sessionKey = '';
}
