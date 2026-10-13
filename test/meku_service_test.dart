import 'dart:async';
import 'dart:convert';
import 'package:dialect_duel/models/meku_emotion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/services/meku_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsService settings;
  late ProgressService progress;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService();
    await settings.load();
    progress = ProgressService();
    await progress.initialize();
  });
  test('response emotions persist per message and restore the latest mood',
      () async {
    var next = MekuEmotion.sad;
    final service =
        MekuService(settings, progress, request: (rules, input) async {
      expect(rules, contains('tsundere'));
      expect(rules, contains('Genuine frustration'));
      expect(rules, contains('Quoted insults'));
      expect(input['latest_user_message'], isNotEmpty);
      return {
        'reply': 'Розберемося разом.',
        'emotion': next.name,
        'action': null
      };
    });
    addTearDown(service.dispose);
    await service.send('Злюся через помилку.', navigate: (_) {});
    expect(service.emotion, MekuEmotion.sad);
    next = MekuEmotion.annoyed;
    await service.send('Ти дурна.', navigate: (_) {});
    expect(service.emotion, MekuEmotion.annoyed);
    expect(
        service.messages
            .where((m) => m['role'] == 'assistant')
            .map((m) => m['emotion']),
        ['sad', 'annoyed']);
    final restored = MekuService(settings, progress);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.emotion, MekuEmotion.annoyed);
    expect(restored.messages, service.messages);
  });

  test('old chat and untrusted emotion names use a safe local fallback',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'meku_chat_v1',
        jsonEncode([
          {'role': 'assistant', 'text': 'Привіт!'}
        ]));
    final service = MekuService(settings, progress,
        request: (_, __) async => {
              'reply': 'Почнемо?',
              'emotion': '../../some-file',
              'action': null
            });
    addTearDown(service.dispose);
    await service.load();
    expect(service.emotion, MekuEmotion.smug);
    await service.send('Привіт', navigate: (_) {});
    expect(service.messages.last['emotion'], 'smug');
    expect(service.emotion.asset, 'assets/images/meku/meku_smug.png');
  });
  test('explicit level starts a new adaptive window and persists', () async {
    settings.learner.recent.addAll(List.filled(10, false));
    expect(settings.effectiveLevel, 'A1');
    final service = MekuService(settings, progress);
    addTearDown(service.dispose);
    await service.execute({'type': 'level', 'value': 'B1'}, (_) {});
    expect(settings.effectiveLevel, 'B1');
    expect(settings.adaptiveLearning, isTrue);
    final restored = SettingsService();
    await restored.load();
    expect(restored.effectiveLevel, 'B1');
    expect(restored.learner.recent, isEmpty);
  });
  test('rejects unknown actions and malformed or out-of-range values',
      () async {
    final service = MekuService(settings, progress);
    addTearDown(service.dispose);
    for (final action in [
      {'type': 'level', 'value': 'C2'},
      {'type': 'card_count', 'value': 1000},
      {'type': 'tts', 'value': 'true'},
      {'type': 'reminder_time', 'value': '25:00'},
      {'type': 'delete_progress', 'value': true},
      {
        'type': 'add_word',
        'value': {'word': 'hello'}
      },
    ]) {
      await expectLater(service.execute(action, (_) {}), throwsFormatException);
    }
    expect(settings.learningLevel, 'A2');
    expect(progress.profile.xp, 0);
  });
  test('word action uses shared vocabulary and survives reload', () async {
    final service = MekuService(settings, progress);
    addTearDown(service.dispose);
    final action = {
      'type': 'add_word',
      'value': {
        'word': 'curious',
        'translation': 'допитливий',
        'example': 'I am curious.'
      }
    };
    await service.execute(action, (_) {});
    await service.execute(action, (_) {});
    expect(settings.vocabulary.custom.length, 1);
    final restored = SettingsService();
    await restored.load();
    expect(restored.vocabulary.custom.single.word, 'curious');
  });
  test('offline blocks network and mutation', () async {
    var calls = 0;
    final service = MekuService(settings, progress, request: (_, __) async {
      calls++;
      return {};
    });
    addTearDown(service.dispose);
    await settings.setExtra('offline_mode', true);
    await service.send('Підніми рівень', navigate: (_) {});
    expect(calls, 0);
    expect(service.error, isNotNull);
    expect(settings.learningLevel, 'A2');
  });
  test('one request at a time; action receipt and history persist', () async {
    final response = Completer<Map<String, dynamic>>();
    var calls = 0;
    final service = MekuService(settings, progress, request: (_, input) {
      calls++;
      expect((input['app'] as Map)['level'], 'A2');
      return response.future;
    });
    addTearDown(service.dispose);
    final pending = service.send('Підніми рівень', navigate: (_) {});
    await service.send('Ще раз', navigate: (_) {});
    response.complete({
      'reply': 'Ого, давай спробуємо B1!',
      'action': {'type': 'level', 'value': 'B1'}
    });
    await pending;
    expect(calls, 1);
    expect(settings.effectiveLevel, 'B1');
    expect(service.messages.last['text'], contains('B1'));
    final restored = MekuService(settings, progress);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.messages.length, 3);
  });
  test('failed request leaves no successful action and can retry', () async {
    var fail = true;
    final service = MekuService(settings, progress, request: (_, __) async {
      if (fail) throw StateError('network');
      return {'reply': 'Привіт!', 'action': null};
    });
    addTearDown(service.dispose);
    await service.send('Привіт', navigate: (_) {});
    expect(service.messages, isEmpty);
    expect(service.busy, isFalse);
    fail = false;
    await service.send('Привіт', navigate: (_) {});
    expect(service.messages.length, 2);
    expect(service.error, isNull);
  });
  test('a late response after disposal cannot change settings', () async {
    final response = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    final service = MekuService(settings, progress, request: (_, __) {
      started.complete();
      return response.future;
    });
    final pending = service.send('Зміни рівень', navigate: (_) {});
    await started.future;
    service.dispose();
    response.complete({
      'reply': 'Гаразд',
      'action': {'type': 'level', 'value': 'C1'}
    });
    await pending;
    expect(settings.learningLevel, 'A2');
  });
}
