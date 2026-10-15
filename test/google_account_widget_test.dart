import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/screens/account_screen.dart';
import 'package:dialect_duel/services/account_service.dart';
import 'package:dialect_duel/services/google_identity_model.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/theme/app_theme.dart';

void main() {
  testWidgets(
      'Google login at 320px and large text keeps local profile until explicit sync',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();
    await progress.initialize();
    await progress.saveProfile('Local Fox', 3);
    final before = progress.profileData();
    final service = AccountService(
        apiKey: 'public',
        projectId: 'test-project',
        googleIdentity: () async => const GoogleIdentity.session({
              'idToken': 'synthetic',
              'localId': 'google-user',
              'email': 'tester@example.com',
              'expiresIn': '3600'
            }));
    addTearDown(service.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: AccountScreen(progress: progress, service: service)));
    final login = find.text('Продовжити з Google');
    await tester.scrollUntilVisible(login, 180);
    await tester.pumpAndSettle();
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(service.signedIn, true);
    expect(progress.profileData(), before);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('Продовжити з Google'), findsNothing);
    expect(tester.takeException(), isNull);
    final logout = find.text('Вийти з акаунта');
    await tester.scrollUntilVisible(logout, 180);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();
    expect(service.signedIn, false);
    expect(progress.profileData(), before);
  });
}
