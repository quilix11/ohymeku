// lib/widgets/stat_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color fillColor;
  final Color shadowColor;
  final String emoji;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 100,
    required this.fillColor,
    required this.shadowColor,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.statLabel),
            const Spacer(),
            Text(
              '$value',
              style: AppTextStyles.statLabel.copyWith(color: fillColor),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.trustBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFCCCCCC),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [fillColor, shadowColor],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate(key: ValueKey(value)).shimmer(
          duration: 500.ms,
          color: fillColor.withValues(alpha: 0.3),
        );
  }
}
