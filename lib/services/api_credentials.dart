import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A user's key stays in memory for this session, never in saved profiles.
class ApiCredentials {
  static const _configuredGateway =
      String.fromEnvironment('GEMINI_GATEWAY_URL');
  static Uri? get gateway {
    final uri = Uri.tryParse(_configuredGateway);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty &&
            uri.query.isEmpty &&
            uri.fragment.isEmpty
        ? uri
        : null;
  }

  static bool get useGateway => geminiKey.isEmpty && gateway != null;
  static bool get available => geminiKey.isNotEmpty || useGateway;
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
