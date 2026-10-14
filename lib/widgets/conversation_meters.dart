import 'package:flutter/material.dart';

/// Practice counters are local counts, not AI estimates of language proficiency.
class ConversationMeters extends StatelessWidget {
  final int trust, patience, turns, words, previousWins;
  final bool compact;
  const ConversationMeters(
      {super.key,
      required this.trust,
      required this.patience,
      required this.turns,
      required this.words,
      required this.previousWins,
      this.compact = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = previousWins.clamp(0, 3);
    final turnGoal = 3 + stage, wordGoal = 20 + stage * 10;
    final metrics = [
      (
        'Довіра',
        trust,
        100,
        'Наскільки переконливо звучить відповідь для персонажа. 80 — успішне завершення.'
      ),
      (
        'Терпіння',
        patience,
        100,
        'Готовність персонажа продовжувати. 0 — завершення розмови.'
      ),
      (
        'Відповіді',
        turns,
        turnGoal,
        'Завершені відповіді / особиста ціль. Ціль зростає після успішних розмов.'
      ),
      (
        'Різні слова',
        words,
        wordGoal,
        'Унікальні англійські слова у завершених відповідях / особиста ціль. Це лічильник практики, а не оцінка рівня.'
      ),
    ];
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: LayoutBuilder(builder: (context, box) {
          final columns = box.maxWidth >= 560 ? 4 : 2;
          return Wrap(
              spacing: 16,
              runSpacing: compact ? 8 : 12,
              children: metrics
                  .map((metric) => SizedBox(
                      width: (box.maxWidth - (columns - 1) * 16) / columns,
                      child: Tooltip(
                          message: metric.$4,
                          child: Semantics(
                              label:
                                  '${metric.$1}: ${metric.$2} з ${metric.$3}. ${metric.$4}',
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${metric.$1}  ${metric.$2}/${metric.$3}',
                                        style: theme.textTheme.labelMedium),
                                    const SizedBox(height: 5),
                                    TweenAnimationBuilder<double>(
                                        tween: Tween(
                                            end: (metric.$2 / metric.$3)
                                                .clamp(0, 1)),
                                        duration: MediaQuery
                                                .disableAnimationsOf(context)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 180),
                                        builder: (context, value, _) =>
                                            LinearProgressIndicator(
                                                value: value,
                                                minHeight: compact ? 4 : 6,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: metric.$1 == 'Терпіння'
                                                    ? theme.colorScheme.tertiary
                                                    : theme.colorScheme.primary,
                                                backgroundColor: theme
                                                    .colorScheme.primary
                                                    .withValues(alpha: .09))),
                                  ])))))
                  .toList());
        }));
  }
}
