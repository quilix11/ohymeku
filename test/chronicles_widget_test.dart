import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/screens/chronicles_screen.dart';
import 'package:dialect_duel/screens/account_screen.dart';
import 'package:dialect_duel/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'story choices, journal and next scene fit 320px at 200%: $dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(
          {'animations_enabled': false, 'tts_enabled': false});
      final settings = SettingsService();
      await settings.load();
      final progress = ProgressService();
      await progress.initialize();
      await progress.saveProfile('Андрій', 4, nickname: 'Fox');
      await tester.pumpWidget(MaterialApp(
          theme: dark ? buildDarkTheme() : buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2), disableAnimations: true),
              child: child!),
          home: ChroniclesScreen(settings: settings, progress: progress)));
      await tester.pumpAndSettle();
      final chapter = find.text('1. Лист, який пахне корицею');
      await tester.scrollUntilVisible(chapter, 180,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(chapter);
      await tester.pumpAndSettle();
      expect(find.textContaining('Fox, я знайшла'), findsOneWidget);
      final answer = find.text('Keep it away from water.');
      await tester.ensureVisible(answer);
      await tester.pumpAndSettle();
      await tester.tap(answer);
      final choice = find.text('Показати лист Норі');
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(settings.story.done(settings.story.chapters.first), 1);
      expect(settings.story.clues.length, 1);
      final next = find.text('Наступна сцена');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Nora'), findsOneWidget);
      expect(find.textContaining('Сцена 2/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
      progress.dispose();
    });
  }
  testWidgets('unconfigured account has no pretend login form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();
    await progress.initialize();
    await tester
        .pumpWidget(MaterialApp(home: AccountScreen(progress: progress)));
    expect(find.text('Акаунти ще не підключені'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
