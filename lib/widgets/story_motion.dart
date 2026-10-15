import 'package:flutter/material.dart';

/// Finite entrance, no repeating controllers or rebuilding the animated child.
class StoryArrival extends StatelessWidget {
  final Widget child;
  const StoryArrival({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween:
          Tween(begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOutQuint,
      child: child,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), child: child)));
}

class GentlePageTransitions extends PageTransitionsBuilder {
  const GentlePageTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
        opacity: curve,
        child: SlideTransition(
            position: Tween(begin: const Offset(.035, .018), end: Offset.zero)
                .animate(curve),
            child: child));
  }
}
