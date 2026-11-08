import 'package:flutter/material.dart';

/// Keeps the current exercise's action above the scrollable content.
class ExerciseLayout extends StatelessWidget {
  final Object step;
  final Widget? action;
  final List<Widget> children;

  const ExerciseLayout({
    super.key,
    required this.step,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (action case final button?)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: button,
            ),
          Expanded(
            child: ListView(
              key: ValueKey(step),
              padding: const EdgeInsets.all(20),
              children: children,
            ),
          ),
        ],
      );
}
