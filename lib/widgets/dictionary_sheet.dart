import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../services/vocabulary_service.dart';
import '../services/ai_service.dart';
import '../models/game_state.dart';

Future<void> showDictionary(BuildContext context, SettingsService settings,
        {String word = ''}) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => DictionarySheet(settings: settings, word: word));

class DictionarySheet extends StatefulWidget {
  final SettingsService settings;
  final String word;
  const DictionarySheet({super.key, required this.settings, this.word = ''});
  @override
  State<DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<DictionarySheet> {
  late final _input = TextEditingController(text: widget.word);
  late final _dictionary = DictionaryService(widget.settings.vocabulary);
  final _tts = TtsService();
  WordCard? _card;
  String? _error;
  String _source = '';
  bool _busy = false, _saving = false, _speaking = false;
  @override
  void initState() {
    super.initState();
    if (widget.word.isNotEmpty) _search();
  }

  Future<void> _search() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _card = null;
    });
    await _tts.stop();
    try {
      final result = await _dictionary.lookup(_input.text,
          offline: widget.settings.offlineMode);
      if (mounted) {
        setState(() {
          _card = result.card;
          _source = result.source;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is AiException
            ? e.message
            : 'Пошук недоступний. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final c = _card;
    if (c == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.settings.vocabulary.add(c.word, c.translation, c.example,
          transcription: c.transcription);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не вдалося додати картку. Повтори спробу.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _speak() async {
    if (_card == null) return;
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await _tts.speak(_card!.word,
          character: GameCharacter.hr,
          speed: widget.settings.ttsSpeed,
          volume: widget.settings.ttsVolume,
          voiceId: widget.settings.voiceFor(GameCharacter.hr),
          cloudVoice: widget.settings.cloudVoices
              ? widget.settings.cloudVoiceFor(GameCharacter.hr)
              : null,
          offline: widget.settings.offlineMode);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Голос недоступний. Для офлайн-вимови встанови англійський голос на телефоні.');
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _dictionary.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = _card != null &&
        widget.settings.vocabulary.cards
            .any((c) => c.word.toLowerCase() == _card!.word.toLowerCase());
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .65,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Слово під рукою', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                  controller: _input,
                  maxLength: 80,
                  enabled: !_busy,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                      labelText: 'Англійське слово або фраза',
                      suffixIcon: IconButton(
                          tooltip: 'Знайти',
                          onPressed: _busy ? null : _search,
                          icon: const Icon(Icons.search)))),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error))),
              if (_card != null) ...[
                Text(_card!.word, style: theme.textTheme.headlineLarge),
                Text(_card!.transcription,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontFamily: 'NotoSans')),
                const SizedBox(height: 16),
                Text(_card!.translation, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText(_card!.example),
                const SizedBox(height: 16),
                Text(_source, style: theme.textTheme.bodySmall),
                TextButton.icon(
                    onPressed: _speak,
                    icon:
                        Icon(_speaking ? Icons.stop : Icons.volume_up_outlined),
                    label: Text(_speaking ? 'Зупинити' : 'Вимова')),
                FilledButton.icon(
                    onPressed: saved || _saving ? null : _save,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(saved
                        ? 'У твоїх картках'
                        : _saving
                            ? 'Зберігаємо…'
                            : 'Додати до карток')),
              ] else if (!_busy) ...[
                const SizedBox(height: 16),
                const Text(
                    'Без інтернету: базові слова, твої картки та останні 200 знайдених слів.'),
                Wrap(
                    spacing: 8,
                    children: ['coffee', 'passport', 'experience']
                        .map((w) => ActionChip(
                            label: Text(w),
                            onPressed: () {
                              _input.text = w;
                              _search();
                            }))
                        .toList()),
              ],
            ])));
  }
}
