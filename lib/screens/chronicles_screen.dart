import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/api_credentials.dart';
import '../story/story_service.dart';
import '../story/story_model.dart';
import '../widgets/ohymeku_design.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/story_motion.dart';
import 'settings_screen.dart';
import 'game_screen.dart';
import '../story/story_cast.dart';
import '../widgets/story_portrait.dart';

class ChroniclesScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  const ChroniclesScreen(
      {super.key, required this.settings, required this.progress});
  @override
  State<ChroniclesScreen> createState() => _ChroniclesScreenState();
}

class _ChroniclesScreenState extends State<ChroniclesScreen> {
  StoryService get story => widget.settings.story;
  String? _error;
  Future<void> _generate() async {
    setState(() => _error = null);
    try {
      await story.generate(
          name: widget.progress.dialogueName,
          level: widget.settings.effectiveLevel,
          offline: widget.settings.offlineMode,
          interests: widget.settings.interests);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _open(StoryChapter c) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => StoryReaderScreen(
                settings: widget.settings,
                progress: widget.progress,
                chapter: c)));
    if (mounted &&
        story.caughtUp &&
        story.autoContinue &&
        ApiCredentials.available &&
        !widget.settings.offlineMode) {
      await _generate();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Хроніки листів'), actions: [
        IconButton(
            tooltip: 'Щоденник доказів',
            icon: const Icon(CupertinoIcons.book),
            onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: .65,
                    minChildSize: .3,
                    maxChildSize: .9,
                    builder: (context, scroll) => ListView(
                            controller: scroll,
                            padding: const EdgeInsets.all(24),
                            children: [
                              Text('Нічого не забуто',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 12),
                              if (story.clues.isEmpty)
                                const Text(
                                    'Перші докази з’являться після твоїх рішень.'),
                              for (final clue in story.clues)
                                ListTile(
                                    leading:
                                        const Icon(CupertinoIcons.envelope),
                                    title: Text(clue)),
                              const SectionTitle('Твої рішення'),
                              for (final decision in story.decisions.values)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(decision)),
                            ]))))
      ]),
      body: SilkBackground(
          child: ListenableBuilder(
              listenable: story,
              builder: (context, _) =>
                  ListView(padding: const EdgeInsets.all(20), children: [
                    StoryArrival(
                        child: SilkPanel(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          const Row(children: [
                            MekuAvatar(size: 64),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    'Затишок. Таємниці. Трохи небезпечної магії.'))
                          ]),
                          const SizedBox(height: 16),
                          Text(
                              'Кожен лист пам’ятає тебе, ${widget.progress.dialogueName}.',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text(
                              'Люмен втрачає спогади. Разом із Meku знайди причину, навчися читати підказки англійською й виріши, кому довіряти. Твої рішення залишаються в історії.'),
                          const SizedBox(height: 16),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            Chip(
                                label: Text(
                                    '${story.chapters.where(story.finished).length} завершених розділів')),
                            Chip(label: Text('${story.clues.length} доказів'))
                          ]),
                        ]))),
                    const SectionTitle('Твоя книжка пригод'),
                    for (var i = 0; i < story.chapters.length; i++)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LearningTile(
                              title: '${i + 1}. ${story.chapters[i].title}',
                              subtitle:
                                  '${story.chapters[i].location} · ${story.finished(story.chapters[i]) ? "Прочитано · відкрити знову" : story.unlocked(i) ? "${story.done(story.chapters[i])}/${story.chapters[i].scenes.length} сцен" : "Після попереднього розділу"}${story.chapters[i].generated ? " · AI-історія" : ""}',
                              icon: story.finished(story.chapters[i])
                                  ? CupertinoIcons.checkmark_seal
                                  : story.unlocked(i)
                                      ? CupertinoIcons.envelope_open
                                      : CupertinoIcons.lock,
                              onTap: () {
                                if (story.unlocked(i)) _open(story.chapters[i]);
                              })),
                    const SectionTitle('Друзі Люмена'),
                    const Text(
                        'Вільні розмови поза сюжетом. Тут можна практикуватись без зміни доказів і рішень.'),
                    const SizedBox(height: 12),
                    for (var i = 0; i < storyCast.length; i++)
                      if (i < story.chapters.where(story.finished).length + 1)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: StoryPortrait(
                                  name: storyCast[i].name, size: 48),
                              title: Text(storyCast[i].name),
                              subtitle: Text(storyCast[i].role),
                              trailing: const Icon(CupertinoIcons.bubble_left),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => GameScreen(
                                          character: storyCast[i].character,
                                          scenario: storyCast[i],
                                          settings: widget.settings,
                                          progress: widget.progress))),
                            )),
                    SwitchListTile.adaptive(
                        title: const Text('Автопродовження'),
                        subtitle: const Text(
                            'Після останнього розділу AI напише наступний. Потрібне підключення Gemini.'),
                        value: story.autoContinue,
                        onChanged: (v) async {
                          try {
                            await story.setAutoContinue(v);
                          } catch (e) {
                            if (mounted) setState(() => _error = e.toString());
                          }
                        }),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    if (story.busy)
                      const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(children: [
                            LinearProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Meku збирає наступний лист…')
                          ])),
                    if (story.caughtUp)
                      FilledButton.icon(
                          onPressed: story.busy ? null : _generate,
                          icon: const Icon(CupertinoIcons.sparkles),
                          label: const Text('Написати продовження')),
                    if (!ApiCredentials.available)
                      TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => SettingsScreen(
                                      settings: widget.settings))),
                          child:
                              const Text('Підключити Gemini для продовжень')),
                    const SizedBox(height: 20),
                  ]))));
}

class StoryReaderScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final StoryChapter chapter;
  const StoryReaderScreen(
      {super.key,
      required this.settings,
      required this.progress,
      required this.chapter});
  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late int _scene = widget.settings.story
      .done(widget.chapter)
      .clamp(0, widget.chapter.scenes.length - 1);
  int? _answer;
  String? _error, _result;
  bool _saving = false;
  String personalized(String text) =>
      text.replaceAll('{name}', widget.progress.dialogueName);
  Future<void> _choose(int choice) async {
    if (_saving || _result != null) return;
    if (_answer != widget.chapter.scenes[_scene].answer) {
      setState(() =>
          _error = 'Прочитай англійську репліку ще раз: відповідь є в ній.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.settings.story
          .choose(widget.chapter.id, _scene, _answer!, choice);
      // Story persistence is authoritative. Reward errors must never invite a second choice.
      if (mounted) {
        setState(
            () => _result = widget.chapter.scenes[_scene].consequences[choice]);
      }
      try {
        await widget.progress
            .recordActivity('story:${widget.chapter.id}:$_scene', 8);
      } catch (_) {/* Story remains saved. */}
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final scene = c.scenes[_scene];
    final done = widget.settings.story.done(c);
    final read = _scene < done;
    final result = _result ?? widget.settings.story.consequence(c, _scene);
    return Scaffold(
        appBar: AppBar(title: Text(c.title)),
        body: SilkBackground(
            child: SafeArea(
                child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(children: [
                LinearProgressIndicator(value: (_scene + 1) / c.scenes.length),
                const SizedBox(height: 8),
                Text('${c.location} · Сцена ${_scene + 1}/${c.scenes.length}')
              ])),
          Expanded(
              child: SingleChildScrollView(
                  key: ValueKey('scene_$_scene'),
                  padding: const EdgeInsets.all(20),
                  child: StoryArrival(
                      key: ValueKey(_scene),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              scene.speaker == 'Meku'
                                  ? const MekuAvatar(size: 48)
                                  : StoryPortrait(
                                      name: scene.speaker, size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(scene.speaker,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge))
                            ]),
                            const SizedBox(height: 16),
                            Text(personalized(scene.text),
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 20),
                            SilkPanel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                  Text(personalized(scene.english),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 20),
                                  Text(scene.question),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < scene.options.length; i++)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: OutlinedButton(
                                            onPressed: read || _saving
                                                ? null
                                                : () => setState(() {
                                                      _answer = i;
                                                      _error = null;
                                                    }),
                                            style: OutlinedButton.styleFrom(
                                                backgroundColor: _answer == i ||
                                                        read &&
                                                            i == scene.answer
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                    : null),
                                            child: Align(
                                                alignment: Alignment.centerLeft,
                                                child:
                                                    Text(scene.options[i])))),
                                ])),
                            const SectionTitle('Як ти вчиниш?'),
                            if (!read)
                              for (var i = 0; i < scene.choices.length; i++)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: FilledButton.tonal(
                                        onPressed:
                                            _saving ? null : () => _choose(i),
                                        child: Text(scene.choices[i]))),
                            if (_saving) const LinearProgressIndicator(),
                            if (_error != null)
                              Text(_error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                            AnimatedSize(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                                child: result == null
                                    ? const SizedBox.shrink()
                                    : StoryArrival(
                                        child: SilkPanel(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                            Text(personalized(result),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge),
                                            const SizedBox(height: 16),
                                            const Text('ЗАПИС У ЩОДЕННИКУ',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    letterSpacing: 1)),
                                            const SizedBox(height: 8),
                                            Text(scene.clue),
                                          ])))),
                            if (read || _result != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: FilledButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () {
                                              if (_scene + 1 ==
                                                  c.scenes.length) {
                                                Navigator.pop(context);
                                              } else {
                                                setState(() {
                                                  _scene++;
                                                  _answer = null;
                                                  _result = null;
                                                  _error = null;
                                                });
                                              }
                                            },
                                      icon: const Icon(
                                          CupertinoIcons.arrow_right),
                                      label: Text(_scene + 1 == c.scenes.length
                                          ? 'До книжки пригод'
                                          : 'Наступна сцена'))),
                            if (_scene > 0)
                              TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () => setState(() {
                                            _scene--;
                                            _answer = null;
                                            _result = null;
                                            _error = null;
                                          }),
                                  child: const Text('Попередня сцена')),
                          ])))),
        ]))));
  }
}
