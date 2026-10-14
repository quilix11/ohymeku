import '../widgets/ohymeku_design.dart';
import '../widgets/flip_card.dart';
import 'dart:async';
import '../services/progress_service.dart';
import '../services/dictionary_service.dart';
import '../widgets/dictionary_sheet.dart';
import 'package:flutter/material.dart';
import '../services/vocabulary_service.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import 'generation_screen.dart';
import '../models/game_state.dart';

class VocabularyScreen extends StatefulWidget {
  final SettingsService settings;
  final bool active;
  final ProgressService? progress;
  final String? initialDeck;
  final bool reviewAll;
  final int requestNonce;
  const VocabularyScreen(
      {super.key,
      required this.settings,
      this.active = true,
      this.progress,
      this.initialDeck,
      this.reviewAll = false,
      this.requestNonce = 0});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late final _words = widget.settings.vocabulary;
  Map<String, dynamic>? _previousReview;
  bool _answering = false;
  final _tts = TtsService();
  String _deck = 'Усі слова';
  bool _flipped = false, _speaking = false;
  List<WordCard> _queue = [];
  List<WordCard>? _previousQueue;
  String? _previousId;
  bool _previousKnown = false;
  int _voiceRequest = 0;
  String? _loadError;
  List<WordCard> get _deckCards => _words.cards
      .where((c) => _deck == 'Усі слова' || c.deck == _deck)
      .toList();
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant VocabularyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _stop();
    if (widget.requestNonce != oldWidget.requestNonce) {
      _deck = widget.initialDeck ?? 'Усі слова';
      _begin(all: widget.reviewAll);
    } else if (widget.active && !oldWidget.active) {
      _begin();
    }
  }

  Future<void> _load() async {
    try {
      await _words.load();
      if (mounted) {
        _deck = widget.initialDeck ?? 'Усі слова';
        _begin(all: widget.reviewAll);
      }
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Не вдалося відкрити словник.');
    }
  }

  void _begin({bool all = false}) {
    if (_answering) return;
    _stop();
    setState(() {
      _queue = _deckCards.where((c) => all || _words.isDue(c.id)).toList();
      _queue.sort((a, b) {
        final aa = _words.reviews[a.id], bb = _words.reviews[b.id];
        return ((bb?['lapses'] as int?) ?? 0)
            .compareTo((aa?['lapses'] as int?) ?? 0);
      });
      _flipped = false;
      _previousQueue = null;
    });
  }

  void _stop() {
    _voiceRequest++;
    _speaking = false;
    unawaited(_tts.stop());
  }

  Future<void> _speak() async {
    if (_queue.isEmpty) return;
    if (_speaking) {
      _stop();
      setState(() {});
      return;
    }
    final token = ++_voiceRequest;
    setState(() => _speaking = true);
    try {
      await _tts.speak(
          _flipped && _queue.first.example.isNotEmpty
              ? _queue.first.example
              : _queue.first.word,
          speed: widget.settings.ttsSpeed,
          voiceId: widget.settings.voiceFor(GameCharacter.hr),
          character: GameCharacter.hr,
          cloudVoice: widget.settings.cloudVoices
              ? widget.settings.cloudVoiceFor(GameCharacter.hr)
              : null,
          offline: widget.settings.offlineMode,
          style: widget.settings.voiceStyle,
          pitch: widget.settings.voicePitch,
          volume: widget.settings.ttsVolume);
    } catch (_) {
      _notice('Не вдалося відтворити слово. Перевір голос у налаштуваннях.');
    } finally {
      if (mounted && token == _voiceRequest) setState(() => _speaking = false);
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _answer(bool known) async {
    if (_queue.isEmpty || !_flipped || _answering) return;
    _answering = true;
    _stop();
    final card = _queue.first;
    final previousQueue = List<WordCard>.of(_queue);
    _previousQueue = previousQueue;
    _previousId = card.id;
    _previousKnown = _words.known.contains(card.id);
    _previousReview = _words.snapshot(card.id);
    setState(() {
      _queue.removeAt(0);
      if (!known) _queue.add(card);
      _flipped = false;
    });
    try {
      await _words.mark(card.id, known);
      try {
        await widget.progress?.recordActivity('word:${card.id}', known ? 5 : 1);
      } catch (_) {
        _notice('Повторення збережене, але XP поки не збережено.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _queue = previousQueue;
          _previousQueue = null;
          _flipped = true;
        });
      }
      _notice('Прогрес поки не збережено на пристрої.');
    }
    _answering = false;
    if (mounted) setState(() {});
  }

  Future<void> _undo() async {
    if (_previousQueue == null || _previousId == null || _answering) return;
    _answering = true;
    _stop();
    final id = _previousId!, known = _previousKnown;
    final previousQueue = _previousQueue!;
    setState(() {});
    try {
      await _words.restore(id, known, _previousReview);
      if (mounted) {
        setState(() {
          _queue = previousQueue;
          _previousQueue = null;
          _flipped = true;
        });
      }
    } catch (_) {
      _notice('Не вдалося зберегти зміну.');
    }
    _answering = false;
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    _stop();
    final word = TextEditingController(),
        translation = TextEditingController(),
        transcription = TextEditingController(),
        example = TextEditingController();
    final form = GlobalKey<FormState>();
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Нова картка'),
                content: SizedBox(
                    width: 380,
                    child: Form(
                        key: form,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              TextFormField(
                                  controller: word,
                                  maxLength: 80,
                                  decoration: const InputDecoration(
                                      labelText: 'Слово англійською'),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Впиши слово'
                                          : null),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: translation,
                                  maxLength: 120,
                                  decoration: const InputDecoration(
                                      labelText: 'Переклад'),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Додай переклад'
                                          : null),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: transcription,
                                  maxLength: 120,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Транскрипція IPA (необов’язково)')),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: example,
                                  maxLength: 240,
                                  decoration: const InputDecoration(
                                      labelText: 'Приклад (необов’язково)')),
                            ])))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Скасувати')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Додати')),
                ]));
    if (save == true) {
      try {
        await _words.add(word.text, translation.text, example.text,
            transcription: transcription.text);
        if (mounted) {
          _deck = 'Мої слова';
          _begin();
        }
      } catch (_) {
        _notice('Не вдалося зберегти картку.');
      }
    }
    // Dispose after the dialog route has completed its reverse transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    word.dispose();
    translation.dispose();
    example.dispose();
    transcription.dispose();
  }

  Future<void> _generate() async {
    _stop();
    if (widget.settings.offlineMode) {
      _notice(
          'Генерація потребує інтернету. Збережені картки працюють офлайн.');
      return;
    }
    String? savedDeck;
    await Navigator.push(
        context,
        MaterialPageRoute<bool>(
            builder: (_) => GenerationScreen(
                boss: false,
                level: widget.settings.effectiveLevel,
                interests: widget.settings.interests,
                count: widget.settings.cardCount,
                onSave: (result, topic, level, warm) async {
                  final base = '$topic · $level';
                  var name = base, suffix = 2;
                  while (_words.cards.any((c) => c.deck == name)) {
                    name = '$base ($suffix)';
                    suffix++;
                  }
                  await _words.addGenerated(result['cards'], name);
                  savedDeck = name;
                })));
    if (mounted && savedDeck != null) {
      _deck = savedDeck!;
      _begin();
    }
  }

  @override
  void deactivate() {
    _stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _tts.dispose();

    super.dispose();
  }

  Widget _cardFace(bool flipped) {
    final theme = Theme.of(context), c = theme.colorScheme;
    return Padding(
        padding: const EdgeInsets.all(20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: c.secondaryContainer,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(flipped ? 'UA' : 'EN',
                    style: theme.textTheme.labelLarge)),
            const Spacer(),
            IconButton.filledTonal(
                tooltip: 'Послухати вимову',
                onPressed: _speak,
                icon: Icon(
                    _speaking ? Icons.stop_rounded : Icons.volume_up_outlined)),
          ]),
          const SizedBox(height: 28),
          Text(flipped ? _queue.first.translation : _queue.first.word,
              key: ValueKey('${_queue.first.id}_$flipped'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontFamily: 'Lora', fontSize: 32)),
          if (_queue.first.transcription.isNotEmpty ||
              wordIpa.containsKey(_queue.first.word)) ...[
            const SizedBox(height: 12),
            Text(
                _queue.first.transcription.isEmpty
                    ? wordIpa[_queue.first.word]!
                    : _queue.first.transcription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontFamily: 'NotoSans')),
          ],
          if (flipped && _queue.first.example.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_queue.first.example,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: c.onPrimaryContainer))),
          ],
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.flip_rounded, size: 20, color: c.primary),
            const SizedBox(width: 8),
            Flexible(
                child: Text(
                    flipped ? 'Повернути слово' : 'Торкнись — покажу переклад',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center)),
          ]),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    if (_loadError != null) return Center(child: Text(_loadError!));
    if (!_words.ready) return const Center(child: CircularProgressIndicator());
    final learned =
        _deckCards.where((card) => _words.known.contains(card.id)).length;
    final due = _deckCards.where((card) => _words.isDue(card.id)).length;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Словник', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Зберігай. Згадуй. Використовуй.',
                      style: theme.textTheme.bodySmall),
                ])),
            IconButton.filledTonal(
                tooltip: 'Додати свою картку',
                onPressed: _add,
                icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(
              onPressed: () async {
                _stop();
                await showDictionary(context, widget.settings);
                if (mounted) _begin();
              },
              icon: const Icon(Icons.search_rounded),
              label: const Text('Знайти слово або переклад')),
          const SizedBox(height: 12),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final deck in {
                  'Усі слова',
                  'Подорож',
                  'Робота',
                  'Мої слова',
                  ..._words.cards.map((card) => card.deck)
                })
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: Text(deck),
                          selected: _deck == deck,
                          onSelected: (_) {
                            _deck = deck;
                            _begin();
                          })),
              ])),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('$due до повторення',
                      style: theme.textTheme.titleMedium),
                  Text('Знаю $learned із ${_deckCards.length}',
                      style: theme.textTheme.bodySmall),
                ])),
            IconButton(
                tooltip: 'Скасувати останню відповідь',
                onPressed: _previousQueue == null || _answering ? null : _undo,
                icon: const Icon(Icons.undo_rounded)),
            const SizedBox(width: 8),
            IconButton(
                tooltip: 'Перемішати картки',
                onPressed: _queue.length < 2 || _answering
                    ? null
                    : () {
                        _stop();
                        setState(() {
                          _queue.shuffle();
                          _flipped = false;
                          _previousQueue = null;
                        });
                      },
                icon: const Icon(Icons.shuffle_rounded)),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
              value: _deckCards.isEmpty ? 0 : learned / _deckCards.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 20),
          if (_queue.isEmpty)
            SilkPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Icon(Icons.task_alt_rounded, size: 48, color: c.primary),
                  const SizedBox(height: 16),
                  Text(
                      _deckCards.isEmpty
                          ? 'Тут будуть твої слова'
                          : 'На сьогодні все повторено',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                      onPressed:
                          _deckCards.isEmpty ? _add : () => _begin(all: true),
                      icon: Icon(_deckCards.isEmpty
                          ? Icons.add_rounded
                          : Icons.replay_rounded),
                      label: Text(_deckCards.isEmpty
                          ? 'Додати перше слово'
                          : 'Повторити весь набір')),
                ]))
          else ...[
            FlipCard(
                key: ValueKey(_queue.first.id),
                flipped: _flipped,
                animate: widget.settings.animationsEnabled && widget.active,
                onTap: () => setState(() => _flipped = !_flipped),
                front: _cardFace(false),
                back: _cardFace(true)),
            const SizedBox(height: 16),
            AdaptiveActions(children: [
              OutlinedButton.icon(
                  onPressed:
                      _flipped && !_answering ? () => _answer(false) : null,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Ще вчу')),
              FilledButton.icon(
                  onPressed:
                      _flipped && !_answering ? () => _answer(true) : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Знаю')),
            ]),
            const SizedBox(height: 12),
            Text(
                _flipped
                    ? 'Обери, наскільки добре пам’ятаєш слово.'
                    : 'Спочатку згадай значення й відкрий переклад.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          LearningTile(
              title: 'Створити набір',
              subtitle: 'Нові слова на цікаву тобі тему',
              icon: Icons.auto_awesome_outlined,
              onTap: _generate,
              rose: true),
        ]);
  }
}
