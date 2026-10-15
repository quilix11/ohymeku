import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/services/account_service.dart';

void main() {
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
