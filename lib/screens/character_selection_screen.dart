import '../widgets/scenario_portrait.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'generation_screen.dart';
import 'practice_screen.dart';
import '../widgets/ohymeku_design.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final VoidCallback? onWords;
  final VoidCallback? onReading;
  const CharacterSelectionScreen(
      {super.key,
      required this.settings,
      required this.progress,
      this.onWords,
      this.onReading});
  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  late int _index;
  bool _opening = false;
  List<Scenario> get _scenarios =>
      [...Scenario.all, ...widget.settings.customScenarios];
  Future<void> _create() async {
    if (widget.settings.offlineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Створення персонажа потребує інтернету. Вимкни офлайн-режим у налаштуваннях.')));
      return;
    }
    final previousCount = _scenarios.length;
    await Navigator.push(
        context,
        MaterialPageRoute<bool>(
            builder: (_) => GenerationScreen(
                boss: true,
                level: widget.settings.effectiveLevel,
                interests: widget.settings.interests,
                onSave: (result, topic, level, warm) async {
                  await widget.settings
                      .addGeneratedScenario(result, topic, level, warm);
                })));
    if (mounted) {
      setState(() {
        if (_scenarios.length > previousCount) _index = _scenarios.length - 1;
      });
      widget.settings.setLastCharacter(_index);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_settingsChanged);
    widget.settings.vocabulary.addListener(_settingsChanged);
    widget.settings.learner.addListener(_settingsChanged);
    _index = widget.settings.lastCharacter;
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.settings.removeListener(_settingsChanged);
    widget.settings.vocabulary.removeListener(_settingsChanged);
    widget.settings.learner.removeListener(_settingsChanged);
    super.dispose();
  }

  Future<void> _start() async {
    if (_opening) return;
    if (widget.settings.offlineMode) {
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => PracticeScreen(
                  settings: widget.settings, progress: widget.progress)));
      return;
    }
    setState(() => _opening = true);
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => GameScreen(
            settings: widget.settings,
            progress: widget.progress,
            character: _scenarios[_index].character,
            scenario: _scenarios[_index])));
    if (mounted) setState(() => _opening = false);
  }

  void _practice() => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => PracticeScreen(
              settings: widget.settings, progress: widget.progress)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final scenarios = _scenarios;
    _index = _index.clamp(0, scenarios.length - 1);
    final s = scenarios[_index];
    final large = MediaQuery.textScalerOf(context).scale(16) > 21;
    final dueWords = widget.settings.vocabulary.cards
        .where((card) => widget.settings.vocabulary.isDue(card.id))
        .length;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      widget.progress.editableName.isEmpty
                          ? 'Твій навчальний день'
                          : 'Привіт, ${widget.progress.editableName}',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Обери, що практикуватимемо.',
                      style: theme.textTheme.bodyMedium),
                ])),
            IconButton(
                tooltip: 'Налаштування',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            SettingsScreen(settings: widget.settings))),
                icon: const Icon(Icons.tune_rounded)),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _DayStat(
                icon: Icons.school_outlined,
                value: widget.settings.effectiveLevel,
                label: 'Рівень'),
            _DayStat(
                icon: Icons.local_fire_department_outlined,
                value: '${widget.progress.profile.streakDays}',
                label: 'Серія днів'),
            _DayStat(
                icon: Icons.bolt_outlined,
                value: '${widget.progress.profile.xp}',
                label: 'XP'),
          ]),
          SectionTitle('Обери ситуацію',
              trailing: IconButton(
                  tooltip: 'Створити співрозмовника',
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded))),
          if (large)
            Column(key: const Key('character_carousel'), children: [
              for (var i = 0; i < scenarios.length; i++)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SceneChoice(
                        scenario: scenarios[i],
                        selected: _index == i,
                        onTap: () {
                          setState(() => _index = i);
                          widget.settings.setLastCharacter(i);
                        })),
            ])
          else
            SizedBox(
                height: 88,
                child: ListView.separated(
                  key: const Key('character_carousel'),
                  scrollDirection: Axis.horizontal,
                  itemCount: scenarios.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => SizedBox(
                      width: 180,
                      child: _SceneChoice(
                          scenario: scenarios[i],
                          selected: _index == i,
                          onTap: () {
                            setState(() => _index = i);
                            widget.settings.setLastCharacter(i);
                          })),
                )),
          const SizedBox(height: 16),
          SilkPanel(
              rose: s.character == GameCharacter.hr,
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                widget.settings.offlineMode
                                    ? 'ОФЛАЙН-ПРАКТИКА'
                                    : 'РОЗМОВНИЙ ТРЕНАЖЕР',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1,
                                    color: c.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(
                                s.customId != null
                                    ? s.role
                                    : s.character == GameCharacter.officer
                                        ? 'Паспортний контроль'
                                        : 'Твоя співбесіда',
                                style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 6),
                            Text(s.level, style: theme.textTheme.labelLarge),
                          ])),
                      const SizedBox(width: 12),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ScenarioPortrait(
                            scenario: s,
                            width: 80,
                            height: 96,
                            fit: BoxFit.contain,
                            cacheWidth: 240,
                          )),
                    ]),
                    const SizedBox(height: 16),
                    Text(
                        s.customId != null
                            ? s.goal
                            : s.character == GameCharacter.officer
                                ? 'Поясни мету подорожі та переконай офіцера пропустити тебе.'
                                : 'Розкажи про свій досвід і покажи сильні сторони.',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        key: Key('start_${s.character.name}'),
                        onPressed: _opening ? null : _start,
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: Text(widget.settings.offlineMode
                            ? 'Практикувати офлайн'
                            : 'Поговорити з ${s.name}')),
                    const SizedBox(height: 10),
                    Text(
                        '${widget.progress.winsFor(s.character, scenarioId: s.customId)} успішних розмов',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall),
                  ])),
          const SectionTitle('Практика без інтернету'),
          if (widget.onReading != null) ...[
            LearningTile(
                title: 'Читати тексти',
                subtitle: 'Статті, переклад слів і запитання',
                icon: Icons.menu_book_outlined,
                onTap: widget.onReading!),
            const SizedBox(height: 10),
          ],
          LearningTile(
              title: 'Повторити слова',
              subtitle: '$dueWords до повторення',
              icon: Icons.style_outlined,
              onTap: widget.onWords ?? _practice),
          const SizedBox(height: 10),
          LearningTile(
              title: 'Потренувати граматику',
              subtitle: 'Завдання твого рівня',
              icon: Icons.edit_note_rounded,
              onTap: _practice,
              rose: true),
        ]);
  }
}

class _DayStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _DayStat(
      {required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.outlineVariant, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: c.primary),
          const SizedBox(width: 8),
          Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ])),
        ]));
  }
}

class _SceneChoice extends StatelessWidget {
  final Scenario scenario;
  final bool selected;
  final VoidCallback onTap;
  const _SceneChoice(
      {required this.scenario, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
        button: true,
        selected: selected,
        child: Material(
            color: selected ? c.primary : c.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: selected ? c.primary : c.outlineVariant, width: 2)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ScenarioPortrait(
                            scenario: scenario,
                            width: 40,
                            height: 48,
                            fit: BoxFit.contain,
                            cacheWidth: 120,
                            excludeFromSemantics: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(scenario.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: selected ? c.onPrimary : c.onSurface,
                                    fontWeight: FontWeight.w800))),
                  ])),
            )));
  }
}
