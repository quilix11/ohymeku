import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reading_article.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/ohymeku_design.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';

const readingTopics = {
  'Travel': ('Подорожі', 'Travel'),
  'Food': ('Їжа й кава', 'Coffee'),
  'IT': ('Технології', 'Technology'),
  'Business': ('Робота', 'Business'),
  'Movies': ('Кіно', 'Cinema'),
  'Music': ('Музика', 'Music'),
  'Sport': ('Спорт', 'Sport'),
  'Art': ('Мистецтво', 'Art'),
};

class ReadingScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final String initialQuery;
  const ReadingScreen(
      {super.key,
      required this.settings,
      required this.progress,
      this.initialQuery = ''});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final _query = TextEditingController(text: widget.initialQuery);
  List<ReadingArticle>? _found;
  bool _busy = false, _savedOnly = false;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) unawaited(_search());
  }

  Future<void> _search([String? topic]) async {
    if (_busy) return;
    if (topic != null) _query.text = topic;
    final request = ++_request;
    setState(() {
      _busy = true;
      _error = null;
      _savedOnly = false;
    });
    try {
      final found = await widget.settings.reading
          .search(_query.text, offline: widget.settings.offlineMode);
      if (mounted && request == _request) setState(() => _found = found);
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = e is AiException
            ? e.message
            : 'Пошук недоступний. Спробуй ще раз.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _request++;
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge([widget.settings, widget.settings.reading]),
      builder: (context, _) {
        final theme = Theme.of(context), c = theme.colorScheme;
        final reading = widget.settings.reading;
        var articles = _found ?? reading.articles;
        if (_savedOnly) {
          articles = reading.articles
              .where((a) => reading.bookmarks.contains(a.id))
              .toList();
        }
        final interests = widget.settings.interests;
        if (_found == null && !_savedOnly && interests.isNotEmpty) {
          articles = List.of(articles)
            ..sort((a, b) => (interests.contains(b.topic) ? 1 : 0)
                .compareTo(interests.contains(a.topic) ? 1 : 0));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Читання')),
          body: SilkBackground(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const ScreenIntro(
                  title: 'Читай і відкривай нове',
                  subtitle:
                      'Торкнись слова, збережи його й перевір розуміння після тексту.',
                  icon: Icons.auto_stories_outlined),
              const SizedBox(height: 20),
              TextField(
                  key: const PageStorageKey('reading_search'),
                  controller: _query,
                  maxLength: 100,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                      labelText: 'Тема статті',
                      hintText: 'Наприклад: coffee або space',
                      helperText:
                          'Пошук у Simple English Wikipedia. Найкраще — англійською.'),
                  onSubmitted: (_) => _search()),
              FilledButton.icon(
                  onPressed: _busy ? null : () => _search(),
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search_rounded),
                  label: Text(_busy
                      ? 'Шукаю статті…'
                      : widget.settings.offlineMode
                          ? 'Знайти серед збережених'
                          : 'Знайти статті')),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final topic in readingTopics.entries)
                  ActionChip(
                      label: Text(topic.value.$1),
                      onPressed: _busy ? null : () => _search(topic.value.$2)),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                    label: const Text('Бібліотека'),
                    selected: !_savedOnly && _found == null,
                    onSelected: (_) => setState(() {
                          _savedOnly = false;
                          _found = null;
                          _error = null;
                          _query.clear();
                        })),
                ChoiceChip(
                    label: Text('Закладки · ${reading.bookmarks.length}'),
                    selected: _savedOnly,
                    onSelected: (_) => setState(() => _savedOnly = true)),
              ]),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                        liveRegion: true,
                        child:
                            Text(_error!, style: TextStyle(color: c.error)))),
              SectionTitle(_savedOnly
                  ? 'Збережено для читання'
                  : _found != null
                      ? 'Результати пошуку'
                      : 'Тексти для тебе'),
              if (articles.isEmpty)
                SilkPanel(
                    child: Text(_savedOnly
                        ? 'Тут з’являться тексти, які ти додаси в закладки.'
                        : 'Нічого не знайдено. Спробуй іншу англійську назву або обери тему вище.')),
              for (final article in articles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                      color: AppVisuals.panelColor(context),
                      surfaceTintColor: Colors.transparent,
                      elevation: 1,
                      shadowColor: c.primary.withValues(alpha: .10),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppVisuals.radiusCard),
                          side: BorderSide(
                              color: AppVisuals.panelBorder(context))),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: Key('read_${article.id}'),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => ReaderScreen(
                                    settings: widget.settings,
                                    progress: widget.progress,
                                    article: article))),
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(article.title,
                                            style: theme.textTheme.titleLarge)),
                                    if (reading.bookmarks.contains(article.id))
                                      const Icon(Icons.bookmark_rounded),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded)
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${article.level} · ${article.words} слів · ≈${article.minutes} хв',
                                      style: theme.textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Text(article.text.replaceAll('\n', ' '),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 12),
                                  Text(article.source,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(color: c.primary)),
                                  if (reading.results.containsKey(article.id))
                                    Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                            'Останній результат: ${reading.results[article.id]!['correct']}/3',
                                            style: theme.textTheme.labelLarge)),
                                ])),
                      )),
                ),
              const SizedBox(height: 12),
              Text(
                  'Навчальні тексти й завантажені статті доступні офлайн. Wikipedia: уривки вступу з посиланням на оригінал.',
                  style: theme.textTheme.bodySmall),
            ]),
          ))),
        );
      });
}
