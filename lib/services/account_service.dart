import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Firebase public web config, not an admin credential. Tokens stay in memory.
/// Session expiry requires a fresh login; passwords and tokens never enter prefs.
class AccountService extends ChangeNotifier {
  static const configuredApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const configuredProject =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static final shared = AccountService();
  final String apiKey, projectId;
  final http.Client _client;
  AccountService(
      {http.Client? client,
      this.apiKey = configuredApiKey,
      this.projectId = configuredProject})
      : _client = client ?? http.Client();
  bool get configured =>
      apiKey.isNotEmpty &&
      RegExp(r'^[a-z][a-z0-9-]{4,29}$').hasMatch(projectId);
  String? _token, _uid, _email;
  DateTime? _expires;
  bool get signedIn =>
      _token != null && _expires != null && DateTime.now().isBefore(_expires!);
  String? get email => _email;
  bool busy = false;
  void _changed() => notifyListeners();

  Future<Map<String, dynamic>> _auth(
      String action, Map<String, dynamic> input) async {
    if (!configured) {
      throw StateError('Firebase ще не підключено до цієї збірки.');
    }
    try {
      final response = await _client
          .post(
              Uri.https('identitytoolkit.googleapis.com',
                  '/v1/accounts:$action', {'key': apiKey}),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(input))
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        final error = data is Map ? data['error'] : null;
        final code = error is Map ? error['message'] : null;
        throw StateError(switch (code) {
          'EMAIL_EXISTS' =>
            'Цю адресу вже зареєстровано. Увійди у свій акаунт.',
          'INVALID_LOGIN_CREDENTIALS' ||
          'EMAIL_NOT_FOUND' ||
          'INVALID_PASSWORD' =>
            'Перевір email і пароль.',
          'INVALID_EMAIL' => 'Перевір формат email.',
          'TOO_MANY_ATTEMPTS_TRY_LATER' => 'Забагато спроб. Спробуй пізніше.',
          'OPERATION_NOT_ALLOWED' =>
            'У Firebase потрібно ввімкнути вхід Email/Password.',
          _ => 'Не вдалося виконати запит. Перевір дані або спробуй пізніше.'
        });
      }
      return Map<String, dynamic>.from(data as Map);
    } on TimeoutException {
      throw StateError('Сервер не відповів вчасно. Спробуй ще раз.');
    } on http.ClientException {
      throw StateError('Немає зв’язку із сервером.');
    }
  }

  Future<void> authenticate(String email, String password,
      {bool register = false}) async {
    if (busy) return;
    if (!email.contains('@') || password.length < 8 || password.length > 128) {
      throw StateError('Введи email і пароль від 8 до 128 символів.');
    }
    busy = true;
    _changed();
    try {
      final j = await _auth(register ? 'signUp' : 'signInWithPassword', {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true
      });
      if (j['idToken'] is! String ||
          j['localId'] is! String ||
          j['email'] is! String) {
        throw const FormatException();
      }
      _token = j['idToken'];
      _uid = j['localId'];
      _email = j['email'];
      _expires = DateTime.now().add(Duration(
          seconds: (int.tryParse('${j['expiresIn']}') ?? 3600).clamp(1, 3600)));
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> resetPassword(String email) async {
    if (!email.contains('@')) throw StateError('Введи email для відновлення.');
    await _auth('sendOobCode',
        {'requestType': 'PASSWORD_RESET', 'email': email.trim()});
  }

  Future<void> verifyEmail() async {
    if (!signedIn) throw StateError('Увійди знову.');
    await _auth(
        'sendOobCode', {'requestType': 'VERIFY_EMAIL', 'idToken': _token});
  }

  void signOut() {
    _token = null;
    _uid = null;
    _email = null;
    _expires = null;
    _changed();
  }

  Future<Map<String, dynamic>?> cloudProfile(
      {Map<String, dynamic>? upload}) async {
    if (!signedIn) throw StateError('Сесія завершилася. Увійди знову.');
    final uri = Uri.https('firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/profiles/$_uid');
    final headers = {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json'
    };
    final response = await (upload == null
            ? _client.get(uri, headers: headers)
            : _client.patch(uri,
                headers: headers,
                body: jsonEncode({
                  'fields': {
                    for (final entry in upload.entries)
                      entry.key: entry.value is int
                          ? {'integerValue': '${entry.value}'}
                          : {'stringValue': entry.value}
                  }
                })))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404 && upload == null) return null;
    if (response.statusCode != 200) {
      throw StateError(response.statusCode == 403
          ? 'Перевір правила Firestore та підтвердь email.'
          : 'Не вдалося синхронізувати профіль. Спробуй пізніше.');
    }
    final j = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    final fields = j['fields'] as Map? ?? {};
    return {
      for (final e in fields.entries)
        e.key as String: (e.value as Map)['stringValue'] ??
            int.tryParse('${(e.value as Map)['integerValue']}')
    };
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
