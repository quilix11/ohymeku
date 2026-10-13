import '../widgets/ohymeku_design.dart';
import 'package:flutter/material.dart';
import '../models/learning_exercise.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';

class PracticeScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final String? focusQuestion;
  const PracticeScreen(
      {super.key,
      required this.settings,
      required this.progress,
      this.focusQuestion});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final List<LearningExercise> _queue = _initialQueue();
  List<LearningExercise> _initialQueue() {
    final due = widget.settings.learner
        .due(widget.settings.effectiveLevel, widget.settings.interests);
    final focus = widget.settings.learner.personal
        .where((e) => e.question == widget.focusQuestion);
    if (focus.isNotEmpty) {
      due.removeWhere((e) => e.id == focus.first.id);
      due.insert(0, focus.first);
    }
    return due;
  }

  int _index = 0, _correct = 0;
  int? _answer;
  bool _saving = false;
  String? _error;
  Future<void> _choose(int value) async {
    if (_saving || _answer != null) return;
    final exercise = _queue[_index];
    final correct = value == exercise.answer;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.settings.learner.answer(exercise, correct);
      try {
        await widget.progress
            .recordActivity('grammar:${exercise.id}', correct ? 10 : 2);
      } catch (_) {
        if (mounted) {
          setState(
              () => _error = 'Відповідь збережена, але XP поки не збережено.');
        }
      }
      if (mounted) {
        setState(() {
          _answer = value;
          if (correct) _correct++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не вдалося зберегти відповідь. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final finished = _index >= _queue.length;
    final e = finished ? null : _queue[_index];
    return Scaffold(
        appBar: AppBar(title: const Text('Граматика')),
        body: SilkBackground(
            child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            ScreenIntro(
                                title: 'Коротка практика',
                                subtitle:
                                    '${widget.settings.effectiveLevel} · працює без інтернету',
                                icon: Icons.edit_note_rounded),
                            const SizedBox(height: 24),
                            if (finished)
                              SilkPanel(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                    Icon(Icons.task_alt_rounded,
                                        size: 56, color: c.primary),
                                    const SizedBox(height: 16),
                                    Text(
                                        _queue.isEmpty
                                            ? 'На сьогодні все повторено'
                                            : '$_correct із ${_queue.length} правильно',
                                        style: theme.textTheme.headlineMedium,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    const Text(
                                        'Складні завдання повернуться через 10 хвилин. Правильні — через 1, 3 або більше днів.'),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text('Готово')),
                                  ]))
                            else ...[
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        'Завдання ${_index + 1} із ${_queue.length}',
                                        style: theme.textTheme.titleSmall)),
                                Text(e!.topic,
                                    style: theme.textTheme.labelMedium),
                              ]),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                  value: _index / _queue.length,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 20),
                              SilkPanel(
                                  rose: true,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.situation,
                                            style: theme.textTheme.bodyMedium),
                                        const SizedBox(height: 16),
                                        Text(e.question,
                                            style:
                                                theme.textTheme.headlineMedium),
                                      ])),
                              const SizedBox(height: 20),
                              for (var i = 0; i < e.options.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AnswerTile(
                                      label: e.options[i],
                                      marker: String.fromCharCode(65 + i),
                                      selected: _answer == i,
                                      correct: _answer != null && i == e.answer,
                                      incorrect: _answer == i && i != e.answer,
                                      onTap: _saving || _answer != null
                                          ? null
                                          : () => _choose(i)),
                                ),
                              if (_answer != null) ...[
                                const SizedBox(height: 8),
                                SilkPanel(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Row(children: [
                                        Icon(
                                            _answer == e.answer
                                                ? Icons
                                                    .check_circle_outline_rounded
                                                : Icons.info_outline_rounded,
                                            color: c.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                _answer == e.answer
                                                    ? 'Так, правильно!'
                                                    : 'Правильно: ${e.options[e.answer]}',
                                                style: theme
                                                    .textTheme.titleMedium)),
                                      ]),
                                      const SizedBox(height: 12),
                                      Text(e.explanation),
                                    ])),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                    onPressed: () => setState(() {
                                          _index++;
                                          _answer = null;
                                        }),
                                    icon:
                                        const Icon(Icons.arrow_forward_rounded),
                                    label: const Text('Далі')),
                              ],
                              if (_saving) const LinearProgressIndicator(),
                              if (_error != null)
                                Text(_error!, style: TextStyle(color: c.error)),
                            ],
                          ])),
                ))));
  }
}
