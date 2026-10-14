import '../widgets/ohymeku_design.dart';
import '../theme/app_theme.dart';
import 'dart:async';
import '../widgets/interest_picker.dart';
import '../services/notification_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';
import '../services/cloud_speech_service.dart';
import '../services/ai_service.dart';
import '../services/api_credentials.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;
  const SettingsScreen({super.key, required this.settings});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tts = TtsService();
  final _speech = SpeechService();
  List<CharacterVoice> _voices = [];
  bool _voicesLoading = true;
  Scenario _previewScenario = Scenario.of(GameCharacter.officer);
  bool _notificationBusy = false;
  Future<void> _configureGemini() async {
    final input = TextEditingController();
    final key = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Ключ Gemini'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Введи власний ключ Google AI Studio. Він діє лише в цьому сеансі та не зберігається у профілі.'),
                const SizedBox(height: 12),
                TextField(
                    controller: input,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 512,
                    decoration: const InputDecoration(
                        labelText: 'API-ключ', counterText: ''),
                    onSubmitted: (value) => Navigator.pop(context, value)),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Скасувати')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, input.text),
                    child: const Text('Застосувати')),
              ],
            ));
    // The closing route may still be animating with the controller attached.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (key == null || !mounted) return;
    setState(() => ApiCredentials.setGeminiKey(key));
    widget.settings.resumePortraits();
  }

  String? _notificationError;
  int _previewRequest = 0;
  Future<void> _previewAs(Scenario scenario) async {
    _previewRequest++;
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _previewing = false;
      _previewScenario = scenario;
    });
    await _preview();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadVoices());
  }

  Future<void> _loadVoices() async {
    setState(() => _voicesLoading = true);
    try {
      final voices = await _tts.voices(refresh: true);
      if (mounted) setState(() => _voices = voices);
    } catch (_) {/* The platform voice can still be used. */} finally {
      if (mounted) setState(() => _voicesLoading = false);
    }
  }

  Widget _voicePicker(Scenario scenario) {
    final character = scenario.character;
    final saved = widget.settings.scenarioVoice(scenario);
    final selected = _voices.any((v) => v.id == saved) ? saved! : '';
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.settings.cloudVoices)
            DropdownButtonFormField<String>(
                key: ValueKey(
                    'cloud_${scenario.customId ?? character.name}_${widget.settings.scenarioCloudVoice(scenario)}'),
                initialValue: widget.settings.scenarioCloudVoice(scenario),
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: 'Gemini: ${scenario.name}'),
                items: cloudVoiceNames
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    _previewRequest++;
                    unawaited(_tts.stop());
                    setState(() => _previewing = false);
                    widget.settings.setScenarioVoice(scenario, v, cloud: true);
                  }
                })
          else
            DropdownButtonFormField<String>(
                key: ValueKey(
                    '${scenario.customId ?? character.name}_$selected'),
                initialValue: selected,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: 'Голос: ${scenario.name}'),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('Підібрати автоматично')),
                  ..._voices.map((v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(v.label, overflow: TextOverflow.ellipsis)))
                ],
                onChanged: _voicesLoading
                    ? null
                    : (value) {
                        _previewRequest++;
                        unawaited(_tts.stop());
                        setState(() => _previewing = false);
                        widget.settings.setScenarioVoice(
                            scenario, value == '' ? null : value);
                      }),
          const SizedBox(height: 16),
          TextButton.icon(
              key: ValueKey('preview_${scenario.voiceKey}'),
              onPressed:
                  _listening || _micBusy ? null : () => _previewAs(scenario),
              icon: const Icon(CupertinoIcons.speaker_2),
              label: Text('Послухати ${scenario.name}')),
        ]));
  }

  bool _previewing = false, _listening = false, _micBusy = false;
  String _transcript = '',
      _micStatus = 'Скажи кілька слів англійською, щоб перевірити запис.';
  @override
  void dispose() {
    _tts.dispose();
    _speech.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final request = ++_previewRequest;
    if (_previewing) {
      await _tts.stop();
      if (mounted) setState(() => _previewing = false);
      return;
    }
    setState(() => _previewing = true);
    try {
      await _tts.speak(_previewScenario.opening,
          character: _previewScenario.character,
          voiceId: widget.settings.scenarioVoice(_previewScenario),
          cloudVoice: widget.settings.cloudVoices
              ? widget.settings.scenarioCloudVoice(_previewScenario)
              : null,
          offline: widget.settings.offlineMode,
          style: widget.settings.voiceStyle,
          pitch: widget.settings.voicePitch,
          speed: widget.settings.ttsSpeed,
          volume: widget.settings.ttsVolume);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is AiException
                ? e.message
                : 'Озвучення недоступне на цьому пристрої.')));
      }
    } finally {
      if (mounted && request == _previewRequest) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _testMic() async {
    setState(() => _micBusy = true);
    try {
      if (_listening) {
        await _speech.stopListening();
      } else {
        await _tts.stop();
        if (!mounted) return;
        setState(() {
          _previewing = false;
          _transcript = '';
          _micStatus = 'Очікуємо доступ до мікрофона…';
        });
        await _speech.startListening(
          locale: widget.settings.speechLocale,
          pauseSeconds: widget.settings.pauseSeconds,
          onResult: (text, finalResult) {
            if (mounted) {
              setState(() {
                _transcript = text;
                _micStatus =
                    'Мікрофон працює. Текст не надсилається персонажу.';
              });
            }
          },
          onStatusChange: (value) {
            if (mounted) {
              setState(() {
                _listening = value;
                if (value) _micStatus = 'Слухаю. Говори англійською…';
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _micStatus = error;
                _listening = false;
              });
            }
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _micStatus =
              'Мікрофон недоступний. Перевір дозвіл у налаштуваннях пристрою.';
        });
      }
    } finally {
      if (mounted) setState(() => _micBusy = false);
    }
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() {
      _notificationBusy = true;
      _notificationError = null;
    });
    try {
      await widget.settings.setPushNotifications(value);
    } catch (e) {
      if (mounted) {
        setState(() => _notificationError = e is StateError
            ? e.message.toString()
            : 'Не вдалося налаштувати нагадування. Перевір дозволи телефона.');
      }
    } finally {
      if (mounted) setState(() => _notificationBusy = false);
    }
  }

  Future<void> _chooseReminderTime() async {
    final value = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: widget.settings.reminderHour,
            minute: widget.settings.reminderMinute));
    if (value == null || !mounted) return;
    setState(() => _notificationBusy = true);
    try {
      await widget.settings.setReminderTime(value.hour, value.minute);
    } catch (_) {
      if (mounted) {
        setState(() => _notificationError =
            'Не вдалося змінити час. Попереднє нагадування збережене.');
      }
    } finally {
      if (mounted) setState(() => _notificationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        final settings = widget.settings;
        final theme = Theme.of(context);
        return Scaffold(
            appBar: AppBar(title: const Text('Налаштування')),
            body: SilkBackground(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                            children: [
                              ScreenIntro(
                                  title: 'Зроби зручно',
                                  subtitle:
                                      '${settings.effectiveLevel} · ${settings.isDark ? "Темна тема" : "Світла тема"}',
                                  icon: CupertinoIcons.slider_horizontal_3),
                              const SizedBox(height: 20),
                              _Section(
                                  icon: CupertinoIcons.lock,
                                  title: 'Gemini',
                                  children: [
                                    ListTile(
                                      title:
                                          Text(ApiCredentials.available == false
                                              ? 'Підключити Gemini'
                                              : ApiCredentials.useGateway
                                                  ? 'Спільний Gemini підключено'
                                                  : 'Gemini підключено'),
                                      subtitle: const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                              'Чат, генерація персонажів і 9 портретів із різними емоціями.')),
                                      trailing: const Icon(
                                          CupertinoIcons.chevron_right),
                                      onTap: _configureGemini,
                                    ),
                                    if (ApiCredentials.hasSessionKey)
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 12, 16, 0),
                                          child: TextButton(
                                              onPressed: () => setState(
                                                  ApiCredentials.clear),
                                              child: const Text(
                                                  'Видалити ключ із цього сеансу'))),
                                  ]),
                              const SizedBox(height: 20),
                              _Section(
                                  icon: CupertinoIcons.paintbrush,
                                  title: 'Тема',
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: DropdownButtonFormField<
                                                AppThemeMode>(
                                            key: ValueKey(
                                                'theme_choice_${settings.themeMode.name}'),
                                            initialValue: settings.themeMode,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                                labelText: 'Тема застосунку'),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: AppThemeMode.system,
                                                  child:
                                                      Text('Як на телефоні')),
                                              DropdownMenuItem(
                                                  value: AppThemeMode.light,
                                                  child: Text('Світла')),
                                              DropdownMenuItem(
                                                  value: AppThemeMode.dark,
                                                  child: Text('Темна')),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                settings.setTheme(value);
                                              }
                                            })),
                                  ]),
                              const SizedBox(height: 20),
                              _Section(
                                  icon: CupertinoIcons.book,
                                  title: 'Навчання',
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: DropdownButtonFormField<String>(
                                            initialValue:
                                                settings.learningLevel,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Базовий рівень навчання'),
                                            items: [
                                              'A1',
                                              'A2',
                                              'B1',
                                              'B2',
                                              'C1'
                                            ]
                                                .map((v) => DropdownMenuItem(
                                                    value: v, child: Text(v)))
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                settings.setExtra(
                                                    'learning_level', v);
                                              }
                                            })),
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: DropdownButtonFormField<int>(
                                            initialValue: settings.cardCount,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Карток у новому наборі'),
                                            items: [5, 8, 12, 16]
                                                .map((v) => DropdownMenuItem(
                                                    value: v,
                                                    child: Text('$v карток')))
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                settings.setExtra(
                                                    'card_count', v);
                                              }
                                            })),
                                    SwitchListTile(
                                        title:
                                            const Text('Адаптивна складність'),
                                        subtitle: Text(
                                            'Поточна складність: ${settings.effectiveLevel}. Зміна після щонайменше 8 відповідей у вправах.'),
                                        value: settings.adaptiveLearning,
                                        onChanged: (v) => settings.setExtra(
                                            'adaptive_learning', v)),
                                    SwitchListTile(
                                        title: const Text('Офлайн-режим'),
                                        subtitle: const Text(
                                            'Слова, тест, граматика й історія. Нові розмови та генерація потребують інтернету.'),
                                        value: settings.offlineMode,
                                        onChanged: (v) {
                                          unawaited(_tts.stop());
                                          settings.setExtra('offline_mode', v);
                                        }),
                                    ListTile(
                                        title: const Text('Завантажені голоси'),
                                        subtitle: const Text(
                                            'Озвучення автоматично кешуються до 20 МБ на телефоні.'),
                                        trailing: IconButton(
                                            tooltip:
                                                'Очистити завантажені озвучення',
                                            icon: const Icon(
                                                CupertinoIcons.trash),
                                            onPressed: () async {
                                              await _tts.stop();
                                              await _tts.clearCache();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Завантажені озвучення очищено.')));
                                              }
                                            })),
                                    SwitchListTile(
                                        title: const Text(
                                            'Показувати поради після відповіді'),
                                        value: settings.showCoaching,
                                        onChanged: (v) => settings.setExtra(
                                            'show_coaching', v)),
                                    _SettingSlider(
                                        title: 'Розмір тексту',
                                        display:
                                            '${(settings.textScale * 100).round()}%',
                                        start: 'Менший',
                                        end: 'Більший',
                                        value: settings.textScale,
                                        min: .9,
                                        max: 1.3,
                                        divisions: 4,
                                        onChanged: (v) =>
                                            settings.setExtra('text_scale', v)),
                                  ]),
                              const SizedBox(height: 28),
                              _Section(
                                  icon: CupertinoIcons.person,
                                  title: 'Твої інтереси й нагадування',
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child:
                                            InterestPicker(settings: settings)),
                                    SwitchListTile(
                                        title:
                                            const Text('Щоденне нагадування'),
                                        subtitle: Text(NotificationService()
                                                .supported
                                            ? 'Працює без інтернету на телефоні'
                                            : 'Доступно в Android та iPhone застосунку'),
                                        value: settings.pushNotifications,
                                        onChanged: _notificationBusy ||
                                                !NotificationService().supported
                                            ? null
                                            : _toggleReminder),
                                    ListTile(
                                        title: const Text('Час нагадування'),
                                        subtitle: const Text(
                                            'Місцевий час телефона. Android може трохи відкласти доставку.'),
                                        trailing: Text(
                                            '${settings.reminderHour.toString().padLeft(2, "0")}:${settings.reminderMinute.toString().padLeft(2, "0")}'),
                                        onTap: _notificationBusy
                                            ? null
                                            : _chooseReminderTime),
                                    if (_notificationError != null ||
                                        settings.notificationError != null)
                                      Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                              _notificationError ??
                                                  settings.notificationError!,
                                              style: TextStyle(
                                                  color: theme
                                                      .colorScheme.error))),
                                  ]),
                              const SizedBox(height: 28),
                              _Section(
                                  icon: CupertinoIcons.waveform,
                                  title: 'Голос і звук',
                                  children: [
                                    SwitchListTile(
                                        title: const Text('Голоси Gemini'),
                                        subtitle: const Text(
                                            '8 голосів через інтернет. Текст надсилається Gemini; діють квоти й тариф твого API. Вимкнено — системні голоси.'),
                                        value: settings.cloudVoices,
                                        onChanged: (v) {
                                          _previewRequest++;
                                          unawaited(_tts.stop());
                                          setState(() => _previewing = false);
                                          settings.setExtra('cloud_voices', v);
                                        }),
                                    if (settings.cloudVoices)
                                      Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: DropdownButtonFormField<
                                                  String>(
                                              initialValue: settings.voiceStyle,
                                              decoration: const InputDecoration(
                                                  labelText: 'Манера мовлення'),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'calm',
                                                    child: Text('Спокійна')),
                                                DropdownMenuItem(
                                                    value: 'friendly',
                                                    child: Text('Дружня')),
                                                DropdownMenuItem(
                                                    value: 'expressive',
                                                    child: Text('Виразна'))
                                              ],
                                              onChanged: (v) {
                                                if (v != null) {
                                                  settings.setExtra(
                                                      'voice_style', v);
                                                }
                                              })),
                                    if (!settings.cloudVoices)
                                      _SettingSlider(
                                          title: 'Висота системного голосу',
                                          display: settings.voicePitch
                                              .toStringAsFixed(1),
                                          start: 'Нижче',
                                          end: 'Вище',
                                          value: settings.voicePitch,
                                          min: .7,
                                          max: 1.3,
                                          divisions: 6,
                                          onChanged: (v) => settings.setExtra(
                                              'voice_pitch', v)),
                                    ...Scenario.all.map(_voicePicker),
                                    ...settings.customScenarios
                                        .map(_voicePicker),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(settings.cloudVoices
                                            ? 'Обери голос і натисни «Послухати». Перше озвучення може потребувати кількох секунд.'
                                            : _voicesLoading
                                                ? 'Завантаження голосів…'
                                                : _voices.length < 2
                                                    ? 'На телефоні менше двох англійських голосів: персонажі можуть звучати однаково. Встанови додаткові системні голоси або ввімкни хмарні.'
                                                    : 'Список залежить від пристрою. Вибрані голоси зберігаються окремо для кожного персонажа.')),
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 16, 16, 16),
                                        child: TextButton(
                                            onPressed: _voicesLoading
                                                ? null
                                                : _loadVoices,
                                            child: const Text(
                                                'Оновити список голосів'))),
                                    SwitchListTile(
                                        title:
                                            const Text('Озвучувати персонажа'),
                                        value: settings.ttsEnabled,
                                        onChanged: (value) {
                                          settings.setTtsEnabled(value);
                                          if (!value) unawaited(_tts.stop());
                                        }),
                                    _SettingSlider(
                                        key: const Key('volume_setting'),
                                        title: 'Гучність голосу',
                                        value: settings.ttsVolume,
                                        min: 0,
                                        max: 1,
                                        divisions: 10,
                                        display:
                                            '${(settings.ttsVolume * 100).round()}%',
                                        onChanged: settings.setTtsVolume,
                                        start: 'Тихо',
                                        end: 'Гучно'),
                                    _SettingSlider(
                                        key: const Key('speed_setting'),
                                        title: 'Темп мовлення',
                                        value: settings.ttsSpeed,
                                        min: 0.25,
                                        max: 0.8,
                                        divisions: 11,
                                        display:
                                            '${(settings.ttsSpeed / 0.5).toStringAsFixed(1)}×',
                                        onChanged: settings.setTtsSpeed,
                                        start: 'Повільно',
                                        end: 'Швидко'),
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 16),
                                        child: SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                                onPressed:
                                                    _listening || _micBusy
                                                        ? null
                                                        : _preview,
                                                icon: Icon(_previewing
                                                    ? CupertinoIcons.stop
                                                    : CupertinoIcons.play),
                                                label: Text(_previewing
                                                    ? 'Зупинити приклад'
                                                    : 'Перевірити звучання')))),
                                  ]),
                              const SizedBox(height: 20),
                              _Section(
                                  icon: CupertinoIcons.mic,
                                  title: 'Мікрофон',
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: DropdownButtonFormField<String>(
                                            initialValue: settings.speechLocale,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Англійська для розпізнавання'),
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'en_US',
                                                  child: Text(
                                                      'Американська · US')),
                                              DropdownMenuItem(
                                                  value: 'en_GB',
                                                  child:
                                                      Text('Британська · UK')),
                                            ],
                                            onChanged: _listening
                                                ? null
                                                : (value) {
                                                    if (value != null) {
                                                      settings.setSpeechLocale(
                                                          value);
                                                    }
                                                  })),
                                    _SettingSlider(
                                        title: 'Пауза перед завершенням',
                                        value: settings.pauseSeconds.toDouble(),
                                        min: 2,
                                        max: 5,
                                        divisions: 3,
                                        display: '${settings.pauseSeconds} с',
                                        onChanged: (v) =>
                                            settings.setPauseSeconds(v.round()),
                                        start: 'Коротка',
                                        end: 'Довга'),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                            'Фактична пауза залежить від служби розпізнавання на пристрої.',
                                            style: theme.textTheme.bodySmall)),
                                    SwitchListTile(
                                        title: const Text(
                                            'Надсилати голос автоматично'),
                                        subtitle: const Text(
                                            'Вимкни, щоб спочатку переглянути й відредагувати текст.'),
                                        value: settings.autoSend,
                                        onChanged: settings.setAutoSend),
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration:
                                                AppVisuals.panelDecoration(
                                                    context,
                                                    radius: AppVisuals
                                                        .radiusControl),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(_micStatus,
                                                      style: theme.textTheme
                                                          .bodyMedium),
                                                  if (_transcript
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 10),
                                                    Text(_transcript,
                                                        style: theme.textTheme
                                                            .bodyLarge)
                                                  ],
                                                  const SizedBox(height: 14),
                                                  FilledButton.tonalIcon(
                                                      onPressed: _micBusy
                                                          ? null
                                                          : _testMic,
                                                      icon: Icon(_listening
                                                          ? CupertinoIcons.stop
                                                          : CupertinoIcons.mic),
                                                      label: Text(_micBusy
                                                          ? 'Підключення…'
                                                          : _listening
                                                              ? 'Зупинити запис'
                                                              : 'Перевірити мікрофон')),
                                                ]))),
                                  ]),
                              const SizedBox(height: 20),
                              Text(
                                  'Налаштування зберігаються автоматично на цьому пристрої.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall),
                            ])))));
      });
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section(
      {required this.icon, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Material(
        color: AppVisuals.panelColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppVisuals.radiusCard),
            side: BorderSide(color: AppVisuals.panelBorder(context), width: 1)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey(title),
          initiallyExpanded: title == 'Gemini',
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppVisuals.panelDecoration(context,
                  radius: AppVisuals.radiusControl),
              child: Icon(icon,
                  size: 22, color: Theme.of(context).colorScheme.primary)),
          title: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.only(top: 8, bottom: 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          expandedAlignment: Alignment.centerLeft,
          children: children,
        ),
      );
}

class _SettingSlider extends StatelessWidget {
  final String title, display, start, end;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const _SettingSlider(
      {super.key,
      required this.title,
      required this.display,
      required this.start,
      required this.end,
      required this.value,
      required this.min,
      required this.max,
      required this.divisions,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(children: [
        Row(children: [
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(width: 8),
          Text(display,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600))
        ]),
        Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: display,
            onChanged: onChanged),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(start, style: Theme.of(context).textTheme.labelSmall),
          Text(end, style: Theme.of(context).textTheme.labelSmall)
        ]),
      ]));
}
