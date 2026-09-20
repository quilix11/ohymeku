// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isNew;
  final bool isDark;

  const ChatBubble({
    super.key,
    required this.message,
    this.isNew = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isPlayer) {
      // Player bubble: simple, right-aligned
      return Padding(
        padding: const EdgeInsets.only(left: 64, right: 16, top: 8, bottom: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bubblePlayer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bubblePlayerBorder, width: 2),
            ),
            child: Text(message.text, style: AppTextStyles.bodyLarge),
          ),
        ).animate(target: isNew ? 1 : 0).fadeIn().slideX(begin: 0.1),
      );
    }

    // NPC Bubble: Matches the white card from the image
    final bgColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0xFFE5E5E5),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top quotes + volume icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('“', style: TextStyle(fontSize: 32, color: Color(0xFFCCCCCC), height: 0.5, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  message.text,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 18,
                    height: 1.4,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.bottomRight,
                child: Text('”', style: TextStyle(fontSize: 32, color: Color(0xFFCCCCCC), height: 0.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ).animate(target: isNew ? 1 : 0).fadeIn().slideY(begin: 0.1),
    );
  }
}
