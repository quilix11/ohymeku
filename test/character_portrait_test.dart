import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/models/scenario.dart';
import 'package:dialect_duel/services/api_credentials.dart';
import 'package:dialect_duel/services/character_portrait_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'portrait_fixtures.dart';

Future<Uint8List> sprite({bool background = true}) async {
  final recorder = ui.PictureRecorder(), canvas = ui.Canvas(recorder);
  canvas.drawColor(
      background ? const ui.Color(0xFF00FF00) : const ui.Color(0xFFEEEEEE),
      ui.BlendMode.src);
  for (var i = 0; i < 9; i++) {
    canvas.drawRect(
        ui.Rect.fromLTWH(
            (i % 3 * 32 + 8).toDouble(), (i ~/ 3 * 32 + 8).toDouble(), 16, 16),
        ui.Paint()..color = ui.Color.fromARGB(255, 60 + i * 15, 35, 70));
  }
  final picture = recorder.endRecording(),
      image = await picture.toImage(96, 96);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    dotenv.testLoad(fileInput: '');
    ApiCredentials.clear();
  });
  tearDown(ApiCredentials.clear);

  test(
      'Gemini receives style references and produces nine transparent PNG emotions',
      () async {
    ApiCredentials.setGeminiKey('synthetic-session-key');
    final sheet = await sprite();
    final client = MockClient((request) async {
      try {
        expect(request.url.path, '/v1beta/interactions');
        expect(request.headers['x-goog-api-key'], 'synthetic-session-key');
        expect(request.url.queryParameters, isEmpty);
        final body = jsonDecode(request.body);
        expect(body['model'], 'gemini-3.1-flash-lite-image');
        expect(body['store'], false);
        expect(body['input'].where((x) => x['type'] == 'image').length, 2,
            reason: body['input'].map((x) => x['type']).toList().toString());
        expect(request.body, isNot(contains('synthetic-session-key')));
        return http.Response(
            jsonEncode({
              'status': 'completed',
              'steps': [
                {
                  'type': 'model_output',
                  'content': [
                    {
                      'type': 'image',
                      'mime_type': 'image/png',
                      'data': base64Encode(sheet)
                    }
                  ]
                }
              ]
            }),
            200);
      } catch (error, stack) {
        Error.throwWithStackTrace(StateError(error.toString()), stack);
      }
    });
    addTearDown(client.close);
    final images = await CharacterPortraitService(client)
        .generate({'name': 'Alex', 'role': 'Barista'});
    expect(images.keys.toSet(), NpcEmotion.values.map((e) => e.name).toSet());
    const order = [
      'neutral',
      'happy',
      'angry',
      'surprised',
      'laughing',
      'worried',
      'proud',
      'shocked',
      'sad'
    ];
    for (var i = 0; i < order.length; i++) {
      final codec = await ui
          .instantiateImageCodec(base64Decode(images[order[i]]!.substring(22)));
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final pixels =
          (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!
              .buffer
              .asUint8List();
      expect(image.width, 256);
      expect(pixels[3], 0, reason: 'Background must be genuinely transparent');
      const center = (128 * 256 + 128) * 4;
      expect(pixels[center + 3], 255);
      expect(pixels[center], closeTo(60 + i * 15, 1),
          reason: 'Correct row-major emotion mapping');
      image.dispose();
    }
  });

  test('unusable opaque backdrop is rejected rather than saved as transparent',
      () async {
    await expectLater(
        CharacterPortraitService.splitPortraitSheet(
            await sprite(background: false)),
        throwsException);
  });

  test(
      'portraits survive save, archive and restore; legacy saves remain compatible',
      () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.load();
    final created = await settings.addGeneratedScenario({
      'name': 'Alex',
      'role': 'Barista',
      'goal': 'Order coffee',
      'opening': 'Hello!',
      'description': 'Friendly',
      'portraits': fixturePortraits,
    }, 'Cafe', 'A2', true);
    await settings.archiveScenario(created.customId!);
    final restored = SettingsService();
    await restored.load();
    expect(restored.archivedScenarios.single.portraits, fixturePortraits);
    await restored.restoreScenario(created.customId!);
    expect(restored.customScenarios.single.portraits, fixturePortraits);
    final old = Map<String, dynamic>.from(created.toJson())
      ..remove('portraits');
    expect(Scenario.fromJson(old).portraits, isEmpty);
    expect(
        Scenario.parsePortraits({'neutral': 'https://example.com/image.png'}),
        isEmpty);
  });

  test(
      'a session key overrides local configuration without entering persisted settings',
      () async {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=synthetic-local-key');
    ApiCredentials.setGeminiKey('synthetic-session-key');
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.load();
    expect(ApiCredentials.geminiKey, 'synthetic-session-key');
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getKeys().any((name) => name.toLowerCase().contains('api_key')),
        false);
    ApiCredentials.clear();
    expect(ApiCredentials.geminiKey, 'synthetic-local-key');
  });
}
