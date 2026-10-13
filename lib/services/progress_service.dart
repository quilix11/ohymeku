import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/practice_record.dart';
import '../models/user_profile.dart';

class ProgressService extends ChangeNotifier {
  late SharedPreferences _prefs;
  List<PracticeRecord> _records = [];
  final Map<String, String> achievements = {};
  final Map<String, int> activities = {};
  int get studiedWords =>
      activities.keys.where((k) => k.contains('|word:')).length;
  int get grammarAttempts =>
      activities.keys.where((k) => k.contains('|grammar:')).length;
  String _name = '';
  int _avatar = 0, _xp = 0;
  DateTime _joined = DateTime.now();
  static const _key = 'practice_progress_v2';
  Future<void> _pending = Future.value();

  List<PracticeRecord> get records => List.unmodifiable(_records);
  String get name => _name.isEmpty ? 'Мій профіль' : _name;
  String get editableName => _name;
  int get avatar => _avatar;
  DateTime get joined => _joined;
  int get wins => _records.where((r) => r.won).length;
  int get turns => _records.fold(0, (sum, r) => sum + r.turns);
  Set<DateTime> get practiceDays => {
        ..._records.map((r) => day(r.date)),
        ...activities.keys
            .map((k) => DateTime.tryParse(k.split('|').first))
            .whereType<DateTime>()
            .map(day),
      };
  void _unlock() {
    void award(String id, bool condition) {
      if (condition) {
        achievements.putIfAbsent(id, () => DateTime.now().toIso8601String());
      }
    }

    award('first_chat', _records.isNotEmpty);
    award('first_win', wins > 0);
    // Recover already-earned streaks from historical days, not just today's streak.
    final days = practiceDays;
    award(
        'streak3',
        days.any((d) =>
            days.contains(d.subtract(const Duration(days: 1))) &&
            days.contains(d.subtract(const Duration(days: 2)))));
    award('turns25', turns >= 25);
    award('words10', studiedWords >= 10);
    award('grammar10', grammarAttempts >= 10);
  }

  Future<void> recordActivity(String id, int xp) async {
    final key = '${day(DateTime.now()).toIso8601String()}|$id';
    final previous = activities[key] ?? 0;
    final next = xp.clamp(0, 10);
    if (next > previous) {
      activities[key] = next;
      _xp += next - previous;
    }
    _unlock();
    await _persist();
    notifyListeners();
  }

  static DateTime day(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
  int streakAt(DateTime now) {
    final days = practiceDays;
    var cursor = day(now);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  UserProfile get profile => UserProfile(
      xp: _xp,
      streakDays: streakAt(DateTime.now()),
      lastPlayDate: _records.isEmpty ? _joined : _records.first.date);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _xp = _prefs.getInt('xp') ?? 0;
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in (data['achievements'] as Map? ?? {}).entries) {
          if (e.value is String) achievements[e.key.toString()] = e.value;
        }
        for (final e in (data['activities'] as Map? ?? {}).entries) {
          if (e.value is int) activities[e.key.toString()] = e.value;
        }
        _name = data['name'] as String? ?? '';
        _avatar = (data['avatar'] as int? ?? 0).clamp(0, 3);
        _xp = data['xp'] as int? ?? _xp;
        _joined = DateTime.tryParse(data['joined'] as String? ?? '') ?? _joined;
        for (final item in data['records'] as List? ?? []) {
          try {
            _records.add(PracticeRecord.fromJson(
                Map<String, dynamic>.from(item as Map)));
          } on Object {/* Keep other valid records if one is damaged. */}
        }
        _records.sort((a, b) => b.date.compareTo(a.date));
      } on Object {/* Preserve legacy XP when storage cannot be decoded. */}
    }
    _unlock();
    await _persist();
    notifyListeners();
  }

  Future<void> saveProfile(String name, int avatar) async {
    _name = name.trim();
    _avatar = avatar.clamp(0, 3);
    await _persist();
    notifyListeners();
  }

  Future<void> recordSession(PracticeRecord record) async {
    if (_records.any((r) => r.id == record.id)) {
      await _persist();
      return;
    }
    _records = [record, ..._records];
    _xp += record.xp;
    _unlock();
    await _persist();
    notifyListeners();
  }

  int winsFor(GameCharacter character, {String? scenarioId}) => _records
      .where((r) =>
          r.character == character && r.scenarioId == scenarioId && r.won)
      .length;

  Future<void> _persist() {
    final value = jsonEncode({
      'achievements': achievements,
      'activities': activities,
      'name': _name,
      'avatar': _avatar,
      'xp': _xp,
      'joined': _joined.toIso8601String(),
      'records': _records.map((r) => r.toJson()).toList()
    });
    final operation = _pending.then((_) async {
      if (!await _prefs.setString(_key, value)) {
        throw StateError('Не вдалося зберегти прогрес.');
      }
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
