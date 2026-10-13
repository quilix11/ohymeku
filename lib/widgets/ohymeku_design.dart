import 'package:flutter/material.dart';

/// Shared surfaces for the Ohymeku screens, with no per-frame blur layers.
class SilkBackground extends StatelessWidget {
  final Widget child;
  const SilkBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: child,
    );
  }
}

class SilkPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool rose;
  const SilkPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.rose = false});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: rose ? c.secondaryContainer : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  rose ? c.secondary.withValues(alpha: .25) : c.outlineVariant,
              width: 1.5),
        ),
        child: child);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (trailing != null) trailing!,
      ]));
}

class LearningTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool rose;
  const LearningTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap,
      this.rose = false});
  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: rose
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon,
                      color: rose
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ])),
      ));
}

/// Selectable answer rows share one shape across placement and practice.
class AnswerTile extends StatelessWidget {
  final String label, marker;
  final bool selected, correct, incorrect;
  final VoidCallback? onTap;
  const AnswerTile(
      {super.key,
      required this.label,
      required this.marker,
      required this.onTap,
      this.selected = false,
      this.correct = false,
      this.incorrect = false});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final highlighted = selected || correct;
    final fill = incorrect
        ? c.errorContainer
        : highlighted
            ? c.primaryContainer
            : c.surface;
    final ink = incorrect
        ? c.onErrorContainer
        : highlighted
            ? c.onPrimaryContainer
            : c.onSurface;
    return Semantics(
      enabled: onTap != null,
      selected: selected,
      button: true,
      child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: incorrect
                      ? c.error
                      : highlighted
                          ? c.primary
                          : c.outlineVariant,
                  width: 2)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                      width: MediaQuery.textScalerOf(context)
                          .scale(14)
                          .clamp(36, 80),
                      height: MediaQuery.textScalerOf(context)
                          .scale(14)
                          .clamp(36, 80),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: highlighted
                              ? c.primary
                              : c.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(marker,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: highlighted ? c.onPrimary : c.onSurface))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: ink))),
                  if (correct || incorrect || selected) ...[
                    const SizedBox(width: 8),
                    Icon(incorrect ? Icons.close_rounded : Icons.check_rounded,
                        color: ink),
                  ],
                ])),
          )),
    );
  }
}

class ScreenIntro extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const ScreenIntro(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]);
}
