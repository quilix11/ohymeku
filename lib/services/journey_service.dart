import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journey_level.dart';
import '../models/journey_story.dart';
import '../models/practice_record.dart';
import '../models/game_state.dart';

class JourneyService extends ChangeNotifier {
  late SharedPreferences _prefs;
  final Map<String, Set<String>> _words = {};
  final Map<String, int> _scores = {};
  final Map<String, Set<String>> _quests = {};
  final Map<String, String> _bosses = {};
  bool challengeDone(JourneyLevel level, String id) =>
      _quests[level.id]?.contains(id) ?? false;
  bool questsDone(JourneyLevel level) =>
      level.challengeIds.every((id) => challengeDone(level, id));
  bool bossDefeated(JourneyLevel level) =>
      !level.boss || _bosses.containsKey(level.id);
  String? bossMode(JourneyLevel level) => _bosses[level.id];
  bool wordsReady(JourneyLevel level) =>
      level.wordIds.every((id) => wordLearned(level, id));
  bool bossReady(JourneyLevel level) =>
      level.boss && unlocked(level) && readyForTest(level) && best(level) >= 4;
  Future<void> _pending = Future.value();
  JourneyLevel get current => journeyLevels.firstWhere((l) => !completed(l),
      orElse: () => journeyLevels.last);
  int get completedCount => journeyLevels.where(completed).length;
  int best(JourneyLevel level) => _scores[level.id] ?? 0;
  bool wordLearned(JourneyLevel level, String id) =>
      _words[level.id]?.contains(id) ?? false;
  bool readyForTest(JourneyLevel level) =>
      wordsReady(level) && questsDone(level);
  bool completed(JourneyLevel level) =>
      unlocked(level) &&
      readyForTest(level) &&
      best(level) >= 4 &&
      bossDefeated(level);
  int stars(JourneyLevel level) =>
      completed(level) ? (best(level) == 5 ? 3 : 2) : 0;
  int get totalStars => journeyLevels.fold(0, (sum, l) => sum + stars(l));
  bool unlocked(JourneyLevel level) {
    final index = journeyLevels.indexWhere((l) => l.id == level.id);
    return index == 0 || (index > 0 && completed(journeyLevels[index - 1]));
  }

  JourneyLevel _level(String id) => journeyLevels.firstWhere((l) => l.id == id,
      orElse: () => throw ArgumentError('Невідомий рівень.'));
  Future<void> load({SharedPreferences? preferences}) async {
    _prefs = preferences ?? await SharedPreferences.getInstance();
    try {
      final saved = _prefs.getString('journey_v2');
      final legacy = saved == null;
      final data = jsonDecode(saved ?? _prefs.getString('journey_v1') ?? '{}');
      var legacyPrefix = true;
      if (data is Map) {
        for (final level in journeyLevels) {
          final item = data[level.id];
          if (item is! Map) {
            legacyPrefix = false;
            continue;
          }
          final words = item['words'];
          if (words is List) {
            _words[level.id] =
                words.whereType<String>().where(level.wordIds.contains).toSet();
          }
          final quests = item['quests'];
          if (quests is List) {
            _quests[level.id] = quests
                .whereType<String>()
                .where(level.challengeIds.contains)
                .toSet();
          }
          final boss = item['boss'];
          if (level.boss && ['ai', 'dialogue', 'legacy'].contains(boss)) {
            _bosses[level.id] = boss as String;
          }
          final score = item['best'];
          if (score is int && score >= 0 && score <= 5) {
            _scores[level.id] = score;
          }
          if (legacy) {
            legacyPrefix =
                legacyPrefix && wordsReady(level) && best(level) >= 4;
            if (legacyPrefix) {
              _quests[level.id] = level.challengeIds.toSet();
              if (level.boss) _bosses[level.id] = 'legacy';
            }
          }
        }
      }
    } catch (_) {
      /* Damaged optional game progress does not prevent learning. */
    }
    notifyListeners();
  }

  Future<T> _write<T>(Future<T> Function() operation) {
    final task = _pending.then((_) => operation());
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> _save(Map<String, Set<String>> words, Map<String, int> scores,
      {Map<String, Set<String>>? quests, Map<String, String>? bosses}) async {
    final nextQuests = quests ?? _quests, nextBosses = bosses ?? _bosses;
    final data = {
      for (final l in journeyLevels)
        l.id: {
          'words': (words[l.id] ?? {}).toList(),
          'best': scores[l.id] ?? 0,
          'quests': (nextQuests[l.id] ?? {}).toList(),
          if (nextBosses.containsKey(l.id)) 'boss': nextBosses[l.id]
        }
    };
    if (!await _prefs.setString('journey_v2', jsonEncode(data))) {
      throw StateError('Не вдалося зберегти пригоду. Спробуй ще раз.');
    }
    _words
      ..clear()
      ..addAll(words);
    _scores
      ..clear()
      ..addAll(scores);
    if (quests != null) {
      _quests
        ..clear()
        ..addAll(quests);
    }
    if (bosses != null) {
      _bosses
        ..clear()
        ..addAll(bosses);
    }
    notifyListeners();
  }

  Future<bool> verifyWord(String levelId, String wordId, String translation) =>
      _write(() async {
        final level = _level(levelId);
        if (!unlocked(level)) {
          throw StateError('Спочатку заверши попередній рівень.');
        }
        final word = level.words.firstWhere((w) => w.id == wordId,
            orElse: () => throw ArgumentError('Цього слова немає на рівні.'));
        if (word.translation != translation) return false;
        final next = {
          for (final entry in _words.entries)
            entry.key: Set<String>.of(entry.value)
        };
        (next[levelId] ??= {}).add(wordId);
        await _save(next, Map.of(_scores));
        return true;
      });
  Future<int> finishTest(
          String levelId, List<JourneyQuestion> questions, List<int> answers) =>
      _write(() async {
        final level = _level(levelId);
        if (!unlocked(level) || !readyForTest(level)) {
          throw StateError('Спочатку перевір слова та заверши сюжетні квести.');
        }
        final expected = level.questions();
        if (questions.length != 5 ||
            answers.length != 5 ||
            questions.map((q) => q.id).toSet().length != 5) {
          throw ArgumentError('Тест не завершений.');
        }
        var score = 0;
        for (var i = 0; i < questions.length; i++) {
          final q = questions[i];
          final source = expected.firstWhere((item) => item.id == q.id,
              orElse: () => throw ArgumentError('Невідоме завдання.'));
          if (q.options.length != source.options.length ||
              q.options.toSet().length != q.options.length ||
              !q.options.toSet().containsAll(source.options) ||
              answers[i] < 0 ||
              answers[i] >= q.options.length) {
            throw ArgumentError('Некоректна відповідь.');
          }
          // Resolve the canonical answer, rather than trusting a caller's answer index.
          if (q.options[answers[i]] == source.options[source.answer]) score++;
        }
        final scores = Map<String, int>.of(_scores);
        if (score > best(level)) scores[levelId] = score;
        await _save(
            {for (final e in _words.entries) e.key: Set.of(e.value)}, scores);
        return score;
      });
  Future<bool> verifyChallenge(
          String levelId, String challengeId, String answer) =>
      _write(() async {
        final level = _level(levelId);
        if (!unlocked(level) || !wordsReady(level)) {
          throw StateError('Спочатку перевір слова рівня.');
        }
        if (!level.challengeIds.contains(challengeId)) {
          throw ArgumentError('Невідомий квест.');
        }
        final correct = challengeId == 'order'
            ? answer == level.story.sentence
            : level.story.questions
                    .firstWhere((q) => q.id == challengeId)
                    .options[0] ==
                answer;
        if (!correct) return false;
        final quests = {
          for (final e in _quests.entries) e.key: Set<String>.of(e.value)
        };
        (quests[levelId] ??= {}).add(challengeId);
        await _save({
          for (final e in _words.entries) e.key: Set<String>.of(e.value)
        }, Map.of(_scores), quests: quests);
        return true;
      });
  Future<void> finishDialogue(String levelId, List<String> answers) =>
      _write(() async {
        final level = _level(levelId);
        if (!bossReady(level)) {
          throw StateError('До боса ведуть слова, квести й тест 4/5.');
        }
        final questions = bossDialogues[levelId]!;
        if (answers.length != questions.length ||
            List.generate(
                    questions.length,
                    (i) =>
                        answers[i] == questions[i].options[questions[i].answer])
                .contains(false)) {
          throw ArgumentError('Спочатку заверши всі три репліки дуелі.');
        }
        await _saveBoss(levelId, 'dialogue');
      });
  Future<void> recordAiVictory(String levelId, PracticeRecord record) =>
      _write(() async {
        final level = _level(levelId);
        if (!bossReady(level) ||
            record.scenarioId != level.opponent?.customId ||
            record.status != GameStatus.win ||
            record.messages.where((m) => m.isPlayer).length < 2) {
          throw StateError(
              'Печатку дає перемога в розмові з босом цього світу.');
        }
        await _saveBoss(levelId, 'ai');
      });
  Future<void> _saveBoss(String levelId, String mode) async {
    final bosses = Map<String, String>.of(_bosses);
    if (bosses[levelId] != 'ai') bosses[levelId] = mode;
    await _save({
      for (final e in _words.entries) e.key: Set<String>.of(e.value)
    }, Map.of(_scores), bosses: bosses);
  }
}
