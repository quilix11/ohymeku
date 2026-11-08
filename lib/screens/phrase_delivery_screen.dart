import 'package:flutter/material.dart';
import '../models/phrase_delivery.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../widgets/exercise_layout.dart';
import '../widgets/ohymeku_design.dart';

class PhraseDeliveryScreen extends StatelessWidget {
  final SettingsService settings;
  const PhraseDeliveryScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Подвійна доставка')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenIntro(
              title: 'Один зміст, два адресати',
              subtitle:
                  'Добери англійські фрази під ситуацію. Потім порівняй, як вони звучать.',
              icon: Icons.forward_to_inbox_rounded,
            ),
            const SizedBox(height: 20),
            for (final drill in phraseDeliveries.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LearningTile(
                  title: drill.title,
                  subtitle: drill.intent,
                  icon: Icons.mail_outline_rounded,
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhraseDeliveryDrillScreen(
                          settings: settings, drill: drill),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class PhraseDeliveryDrillScreen extends StatefulWidget {
  final SettingsService settings;
  final PhraseDelivery drill;
  const PhraseDeliveryDrillScreen(
      {super.key, required this.settings, required this.drill});

  @override
  State<PhraseDeliveryDrillScreen> createState() => _PhraseDeliveryDrillState();
}

class _PhraseDeliveryDrillState extends State<PhraseDeliveryDrillScreen> {
  final _tts = TtsService();
  int _step = 0;
  DeliveryLine? _selected;
  bool _speaking = false, _saving = false;
  late List<DeliveryLine> _options = widget.drill.lines..shuffle();

  void _setStep(int step) => setState(() {
        _step = step;
        _selected = null;
        _options = widget.drill.lines..shuffle();
      });

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _speak(DeliveryLine line, {bool slow = false}) async {
    if (_speaking) return;
    final settings = widget.settings;
    setState(() => _speaking = true);
    try {
      await _tts.speak(line.english,
          speed: slow
              ? (settings.ttsSpeed * .65).clamp(.25, .3)
              : settings.ttsSpeed,
          volume: settings.ttsVolume,
          offline: settings.offlineMode);
    } catch (_) {
      _notice(
          'Не вдалося відтворити фразу. Перевір англійський голос на пристрої.');
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _save(DeliveryLine line) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.settings.vocabulary.add(line.english, line.translation, '');
      _notice('Фразу збережено в «Мої слова».');
    } catch (_) {
      _notice('Не вдалося зберегти фразу. Спробуй ще раз.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Widget _compare(DeliveryLine line) {
    final saved = widget.settings.vocabulary.cards
        .any((card) => card.word.toLowerCase() == line.english.toLowerCase());
    return SilkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.audience, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(line.english, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(line.translation),
          const SizedBox(height: 12),
          Text(line.explanation),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton.icon(
              onPressed: _speaking ? null : () => _speak(line),
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Послухати'),
            ),
            TextButton.icon(
              onPressed: _speaking ? null : () => _speak(line, slow: true),
              icon: const Icon(Icons.slow_motion_video_rounded),
              label: const Text('Повільно'),
            ),
            TextButton.icon(
              onPressed: saved || _saving ? null : () => _save(line),
              icon: Icon(
                  saved ? Icons.bookmark_added : Icons.bookmark_add_outlined),
              label: Text(saved ? 'У словнику' : 'У «Мої слова»'),
            ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.drill.lines;
    final target = _step < lines.length ? lines[_step] : null;
    final correct = target != null && _selected == target;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.drill.title)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ExerciseLayout(
              step: _step,
              action: correct
                  ? FilledButton(
                      onPressed: () => _setStep(_step + 1),
                      child: Text(
                          _step == 0 ? 'Другий адресат' : 'Порівняти фрази'),
                    )
                  : null,
              children: [
                if (target == null) ...[
                  Text('Обидва адресати отримали повідомлення',
                      style: text.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                      'Прослухай обидві фрази й спробуй повторити їх уголос.'),
                  for (final line in lines) ...[
                    const SizedBox(height: 16),
                    _compare(line),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        !_speaking && !_saving ? () => _setStep(0) : null,
                    child: const Text('Повторити доставку'),
                  ),
                ] else ...[
                  Text('Адресат ${_step + 1} із ${lines.length}',
                      style: text.labelLarge),
                  const SizedBox(height: 8),
                  Text(target.audience, style: text.headlineSmall),
                  const SizedBox(height: 8),
                  Text(widget.drill.intent, style: text.bodyLarge),
                  const SizedBox(height: 16),
                  for (final (i, line) in _options.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AnswerTile(
                        label: line.english,
                        marker: i == 0 ? 'A' : 'B',
                        selected: _selected == line,
                        correct: correct && _selected == line,
                        incorrect: !correct && _selected == line,
                        onTap: correct
                            ? null
                            : () => setState(() => _selected = line),
                      ),
                    ),
                  if (_selected case final chosen?)
                    Semantics(
                      liveRegion: true,
                      child: SilkPanel(
                        child: Text(correct
                            ? target.explanation
                            : '${chosen.explanation} Спробуй іншу фразу для цього адресата.'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
