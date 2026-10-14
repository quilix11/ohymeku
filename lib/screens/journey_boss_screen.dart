import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../models/journey_story.dart';
import '../models/game_state.dart';
import '../models/meku_emotion.dart';
import '../services/api_credentials.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/scenario_portrait.dart';
import '../widgets/ohymeku_design.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class JourneyBossScreen extends StatefulWidget {
  final JourneyLevel level;
  final SettingsService settings;
  final ProgressService progress;
  const JourneyBossScreen(
      {super.key,
      required this.level,
      required this.settings,
      required this.progress});
  @override
  State<JourneyBossScreen> createState() => _JourneyBossScreenState();
}

class _JourneyBossScreenState extends State<JourneyBossScreen> {
  bool _dialogue = false, _busy = false;
  int _turn = 0;
  bool? _correct;
  String? _error;
  List<String> _options = [];
  final List<String> _answers = [];
  void _prepare() {
    _options = List.of(bossDialogues[widget.level.id]![_turn].options)
      ..shuffle(Random());
    _correct = null;
    _error = null;
  }

  Future<void> _answer(String answer) async {
    if (_busy || _correct == true) return;
    final q = bossDialogues[widget.level.id]![_turn];
    if (answer != q.options[q.answer]) {
      setState(() => _correct = false);
      return;
    }
    if (_turn < 2) {
      setState(() => _correct = true);
      _answers.add(answer);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.settings.journey
          .finishDialogue(widget.level.id, [..._answers, answer]);
      if (mounted) setState(() => _correct = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Печатку не збережено. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ai() async {
    if (_busy || widget.settings.offlineMode || !ApiCredentials.available) {
      return;
    }
    final opponent = widget.level.opponent!;
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => GameScreen(
                settings: widget.settings,
                progress: widget.progress,
                character: opponent.character,
                scenario: opponent,
                onVictory: (record) => widget.settings.journey
                    .recordAiVictory(widget.level.id, record))));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level,
        opponent = level.opponent!,
        theme = Theme.of(context),
        journey = widget.settings.journey;
    final defeated = journey.bossDefeated(level);
    final canAi = !widget.settings.offlineMode && ApiCredentials.available;
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar: AppBar(title: Text('Бос · ${opponent.name}')),
            body: SafeArea(
                top: false,
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Row(children: [
                                ScenarioPortrait(
                                    scenario: opponent,
                                    emotion: defeated
                                        ? NpcEmotion.proud
                                        : NpcEmotion.neutral,
                                    width: 88,
                                    height: 110,
                                    cacheWidth: 220),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(opponent.name,
                                          style: theme.textTheme.headlineSmall),
                                      Text(opponent.role,
                                          style: theme.textTheme.labelMedium)
                                    ]))
                              ]),
                              const SizedBox(height: 16),
                              SilkPanel(
                                  rose: true,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MekuAvatar(
                                            size: 48,
                                            emotion: defeated
                                                ? MekuEmotion.excited
                                                : MekuEmotion.affectionate),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Text(defeated
                                                ? 'Печатка наша! Ходімо до наступного світу.'
                                                : 'Ми дійшли! Використай слова зі стежки. Можеш пройти сюжетну дуель або поговорити з босом своїми словами.'))
                                      ])),
                              const SizedBox(height: 20),
                              if (_busy) const LinearProgressIndicator(),
                              if (_error != null)
                                Text(_error!,
                                    style: TextStyle(
                                        color: theme.colorScheme.error)),
                              if (!journey.bossReady(level))
                                const Text(
                                    'Спершу заверши квести й тест цього рівня.')
                              else if (defeated) ...[
                                Icon(Icons.workspace_premium_rounded,
                                    size: 72, color: theme.colorScheme.primary),
                                Text('Печатка: ${level.story.reward}',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge),
                                Text(
                                    journey.bossMode(level) == 'ai'
                                        ? 'Перемога в живій AI-розмові'
                                        : journey.bossMode(level) == 'legacy'
                                            ? 'Збережений результат попередньої пригоди'
                                            : 'Перемога в сюжетній дуелі',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Продовжити пригоду')),
                                const SizedBox(height: 12),
                                TextButton(
                                    onPressed: canAi ? _ai : null,
                                    child: const Text('Ще одна AI-дуель')),
                              ] else if (!_dialogue) ...[
                                Text('Зібрані підказки',
                                    style: theme.textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final word in level.worldWords)
                                    Chip(label: Text(word.word))
                                ]),
                                const SizedBox(height: 16),
                                Text(opponent.opening,
                                    style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                    key: const Key('story_boss'),
                                    onPressed: () => setState(() {
                                          _dialogue = true;
                                          _turn = 0;
                                          _answers.clear();
                                          _prepare();
                                        }),
                                    icon:
                                        const Icon(Icons.auto_stories_rounded),
                                    label:
                                        const Text('Сюжетна дуель · без ШІ')),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    key: const Key('ai_boss'),
                                    onPressed: canAi ? _ai : null,
                                    icon: const Icon(Icons.chat_rounded),
                                    label: const Text('Жива AI-дуель')),
                                if (!canAi) ...[
                                  const SizedBox(height: 16),
                                  Text(widget.settings.offlineMode
                                      ? 'Офлайн: сюжетна дуель доступна повністю.'
                                      : 'Для живої AI-дуелі підключи Gemini у налаштуваннях. Сюжетна дуель працює без ключа.'),
                                  const SizedBox(height: 12),
                                  TextButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                                builder: (_) => SettingsScreen(
                                                    settings:
                                                        widget.settings)));
                                        if (mounted) setState(() {});
                                      },
                                      child:
                                          const Text('Налаштувати AI-розмови')),
                                ],
                              ] else ...[
                                Text('Репліка ${_turn + 1} із 3',
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                Text(bossDialogues[level.id]![_turn].question,
                                    style: theme.textTheme.headlineSmall),
                                const SizedBox(height: 16),
                                for (var i = 0; i < _options.length; i++)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: AnswerTile(
                                          label: _options[i],
                                          marker: String.fromCharCode(65 + i),
                                          onTap: _busy || _correct == true
                                              ? null
                                              : () => _answer(_options[i]),
                                          correct: _correct == true &&
                                              _options[i] ==
                                                  bossDialogues[level.id]![
                                                          _turn]
                                                      .options[0])),
                                if (_correct == false)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Text(
                                          'Спробуй ще раз. ${bossDialogues[level.id]![_turn].explanation}')),
                                if (_correct == true && _turn < 2)
                                  FilledButton(
                                      onPressed: () => setState(() {
                                            _turn++;
                                            _prepare();
                                          }),
                                      child: const Text('Наступна репліка')),
                                const SizedBox(height: 12),
                                TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () =>
                                            setState(() => _dialogue = false),
                                    child: const Text('До вибору дуелі')),
                              ],
                            ]))))));
  }
}
