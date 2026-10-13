import 'game_state.dart';

class PracticeRecord {
  final String? scenarioId, scenarioName;
  final String id;
  final DateTime date;
  final GameCharacter character;
  final GameStatus status;
  final int trust, patience, xp;
  final List<ChatMessage> messages;
  final List<Feedback> feedback;
  const PracticeRecord(
      {this.scenarioId,
      this.scenarioName,
      required this.id,
      required this.date,
      required this.character,
      required this.status,
      required this.trust,
      required this.patience,
      required this.xp,
      required this.messages,
      required this.feedback});
  int get turns => messages.where((m) => m.isPlayer).length;
  bool get won => status == GameStatus.win;
  String get resultLabel => won
      ? 'Перемога'
      : status == GameStatus.lose
          ? 'Спроба'
          : 'Практика';

  Map<String, dynamic> toJson() => {
        'id': id,
        'scenario_id': scenarioId,
        'scenario_name': scenarioName,
        'date': date.toIso8601String(),
        'character': character.name,
        'status': status.name,
        'trust': trust,
        'patience': patience,
        'xp': xp,
        'messages': messages
            .map((m) => {
                  'text': m.text,
                  'player': m.isPlayer,
                  'time': m.timestamp.toIso8601String()
                })
            .toList(),
        'feedback': feedback
            .map((f) => {
                  'grammar_correction': f.grammarCorrection,
                  'tactical_advice': f.tacticalAdvice,
                  if (f.exercise != null) 'exercise': f.exercise!.toJson()
                })
            .toList(),
      };
  factory PracticeRecord.fromJson(Map<String, dynamic> json) => PracticeRecord(
        scenarioId: json['scenario_id'] as String?,
        scenarioName: json['scenario_name'] as String?,
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        character: GameCharacter.values.byName(json['character'] as String),
        status: GameStatus.values.byName(json['status'] as String),
        trust: json['trust'] as int,
        patience: json['patience'] as int,
        xp: json['xp'] as int,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage(
                text: m['text'] as String,
                isPlayer: m['player'] as bool,
                timestamp: DateTime.parse(m['time'] as String)))
            .toList(),
        feedback: (json['feedback'] as List)
            .map((f) => Feedback.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
      );
}
