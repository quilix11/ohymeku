import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../models/meku_emotion.dart';
import '../models/game_state.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/scenario_portrait.dart';
import '../widgets/ohymeku_design.dart';
import 'journey_level_screen.dart';
import 'journey_chat_sheet.dart';
import 'journey_boss_screen.dart';

class JourneyScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final VoidCallback onConversations;
  const JourneyScreen(
      {super.key,
      required this.settings,
      required this.progress,
      required this.onConversations});
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _mapKey = GlobalKey();
  late final AnimationController _walk = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  late double _from = widget.settings.journey.current.number - 1.0, _to = _from;
  @override
  void initState() {
    super.initState();
    _walk.value = 1;
    _from = widget.settings.journey.current.number - 1.0;
    _to = _from;
  }

  bool _opening = false;
  bool get _animate =>
      widget.settings.animationsEnabled &&
      !MediaQuery.disableAnimationsOf(context);
  double get _extent => MediaQuery.textScalerOf(context).scale(16) > 21
      ? 155 + MediaQuery.textScalerOf(context).scale(14) * 6
      : 190;
  Future<void> _move(int index) async {
    if (!mounted) return;
    final box = _mapKey.currentContext?.findRenderObject();
    if (box is RenderBox && _scroll.hasClients) {
      final target = (_scroll.offset +
              box.localToGlobal(Offset(0, 126 + index * _extent)).dy -
              MediaQuery.sizeOf(context).height * .4)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      if (_animate) {
        await _scroll.animateTo(target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut);
      } else {
        _scroll.jumpTo(target);
      }
    }
    if (!mounted || _to == index.toDouble()) return;
    _from = _to;
    _to = index.toDouble();
    if (_animate) {
      await _walk.forward(from: 0).orCancel;
    } else {
      _walk.value = 1;
      setState(() {});
    }
  }

  Future<void> _open(JourneyLevel level) async {
    if (_opening || !widget.settings.journey.unlocked(level)) return;
    _opening = true;
    try {
      await _move(level.number - 1);
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => widget.settings.journey.bossReady(level)
                  ? JourneyBossScreen(
                      level: level,
                      settings: widget.settings,
                      progress: widget.progress)
                  : JourneyLevelScreen(
                      level: level,
                      settings: widget.settings,
                      progress: widget.progress)));
      if (mounted) await _move(widget.settings.journey.current.number - 1);
    } on TickerCanceled {/* Screen disposed during a walk. */} finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _walk.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge([widget.settings.journey, widget.settings]),
      builder: (context, _) {
        final journey = widget.settings.journey,
            theme = Theme.of(context),
            c = theme.colorScheme;
        final large = MediaQuery.textScalerOf(context).scale(16) > 21,
            extent = _extent;
        final allDone = journey.completedCount == journeyLevels.length;
        final seals =
            journeyLevels.where((l) => l.boss && journey.completed(l)).length;
        return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(children: [
                Expanded(
                    child: Text('Пригода з Meku',
                        style: large
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineMedium)),
                Chip(
                    avatar: const Icon(Icons.star_rounded, size: 18),
                    label: Text(
                        '${journey.totalStars}/${journeyLevels.length * 3}'))
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
                              MekuAvatar(
                                  size: large ? 40 : 68,
                                  emotion: allDone
                                      ? MekuEmotion.excited
                                      : MekuEmotion.playful),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        allDone
                                            ? 'Три печатки наші!'
                                            : large
                                                ? 'Meku поруч!'
                                                : 'Ходімо рятувати історію!',
                                        style: large
                                            ? theme.textTheme.titleMedium
                                            : theme.textTheme.titleLarge),
                                    const SizedBox(height: 6),
                                    Text(large
                                        ? 'Слова · історії · 3 боси'
                                        : 'На стежці — загублені квитки, таємні листи й міст слів. Збери три печатки у вартових світу.'),
                                  ]))
                            ]),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                            value:
                                journey.completedCount / journeyLevels.length,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8)),
                        const SizedBox(height: 8),
                        Text(
                            '${journey.completedCount}/${journeyLevels.length} рівнів · Печатки $seals/3'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                            key: const Key('journey_continue'),
                            onPressed: () => _open(journey.current),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(allDone
                                ? 'Повторити фінал'
                                : large
                                    ? 'Рівень ${journey.current.number}'
                                    : 'Рівень ${journey.current.number} · Почати')),
                      ])),
              const SizedBox(height: 16),
              Text('Розмови поруч', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final boss in journeyLevels.where((l) => l.boss))
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                              key: Key('free_chat_${boss.id}'),
                              onPressed: () => showJourneyChats(context, boss,
                                  widget.settings, widget.progress),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 8)),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ScenarioPortrait(
                                        scenario: boss.opponent!,
                                        width: 38,
                                        height: 44,
                                        cacheWidth: 110,
                                        excludeFromSemantics: true),
                                    const SizedBox(height: 4),
                                    Text(
                                        boss.id == 'j4'
                                            ? 'Vance'
                                            : boss.id == 'j8'
                                                ? 'Hannah'
                                                : 'Willow',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelMedium)
                                  ])))),
              ]),
              TextButton.icon(
                  key: const Key('open_conversations'),
                  onPressed: widget.onConversations,
                  icon: const Icon(Icons.people_outline_rounded),
                  label: const Text('Усі персонажі та ситуації')),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth,
                    cardWidth = min(230.0, width * .55);
                return CustomPaint(
                    key: _mapKey,
                    painter: _TrailPainter(extent, c.primary, c.outlineVariant,
                        journey.completedCount),
                    child: SizedBox(
                        width: width,
                        height: extent * journeyLevels.length + 80,
                        child: Stack(children: [
                          for (var world = 0; world < 3; world++)
                            Positioned(
                                top: extent * world * 4,
                                left: 0,
                                right: 0,
                                child: Center(
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: c.secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(22)),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            child: Text(
                                                [
                                                  '01 · Долина подорожей',
                                                  '02 · Місто команди',
                                                  '03 · Сад історій'
                                                ][world],
                                                style: theme
                                                    .textTheme.labelLarge))))),
                          for (final level in journeyLevels)
                            Positioned(
                                top: extent * (level.number - 1) + 92,
                                left: width * (level.number.isOdd ? .28 : .72) -
                                    cardWidth / 2,
                                width: cardWidth,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                          button: true,
                                          enabled: journey.unlocked(level),
                                          label:
                                              'Рівень ${level.number}: ${level.title}${journey.unlocked(level) ? '' : '. Зачинено'}',
                                          child: Material(
                                              color: journey.completed(level)
                                                  ? c.primaryContainer
                                                  : journey.unlocked(level)
                                                      ? c.primary
                                                      : c
                                                          .surfaceContainerHighest,
                                              elevation: journey.unlocked(level)
                                                  ? 5
                                                  : 0,
                                              shadowColor: c.primary.withValues(
                                                  alpha: .25),
                                              shape: CircleBorder(
                                                  side: BorderSide(
                                                      color: journey
                                                              .unlocked(level)
                                                          ? c.primary
                                                          : c.outlineVariant,
                                                      width: 3)),
                                              child: InkWell(
                                                  key: Key(
                                                      'journey_level_${level.id}'),
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: journey.unlocked(level)
                                                      ? () => _open(level)
                                                      : null,
                                                  child: SizedBox.square(
                                                      dimension: 68,
                                                      child: level.boss
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                      5),
                                                              child: ScenarioPortrait(
                                                                  scenario: level
                                                                      .opponent!,
                                                                  emotion: journey.completed(level)
                                                                      ? NpcEmotion
                                                                          .proud
                                                                      : NpcEmotion
                                                                          .neutral,
                                                                  width: 56,
                                                                  height: 58,
                                                                  cacheWidth:
                                                                      140,
                                                                  excludeFromSemantics:
                                                                      true))
                                                          : Icon(
                                                              journey.completed(level)
                                                                  ? Icons.check_rounded
                                                                  : journey.unlocked(level)
                                                                      ? Icons.star_rounded
                                                                      : Icons.lock_rounded,
                                                              size: 32,
                                                              color: journey.unlocked(level) && !journey.completed(level) ? c.onPrimary : c.onSurfaceVariant))))),
                                      const SizedBox(height: 8),
                                      Text('${level.number}. ${level.title}',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleSmall),
                                      const SizedBox(height: 3),
                                      if (journey.completed(level))
                                        Semantics(
                                            label:
                                                '${journey.stars(level)} зірки',
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  for (var i = 0;
                                                      i < journey.stars(level);
                                                      i++)
                                                    Icon(Icons.star_rounded,
                                                        size: 18,
                                                        color: c.primary)
                                                ]))
                                      else
                                        Text(
                                            level.boss
                                                ? journey.bossReady(level)
                                                    ? 'Здобудь печатку'
                                                    : 'Вартовий · квести + дуель'
                                                : journey.unlocked(level)
                                                    ? 'Слова · текст · міст'
                                                    : 'Пройди рівень ${level.number - 1}',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall),
                                    ])),
                          AnimatedBuilder(
                              animation: _walk,
                              builder: (_, child) {
                                final value = _from +
                                    (_to - _from) *
                                        Curves.easeInOut.transform(_walk.value);
                                final point = _trailPoint(value, width, extent);
                                final bounce = _walk.isAnimating && _animate
                                    ? sin(_walk.value * pi * 12) * 3
                                    : 0.0;
                                return Positioned(
                                    left: point.dx - 28,
                                    top: point.dy - 76 + bounce,
                                    child: IgnorePointer(
                                        child: Semantics(
                                            label:
                                                'Meku на стежці біля рівня ${value.round() + 1}',
                                            child: Transform.rotate(
                                                angle: _walk.isAnimating &&
                                                        _animate
                                                    ? sin(_walk.value *
                                                            pi *
                                                            12) *
                                                        .06
                                                    : 0,
                                                child: child))));
                              },
                              child: const MekuAvatar(
                                  key: Key('journey_walker'),
                                  size: 56,
                                  emotion: MekuEmotion.happy)),
                        ])));
              }),
              const SizedBox(height: 16),
              const Text(
                  'Квести й сюжетні дуелі працюють без інтернету. Для живої AI-розмови потрібне підключення. Прогрес зберігається на цьому пристрої.',
                  textAlign: TextAlign.center),
            ]);
      });
}

Offset _nodePoint(int i, double width, double extent) =>
    Offset(width * (i.isEven ? .28 : .72), extent * i + 126);
Offset _trailPoint(double index, double width, double extent) {
  final i = index.floor(), t = index - i, a = _nodePoint(i, width, extent);
  if (t == 0) return a;
  final b = _nodePoint(i + 1, width, extent),
      middle = (a.dy + b.dy) / 2,
      u = 1 - t;
  return a * (u * u * u) +
      Offset(a.dx, middle) * (3 * u * u * t) +
      Offset(b.dx, middle) * (3 * u * t * t) +
      b * (t * t * t);
}

class _TrailPainter extends CustomPainter {
  final double extent;
  final Color color, muted;
  final int completed;
  _TrailPainter(this.extent, this.color, this.muted, this.completed);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < journeyLevels.length - 1; i++) {
      final a = _nodePoint(i, size.width, extent),
          b = _nodePoint(i + 1, size.width, extent),
          mid = (a.dy + b.dy) / 2;
      canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy),
          paint
            ..color = i < completed
                ? color.withValues(alpha: .45)
                : muted.withValues(alpha: .65));
      if (i < completed) {
        for (var step = 1; step < 6; step++) {
          final p = _trailPoint(i + step / 6, size.width, extent);
          canvas.drawOval(
              Rect.fromCenter(
                  center: p + Offset(step.isEven ? 5 : -5, 0),
                  width: 4,
                  height: 7),
              Paint()..color = color.withValues(alpha: .7));
        }
      }
    }
    // Small plants make each region feel like a place without hiding the path.
    for (var i = 0; i < journeyLevels.length; i++) {
      final x = size.width * (i.isEven ? .84 : .16), y = i * extent + 135;
      final leaves = Paint()..color = color.withValues(alpha: .15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x - 5, y), width: 13, height: 27),
          leaves);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x + 6, y + 5), width: 13, height: 23),
          leaves);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.extent != extent ||
      old.color != color ||
      old.muted != muted ||
      old.completed != completed;
}
