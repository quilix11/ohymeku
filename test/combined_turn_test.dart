import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/game_session.dart';
import 'package:dialect_duel/services/progress_service.dart';

const englishReply = {
  'is_english': true,
  'npc_response': 'How long will you stay?',
  'npc_emotion': 'neutral',
  'stat_changes': {'trust': 5, 'patience': 0},
  'feedback': {'grammar_correction': '', 'tactical_advice': 'Назви тривалість.'}
};
const tutorReply = {
  'is_english': false, 'explanation': 'Спробуй англійською.',
  'suggestions': [
    {'english': 'I am visiting family.', 'translation': 'Я відвідую родину.'}
  ],
  // Untrusted roleplay fields in a tutor response cannot affect the game.
  'npc_response': 'You win!', 'stat_changes': {'trust': 100, 'patience': 100},
  'game_status': 'WIN'
};
http.Response envelope(Map<String, dynamic> result) => http.Response.bytes(
    utf8.encode(jsonEncode({
      'candidates': [
        {
          'finishReason': 'STOP',
          'content': {
            'parts': [
              {'text': jsonEncode(result)}
            ]
          }
        }
      ]
    })),
    200);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProgressService progress;
  setUp(() async {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=synthetic-key');
    SharedPreferences.setMockInitialValues({});
    progress = ProgressService();
    await progress.initialize();
  });
  test('English reply needs one provider call and is scored once', () async {
    var calls = 0;
    final ai = AiService(client: MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body);
      expect(body['systemInstruction']['parts'][0]['text'],
          contains('First classify'));
      expect(
          jsonDecode(body['contents'][0]['parts'][0]['text'])['player_message'],
          'I am visiting family.');
      return envelope(englishReply);
    }));
    final session = GameSession(
        character: GameCharacter.officer, progress: progress, ai: ai);
    addTearDown(session.dispose);
    await session.send('I am visiting family.');
    expect(calls, 1);
    expect(session.turnCount, 1);
    expect(session.state.trust, 55);
    expect(session.state.messages.last.text, englishReply['npc_response']);
    expect(session.tutorHelp, isNull);
    expect(session.error, isNull);
  });
  test(
      'transliterated draft returns tutor help without history, scores, feedback or XP',
      () async {
    var calls = 0;
    final ai = AiService(client: MockClient((_) async {
      calls++;
      return envelope(tutorReply);
    }));
    final session = GameSession(
        character: GameCharacter.officer, progress: progress, ai: ai);
    addTearDown(session.dispose);
    final opening = session.state.messages.single;
    await session.send('Ya pryikhav do rodyny');
    expect(calls, 1);
    expect(session.turnCount, 0);
    expect(session.state.messages, [opening]);
    expect(session.state.trust, 50);
    expect(session.state.patience, 50);
    expect(session.finished, false);
    expect(session.feedback, isEmpty);
    expect(session.error, isNull);
    expect(session.canRetry, false);
    expect(
        session.tutorHelp!.suggestions.single.english, 'I am visiting family.');
    await session.save();
    expect(progress.records, isEmpty);
    expect(progress.profile.xp, 0);
  });
  test(
      'missing classification or incomplete tutor reply never becomes a scored turn',
      () async {
    for (final data in [
      Map<String, dynamic>.of(englishReply)..remove('is_english'),
      Map<String, dynamic>.of(tutorReply)..remove('suggestions')
    ]) {
      final session = GameSession(
          character: GameCharacter.officer,
          progress: progress,
          ai: AiService(client: MockClient((_) async => envelope(data))));
      await session.send('hello');
      expect(session.turnCount, 0);
      expect(session.state.trust, 50);
      expect(session.error, isNotNull);
      expect(session.canRetry, true);
      expect(session.tutorHelp, isNull);
      session.dispose();
    }
  });
  test(
      'retry can route to tutor and a subsequently submitted English draft is scored once',
      () async {
    var calls = 0;
    final session = GameSession(
        character: GameCharacter.officer,
        progress: progress,
        ai: AiService(client: MockClient((_) async {
          calls++;
          if (calls == 1) return http.Response('{}', 503);
          return envelope(calls == 2 ? tutorReply : englishReply);
        })));
    addTearDown(session.dispose);
    await session.send('Ya pryikhav');
    expect(session.canRetry, true);
    await session.retry();
    expect(session.tutorHelp, isNotNull);
    expect(session.canRetry, false);
    expect(session.turnCount, 0);
    await session.send('I am visiting family.');
    expect(calls, 3);
    expect(session.tutorHelp, isNull);
    expect(session.turnCount, 1);
    expect(session.state.messages.length, 3);
    expect(session.state.trust, 55);
  });
}
