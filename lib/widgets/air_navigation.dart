import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'meku_avatar.dart';
import '../models/meku_emotion.dart';

/// A light navigation surface with full-size targets and a quiet active mark.
class AirNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onMeku;
  final VoidCallback onSettings;
  final MekuEmotion emotion;

  const AirNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onMeku,
    required this.onSettings,
    this.emotion = MekuEmotion.smug,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final showLabels = MediaQuery.textScalerOf(context).scale(16) < 22.4;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 696),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: dark ? .20 : .28),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: c.outline.withValues(alpha: dark ? .22 : .16),
                  width: .7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? .10 : .035),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                key: const Key('air_navigation_panel'),
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _destination(
                        context,
                        kind: AppIconKind.journey,
                        label: 'Пригода',
                        selected: selectedIndex == 0,
                        showLabel: showLabels,
                        onTap: () => onSelect(0),
                      ),
                      _destination(
                        context,
                        kind: AppIconKind.words,
                        label: 'Слова',
                        selected: selectedIndex == 1,
                        showLabel: showLabels,
                        onTap: () => onSelect(1),
                      ),
                      _destination(
                        context,
                        kind: AppIconKind.meku,
                        label: 'Meku',
                        showLabel: showLabels,
                        onTap: onMeku,
                        controlKey: const Key('meku_launcher'),
                      ),
                      _destination(
                        context,
                        kind: AppIconKind.progress,
                        label: 'Прогрес',
                        selected: selectedIndex == 2,
                        showLabel: showLabels,
                        onTap: () => onSelect(2),
                      ),
                      _destination(
                        context,
                        kind: AppIconKind.settings,
                        label: 'Налаштування',
                        showLabel: showLabels,
                        onTap: onSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(
    BuildContext context, {
    required AppIconKind kind,
    required String label,
    required bool showLabel,
    required VoidCallback onTap,
    bool selected = false,
    Key? controlKey,
  }) {
    final c = Theme.of(context).colorScheme;
    final ink = selected ? c.primary : c.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        onTap: onTap,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: controlKey,
                onTap: onTap,
                excludeFromSemantics: true,
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? c.primary.withValues(alpha: .09)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: kind == AppIconKind.meku
                            ? MekuAvatar(size: 28, emotion: emotion)
                            : AppIcon(kind, size: 23, color: ink),
                      ),
                      if (showLabel) ...[
                        const SizedBox(height: 1),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: kind == AppIconKind.settings ? 8.5 : 10.5,
                            height: 1.15,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
