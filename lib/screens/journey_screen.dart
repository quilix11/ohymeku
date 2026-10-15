import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show listEquals;
import '../models/journey_level.dart';
import '../models/meku_emotion.dart';
import '../models/game_state.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/scenario_portrait.dart';
import '../widgets/ohymeku_design.dart';
import '../theme/app_theme.dart';
import 'journey_level_screen.dart';
import 'chronicles_screen.dart';
import 'journey_boss_screen.dart';

class JourneyScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  const JourneyScreen(
      {super.key, required this.settings, required this.progress});
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
    _walk.addListener(_followWalk);
    _from = widget.settings.journey.current.number - 1.0;
    _to = _from;
  }

  bool _opening = false;
  bool get _animate =>
      widget.settings.animationsEnabled &&
      !MediaQuery.disableAnimationsOf(context);
  List<double> _centers = [];
  List<double> _worldTops = [];
  double _mapHeight = 0;
  double? _cameraOffset(double position) {
    final box = _mapKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        !box.attached ||
        !_scroll.hasClients ||
        _centers.isEmpty) {
      return null;
    }
    return (_scroll.offset +
            box
                .localToGlobal(_trailPoint(position, box.size.width, _centers))
                .dy -
            MediaQuery.sizeOf(context).height * .42)
        .clamp(0.0, _scroll.position.maxScrollExtent);
  }

  void _followWalk() {
    if (!mounted || !_walk.isAnimating || !_animate) return;
    final position =
        _from + (_to - _from) * Curves.easeInOutCubic.transform(_walk.value);
    final target = _cameraOffset(position);
    if (target != null && (_scroll.offset - target).abs() > .5) {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _move(int index) async {
    if (!mounted || _to == index.toDouble()) return;
    final start = _cameraOffset(_animate ? _to : index.toDouble());
    if (start != null) {
      if (_animate) {
        await _scroll.animateTo(start,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(start);
      }
    }
    if (!mounted) return;
    _from = _to;
    _to = index.toDouble();
    if (_animate) {
      _walk.duration = Duration(
          milliseconds: (1200 * (_to - _from).abs()).round().clamp(1200, 3600));
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

  String _caption(JourneyLevel level) {
    final journey = widget.settings.journey;
    return level.boss
        ? journey.bossReady(level)
            ? 'Здобудь печатку'
            : 'Вартовий · квести + дуель'
        : journey.unlocked(level)
            ? 'Слова · текст · міст'
            : 'Пройди рівень ${level.number - 1}';
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
        final large = MediaQuery.textScalerOf(context).scale(16) > 21;
        final allDone = journey.completedCount == journeyLevels.length;
        final seals =
            journeyLevels.where((l) => l.boss && journey.completed(l)).length;
        return SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('Пригода з Meku',
                            style: large
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.headlineMedium)),
                    Chip(
                        avatar: const Icon(CupertinoIcons.star, size: 18),
                        label: Text(
                            '${journey.totalStars}/${journeyLevels.length * 3}'))
                  ]),
                  const SizedBox(height: 12),
                  SilkPanel(
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
                            onPressed: allDone
                                ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) => ChroniclesScreen(
                                            settings: widget.settings,
                                            progress: widget.progress)))
                                : () => _open(journey.current),
                            icon: const Icon(CupertinoIcons.play),
                            label: Text(allDone
                                ? 'Продовжити історію'
                                : large
                                    ? 'Рівень ${journey.current.number}'
                                    : 'Рівень ${journey.current.number} · Почати')),
                      ])),
                  const SizedBox(height: 16),
                  LearningTile(
                    title: 'Хроніки листів',
                    subtitle:
                        'Сюжетна пригода · докази, рішення й нові розділи',
                    icon: CupertinoIcons.envelope_open,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => ChroniclesScreen(
                                settings: widget.settings,
                                progress: widget.progress))),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth,
                        cardWidth = min(230.0, width * .55);
                    final scaler = MediaQuery.textScalerOf(context);
                    double measure(
                        String text, TextStyle? style, double maxWidth) {
                      final painter = TextPainter(
                          text: TextSpan(text: text, style: style),
                          textDirection: Directionality.of(context),
                          textScaler: scaler)
                        ..layout(maxWidth: maxWidth);
                      final height = painter.height.ceilToDouble();
                      painter.dispose();
                      return height;
                    }

                    final centers = <double>[], worldTops = <double>[];
                    const worlds = [
                      '01 · Долина подорожей',
                      '02 · Місто команди',
                      '03 · Сад історій'
                    ];
                    var cursor = 0.0;
                    for (final level in journeyLevels) {
                      if ((level.number - 1) % 4 == 0) {
                        worldTops.add(cursor);
                        cursor += measure(worlds[(level.number - 1) ~/ 4],
                                theme.textTheme.labelLarge, width - 28) +
                            16 +
                            62;
                      }
                      final center = cursor + 34;
                      centers.add(center);
                      final titleHeight = measure(
                          '${level.number}. ${level.title}',
                          theme.textTheme.titleSmall,
                          cardWidth);
                      final captionHeight = journey.completed(level)
                          ? 18.0
                          : measure(_caption(level), theme.textTheme.bodySmall,
                              cardWidth);
                      final bottom =
                          center + 34 + 8 + titleHeight + 6 + captionHeight;
                      cursor = max(bottom + 42, center + 160);
                    }
                    _centers = centers;
                    _worldTops = worldTops;
                    _mapHeight = cursor + 24;
                    return CustomPaint(
                        key: _mapKey,
                        painter: _TrailPainter(centers, c.primary,
                            c.outlineVariant, journey.completedCount),
                        child: SizedBox(
                            width: width,
                            height: _mapHeight,
                            child: Stack(children: [
                              for (var world = 0; world < 3; world++)
                                Positioned(
                                    top: _worldTops[world],
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                        child: DecoratedBox(
                                            decoration: AppVisuals.panelDecoration(
                                                context,
                                                radius:
                                                    AppVisuals.radiusControl),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                child: Text(
                                                    [
                                                      '01 · Долина подорожей',
                                                      '02 · Місто команди',
                                                      '03 · Сад історій'
                                                    ][world],
                                                    key: Key(
                                                        'journey_world_$world'),
                                                    textAlign: TextAlign.center,
                                                    style: theme.textTheme
                                                        .labelLarge))))),
                              for (final level in journeyLevels)
                                Positioned(
                                    top: centers[level.number - 1] - 34,
                                    left: width *
                                            (level.number.isOdd ? .28 : .72) -
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
                                                  color: journey
                                                          .completed(level)
                                                      ? c.primary.withValues(
                                                          alpha: .10)
                                                      : journey.unlocked(level)
                                                          ? c.primary.withValues(
                                                              alpha: .06)
                                                          : AppVisuals.panelColor(
                                                              context),
                                                  surfaceTintColor:
                                                      Colors.transparent,
                                                  elevation: 0,
                                                  shape: CircleBorder(
                                                      side: BorderSide(
                                                          color: journey.unlocked(level)
                                                              ? c.primary.withValues(
                                                                  alpha: .38)
                                                              : AppVisuals.panelBorder(
                                                                  context),
                                                          width: 1)),
                                                  child: InkWell(
                                                      key: Key(
                                                          'journey_level_${level.id}'),
                                                      customBorder:
                                                          const CircleBorder(),
                                                      onTap: journey
                                                              .unlocked(level)
                                                          ? () => _open(level)
                                                          : null,
                                                      child: SizedBox.square(
                                                          dimension: 68,
                                                          child: level.boss
                                                              ? Padding(padding: const EdgeInsets.all(5), child: ScenarioPortrait(scenario: level.opponent!, emotion: journey.completed(level) ? NpcEmotion.proud : NpcEmotion.neutral, width: 56, height: 58, cacheWidth: 140, excludeFromSemantics: true))
                                                              : Icon(
                                                                  journey.completed(level)
                                                                      ? CupertinoIcons.check_mark
                                                                      : journey.unlocked(level)
                                                                          ? CupertinoIcons.star
                                                                          : CupertinoIcons.lock,
                                                                  size: 28,
                                                                  color: journey.unlocked(level) ? c.primary : c.onSurfaceVariant))))),
                                          const SizedBox(height: 8),
                                          Text(
                                              '${level.number}. ${level.title}',
                                              key: Key(
                                                  'journey_title_${level.id}'),
                                              textAlign: TextAlign.center,
                                              style:
                                                  theme.textTheme.titleSmall),
                                          const SizedBox(height: 6),
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
                                                        Icon(
                                                            CupertinoIcons.star,
                                                            size: 18,
                                                            color: c.primary)
                                                    ]))
                                          else
                                            Text(_caption(level),
                                                key: Key(
                                                    'journey_description_${level.id}'),
                                                textAlign: TextAlign.center,
                                                style:
                                                    theme.textTheme.bodySmall),
                                        ])),
                              AnimatedBuilder(
                                  animation: _walk,
                                  builder: (_, child) {
                                    final value = _from +
                                        (_to - _from) *
                                            Curves.easeInOutCubic
                                                .transform(_walk.value);
                                    final point =
                                        _trailPoint(value, width, centers);
                                    final walking =
                                        _walk.isAnimating && _animate;
                                    final stride = _walk.value *
                                        pi *
                                        12 *
                                        max(1, (_to - _from).abs());
                                    final hop =
                                        walking ? -sin(stride).abs() * 6 : 0.0;
                                    final direction = (_trailPoint(
                                                    min(
                                                        journeyLevels.length -
                                                            1.0,
                                                        value + .01),
                                                    width,
                                                    centers)
                                                .dx -
                                            point.dx) *
                                        (_to >= _from ? 1 : -1);
                                    final landing = walking && _walk.value > .82
                                        ? sin((_walk.value - .82) / .18 * pi)
                                        : 0.0;
                                    return Positioned(
                                        left: point.dx - 40,
                                        top: point.dy - 88,
                                        child: IgnorePointer(
                                            child: Semantics(
                                                label:
                                                    'Meku на стежці біля рівня ${value.round() + 1}',
                                                child: SizedBox(
                                                    width: 80,
                                                    height: 88,
                                                    child: Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          Positioned(
                                                              left: 19,
                                                              top: 70,
                                                              child: Transform.scale(
                                                                  scaleX: walking
                                                                      ? 1 -
                                                                          sin(stride).abs() *
                                                                              .18
                                                                      : 1,
                                                                  child: Container(
                                                                      width: 42,
                                                                      height: 8,
                                                                      decoration: BoxDecoration(
                                                                          color: c
                                                                              .primary
                                                                              .withValues(alpha: .18),
                                                                          borderRadius: BorderRadius.circular(20))))),
                                                          if (walking)
                                                            Positioned.fill(
                                                                child: CustomPaint(
                                                                    painter: _WalkAccents(
                                                                        c.primary,
                                                                        landing,
                                                                        stride))),
                                                          Positioned(
                                                              left: 12,
                                                              top: 12 + hop,
                                                              child: Transform.rotate(
                                                                  angle: walking
                                                                      ? sin(stride) *
                                                                          .08
                                                                      : 0,
                                                                  child: Transform.flip(
                                                                      flipX: walking &&
                                                                          direction <
                                                                              0,
                                                                      child:
                                                                          child))),
                                                        ])))));
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
                ]));
      });
}

Offset _nodePoint(int i, double width, List<double> centers) =>
    Offset(width * (i.isEven ? .28 : .72), centers[i]);
Offset _trailPoint(double index, double width, List<double> centers) {
  final i = index.floor(), t = index - i, a = _nodePoint(i, width, centers);
  if (t == 0) return a;
  final b = _nodePoint(i + 1, width, centers),
      middle = (a.dy + b.dy) / 2,
      u = 1 - t;
  return a * (u * u * u) +
      Offset(a.dx, middle) * (3 * u * u * t) +
      Offset(b.dx, middle) * (3 * u * t * t) +
      b * (t * t * t);
}

class _TrailPainter extends CustomPainter {
  final List<double> centers;
  final Color color, muted;
  final int completed;
  _TrailPainter(this.centers, this.color, this.muted, this.completed);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < journeyLevels.length - 1; i++) {
      final a = _nodePoint(i, size.width, centers),
          b = _nodePoint(i + 1, size.width, centers),
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
          final p = _trailPoint(i + step / 6, size.width, centers);
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
      final x = size.width * (i.isEven ? .84 : .16), y = centers[i] + 12;
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
      !listEquals(old.centers, centers) ||
      old.color != color ||
      old.muted != muted ||
      old.completed != completed;
}

class _WalkAccents extends CustomPainter {
  final Color color;
  final double landing, stride;
  _WalkAccents(this.color, this.landing, this.stride);
  @override
  void paint(Canvas canvas, Size size) {
    final dust = Paint()..color = color.withValues(alpha: .18);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(20 + i * 18, 77 + sin(stride + i) * 2),
          2 + (sin(stride + i) + 1), dust);
    }
    if (landing > 0) {
      for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4, radius = 26 + landing * 15;
        canvas.drawCircle(
            Offset(40 + cos(angle) * radius, 40 + sin(angle) * radius),
            2 * landing,
            Paint()..color = color.withValues(alpha: landing * .65));
      }
    }
  }

  @override
  bool shouldRepaint(_WalkAccents old) =>
      old.landing != landing || old.stride != stride || old.color != color;
}
