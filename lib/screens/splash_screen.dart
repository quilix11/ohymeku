import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/meku_emotion.dart';
import '../services/tts_service.dart';
import '../widgets/meku_avatar.dart';

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
    duration: const Duration(milliseconds: 2300),
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
    final colors = theme.colorScheme;
    final retry = widget.onRetry;

    final stage = _MekuStage(dance: _dance);
    final welcome = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ohymeku', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text('Англійська з Meku', style: theme.textTheme.labelLarge),
        const SizedBox(height: 16),
        if (retry == null) ...[
          ScaleTransition(
            alignment: Alignment.topLeft,
            scale: _dance
                .drive(CurveTween(
                    curve: const Interval(.12, .38, curve: Curves.easeOutBack)))
                .drive(Tween(begin: .88, end: 1.0)),
            child: _GreetingBubble(
                greeting: _greeting, onPlay: _speaking ? null : _sayGreeting),
          ),
          const SizedBox(height: 16),
          Text('Завантажуємо пригоду…',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ] else ...[
          Semantics(
              liveRegion: true,
              child: const Text('Не вдалося завантажити Ohymeku.')),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: retry, child: const Text('Спробувати ще раз')),
        ],
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 744),
              child: LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return Row(children: [
                    Expanded(child: stage),
                    const SizedBox(width: 32),
                    Expanded(child: welcome),
                  ]);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [stage, const SizedBox(height: 22), welcome],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingBubble extends StatelessWidget {
  final String greeting;
  final VoidCallback? onPlay;
  const _GreetingBubble({required this.greeting, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primaryContainer;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -5,
          left: 22,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: ColoredBox(
                color: color, child: const SizedBox.square(dimension: 14)),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Привіт! Готовий до пригоди?'),
                ],
              ),
            ),
            IconButton(
              onPressed: onPlay,
              tooltip: 'Послухати привітання Meku',
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
  const _MekuStage({required this.dance});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 224,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .46),
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 162),
          ),
          Positioned(
            top: 18,
            left: 20,
            child: Icon(Icons.auto_awesome_rounded,
                size: 21, color: colors.primary.withValues(alpha: .72)),
          ),
          Positioned(
            bottom: 22,
            right: 22,
            child: Icon(Icons.music_note_rounded,
                size: 22, color: colors.primary.withValues(alpha: .52)),
          ),
          AnimatedBuilder(
            animation: dance,
            builder: (context, child) {
              final beat = (dance.value * 3).clamp(0.0, 3.0);
              final hop = math.sin(beat * math.pi).abs() * (1 - dance.value);
              final sway = math.sin(beat * math.pi) * (1 - dance.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 76),
                    child: Transform.scale(
                      scaleX: 1 - hop * .25,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const SizedBox(width: 78, height: 11),
                      ),
                    ),
                  ),
                  Transform.translate(
                    key: const ValueKey('meku_dance_pose'),
                    offset: Offset(sway * 23, -hop * 27),
                    child: Transform.rotate(
                      angle: sway * .26,
                      child: MekuAvatar(
                        size: 186,
                        emotion: dance.value < .68
                            ? MekuEmotion.playful
                            : MekuEmotion.happy,
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
}
