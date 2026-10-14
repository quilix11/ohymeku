import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

import 'word_clickable_text.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isNew, isDark;
  final VoidCallback? onSpeak;
  final ValueChanged<String>? onWordTap;
  const ChatBubble(
      {super.key,
      required this.message,
      this.isNew = false,
      this.isDark = false,
      this.onSpeak,
      this.onWordTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final ink = message.isPlayer ? c.onPrimaryContainer : c.onSurface;
    final surface = message.isPlayer
        ? c.primaryContainer.withValues(alpha: .58)
        : AppVisuals.panelColor(context);
    return Align(
        alignment:
            message.isPlayer ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            margin: EdgeInsets.fromLTRB(
                message.isPlayer ? 32 : 0, 6, message.isPlayer ? 0 : 20, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(message.isPlayer ? 20 : 7),
                    bottomRight: Radius.circular(message.isPlayer ? 7 : 20)),
                border: Border.all(
                    color: message.isPlayer
                        ? c.primary.withValues(alpha: .14)
                        : AppVisuals.panelBorder(context),
                    width: .65)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                    child: Text(message.isPlayer ? 'ТИ' : 'СПІВРОЗМОВНИК',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: message.isPlayer
                                ? c.onPrimaryContainer
                                : c.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .6))),
                if (!message.isPlayer && onSpeak != null)
                  IconButton(
                      tooltip: 'Прослухати репліку',
                      onPressed: onSpeak,
                      icon: const Icon(CupertinoIcons.speaker_2, size: 20)),
              ]),
              const SizedBox(height: 4),
              WordClickableText(
                  text: message.text,
                  onWordTap: onWordTap,
                  style: theme.textTheme.bodyLarge?.copyWith(color: ink)),
            ])));
  }
}
