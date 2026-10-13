import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/gemini_transport.dart';

class WaitingClient extends http.BaseClient {
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abortable = request as http.AbortableRequest;
    await abortable.abortTrigger;
    aborted = true;
    throw http.ClientException('aborted');
  }
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: ''));
  test('retired configured model falls back to Lite and remembers it',
      () async {
    dotenv.testLoad(fileInput: 'GEMINI_MODEL=gemini-2.5-flash');
    final models = <String>[];
    final client = MockClient((request) async {
      expect(request.headers['x-goog-api-key'], 'synthetic-key');
      expect(request.url.queryParameters, isEmpty);
      models.add(request.url.path.split('/').last);
      final body = jsonDecode(request.body), config = body['generationConfig'];
      expect(body['systemInstruction'], isNotNull);
      expect(config['responseFormat']['text']['mimeType'], 'APPLICATION_JSON');
      expect(config['responseFormat']['text']['schema']['type'], 'object');
      return http.Response('{}', models.length == 1 ? 404 : 200);
    });
    addTearDown(client.close);
    final transport = GeminiTransport(client);
    final payload = {
      'system_instruction': {
        'parts': [
          {'text': 'fixture'}
        ]
      },
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {'type': 'OBJECT'}
      }
    };
    await transport.post(payload, 'synthetic-key');
    await transport.post(payload, 'synthetic-key');
    expect(models, [
      'gemini-2.5-flash:generateContent',
      'gemini-flash-lite-latest:generateContent',
      'gemini-flash-lite-latest:generateContent'
    ]);
  });
  test(
      'quota, outage and authentication errors expose cause without retry or secret',
      () async {
    for (final code in [400, 429, 503, 403, 401]) {
      var calls = 0;
      final client = MockClient((r) async {
        calls++;
        return http.Response(
            jsonEncode({
              'error': {
                'status': 'PROVIDER_STATUS',
                'message': 'details synthetic-key'
              }
            }),
            code);
      });
      await expectLater(
          GeminiTransport(client).post({}, 'synthetic-key'),
          throwsA(isA<AiException>()
              .having((e) => e.message, 'HTTP', contains('HTTP $code'))
              .having((e) => e.message, 'cause', contains('PROVIDER_STATUS'))
              .having((e) => e.message, 'secret',
                  isNot(contains('synthetic-key')))));
      expect(calls, 1);
      client.close();
    }
  });
  test('default uses fast Lite with minimal thinking', () async {
    final client = MockClient((request) async {
      expect(
          request.url.path, contains('gemini-3.5-flash-lite:generateContent'));
      expect(jsonDecode(request.body)['generationConfig']['thinkingConfig'],
          {'thinkingLevel': 'MINIMAL'});
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    await GeminiTransport(client).post({}, 'synthetic-key');
  });
  test('deadline aborts the underlying request', () async {
    final client = WaitingClient();
    await expectLater(
        GeminiTransport(client, timeout: const Duration(milliseconds: 10))
            .post({}, 'synthetic-key'),
        throwsA(isA<AiException>()
            .having((e) => e.message, 'timeout', contains('скасовано'))));
    await Future<void>.delayed(Duration.zero);
    expect(client.aborted, true);
  });
}
