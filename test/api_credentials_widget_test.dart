import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/services/api_credentials.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/screens/settings_screen.dart';

void main() {
  testWidgets('settings applies and clears a personal session key',
      (tester) async {
    dotenv.testLoad(fileInput: '');
    ApiCredentials.clear();
    addTearDown(ApiCredentials.clear);
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.load();
    await tester
        .pumpWidget(MaterialApp(home: SettingsScreen(settings: settings)));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Підключити Gemini'));
    await tester.pumpAndSettle();
    final input = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(tester.widget<TextField>(input).obscureText, true);
    await tester.enterText(input, 'synthetic-settings-key');
    await tester.tap(find.text('Застосувати'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(ApiCredentials.geminiKey, 'synthetic-settings-key');
    expect(find.text('Gemini підключено'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().any((name) => name.contains('api_key')), false);
    await tester.tap(find.text('Видалити ключ із цього сеансу'));
    await tester.pumpAndSettle();
    expect(ApiCredentials.geminiKey, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
