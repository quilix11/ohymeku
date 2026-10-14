import '../widgets/scenario_portrait.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import '../models/game_state.dart';
import '../models/scenario.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import 'game_screen.dart';
import 'generation_screen.dart';
import 'practice_screen.dart';
import '../widgets/ohymeku_design.dart';
import '../theme/app_theme.dart';

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
          SectionTitle('Обери ситуацію',
              trailing: IconButton(
                  tooltip: 'Створити співрозмовника',
                  onPressed: _create,
                  icon: const Icon(CupertinoIcons.plus))),
          LayoutBuilder(builder: (context, constraints) {
            final columns = !large && constraints.maxWidth >= 280 ? 2 : 1;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
                key: const Key('character_carousel'),
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < scenarios.length; i++)
                    SizedBox(
                        width: width,
                        child: _SceneChoice(
                            key: Key(
                                'character_choice_${scenarios[i].customId ?? scenarios[i].character.name}'),
                            scenario: scenarios[i],
                            selected: _index == i,
                            onTap: () {
                              setState(() => _index = i);
                              widget.settings.setLastCharacter(i);
                            })),
                ]);
          }),
          const SizedBox(height: 16),
          SilkPanel(
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
                                s.customId == 'willow'
                                    ? s.title
                                    : s.customId != null
                                        ? s.role
                                        : s.character == GameCharacter.officer
                                            ? 'Паспортний контроль'
                                            : 'Твоя співбесіда',
                                style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 6),
                            Text(s.level, style: theme.textTheme.labelLarge),
                            if (s.portraitStatus == PortraitStatus.queued ||
                                s.portraitStatus == PortraitStatus.generating)
                              Text(s.portraitStatus == PortraitStatus.queued
                                  ? 'Портрети в черзі'
                                  : 'Портрети генеруються у фоні'),
                            if (s.portraitStatus == PortraitStatus.failed)
                              Text(
                                  s.portraitError ??
                                      'Не вдалося створити портрети.',
                                  style: TextStyle(color: c.error)),
                          ])),
                      const SizedBox(width: 12),
                      ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppVisuals.radiusControl),
                          child: ScenarioPortrait(
                            scenario: s,
                            onRetry: s.customId == null
                                ? null
                                : () =>
                                    widget.settings.retryPortraits(s.customId!),
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
                        key: Key('start_${s.customId ?? s.character.name}'),
                        onPressed: _opening ? null : _start,
                        icon: const Icon(CupertinoIcons.play, size: 28),
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
                icon: CupertinoIcons.book,
                onTap: widget.onReading!),
            const SizedBox(height: 10),
          ],
          LearningTile(
              title: 'Повторити слова',
              subtitle: '$dueWords до повторення',
              icon: CupertinoIcons.square_stack,
              onTap: widget.onWords ?? _practice),
          const SizedBox(height: 10),
          LearningTile(
              title: 'Потренувати граматику',
              subtitle: 'Завдання твого рівня',
              icon: CupertinoIcons.pencil_outline,
              onTap: _practice),
        ]);
  }
}

class _SceneChoice extends StatelessWidget {
  final Scenario scenario;
  final bool selected;
  final VoidCallback onTap;
  const _SceneChoice(
      {super.key,
      required this.scenario,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
        button: true,
        selected: selected,
        child: Material(
            color: selected
                ? c.primary.withValues(alpha: .07)
                : AppVisuals.panelColor(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppVisuals.radiusControl),
                side: BorderSide(
                    color: selected
                        ? c.primary.withValues(alpha: .38)
                        : AppVisuals.panelBorder(context),
                    width: 1)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppVisuals.radiusSmall),
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
                                    color: selected ? c.primary : c.onSurface,
                                    fontWeight: FontWeight.w600))),
                  ])),
            )));
  }
}
