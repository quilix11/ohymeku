// lib/models/game_state.dart

enum GameCharacter { officer, hr }

enum NpcEmotion { neutral, happy, angry, surprised, laughing, worried, proud, shocked, sad }

enum GameStatus { inProgress, win, lose }

class ChatMessage {
  final String text;
  final bool isPlayer;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isPlayer,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'role': isPlayer ? 'user' : 'assistant',
        'content': text,
      };
}

class Feedback {
  final String grammarCorrection;
  final String tacticalAdvice;

  const Feedback({
    required this.grammarCorrection,
    required this.tacticalAdvice,
  });

  factory Feedback.empty() =>
      const Feedback(grammarCorrection: '', tacticalAdvice: '');

  factory Feedback.fromJson(Map<String, dynamic> json) => Feedback(
        grammarCorrection: json['grammar_correction'] as String? ?? '',
        tacticalAdvice: json['tactical_advice'] as String? ?? '',
      );
}

class NpcResponse {
  final String npcResponse;
  final NpcEmotion npcEmotion;
  final int trustDelta;
  final int patienceDelta;
  final int currentTrust;
  final int currentPatience;
  final GameStatus gameStatus;
  final Feedback feedback;

  const NpcResponse({
    required this.npcResponse,
    required this.npcEmotion,
    required this.trustDelta,
    required this.patienceDelta,
    required this.currentTrust,
    required this.currentPatience,
    required this.gameStatus,
    required this.feedback,
  });

  factory NpcResponse.fromJson(Map<String, dynamic> json) {
    final statChanges =
        json['stat_changes'] as Map<String, dynamic>? ?? {};
    final currentStats =
        json['current_stats'] as Map<String, dynamic>? ?? {};
    final feedbackJson =
        json['feedback'] as Map<String, dynamic>? ?? {};

    NpcEmotion emotion;
    switch (json['npc_emotion'] as String? ?? 'neutral') {
      case 'happy':
        emotion = NpcEmotion.happy;
        break;
      case 'angry':
        emotion = NpcEmotion.angry;
        break;
      case 'surprised':
        emotion = NpcEmotion.surprised;
        break;
      case 'laughing':
        emotion = NpcEmotion.laughing;
        break;
      case 'worried':
        emotion = NpcEmotion.worried;
        break;
      case 'proud':
        emotion = NpcEmotion.proud;
        break;
      case 'shocked':
        emotion = NpcEmotion.shocked;
        break;
      case 'sad':
        emotion = NpcEmotion.sad;
        break;
      default:
        emotion = NpcEmotion.neutral;
    }

    GameStatus status;
    switch (json['game_status'] as String? ?? 'IN_PROGRESS') {
      case 'WIN':
        status = GameStatus.win;
        break;
      case 'LOSE':
        status = GameStatus.lose;
        break;
      default:
        status = GameStatus.inProgress;
    }

    return NpcResponse(
      npcResponse: json['npc_response'] as String? ?? '',
      npcEmotion: emotion,
      trustDelta: (statChanges['trust'] as num?)?.toInt() ?? 0,
      patienceDelta: (statChanges['patience'] as num?)?.toInt() ?? 0,
      currentTrust: (currentStats['trust'] as num?)?.toInt() ?? 50,
      currentPatience:
          (currentStats['patience'] as num?)?.toInt() ?? 50,
      gameStatus: status,
      feedback: Feedback.fromJson(feedbackJson),
    );
  }
}

class GameState {
  final GameCharacter character;
  final int trust;
  final int patience;
  final int lives;
  final NpcEmotion npcEmotion;
  final List<ChatMessage> messages;
  final Feedback? lastFeedback;
  final GameStatus status;
  final bool isLoading;
  final int xp;

  const GameState({
    this.character = GameCharacter.officer,
    this.trust = 50,
    this.patience = 50,
    this.lives = 3,
    this.npcEmotion = NpcEmotion.neutral,
    this.messages = const [],
    this.lastFeedback,
    this.status = GameStatus.inProgress,
    this.isLoading = false,
    this.xp = 0,
  });

  GameState copyWith({
    GameCharacter? character,
    int? trust,
    int? patience,
    int? lives,
    NpcEmotion? npcEmotion,
    List<ChatMessage>? messages,
    Feedback? lastFeedback,
    GameStatus? status,
    bool? isLoading,
    int? xp,
  }) =>
      GameState(
        character: character ?? this.character,
        trust: trust ?? this.trust,
        patience: patience ?? this.patience,
        lives: lives ?? this.lives,
        npcEmotion: npcEmotion ?? this.npcEmotion,
        messages: messages ?? this.messages,
        lastFeedback: lastFeedback ?? this.lastFeedback,
        status: status ?? this.status,
        isLoading: isLoading ?? this.isLoading,
        xp: xp ?? this.xp,
      );

  GameState reset() => GameState(
        character: character,
        lives: lives > 0 ? lives - 1 : 0,
        xp: xp,
      );
}
