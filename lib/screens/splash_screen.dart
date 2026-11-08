import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/meku_emotion.dart';
import '../services/tts_service.dart';
import '../widgets/meku_avatar.dart';

const _night = Color(0xFF160F29);
const _paper = Color(0xFFFFF3E1);
const _gold = Color(0xFFFFCB88);
const _mist = Color(0xFFE5D8F4);

class SplashScreen extends StatefulWidget {
  final bool animationsEnabled;
  final VoidCallback onIntroFinished;
  final ValueChanged<bool> onSpeakingChanged;
  final VoidCallback? onRetry;

  const SplashScreen({
    super.key,
    required this.animationsEnabled,
    required this.onIntroFinished,
    required this.onSpeakingChanged,
    this.onRetry,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _greeting = 'Hi! Ready for an adventure?';
  late final _dance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2550),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _finishIntro();
    });
  bool _finished = false, _speaking = false;
  TtsService? _voice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (_finished) return;
    if (!widget.animationsEnabled || MediaQuery.disableAnimationsOf(context)) {
      _dance.stop();
      _dance.value = 1;
    } else if (!_dance.isAnimating) {
      _dance.forward();
    }
  }

  void _finishIntro() {
    if (_finished) return;
    _finished = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onIntroFinished();
    });
  }

  Future<void> _sayGreeting() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    widget.onSpeakingChanged(true);
    final voice = _voice ??= TtsService();
    try {
      await voice
          .speak(_greeting, offline: true)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // A missing voice must not hold up startup or prevent reading the greeting.
      voice.dispose();
      _voice = null;
    } finally {
      if (mounted) {
        setState(() => _speaking = false);
        widget.onSpeakingChanged(false);
      }
    }
  }

  @override
  void dispose() {
    _dance.dispose();
    _voice?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = widget.onRetry;
    final wide = MediaQuery.sizeOf(context).width >= 680;
    return Scaffold(
      backgroundColor: _night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            wide
                ? 'assets/images/meku_splash_pass.webp'
                : 'assets/images/meku_splash_pass_portrait.webp',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99160F29),
                  Color(0x16160F29),
                  Color(0xE6160F29)
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _Fireflies(_dance)),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxHeight < 600;
              final alignment =
                  wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
              final brand = Column(
                crossAxisAlignment: alignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('АНГЛІЙСЬКА ПРИГОДА',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: _gold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4)),
                  const SizedBox(height: 4),
                  Text('Ohymeku',
                      style: theme.textTheme.headlineLarge?.copyWith(
                          color: _paper,
                          fontFamily: 'Lora',
                          fontSize: wide ? 54 : 42,
                          fontWeight: FontWeight.w700)),
                ],
              );
              final stage =
                  _MekuStage(dance: _dance, size: compact ? 180 : 246);
              final greeting = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (retry == null) ...[
                    ScaleTransition(
                      alignment:
                          wide ? Alignment.centerLeft : Alignment.topCenter,
                      scale: _dance
                          .drive(CurveTween(
                              curve: const Interval(.22, .48,
                                  curve: Curves.easeOutBack)))
                          .drive(Tween(begin: .85, end: 1.0)),
                      child: _GreetingBubble(
                        greeting: _greeting,
                        onPlay: _speaking ? null : _sayGreeting,
                        wide: wide,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Завантажуємо пригоду…',
                        textAlign: wide ? TextAlign.start : TextAlign.center,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: _mist)),
                  ] else ...[
                    Semantics(
                      liveRegion: true,
                      child: const Text('Не вдалося завантажити Ohymeku.',
                          style: TextStyle(color: _paper)),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: retry,
                        child: const Text('Спробувати ще раз')),
                  ],
                ],
              );
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 824),
                    child: wide
                        ? Row(children: [
                            Expanded(child: stage),
                            const SizedBox(width: 32),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                brand,
                                const SizedBox(height: 28),
                                greeting
                              ],
                            )),
                          ])
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              brand,
                              const SizedBox(height: 12),
                              stage,
                              const SizedBox(height: 18),
                              greeting
                            ],
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GreetingBubble extends StatelessWidget {
  final String greeting;
  final VoidCallback? onPlay;
  final bool wide;
  const _GreetingBubble(
      {required this.greeting, required this.onPlay, required this.wide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xF2261B3C);
    return Stack(
      clipBehavior: Clip.none,
      alignment: wide ? Alignment.centerLeft : Alignment.topCenter,
      children: [
        FractionalTranslation(
          translation: wide ? const Offset(-.46, 0) : const Offset(0, -.46),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: const ColoredBox(
                color: color, child: SizedBox.square(dimension: 14)),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 9, 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: .26)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MEKU',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: _gold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8)),
                  const SizedBox(height: 5),
                  Text(greeting,
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: _paper, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  const Text('Привіт! Готовий до пригоди?',
                      style: TextStyle(color: _mist)),
                ],
              ),
            ),
            IconButton(
              onPressed: onPlay,
              tooltip: 'Послухати привітання Meku',
              color: _gold,
              disabledColor: _gold.withValues(alpha: .45),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ]),
        ),
      ],
    );
  }
}

class _MekuStage extends StatelessWidget {
  final Animation<double> dance;
  final double size;
  const _MekuStage({required this.dance, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x6DFFB372), Color(0x00FFB372)],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: dance,
              builder: (context, child) {
                final time = dance.value;
                final beat = math.sin(time * math.pi * 7);
                final energy = 1 - Curves.easeInCubic.transform(time);
                final hop = beat.abs() * energy;
                final sway = math.sin(time * math.pi * 4) * energy;
                final landing = math.pow(1 - beat.abs(), 6) *
                    energy *
                    (time * 12).clamp(0.0, 1.0);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, size * .40),
                      child: Transform.scale(
                        scaleX: 1 + landing * .45 - hop * .25,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _night.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color:
                                  _gold.withValues(alpha: .16 + landing * .35),
                            ),
                          ),
                          child: SizedBox(width: size * .44, height: 13),
                        ),
                      ),
                    ),
                    Transform.translate(
                      key: const ValueKey('meku_dance_pose'),
                      offset: Offset(sway * 28, -hop * 30),
                      child: Transform.rotate(
                        angle: sway * .20,
                        child: Transform.scale(
                          scaleX: 1 + landing * .09,
                          scaleY: 1 - landing * .09,
                          alignment: Alignment.bottomCenter,
                          child: MekuAvatar(
                            size: size * .94,
                            emotion: time < .66
                                ? MekuEmotion.playful
                                : MekuEmotion.happy,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _Fireflies extends CustomPainter {
  final Animation<double> dance;
  _Fireflies(this.dance) : super(repaint: dance);

  @override
  void paint(Canvas canvas, Size size) {
    final time = dance.value;
    final glow = Paint();
    final core = Paint();
    for (var i = 0; i < 18; i++) {
      final phase = i * 2.39996 + time * 3.7;
      final x = ((i * 37 % 97) + 2) / 100 * size.width;
      final y = ((i * 29 % 79) + 10) / 100 * size.height;
      final point =
          Offset(x + math.sin(phase) * 14, y - time * (18 + i % 3 * 7));
      final intensity = (.5 + math.sin(phase) * .5);
      final radius = 1 + i % 3 * .42;
      glow.color = _gold.withValues(alpha: .04 + intensity * .11);
      core.color = _gold.withValues(alpha: .26 + intensity * .55);
      canvas.drawCircle(point, radius * 3.1, glow);
      canvas.drawCircle(point, radius, core);
    }
  }

  @override
  bool shouldRepaint(covariant _Fireflies oldDelegate) =>
      oldDelegate.dance != dance;
}
