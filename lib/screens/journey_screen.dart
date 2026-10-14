import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../models/meku_emotion.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/ohymeku_design.dart';
import 'journey_level_screen.dart';

class JourneyScreen extends StatelessWidget {
  final SettingsService settings;
  final ProgressService progress;
  final VoidCallback onConversations;
  const JourneyScreen(
      {super.key,
      required this.settings,
      required this.progress,
      required this.onConversations});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge([settings.journey, settings]),
      builder: (context, _) {
        final theme = Theme.of(context),
            c = theme.colorScheme,
            journey = settings.journey;
        final large = MediaQuery.textScalerOf(context).scale(16) > 21;
        final extent = large
            ? 120 + MediaQuery.textScalerOf(context).scale(14) * 5.5
            : 160.0;
        final animate = settings.animationsEnabled &&
            !MediaQuery.disableAnimationsOf(context);
        void open(JourneyLevel level) {
          if (!journey.unlocked(level)) return;
          Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => JourneyLevelScreen(
                      level: level, settings: settings, progress: progress)));
        }

        return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(children: [
                Expanded(
                    child: Text('Пригода з Meku',
                        style: theme.textTheme.headlineMedium)),
                Chip(
                    avatar: const Icon(Icons.star_rounded, size: 18),
                    label: Text('${journey.totalStars}/24'))
              ]),
              const SizedBox(height: 12),
              SilkPanel(
                  rose: true,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder<double>(
                                  tween: Tween(begin: .88, end: 1),
                                  duration: animate
                                      ? const Duration(milliseconds: 500)
                                      : Duration.zero,
                                  builder: (_, value, child) => Transform.scale(
                                      scale: value, child: child),
                                  child: MekuAvatar(
                                      size: large ? 40 : 76,
                                      emotion: journey.completedCount == 8
                                          ? MekuEmotion.excited
                                          : MekuEmotion.playful)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        journey.completedCount == 8
                                            ? 'Усі острови твої!'
                                            : large
                                                ? 'Meku поруч!'
                                                : 'Я покажу дорогу!',
                                        style: large
                                            ? theme.textTheme.titleMedium
                                            : theme.textTheme.titleLarge),
                                    const SizedBox(height: 6),
                                    Text(journey.completedCount == 8
                                        ? 'Можеш повторювати рівні й збирати всі зірки.'
                                        : 'Два слова + тест. Чотири з п’яти правильно — і новий острів твій!'),
                                  ])),
                            ]),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                            value: journey.completedCount / 8,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8)),
                        const SizedBox(height: 8),
                        Text(large
                            ? '${journey.completedCount}/8 рівнів'
                            : 'Пройдено ${journey.completedCount} із 8 рівнів'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                            key: const Key('journey_continue'),
                            onPressed: () => open(journey.current),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(journey.completedCount == 8
                                ? 'Повторити фінал'
                                : large
                                    ? 'Рівень ${journey.current.number}'
                                    : 'Рівень ${journey.current.number} · Почати')),
                      ])),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                  key: const Key('open_conversations'),
                  onPressed: onConversations,
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Вільні розмови з персонажами')),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth = min(220.0, width * .54);
                return CustomPaint(
                    painter:
                        _PathPainter(extent, c.primary.withValues(alpha: .22)),
                    child: SizedBox(
                        width: width,
                        height: extent * 8,
                        child: Stack(children: [
                          for (final level in journeyLevels)
                            Positioned(
                                top: extent * (level.number - 1) + 8,
                                left: width * (level.number.isOdd ? .28 : .72) -
                                    cardWidth / 2,
                                width: cardWidth,
                                child: TweenAnimationBuilder<double>(
                                    key: ValueKey(level.id),
                                    tween: Tween(begin: .9, end: 1),
                                    duration: animate
                                        ? Duration(
                                            milliseconds:
                                                350 + level.number * 30)
                                        : Duration.zero,
                                    builder: (_, scale, child) =>
                                        Transform.scale(
                                            scale: scale, child: child),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Semantics(
                                              button: true,
                                              enabled: journey.unlocked(level),
                                              label:
                                                  'Рівень ${level.number}: ${level.title}${journey.unlocked(level) ? '' : '. Зачинено'}',
                                              child: Material(
                                                  color: journey
                                                          .completed(level)
                                                      ? c.secondaryContainer
                                                      : journey.unlocked(level)
                                                          ? c.primary
                                                          : c
                                                              .surfaceContainerHighest,
                                                  elevation:
                                                      journey.unlocked(level)
                                                          ? 5
                                                          : 0,
                                                  shadowColor: c.primary
                                                      .withValues(alpha: .25),
                                                  shape: CircleBorder(
                                                      side: BorderSide(
                                                          color: journey.unlocked(
                                                                  level)
                                                              ? c.primary
                                                              : c
                                                                  .outlineVariant,
                                                          width: 3)),
                                                  child: InkWell(
                                                      key: Key(
                                                          'journey_level_${level.id}'),
                                                      customBorder:
                                                          const CircleBorder(),
                                                      onTap: journey
                                                              .unlocked(level)
                                                          ? () => open(level)
                                                          : null,
                                                      child: SizedBox.square(
                                                          dimension: 68,
                                                          child: Icon(
                                                              !journey.unlocked(
                                                                      level)
                                                                  ? Icons
                                                                      .lock_rounded
                                                                  : journey.completed(
                                                                          level)
                                                                      ? Icons.check_rounded
                                                                      : level.boss
                                                                          ? Icons.flag_rounded
                                                                          : Icons.star_rounded,
                                                              size: 32,
                                                              color: journey.unlocked(level) && !journey.completed(level) ? c.onPrimary : c.onSurfaceVariant))))),
                                          const SizedBox(height: 8),
                                          Text(
                                              '${level.number}. ${level.title}',
                                              textAlign: TextAlign.center,
                                              style:
                                                  theme.textTheme.titleSmall),
                                          const SizedBox(height: 3),
                                          if (journey.completed(level))
                                            Semantics(
                                                label:
                                                    '${journey.stars(level)} зірки',
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      for (var i = 0;
                                                          i <
                                                              journey
                                                                  .stars(level);
                                                          i++)
                                                        Icon(Icons.star_rounded,
                                                            size: 18,
                                                            color: c.primary),
                                                    ]))
                                          else
                                            Text(
                                                journey.unlocked(level)
                                                    ? '${level.world} · 2 слова + тест'
                                                    : 'Пройди рівень ${level.number - 1}',
                                                textAlign: TextAlign.center,
                                                style:
                                                    theme.textTheme.bodySmall),
                                        ]))),
                        ])));
              }),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              const Text(
                  'Прогрес пригоди зберігається на цьому пристрої. Усі рівні працюють без інтернету.',
                  textAlign: TextAlign.center),
            ]);
      });
}

class _PathPainter extends CustomPainter {
  final double extent;
  final Color color;
  _PathPainter(this.extent, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    Offset point(int i) =>
        Offset(size.width * (i.isEven ? .28 : .72), extent * i + 42);
    var prior = point(0);
    path.moveTo(prior.dx, prior.dy);
    for (var i = 1; i < 8; i++) {
      final next = point(i), middle = (prior.dy + next.dy) / 2;
      path.cubicTo(prior.dx, middle, next.dx, middle, next.dx, next.dy);
      prior = next;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      extent != old.extent || color != old.color;
}
