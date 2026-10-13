import 'portrait_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/meku_route.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/learning_service.dart';
import 'package:dialect_duel/services/meku_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';

class GeneratedFixture extends LearningService {
  int calls = 0;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> generate(
      String topic, String level, int count, bool boss,
      {List<String> excludeWords = const [], bool? warm}) async {
    if (fail) throw const AiException('Синтетична помилка генерації.');
    calls++;
    if (boss) {
      return {
        'name': 'Alex',
        'role': 'Бариста',
        'goal': 'Замов каву.',
        'opening': 'What would you like?',
        'description': 'Грайливий бариста.'
      };
    }
    if (calls > 1) expect(excludeWords, contains('word1-0'));
    return {
      'cards': List.generate(
          count,
          (i) => {
                'word': 'word$calls-$i',
                'translation': 'слово $i',
                'example': 'This is word$calls-$i.',
                'transcription': '/wɜːd/'
              })
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsService settings;
  late ProgressService progress;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(portraitGenerator: fakePortraits);
    await settings.load();
    progress = ProgressService();
    await progress.initialize();
  });
  test(
      'multiple actions create 12 cards atomically, then open their actual deck',
      () async {
    final ai = GeneratedFixture(), routes = <MekuRoute>[];
    final meku =
        MekuService(settings, progress, ai: ai, request: (rules, input) async {
      expect(rules, contains('Polite requests'));
      expect(rules, contains('карточки'));
      return {
        'reply': 'Зараз створю набір.',
        'emotion': 'excited',
        'actions': [
          {
            'type': 'review_words',
            'value': {'deck': 'last_created', 'all': true}
          },
          {'type': 'theme', 'value': 'dark'},
          {
            'type': 'create_cards',
            'value': {'topic': 'Кава', 'count': 12, 'level': 'A2'}
          },
        ]
      };
    });
    addTearDown(meku.dispose);
    await meku.send('Можеш зробити 12 карточок про каву й почати повторення?',
        navigate: (_) {}, route: (r) {
      routes.add(r);
      return true;
    });
    expect(meku.error, isNull);
    expect(settings.isDark, isTrue);
    expect(settings.vocabulary.custom.length, 12);
    expect(ai.calls, 2);
    expect(routes.single.destination, 'review_words');
    expect(routes.single.arguments, {'deck': 'Кава · A2', 'all': true});
    expect(meku.messages.where((m) => m['status'] == 'success').length, 3);
    final restored = SettingsService();
    await restored.load();
    expect(restored.vocabulary.custom.length, 12);
    expect(progress.profile.xp, 0);
  });
  test(
      'character creation and start use saved ID; archive and restore survive reload',
      () async {
    final routes = <MekuRoute>[];
    final meku = MekuService(settings, progress,
        ai: GeneratedFixture(),
        request: (_, __) async => {
              'reply': 'Створю баристу.',
              'actions': [
                {
                  'type': 'create_character',
                  'value': {'topic': 'Кава', 'warm': true}
                },
                {'type': 'start_conversation', 'value': 'last_created'}
              ]
            });
    addTearDown(meku.dispose);
    await meku.send('Створи баристу і почни розмову.', navigate: (_) {},
        route: (r) {
      routes.add(r);
      return true;
    });
    final id = settings.customScenarios.single.customId!;
    expect(routes.single.arguments['id'], id);
    await meku.execute({'type': 'delete_character', 'value': id}, (_) {});
    expect(settings.customScenarios, isEmpty);
    final restored = SettingsService();
    await restored.load();
    expect(restored.archivedScenarios.single.customId, id);
    await meku.execute({'type': 'restore_character', 'value': id}, (_) {});
    expect(settings.customScenarios.single.customId, id);
  });
  test(
      'generation failure saves nothing, records failure and stops dependent navigation',
      () async {
    final ai = GeneratedFixture()..fail = true;
    final meku = MekuService(settings, progress,
        ai: ai,
        request: (_, __) async => {
              'reply': 'Створю.',
              'actions': [
                {
                  'type': 'create_cards',
                  'value': {'topic': 'Кава'}
                },
                {
                  'type': 'review_words',
                  'value': {'deck': 'last_created'}
                }
              ]
            });
    addTearDown(meku.dispose);
    await meku.send('Створи картки',
        navigate: (_) {}, route: (_) => fail('Must not navigate'));
    expect(settings.vocabulary.custom, isEmpty);
    expect(meku.messages.last['status'], 'error');
    expect(meku.messages.last['text'], contains('Синтетична'));
  });
  test('word edits and recoverable deletion preserve review state without XP',
      () async {
    final meku = MekuService(settings, progress);
    addTearDown(meku.dispose);
    await meku.execute({
      'type': 'add_word',
      'value': {
        'word': 'coffee',
        'translation': 'кава',
        'example': 'I like coffee.',
        'transcription': '/ˈkɒfi/'
      }
    }, (_) {});
    final id = settings.vocabulary.custom.single.id;
    await meku.execute({
      'type': 'word_known',
      'value': {'id': id, 'known': true}
    }, (_) {});
    await meku.execute({'type': 'delete_word', 'value': id}, (_) {});
    expect(settings.vocabulary.known, isNot(contains(id)));
    await meku.execute({'type': 'restore_word', 'value': id}, (_) {});
    expect(settings.vocabulary.known, contains(id));
    expect(settings.vocabulary.reviews[id], isNotNull);
    expect(progress.profile.xp, 0);
    await expectLater(
        meku.execute({'type': 'delete_word', 'value': 'a1'}, (_) {}),
        throwsStateError);
  });
}
