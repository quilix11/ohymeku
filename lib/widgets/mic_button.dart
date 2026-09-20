// lib/widgets/mic_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final bool disabled;

  const MicButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  bool _pressed = false;

  Color get _fill {
    if (widget.disabled) return const Color(0xFFD0D0D0);
    if (widget.isListening) return const Color(0xFFFF4B4B);
    return AppColors.micFill;
  }

  Color get _shadow {
    if (widget.disabled) return const Color(0xFFAAAAAA);
    if (widget.isListening) return AppColors.loseRedDark;
    return AppColors.micShadow;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.disabled) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72,
        height: 72,
        margin: EdgeInsets.only(top: _pressed ? 4 : 0),
        decoration: BoxDecoration(
          color: _fill,
          shape: BoxShape.circle,
          border: Border.all(color: _shadow, width: 2.5),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: _shadow,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}
