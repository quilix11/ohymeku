import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' hide GoogleIdentity;
import 'google_identity_model.dart';

bool get googleSupported => defaultTargetPlatform == TargetPlatform.android;
Future<void>? _initialization;
Future<GoogleIdentity?> acquireGoogleIdentity() async {
  if (!googleSupported) {
    throw StateError('Google-вхід доступний на Android і у вебверсії.');
  }
  final google = GoogleSignIn.instance;
  try {
    await (_initialization ??= google.initialize());
  } catch (_) {
    _initialization = null;
    throw StateError(
        'Не вдалося налаштувати Google-вхід. Перевір конфігурацію застосунку.');
  }
  try {
    final user = await google.authenticate();
    return GoogleIdentity.token(user.authentication.idToken);
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;
    throw StateError(
        'Не вдалося увійти через Google. Перевір інтернет і налаштування Google Play.');
  } finally {
    // Keep the Firebase session in AccountService only; allow account selection next time.
    try {
      await google.signOut();
    } catch (_) {/* No local Google session to retain. */}
  }
}

Future<void> prepareGoogleIdentity() async {}
