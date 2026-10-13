import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dialect_duel/services/api_credentials.dart';
import 'package:dialect_duel/services/gemini_transport.dart';

void main() {
  test('shared gateway receives no API key; personal key uses Google directly',
      () async {
    dotenv.testLoad(fileInput: '');
    ApiCredentials.clear();
    addTearDown(ApiCredentials.clear);
    expect(ApiCredentials.available, true);
    expect(ApiCredentials.useGateway, true);
    final urls = <Uri>[];
    final client = MockClient((r) async {
      urls.add(r.url);
      if (urls.length == 1) {
        expect(r.url.toString(), 'https://gateway.example/api/text');
        expect(r.headers.containsKey('x-goog-api-key'), false);
        final body = jsonDecode(r.body);
        expect(body['payload']['contents'], isNotNull);
        expect(body['model'], 'gemini-2.5-flash-lite');
      } else {
        expect(r.url.host, 'generativelanguage.googleapis.com');
        expect(r.headers['x-goog-api-key'], 'synthetic-personal-key');
      }
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    final transport = GeminiTransport(client);
    await transport.post({'contents': []}, ApiCredentials.geminiKey);
    ApiCredentials.setGeminiKey('synthetic-personal-key');
    expect(ApiCredentials.useGateway, false);
    await transport.post({'contents': []}, ApiCredentials.geminiKey);
    expect(urls.length, 2);
  },
      skip: const String.fromEnvironment('GEMINI_GATEWAY_URL') !=
              'https://gateway.example'
          ? 'Run with --dart-define=GEMINI_GATEWAY_URL=https://gateway.example'
          : false);
}
