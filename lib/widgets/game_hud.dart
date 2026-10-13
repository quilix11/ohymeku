// lib/widgets/game_hud.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'stat_bar.dart';

class GameHud extends StatelessWidget {
  final GameState state;
  final bool isDark;
  const GameHud({super.key, required this.state, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111827) : AppColors.background;
    final borderColor =
        isDark ? const Color(0xFF374151) : AppColors.borderDefault;
    return Container(
      padding:
          const EdgeInsets.fromLTRB(16, 8, 60, 12), // right 60 for settings btn
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LivesColumn(lives: state.lives),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatBar(
                  label: 'TRUST',
                  value: state.trust,
                  fillColor: AppColors.trustFill,
                  shadowColor: AppColors.trustShadow,
                  emoji: '🛡️',
                ),
                const SizedBox(height: 8),
                StatBar(
                  label: 'PATIENCE',
                  value: state.patience,
                  fillColor: AppColors.patienceFill,
                  shadowColor: AppColors.patienceShadow,
                  emoji: '⏱️',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivesColumn extends StatelessWidget {
  final int lives;
  const _LivesColumn({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(3, (i) {
          final active = i < lives;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey('$i-$active'),
                color: active ? AppColors.heartActive : AppColors.heartEmpty,
                size: 22,
              ),
            ),
          );
        }),
      ],
    );
  }
}
