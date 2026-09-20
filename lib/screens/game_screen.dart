// lib/screens/game_screen.dart
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_hud.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/coaching_box.dart';
import '../widgets/input_panel.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  final GameCharacter character;
  const GameScreen({
    super.key,
    required this.settings,
    required this.progress,
    this.character = GameCharacter.officer,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AiService _aiService = AiService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final ScrollController _scrollController = ScrollController();

  late GameState _state;
  bool _isListening = false;
  String _liveTranscript = '';
  bool _speechAvailable = false;
  String? _errorMessage;
  int _newMessageIndex = -1;

  SettingsService get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    _state = GameState(character: widget.character);
    _initialize();
  }

  Future<void> _initialize() async {
    await _ttsService.initialize();
    _speechAvailable = await _speechService.initialize();
    await _loadOpeningLine();
  }

  Future<void> _loadOpeningLine() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      final npcResp = await _aiService.getOpeningLine(_state.character);
      final npcMsg = ChatMessage(
        text: npcResp.npcResponse,
        isPlayer: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _state = _state.copyWith(
          messages: [npcMsg],
          npcEmotion: npcResp.npcEmotion,
          isLoading: false,
        );
        _newMessageIndex = 0;
      });
      await _ttsService.speak(npcResp.npcResponse);
    } catch (e) {
      if (mounted) setState(() {
        _state = _state.copyWith(isLoading: false);
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handlePlayerMessage(String text) async {
    if (text.trim().isEmpty || _state.isLoading) return;
    final playerMsg = ChatMessage(
      text: text.trim(),
      isPlayer: true,
      timestamp: DateTime.now(),
    );
    final updatedMessages = [..._state.messages, playerMsg];
    setState(() {
      _state = _state.copyWith(messages: updatedMessages, isLoading: true);
      _newMessageIndex = updatedMessages.length - 1;
      _liveTranscript = '';
      _errorMessage = null;
    });
    _scrollToBottom();
    try {
      final npcResp = await _aiService.sendMessage(
        character: _state.character,
        chatHistory: _state.messages,
        currentTrust: _state.trust,
        currentPatience: _state.patience,
        playerMessage: text.trim(),
      );
      final npcMsg = ChatMessage(
        text: npcResp.npcResponse,
        isPlayer: false,
        timestamp: DateTime.now(),
      );
      final newMessages = [...updatedMessages, npcMsg];
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          messages: newMessages,
          trust: npcResp.currentTrust.clamp(0, 100),
          patience: npcResp.currentPatience.clamp(0, 100),
          npcEmotion: npcResp.npcEmotion,
          lastFeedback: npcResp.feedback,
          status: npcResp.gameStatus,
          isLoading: false,
        );
        _newMessageIndex = newMessages.length - 1;
      });
      await _ttsService.speak(npcResp.npcResponse);
      _scrollToBottom();
      if (npcResp.gameStatus == GameStatus.win) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _showWinDialog();
      } else if (npcResp.gameStatus == GameStatus.lose) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _showLoseDialog(npcResp.feedback);
      }
    } catch (e) {
      if (mounted) setState(() {
        _state = _state.copyWith(isLoading: false);
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _toggleMic() async {
    if (_isListening) {
      await _speechService.stopListening(
        onStatusChange: (v) => setState(() => _isListening = v),
      );
      if (_liveTranscript.isNotEmpty) _handlePlayerMessage(_liveTranscript);
    } else {
      await _speechService.startListening(
        onResult: (text) => setState(() => _liveTranscript = text),
        onStatusChange: (v) => setState(() => _isListening = v),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showWinDialog() {
    _ttsService.stop();
    final xp = 100 +
        (_state.trust - 50).clamp(0, 50) * 2 +
        (_state.patience - 50).clamp(0, 50);
        
    widget.progress.addXp(xp);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EndDialog(
        isWin: true,
        xpEarned: xp,
        trust: _state.trust,
        patience: _state.patience,
        onRestart: () { Navigator.pop(context); _restart(); },
      ),
    );
  }

  void _showLoseDialog(Feedback feedback) {
    _ttsService.stop();
    widget.progress.deductHeart();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EndDialog(
        isWin: false,
        xpEarned: 0,
        trust: _state.trust,
        patience: _state.patience,
        feedback: feedback,
        livesLeft: widget.progress.profile.hearts,
        onRestart: () { Navigator.pop(context); _restart(loseLife: true); },
      ),
    );
  }

  void _restart({bool loseLife = false}) {
    setState(() {
      _liveTranscript = '';
      _errorMessage = null;
      _state = loseLife ? _state.reset() : const GameState();
    });
    _loadOpeningLine();
  }

  @override
  void dispose() {
    _speechService.dispose();
    _ttsService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            SettingsScreen(settings: _settings),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), // extra padding for overlap
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(), // Will go back to MainScreen! Ah wait, requires MainScreen check
                  ),
                  Text(
                    'Lesson - 01', // Matching styling from photo exactly
                    style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: _openSettings,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Simplified HUD embedded inside the green header
              GameHud(state: _state, isDark: false),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
    );

    return Scaffold(
      backgroundColor: widget.settings.isDark ? const Color(0xFF111827) : const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Content Stack (Header overlapping Chat bubbles)
          Expanded(
            child: Stack(
              children: [
                _buildTopHeader(),
                // Chat List positioned to overlap the header by 30px
                Positioned(
                  top: 150, // Enough to overlap the bottom curves
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 0, bottom: 20),
                    itemCount: _state.messages.length + (_state.lastFeedback != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_state.lastFeedback != null && index == _state.messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: CoachingBox(feedback: _state.lastFeedback!),
                        );
                      }
                      return ChatBubble(
                        message: _state.messages[index],
                        isNew: index == _newMessageIndex,
                        isDark: widget.settings.isDark,
                      );
                    },
                  ),
                ),
                // Loading indicator
                if (_state.isLoading)
                  Positioned(
                    top: 180,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                        child: const CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.loseRed,
              width: double.infinity,
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
            ),

          InputPanel(
            isListening: _isListening,
            isLoading: _state.isLoading,
            speechAvailable: _speechAvailable,
            liveTranscript: _liveTranscript,
            onSendText: _handlePlayerMessage,
            onMicTap: _toggleMic,
            isDark: widget.settings.isDark,
          ),
        ],
      ),
    );
  }
}

class _EndDialog extends StatelessWidget {
  final bool isWin;
  final int xpEarned;
  final int trust;
  final int patience;
  final Feedback? feedback;
  final int livesLeft;
  final VoidCallback onRestart;

  const _EndDialog({
    required this.isWin,
    required this.xpEarned,
    required this.trust,
    required this.patience,
    this.feedback,
    this.livesLeft = 3,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = isWin ? AppColors.winGold : AppColors.loseRed;
    final mainShadow = isWin ? AppColors.winGoldDark : AppColors.loseRedDark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: mainColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: mainShadow,
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              ),
              child: Column(
                children: [
                  Text(
                    isWin ? '🎉' : '😞',
                    style: const TextStyle(fontSize: 56),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    isWin ? 'ENTRY APPROVED! 🛂' : 'ACCESS DENIED',
                    style: AppTextStyles.titleLarge.copyWith(color: mainColor, fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isWin
                        ? 'You convinced them!'
                        : 'You failed to convince them.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatChip(label: 'Trust', value: '$trust', color: AppColors.trustFill),
                      _StatChip(label: 'Patience', value: '$patience', color: AppColors.patienceFill),
                      if (isWin) _StatChip(label: 'XP', value: '+$xpEarned', color: AppColors.winGold),
                    ],
                  ),
                  if (!isWin && feedback != null) ...[  
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.coachingBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.coachingBorder, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (feedback!.grammarCorrection.isNotEmpty)
                            Text(feedback!.grammarCorrection, style: AppTextStyles.coachingStyle),
                          if (feedback!.tacticalAdvice.isNotEmpty)
                            Text(feedback!.tacticalAdvice, style: AppTextStyles.coachingStyle),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _BigDuoButton(
                    label: isWin ? 'Play Again' : 'Try Again',
                    fillColor: mainColor,
                    shadowColor: mainShadow,
                    onTap: onRestart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 400.ms),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: color.withValues(alpha: 0.8), fontSize: 11)),
        ],
      ),
    );
  }
}

class _BigDuoButton extends StatefulWidget {
  final String label;
  final Color fillColor;
  final Color shadowColor;
  final VoidCallback onTap;
  const _BigDuoButton({
    required this.label,
    required this.fillColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_BigDuoButton> createState() => _BigDuoButtonState();
}

class _BigDuoButtonState extends State<_BigDuoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        margin: EdgeInsets.only(top: _pressed ? 5 : 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.shadowColor, width: 2),
          boxShadow: _pressed
              ? []
              : [BoxShadow(color: widget.shadowColor, offset: const Offset(0, 5), blurRadius: 0)],
        ),
        child: Center(
          child: Text(
            widget.label.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0),
          ),
        ),
      ),
    );
  }
}
