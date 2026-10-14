import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Shared surfaces for the Ohymeku screens, with no per-frame blur layers.
class SilkBackground extends StatelessWidget {
  final Widget child;
  const SilkBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  AppColors.backgroundDark,
                  const Color(0xFF1B2428),
                  const Color(0xFF25242C)
                ]
              : [
                  AppColors.background,
                  const Color(0xFFEEF4F2),
                  const Color(0xFFF7F3F3)
                ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1, -.7),
            radius: 1.35,
            colors: [
              const Color(0xFFB9D8CF).withValues(alpha: dark ? .08 : .40),
              const Color(0xFFB9D8CF).withValues(alpha: 0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1, .8),
              radius: 1.4,
              colors: [
                const Color(0xFFE2C9D0).withValues(alpha: dark ? .06 : .30),
                const Color(0xFFE2C9D0).withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
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
    return Container(
        padding: padding,
        decoration: AppVisuals.panelDecoration(context, rose: rose),
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
      color: AppVisuals.panelColor(context),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppVisuals.radiusControl),
          side: BorderSide(color: AppVisuals.panelBorder(context), width: .65)),
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
                          ? Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: .52)
                          : Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: .52),
                      borderRadius:
                          BorderRadius.circular(AppVisuals.radiusSmall)),
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
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
              const SizedBox(width: 8),
              Icon(CupertinoIcons.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        ? c.errorContainer.withValues(alpha: .72)
        : highlighted
            ? c.primaryContainer.withValues(alpha: .70)
            : AppVisuals.panelColor(context);
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
              borderRadius: BorderRadius.circular(AppVisuals.radiusControl),
              side: BorderSide(
                  color: incorrect
                      ? c.error.withValues(alpha: .48)
                      : highlighted
                          ? c.primary.withValues(alpha: .42)
                          : AppVisuals.panelBorder(context),
                  width: .75)),
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
                              ? c.primary.withValues(alpha: .12)
                              : c.surfaceContainerHighest
                                  .withValues(alpha: .45),
                          borderRadius:
                              BorderRadius.circular(AppVisuals.radiusSmall)),
                      child: Text(marker,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: highlighted ? c.primary : c.onSurface))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: ink))),
                  if (correct || incorrect || selected) ...[
                    const SizedBox(width: 8),
                    Icon(
                        incorrect
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.check_mark,
                        size: 19,
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
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: .52),
                borderRadius: BorderRadius.circular(AppVisuals.radiusControl)),
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

/// Keep paired actions apart and stack them when labels need more room.
class AdaptiveActions extends StatelessWidget {
  final List<Widget> children;
  const AdaptiveActions({super.key, required this.children});
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(16) > 21) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++)
                  Padding(
                      padding: EdgeInsets.only(
                          bottom: i == children.length - 1 ? 0 : 12),
                      child: children[i])
              ]);
        }
        return Row(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i])
          ]
        ]);
      });
}
