import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/learning_service.dart';

const character = {
  'name': 'Alex',
  'role': 'Бариста',
  'goal': 'Замов каву та уточни ціну.',
  'opening': 'Hi! What would you like today?',
  'description': 'Грайливий, уважний і терплячий.',
};

http.Response reply(Object envelope) =>
    http.Response.bytes(utf8.encode(jsonEncode(envelope)), 200,
        headers: {'content-type': 'application/json'});
Map<String, dynamic> envelope(String text, {String? finish = 'STOP'}) => {
      'candidates': [
        {
          if (finish != null) 'finishReason': finish,
          'content': {
            'parts': [
              {'text': text}
            ]
          }
        }
      ]
    };

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'GEMINI_API_KEY=test-only-key'));

  test('scenario uses required schema and preserves Ukrainian UTF-8', () async {
    final service = LearningService(client: MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      final config = body['generationConfig'] as Map;
      expect(config['maxOutputTokens'], 8192);
      expect(config['responseFormat']['text']['mimeType'], 'APPLICATION_JSON');
      expect((config['responseFormat']['text']['schema'] as Map)['required'],
          character.keys.toList());
      final text = jsonEncode(character);
      return reply({
        'candidates': [
          {
            'finishReason': 'STOP',
            'content': {
              'parts': [
                {'text': 'hidden reasoning', 'thought': true},
                {'text': text.substring(0, 30)},
                {'text': text.substring(30)}
              ]
            }
          }
        ]
      });
    }));
    addTearDown(service.dispose);
    expect(await service.generate('Кав’ярня', 'A2', 8, true), character);
  });

  test('complete fenced JSON without finish metadata is accepted', () async {
    var calls = 0;
    final service = LearningService(client: MockClient((_) async {
      calls++;
      return reply(
          envelope('```json\n${jsonEncode(character)}\n```', finish: null));
    }));
    addTearDown(service.dispose);
    expect(await service.generate('Кав’ярня', 'A2', 8, true), character);
    expect(calls, 1);
  });

  test('truncation retries once with more room and never accepts partial data',
      () async {
    final budgets = <int>[];
    final service = LearningService(client: MockClient((request) async {
      budgets
          .add(jsonDecode(request.body)['generationConfig']['maxOutputTokens']);
      return reply(budgets.length == 1
          ? envelope('{"name":"Alex', finish: 'MAX_TOKENS')
          : envelope(jsonEncode(character)));
    }));
    addTearDown(service.dispose);
    expect(await service.generate('Кав’ярня', 'A2', 8, true), character);
    expect(budgets, [8192, 16384]);
  });

  for (final broken in [
    envelope('{broken'),
    {'candidates': []}
  ]) {
    test('malformed or empty output stops after two attempts: $broken',
        () async {
      var calls = 0;
      final service = LearningService(client: MockClient((_) async {
        calls++;
        return reply(broken);
      }));
      addTearDown(service.dispose);
      await expectLater(
          service.generate('Кав’ярня', 'A2', 8, true),
          throwsA(isA<AiException>()
              .having((e) => e.message, 'message', contains('двічі'))));
      expect(calls, 2);
    });
  }

  test('quota is reported after one fallback to the lite model', () async {
    var calls = 0;
    final service = LearningService(client: MockClient((_) async {
      calls++;
      return http.Response('{}', 429);
    }));
    addTearDown(service.dispose);
    await expectLater(
        service.generate('Кав’ярня', 'A2', 8, true),
        throwsA(isA<AiException>()
            .having((e) => e.message, 'message', contains('Ліміт'))));
    expect(calls, 2);
  });

  test('blocked response is not retried as an incomplete one', () async {
    var calls = 0;
    final service = LearningService(client: MockClient((_) async {
      calls++;
      return reply({
        'promptFeedback': {'blockReason': 'SAFETY'}
      });
    }));
    addTearDown(service.dispose);
    await expectLater(
        service.generate('Кав’ярня', 'A2', 8, true),
        throwsA(isA<AiException>()
            .having((e) => e.message, 'message', contains('переформулювати'))));
    expect(calls, 1);
  });

  test('missing scenario fields cannot reach preview or saving', () async {
    final service = LearningService(
        client: MockClient((_) async => reply(envelope('{"name":"Alex"}'))));
    addTearDown(service.dispose);
    await expectLater(service.generate('Кав’ярня', 'A2', 8, true),
        throwsA(isA<AiException>()));
  });

  test('vocabulary schema requests exact count; duplicate words are rejected',
      () async {
    final service = LearningService(client: MockClient((request) async {
      final config = jsonDecode(request.body)['generationConfig'];
      final cards =
          config['responseFormat']['text']['schema']['properties']['cards'];
      expect(cards['minItems'], 5);
      expect(cards['maxItems'], 5);
      return reply(envelope(jsonEncode({
        'cards': List.generate(
            5,
            (_) => {
                  'word': 'coffee',
                  'translation': 'кава',
                  'example': 'A coffee, please.',
                  'transcription': '/ˈkɒfi/'
                })
      })));
    }));
    addTearDown(service.dispose);
    await expectLater(
        service.generate('Кав’ярня', 'A2', 5, false),
        throwsA(isA<AiException>()
            .having((e) => e.message, 'message', contains('повтори'))));
  });
}
