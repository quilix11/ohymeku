import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../models/meku_emotion.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/ohymeku_design.dart';

enum _Phase { words, recall, test, result }

class JourneyLevelScreen extends StatefulWidget {
  final JourneyLevel level;
  final SettingsService settings;
  final ProgressService progress;
  const JourneyLevelScreen(
      {super.key,
      required this.level,
      required this.settings,
      required this.progress});
  @override
  State<JourneyLevelScreen> createState() => _JourneyLevelScreenState();
}

class _JourneyLevelScreenState extends State<JourneyLevelScreen> {
  _Phase _phase = _Phase.words;
  int _word = 0, _question = 0, _score = 0;
  bool _busy = false;
  String? _error;
  int? _answer;
  bool? _wordCorrect;
  List<String> _wordOptions = [];
  List<JourneyQuestion> _questions = [];
  final List<int> _answers = [];
  bool get _animate =>
      widget.settings.animationsEnabled &&
      !MediaQuery.disableAnimationsOf(context);
  void _recall() => setState(() {
        _wordOptions = widget.level.choices(widget.level.words[_word])
          ..shuffle(Random());
        _wordCorrect = null;
        _phase = _Phase.recall;
        _error = null;
      });
  Future<void> _verify(String translation) async {
    if (_busy || _wordCorrect == true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final word = widget.level.words[_word];
      final alreadyLearned =
          widget.settings.journey.wordLearned(widget.level, word.id);
      final correct = await widget.settings.journey
          .verifyWord(widget.level.id, word.id, translation);
      if (correct && !alreadyLearned) {
        try {
          await widget.settings.vocabulary.mark(word.id, true);
        } catch (_) {
          if (mounted) {
            setState(() => _error =
                'Слово перевірено, але словник не збережено. Звільни місце у сховищі.');
          }
        }
      }
      if (mounted) setState(() => _wordCorrect = correct);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startTest() {
    if (!widget.settings.journey.readyForTest(widget.level)) return;
    setState(() {
      _questions = widget.level.questions();
      _answers.clear();
      _question = 0;
      _answer = null;
      _error = null;
      _phase = _Phase.test;
    });
  }

  Future<void> _choose(int answer) async {
    if (_busy || _answer != null) return;
    final q = _questions[_question];
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (q.grammar != null) {
        await widget.settings.learner.answer(q.grammar!, answer == q.answer);
      }
      if (mounted) {
        setState(() {
          _answer = answer;
          _answers.add(answer);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не вдалося зберегти відповідь. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    if (_busy || _answer == null) return;
    if (_question < _questions.length - 1) {
      setState(() {
        _question++;
        _answer = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final score = await widget.settings.journey
          .finishTest(widget.level.id, _questions, _answers);
      if (mounted) {
        setState(() {
          _score = score;
          _phase = _Phase.result;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level,
        theme = Theme.of(context),
        c = theme.colorScheme;
    final journey = widget.settings.journey;
    final passed = _score >= 4;
    final emotion = _phase == _Phase.result
        ? passed
            ? MekuEmotion.excited
            : MekuEmotion.affectionate
        : _phase == _Phase.test && _answer != null
            ? _answer == _questions[_question].answer
                ? MekuEmotion.happy
                : MekuEmotion.affectionate
            : _wordCorrect == false
                ? MekuEmotion.shy
                : _wordCorrect == true
                    ? MekuEmotion.happy
                    : MekuEmotion.playful;
    String guidance() {
      if (_phase == _Phase.result) {
        return passed
            ? 'Острів відкрито! Ти впорався — ходімо далі!'
            : 'Ми знайшли, що повторити. Спробуй ще раз — я поруч.';
      }
      if (_phase == _Phase.test) {
        return _answer == null
            ? 'Тепер маленька перевірка. Чотири правильні відповіді з п’яти відкриють наступний острів.'
            : _answer == _questions[_question].answer
                ? 'Точно! Запам’ятай пояснення — і рушай далі.'
                : 'Зверни увагу на пояснення нижче. Помилка показує, що потренувати.';
      }
      if (_phase == _Phase.recall && _wordCorrect == true) {
        return 'Є! Слово перевірено. Наступний крок уже поруч.';
      }
      if (_phase == _Phase.recall && _wordCorrect == false) {
        return 'Ще спроба! Можеш повернутися до картки й пригадати переклад.';
      }
      return level.guide;
    }

    final word = level.words[_word];
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar:
                AppBar(title: Text('Рівень ${level.number} · ${level.world}')),
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
                                        MekuAvatar(size: 64, emotion: emotion),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Text(guidance(),
                                                style:
                                                    theme.textTheme.bodyLarge)),
                                      ])),
                              const SizedBox(height: 20),
                              if (_busy) const LinearProgressIndicator(),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(_error!,
                                        style: TextStyle(color: c.error))),
                              AnimatedSwitcher(
                                  duration: _animate
                                      ? const Duration(milliseconds: 220)
                                      : Duration.zero,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                              position: Tween(
                                                      begin:
                                                          const Offset(.06, 0),
                                                      end: Offset.zero)
                                                  .animate(animation),
                                              child: child)),
                                  child: Column(
                                      key: ValueKey(
                                          '${_phase.name}:$_word:$_question'),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (_phase == _Phase.words) ...[
                                          Text('01 · Слова',
                                              style:
                                                  theme.textTheme.titleLarge),
                                          const SizedBox(height: 8),
                                          Text('Слово ${_word + 1} із 2'),
                                          const SizedBox(height: 12),
                                          SilkPanel(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(word.word,
                                                    style: theme.textTheme
                                                        .headlineMedium),
                                                const SizedBox(height: 8),
                                                Text(word.translation,
                                                    style: theme
                                                        .textTheme.titleMedium),
                                                const SizedBox(height: 16),
                                                Text(word.example),
                                              ])),
                                          const SizedBox(height: 16),
                                          FilledButton(
                                              onPressed: _busy ? null : _recall,
                                              child: const Text(
                                                  'Перевірити слово')),
                                          if (journey.readyForTest(level))
                                            TextButton(
                                                onPressed:
                                                    _busy ? null : _startTest,
                                                child: const Text(
                                                    'Обидва слова вже перевірені · До тесту')),
                                        ],
                                        if (_phase == _Phase.recall) ...[
                                          Text('Що означає «${word.word}»?',
                                              style: theme
                                                  .textTheme.headlineSmall),
                                          const SizedBox(height: 16),
                                          for (var i = 0;
                                              i < _wordOptions.length;
                                              i++)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: AnswerTile(
                                                    label: _wordOptions[i],
                                                    marker: String.fromCharCode(
                                                        65 + i),
                                                    selected: _wordCorrect ==
                                                            true &&
                                                        _wordOptions[i] ==
                                                            word.translation,
                                                    correct: _wordCorrect ==
                                                            true &&
                                                        _wordOptions[i] ==
                                                            word.translation,
                                                    onTap: _busy ||
                                                            _wordCorrect == true
                                                        ? null
                                                        : () => _verify(
                                                            _wordOptions[i]))),
                                          if (_wordCorrect == false)
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 12),
                                                child: Text(
                                                    'Ще спроба! Пригадай переклад — або повернися до картки.')),
                                          if (_wordCorrect == true)
                                            FilledButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () {
                                                        if (_word == 0) {
                                                          setState(() {
                                                            _word = 1;
                                                            _phase =
                                                                _Phase.words;
                                                            _wordCorrect = null;
                                                          });
                                                        } else {
                                                          _startTest();
                                                        }
                                                      },
                                                child: Text(_word == 0
                                                    ? 'Друге слово'
                                                    : 'До тесту')),
                                          TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => setState(() =>
                                                      _phase = _Phase.words),
                                              child: const Text(
                                                  'Повернутися до картки')),
                                        ],
                                        if (_phase == _Phase.test) ...[
                                          Text(
                                              '02 · Перевірка ${_question + 1}/5',
                                              style:
                                                  theme.textTheme.titleLarge),
                                          const SizedBox(height: 8),
                                          const Text(
                                              'Для проходження потрібно 4 правильні відповіді.'),
                                          const SizedBox(height: 12),
                                          LinearProgressIndicator(
                                              value: _question / 5),
                                          const SizedBox(height: 20),
                                          Text(_questions[_question].question,
                                              style: theme
                                                  .textTheme.headlineSmall),
                                          const SizedBox(height: 16),
                                          for (var i = 0;
                                              i <
                                                  _questions[_question]
                                                      .options
                                                      .length;
                                              i++)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: AnswerTile(
                                                    label: _questions[_question]
                                                        .options[i],
                                                    marker: String.fromCharCode(
                                                        65 + i),
                                                    selected: _answer == i,
                                                    correct: _answer != null &&
                                                        i ==
                                                            _questions[_question]
                                                                .answer,
                                                    incorrect: _answer == i &&
                                                        i !=
                                                            _questions[_question]
                                                                .answer,
                                                    onTap: _busy ||
                                                            _answer != null
                                                        ? null
                                                        : () => _choose(i))),
                                          if (_answer != null) ...[
                                            SilkPanel(
                                                child: Text(
                                                    _questions[_question]
                                                        .explanation)),
                                            const SizedBox(height: 12),
                                            FilledButton(
                                                onPressed: _busy ? null : _next,
                                                child: Text(_question == 4
                                                    ? 'Завершити тест'
                                                    : 'Далі')),
                                          ],
                                        ],
                                        if (_phase == _Phase.result) ...[
                                          TweenAnimationBuilder<double>(
                                              tween: Tween(begin: .75, end: 1),
                                              duration: _animate
                                                  ? const Duration(
                                                      milliseconds: 500)
                                                  : Duration.zero,
                                              builder: (_, scale, child) =>
                                                  Transform.scale(
                                                      scale: scale,
                                                      child: child),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    for (var i = 0; i < 3; i++)
                                                      Icon(
                                                          passed &&
                                                                  i <
                                                                      (_score == 5
                                                                          ? 3
                                                                          : 2)
                                                              ? Icons
                                                                  .star_rounded
                                                              : Icons
                                                                  .star_outline_rounded,
                                                          size: 48,
                                                          color: c.primary)
                                                  ])),
                                          const SizedBox(height: 16),
                                          Text('$_score із 5 правильно',
                                              textAlign: TextAlign.center,
                                              style: theme
                                                  .textTheme.headlineMedium),
                                          const SizedBox(height: 12),
                                          Text(
                                              passed
                                                  ? level.number == 8
                                                      ? 'Ти завершив усю пригоду! Повторюй рівні, щоб зібрати 24 зірки.'
                                                      : 'Рівень ${level.number + 1} тепер доступний на карті.'
                                                  : journey.completed(level)
                                                      ? 'Ця спроба не змінює твій попередній успіх. Наступний рівень залишається відкритим.'
                                                      : 'Слова збережені. Повтори тест — наступний рівень відкриється після 4 із 5.',
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 20),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('На карту')),
                                          TextButton(
                                              onPressed: _startTest,
                                              child:
                                                  const Text('Повторити тест')),
                                        ],
                                      ])),
                            ]))))));
  }
}
