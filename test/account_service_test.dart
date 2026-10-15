import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/services/account_service.dart';
import 'package:dialect_duel/services/google_identity_model.dart';

void main() {
  test(
      'Google credential is exchanged with Firebase and cloud uses Firebase UID',
      () async {
    final client = MockClient((request) async {
      if (request.url.host == 'identitytoolkit.googleapis.com') {
        expect(request.url.path, '/v1/accounts:signInWithIdp');
        final body = jsonDecode(request.body) as Map;
        final post = Uri.splitQueryString(body['postBody'] as String);
        expect(post['providerId'], 'google.com');
        expect(post['id_token'], 'synthetic+google/token');
        expect(body['returnSecureToken'], true);
        expect(body.containsKey('password'), false);
        return http.Response(
            jsonEncode({
              'idToken': 'firebase-token',
              'localId': 'firebase-uid',
              'email': 'tester@example.com',
              'expiresIn': '3600'
            }),
            200);
      }
      expect(request.url.path, endsWith('/profiles/firebase-uid'));
      expect(request.headers['Authorization'], 'Bearer firebase-token');
      return http.Response('{"fields":{}}', 200);
    });
    final service = AccountService(
        client: client,
        apiKey: 'public',
        projectId: 'test-project',
        googleIdentity: () async =>
            const GoogleIdentity.token('synthetic+google/token'));
    addTearDown(service.dispose);
    expect(await service.authenticateGoogle(), true);
    expect(service.email, 'tester@example.com');
    await service.cloudProfile();
    service.signOut();
    expect(service.signedIn, false);
  });
  test('Google cancellation never calls Firebase and clears busy', () async {
    final service = AccountService(
        apiKey: 'public',
        projectId: 'test-project',
        client: MockClient((_) async => throw StateError('must not send')),
        googleIdentity: () async => null);
    addTearDown(service.dispose);
    expect(await service.authenticateGoogle(), false);
    expect(service.busy, false);
    expect(service.signedIn, false);
  });
  test('Google rejects malformed responses without accepting a partial session',
      () async {
    final service = AccountService(
        apiKey: 'public',
        projectId: 'test-project',
        client: MockClient(
            (_) async => http.Response('{"idToken":"partial"}', 200)),
        googleIdentity: () async => const GoogleIdentity.token('synthetic'));
    addTearDown(service.dispose);
    await expectLater(service.authenticateGoogle(), throwsStateError);
    expect(service.busy, false);
    expect(service.signedIn, false);
    expect(service.email, null);
  });
  test('Google failure does not expose provider details', () async {
    final service = AccountService(
        apiKey: 'public',
        projectId: 'test-project',
        client: MockClient((_) async =>
            http.Response('{"error":{"message":"synthetic-secret"}}', 400)),
        googleIdentity: () async => const GoogleIdentity.token('synthetic'));
    addTearDown(service.dispose);
    try {
      await service.authenticateGoogle();
      fail('must reject');
    } catch (e) {
      expect(e.toString(), isNot(contains('synthetic-secret')));
    }
    expect(service.signedIn, false);
    expect(service.busy, false);
  });

  test('no config never calls auth or pretends to log in', () async {
    final s = AccountService(
        client:
            MockClient((_) async => throw StateError('network must not run')));
    expect(s.configured, false);
    await expectLater(
        s.authenticate('a@b.com', 'password123'), throwsStateError);
    expect(s.signedIn, false);
  });
  test(
      'auth session scopes Firestore to the actual UID and signout revokes local access',
      () async {
    final requests = <http.Request>[];
    final client = MockClient((r) async {
      requests.add(r);
      if (r.url.host == 'identitytoolkit.googleapis.com') {
        expect(jsonDecode(r.body)['password'], 'password123');
        return http.Response(
            jsonEncode({
              'idToken': 'test-token',
              'localId': 'actual-uid',
              'email': 'a@b.com',
              'expiresIn': '3600'
            }),
            200);
      }
      expect(r.url.path, endsWith('/profiles/actual-uid'));
      expect(r.headers['Authorization'], 'Bearer test-token');
      return http.Response(
          jsonEncode({
            'fields': {
              'name': {'stringValue': 'Fox'},
              'avatar': {'integerValue': '5'}
            }
          }),
          200);
    });
    final s = AccountService(
        client: client, apiKey: 'public-key', projectId: 'ohymeku-test');
    await s.authenticate('a@b.com', 'password123');
    expect(s.signedIn, true);
    final p = await s.cloudProfile();
    expect(p?['avatar'], 5);
    s.signOut();
    expect(s.signedIn, false);
    await expectLater(s.cloudProfile(), throwsStateError);
    expect(requests.length, 2);
  });
  test('bad credentials have a readable error and leave the account signed out',
      () async {
    final s = AccountService(
        apiKey: 'public',
        projectId: 'ohymeku-test',
        client: MockClient((_) async => http.Response(
            '{"error":{"message":"INVALID_LOGIN_CREDENTIALS"}}', 400)));
    await expectLater(
        s.authenticate('a@b.com', 'password123'), throwsStateError);
    expect(s.signedIn, false);
    expect(s.busy, false);
  });
}
