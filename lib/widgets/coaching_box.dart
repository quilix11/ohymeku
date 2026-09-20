// lib/widgets/coaching_box.dart
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class CoachingBox extends StatelessWidget {
  final Feedback feedback;
  const CoachingBox({super.key, required this.feedback});

  bool get _hasContent =>
      feedback.grammarCorrection.isNotEmpty ||
      feedback.tacticalAdvice.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.coachingBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coachingBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.coachingBorder,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Порада тренера',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.coachingText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (feedback.grammarCorrection.isNotEmpty)
              _Row(icon: '🔧', label: 'Граматика', text: feedback.grammarCorrection),
            if (feedback.grammarCorrection.isNotEmpty &&
                feedback.tacticalAdvice.isNotEmpty)
              const SizedBox(height: 8),
            if (feedback.tacticalAdvice.isNotEmpty)
              _Row(icon: '🎯', label: 'Тактика', text: feedback.tacticalAdvice),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: 150.ms)
        .slideY(begin: 0.15, end: 0, duration: 350.ms, delay: 150.ms, curve: Curves.easeOutCubic);
  }
}

class _Row extends StatelessWidget {
  final String icon;
  final String label;
  final String text;
  const _Row({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMedium.copyWith(fontSize: 12)),
              const SizedBox(height: 2),
              Text(text, style: AppTextStyles.coachingStyle),
            ],
          ),
        ),
      ],
    );
  }
}
