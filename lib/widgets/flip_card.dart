import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Both faces share their maximum height, keeping review buttons stationary.
class FlipCard extends StatelessWidget {
  final bool flipped;
  final bool animate;
  final VoidCallback onTap;
  final Widget front;
  final Widget back;

  const FlipCard(
      {super.key,
      required this.flipped,
      required this.animate,
      required this.onTap,
      required this.front,
      required this.back});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final motion = animate && !MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: flipped ? 1 : 0, end: flipped ? 1 : 0),
      duration: motion ? const Duration(milliseconds: 460) : Duration.zero,
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) {
        final progress = motion ? value : (flipped ? 1.0 : 0.0);
        final showBack = progress >= .5;
        return Transform(
          key: const ValueKey('word_card_rotation'),
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateY(math.pi * progress),
          child: Semantics(
            button: true,
            label: showBack ? 'Приховати переклад' : 'Показати переклад',
            child: Material(
              color: AppVisuals.panelColor(context, rose: showBack),
              elevation: 8 * math.sin(math.pi * progress),
              shadowColor: colors.primary.withValues(alpha: .16),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppVisuals.radiusCard),
                  side: BorderSide(
                      color: AppVisuals.panelBorder(context), width: 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Stack(alignment: Alignment.topCenter, children: [
                  Visibility(
                      visible: !showBack,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: front),
                  Visibility(
                      visible: showBack,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: back)),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
