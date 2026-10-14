import 'dart:convert';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/main.dart';
import 'package:dialect_duel/models/journey_level.dart';
import 'package:dialect_duel/models/journey_story.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/models/practice_record.dart';
import 'package:dialect_duel/screens/journey_screen.dart';
import 'package:dialect_duel/screens/game_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/api_credentials.dart';
import 'journey_widget_test.dart' show tapText;

class WinningBoss extends AiService {
  int calls = 0;
  @override
  Future<NpcResponse> sendMessage(
      {required GameCharacter character,
      required List<ChatMessage> chatHistory,
      required int currentTrust,
      required int currentPatience,
      required String playerMessage,
      List<String> interests = const []}) async {
    calls++;
    return const NpcResponse(
        npcResponse: 'That is a clear answer. Welcome!',
        npcEmotion: NpcEmotion.happy,
        trustDelta: 15,
        patienceDelta: 15,
        currentTrust: 80,
        currentPatience: 80,
        gameStatus: GameStatus.inProgress,
        feedback: Feedback(grammarCorrection: '', tacticalAdvice: ''));
  }
}

Future<(SettingsService, ProgressService)> setupBoss() async {
  SharedPreferences.setMockInitialValues({
    'has_taken_placement': true,
    'tts_enabled': false,
    'journey_v2': jsonEncode({
      for (final l in journeyLevels.take(4))
        l.id: {'words': l.wordIds, 'quests': l.challengeIds, 'best': 5}
    })
  });
  final settings = SettingsService();
  await settings.load();
  await settings.setAnimationsEnabled(false);
  final progress = ProgressService();
  await progress.initialize();
  return (settings, progress);
}

void main() {
  testWidgets(
      'a reached boss requires three dialogue replies and unlocks the next world',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await setupBoss();
    addTearDown(settings.dispose);
    expect(settings.journey.current.id, 'j4');
    expect(settings.journey.unlocked(journeyLevels[4]), false);
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
        find.byKey(const Key('journey_continue')), 200,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('journey_continue'))),
        alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journey_continue')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Сюжетна дуель · без ШІ');
    final questions = bossDialogues['j4']!;
    await tapText(tester, questions.first.options[1]);
    expect(settings.journey.unlocked(journeyLevels[4]), false);
    for (var i = 0; i < 3; i++) {
      await tapText(tester, questions[i].options[questions[i].answer]);
      if (i < 2) await tapText(tester, 'Наступна репліка');
    }
    expect(settings.journey.unlocked(journeyLevels[4]), true);
    await tapText(tester, 'Продовжити пригоду');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('journey_walker')), findsOneWidget);
    final restored = SettingsService();
    await restored.load();
    addTearDown(restored.dispose);
    expect(restored.journey.bossMode(journeyLevels[3]), 'dialogue');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'saved AI victory awards a boss seal only after real confirmed turns',
      (tester) async {
    final (settings, progress) = await setupBoss();
    addTearDown(settings.dispose);
    ApiCredentials.setGeminiKey('synthetic-test-key');
    addTearDown(ApiCredentials.clear);
    final boss = journeyLevels[3];
    final receipts = <PracticeRecord>[];
    final ai = WinningBoss();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: FilledButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => GameScreen(
                                settings: settings,
                                progress: progress,
                                character: boss.opponent!.character,
                                scenario: boss.opponent!,
                                ai: ai,
                                onVictory: (record) async {
                                  receipts.add(record);
                                  await settings.journey
                                      .recordAiVictory(boss.id, record);
                                }))),
                    child: const Text('Відкрити боса'))))));
    await tester.tap(find.text('Відкрити боса'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.enterText(find.byKey(const Key('message_input')),
          'I will stay with my sister for five days.');
      await tester.pump();
      await tester.tap(find.byKey(const Key('send_message')));
      await tester.pumpAndSettle();
    }
    expect(settings.journey.bossDefeated(boss), false);
    expect(ai.calls, 2);
    expect(find.byKey(const Key('message_input')), findsNothing);
    await tester.tap(find.text('До пригоди'));
    await tester.pumpAndSettle();
    expect(receipts.single.won, true);
    expect(receipts.single.turns, 2);
    expect(receipts.single.scenarioId, boss.opponent!.customId);
    expect(settings.journey.bossMode(boss), 'ai');
    expect(settings.journey.unlocked(journeyLevels[4]), true);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'system theme follows the device and ignores legacy manual choices',
      (tester) async {
    final (settings, progress) = await setupBoss();
    addTearDown(settings.dispose);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(settings.themeMode, AppThemeMode.system);
    await tester
        .pumpWidget(DialectDuelApp(settings: settings, progress: progress));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(JourneyScreen))).brightness,
        Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(JourneyScreen))).brightness,
        Brightness.dark);
    await settings.setTheme(AppThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(JourneyScreen))).brightness,
        Brightness.dark);
    final restored = SettingsService();
    await restored.load();
    addTearDown(restored.dispose);
    expect(restored.themeMode, AppThemeMode.system);
    expect(find.byTooltip('Профіль'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(tester.getCenter(find.byKey(const Key('meku_launcher'))).dy,
        greaterThan(tester.getCenter(find.byTooltip('Профіль')).dy));
    expect(tester.takeException(), isNull);
  });
}
