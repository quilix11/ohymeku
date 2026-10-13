import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/game_state.dart';
import 'package:dialect_duel/models/scenario.dart';
import 'package:dialect_duel/screens/generation_screen.dart';
import 'package:dialect_duel/services/learning_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'learning_service_test.dart' show character, reply, envelope;
import 'dart:convert';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=test-only-key');
  });

  testWidgets(
      'scenario generation reaches preview and persists the approved snapshot',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = SettingsService();
    await settings.load();
    final service = LearningService(
        client: MockClient((_) async => reply(
            envelope('```json\n${jsonEncode(character)}\n```', finish: null))));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => GenerationScreen(
                                  boss: true,
                                  service: service,
                                  onSave: (result, topic, level, warm) =>
                                      settings.addScenario(Scenario(
                                        customId: 'test-cafe',
                                        character: warm
                                            ? GameCharacter.hr
                                            : GameCharacter.officer,
                                        name: result['name'],
                                        role: result['role'],
                                        title: topic,
                                        goal: result['goal'],
                                        opening: result['opening'],
                                        personality: result['description'],
                                        level: level,
                                        winTitle: 'Вдало поговорили!',
                                        color: Colors.green,
                                        backdrop: Colors.white,
                                      ))))),
                      child: const Text('Відкрити генерацію')),
                ))));
    await tester.tap(find.text('Відкрити генерацію'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Кав’ярня');
    await tester.scrollUntilVisible(find.text('Створити'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Створити'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Alex'), 150,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.text('Alex'), findsOneWidget);
    expect(settings.customScenarios, isEmpty);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(
        find.byType(TextField), 'Змінена тема після перегляду');
    await tester.scrollUntilVisible(find.text('Додати співрозмовника'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Додати співрозмовника'));
    await tester.pumpAndSettle();
    expect(find.text('Відкрити генерацію'), findsOneWidget);
    expect(settings.customScenarios.single.title, 'Кав’ярня');
    final restored = SettingsService();
    await restored.load();
    expect(restored.customScenarios.single.name, 'Alex');
    expect(restored.customScenarios.single.opening, character['opening']);
    expect(
        restored.customScenarios.single.personality, character['description']);
    expect(restored.customScenarios.single.level, 'A2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed generation retains the topic and can be retried',
      (tester) async {
    var calls = 0, saved = 0;
    final service = LearningService(client: MockClient((_) async {
      calls++;
      return reply(envelope(calls <= 2 ? '{broken' : jsonEncode(character)));
    }));
    await tester.pumpWidget(MaterialApp(
        home: GenerationScreen(
      boss: true,
      service: service,
      onSave: (_, __, ___, ____) async {
        saved++;
      },
    )));
    await tester.enterText(find.byType(TextField), 'Кав’ярня');
    await tester.scrollUntilVisible(find.text('Створити'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Створити'));
    await tester.pumpAndSettle();
    expect(find.textContaining('двічі'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Кав’ярня');
    expect(find.text('Додати співрозмовника'), findsNothing);
    expect(saved, 0);
    await tester.tap(find.text('Створити'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Alex'), 150,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.text('Alex'), findsOneWidget);
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });
}
