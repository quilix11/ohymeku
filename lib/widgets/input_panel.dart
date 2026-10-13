// lib/widgets/input_panel.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InputPanel extends StatefulWidget {
  final bool isListening;
  final bool isLoading;
  final bool speechAvailable;
  final String liveTranscript;
  final Function(String) onSendText;
  final VoidCallback onMicTap;
  final bool isDark;

  const InputPanel({
    super.key,
    required this.isListening,
    required this.isLoading,
    required this.speechAvailable,
    required this.liveTranscript,
    required this.onSendText,
    required this.onMicTap,
    this.isDark = false,
  });

  @override
  State<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends State<InputPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(InputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.text = widget.liveTranscript;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSendText(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF111827) : Colors.white;
    final textBg =
        widget.isDark ? const Color(0xFF1F2937) : const Color(0xFFF7F7F7);
    final borderColor =
        widget.isDark ? const Color(0xFF374151) : AppColors.borderDefault;
    final hintColor = widget.isDark ? Colors.white54 : AppColors.textHint;

    final bool disabled = widget.isLoading || _controller.text.trim().isEmpty;
    final fillBtn = disabled ? const Color(0xFFE5E5E5) : AppColors.primary;
    final shadowBtn =
        disabled ? const Color(0xFFCCCCCC) : AppColors.primaryDark;
    final textBtn = disabled ? const Color(0xFFAAAAAA) : Colors.white;

    return Container(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text Area
              Container(
                decoration: BoxDecoration(
                  color: textBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _focusNode.hasFocus ? AppColors.primary : borderColor,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: widget.isDark ? Colors.white : Colors.black),
                  maxLines: 4,
                  minLines: 1,
                  enabled: !widget.isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: widget.isListening
                        ? '🎙️ Listening...'
                        : 'Your answer......',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.mic,
                          color: widget.isListening
                              ? AppColors.primary
                              : hintColor),
                      onPressed: widget.onMicTap,
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(height: 16),
              // Massive Submit Button
              GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  if (!disabled) _handleSend();
                },
                onTapCancel: () => setState(() => _pressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  margin: EdgeInsets.only(top: _pressed ? 5 : 0),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: fillBtn,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: shadowBtn, width: 2),
                    boxShadow: _pressed
                        ? []
                        : [
                            BoxShadow(
                              color: shadowBtn,
                              offset: const Offset(0, 5),
                              blurRadius: 0,
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textBtn,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
