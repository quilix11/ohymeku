import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/learning_service.dart';
import '../services/ai_service.dart';
import 'story_catalog.dart';
import 'story_model.dart';

typedef StoryRequest = Future<Map<String, dynamic>> Function(
    String rules, Map<String, dynamic> input);

class StoryService extends ChangeNotifier {
  static const storageKey = 'letter_chronicles_v1';
  late SharedPreferences _prefs;
  final List<StoryChapter> _generated = [];
  final Map<String, int> _completed = {};
  final Map<String, String> _decisions = {};
  final Set<String> _clues = {};
  bool busy = false;
  bool autoContinue = true;
  Future<void> setAutoContinue(bool value) async {
    if (!await _prefs.setBool('story_auto_continue', value)) {
      throw StateError('Не вдалося зберегти налаштування.');
    }
    autoContinue = value;
    notifyListeners();
  }

  Future<void> _writes = Future.value();
  bool _disposed = false;
  List<StoryChapter> get chapters =>
      List.unmodifiable([...storyChapters, ..._generated]);
  int done(StoryChapter c) => (_completed[c.id] ?? 0).clamp(0, c.scenes.length);
  bool finished(StoryChapter c) => done(c) == c.scenes.length;
  List<String> get clues => List.unmodifiable(_clues);
  Map<String, String> get decisions => Map.unmodifiable(_decisions);
  bool unlocked(int index) => index == 0 || finished(chapters[index - 1]);
  StoryChapter get current =>
      chapters.firstWhere((c) => !finished(c), orElse: () => chapters.last);
  bool get caughtUp => chapters.every(finished);
  String? consequence(StoryChapter c, int scene) =>
      _decisions['${c.id}:$scene'];

  Future<void> load({SharedPreferences? preferences}) async {
    _prefs = preferences ?? await SharedPreferences.getInstance();
    autoContinue = _prefs.getBool('story_auto_continue') ?? true;
    final raw = _prefs.getString(storageKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map;
      for (final value in j['generated'] as List? ?? []) {
        final c =
            StoryChapter.fromJson(Map<String, dynamic>.from(value as Map));
        if (c.generated && !chapters.any((old) => old.id == c.id)) {
          _generated.add(c);
        }
      }
      for (final e in (j['completed'] as Map? ?? {}).entries) {
        if (e.value is int && chapters.any((c) => c.id == e.key)) {
          _completed[e.key as String] = e.value;
        }
      }
      for (final e in (j['decisions'] as Map? ?? {}).entries) {
        if (e.key is String && e.value is String) _decisions[e.key] = e.value;
      }
      _clues.addAll((j['clues'] as List? ?? []).whereType<String>());
    } on Object {
      /* Keep authored chapters available if an imported save is damaged. */
    }
  }

  Map<String, dynamic> snapshot() => {
        'generated': _generated.map((c) => c.toJson()).toList(),
        'completed': _completed,
        'decisions': _decisions,
        'clues': _clues.toList()
      };

  Future<void> _persist(Map<String, dynamic> next) async {
    if (!await _prefs.setString(storageKey, jsonEncode(next))) {
      throw StateError('Не вдалося зберегти історію. Спробуй ще раз.');
    }
  }

  Future<void> choose(
      String chapterId, int sceneIndex, int answer, int choice) {
    final operation = _writes.then((_) async {
      final catalog = chapters;
      final index = catalog.indexWhere((c) => c.id == chapterId);
      if (index < 0 || !unlocked(index)) throw StateError('Розділ ще закрито.');
      final c = catalog[index];
      if (sceneIndex != done(c) || finished(c)) {
        throw StateError('Сцена вже змінилася.');
      }
      final scene = c.scenes[sceneIndex];
      if (answer != scene.answer ||
          choice < 0 ||
          choice >= scene.choices.length) {
        throw StateError('Спершу знайди правильну відповідь у репліці.');
      }
      final completed = {..._completed, c.id: sceneIndex + 1};
      final decisions = {
        ..._decisions,
        '$chapterId:$sceneIndex': scene.consequences[choice]
      };
      final clues = {..._clues, scene.clue};
      await _persist({
        ...snapshot(),
        'completed': completed,
        'decisions': decisions,
        'clues': clues.toList()
      });
      if (_disposed) return;
      _completed.addAll(completed);
      _decisions.addAll(decisions);
      _clues.addAll(clues);
      notifyListeners();
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> generate(
      {required String name,
      required String level,
      required bool offline,
      List<String> interests = const [],
      StoryRequest? request}) async {
    if (busy) return;
    if (offline) {
      throw const AiException(
          'Збережені розділи доступні офлайн. Для нової історії потрібен інтернет.');
    }
    if (!caughtUp) throw StateError('Спочатку заверши відкриту історію.');
    busy = true;
    notifyListeners();
    final ai = request == null ? LearningService() : null;
    try {
      final input = {
        'canon': storyCanon,
        'player_name': name,
        'level': level,
        'interests': interests,
        'confirmed_clues': _clues.toList(),
        'player_choices': _decisions,
        'previous_chapters': chapters
            .map((c) => {'title': c.title, 'summary': c.summary})
            .toList(),
        'chapter_number': chapters.length + 1
      };
      final json = await (request ??
              ((rules, input) =>
                  ai!.request(rules, input, maxOutputTokens: 8192)))(
          '''Write ONE substantial next chapter for a Ukrainian English-learning story.
Follow canon, confirmed clues and choices strictly. Continue from the actual ending.
After the authored Lumen arc, explore the unmapped city beyond the river with a new
mystery; do not undo Lyra's freedom. Keep recurring allies, add at most one original
character. Choices must reflect earlier consequences and change concrete events.
Use the player's name naturally as {name}. Each scene: Ukrainian narration (100-180
words), an English dialogue (2-4 sentences) at requested CEFR, and a comprehension
question in Ukrainian with 3 DISTINCT English options and exactly ONE correct
answer. Distribute correct indices. No cruelty or graphic violence. Add a fair clue,
2 meaningful choices, and 2 corresponding concrete Ukrainian consequences. End with
a discovery that supports another chapter. Do not claim an entire season is finished.
Return {"title":"...","location":"...","summary":"accurate summary of events introduced",
"scenes":[{"speaker":"name","text":"narration","english":"dialogue","question":"...",
"options":["...","...","..."],"answer":0,"clue":"fact","choices":["...","..."],
"consequences":["...","..."]}]} with 4 scenes. All fields required.''', input);
      if (_disposed) return;
      final chapter =
          StoryChapter.fromJson(json, id: 'generated_${chapters.length + 1}');
      await _persist({
        ...snapshot(),
        'generated': [..._generated, chapter].map((c) => c.toJson()).toList()
      });
      if (!_disposed) _generated.add(chapter);
    } on FormatException {
      throw const AiException(
          'Продовження вийшло неповним. Історію збережено — спробуй ще раз.');
    } finally {
      ai?.dispose();
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
