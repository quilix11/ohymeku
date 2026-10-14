import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/journey_level.dart';
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
      'all eight levels can be completed; replays never remove progress or duplicate stars',
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
    }
    expect(service.completedCount, 8);
    expect(service.totalStars, 24);
    final questions = journeyLevels.first.questions();
    await service.finishTest('j1', questions,
        questions.map((q) => (q.answer + 1) % q.options.length).toList());
    expect(service.totalStars, 24);
    expect(service.best(journeyLevels.first), 5);
    final restored = JourneyService();
    await restored.load();
    expect(restored.totalStars, 24);
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
    expect(restored.readyForTest(level), true);
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
}
