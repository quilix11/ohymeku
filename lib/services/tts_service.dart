import 'dart:async';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/game_state.dart';
import 'cloud_speech_service.dart';
import 'ai_service.dart';

class CharacterVoice {
  final String name, locale, gender;
  final bool networkRequired;
  const CharacterVoice(this.name, this.locale, this.gender,
      {this.networkRequired = false});
  String get id => jsonEncode({'name': name, 'locale': locale});
  String get label => '$name · $locale';
}

class TtsService {
  final FlutterTts _tts = FlutterTts();
  Future<void>? _initializing;
  static List<CharacterVoice>? _cachedVoices;
  bool _disposed = false;
  int _request = 0;
  final _cloud = CloudSpeechService();
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<List<CharacterVoice>> voices({bool refresh = false}) async {
    if (!refresh && _cachedVoices != null) return _cachedVoices!;
    await initialize().timeout(const Duration(seconds: 5));
    final raw = await _tts.getVoices.timeout(const Duration(seconds: 5));
    final result = <CharacterVoice>[];
    for (final entry in raw is List ? raw : []) {
      if (entry is! Map) continue;
      final name = entry['name'], locale = entry['locale'];
      if (name is! String ||
          locale is! String ||
          !locale.toLowerCase().startsWith('en')) {
        continue;
      }
      final voice = CharacterVoice(
          name, locale, entry['gender']?.toString().toLowerCase() ?? '',
          networkRequired: entry['network_required'] == true ||
              entry['network_required'] == 'true');
      if (!result.any((v) => v.id == voice.id)) result.add(voice);
    }
    if (result.isNotEmpty) _cachedVoices = List.unmodifiable(result);
    return result;
  }

  Future<void> speak(String text,
      {bool enabled = true,
      double speed = .5,
      double volume = .8,
      GameCharacter character = GameCharacter.officer,
      String? voiceId,
      String? cloudVoice,
      String style = 'calm',
      double pitch = 1,
      bool offline = false}) async {
    if (!enabled || _disposed) return;
    final request = ++_request;
    if (cloudVoice != null) {
      if (_initializing != null) {
        try {
          await _tts.stop();
        } catch (_) {}
      }
      if (_disposed || request != _request) return;
      await _cloud.speak(text, cloudVoice, style, speed, volume,
          offline: offline);
      return;
    }
    await _cloud.stop();
    await initialize().timeout(const Duration(seconds: 5));
    if (_disposed || request != _request) return;
    await _tts.stop().timeout(const Duration(seconds: 2));
    try {
      final available = (await voices())
          .where((v) => !offline || !v.networkRequired)
          .toList();
      if (offline && available.isEmpty) {
        throw const AiException(
            'Встанови англійський голос на телефоні для офлайн-вимови.');
      }
      CharacterVoice? voice;
      if (voiceId != null) {
        for (final candidate in available) {
          if (candidate.id == voiceId) voice = candidate;
        }
      }
      if (voice == null && available.isNotEmpty) {
        final males = available.where((v) =>
            v.gender == 'male' ||
            RegExp(r'david|guy|daniel|mark|george|james', caseSensitive: false)
                .hasMatch(v.name));
        final officer = males.isNotEmpty ? males.first : available.first;
        final alternatives =
            available.where((v) => v.id != officer.id).toList();
        final females = alternatives.where((v) =>
            v.gender == 'female' ||
            RegExp(r'jenny|samantha|zira|susan|aria|hazel',
                    caseSensitive: false)
                .hasMatch(v.name));
        voice = character == GameCharacter.officer
            ? officer
            : females.isNotEmpty
                ? females.first
                : alternatives.isNotEmpty
                    ? alternatives.first
                    : officer;
      }
      if (_disposed || request != _request) return;
      if (voice != null) {
        await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      }
    } on AiException {
      rethrow;
    } catch (_) {
      if (offline) {
        throw const AiException(
            'Не вдалося знайти офлайн-голос. Перевір встановлені голоси телефона.');
      }
      /* Platform default remains usable if voice discovery fails. */
    }
    if (_disposed || request != _request) return;
    await _tts.setPitch(
        ((character == GameCharacter.officer ? .88 : 1.08) * pitch)
            .clamp(.5, 2));
    await _tts.setSpeechRate(
        (speed * (character == GameCharacter.officer ? .94 : 1.04))
            .clamp(.25, .8));
    await _tts.setVolume(volume.clamp(0, 1));
    if (_disposed || request != _request) return;
    await _tts.speak(text).timeout(const Duration(seconds: 60));
  }

  Future<void> stop() async {
    _request++;
    await _cloud.stop();
    if (_initializing == null) return;
    try {
      await _tts.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> clearCache() async {
    await stop();
    await _cloud.clearCache();
  }

  void dispose() {
    _disposed = true;
    _cloud.dispose();
    unawaited(stop());
  }
}
