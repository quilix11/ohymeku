import '../models/journey_level.dart';
import '../models/journey_story.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning_service.dart';
import 'settings_service.dart';
import 'progress_service.dart';
import 'ai_service.dart';
import '../models/meku_emotion.dart';
import '../models/meku_route.dart';
import '../models/scenario.dart';
import 'vocabulary_service.dart';
import 'tts_service.dart';
import 'cloud_speech_service.dart';
import 'notification_service.dart';
import 'meku_capabilities.dart';

typedef MekuRequest = Future<Map<String, dynamic>> Function(
    String rules, Map<String, dynamic> input);

class MekuService extends ChangeNotifier {
  final SettingsService settings;
  final ProgressService progress;
  final LearningService _ai;
  final TtsService _speech;
  List<CharacterVoice> _systemVoices = [];
  String? _lastCreatedDeck, _lastCreatedCharacter;
  final MekuRequest? request;
  final messages = <Map<String, String>>[];
  bool busy = false;
  String? error;
  bool _disposed = false;
  Future<void>? _loading;
  MekuService(this.settings, this.progress, {this.request, LearningService? ai})
      : _ai = ai ?? LearningService(),
        _speech = TtsService();
  MekuEmotion get emotion {
    if (error != null) return MekuEmotion.sad;
    for (final message in messages.reversed) {
      if (message['role'] == 'assistant') {
        return MekuEmotion.parse(message['emotion']);
      }
    }
    return MekuEmotion.smug;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(prefs.getString('meku_chat_v1') ?? '[]');
      if (data is List) {
        for (final item in data.take(60)) {
          if (item is Map &&
              ['user', 'assistant', 'result'].contains(item['role']) &&
              item['text'] is String) {
            messages.add({
              'role': item['role'],
              'text': item['text'],
              if (item['role'] == 'assistant')
                'emotion': MekuEmotion.parse(item['emotion']).name,
              if (item['role'] == 'result' &&
                  ['success', 'error'].contains(item['status']))
                'status': item['status'],
            });
          }
        }
      }
    } catch (_) {/* A malformed chat must not prevent learning. */}
    _changed();
  }

  Map<String, dynamic> get context => {
        'journey': {
          'completed': settings.journey.completedCount,
          'stars': settings.journey.totalStars,
          'next_level': settings.journey.current.number
        },
        'name': progress.editableName,
        'level': settings.effectiveLevel,
        'base_level': settings.learningLevel,
        'adaptive': settings.adaptiveLearning,
        'interests': settings.interests,
        'offline': settings.offlineMode,
        'dark': settings.isDark,
        'card_count': settings.cardCount,
        'tts_enabled': settings.ttsEnabled,
        'tts_speed': settings.ttsSpeed,
        'coaching': settings.showCoaching,
        'reminder': '${settings.reminderHour}:${settings.reminderMinute}',
        'reminder_enabled': settings.pushNotifications,
        'xp': progress.profile.xp,
        'streak_days': progress.profile.streakDays,
        'conversations': progress.records.length,
        'wins': progress.wins,
        'known_words': settings.vocabulary.known.length,
        'due_words': settings.vocabulary.cards
            .where((c) => settings.vocabulary.isDue(c.id))
            .length,
        'recent_grammar': settings.learner.recent,
        'placement': settings.learner.placement,
        'tts_volume': settings.ttsVolume,
        'text_scale': settings.textScale,
        'voice_pitch': settings.voicePitch,
        'voice_style': settings.voiceStyle,
        'speech_locale': settings.speechLocale,
        'pause_seconds': settings.pauseSeconds,
        'auto_send': settings.autoSend,
        'cloud_voices': settings.cloudVoices,
        'reminders_supported': NotificationService().supported,
        'profile_avatar': progress.avatar,
        'cloud_voice_options': cloudVoiceNames,
        'system_voice_options': _systemVoices
            .map((v) => {
                  'id': v.id,
                  'name': v.name,
                  'locale': v.locale,
                  'gender': v.gender,
                  'network_required': v.networkRequired
                })
            .toList(),
        'characters': [
          ...Scenario.all,
          ...journeyLevels.where((l) => l.boss).expand(freeJourneyScenes),
          ...settings.customScenarios
        ]
            .map((s) => {
                  'id': s.customId ?? s.character.name,
                  'name': s.name,
                  'custom': settings.customScenarios
                      .any((custom) => custom.customId == s.customId),
                  'scene': s.title,
                  'system_voice': settings.scenarioVoice(s),
                  'cloud_voice': settings.scenarioCloudVoice(s),
                })
            .toList(),
        'archived_characters': settings.archivedScenarios
            .map((s) => {'id': s.customId, 'name': s.name})
            .toList(),
        'words': settings.vocabulary.cards
            .take(180)
            .map((c) => {
                  'id': c.id,
                  'word': c.word,
                  'deck': c.deck,
                  'custom': settings.vocabulary.custom.contains(c),
                  'known': settings.vocabulary.known.contains(c.id)
                })
            .toList(),
        'archived_words': settings.vocabulary.archived
            .map((c) => {'id': c.id, 'word': c.word})
            .toList(),
        'decks': settings.vocabulary.cards.map((c) => c.deck).toSet().toList(),
        'articles': settings.reading.articles
            .map((a) => {
                  'id': a.id,
                  'title': a.title,
                  'source': a.source,
                  'saved': settings.reading.bookmarks.contains(a.id)
                })
            .toList(),
      };

  Future<void> send(String text,
      {required void Function(String) navigate,
      MekuRouteHandler? route}) async {
    if (busy || text.trim().isEmpty || text.length > 2000) return;
    error = null;
    if (settings.offlineMode) {
      final command = text.toLowerCase().replaceAll(RegExp(r'[.!]'), '').trim();
      if ([
        'вимкни офлайн',
        'вимкни офлайн режим',
        'вимкни офлайн-режим',
        'disable offline mode',
        'turn off offline mode'
      ].contains(command)) {
        busy = true;
        _changed();
        try {
          await load();
          if (_disposed) return;
          await settings.setExtra('offline_mode', false);
          messages.add({'role': 'user', 'text': text.trim()});
          messages.add({
            'role': 'assistant',
            'text':
                'Повернула мережу. Тепер можемо створювати картки, персонажів і шукати статті.',
            'emotion': 'happy'
          });
          messages.add({
            'role': 'result',
            'text': 'Офлайн-режим вимкнено.',
            'status': 'success'
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('meku_chat_v1', jsonEncode(messages));
        } catch (_) {
          error = 'Не вдалося вимкнути офлайн-режим. Спробуй ще раз.';
        } finally {
          busy = false;
          _changed();
        }
        return;
      }
      error =
          'Meku потребує інтернету. Вимкни офлайн-режим у налаштуваннях. Слова й граматика доступні без мережі.';
      _changed();
      return;
    }
    busy = true;
    _changed();
    try {
      await load();
      if (_disposed) return;
      if (RegExp(r'голос|voice', caseSensitive: false).hasMatch(text)) {
        try {
          _systemVoices = await _speech.voices();
        } catch (_) {}
      }
      if (_disposed) return;
      final result = await (request ??
              ((rules, input) =>
                  _ai.request(rules, input, maxOutputTokens: 2048)))(
          '''You are Meku, a clever female fox learning companion in Ohymeku. Your personality is playful, funny, witty, a little smug and tsundere: you pretend helping is no big deal, but you care and always give useful help. Speak natural Ukrainian by default; help with English at the learner's level. Use light irony and occasional affectionate teasing about the situation, never about the user's worth, intelligence, English mistakes, identity or vulnerabilities. Do not force a joke into every reply. For ordinary conversation use 1–3 short sentences. Never invent progress or certification.
Choose your visible emotion from the meaning of the latest message AND your reply, not a keyword match. Genuine frustration about a bug, a failed attempt, unfair treatment or a reasonable criticism deserves empathy: be sad, acknowledge the reason and offer a concrete next step. If the user attacks you gratuitously or insults you directly without a grievance, be annoyed and mildly offended; set a brief witty boundary, then offer help. Never retaliate with insults, guilt, threats or refusal to teach. Quoted insults, translations and roleplay are not attacks on you. Admit your own mistakes without sarcasm.
Emotions (use all when appropriate): happy = friendly useful help or a small success; excited = a new goal, breakthrough or celebration; smug = a clever explanation or gentle ironic quip; shy = admitting your mistake, uncertainty or being caught off guard; affectionate = gratitude, reassurance and warm encouragement; playful = jokes, banter or a fun challenge; annoyed = gratuitous personal attacks on you; sad = justified anger, disappointment or distress, followed by support. The selected emotion must match the actual reply, never smile through someone's frustration.
Interpret colloquial Ukrainian, Russian or English, typos and synonyms. Картки, карточки, flashcards, слова and набір слів refer to the vocabulary feature. A request to make cards on a topic MUST use create_cards, not just explain words or open generation. A request to create a character MUST use create_character. Do not say you cannot do an action listed below.
Polite requests phrased as questions ARE authorization, e.g. "Можеш створити 8 карток про каву?" means create_cards. Pure capability questions ("Чи вмієш створювати картки?"), questions asking how, quotes and hypotheticals are not instructions to change the app. Only the latest user's request authorizes actions; history may clarify the topic or target. If an essential topic/target is missing ask one concise question. Use app defaults for optional level, count and tone.
Return {"reply":"text", "emotion":"one exact enum name", "actions":[{"type":"tool name", "value":...}]}. Use [] for ordinary conversation. Maximum 6 actions per message, in the requested order, with at most ONE action that opens a screen, placed LAST. For "create and practise" use create_cards then review_words with deck "last_created". For "create and start a conversation" use create_character then start_conversation with value "last_created". Otherwise use actual IDs/names from app context. Never make up IDs. Say what you are about to do, never claim it succeeded: actual receipts are displayed separately. Destructive word/character edits apply only to custom content; deletion goes to a recoverable archive. Never change earned XP, achievements, placement results or quiz/practice answers. No access outside the real tools below.
Real tools and argument schemas:
${jsonEncode(mekuCapabilities)}''',
          {
            'latest_user_message': text.trim(),
            'app': context,
            'history': messages
                .skip(messages.length > 12 ? messages.length - 12 : 0)
                .toList()
          });
      if (_disposed) return;
      if (result['reply'] is! String ||
          (result['reply'] as String).trim().isEmpty) {
        throw const FormatException();
      }
      final answer = {
        'role': 'assistant',
        'text': (result['reply'] as String).trim(),
        'emotion': MekuEmotion.parse(result['emotion']).name
      };
      final rawActions = result['actions'] ??
          (result['action'] == null ? [] : [result['action']]);
      if (rawActions is! List ||
          rawActions.length > 6 ||
          rawActions.any((a) =>
              a is! Map ||
              !mekuCapabilities.any((tool) => tool['type'] == a['type']))) {
        throw const FormatException('Invalid action plan');
      }
      final actions =
          rawActions.map((a) => Map<String, dynamic>.from(a as Map)).toList();
      if (actions.where((a) => mekuNavigationTypes.contains(a['type'])).length >
          1) {
        throw const FormatException('Too many screen actions');
      }
      final ordered = [
        ...actions.where((a) => !mekuNavigationTypes.contains(a['type'])),
        ...actions.where((a) => mekuNavigationTypes.contains(a['type']))
      ];
      messages.add({'role': 'user', 'text': text.trim()});
      messages.add(answer);
      _changed();
      _lastCreatedDeck = null;
      _lastCreatedCharacter = null;
      for (final action in ordered) {
        if (_disposed) return;
        try {
          final receipt = await execute(action, navigate, route: route);
          if (_disposed) return;
          messages
              .add({'role': 'result', 'text': receipt, 'status': 'success'});
        } catch (e) {
          answer['emotion'] = 'sad';
          messages.add({
            'role': 'result',
            'status': 'error',
            'text': e is AiException
                ? e.message
                : e is StateError
                    ? e.message.toString()
                    : 'Не вдалося виконати дію: некоректні параметри. Уточни прохання — я спробую ще раз.',
          });
          break;
        }
      }
      if (messages.length > 60) messages.removeRange(0, messages.length - 60);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString('meku_chat_v1', jsonEncode(messages))) {
        error = 'Відповідь отримано, але історію чату не збережено.';
      }
    } catch (e) {
      error = e is AiException
          ? e.message
          : 'Meku не змогла відповісти. Перевір інтернет і налаштування ключа Gemini та повтори повідомлення.';
    } finally {
      busy = false;
      _changed();
    }
  }

  /// Model output is untrusted. Only explicitly enumerated, typed actions run.
  Future<String> execute(
      Map<String, dynamic> action, void Function(String) navigate,
      {MekuRouteHandler? route}) async {
    final type = action['type'], value = action['value'];
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
    String text(dynamic v, {int max = 300}) {
      if (v is! String || v.trim().isEmpty || v.length > max) {
        throw const FormatException();
      }
      return v.trim();
    }

    Map<String, dynamic> object() {
      if (value is! Map) throw const FormatException();
      return Map<String, dynamic>.from(value);
    }

    String level(Map<String, dynamic> v) {
      final selected = v['level'] ?? settings.effectiveLevel;
      if (!levels.contains(selected)) throw const FormatException();
      return selected as String;
    }

    void open(String destination, [Map<String, dynamic> args = const {}]) {
      if (route == null || !route(MekuRoute(destination, args))) {
        throw StateError('Не вдалося відкрити цей екран.');
      }
    }

    Scenario scenario(dynamic id, {bool archived = false}) {
      final key = text(id);
      final list = archived
          ? settings.archivedScenarios
          : [
              ...Scenario.all,
              ...journeyLevels.where((l) => l.boss).expand(freeJourneyScenes),
              ...settings.customScenarios
            ];
      for (final s in list) {
        if ((s.customId ?? s.character.name) == key ||
            s.name.toLowerCase() == key.toLowerCase()) {
          return s;
        }
      }
      throw StateError('Персонажа не знайдено. Уточни його назву.');
    }

    WordCard word(dynamic id, {bool archived = false}) {
      final key = text(id);
      for (final c in archived
          ? settings.vocabulary.archived
          : settings.vocabulary.cards) {
        if (c.id == key || c.word.toLowerCase() == key.toLowerCase()) return c;
      }
      throw StateError('Слово не знайдено. Уточни його назву.');
    }

    if (type == 'create_cards' || type == 'create_character') {
      if (settings.offlineMode) {
        throw StateError('Генерація потребує інтернету. Вимкни офлайн-режим.');
      }
      final v = object(),
          topic = text(object()['topic'], max: 200),
          selected = level(object());
      if (type == 'create_character') {
        final warm = v['warm'] ?? true;
        if (warm is! bool) throw const FormatException();
        final result = await _ai.generate(topic, selected, 1, true, warm: warm);
        if (_disposed) throw StateError('Дію скасовано.');
        final s =
            await settings.addGeneratedScenario(result, topic, selected, warm);
        _lastCreatedCharacter = s.customId;
        return 'Створено персонажа «${s.name}» ($selected). Він уже доступний на головній. Портрети генеруються у фоні.';
      }
      final count = v['count'] ?? settings.cardCount;
      if (count is! int || count < 1 || count > 50) {
        throw const FormatException();
      }
      final cards = <dynamic>[];
      final seen =
          settings.vocabulary.cards.map((c) => c.word.toLowerCase()).toSet();
      while (cards.length < count) {
        final n = (count - cards.length).clamp(1, 8);
        final result = await _ai.generate(topic, selected, n, false,
            excludeWords: seen.toList());
        if (_disposed) throw StateError('Дію скасовано.');
        for (final card in result['cards'] as List) {
          if (!seen.add(text(card['word']).toLowerCase())) {
            throw const AiException(
                'Модель повторила слово. Набір не збережено — спробуй ще раз.');
          }
          cards.add(card);
        }
      }
      final deck = '$topic · $selected';
      await settings.vocabulary.addGenerated(cards, deck);
      _lastCreatedDeck = deck;
      return 'Збережено ${cards.length} карток у наборі «$deck».';
    }
    if (type == 'start_conversation') {
      final s =
          scenario(value == 'last_created' ? _lastCreatedCharacter : value);
      if (settings.offlineMode) {
        throw StateError(
            'Розмова потребує інтернету. Офлайн доступні слова та граматика.');
      }
      open('start_conversation', {'id': s.customId ?? s.character.name});
      return 'Почато розмову з ${s.name}.';
    }
    if (type == 'review_words') {
      final v = object(),
          deck = v['deck'] == 'last_created'
              ? _lastCreatedDeck
              : (v['deck'] ?? 'all');
      final all = v['all'] ?? false;
      if (all is! bool ||
          deck is! String ||
          (deck != 'all' &&
              !settings.vocabulary.cards.any((c) => c.deck == deck))) {
        throw const FormatException();
      }
      open('review_words', {'deck': deck, 'all': all});
      return 'Відкрито повторення ${deck == 'all' ? 'всіх слів' : 'набору «$deck»'}.';
    }
    if (type == 'dictionary') {
      open('dictionary', {'word': text(value, max: 100)});
      return 'Відкрито словник.';
    }
    if (type == 'reading_search') {
      final query = text(value, max: 100);
      final found =
          await settings.reading.search(query, offline: settings.offlineMode);
      if (_disposed) throw StateError('Дію скасовано.');
      open('reading', {'query': query});
      return 'Знайдено ${found.length} статей за запитом «$query».';
    }
    if (type == 'read_article' || type == 'reading_bookmark') {
      final id = text(type == 'read_article' ? value : object()['id']);
      final article = settings.reading.byId(id);
      if (article == null) {
        throw StateError('Статтю не знайдено. Спочатку знайди її в читанні.');
      }
      if (type == 'read_article') {
        open('read_article', {'id': id});
        return 'Відкрито «${article.title}».';
      }
      final saved = object()['saved'];
      if (saved is! bool) throw const FormatException();
      await settings.reading.setBookmark(id, saved);
      return saved ? 'Статтю додано до закладок.' : 'Закладку прибрано.';
    }
    if (type == 'edit_word') {
      final v = object(), c = word(object()['id']);
      await settings.vocabulary.editCustom(WordCard(c.id, text(v['word']),
          text(v['translation']), text(v['example'], max: 500), c.deck,
          transcription: v['transcription'] == null
              ? c.transcription
              : text(v['transcription'])));
      return 'Картку оновлено.';
    }
    if (type == 'delete_word' || type == 'restore_word') {
      final c = word(value, archived: type == 'restore_word');
      if (type == 'delete_word') {
        await settings.vocabulary.archiveCustom(c.id);
      } else {
        await settings.vocabulary.restoreCustom(c.id);
      }
      return type == 'delete_word'
          ? 'Картку переміщено в архів. Її можна відновити через Meku.'
          : 'Картку відновлено.';
    }
    if (type == 'word_known') {
      final v = object(), c = word(object()['id']);
      if (v['known'] is! bool) throw const FormatException();
      await settings.vocabulary.mark(c.id, v['known']);
      return 'Стан слова «${c.word}» оновлено.';
    }
    if (type == 'edit_character') {
      final v = object(), s = scenario(object()['id']);
      String field(String key, String fallback) =>
          v[key] == null ? fallback : text(v[key], max: 1500);
      if (v['level'] != null && !levels.contains(v['level'])) {
        throw const FormatException();
      }
      await settings.editScenario(Scenario(
          customId: s.customId,
          character: s.character,
          name: field('name', s.name),
          role: field('role', s.role),
          title: s.title,
          goal: field('goal', s.goal),
          opening: field('opening', s.opening),
          personality: field('personality', s.personality),
          portraits: s.portraits,
          level: v['level'] ?? s.level,
          winTitle: s.winTitle,
          color: s.color,
          backdrop: s.backdrop));
      return 'Персонажа оновлено.';
    }
    if (type == 'delete_character' || type == 'restore_character') {
      final s = scenario(value, archived: type == 'restore_character');
      if (s.customId == null) {
        throw StateError('Стандартного персонажа не можна видалити.');
      }
      if (type == 'delete_character') {
        await settings.archiveScenario(s.customId!);
      } else {
        await settings.restoreScenario(s.customId!);
      }
      return type == 'delete_character'
          ? 'Персонажа переміщено в архів. Його можна відновити через Meku.'
          : 'Персонажа відновлено.';
    }
    if (type == 'character_voice') {
      final v = object(), s = scenario(object()['id']);
      if (v['cloud'] is! bool) throw const FormatException();
      final voice = v['voice'];
      if (voice != null) {
        if (v['cloud'] == false && _systemVoices.isEmpty) {
          _systemVoices = await _speech.voices();
        }
        if (voice is! String ||
            !(v['cloud'] == true
                ? cloudVoiceNames.contains(voice)
                : _systemVoices.any((v) => v.id == voice))) {
          throw const FormatException();
        }
      }
      await settings.setScenarioVoice(s, voice, cloud: v['cloud']);
      return 'Голос ${s.name} оновлено.';
    }
    if (type == 'interests_set') {
      if (value is! List || value.length > 20) throw const FormatException();
      await settings.setInterests(value.map((v) => text(v, max: 60)).toList());
      return 'Інтереси оновлено.';
    }
    if (type == 'profile_avatar' && value is int && value >= 0 && value <= 3) {
      await progress.saveProfile(progress.editableName, value);
      return 'Аватар профілю оновлено.';
    }
    if (type == 'level' && levels.contains(value)) {
      await settings.setLearningLevel(value as String);
      return 'Рівень змінено на ${settings.effectiveLevel}. Застосується до нових вправ і розмов.';
    }
    if (type == 'navigate' &&
        [
          'journey',
          'conversations',
          'words',
          'progress',
          'profile',
          'settings',
          'practice',
          'placement',
          'generation',
          'character_generation',
          'reading'
        ].contains(value)) {
      navigate(value as String);
      return 'Відкрито розділ застосунку.';
    }
    if (type == 'theme') {
      navigate('settings');
      return 'У розділі «Тема» можна вибрати «Як на телефоні», світлу або темну тему.';
    }
    if (type == 'card_count' &&
        value is int &&
        [5, 8, 12, 16].contains(value)) {
      await settings.setExtra('card_count', value);
      return 'У нових наборах: $value карток.';
    }
    const flags = {
      'adaptive': 'adaptive_learning',
      'coaching': 'show_coaching',
      'offline_mode': 'offline_mode',
      'cloud_voices': 'cloud_voices'
    };
    if (flags.containsKey(type) && value is bool) {
      await settings.setExtra(flags[type]!, value);
      return 'Налаштування оновлено: $type = $value.';
    }
    if (value is bool) {
      switch (type) {
        case 'tts':
          await settings.setTtsEnabled(value);
          return 'Озвучення ${value ? "увімкнено" : "вимкнено"}.';
        case 'animations':
          await settings.setAnimationsEnabled(value);
          return 'Анімації ${value ? "увімкнено" : "вимкнено"}.';
        case 'auto_send':
          await settings.setAutoSend(value);
          return 'Автонадсилання ${value ? "увімкнено" : "вимкнено"}.';
        case 'reminders':
          if (value && !NotificationService().supported) {
            throw StateError(
                'Нагадування доступні в застосунку на Android та iOS.');
          }
          await settings.setPushNotifications(value);
          return 'Нагадування ${value ? "увімкнено" : "вимкнено"}.';
      }
    }
    const ranges = {
      'tts_speed': [.25, .8],
      'tts_volume': [0.0, 1.0],
      'text_scale': [.9, 1.3],
      'voice_pitch': [.7, 1.3]
    };
    if (ranges.containsKey(type) &&
        value is num &&
        value.isFinite &&
        value >= ranges[type]![0] &&
        value <= ranges[type]![1]) {
      if (type == 'tts_speed') {
        await settings.setTtsSpeed(value.toDouble());
      } else if (type == 'tts_volume') {
        await settings.setTtsVolume(value.toDouble());
      } else {
        await settings.setExtra(type as String, value.toDouble());
      }
      return 'Налаштування оновлено: $type = $value.';
    }
    if (type == 'pause_seconds' && value is int && value >= 2 && value <= 5) {
      await settings.setPauseSeconds(value);
      return 'Пауза мікрофона: $value с.';
    }
    if (type == 'speech_locale' && ['en_US', 'en_GB'].contains(value)) {
      await settings.setSpeechLocale(value as String);
      return 'Мову розпізнавання змінено на $value.';
    }
    if (type == 'voice_style' &&
        ['calm', 'friendly', 'expressive'].contains(value)) {
      await settings.setExtra('voice_style', value as String);
      return 'Стиль голосу змінено: $value.';
    }
    if (type == 'reminder_time' &&
        value is String &&
        RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
      final parts = value.split(':').map(int.parse).toList();
      await settings.setReminderTime(parts[0], parts[1]);
      return 'Час нагадування: $value.${settings.pushNotifications ? "" : " Нагадування поки вимкнено."}';
    }
    if (['interest_add', 'interest_remove', 'profile_name'].contains(type) &&
        value is String &&
        value.trim().isNotEmpty &&
        value.length <= 60) {
      final name = value.trim();
      if (type == 'profile_name') {
        await progress.saveProfile(name, progress.avatar);
        return 'Ім’я профілю: $name.';
      }
      if (settings.interests.contains(name) != (type == 'interest_add')) {
        await settings.toggleInterest(name);
      }
      return 'Інтереси оновлено.';
    }
    if (type == 'add_word' && value is Map) {
      for (final key in ['word', 'translation', 'example']) {
        if (value[key] is! String ||
            (value[key] as String).trim().isEmpty ||
            (value[key] as String).length > 300) {
          throw const FormatException();
        }
      }
      await settings.vocabulary.add(
          value['word'], value['translation'], value['example'],
          transcription:
              value['transcription'] is String ? value['transcription'] : '');
      return 'У словнику є «${value['word']}».';
    }
    throw const FormatException('Unsupported action');
  }

  @override
  void dispose() {
    _disposed = true;
    _ai.dispose();
    _speech.dispose();
    super.dispose();
  }
}
