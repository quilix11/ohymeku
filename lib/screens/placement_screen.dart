import '../widgets/ohymeku_design.dart';
import 'package:flutter/material.dart';
import '../models/learning_exercise.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/interest_picker.dart';
import '../widgets/meku_avatar.dart';

class PlacementScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final bool retake;
  const PlacementScreen(
      {super.key,
      required this.settings,
      required this.progress,
      this.retake = false});
  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  final _answers = <int>[];
  int? _selected;
  String? _result, _error;
  bool _started = false, _busy = false;
  Future<void> _next() async {
    if (_selected == null || _busy) return;
    _answers.add(_selected!);
    if (_answers.length < placementExercises.length) {
      setState(() => _selected = null);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.settings.learner.savePlacement(_answers);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      _answers.removeLast();
      if (mounted) {
        setState(
            () => _error = 'Не вдалося зберегти результат. Повтори спробу.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await widget.settings.setExtra('learning_level', _result!);
      await widget.settings.setHasTakenPlacement(true);
      if (mounted && widget.retake) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не вдалося зберегти. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Bypass onboarding without inventing a placement score or changing level.
      if (!widget.retake) await widget.settings.setHasTakenPlacement(true);
      if (mounted && widget.retake) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не вдалося зберегти. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final question = placementExercises[
        _answers.length.clamp(0, placementExercises.length - 1)];
    return Scaffold(
        appBar: AppBar(title: const Text('Твій старт'), actions: [
          if (_result == null)
            TextButton(
              onPressed: _busy ? null : _skip,
              child: Text(widget.retake ? 'Закрити' : 'Пропустити'),
            ),
        ]),
        body: SilkBackground(
            child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (!_started) ...[
                              SilkPanel(
                                  rose: true,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const MekuAvatar(size: 96),
                                        const SizedBox(height: 16),
                                        Text('Знайдемо твій рівень',
                                            style:
                                                theme.textTheme.headlineLarge),
                                        const SizedBox(height: 12),
                                        const Text(
                                            '15 коротких питань, близько 5 хвилин. Без таймера та інтернету.'),
                                      ])),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() => _started = true),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Почати тест')),
                              if (!widget.retake) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                    onPressed: _busy ? null : _skip,
                                    child: const Text(
                                        'Пропустити — пройти пізніше')),
                                const Text(
                                    'Тест можна пройти з профілю. Поточний рівень залишиться без змін.'),
                              ],
                              const SectionTitle('Твої інтереси'),
                              SilkPanel(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const Text(
                                        'Обери теми для майбутніх розмов.'),
                                    const SizedBox(height: 12),
                                    InterestPicker(settings: widget.settings),
                                  ])),
                              const SizedBox(height: 20),
                              Text(
                                  'Це приблизний орієнтир для вправ. Тест не оцінює слухання й усне мовлення та не є сертифікацією CEFR.',
                                  style: theme.textTheme.bodySmall),
                            ] else if (_result != null) ...[
                              SilkPanel(
                                  child: Column(children: [
                                Icon(Icons.school_outlined,
                                    size: 48, color: c.primary),
                                const SizedBox(height: 16),
                                Text(_result!,
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                            color: c.primary,
                                            fontWeight: FontWeight.w800)),
                                Text('Твій приблизний рівень',
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                Text(
                                    '${widget.settings.learner.placement?["score"]} із 15 правильних відповідей'),
                              ])),
                              const SizedBox(height: 20),
                              const Text(
                                  'Почнемо з цього рівня. Складність змінюватиметься за результатами практики.'),
                              const SectionTitle('Результати за рівнями'),
                              SilkPanel(
                                  child: Column(
                                      children: List.generate(
                                          5,
                                          (i) => ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: const Icon(
                                                  Icons.checklist_rounded),
                                              title: Text([
                                                'A1',
                                                'A2',
                                                'B1',
                                                'B2',
                                                'C1'
                                              ][i]),
                                              trailing: Text(
                                                  '${widget.settings.learner.placement?["bands"]?[i] ?? 0} / 3'))))),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                  onPressed: _busy ? null : _finish,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Зберегти та продовжити')),
                            ] else ...[
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        'Питання ${_answers.length + 1} із ${placementExercises.length}',
                                        style: theme.textTheme.titleMedium)),
                                const Icon(Icons.quiz_outlined)
                              ]),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                  value: _answers.length /
                                      placementExercises.length,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 24),
                              SilkPanel(
                                  rose: true,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(question.situation),
                                        const SizedBox(height: 16),
                                        Text(question.question,
                                            style:
                                                theme.textTheme.headlineMedium),
                                      ])),
                              const SizedBox(height: 20),
                              for (var i = 0; i < question.options.length; i++)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: AnswerTile(
                                        label: question.options[i],
                                        marker: String.fromCharCode(65 + i),
                                        selected: _selected == i,
                                        onTap: _busy
                                            ? null
                                            : () =>
                                                setState(() => _selected = i))),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                  onPressed:
                                      _busy || _selected == null ? null : _next,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: Text(_busy ? 'Зберігаємо…' : 'Далі')),
                              const SizedBox(height: 10),
                              TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          _selected = -1;
                                          _next();
                                        },
                                  child: const Text('Поки не знаю')),
                            ],
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(_error!,
                                      style: TextStyle(color: c.error))),
                          ])),
                ))));
  }
}
