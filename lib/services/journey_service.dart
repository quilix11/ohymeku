import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journey_level.dart';

class JourneyService extends ChangeNotifier {
  late SharedPreferences _prefs;
  final Map<String, Set<String>> _words = {};
  final Map<String, int> _scores = {};
  Future<void> _pending = Future.value();
  JourneyLevel get current => journeyLevels.firstWhere((l) => !completed(l),
      orElse: () => journeyLevels.last);
  int get completedCount => journeyLevels.where(completed).length;
  int best(JourneyLevel level) => _scores[level.id] ?? 0;
  bool wordLearned(JourneyLevel level, String id) =>
      _words[level.id]?.contains(id) ?? false;
  bool readyForTest(JourneyLevel level) =>
      level.wordIds.every((id) => wordLearned(level, id));
  bool completed(JourneyLevel level) =>
      unlocked(level) && readyForTest(level) && best(level) >= 4;
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
      final data = jsonDecode(_prefs.getString('journey_v1') ?? '{}');
      if (data is Map) {
        for (final level in journeyLevels) {
          final item = data[level.id];
          if (item is! Map) continue;
          final words = item['words'];
          if (words is List) {
            _words[level.id] =
                words.whereType<String>().where(level.wordIds.contains).toSet();
          }
          final score = item['best'];
          if (score is int && score >= 0 && score <= 5) {
            _scores[level.id] = score;
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

  Future<void> _save(
      Map<String, Set<String>> words, Map<String, int> scores) async {
    final data = {
      for (final l in journeyLevels)
        l.id: {'words': (words[l.id] ?? {}).toList(), 'best': scores[l.id] ?? 0}
    };
    if (!await _prefs.setString('journey_v1', jsonEncode(data))) {
      throw StateError('Не вдалося зберегти пригоду. Спробуй ще раз.');
    }
    _words
      ..clear()
      ..addAll(words);
    _scores
      ..clear()
      ..addAll(scores);
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
          throw StateError('Спочатку перевір обидва слова рівня.');
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
}
