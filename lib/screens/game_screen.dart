import '../widgets/ohymeku_design.dart';
import 'dart:async';
import '../widgets/dictionary_sheet.dart';
import 'practice_screen.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';
import '../services/ai_service.dart';
import '../services/game_session.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/coaching_box.dart';
import '../widgets/npc_avatar.dart';
import '../widgets/conversation_meters.dart';
import '../services/learning_service.dart';

class GameScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final GameCharacter character;
  final AiService? ai;
  final LearningService? tutor;
  final Scenario? scenario;
  const GameScreen(
      {super.key,
      required this.settings,
      required this.progress,
      this.character = GameCharacter.officer,
      this.ai,
      this.tutor,
      this.scenario});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameSession _session;
  late int _previousWins;
  final _tts = TtsService();
  late final _tutor = widget.tutor ?? LearningService();
  bool _routing = false;
  final _speech = SpeechService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _listening = false,
      _speaking = false,
      _micBusy = false,
      _leaving = false;
  int _capture = 0, _voiceRequest = 0, _messageCount = 0;
  String? _audioError;
  Scenario get _scenario {
    final original = widget.scenario ?? Scenario.of(widget.character);
    return widget.settings.customScenarios.firstWhere(
        (s) => s.customId == original.customId,
        orElse: () => original);
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _previousWins = widget.progress
        .winsFor(widget.character, scenarioId: _scenario.customId);
    _session = GameSession(
        character: widget.character,
        progress: widget.progress,
        ai: widget.ai,
        scenario: _scenario,
        interests: widget.settings.interests,
        learner: widget.settings.learner,
        learningLevel: widget.settings.effectiveLevel);
    _messageCount = _session.state.messages.length;
    _session.addListener(_changed);
    widget.settings.addListener(_settingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_speak(_session.state.messages.first.text));
    });
  }

  void _changed() {
    if (!mounted) return;
    final messages = _session.state.messages;
    if (messages.length > _messageCount && !messages.last.isPlayer) {
      unawaited(_speak(messages.last.text));
    }
    _messageCount = messages.length;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _speak(String text, {bool manual = false}) async {
    if (!mounted || _listening || (!widget.settings.ttsEnabled && !manual)) {
      return;
    }
    final token = ++_voiceRequest;
    setState(() {
      _speaking = true;
      _audioError = null;
    });
    try {
      await _tts.speak(text,
          speed: widget.settings.ttsSpeed,
          volume: widget.settings.ttsVolume,
          voiceId: widget.settings.scenarioVoice(_scenario),
          cloudVoice: widget.settings.cloudVoices
              ? widget.settings.scenarioCloudVoice(_scenario)
              : null,
          offline: widget.settings.offlineMode,
          style: widget.settings.voiceStyle,
          pitch: widget.settings.voicePitch,
          character: widget.character);
    } catch (_) {
      if (mounted && token == _voiceRequest) {
        setState(
            () => _audioError = 'Голос недоступний. Можна продовжити текстом.');
      }
    } finally {
      if (mounted && token == _voiceRequest) setState(() => _speaking = false);
    }
  }

  Future<void> _stopVoice() async {
    _voiceRequest++;
    if (mounted) setState(() => _speaking = false);
    await _tts.stop();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty ||
        _session.state.isLoading ||
        _session.finished ||
        _micBusy ||
        _routing) {
      return;
    }
    if (!await _prepareInput(text)) return;
    if (!mounted) return;
    _capture++;
    setState(() {
      _listening = false;
      _audioError = null;
    });
    _input.clear();
    // Lock the turn synchronously before awaiting platform audio operations.
    final send = _session.send(text);
    unawaited(_stopVoice());
    try {
      await _speech.cancel();
    } catch (_) {}
    await send;
    await _presentSessionTutor(text);
  }

  Future<void> _presentSessionTutor(String original) async {
    final help = _session.tutorHelp;
    if (!mounted || help == null) return;
    _input.text = original;
    await _showTutor(help);
  }

  Future<void> _retryTurn() async {
    final original = _session.state.messages.last.text;
    if (!await _prepareInput(original) || !mounted) return;
    await _session.retry();
    await _presentSessionTutor(original);
  }

  Future<bool> _prepareInput(String text, {bool help = false}) async {
    if (widget.settings.offlineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Для живої розмови потрібен інтернет. Офлайн доступні слова та граматичні вправи.')));
      return false;
    }
    help = help ||
        RegExp(r'[\u0400-\u052f\u0370-\u03ff\u0590-\u08ff\u0900-\u0fff\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]')
            .hasMatch(text);
    if (_routing || _session.state.isLoading || _session.finished) return false;
    // Latin-script drafts are classified in the same request as the NPC reply.
    if (!help) return true;
    setState(() => _routing = true);
    _capture++;
    unawaited(_stopVoice());
    try {
      await _speech.cancel();
      if (!mounted) return false;
      setState(() => _listening = false);
      final contextText =
          _session.state.messages.where((m) => !m.isPlayer).last.text;
      final result = await _tutor.prepare(text, contextText,
          help: help, level: widget.settings.effectiveLevel);
      if (!mounted) return false;
      if (result.isEnglish && !help) return true;
      setState(() => _routing = false);
      await _showTutor(result);
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is AiException
                ? e.message
                : 'Помічник недоступний. Текст залишився у полі.')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Future<void> _showTutor(LanguageHelp result) async {
    final phrase = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .72,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      Text('Як сказати англійською',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      const Text(
                          'Це запит до помічника. Персонаж його не отримав, шкали не змінилися.'),
                      if (result.explanation.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(result.explanation)),
                      ...result.suggestions.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SelectableText(s.english,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        Text(s.translation),
                                        const SizedBox(height: 8),
                                        TextButton(
                                            onPressed: () => Navigator.pop(
                                                context, s.english),
                                            child: const Text(
                                                'Вставити у відповідь')),
                                      ])))))
                    ]))));
    if (mounted && phrase != null) {
      _input.value = TextEditingValue(
          text: phrase,
          selection: TextSelection.collapsed(offset: phrase.length));
    }
  }

  void _showDictionaryModal(String word) async {
    await _stopVoice();
    if (mounted) await showDictionary(context, widget.settings, word: word);
  }

  Future<void> _toggleMic() async {
    if (_micBusy || _session.state.isLoading || _session.finished) return;
    setState(() {
      _micBusy = true;
      _audioError = null;
    });
    if (_listening) {
      try {
        await _speech.stopListening();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _micBusy = false;
        _listening = false;
      });
      if (widget.settings.autoSend) await _send();
      return;
    }
    await _stopVoice();
    if (!mounted) return;
    final capture = ++_capture;
    await _speech.startListening(
      locale: widget.settings.speechLocale,
      pauseSeconds: widget.settings.pauseSeconds,
      onResult: (text, finalResult) {
        if (!mounted || capture != _capture || _session.state.isLoading) return;
        _input.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length));
        if (finalResult) {
          setState(() {
            _listening = false;
            _micBusy = false;
          });
          if (widget.settings.autoSend) unawaited(_send());
        }
      },
      onStatusChange: (listening) {
        if (mounted && capture == _capture) {
          setState(() => _listening = listening);
        }
      },
      onError: (error) {
        if (mounted && capture == _capture) {
          setState(() {
            _audioError = error;
            _listening = false;
          });
        }
      },
    );
    if (mounted) setState(() => _micBusy = false);
  }

  Future<void> _leave() async {
    if (_leaving) return;
    if (_session.saving) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Зберігаємо результат…')));
      return;
    }
    if (!_session.finished &&
        (_session.turnCount > 0 || _session.state.isLoading)) {
      final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Завершити практику?'),
                content: const Text(
                    'Завершені ходи та поради залишаться в історії. Поточний AI-запит буде скасовано.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Продовжити')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Завершити')),
                ],
              ));
      if (leave != true || !mounted) return;
    }
    setState(() => _leaving = true);
    await _session.save();
    if (!mounted) return;
    if (_session.saveError != null) {
      setState(() => _leaving = false);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _restart() async {
    await _stopVoice();
    await _session.restart();
    if (mounted && !_session.finished) {
      _previousWins = widget.progress
          .winsFor(widget.character, scenarioId: _scenario.customId);
      _input.clear();
      _messageCount = _session.state.messages.length;
      unawaited(_speak(_session.state.messages.first.text));
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_settingsChanged);
    _tutor.dispose();
    _capture++;
    _voiceRequest++;
    _session.removeListener(_changed);
    _session.dispose();
    _tts.dispose();
    _speech.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _session.state;
    final theme = Theme.of(context);
    final busy = state.isLoading || _leaving || _routing;
    final compact = MediaQuery.viewInsetsOf(context).bottom > 0 ||
        MediaQuery.sizeOf(context).height < 780;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 21;
    final scrollingStage = largeText || MediaQuery.sizeOf(context).height < 600;
    final activity = _routing
        ? 'Перевіряю мову й готую підказку…'
        : state.isLoading
            ? 'Обмірковує відповідь…'
            : _listening
                ? 'Слухає тебе…'
                : _speaking
                    ? 'Говорить…'
                    : _session.finished
                        ? 'Розмову завершено'
                        : 'Твоя черга';
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
                tooltip: 'До персонажів',
                onPressed: _leave,
                icon: const Icon(Icons.arrow_back_rounded)),
            title: Text(_scenario.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                  tooltip: _speaking
                      ? 'Зупинити озвучення'
                      : 'Прослухати останню репліку',
                  onPressed: _speaking
                      ? _stopVoice
                      : () {
                          final message =
                              state.messages.lastWhere((m) => !m.isPlayer);
                          _speak(message.text, manual: true);
                        },
                  icon: Icon(_speaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_outlined))
            ]),
        body: SilkBackground(
            child: SafeArea(
                top: false,
                child: Center(
                    child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(children: [
                    if (_routing) const LinearProgressIndicator(minHeight: 2),
                    if (!scrollingStage)
                      CharacterStage(
                          scenario: _scenario,
                          emotion: state.npcEmotion,
                          activity: activity,
                          compact: compact),
                    Expanded(
                        child: ListView(
                      key: const Key('conversation'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      children: [
                        if (scrollingStage)
                          CharacterStage(
                              scenario: _scenario,
                              emotion: state.npcEmotion,
                              activity: activity,
                              compact: true),
                        ConversationMeters(
                            trust: state.trust,
                            patience: state.patience,
                            turns: _session.turnCount,
                            words: _session.uniqueWords,
                            previousWins: _previousWins,
                            compact: compact),
                        ...state.messages.asMap().entries.map((entry) {
                          final message = entry.value;
                          final feedbackIndex = (entry.key - 2) ~/ 2;
                          return Column(
                              key: ValueKey(
                                  '${message.timestamp.microsecondsSinceEpoch}_${entry.key}'),
                              children: [
                                ChatBubble(
                                    message: message,
                                    onWordTap: _showDictionaryModal,
                                    onSpeak: message.isPlayer || _listening
                                        ? null
                                        : () =>
                                            _speak(message.text, manual: true)),
                                if (widget.settings.showCoaching &&
                                    !message.isPlayer &&
                                    entry.key >= 2 &&
                                    feedbackIndex < _session.feedback.length)
                                  CoachingBox(
                                      feedback:
                                          _session.feedback[feedbackIndex],
                                      onPractice: () async {
                                        await _stopVoice();
                                        if (context.mounted) {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                  builder: (_) => PracticeScreen(
                                                      settings: widget.settings,
                                                      progress: widget.progress,
                                                      focusQuestion: _session
                                                          .feedback[
                                                              feedbackIndex]
                                                          .exercise
                                                          ?.question)));
                                        }
                                      }),
                              ]);
                        }),
                        if (state.isLoading)
                          const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(children: [
                                SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                SizedBox(width: 12),
                                Expanded(
                                    child:
                                        Text('Співрозмовник готує відповідь…')),
                              ])),
                        if (_session.error != null)
                          _Notice(
                              text: _session.error!,
                              action: 'Повторити',
                              onAction: _session.canRetry ? _retryTurn : null),
                        if (_audioError != null)
                          _Notice(
                              text: _audioError!,
                              action: 'Зрозуміло',
                              onAction: () =>
                                  setState(() => _audioError = null)),
                        if (_session.saveError != null)
                          _Notice(
                              text: _session.saveError!,
                              action: 'Зберегти',
                              onAction: _session.save),
                        if (_session.finished)
                          Card(
                              color: theme.colorScheme.primaryContainer,
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(children: [
                                    Icon(
                                        state.status == GameStatus.win
                                            ? Icons.emoji_events_rounded
                                            : Icons.school_outlined,
                                        size: 36),
                                    const SizedBox(height: 10),
                                    Text(
                                        state.status == GameStatus.win
                                            ? _scenario.winTitle
                                            : 'Це теж досвід.',
                                        style: theme.textTheme.titleLarge,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 8),
                                    Text(state.status == GameStatus.win
                                        ? '+${_session.earnedXp} XP'
                                        : 'Переглянь поради й спробуй новий підхід.'),
                                    if (_session.saving)
                                      const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text('Зберігаємо…')),
                                  ]))),
                      ],
                    )),
                    if (_session.finished)
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: _session.saving ? null : _leave,
                                    child: const Text('До персонажів'))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: FilledButton(
                                    onPressed:
                                        _session.saving ? null : _restart,
                                    child: const Text('Ще раз'))),
                          ]))
                    else
                      Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          color: theme.colorScheme.surface,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                    key: const Key('message_input'),
                                    controller: _input,
                                    minLines: 1,
                                    maxLines: largeText ? 1 : 3,
                                    maxLength: 2000,
                                    enabled: !busy,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                        hintText: _listening
                                            ? 'Слухаю…'
                                            : 'Напиши англійською…',
                                        hintMaxLines: 1,
                                        counterText: '',
                                        contentPadding:
                                            const EdgeInsets.all(14)),
                                    onSubmitted: (_) => _send()),
                                const SizedBox(height: 10),
                                Row(children: [
                                  if (largeText)
                                    IconButton.filledTonal(
                                        tooltip: _listening
                                            ? 'Завершити запис'
                                            : 'Говорити англійською',
                                        onPressed: busy || _micBusy
                                            ? null
                                            : _toggleMic,
                                        icon: Icon(_listening
                                            ? Icons.stop_rounded
                                            : Icons.mic_none_rounded))
                                  else
                                    OutlinedButton.icon(
                                        onPressed: busy || _micBusy
                                            ? null
                                            : _toggleMic,
                                        icon: Icon(_listening
                                            ? Icons.stop_rounded
                                            : Icons.mic_none_rounded),
                                        label: Text(_listening
                                            ? 'Зупинити'
                                            : 'Говорити')),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                      tooltip: 'Допоможи сказати англійською',
                                      onPressed: busy || _session.finished
                                          ? null
                                          : () => _prepareInput(
                                              _input.text.trim(),
                                              help: true),
                                      icon: const Icon(
                                          Icons.lightbulb_outline_rounded)),
                                  const Spacer(),
                                  ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _input,
                                      builder: (context, input, _) =>
                                          IconButton.filled(
                                              key: const Key('send_message'),
                                              tooltip: 'Надіслати відповідь',
                                              onPressed: busy ||
                                                      _micBusy ||
                                                      input.text.trim().isEmpty
                                                  ? null
                                                  : _send,
                                              icon: const Icon(
                                                  Icons.send_rounded))),
                                ]),
                              ])),
                  ]),
                )))),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text, action;
  final VoidCallback? onAction;
  const _Notice({required this.text, required this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
            if (onAction != null)
              TextButton(onPressed: onAction, child: Text(action)),
          ])));
}
