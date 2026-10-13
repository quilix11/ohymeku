import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/services/gemini_transport.dart';

void main() {
  test('retired configured model falls back and remembers the working alias',
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
      expect(
          config['responseFormat']['text']['schema']['properties']['name']
              ['type'],
          'string');
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
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'}
          }
        }
      }
    };
    await transport.post(payload, 'synthetic-key');
    await transport.post(payload, 'synthetic-key');
    expect(models, [
      'gemini-2.5-flash:generateContent',
      'gemini-flash-latest:generateContent',
      'gemini-flash-latest:generateContent'
    ]);
  });
  test('rate limits switch models once; authentication errors never retry',
      () async {
    dotenv.testLoad(fileInput: '');
    for (final code in [429, 503, 403, 401]) {
      final paths = <String>[];
      final client = MockClient((r) async {
        paths.add(r.url.path);
        return http.Response('{}', code);
      });
      final response = await GeminiTransport(client).post({}, 'synthetic-key');
      expect(response.statusCode, code);
      expect(paths.length, [429, 503].contains(code) ? 2 : 1);
      expect(paths.first, contains('gemini-flash-lite-latest'));
      if (paths.length == 2) {
        expect(paths.last, contains('gemini-flash-latest'));
      }
      client.close();
    }
  });
  test('default uses Flash-Lite without adding thinking and remembers fallback',
      () async {
    dotenv.testLoad(fileInput: '');
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      final config = jsonDecode(request.body)['generationConfig'] as Map;
      if (paths.length == 1) {
        expect(config.containsKey('thinkingConfig'), isFalse);
        return http.Response('{}', 503);
      }
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    final transport = GeminiTransport(client);
    await transport.post({}, 'synthetic-key');
    await transport.post({}, 'synthetic-key');
    expect(paths.first, contains('gemini-flash-lite-latest'));
    expect(paths.sublist(1), everyElement(contains('gemini-flash-latest')));
  });
}
