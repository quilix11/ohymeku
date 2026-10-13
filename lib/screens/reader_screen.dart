import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reading_article.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/ai_service.dart';
import '../widgets/ohymeku_design.dart';
import '../widgets/word_clickable_text.dart';
import '../widgets/dictionary_sheet.dart';

class ReaderScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final ReadingArticle article;
  const ReaderScreen(
      {super.key,
      required this.settings,
      required this.progress,
      required this.article});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ReadingQuiz? _quiz;
  List<int?> _answers = [];
  bool _busy = false, _saving = false, _bookmarking = false;
  int? _score;
  String? _error;
  final _scroll = ScrollController();
  Future<void> _startQuiz() async {
    if (_busy || _saving) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final quiz = await widget.settings.reading.quizFor(widget.article,
          offline: widget.settings.offlineMode,
          level: widget.settings.effectiveLevel);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _answers = List.filled(quiz.questions.length, null);
        _score = null;
      });
      _scroll.jumpTo(0);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is AiException
            ? e.message
            : 'Не вдалося підготувати запитання. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_quiz == null ||
        _saving ||
        _answers.any((a) => a == null) ||
        _score != null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final score = await widget.settings.reading
          .complete(widget.article, _quiz!, _answers.cast<int>());
      await widget.progress.recordActivity(
          'reading:${widget.article.id}:${widget.article.fingerprint}',
          4 + score * 2);
      if (mounted) setState(() => _score = score);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is AiException
            ? e.message
            : 'Не вдалося зберегти результат. Повтори спробу.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _bookmark() async {
    if (_bookmarking) return;
    setState(() => _bookmarking = true);
    try {
      await widget.settings.reading.setBookmark(widget.article.id,
          !widget.settings.reading.bookmarks.contains(widget.article.id));
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is AiException ? e.message : 'Не вдалося зберегти закладку.');
      }
    } finally {
      if (mounted) setState(() => _bookmarking = false);
    }
  }

  Future<void> _source(String url) async {
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* Surface unavailable browser handlers as normal feedback. */}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося відкрити посилання.')));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.settings.reading,
      builder: (context, _) {
        final theme = Theme.of(context),
            c = theme.colorScheme,
            article = widget.article;
        return PopScope(
            canPop: !_saving,
            child: Scaffold(
              appBar: AppBar(
                  title: Text(_quiz == null ? 'Читання' : 'Перевір розуміння'),
                  actions: [
                    IconButton(
                        tooltip: widget.settings.reading.bookmarks
                                .contains(article.id)
                            ? 'Прибрати закладку'
                            : 'Зберегти текст',
                        onPressed: _bookmarking ? null : _bookmark,
                        icon: Icon(widget.settings.reading.bookmarks
                                .contains(article.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded)),
                  ]),
              body: SilkBackground(
                  child: Center(
                      child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(article.title,
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                          '${article.level} · ${article.words} слів · ≈${article.minutes} хв',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 20),
                      if (_quiz == null) ...[
                        SilkPanel(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                const Icon(Icons.touch_app_outlined, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'Торкнись англійського слова для перекладу',
                                        style: theme.textTheme.bodySmall))
                              ]),
                              const SizedBox(height: 20),
                              WordClickableText(
                                  text: article.text,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(height: 1.8),
                                  onWordTap: (word) => showDictionary(
                                      context, widget.settings,
                                      word: word)),
                            ])),
                        const SizedBox(height: 16),
                        Text(article.source, style: theme.textTheme.labelLarge),
                        if (article.url.isNotEmpty) ...[
                          Text(
                              'Уривок вступу · Wikipedia contributors · ${article.license}',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            TextButton.icon(
                                onPressed: () => _source(article.url),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Оригінал статті')),
                            TextButton(
                                onPressed: () => _source(
                                    'https://creativecommons.org/licenses/by-sa/4.0/'),
                                child: const Text('Ліцензія')),
                          ]),
                        ],
                        const SectionTitle('Після читання'),
                        const Text(
                            'Три запитання допоможуть перевірити, що ти зрозумів із тексту.'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            key: const Key('start_reading_quiz'),
                            onPressed: _busy ? null : _startQuiz,
                            icon: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.quiz_outlined),
                            label: Text(_busy
                                ? 'Готую запитання…'
                                : 'Перевірити розуміння')),
                      ] else ...[
                        Text(
                            _quiz!.kind == 'ai'
                                ? 'Запитання ШІ · з опорою на текст'
                                : _quiz!.kind == 'authored'
                                    ? 'Запитання до навчального тексту'
                                    : 'Віднови факти з тексту · локальні запитання',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 12),
                        TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _quiz = null),
                            icon: const Icon(Icons.auto_stories_outlined),
                            label: const Text('Повернутися до тексту')),
                        for (var i = 0; i < _quiz!.questions.length; i++) ...[
                          SectionTitle(
                              'Запитання ${i + 1} із ${_quiz!.questions.length}'),
                          Text(_quiz!.questions[i].question,
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          for (var j = 0; j < 4; j++)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AnswerTile(
                                  key: Key('reading_answer_${i}_$j'),
                                  marker: String.fromCharCode(65 + j),
                                  label: _quiz!.questions[i].options[j],
                                  selected: _answers[i] == j,
                                  correct: _score != null &&
                                      _quiz!.questions[i].answer == j,
                                  incorrect: _score != null &&
                                      _answers[i] == j &&
                                      j != _quiz!.questions[i].answer,
                                  onTap: _saving || _score != null
                                      ? null
                                      : () => setState(() => _answers[i] = j),
                                )),
                          if (_score != null)
                            SilkPanel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(_quiz!.questions[i].explanation),
                                  const SizedBox(height: 8),
                                  Text(
                                      'У тексті: “${_quiz!.questions[i].evidence}”',
                                      style: theme.textTheme.bodySmall),
                                ])),
                        ],
                        const SizedBox(height: 16),
                        if (_score == null)
                          FilledButton.icon(
                              key: const Key('finish_reading_quiz'),
                              onPressed:
                                  _saving || _answers.any((a) => a == null)
                                      ? null
                                      : _finish,
                              icon: const Icon(Icons.check_rounded),
                              label: Text(_saving
                                  ? 'Зберігаю…'
                                  : 'Перевірити відповіді'))
                        else
                          SilkPanel(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Твій результат: $_score/3',
                                    style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 8),
                                const Text(
                                    'Переглянь пояснення й цитати вище. Результат збережено.'),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                    onPressed: () => setState(() {
                                          _answers = List.filled(3, null);
                                          _score = null;
                                          _scroll.jumpTo(0);
                                        }),
                                    child: const Text('Спробувати ще раз')),
                              ])),
                      ],
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(_error!,
                                    style: TextStyle(color: c.error)))),
                      const SizedBox(height: 32),
                    ]),
              ))),
            ));
      });
}
