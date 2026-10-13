import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/services/ai_service.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'GEMINI_API_KEY=synthetic-key'));
  for (final entry in [
    (
      {
        'promptFeedback': {'blockReason': 'SAFETY'}
      },
      'SAFETY'
    ),
    (
      {
        'candidates': [
          {'finishReason': 'MAX_TOKENS'}
        ]
      },
      'MAX_TOKENS'
    ),
  ]) {
    test('conversation displays provider stop reason ${entry.$2}', () async {
      final service = AiService(
          client: MockClient(
              (_) async => http.Response(jsonEncode(entry.$1), 200)));
      addTearDown(service.dispose);
      await expectLater(
          service.sendMessage(
              character: GameCharacter.hr,
              chatHistory: [],
              currentTrust: 50,
              currentPatience: 50,
              playerMessage: 'Hi'),
          throwsA(isA<AiException>()
              .having((e) => e.message, 'cause', contains(entry.$2))));
    });
  }
}
