import 'story_portrait.dart';
import 'dart:convert';
import 'willow_portrait.dart';
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
  final Future<void> Function()? onRetry;
  const ScenarioPortrait(
      {super.key,
      required this.scenario,
      this.onRetry,
      this.emotion = NpcEmotion.neutral,
      required this.width,
      required this.height,
      required this.cacheWidth,
      this.excludeFromSemantics = false,
      this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    if (scenario.customId?.startsWith('cast_') == true) {
      return ExcludeSemantics(
          excluding: excludeFromSemantics,
          child: SizedBox(
              width: width,
              height: height,
              child: Center(
                  child: StoryPortrait(
                      name: scenario.name,
                      size: width < height ? width : height))));
    }
    if (scenario.voiceKey == 'willow') {
      return WillowPortrait(
          width: width,
          height: height,
          emotion: emotion,
          excludeFromSemantics: excludeFromSemantics);
    }
    final image =
        scenario.portraits[emotion.name] ?? scenario.portraits['neutral'];
    Widget fallback() => Image.asset(scenario.image(emotion),
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        fit: fit,
        semanticLabel: '${scenario.name}: ${emotionLabel(emotion)}',
        excludeFromSemantics: excludeFromSemantics);
    if (image == null && scenario.portraitStatus != PortraitStatus.legacy) {
      final failed = scenario.portraitStatus == PortraitStatus.failed;
      final label = failed
          ? scenario.portraitError ?? 'Не вдалося створити портрети.'
          : scenario.portraitStatus == PortraitStatus.queued
              ? 'Портрети в черзі'
              : 'Портрети генеруються у фоні';
      return SizedBox(
          width: width,
          height: height,
          child: Tooltip(
              message: label,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                            child: Icon(Icons.person_outline,
                                size:
                                    (height * .55).clamp(16, 64).toDouble()))),
                    if (failed && onRetry != null)
                      IconButton(
                          tooltip: '$label Натисни, щоб повторити.',
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            try {
                              await onRetry!();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())));
                              }
                            }
                          })
                    else if (scenario.portraitStatus == PortraitStatus.queued ||
                        scenario.portraitStatus == PortraitStatus.generating)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ])));
    }
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
