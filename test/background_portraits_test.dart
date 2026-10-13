import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/scenario.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'portrait_fixtures.dart';
import 'learning_service_test.dart' show character;

Future<void> flush() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '');
  });
  test(
      'save returns before images, requests serialize and finished artwork persists',
      () async {
    final jobs = <Completer<Map<String, String>>>[];
    final settings = SettingsService(portraitGenerator: (_) {
      final job = Completer<Map<String, String>>();
      jobs.add(job);
      return job.future;
    });
    addTearDown(settings.dispose);
    await settings.load();
    final first =
        await settings.addGeneratedScenario(character, 'Coffee', 'A2', true);
    await settings.addGeneratedScenario(
        {...character, 'name': 'Second'}, 'Travel', 'B1', false);
    await flush();
    expect(settings.customScenarios.length, 2);
    expect(jobs.length, 1);
    expect(settings.customScenarios.first.portraitStatus,
        PortraitStatus.generating);
    jobs.first.complete(fixturePortraits);
    await flush();
    expect(jobs.length, 2);
    // A stale metadata edit must not overwrite completed artwork.
    await settings.editScenario(first);
    expect(settings.customScenarios.first.portraits, fixturePortraits);
    jobs.last.complete(fixturePortraits);
    await flush();
    final restored = SettingsService();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.customScenarios.map((s) => s.portraitStatus),
        everyElement(PortraitStatus.ready));
    expect(restored.customScenarios.map((s) => s.portraits),
        everyElement(fixturePortraits));
  });
  test('failure keeps character, shows cause and can be retried independently',
      () async {
    var calls = 0;
    final settings = SettingsService(portraitGenerator: (_) async {
      if (++calls == 1) throw const AiException('HTTP 429: daily quota');
      return fixturePortraits;
    });
    addTearDown(settings.dispose);
    await settings.load();
    final s =
        await settings.addGeneratedScenario(character, 'Coffee', 'A2', true);
    await flush();
    expect(settings.customScenarios.single.name, 'Alex');
    expect(settings.customScenarios.single.portraitError, contains('HTTP 429'));
    expect(
        settings.customScenarios.single.portraitStatus, PortraitStatus.failed);
    settings.resumePortraits();
    await flush();
    expect(calls, 1);
    await settings.retryPortraits(s.customId!);
    await flush();
    expect(
        settings.customScenarios.single.portraitStatus, PortraitStatus.ready);
    expect(settings.customScenarios.single.portraitError, isNull);
  });
  test('archiving during generation never resurrects the character', () async {
    final job = Completer<Map<String, String>>();
    final settings = SettingsService(portraitGenerator: (_) => job.future);
    addTearDown(settings.dispose);
    await settings.load();
    final s =
        await settings.addGeneratedScenario(character, 'Coffee', 'A2', true);
    await flush();
    await settings.archiveScenario(s.customId!);
    job.complete(fixturePortraits);
    await flush();
    expect(settings.customScenarios, isEmpty);
    expect(settings.archivedScenarios.single.name, 'Alex');
    expect(settings.archivedScenarios.single.portraits, fixturePortraits);
    expect(
        settings.archivedScenarios.single.portraitStatus, PortraitStatus.ready);
  });
  test('interrupted generation resumes on load but offline mode pauses it',
      () async {
    final s = Scenario.fromJson({
      ...character,
      'id': 'pending',
      'character': 'hr',
      'level': 'A2',
      'portraitStatus': 'generating'
    });
    SharedPreferences.setMockInitialValues({
      'custom_scenarios_v1': jsonEncode([s.toJson()]),
      'offline_mode': true
    });
    var calls = 0;
    final settings = SettingsService(portraitGenerator: (_) async {
      calls++;
      return fixturePortraits;
    });
    addTearDown(settings.dispose);
    await settings.load();
    await flush();
    expect(calls, 0);
    await settings.setExtra('offline_mode', false);
    await flush();
    expect(calls, 1);
    expect(
        settings.customScenarios.single.portraitStatus, PortraitStatus.ready);
  });
}
