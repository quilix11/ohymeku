import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning_exercise.dart';

class LearnerService extends ChangeNotifier {
  late SharedPreferences _prefs;
  final List<LearningExercise> personal = [];
  final Map<String, Map<String, dynamic>> reviews = {};
  final List<bool> recent = [];
  Map<String, dynamic>? placement;
  Future<void> _pending = Future.value();
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(_prefs.getString('learner_v1') ?? '{}') as Map;
      for (final item in data['personal'] as List? ?? []) {
        final exercise = LearningExercise.parse(item);
        if (exercise != null) personal.add(exercise);
      }
      for (final e in (data['reviews'] as Map? ?? {}).entries) {
        if (e.value is Map) {
          reviews[e.key.toString()] = Map<String, dynamic>.from(e.value);
        }
      }
      recent.addAll((data['recent'] as List? ?? []).whereType<bool>().take(12));
      if (data['placement'] is Map) {
        placement = Map<String, dynamic>.from(data['placement']);
      }
    } catch (_) {/* Offline authored exercises remain available. */}
  }

  String effectiveLevel(String base, bool adaptive) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
    final start = levels.indexOf(base).clamp(0, 4);
    if (!adaptive || recent.length < 8) return levels[start];
    final accuracy = recent.where((v) => v).length / recent.length;
    final shift = accuracy >= .85
        ? 1
        : accuracy < .5
            ? -1
            : 0;
    return levels[(start + shift).clamp(0, 4)];
  }

  Future<void> resetAdaptation() async {
    final previous = List<bool>.of(recent);
    recent.clear();
    try {
      await _save();
    } catch (_) {
      recent.addAll(previous);
      rethrow;
    }
    notifyListeners();
  }

  List<LearningExercise> due(String level, List<String> interests) {
    final now = DateTime.now();
    final rank = ['A1', 'A2', 'B1', 'B2', 'C1'].indexOf(level).clamp(0, 4);
    final result = [...personal, ...practiceExercises].where((e) {
      final next = DateTime.tryParse(reviews[e.id]?['next'] as String? ?? '');
      return next == null || !next.isAfter(now);
    }).toList();
    int priority(LearningExercise e) =>
        (personal.contains(e) ? -20 : 0) +
        (reviews.containsKey(e.id) ? -10 : 0) +
        ((placement?['topics'] as Map?)?[e.topic] == false ? -4 : 0) +
        (e.difficulty - rank).abs() * 3 -
        (interests.contains(e.interest) ? 2 : 0);
    result.sort((a, b) => priority(a).compareTo(priority(b)));
    return result.take(8).toList();
  }

  Future<void> capture(LearningExercise exercise) async {
    if (personal.any((e) => e.question == exercise.question)) return;
    final data = exercise.toJson();
    data['id'] = 'personal:${sha256.convert(utf8.encode(exercise.question))}';
    final stored = LearningExercise.parse(data)!;
    personal.add(stored);
    try {
      await _save();
    } catch (_) {
      personal.remove(stored);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> answer(LearningExercise exercise, bool correct) async {
    final previousRecent = List<bool>.of(recent);
    final prior = reviews[exercise.id];
    final streak = correct ? ((prior?['streak'] as int?) ?? 0) + 1 : 0;
    final days = streak == 1
        ? 1
        : streak == 2
            ? 3
            : (streak * 3).clamp(1, 30);
    reviews[exercise.id] = {
      'streak': streak,
      'next': DateTime.now()
          .add(correct ? Duration(days: days) : const Duration(minutes: 10))
          .toIso8601String(),
      'attempts': ((prior?['attempts'] as int?) ?? 0) + 1,
      'correct': ((prior?['correct'] as int?) ?? 0) + (correct ? 1 : 0)
    };
    recent.add(correct);
    if (recent.length > 12) recent.removeAt(0);
    try {
      await _save();
    } catch (_) {
      if (prior == null) {
        reviews.remove(exercise.id);
      } else {
        reviews[exercise.id] = prior;
      }
      recent
        ..clear()
        ..addAll(previousRecent);
      rethrow;
    }
    notifyListeners();
  }

  Future<String> savePlacement(List<int> answers) async {
    final byLevel = List<int>.filled(5, 0);
    final byTopic = <String, bool>{};
    for (var i = 0; i < placementExercises.length; i++) {
      final e = placementExercises[i];
      final correct = answers[i] == e.answer;
      if (correct) byLevel[e.difficulty]++;
      byTopic[e.topic] = correct;
    }
    var band = 0;
    // Require at least two of three correct at each preceding band.
    for (var i = 0; i < 5; i++) {
      if (byLevel[i] < 2) break;
      band = i;
    }
    final level = ['A1', 'A2', 'B1', 'B2', 'C1'][band];
    placement = {
      'date': DateTime.now().toIso8601String(),
      'level': level,
      'score': byLevel.reduce((a, b) => a + b),
      'bands': byLevel,
      'topics': byTopic
    };
    recent.clear();
    await _save();
    notifyListeners();
    return level;
  }

  Future<void> _save() {
    final value = jsonEncode({
      'personal': personal.map((e) => e.toJson()).toList(),
      'reviews': reviews,
      'recent': recent,
      'placement': placement
    });
    final task = _pending.then((_) async {
      if (!await _prefs.setString('learner_v1', value)) {
        throw StateError('Не вдалося зберегти навчання.');
      }
    });
    _pending = task.catchError((Object _) {});
    return task;
  }
}
