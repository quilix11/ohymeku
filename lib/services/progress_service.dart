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
  String _nickname = '', _bio = '';
  int _avatarColor = 0;
  String get nickname => _nickname;
  String get bio => _bio;
  int get avatarColor => _avatarColor;
  String get dialogueName => _nickname.isNotEmpty
      ? _nickname
      : _name.isNotEmpty
          ? _name
          : 'Мандрівник';
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
        _nickname = data['nickname'] as String? ?? '';
        _bio = data['bio'] as String? ?? '';
        _avatarColor = (data['avatarColor'] as int? ?? 0).clamp(0, 5);
        _avatar = (data['avatar'] as int? ?? 0).clamp(0, 11);
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

  Map<String, dynamic> profileData() => {
        'name': _name,
        'nickname': _nickname,
        'bio': _bio,
        'avatar': _avatar,
        'avatarColor': _avatarColor
      };

  Future<void> saveProfile(String name, int avatar,
      {String? nickname, String? bio, int? avatarColor}) async {
    final clean = name.trim();
    final nick = (nickname ?? _nickname).trim().replaceFirst(RegExp(r'^@'), '');
    final description = (bio ?? _bio).trim();
    if (clean.length > 24 ||
        nick.length > 24 ||
        description.length > 160 ||
        nick.isNotEmpty &&
            !RegExp(r'^[\p{L}\p{N}_ .-]+$', unicode: true).hasMatch(nick)) {
      throw ArgumentError('Ім’я та нік — до 24 символів, про себе — до 160.');
    }
    final next = {
      ...profileData(),
      'name': clean,
      'nickname': nick,
      'bio': description,
      'avatar': avatar.clamp(0, 11),
      'avatarColor': (avatarColor ?? _avatarColor).clamp(0, 5)
    };
    await _persist(profileOverride: next);
    _name = clean;
    _nickname = nick;
    _bio = description;
    _avatar = next['avatar'] as int;
    _avatarColor = next['avatarColor'] as int;
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

  Future<void> _persist({Map<String, dynamic>? profileOverride}) {
    final value = jsonEncode({
      'achievements': achievements,
      'activities': activities,
      ...profileOverride ?? profileData(),
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
