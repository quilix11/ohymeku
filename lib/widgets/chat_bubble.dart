import 'package:flutter/material.dart';
import '../models/game_state.dart';

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
    return Align(
        alignment:
            message.isPlayer ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            margin: EdgeInsets.fromLTRB(
                message.isPlayer ? 32 : 0, 6, message.isPlayer ? 0 : 20, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: message.isPlayer
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(message.isPlayer ? 12 : 4),
                    bottomRight: Radius.circular(message.isPlayer ? 4 : 12)),
                border: Border.all(
                    color: message.isPlayer
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                    child: Text(message.isPlayer ? 'ТИ' : 'СПІВРОЗМОВНИК',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: message.isPlayer
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1))),
                if (!message.isPlayer && onSpeak != null)
                  IconButton(
                      tooltip: 'Прослухати репліку',
                      onPressed: onSpeak,
                      icon: const Icon(Icons.volume_up_outlined, size: 20)),
              ]),
              const SizedBox(height: 4),
              WordClickableText(
                  text: message.text,
                  onWordTap: onWordTap,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: message.isPlayer
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface)),
            ])));
  }
}
