import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';
import 'dart:convert';
import 'learner_service.dart';
import 'vocabulary_service.dart';
import 'notification_service.dart';
import 'cloud_speech_service.dart';
import 'reading_service.dart';

enum AppThemeMode { light, dark }

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;
  final learner = LearnerService();
  final vocabulary = VocabularyService();
  final reading = ReadingService();
  bool adaptiveLearning = true, offlineMode = false;
  int reminderHour = 19, reminderMinute = 0;
  String? notificationError;
  final Map<String, String> _scenarioVoices = {}, _scenarioCloudVoices = {};
  String get effectiveLevel =>
      learner.effectiveLevel(learningLevel, adaptiveLearning);
  String? scenarioVoice(Scenario s) =>
      _scenarioVoices[s.customId ?? s.character.name] ?? voiceFor(s.character);
  String scenarioCloudVoice(Scenario s) {
    final id = s.customId ?? s.character.name;
    if (_scenarioCloudVoices.containsKey(id)) return _scenarioCloudVoices[id]!;
    if (s.customId == null) return cloudVoiceFor(s.character);
    final index = customScenarios.indexWhere((v) => v.customId == s.customId);
    return cloudVoiceNames[
        (index + 2).clamp(0, 100000) % cloudVoiceNames.length];
  }

  Future<void> setScenarioVoice(Scenario s, String? voice,
      {bool cloud = false}) async {
    final values = cloud ? _scenarioCloudVoices : _scenarioVoices;
    final id = s.customId ?? s.character.name;
    if (voice == null) {
      values.remove(id);
    } else {
      values[id] = voice;
    }
    await _prefs.setString(cloud ? 'scenario_cloud_voices' : 'scenario_voices',
        jsonEncode(values));
    notifyListeners();
  }

  final List<Scenario> customScenarios = [];
  final List<Scenario> archivedScenarios = [];
  String learningLevel = 'A2', voiceStyle = 'calm';
  int cardCount = 8;
  double textScale = 1, voicePitch = 1;
  bool cloudVoices = false, showCoaching = true;
  String officerCloudVoice = 'Charon', hrCloudVoice = 'Kore';
  String cloudVoiceFor(GameCharacter c) =>
      _scenarioCloudVoices[c.name] ??
      (c == GameCharacter.officer ? officerCloudVoice : hrCloudVoice);
  Future<void> setExtra(String key, Object value) async {
    if (key == 'learning_level') {
      await setLearningLevel(value as String);
      return;
    }
    switch (key) {
      case 'adaptive_learning':
        adaptiveLearning = value as bool;
        break;
      case 'offline_mode':
        offlineMode = value as bool;
        break;
      case 'learning_level':
        learningLevel = value as String;
        break;
      case 'voice_style':
        voiceStyle = value as String;
        break;
      case 'card_count':
        cardCount = value as int;
        break;
      case 'text_scale':
        textScale = value as double;
        break;
      case 'voice_pitch':
        voicePitch = value as double;
        break;
      case 'cloud_voices':
        cloudVoices = value as bool;
        break;
      case 'show_coaching':
        showCoaching = value as bool;
        break;
      case 'officer_cloud_voice':
        officerCloudVoice = value as String;
        break;
      case 'hr_cloud_voice':
        hrCloudVoice = value as String;
        break;
    }
    notifyListeners();
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
  }

  Future<void> setLearningLevel(String level) async {
    if (!['A1', 'A2', 'B1', 'B2', 'C1'].contains(level)) {
      throw ArgumentError.value(level, 'level');
    }
    final old = learningLevel;
    if (!await _prefs.setString('learning_level', level)) {
      throw StateError('Не вдалося зберегти рівень.');
    }
    try {
      await learner.resetAdaptation();
    } catch (_) {
      await _prefs.setString('learning_level', old);
      rethrow;
    }
    learningLevel = level;
    notifyListeners();
  }

  Future<void> addScenario(Scenario scenario) async {
    final next = [...customScenarios, scenario];
    if (!await _prefs.setString(
        'custom_scenarios_v1', _scenarioJson(next, archivedScenarios))) {
      throw StateError('Не вдалося зберегти персонажа.');
    }
    customScenarios.add(scenario);
    notifyListeners();
  }

  String _scenarioJson(List<Scenario> active, List<Scenario> archive) =>
      jsonEncode([
        ...active.map((s) => s.toJson()),
        ...archive.map((s) => {...s.toJson(), 'deleted': true})
      ]);
  Future<void> editScenario(Scenario replacement) async {
    final index =
        customScenarios.indexWhere((s) => s.customId == replacement.customId);
    if (index < 0) {
      throw StateError('Редагувати можна лише власних персонажів.');
    }
    final next = List<Scenario>.of(customScenarios);
    next[index] = replacement;
    if (!await _prefs.setString(
        'custom_scenarios_v1', _scenarioJson(next, archivedScenarios))) {
      throw StateError('Не вдалося зберегти персонажа.');
    }
    customScenarios[index] = replacement;
    notifyListeners();
  }

  Future<void> archiveScenario(String id) async {
    final matches = customScenarios.where((s) => s.customId == id).toList();
    if (matches.isEmpty) {
      throw StateError('Видаляти можна лише власних персонажів.');
    }
    if (archivedScenarios.length >= 30) {
      throw StateError(
          'Архів персонажів заповнений. Спочатку віднови потрібного.');
    }
    final next = customScenarios.where((s) => s.customId != id).toList(),
        archive = [...archivedScenarios, matches.single];
    if (!await _prefs.setString(
        'custom_scenarios_v1', _scenarioJson(next, archive))) {
      throw StateError('Не вдалося прибрати персонажа.');
    }
    customScenarios
      ..clear()
      ..addAll(next);
    archivedScenarios
      ..clear()
      ..addAll(archive);
    notifyListeners();
  }

  Future<void> restoreScenario(String id) async {
    final matches = archivedScenarios.where((s) => s.customId == id).toList();
    if (matches.isEmpty) throw StateError('Персонажа немає в архіві.');
    final next = [...customScenarios, matches.single],
        archive = archivedScenarios.where((s) => s.customId != id).toList();
    if (!await _prefs.setString(
        'custom_scenarios_v1', _scenarioJson(next, archive))) {
      throw StateError('Не вдалося відновити персонажа.');
    }
    customScenarios
      ..clear()
      ..addAll(next);
    archivedScenarios
      ..clear()
      ..addAll(archive);
    notifyListeners();
  }

  Future<Scenario> addGeneratedScenario(Map<String, dynamic> result,
      String topic, String level, bool warm) async {
    final scenario = Scenario(
        customId: DateTime.now().microsecondsSinceEpoch.toString(),
        character: warm ? GameCharacter.hr : GameCharacter.officer,
        name: result['name'],
        role: result['role'],
        title: topic,
        goal: result['goal'],
        opening: result['opening'],
        personality: result['description'],
        portraits: Scenario.parsePortraits(result['portraits']),
        level: level,
        winTitle: 'Вдало поговорили!',
        color: const Color(0xFF8F4856),
        backdrop: const Color(0xFFECD6D9));
    await addScenario(scenario);
    return scenario;
  }

  AppThemeMode _themeMode = AppThemeMode.light;
  final Map<GameCharacter, String> _voices = {};
  String? voiceFor(GameCharacter character) =>
      _scenarioVoices[character.name] ?? _voices[character];
  Future<void> setVoice(GameCharacter character, String? value) async {
    if (value == null) {
      _voices.remove(character);
    } else {
      _voices[character] = value;
    }
    notifyListeners();
    if (value == null) {
      await _prefs.remove('voice_${character.name}');
    } else {
      await _prefs.setString('voice_${character.name}', value);
    }
  }

  double _ttsSpeed = 0.5, _ttsVolume = 0.8;
  bool _ttsEnabled = true, _autoSend = false, _animationsEnabled = true;
  int _lastCharacter = 0, _pauseSeconds = 3;
  String _speechLocale = 'en_US';

  AppThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == AppThemeMode.dark;
  double get ttsSpeed => _ttsSpeed;
  double get ttsVolume => _ttsVolume;
  bool get ttsEnabled => _ttsEnabled;
  bool get autoSend => _autoSend;
  bool get animationsEnabled => _animationsEnabled;
  int get lastCharacter => _lastCharacter;
  int get pauseSeconds => _pauseSeconds;
  String get speechLocale => _speechLocale;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    await learner.load();
    await vocabulary.load();
    await reading.load();
    adaptiveLearning = _prefs.getBool('adaptive_learning') ?? true;
    offlineMode = _prefs.getBool('offline_mode') ?? false;
    reminderHour = (_prefs.getInt('reminder_hour') ?? 19).clamp(0, 23);
    reminderMinute = (_prefs.getInt('reminder_minute') ?? 0).clamp(0, 59);
    for (final entry in {
      'scenario_voices': _scenarioVoices,
      'scenario_cloud_voices': _scenarioCloudVoices
    }.entries) {
      try {
        final data = jsonDecode(_prefs.getString(entry.key) ?? '{}') as Map;
        for (final e in data.entries) {
          if (e.value is String &&
              (entry.key != 'scenario_cloud_voices' ||
                  cloudVoiceNames.contains(e.value))) {
            entry.value[e.key.toString()] = e.value;
          }
        }
      } catch (_) {}
    }

    learningLevel = _prefs.getString('learning_level') ?? 'A2';
    if (!['A1', 'A2', 'B1', 'B2', 'C1'].contains(learningLevel)) {
      learningLevel = 'A2';
    }
    cardCount = _prefs.getInt('card_count') ?? 8;
    if (![5, 8, 12, 16].contains(cardCount)) cardCount = 8;
    voiceStyle = _prefs.getString('voice_style') ?? 'calm';
    if (!['calm', 'friendly', 'expressive'].contains(voiceStyle)) {
      voiceStyle = 'calm';
    }
    textScale = (_prefs.getDouble('text_scale') ?? 1).clamp(.9, 1.3);
    voicePitch = (_prefs.getDouble('voice_pitch') ?? 1).clamp(.7, 1.3);
    cloudVoices = _prefs.getBool('cloud_voices') ?? false;
    showCoaching = _prefs.getBool('show_coaching') ?? true;
    const voiceNames = [
      'Charon',
      'Kore',
      'Puck',
      'Aoede',
      'Fenrir',
      'Leda',
      'Orus',
      'Zephyr'
    ];
    officerCloudVoice = _prefs.getString('officer_cloud_voice') ?? 'Charon';
    hrCloudVoice = _prefs.getString('hr_cloud_voice') ?? 'Kore';
    if (!voiceNames.contains(officerCloudVoice)) officerCloudVoice = 'Charon';
    if (!voiceNames.contains(hrCloudVoice)) hrCloudVoice = 'Kore';
    try {
      customScenarios.clear();
      archivedScenarios.clear();
      for (final item
          in jsonDecode(_prefs.getString('custom_scenarios_v1') ?? '[]')
              as List) {
        try {
          (item['deleted'] == true ? archivedScenarios : customScenarios)
              .add(Scenario.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    } catch (_) {}
    _themeMode =
        AppThemeMode.values[(_prefs.getInt('theme_mode') ?? 0).clamp(0, 1)];
    for (final character in GameCharacter.values) {
      final voice = _prefs.getString('voice_${character.name}');
      if (voice != null) _voices[character] = voice;
    }
    _ttsSpeed = (_prefs.getDouble('tts_speed') ?? 0.5).clamp(0.25, 0.8);
    _ttsVolume = (_prefs.getDouble('tts_volume') ?? 0.8).clamp(0.0, 1.0);
    _ttsEnabled = _prefs.getBool('tts_enabled') ?? true;
    _autoSend = _prefs.getBool('auto_send') ?? false;
    _animationsEnabled = _prefs.getBool('animations_enabled') ?? true;
    _lastCharacter = (_prefs.getInt('last_character') ?? 0)
        .clamp(0, 1 + customScenarios.length);
    _pauseSeconds = (_prefs.getInt('speech_pause') ?? 3).clamp(2, 5);
    final locale = _prefs.getString('speech_locale') ?? 'en_US';
    _speechLocale = ['en_US', 'en_GB'].contains(locale) ? locale : 'en_US';
    interests = _prefs.getStringList('interests') ?? [];
    pushNotifications = _prefs.getBool('push_notifications') ?? false;
    hasTakenPlacement = _prefs.getBool('has_taken_placement') ?? false;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    await _prefs.setInt('theme_mode', value.index);
  }

  Future<void> setTtsSpeed(double value) async {
    _ttsSpeed = value.clamp(0.25, 0.8);
    notifyListeners();
    await _prefs.setDouble('tts_speed', _ttsSpeed);
  }

  Future<void> setTtsVolume(double value) async {
    _ttsVolume = value.clamp(0.0, 1.0);
    notifyListeners();
    await _prefs.setDouble('tts_volume', _ttsVolume);
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    notifyListeners();
    await _prefs.setBool('tts_enabled', value);
  }

  Future<void> setAutoSend(bool value) async {
    _autoSend = value;
    notifyListeners();
    await _prefs.setBool('auto_send', value);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    notifyListeners();
    await _prefs.setBool('animations_enabled', value);
  }

  Future<void> setLastCharacter(int value) async {
    _lastCharacter = value.clamp(0, 1 + customScenarios.length);
    await _prefs.setInt('last_character', _lastCharacter);
  }

  Future<void> setSpeechLocale(String value) async {
    if (!['en_US', 'en_GB'].contains(value)) return;
    _speechLocale = value;
    notifyListeners();
    await _prefs.setString('speech_locale', value);
  }

  Future<void> setPauseSeconds(int value) async {
    _pauseSeconds = value.clamp(2, 5);
    notifyListeners();
    await _prefs.setInt('speech_pause', _pauseSeconds);
  }

  List<String> interests = [];
  bool pushNotifications = false;
  bool hasTakenPlacement = false;

  Future<void> toggleInterest(String interest) async {
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    notifyListeners();
    await _prefs.setStringList('interests', interests);
  }

  Future<void> setInterests(List<String> values) async {
    final next =
        values.map((v) => v.trim()).where((v) => v.isNotEmpty).toSet().toList();
    if (!await _prefs.setStringList('interests', next)) {
      throw StateError('Не вдалося зберегти інтереси.');
    }
    interests = next;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    if (value) {
      if (!await NotificationService().requestPermissions()) {
        throw StateError(
            'Дозволь сповіщення в системних налаштуваннях телефону.');
      }
      await NotificationService()
          .scheduleDailyReminder(reminderHour, reminderMinute);
    } else {
      await NotificationService().cancelAll();
    }
    await _prefs.setBool('push_notifications', value);
    pushNotifications = value;
    notificationError = null;
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    if (pushNotifications) {
      await NotificationService().scheduleDailyReminder(hour, minute);
    }
    await _prefs.setInt('reminder_hour', hour);
    await _prefs.setInt('reminder_minute', minute);
    reminderHour = hour;
    reminderMinute = minute;
    notifyListeners();
  }

  Future<void> restoreReminder() async {
    if (!pushNotifications) return;
    try {
      await NotificationService()
          .scheduleDailyReminder(reminderHour, reminderMinute);
      notificationError = null;
    } catch (_) {
      notificationError =
          'Не вдалося відновити нагадування. Перевір дозволи у налаштуваннях.';
    }
    notifyListeners();
  }

  Future<void> setHasTakenPlacement(bool value) async {
    hasTakenPlacement = value;
    notifyListeners();
    await _prefs.setBool('has_taken_placement', value);
  }
}
