import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';

class NpcAvatar extends StatelessWidget {
  final GameCharacter character;
  final NpcEmotion emotion;
  final bool large;
  const NpcAvatar(
      {super.key,
      required this.character,
      required this.emotion,
      this.large = false});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(large ? 24 : 16),
      child: Image.asset(Scenario.of(character).image(emotion),
          cacheWidth: large ? 360 : 104,
          width: large ? 180 : 52,
          height: large ? 220 : 52,
          fit: BoxFit.contain,
          semanticLabel:
              '${Scenario.of(character).name}: ${emotionLabel(emotion)}'));
}

class CharacterStage extends StatelessWidget {
  final Scenario scenario;
  final NpcEmotion emotion;
  final String activity;
  final bool compact;
  const CharacterStage(
      {super.key,
      required this.scenario,
      required this.emotion,
      required this.activity,
      required this.compact});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 1.5))),
      child: Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: Image.asset(scenario.image(emotion),
                  key: ValueKey(emotion),
                  cacheWidth: 240,
                  width: 52,
                  height: 64,
                  fit: BoxFit.contain,
                  semanticLabel: '${scenario.name}: ${emotionLabel(emotion)}'),
            )),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(scenario.role,
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(activity, style: theme.textTheme.titleMedium),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(emotionLabel(emotion), style: theme.textTheme.bodySmall)
          ],
        ])),
      ]),
    );
  }
}
