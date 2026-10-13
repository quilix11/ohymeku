import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/scenario.dart';

class ScenarioPortrait extends StatelessWidget {
  final Scenario scenario;
  final NpcEmotion emotion;
  final double width, height;
  final int cacheWidth;
  final bool excludeFromSemantics;
  final BoxFit fit;
  const ScenarioPortrait(
      {super.key,
      required this.scenario,
      this.emotion = NpcEmotion.neutral,
      required this.width,
      required this.height,
      required this.cacheWidth,
      this.excludeFromSemantics = false,
      this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final image =
        scenario.portraits[emotion.name] ?? scenario.portraits['neutral'];
    Widget fallback() => Image.asset(scenario.image(emotion),
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        fit: fit,
        semanticLabel: '${scenario.name}: ${emotionLabel(emotion)}',
        excludeFromSemantics: excludeFromSemantics);
    if (image == null) return fallback();
    return Image.memory(base64Decode(image.substring(22)),
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        fit: fit,
        gaplessPlayback: true,
        semanticLabel: '${scenario.name}: ${emotionLabel(emotion)}',
        excludeFromSemantics: excludeFromSemantics,
        errorBuilder: (_, __, ___) => fallback());
  }
}
