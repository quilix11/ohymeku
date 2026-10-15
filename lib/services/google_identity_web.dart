import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'google_identity_model.dart';

bool get googleSupported => true;
Future<FirebaseAuth>? _initialization;
Future<FirebaseAuth> _prepare() async {
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const key = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID',
      defaultValue: '1:933394961865:web:7342ec08bec06f3b100418');
  const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '933394961865');
  if (appId.isEmpty || sender.isEmpty) {
    throw StateError('Для Google-входу потрібна вебконфігурація Firebase.');
  }
  final app = await Firebase.initializeApp(
      name: 'google-account',
      options: const FirebaseOptions(
        apiKey: key,
        appId: appId,
        messagingSenderId: sender,
        projectId: project,
        authDomain: '$project.firebaseapp.com',
      ));
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.setPersistence(Persistence.NONE);
  return auth;
}

// Prepare before the click so signInWithPopup retains browser user activation.
Future<void> prepareGoogleIdentity() async {
  try {
    await (_initialization ??= _prepare());
  } catch (_) {
    _initialization = null;
  }
}

Future<GoogleIdentity?> acquireGoogleIdentity() async {
  final auth = await (_initialization ??= _prepare());
  try {
    final result = await auth.signInWithPopup(GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'}));
    final user = result.user;
    final token = await user?.getIdToken();
    return GoogleIdentity.session({
      'idToken': token,
      'localId': user?.uid,
      'email': user?.email,
      'expiresIn': '3600',
    });
  } on FirebaseAuthException catch (e) {
    if (e.code == 'popup-closed-by-user' ||
        e.code == 'cancelled-popup-request') {
      return null;
    }
    throw StateError(switch (e.code) {
      'popup-blocked' => 'Дозволь спливне вікно для входу через Google.',
      'unauthorized-domain' => 'Цей домен ще не дозволений у Firebase.',
      'account-exists-with-different-credential' =>
        'Увійди наявним способом для цього email.',
      _ => 'Не вдалося увійти через Google. Перевір інтернет і спробуй ще раз.',
    });
  } finally {
    await auth.signOut();
  }
}
