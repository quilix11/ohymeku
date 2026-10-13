import 'package:flutter/material.dart' hide Feedback;
import '../models/game_state.dart';

class CoachingBox extends StatelessWidget {
  final Feedback feedback;
  final VoidCallback? onPractice;
  const CoachingBox({super.key, required this.feedback, this.onPractice});
  @override
  Widget build(BuildContext context) {
    final lines = [feedback.grammarCorrection, feedback.tacticalAdvice]
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb_outline_rounded),
              title: const Text('Порада тренера'),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (feedback.exercise != null && onPractice != null)
                  TextButton.icon(
                      onPressed: onPractice,
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Закріпити граматику')),
                Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(lines.join('\n\n'),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            height: 1.5)))
              ],
            )));
  }
}
