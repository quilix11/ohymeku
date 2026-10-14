import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/cupertino.dart' hide Feedback;
import '../models/game_state.dart';
import '../theme/app_theme.dart';

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
    final c = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
            elevation: 0,
            shadowColor: Colors.transparent,
            color: AppVisuals.panelColor(context, rose: true),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppVisuals.radiusCard),
                side: BorderSide(
                    color: AppVisuals.panelBorder(context), width: .65)),
            child: ExpansionTile(
              iconColor: c.secondary,
              collapsedIconColor: c.secondary,
              leading: const Icon(CupertinoIcons.lightbulb, size: 22),
              title: const Text('Порада тренера'),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (feedback.exercise != null && onPractice != null)
                  TextButton.icon(
                      onPressed: onPractice,
                      icon: const Icon(CupertinoIcons.book, size: 19),
                      label: const Text('Закріпити граматику')),
                Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(lines.join('\n\n'),
                        style: TextStyle(color: c.onSurface, height: 1.5)))
              ],
            )));
  }
}
