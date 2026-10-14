import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/journey_level.dart';
import 'package:dialect_duel/screens/journey_screen.dart';
import 'package:dialect_duel/screens/journey_level_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';

Future<(SettingsService, ProgressService)> setup() async {
  SharedPreferences.setMockInitialValues({'tts_enabled': false});
  final settings = SettingsService();
  await settings.load();
  final progress = ProgressService();
  await progress.initialize();
  return (settings, progress);
}

Future<void> tapText(WidgetTester tester, String value) async {
  final finder = find.text(value);
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).last;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 160,
        scrollable: find.byType(Scrollable).last);
  }
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'first level verifies words, passes a real test and opens the next node',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await setup();
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JourneyScreen(settings: settings, progress: progress))));
    await tester.pumpAndSettle();
    expect(
        tester.widget<InkWell>(find.byKey(const Key('journey_level_j2'))).onTap,
        isNull);
    await tester.ensureVisible(find.byKey(const Key('journey_continue')));
    await tester.tap(find.byKey(const Key('journey_continue')));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyLevelScreen), findsOneWidget);
    final level = journeyLevels.first;
    await tapText(tester, 'Перевірити слово');
    await tapText(tester, level.choices(level.words.first).last);
    expect(settings.journey.wordLearned(level, level.words.first.id), false);
    await tapText(tester, level.words.first.translation);
    await tapText(tester, 'Друге слово');
    await tapText(tester, 'Перевірити слово');
    await tapText(tester, level.words.last.translation);
    await tapText(tester, 'До квестів');
    for (final q in level.story.questions) {
      await tapText(tester, q.options[q.answer]);
      await tapText(tester, 'Наступний квест');
    }
    for (final token in level.story.tokens) {
      await tester.tap(find.widgetWithText(ActionChip, token).first);
      await tester.pumpAndSettle();
    }
    await tapText(tester, 'Перевірити міст');
    await tapText(tester, 'Забрати знахідку');
    await tapText(tester, 'До перевірки');
    for (final q in level.questions()) {
      await tapText(tester, q.options[q.answer]);
      await tapText(tester,
          q.id == level.questions().last.id ? 'Завершити тест' : 'Далі');
    }
    expect(find.text('5 із 5 правильно'), findsOneWidget);
    expect(settings.journey.totalStars, 3);
    expect(settings.vocabulary.known, containsAll(level.wordIds));
    await tapText(tester, 'На карту');
    expect(
        tester.widget<InkWell>(find.byKey(const Key('journey_level_j2'))).onTap,
        isNotNull);
    final restored = SettingsService();
    await restored.load();
    addTearDown(restored.dispose);
    expect(restored.journey.current.id, 'j2');
    expect(restored.journey.totalStars, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'map and lesson fit small phones with large text and reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await setup();
    await settings.setAnimationsEnabled(false);
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: JourneyScreen(settings: settings, progress: progress))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('journey_level_j8')), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
        find.byKey(const Key('journey_continue')), -300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journey_continue')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Перевірити слово');
    await tapText(tester, journeyLevels.first.words.first.translation);
    expect(tester.takeException(), isNull);
  });
  testWidgets('closing an unfinished attempt never unlocks a level',
      (tester) async {
    final (settings, progress) = await setup();
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JourneyScreen(settings: settings, progress: progress))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journey_continue')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Перевірити слово');
    await tapText(tester, journeyLevels.first.words.first.translation);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(settings.journey.completedCount, 0);
    expect(settings.journey.unlocked(journeyLevels[1]), false);
    expect(settings.journey.wordLearned(journeyLevels.first, 'a1'), true);
  });
}
