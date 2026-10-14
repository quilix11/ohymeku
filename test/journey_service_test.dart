import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/journey_level.dart';
import 'package:dialect_duel/models/journey_story.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/models/practice_record.dart';
import 'package:dialect_duel/services/journey_service.dart';

class FailingPrefs extends Fake implements SharedPreferences {
  bool fail = false;
  final values = <String, String>{};
  @override
  String? getString(String key) => values[key];
  @override
  Future<bool> setString(String key, String value) async {
    if (fail) return false;
    values[key] = value;
    return true;
  }
}

Future<void> learn(JourneyService service, JourneyLevel level) async {
  for (final word in level.words) {
    await service.verifyWord(level.id, word.id, word.translation);
  }
  await quests(service, level);
}

Future<void> quests(JourneyService service, JourneyLevel level) async {
  for (final q in level.story.questions) {
    await service.verifyChallenge(level.id, q.id, q.options[q.answer]);
  }
  await service.verifyChallenge(level.id, 'order', level.story.sentence);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('level locks require both verified words and a complete passing test',
      () async {
    final service = JourneyService();
    await service.load();
    final first = journeyLevels.first, next = journeyLevels[1];
    expect(service.unlocked(first), true);
    expect(service.unlocked(next), false);
    await expectLater(
        service.verifyWord(
            next.id, next.words.first.id, next.words.first.translation),
        throwsStateError);
    expect(await service.verifyWord(first.id, first.words.first.id, 'wrong'),
        false);
    expect(service.wordLearned(first, first.words.first.id), false);
    final questions = first.questions();
    await expectLater(
        service.finishTest(
            first.id, questions, questions.map((q) => q.answer).toList()),
        throwsStateError);
    await learn(service, first);
    await expectLater(
        service.finishTest(first.id, questions.take(4).toList(), [0, 0, 0, 0]),
        throwsArgumentError);
    final fail =
        questions.map((q) => (q.answer + 1) % q.options.length).toList();
    expect(await service.finishTest(first.id, questions, fail), 0);
    expect(service.unlocked(next), false);
    final pass = questions.map((q) => q.answer).toList();
    pass[0] = fail[0];
    expect(await service.finishTest(first.id, questions, pass), 4);
    expect(service.unlocked(next), true);
    expect(service.stars(first), 2);
    final restored = JourneyService();
    await restored.load();
    expect(restored.current.id, next.id);
    expect(restored.totalStars, 2);
  });
  test(
      'test validation uses canonical answers and rejects duplicated or foreign questions',
      () async {
    final service = JourneyService();
    await service.load();
    final level = journeyLevels.first;
    await learn(service, level);
    final questions = level.questions();
    final forged = questions
        .map((q) => JourneyQuestion(q.id, q.question, q.options,
            (q.answer + 1) % q.options.length, q.explanation))
        .toList();
    expect(
        await service.finishTest(
            level.id, forged, forged.map((q) => q.answer).toList()),
        0);
    await expectLater(
        service.finishTest(
            level.id, List.filled(5, questions.first), List.filled(5, 0)),
        throwsArgumentError);
    await expectLater(service.finishTest(level.id, questions, [99, 0, 0, 0, 0]),
        throwsArgumentError);
    expect(service.completedCount, 0);
  });
  test(
      'all twelve levels can be completed; replays never remove progress or duplicate stars',
      () async {
    final service = JourneyService();
    await service.load();
    for (final level in journeyLevels) {
      expect(level.words.length, 2);
      expect(level.questions().length, 5);
      expect(service.unlocked(level), true);
      await learn(service, level);
      final questions = level.questions();
      await service.finishTest(
          level.id, questions, questions.map((q) => q.answer).toList());
      if (level.boss) {
        await service.finishDialogue(level.id,
            bossDialogues[level.id]!.map((q) => q.options[q.answer]).toList());
      }
    }
    expect(service.completedCount, 12);
    expect(service.totalStars, 36);
    final questions = journeyLevels.first.questions();
    await service.finishTest('j1', questions,
        questions.map((q) => (q.answer + 1) % q.options.length).toList());
    expect(service.totalStars, 36);
    expect(service.best(journeyLevels.first), 5);
    final restored = JourneyService();
    await restored.load();
    expect(restored.totalStars, 36);
  });
  test(
      'failed persistence does not award words or unlock a level and can be retried',
      () async {
    final prefs = FailingPrefs(), service = JourneyService();
    await service.load(preferences: prefs);
    final level = journeyLevels.first, word = level.words.first;
    prefs.fail = true;
    await expectLater(service.verifyWord(level.id, word.id, word.translation),
        throwsStateError);
    expect(service.wordLearned(level, word.id), false);
    prefs.fail = false;
    await learn(service, level);
    final questions = level.questions(),
        answers = questions.map((q) => q.answer).toList();
    prefs.fail = true;
    await expectLater(
        service.finishTest(level.id, questions, answers), throwsStateError);
    expect(service.best(level), 0);
    expect(service.unlocked(journeyLevels[1]), false);
    prefs.fail = false;
    await service.finishTest(level.id, questions, answers);
    expect(service.unlocked(journeyLevels[1]), true);
  });
  test('simultaneous verified words are persisted without losing either',
      () async {
    final service = JourneyService();
    await service.load();
    final level = journeyLevels.first;
    await Future.wait(level.words.map(
        (word) => service.verifyWord(level.id, word.id, word.translation)));
    final restored = JourneyService();
    await restored.load();
    expect(restored.wordsReady(level), true);
    expect(restored.readyForTest(level), false);
  });
  test(
      'unknown save fields, malformed values and orphaned completion do not open the path',
      () async {
    SharedPreferences.setMockInitialValues({
      'journey_v1': jsonEncode({
        'j1': {
          'words': ['not-a-card'],
          'best': 999
        },
        'j8': {
          'words': ['h7', 'h8'],
          'best': 5
        },
      })
    });
    final service = JourneyService();
    await service.load();
    expect(service.completedCount, 0);
    expect(service.totalStars, 0);
    expect(service.current.id, 'j1');
    expect(service.unlocked(journeyLevels.last), false);
  });
  test(
      'story and sentence challenges gate tests and persist only verified answers',
      () async {
    final prefs = FailingPrefs(), service = JourneyService();
    await service.load(preferences: prefs);
    final level = journeyLevels.first;
    await expectLater(
        service.verifyChallenge(level.id, 'order', level.story.sentence),
        throwsStateError);
    for (final w in level.words) {
      await service.verifyWord(level.id, w.id, w.translation);
    }
    expect(await service.verifyChallenge(level.id, 'read:0', 'wrong'), false);
    await expectLater(
        service.finishTest(level.id, level.questions(), [0, 0, 0, 0, 0]),
        throwsStateError);
    prefs.fail = true;
    await expectLater(
        service.verifyChallenge(
            level.id, 'read:0', level.story.questions.first.options.first),
        throwsStateError);
    expect(service.challengeDone(level, 'read:0'), false);
    prefs.fail = false;
    await quests(service, level);
    expect(service.readyForTest(level), true);
    final restored = JourneyService();
    await restored.load(preferences: prefs);
    expect(restored.questsDone(level), true);
  });
  test('a passing boss test never opens the next world before a genuine duel',
      () async {
    final service = JourneyService();
    await service.load();
    for (final level in journeyLevels.take(4)) {
      await learn(service, level);
      final q = level.questions();
      await service.finishTest(level.id, q, q.map((q) => q.answer).toList());
    }
    final boss = journeyLevels[3];
    expect(service.bossReady(boss), true);
    expect(service.unlocked(journeyLevels[4]), false);
    final replies =
        bossDialogues[boss.id]!.map((q) => q.options[q.answer]).toList();
    await expectLater(service.finishDialogue(boss.id, replies.take(2).toList()),
        throwsArgumentError);
    PracticeRecord record(String scenario, GameStatus status) => PracticeRecord(
            id: 'battle',
            date: DateTime.now(),
            character: GameCharacter.officer,
            status: status,
            trust: 80,
            patience: 80,
            xp: 100,
            scenarioId: scenario,
            messages: [
              for (var i = 0; i < 2; i++)
                ChatMessage(
                    text: 'I am visiting my sister.',
                    isPlayer: true,
                    timestamp: DateTime.now())
            ],
            feedback: const []);
    await expectLater(
        service.recordAiVictory(
            boss.id, record('journey-free-j4-0', GameStatus.win)),
        throwsStateError);
    await expectLater(
        service.recordAiVictory(
            boss.id, record(boss.opponent!.customId!, GameStatus.inProgress)),
        throwsStateError);
    await service.recordAiVictory(
        boss.id, record(boss.opponent!.customId!, GameStatus.win));
    expect(service.unlocked(journeyLevels[4]), true);
    expect(service.bossMode(boss), 'ai');
    await service.finishDialogue(boss.id, replies);
    expect(service.bossMode(boss), 'ai');
  });
  test(
      'v1 completed levels migrate without resetting stars; partial saves still require new quests',
      () async {
    SharedPreferences.setMockInitialValues({
      'journey_v1': jsonEncode({
        for (final l in journeyLevels.take(4))
          l.id: {'words': l.wordIds, 'best': 5},
        'j5': {'words': journeyLevels[4].wordIds, 'best': 0},
      })
    });
    final service = JourneyService();
    await service.load();
    expect(service.completedCount, 4);
    expect(service.totalStars, 12);
    expect(service.bossMode(journeyLevels[3]), 'legacy');
    expect(service.current.id, 'j5');
    expect(service.wordsReady(journeyLevels[4]), true);
    expect(service.questsDone(journeyLevels[4]), false);
    await quests(service, journeyLevels[4]);
    final restored = JourneyService();
    await restored.load();
    expect(restored.completedCount, 4);
    expect(restored.questsDone(journeyLevels[4]), true);
  });
}
