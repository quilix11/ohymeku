import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/journey_level.dart';
import 'package:dialect_duel/screens/journey_screen.dart';
import 'package:dialect_duel/screens/journey_level_screen.dart';
import 'package:dialect_duel/screens/chronicles_screen.dart';
import 'package:dialect_duel/story/story_catalog.dart';
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
    await tapText(tester, 'Додаткова вправа');
    for (final q in level.story.questions) {
      await tapText(tester, q.options[q.answer]);
      final next = find.text('Наступний квест').hitTestable();
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable).last)
              .position
              .pixels,
          0);
    }
    for (final token in level.story.tokens) {
      await tester.tap(find.widgetWithText(ActionChip, token).first);
      await tester.pumpAndSettle();
    }
    await tapText(tester, 'Перевірити міст');
    await tapText(tester, 'Забрати знахідку');
    await tapText(tester, 'До рівня');
    await tapText(tester, 'Почати тест');
    for (final q in level.questions()) {
      await tapText(tester, q.options[q.answer]);
      final next = find
          .text(q.id == level.questions().last.id ? 'Завершити тест' : 'Далі')
          .hitTestable();
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('5 із 5 правильно'), findsOneWidget);
    expect(settings.journey.totalStars, 3);
    expect(settings.story.done(storyChapters.first), 0);
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
  testWidgets('map opens story independently and unlocks its next chapter',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (settings, progress) = await setup();
    await settings.setAnimationsEnabled(false);
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JourneyScreen(settings: settings, progress: progress))));
    await tester.pumpAndSettle();
    final level = find.byKey(const Key('journey_level_j1'));
    final story = find.byKey(const Key('journey_story_j1'));
    expect(tester.getCenter(level).dx, lessThan(tester.getCenter(story).dx));
    expect(tester.getTopLeft(level).dy, tester.getTopLeft(story).dy);
    await tester.ensureVisible(story);
    await tester.tap(story);
    await tester.pumpAndSettle();
    expect(find.byType(StoryReaderScreen), findsOneWidget);
    final chapter = storyChapters.first;
    for (final (index, scene) in chapter.scenes.indexed) {
      await tapText(tester, scene.options[scene.answer]);
      await tapText(tester, scene.choices.first);
      final next = find
          .text(index == chapter.scenes.length - 1
              ? 'Завершити розділ'
              : 'Наступна сцена')
          .hitTestable();
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(settings.story.finished(chapter), true);
    expect(settings.journey.completedCount, 0);
    expect(settings.journey.unlocked(journeyLevels[1]), false);
    await tapText(tester, 'Сюжет 2');
    expect(
        tester
            .widget<StoryReaderScreen>(find.byType(StoryReaderScreen))
            .chapter
            .id,
        storyChapters[1].id);
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
