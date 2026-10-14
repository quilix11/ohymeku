import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/scenario.dart';
import 'package:dialect_duel/models/journey_story.dart';
import 'package:dialect_duel/models/journey_level.dart';
import 'package:dialect_duel/screens/character_selection_screen.dart';
import 'package:dialect_duel/screens/settings_screen.dart';
import 'package:dialect_duel/screens/game_screen.dart';
import 'package:dialect_duel/screens/journey_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/theme/app_theme.dart';
import 'package:dialect_duel/widgets/willow_portrait.dart';

Future<(SettingsService, ProgressService)> setup(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(
      {'tts_enabled': false, 'animations_enabled': false, ...initial});
  final settings = SettingsService();
  await settings.load();
  final progress = ProgressService();
  await progress.initialize();
  return (settings, progress);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).last;
  if (finder.evaluate().isEmpty) {
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 160, scrollable: scrollable);
  }
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: .5);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('teacher voice is shared by her scenes but independent from Hannah',
      () async {
    final (settings, _) = await setup();
    addTearDown(settings.dispose);
    await settings.setScenarioVoice(Scenario.willow, 'Zephyr', cloud: true);
    await settings.setScenarioVoice(Scenario.willow, 'teacher-system');
    expect(settings.scenarioCloudVoice(journeyLevels.last.opponent!), 'Zephyr');
    for (final scene in freeJourneyScenes(journeyLevels.last)) {
      expect(settings.scenarioCloudVoice(scene), 'Zephyr');
      expect(settings.scenarioVoice(scene), 'teacher-system');
    }
    expect(settings.scenarioCloudVoice(Scenario.all[1]), 'Kore');
    await settings.setScenarioVoice(Scenario.all.first, 'Orus', cloud: true);
    expect(settings.scenarioCloudVoice(journeyLevels[3].opponent!), 'Orus');
    final restored = SettingsService();
    await restored.load();
    addTearDown(restored.dispose);
    expect(restored.scenarioCloudVoice(journeyLevels.last.opponent!), 'Zephyr');
  });
  test(
      'existing custom selection migrates by ID and Willow selection survives reload',
      () async {
    final custom = Scenario.willow.toJson()
      ..['id'] = 'my-teacher'
      ..['name'] = 'Alex';
    final (settings, _) = await setup({
      'last_character': 2,
      'custom_scenarios_v1': jsonEncode([custom])
    });
    addTearDown(settings.dispose);
    expect(settings.lastCharacter, 3);
    await settings.setLastCharacter(2);
    final restored = SettingsService();
    await restored.load();
    addTearDown(restored.dispose);
    expect(restored.lastCharacter, 2);
    expect(Scenario.all[restored.lastCharacter].name, 'Ms Willow');
    expect(
        (await SharedPreferences.getInstance()).getString('last_scenario_id'),
        'willow');
  });
  testWidgets(
      'Willow is visible in the complete picker and starts her own conversation',
      (tester) async {
    tester.view.physicalSize = const Size(384, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await setup();
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
            body: CharacterSelectionScreen(
                settings: settings, progress: progress))));
    await tester.pumpAndSettle();
    final teacher = find.byKey(const Key('character_choice_willow'));
    expect(teacher.hitTestable(), findsOneWidget);
    await tester.tap(teacher);
    await tester.pumpAndSettle();
    expect(settings.lastCharacter, 2);
    expect(find.byType(WillowPortrait), findsWidgets);
    final start = find.byKey(const Key('start_willow'));
    await scrollTo(tester, start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.textContaining('I am Ms Willow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets('world headings stay below boss labels at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(384, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, progress) = await setup();
      addTearDown(settings.dispose);
      await tester.pumpWidget(MaterialApp(
          theme: buildDarkTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: JourneyScreen(settings: settings, progress: progress))));
      await tester.pumpAndSettle();
      for (var world = 1; world < 3; world++) {
        final header = find.byKey(Key('journey_world_$world'));
        await scrollTo(tester, header);
        final previous = find.byKey(Key('journey_description_j${world * 4}'));
        expect(tester.getRect(header).top - tester.getRect(previous).bottom,
            greaterThanOrEqualTo(32));
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('voice fields and preview actions have space and include Willow',
      (tester) async {
    tester.view.physicalSize = const Size(384, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async => call.method == 'getVoices' ? <dynamic>[] : 1);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null));
    final (settings, _) = await setup({'cloud_voices': true});
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildDarkTheme(), home: SettingsScreen(settings: settings)));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Голос і звук'));
    await tester.tap(find.text('Голос і звук'));
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('preview_willow'));
    await scrollTo(tester, preview);
    final dropdown = find.byKey(const ValueKey('cloud_willow_Leda'));
    expect(dropdown, findsOneWidget);
    expect(tester.getRect(preview).top - tester.getRect(dropdown).bottom,
        greaterThanOrEqualTo(16));
    expect((tester.getRect(preview).left - tester.getRect(dropdown).left).abs(),
        lessThan(1));
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zephyr').last);
    await tester.pumpAndSettle();
    expect(settings.scenarioCloudVoice(journeyLevels.last.opponent!), 'Zephyr');
    expect(tester.takeException(), isNull);
  });
}
