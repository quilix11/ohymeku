import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/practice_record.dart';
import '../models/scenario.dart';
import '../models/language_help.dart';
import 'ai_service.dart';
import 'progress_service.dart';
import 'learner_service.dart';

class GameSession extends ChangeNotifier {
  final GameCharacter character;
  final ProgressService progress;
  final AiService ai;
  final LearnerService? learner;
  final Scenario scenario;
  late GameState state;
  late String _id;
  bool _disposed = false, _saved = false;
  String? error, saveError;
  LanguageHelp? tutorHelp;
  bool saving = false;
  PracticeRecord? _savedRecord;
  PracticeRecord? get savedRecord => _savedRecord;
  String? _failedMessage;
  List<ChatMessage> _confirmed = [];
  final List<Feedback> feedback = [];

  final List<String> interests;

  GameSession(
      {required this.character,
      required this.progress,
      this.interests = const [],
      this.learner,
      String? learningLevel,
      AiService? ai,
      Scenario? scenario})
      : scenario = scenario ?? Scenario.of(character),
        ai = ai ?? AiService(scenario: scenario) {
    this.ai.learningLevel = learningLevel;
    _reset();
  }
  bool get finished => state.status != GameStatus.inProgress;
  bool get canRetry => _failedMessage != null && !state.isLoading;
  int get turnCount => _confirmed.where((m) => m.isPlayer).length;
  int get uniqueWords => _confirmed
      .where((m) => m.isPlayer)
      .expand((m) => RegExp(r"[a-z]+(?:'[a-z]+)?")
          .allMatches(m.text.toLowerCase())
          .map((w) => w.group(0)!))
      .toSet()
      .length;
  int get earnedXp => state.status == GameStatus.win
      ? 100 +
          (state.trust - 50).clamp(0, 50) * 2 +
          (state.patience - 50).clamp(0, 50)
      : 0;

  void _reset() {
    _id = DateTime.now().microsecondsSinceEpoch.toString();
    _confirmed = [
      ChatMessage(
          text: scenario.customId == null && ai.learningLevel == 'A1'
              ? (character == GameCharacter.officer
                  ? 'Hello! May I see your passport? Why are you here?'
                  : 'Hi, I am Hannah. What do you do?')
              : scenario.opening,
          isPlayer: false,
          timestamp: DateTime.now())
    ];
    state = GameState(
        character: character, messages: List.unmodifiable(_confirmed));
    error = null;
    tutorHelp = null;
    saveError = null;
    _failedMessage = null;
    _saved = false;
    _savedRecord = null;
    feedback.clear();
  }

  Future<void> restart() async {
    if (state.isLoading || saving) return;
    await save();
    if (_disposed || saveError != null) return;
    _reset();
    notifyListeners();
  }

  Future<void> send(String input) async {
    final text = input.trim();
    if (_disposed || text.isEmpty || state.isLoading || finished) return;
    tutorHelp = null;
    if (text.length > 2000) {
      error = 'Скороти відповідь до 2000 символів.';
      notifyListeners();
      return;
    }
    error = null;
    _failedMessage = null;
    final player =
        ChatMessage(text: text, isPlayer: true, timestamp: DateTime.now());
    state = state.copyWith(messages: [..._confirmed, player], isLoading: true);
    notifyListeners();
    try {
      final result = await (ai..playerName = progress.dialogueName).sendMessage(
          character: character,
          chatHistory: List.unmodifiable(_confirmed),
          currentTrust: state.trust,
          currentPatience: state.patience,
          playerMessage: text,
          interests: interests);
      if (_disposed) return;
      final trust =
          (state.trust + result.trustDelta.clamp(-25, 15)).clamp(0, 100);
      final patience =
          (state.patience + result.patienceDelta.clamp(-25, 15)).clamp(0, 100);
      final status = trust <= 0 || patience <= 0
          ? GameStatus.lose
          : trust >= 80 || patience >= 80
              ? GameStatus.win
              : GameStatus.inProgress;
      _confirmed = [
        ..._confirmed,
        player,
        ChatMessage(
            text: result.npcResponse,
            isPlayer: false,
            timestamp: DateTime.now())
      ];
      feedback.add(result.feedback);
      state = state.copyWith(
          messages: List.unmodifiable(_confirmed),
          trust: trust,
          patience: patience,
          npcEmotion: result.npcEmotion,
          lastFeedback: result.feedback,
          status: status,
          isLoading: false);
      if (result.feedback.exercise != null && learner != null) {
        try {
          await learner!.capture(result.feedback.exercise!);
        } catch (_) {
          saveError = 'Не вдалося зберегти вправу з цієї розмови.';
        }
      }
      if (_disposed) return;
      notifyListeners();
      if (finished) await save();
    } on TutorRequired catch (result) {
      if (_disposed) return;
      tutorHelp = result.help;
      // Discard the unscored draft; confirmed history, meters and XP stay intact.
      state = state.copyWith(
          messages: List.unmodifiable(_confirmed), isLoading: false);
      notifyListeners();
    } catch (exception) {
      if (_disposed) return;
      _failedMessage = text;
      error = exception is AiException
          ? exception.message
          : 'Не вдалося отримати відповідь. Спробуй ще раз.';
      state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> retry() async {
    final text = _failedMessage;
    if (text != null) await send(text);
  }

  Future<void> save() async {
    if (_saved || turnCount == 0 || saving) return;
    saving = true;
    saveError = null;
    if (!_disposed) notifyListeners();
    try {
      final record = PracticeRecord(
          scenarioId: scenario.customId,
          scenarioName: scenario.name,
          id: _id,
          date: DateTime.now(),
          character: character,
          status: state.status,
          trust: state.trust,
          patience: state.patience,
          xp: earnedXp,
          messages: List.unmodifiable(_confirmed),
          feedback: List.unmodifiable(feedback));
      await progress.recordSession(record);
      _savedRecord = record;
      _saved = true;
    } catch (_) {
      saveError = 'Не вдалося зберегти розмову. Повтори збереження.';
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ai.dispose();
    super.dispose();
  }
}
