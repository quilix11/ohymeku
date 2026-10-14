import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../models/meku_emotion.dart';
import '../services/settings_service.dart';
import '../widgets/dictionary_sheet.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/ohymeku_design.dart';

class JourneyQuestScreen extends StatefulWidget {
  final JourneyLevel level;
  final SettingsService settings;
  const JourneyQuestScreen(
      {super.key, required this.level, required this.settings});
  @override
  State<JourneyQuestScreen> createState() => _JourneyQuestScreenState();
}

class _JourneyQuestScreenState extends State<JourneyQuestScreen> {
  int _step = 0;
  bool _busy = false;
  bool? _correct;
  String? _error;
  List<String> _options = [];
  List<int> _tokens = [], _chosen = [];
  @override
  void initState() {
    super.initState();
    _resume();
  }

  void _resume() {
    final journey = widget.settings.journey;
    _step = widget.level.challengeIds
        .indexWhere((id) => !journey.challengeDone(widget.level, id));
    if (_step < 0) _step = 3;
    _prepare();
  }

  void _prepare() {
    _correct = null;
    _error = null;
    if (_step < 2) {
      _options = List.of(widget.level.story.questions[_step].options)
        ..shuffle(Random());
    }
    _chosen = [];
    _tokens = List.generate(widget.level.story.tokens.length, (i) => i)
      ..shuffle(Random());
  }

  Future<void> _verify(String answer) async {
    if (_busy || _correct == true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final correct = await widget.settings.journey.verifyChallenge(
          widget.level.id, widget.level.challengeIds[_step], answer);
      if (mounted) setState(() => _correct = correct);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не вдалося зберегти квест. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.level.story,
        theme = Theme.of(context),
        c = theme.colorScheme;
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar: AppBar(title: Text('Квести · ${widget.level.title}')),
            body: SafeArea(
                top: false,
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              SilkPanel(
                                  rose: true,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MekuAvatar(
                                            size: 56,
                                            emotion: _correct == true
                                                ? MekuEmotion.happy
                                                : MekuEmotion.smug),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Text(_step == 3
                                                ? 'Знайшли підказки! Тепер перевіримо, що запам’ятали.'
                                                : _step < 2
                                                    ? 'Прочитай знахідку. Відповідь захована в тексті!'
                                                    : 'Міст зламався! Склади речення з дощечок, щоб ми перейшли далі.'))
                                      ])),
                              const SizedBox(height: 20),
                              if (_busy) const LinearProgressIndicator(),
                              if (_error != null)
                                Text(_error!, style: TextStyle(color: c.error)),
                              if (_step == 3) ...[
                                Icon(Icons.backpack_rounded,
                                    size: 64, color: c.primary),
                                Text('Знахідка: ${story.reward}',
                                    style: theme.textTheme.headlineSmall,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('До перевірки')),
                              ] else ...[
                                Text(
                                    _step < 2
                                        ? 'Знахідка · ${story.title}'
                                        : 'Міст слів',
                                    style: theme.textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text('Квест ${_step + 1} із 3'),
                                const SizedBox(height: 16),
                                if (_step < 2) ...[
                                  SilkPanel(
                                      child: SelectableText(story.text,
                                          style: theme.textTheme.bodyLarge)),
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: TextButton.icon(
                                          onPressed: () => showDictionary(
                                              context, widget.settings),
                                          icon: const Icon(
                                              Icons.menu_book_rounded),
                                          label: const Text(
                                              'Розібрати незнайоме слово'))),
                                  const SizedBox(height: 12),
                                  Text(story.questions[_step].question,
                                      style: theme.textTheme.titleLarge),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < _options.length; i++)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: AnswerTile(
                                            label: _options[i],
                                            marker: String.fromCharCode(65 + i),
                                            onTap: _busy || _correct == true
                                                ? null
                                                : () => _verify(_options[i]),
                                            correct: _correct == true &&
                                                _options[i] ==
                                                    story.questions[_step]
                                                        .options[0])),
                                ] else ...[
                                  Text(
                                      'Збери фразу англійською. Натисни вибране слово, щоб повернути його.',
                                      style: theme.textTheme.bodyLarge),
                                  const SizedBox(height: 16),
                                  SilkPanel(
                                      child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                        if (_chosen.isEmpty)
                                          const Text(
                                              'Твоє речення з’явиться тут…'),
                                        for (final index in _chosen)
                                          InputChip(
                                              label: Text(story.tokens[index]),
                                              onPressed: _busy ||
                                                      _correct == true
                                                  ? null
                                                  : () => setState(() {
                                                        _chosen.remove(index);
                                                        _correct = null;
                                                      })),
                                      ])),
                                  const SizedBox(height: 16),
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    for (final index in _tokens)
                                      if (!_chosen.contains(index))
                                        ActionChip(
                                            label: Text(story.tokens[index]),
                                            onPressed: _busy || _correct == true
                                                ? null
                                                : () => setState(() {
                                                      _chosen.add(index);
                                                      _correct = null;
                                                    })),
                                  ]),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                      onPressed: _busy ||
                                              _correct == true ||
                                              _chosen.length !=
                                                  story.tokens.length
                                          ? null
                                          : () => _verify(_chosen
                                              .map((i) => story.tokens[i])
                                              .join(' ')),
                                      child: const Text('Перевірити міст')),
                                  const SizedBox(height: 12),
                                  TextButton(
                                      onPressed: _busy || _correct == true
                                          ? null
                                          : () => setState(() {
                                                _chosen.clear();
                                                _correct = null;
                                              }),
                                      child:
                                          const Text('Почати речення заново')),
                                ],
                                if (_correct == false)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Text(_step < 2
                                          ? 'Спробуй ще раз: шукай відповідь у тексті.'
                                          : 'Ще не тримається! Пригадай фразу: ${story.sentence}')),
                                if (_correct == true) ...[
                                  const SizedBox(height: 12),
                                  SilkPanel(
                                      child: Text(_step < 2
                                          ? story.questions[_step].explanation
                                          : 'Міст готовий! ${story.sentence}')),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => setState(() {
                                                _step++;
                                                _prepare();
                                              }),
                                      child: Text(_step == 2
                                          ? 'Забрати знахідку'
                                          : 'Наступний квест')),
                                ],
                              ],
                            ]))))));
  }
}
