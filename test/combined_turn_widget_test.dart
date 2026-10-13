import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/screens/game_screen.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/learning_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'combined_turn_test.dart' show envelope, englishReply, tutorReply;

class CountingTutor extends LearningService {
  int calls = 0;
  @override
  Future<LanguageHelp> prepare(String text, String context,
      {bool help = false, String level = 'A2'}) async {
    calls++;
    return const LanguageHelp(false, 'Підказка українською.', [
      (english: 'I am visiting family.', translation: 'Я відвідую родину.')
    ]);
  }
}

Future<(SettingsService, ProgressService)> state() async {
  SharedPreferences.setMockInitialValues({'tts_enabled': false});
  final settings = SettingsService();
  await settings.load();
  final progress = ProgressService();
  await progress.initialize();
  return (settings, progress);
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'GEMINI_API_KEY=synthetic-key'));
  testWidgets(
      'English send performs one HTTP call and no separate tutor request',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await state();
    addTearDown(settings.dispose);
    final tutor = CountingTutor();
    var calls = 0;
    final ai = AiService(client: MockClient((_) async {
      calls++;
      return envelope(englishReply);
    }));
    await tester.pumpWidget(MaterialApp(
        home: GameScreen(
            settings: settings, progress: progress, tutor: tutor, ai: ai)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('message_input')), 'I am visiting family.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tutor.calls, 0);
    expect(find.text('How long will you stay?'), findsOneWidget);
    expect(find.text('Як сказати англійською'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets(
      'Latin tutor response inserts a draft, never auto-sends, and respects offline mode',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await state();
    addTearDown(settings.dispose);
    final tutor = CountingTutor();
    var calls = 0;
    final ai = AiService(client: MockClient((_) async {
      calls++;
      return envelope(calls == 1 ? tutorReply : englishReply);
    }));
    await tester.pumpWidget(MaterialApp(
        home: GameScreen(
            settings: settings, progress: progress, tutor: tutor, ai: ai)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('message_input')), 'Ya pryikhav do rodyny');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tutor.calls, 0);
    expect(find.text('Як сказати англійською'), findsOneWidget);
    expect(find.text('You win!'), findsNothing);
    await tester.tap(find.text('Вставити у відповідь'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('message_input')))
            .controller!
            .text,
        'I am visiting family.');
    expect(calls, 1);
    expect(progress.profile.xp, 0);
    await settings.setExtra('offline_mode', true);
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('Для живої розмови потрібен інтернет'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await settings.setExtra('offline_mode', false);
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('How long will you stay?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets(
      'Cyrillic draft keeps explicit tutor routing without an NPC request',
      (tester) async {
    final (settings, progress) = await state();
    addTearDown(settings.dispose);
    final tutor = CountingTutor();
    var calls = 0;
    final ai = AiService(client: MockClient((_) async {
      calls++;
      return envelope(englishReply);
    }));
    await tester.pumpWidget(MaterialApp(
        home: GameScreen(
            settings: settings, progress: progress, tutor: tutor, ai: ai)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('message_input')), 'Я відвідую родину');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tutor.calls, 1);
    expect(find.text('Як сказати англійською'), findsOneWidget);
    expect(progress.profile.xp, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets(
      'retry checks offline mode and can show tutor suggestions after reconnecting',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await state();
    addTearDown(settings.dispose);
    var calls = 0;
    final ai = AiService(client: MockClient((_) async {
      calls++;
      return calls == 1 ? http.Response('{}', 503) : envelope(tutorReply);
    }));
    await tester.pumpWidget(MaterialApp(
        home: GameScreen(
            settings: settings,
            progress: progress,
            tutor: CountingTutor(),
            ai: ai)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('message_input')), 'Ya pryikhav');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Повторити'), findsOneWidget);
    await settings.setExtra('offline_mode', true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Повторити'));
    await tester.tap(find.text('Повторити'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('Для живої розмови потрібен інтернет'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await settings.setExtra('offline_mode', false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Повторити'));
    await tester.tap(find.text('Повторити'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Як сказати англійською'), findsOneWidget);
    expect(find.text('You win!'), findsNothing);
    expect(progress.profile.xp, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
