// lib/widgets/duo_app_bar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DuoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int streak;
  final int xp;
  final int hearts;
  final bool isDark;

  const DuoAppBar({
    super.key,
    required this.streak,
    required this.xp,
    required this.hearts,
    required this.isDark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF111827) : AppColors.background;
    final borderColor =
        isDark ? const Color(0xFF374151) : AppColors.borderDefault;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flag / Language icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: const Text('🇺🇸', style: TextStyle(fontSize: 18)),
              ),

              // Stats
              Row(
                children: [
                  _StatItem(
                    icon: '🔥',
                    value: '$streak',
                    color: AppColors.secondary,
                    textColor: AppColors.secondary,
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: '💎',
                    value: '$xp',
                    color: const Color(0xFF1CB0F6), // Duolingo Blue
                    textColor: const Color(0xFF1CB0F6),
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: '❤️',
                    value: hearts > 0 ? '$hearts' : '0',
                    color: AppColors.heartActive,
                    textColor: AppColors.heartActive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;
  final Color textColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
