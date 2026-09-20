// lib/widgets/npc_avatar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class NpcAvatar extends StatelessWidget {
  final GameCharacter character;
  final NpcEmotion emotion;
  final bool large;

  const NpcAvatar({
    super.key,
    required this.character,
    required this.emotion,
    this.large = false,
  });

  String get _imagePath {
    final prefix = character == GameCharacter.officer ? 'officer' : 'hr';
    switch (emotion) {
      case NpcEmotion.neutral:    return 'assets/images/${prefix}_neutral.jpg';
      case NpcEmotion.happy:      return 'assets/images/${prefix}_satisfied.jpg';
      case NpcEmotion.angry:      return 'assets/images/${prefix}_angry.jpg';
      case NpcEmotion.surprised:  return 'assets/images/${prefix}_suspicious.jpg';
      case NpcEmotion.laughing:   return 'assets/images/${prefix}_satisfied.jpg';
      case NpcEmotion.worried:    return 'assets/images/${prefix}_suspicious.jpg';
      case NpcEmotion.proud:      return 'assets/images/${prefix}_satisfied.jpg';
      case NpcEmotion.shocked:    return 'assets/images/${prefix}_angry.jpg';
      case NpcEmotion.sad:        return 'assets/images/${prefix}_neutral.jpg';
    }
  }

  Color get _color {
    switch (emotion) {
      case NpcEmotion.neutral:    return AppColors.emotionNeutral;
      case NpcEmotion.happy:      return AppColors.emotionSatisfied;
      case NpcEmotion.angry:      return AppColors.emotionAngry;
      case NpcEmotion.surprised:  return AppColors.emotionSuspicious;
      case NpcEmotion.laughing:   return AppColors.emotionSatisfied;
      case NpcEmotion.worried:    return AppColors.emotionSuspicious;
      case NpcEmotion.proud:      return AppColors.emotionSatisfied;
      case NpcEmotion.shocked:    return AppColors.emotionAngry;
      case NpcEmotion.sad:        return AppColors.emotionNeutral;
    }
  }

  String get _label {
    switch (emotion) {
      case NpcEmotion.neutral:    return 'Neutral';
      case NpcEmotion.happy:      return 'Happy';
      case NpcEmotion.angry:      return 'Angry';
      case NpcEmotion.surprised:  return 'Surprised';
      case NpcEmotion.laughing:   return 'Laughing';
      case NpcEmotion.worried:    return 'Worried';
      case NpcEmotion.proud:      return 'Proud';
      case NpcEmotion.shocked:    return 'Shocked';
      case NpcEmotion.sad:        return 'Sad';
    }
  }
  
  String get _name {
    return character == GameCharacter.officer ? 'Officer Vance' : 'HR Manager';
  }
  
  String get _emoji {
    return character == GameCharacter.officer ? '👮' : '👔';
  }

  @override
  Widget build(BuildContext context) {
    if (large) {
      return _LargeAvatar(
        imagePath: _imagePath,
        color: _color,
        label: _label,
        name: _name,
        emoji: _emoji,
        emotion: emotion,
      );
    }
    return _SmallAvatar(imagePath: _imagePath, color: _color, emoji: _emoji);
  }
}

// ── Large version (Ace Attorney style — bottom of screen) ───────────────────
class _LargeAvatar extends StatelessWidget {
  final String imagePath;
  final Color color;
  final String label;
  final String name;
  final String emoji;
  final NpcEmotion emotion;

  const _LargeAvatar({
    required this.imagePath,
    required this.color,
    required this.label,
    required this.name,
    required this.emoji,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Character image with bounce
        SizedBox(
          width: 90,
          height: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: color.withValues(alpha: 0.1),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 52)),
                ),
              ),
            ),
          ),
        )
            // Shake on angry/shocked
            .animate(key: ValueKey('${emotion}_shake'))
            .shake(
              duration: (emotion == NpcEmotion.angry || emotion == NpcEmotion.shocked) ? 500.ms : 0.ms,
              hz: 5,
            )
            // Bounce always
            .then()
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),

        const SizedBox(height: 6),

        // Name
        Text(
          name,
          style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
        ),

        const SizedBox(height: 3),

        // Emotion badge pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ).animate(key: ValueKey(emotion)).fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
            ),
      ],
    );
  }
}

// ── Small version (for compact HUD fallback) ─────────────────────────────────
class _SmallAvatar extends StatelessWidget {
  final String imagePath;
  final Color color;
  final String emoji;

  const _SmallAvatar({required this.imagePath, required this.color, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
        ),
      ),
    );
  }
}

// ── Full-screen background character (Ace Attorney style) ────────────────────
class NpcFullBackground extends StatelessWidget {
  final GameCharacter character;
  final NpcEmotion emotion;
  final bool isDark;

  const NpcFullBackground({
    super.key,
    required this.character,
    required this.emotion,
    this.isDark = false,
  });

  String get _imagePath {
    final prefix = character == GameCharacter.officer ? 'officer' : 'hr';
    switch (emotion) {
      case NpcEmotion.neutral:    return 'assets/images/${prefix}_neutral.jpg';
      case NpcEmotion.happy:      return 'assets/images/${prefix}_satisfied.jpg';
      case NpcEmotion.angry:      return 'assets/images/${prefix}_angry.jpg';
      case NpcEmotion.surprised:  return 'assets/images/${prefix}_suspicious.jpg';
      case NpcEmotion.laughing:   return 'assets/images/${prefix}_satisfied.jpg';
      case NpcEmotion.worried:    return 'assets/images/${prefix}_suspicious.jpg';
      case NpcEmotion.proud:      return 'assets/images/${prefix}_satisfied.jpg';
      case NpcEmotion.shocked:    return 'assets/images/${prefix}_angry.jpg';
      case NpcEmotion.sad:        return 'assets/images/${prefix}_neutral.jpg';
    }
  }

  Color get _color {
    switch (emotion) {
      case NpcEmotion.neutral:    return AppColors.emotionNeutral;
      case NpcEmotion.happy:      return AppColors.emotionSatisfied;
      case NpcEmotion.angry:      return AppColors.emotionAngry;
      case NpcEmotion.surprised:  return AppColors.emotionSuspicious;
      case NpcEmotion.laughing:   return AppColors.emotionSatisfied;
      case NpcEmotion.worried:    return AppColors.emotionSuspicious;
      case NpcEmotion.proud:      return AppColors.emotionSatisfied;
      case NpcEmotion.shocked:    return AppColors.emotionAngry;
      case NpcEmotion.sad:        return AppColors.emotionNeutral;
    }
  }

  String get _emoji {
    return character == GameCharacter.officer ? '👮' : '👔';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: size.height * 0.52,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Subtle color glow at bottom behind character
              Positioned(
                bottom: 0,
                left: size.width * 0.1,
                right: size.width * 0.1,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.18),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Character image
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Image.asset(
                  _imagePath,
                  key: ValueKey(_imagePath),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(_emoji, style: const TextStyle(fontSize: 120)),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -10,
                    duration: 2200.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
