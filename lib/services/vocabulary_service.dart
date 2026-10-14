import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordCard {
  final String id, word, translation, example, deck, transcription;
  const WordCard(this.id, this.word, this.translation, this.example, this.deck,
      {this.transcription = ''});
  Map<String, String> toJson() => {
        'id': id,
        'word': word,
        'translation': translation,
        'example': example,
        'deck': deck,
        'transcription': transcription,
      };
}

class VocabularyService extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool ready = false;
  final Map<String, Map<String, dynamic>> reviews = {};
  bool isDue(String id) {
    final next = DateTime.tryParse(reviews[id]?['next'] as String? ?? '');
    return next == null || !next.isAfter(DateTime.now());
  }

  Map<String, dynamic>? snapshot(String id) =>
      reviews[id] == null ? null : Map.of(reviews[id]!);
  Future<void> restore(
      String id, bool wasKnown, Map<String, dynamic>? prior) async {
    final current = snapshot(id), currentKnown = known.contains(id);
    if (wasKnown) {
      known.add(id);
    } else {
      known.remove(id);
    }
    if (prior == null) {
      reviews.remove(id);
    } else {
      reviews[id] = prior;
    }
    try {
      await _save();
    } catch (_) {
      if (currentKnown) {
        known.add(id);
      } else {
        known.remove(id);
      }
      if (current == null) {
        reviews.remove(id);
      } else {
        reviews[id] = current;
      }
      rethrow;
    }
    notifyListeners();
  }

  final Set<String> known = {};
  final List<WordCard> custom = [];
  final List<WordCard> archived = [];
  final Set<String> _archiveKnown = {};
  Future<void> _pending = Future.value();
  List<WordCard> get cards => [...starterCards, ...custom];
  Future<void> load() async {
    if (ready) return;
    _prefs = await SharedPreferences.getInstance();
    known.addAll(_prefs!.getStringList('words_known_v1') ?? []);
    try {
      final data =
          jsonDecode(_prefs!.getString('word_reviews_v1') ?? '{}') as Map;
      for (final entry in data.entries) {
        if (entry.value is Map) {
          reviews[entry.key.toString()] =
              Map<String, dynamic>.from(entry.value);
        }
      }
    } catch (_) {}
    try {
      for (final item
          in jsonDecode(_prefs!.getString('words_custom_v1') ?? '[]') as List) {
        if (item is Map &&
            item['id'] is String &&
            item['word'] is String &&
            item['translation'] is String) {
          final card = WordCard(
              item['id'],
              item['word'],
              item['translation'],
              item['example'] as String? ?? '',
              item['deck'] as String? ?? 'Мої слова',
              transcription: item['transcription'] as String? ?? '');
          if (item['deleted'] == true) {
            archived.add(card);
            if (item['was_known'] == true) _archiveKnown.add(card.id);
            known.remove(card.id);
          } else {
            custom.add(card);
          }
        }
      }
    } catch (_) {}
    ready = true;
    notifyListeners();
  }

  Future<void> mark(String id, bool learned) async {
    final before = snapshot(id), wasKnown = known.contains(id);
    final old = reviews[id];
    final streak = learned ? ((old?['streak'] as int?) ?? 0) + 1 : 0;
    final days = streak == 1
        ? 1
        : streak == 2
            ? 3
            : (streak * 3).clamp(1, 60);
    reviews[id] = {
      'streak': streak,
      'lapses': ((old?['lapses'] as int?) ?? 0) + (learned ? 0 : 1),
      'next': DateTime.now()
          .add(learned ? Duration(days: days) : const Duration(minutes: 10))
          .toIso8601String()
    };
    if (learned) {
      known.add(id);
    } else {
      known.remove(id);
    }
    try {
      await _save();
    } catch (_) {
      if (wasKnown) {
        known.add(id);
      } else {
        known.remove(id);
      }
      if (before == null) {
        reviews.remove(id);
      } else {
        reviews[id] = before;
      }
      rethrow;
    }
    notifyListeners();
  }

  Future<void> add(String word, String translation, String example,
      {String transcription = ''}) async {
    if (cards.any((c) => c.word.toLowerCase() == word.trim().toLowerCase())) {
      return;
    }
    final card = WordCard(DateTime.now().microsecondsSinceEpoch.toString(),
        word.trim(), translation.trim(), example.trim(), 'Мої слова',
        transcription: transcription.trim());
    custom.add(card);
    try {
      await _save();
    } catch (_) {
      custom.remove(card);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> addGenerated(List<dynamic> cards, String deck) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final additions = cards
        .asMap()
        .entries
        .map((e) => WordCard('${stamp}_${e.key}', e.value['word'],
            e.value['translation'], e.value['example'], deck,
            transcription: e.value['transcription'] ?? ''))
        .toList();
    custom.addAll(additions);
    try {
      await _save();
    } catch (_) {
      custom.removeWhere((c) => additions.contains(c));
      rethrow;
    }
    notifyListeners();
  }

  Future<void> editCustom(WordCard replacement) async {
    final index = custom.indexWhere((c) => c.id == replacement.id);
    if (index < 0) throw StateError('Редагувати можна лише власні картки.');
    if (cards.any((c) =>
        c.id != replacement.id &&
        c.word.toLowerCase() == replacement.word.toLowerCase())) {
      throw StateError('Таке слово вже є у словнику.');
    }
    final old = custom[index];
    custom[index] = replacement;
    try {
      await _save();
    } catch (_) {
      custom[index] = old;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> archiveCustom(String id) async {
    final index = custom.indexWhere((c) => c.id == id);
    if (index < 0) throw StateError('Видаляти можна лише власні картки.');
    if (archived.length >= 50) {
      throw StateError(
          'Архів містить 50 карток. Спочатку віднови потрібні слова.');
    }
    final card = custom.removeAt(index), wasKnown = known.remove(id);
    archived.add(card);
    if (wasKnown) _archiveKnown.add(id);
    try {
      await _save();
    } catch (_) {
      archived.remove(card);
      custom.insert(index, card);
      if (wasKnown) known.add(id);
      _archiveKnown.remove(id);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> restoreCustom(String id) async {
    final index = archived.indexWhere((c) => c.id == id);
    if (index < 0) throw StateError('Картку не знайдено в архіві.');
    final card = archived[index];
    if (cards.any((c) => c.word.toLowerCase() == card.word.toLowerCase())) {
      throw StateError('Таке слово вже є у словнику.');
    }
    archived.removeAt(index);
    custom.add(card);
    final wasKnown = _archiveKnown.remove(id);
    if (wasKnown) known.add(id);
    try {
      await _save();
    } catch (_) {
      custom.remove(card);
      archived.insert(index, card);
      known.remove(id);
      if (wasKnown) _archiveKnown.add(id);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _save() {
    final learned = known.toList(),
        words = jsonEncode([
          ...custom.map((c) => c.toJson()),
          ...archived.map((c) => {
                ...c.toJson(),
                'deleted': true,
                'was_known': _archiveKnown.contains(c.id)
              }),
        ]),
        schedule = jsonEncode(reviews);
    final task = _pending.then((_) async {
      if (!await _prefs!.setString('word_reviews_v1', schedule) ||
          !await _prefs!.setStringList('words_known_v1', learned) ||
          !await _prefs!.setString('words_custom_v1', words)) {
        throw StateError('Не вдалося зберегти слова.');
      }
    });
    _pending = task.catchError((Object _) {});
    return task;
  }
}

const starterCards = [
  WordCard('a1', 'boarding pass', 'посадковий талон',
      'May I see your boarding pass?', 'Подорож'),
  WordCard(
      'a2', 'purpose', 'мета', 'What is the purpose of your visit?', 'Подорож'),
  WordCard('a3', 'accommodation', 'житло; місце проживання',
      'I have already booked my accommodation.', 'Подорож'),
  WordCard('a4', 'return ticket', 'зворотний квиток',
      'My return ticket is for next Friday.', 'Подорож'),
  WordCard('a5', 'luggage', 'багаж', 'I only have hand luggage.', 'Подорож'),
  WordCard('a6', 'departure', 'відправлення; виліт',
      'The departure time has changed.', 'Подорож'),
  WordCard(
      'a7', 'declare', 'декларувати', 'I have nothing to declare.', 'Подорож'),
  WordCard('a8', 'stay', 'перебування; залишатися',
      'I plan to stay for five days.', 'Подорож'),
  WordCard('h1', 'experience', 'досвід',
      'I have three years of experience in sales.', 'Робота'),
  WordCard('h2', 'responsibility', 'відповідальність; обов’язок',
      'Training new colleagues was my responsibility.', 'Робота'),
  WordCard('h3', 'achievement', 'досягнення',
      'My biggest achievement was launching our new product.', 'Робота'),
  WordCard('h4', 'deadline', 'кінцевий термін',
      'We finished the project before the deadline.', 'Робота'),
  WordCard('h5', 'strength', 'сильна сторона',
      'My greatest strength is listening to people.', 'Робота'),
  WordCard('h6', 'challenge', 'складне завдання; виклик',
      'Tell me about a challenge you overcame.', 'Робота'),
  WordCard('h7', 'improve', 'покращувати',
      'I want to improve my communication skills.', 'Робота'),
  WordCard('h8', 'teamwork', 'командна робота',
      'Good teamwork helped us solve the problem.', 'Робота'),
  WordCard(
      's1', 'library', 'бібліотека', 'The library opens at nine.', 'Школа'),
  WordCard('s2', 'borrow', 'позичати', 'May I borrow this book?', 'Школа'),
  WordCard('s3', 'lesson', 'урок', 'Our lesson starts at ten.', 'Школа'),
  WordCard(
      's4', 'schedule', 'розклад', 'Check the schedule before class.', 'Школа'),
  WordCard(
      's5', 'clue', 'підказка', 'The clue is under the old tree.', 'Школа'),
  WordCard('s6', 'discover', 'відкривати; знаходити',
      'We discover a secret garden.', 'Школа'),
  WordCard(
      's7', 'explain', 'пояснювати', 'Can you explain your answer?', 'Школа'),
  WordCard('s8', 'curious', 'допитливий', 'Meku is curious about everything.',
      'Школа'),
];
