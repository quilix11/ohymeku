import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/models/practice_record.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/game_session.dart';
import 'package:dialect_duel/services/progress_service.dart';

class ControlledAi extends AiService {
  bool fail = false;
  int calls = 0;
  final List<int> historyLengths = [];
  @override
  Future<NpcResponse> sendMessage(
      {required GameCharacter character,
      required List<ChatMessage> chatHistory,
      required int currentTrust,
      required int currentPatience,
      List<String>? interests,
      required String playerMessage}) async {
    calls++;
    historyLengths.add(chatHistory.length);
    if (fail) throw const AiException('offline');
    return NpcResponse(
        npcResponse: 'Thank you.',
        npcEmotion: NpcEmotion.proud,
        trustDelta: 15,
        patienceDelta: 0,
        currentTrust: 100,
        currentPatience: 100,
        gameStatus: GameStatus.win,
        feedback: Feedback.empty());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProgressService progress;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    progress = ProgressService();
    await progress.initialize();
  });

  test(
      'local rules reject fabricated WIN; terminal award is once; HR survives restart',
      () async {
    final ai = ControlledAi();
    final session =
        GameSession(character: GameCharacter.hr, progress: progress, ai: ai);
    await session.send('I managed a team.');
    expect(session.state.trust, 65);
    expect(session.finished, false);
    expect(progress.profile.xp, 0);
    await session.send('We delivered the project.');
    expect(session.state.trust, 80);
    expect(session.finished, true);
    expect(progress.profile.xp, 160);
    await session.send('Another answer');
    await session.save();
    expect(ai.calls, 2);
    expect(progress.records, hasLength(1));
    expect(progress.profile.xp, 160);
    await session.restart();
    expect(session.character, GameCharacter.hr);
    expect(session.state.character, GameCharacter.hr);
    expect(session.state.messages.single.text, contains('Hannah'));
    session.dispose();
  });

  test('retry replaces failed turn without duplicated history or progress',
      () async {
    final ai = ControlledAi()..fail = true;
    final session = GameSession(
        character: GameCharacter.officer, progress: progress, ai: ai);
    await session.send('I am visiting family.');
    expect(session.canRetry, true);
    expect(session.state.messages, hasLength(2));
    ai.fail = false;
    await session.retry();
    expect(session.state.messages, hasLength(3));
    expect(ai.historyLengths, [1, 1]);
    expect(session.turnCount, 1);
    expect(session.error, isNull);
    session.dispose();
  });

  test(
      'profile, records and awards survive reload; streak counts calendar days',
      () async {
    await progress.saveProfile('Андрій', 2);
    PracticeRecord record(String id, DateTime date) => PracticeRecord(
        id: id,
        date: date,
        character: GameCharacter.hr,
        status: GameStatus.win,
        trust: 80,
        patience: 50,
        xp: 160,
        messages: [ChatMessage(text: 'Hello', isPlayer: true, timestamp: date)],
        feedback: []);
    await progress.recordSession(record('a', DateTime(2026, 3, 28)));
    await progress.recordSession(record('b', DateTime(2026, 3, 29)));
    expect(progress.streakAt(DateTime(2026, 3, 29)), 2);
    expect(progress.streakAt(DateTime(2026, 3, 31)), 0);
    final restored = ProgressService();
    await restored.initialize();
    expect(restored.name, 'Андрій');
    expect(restored.avatar, 2);
    expect(restored.records, hasLength(2));
    expect(restored.profile.xp, 320);
    await restored.recordSession(record('b', DateTime(2026, 3, 29)));
    expect(restored.profile.xp, 320);
  });
}
