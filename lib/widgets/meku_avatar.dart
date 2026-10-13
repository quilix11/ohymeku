import 'package:flutter/material.dart';
import '../models/meku_emotion.dart';

/// Standalone transparent artwork keeps the entire silhouette inside the icon.
class MekuAvatar extends StatelessWidget {
  final double size;
  final MekuEmotion emotion;
  const MekuAvatar(
      {super.key, this.size = 120, this.emotion = MekuEmotion.smug});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Meku · ${emotion.label}',
        image: true,
        child: SizedBox.square(
            dimension: size,
            child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: Image.asset(emotion.asset,
                    key: ValueKey(emotion),
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                        .ceil()
                        .clamp(64, 384)
                        .toInt(),
                    excludeFromSemantics: true))),
      );
}
