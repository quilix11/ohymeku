import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/story/story_service.dart';
import 'package:dialect_duel/story/story_catalog.dart';
import 'package:dialect_duel/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'authored story is sequential; wrong answers and duplicate choices do not advance',
      () async {
    final s = StoryService();
    await s.load();
    final c = s.chapters.first;
    await expectLater(s.choose(c.id, 0, 1, 0), throwsStateError);
    await expectLater(s.choose(s.chapters[1].id, 0, 0, 0), throwsStateError);
    final first = s.choose(c.id, 0, c.scenes[0].answer, 1);
    final duplicate = s.choose(c.id, 0, c.scenes[0].answer, 0);
    await first;
    await expectLater(duplicate, throwsStateError);
    expect(s.done(c), 1);
    expect(s.clues, contains(c.scenes[0].clue));
    expect(s.consequence(c, 0), c.scenes[0].consequences[1]);
    final restored = StoryService();
    await restored.load();
    expect(restored.done(c), 1);
    expect(restored.decisions, s.decisions);
  });
  test(
      'generated continuation receives decisions and survives restart; offline never requests',
      () async {
    final s = StoryService();
    await s.load();
    for (final c in s.chapters) {
      for (var i = 0; i < c.scenes.length; i++) {
        await s.choose(c.id, i, c.scenes[i].answer, i % 2);
      }
    }
    expect(s.caughtUp, isTrue);
    var calls = 0;
    Future<Map<String, dynamic>> request(
        String rules, Map<String, dynamic> input) async {
      calls++;
      expect(input['player_name'], 'Лис');
      expect((input['player_choices'] as Map).length, 15);
      expect((input['confirmed_clues'] as List).length, 15);
      expect(rules, contains('Lyra'));
      return {...storyChapters.first.toJson(), 'title': 'Новий берег'};
    }

    await expectLater(
        s.generate(name: 'Лис', level: 'A2', offline: true, request: request),
        throwsException);
    expect(calls, 0);
    await s.generate(
        name: 'Лис', level: 'A2', offline: false, request: request);
    expect(s.chapters.length, 6);
    expect(s.current.title, 'Новий берег');
    final restored = StoryService();
    await restored.load();
    expect(restored.chapters.last.title, 'Новий берег');
    expect(restored.chapters.last.generated, isTrue);
    expect(restored.clues.length, 15);
  });
  test('invalid model output never replaces the save or creates a chapter',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        StoryService.storageKey,
        jsonEncode({
          'completed': {for (final c in storyChapters) c.id: c.scenes.length},
          'generated': [],
          'decisions': {},
          'clues': []
        }));
    final s = StoryService();
    await s.load();
    final before = prefs.getString(StoryService.storageKey);
    await expectLater(
        s.generate(
            name: 'Лис',
            level: 'B1',
            offline: false,
            request: (_, __) async => {'title': 'Broken', 'scenes': []}),
        throwsException);
    expect(s.chapters.length, 5);
    expect(s.busy, isFalse);
    expect(prefs.getString(StoryService.storageKey), before);
  });
  test(
      'nickname, biography and new avatar persist without losing legacy progress',
      () async {
    final p = ProgressService();
    await p.initialize();
    await p.saveProfile('Андрій', 10,
        nickname: '@fox', bio: 'Люблю море', avatarColor: 4);
    await p.recordActivity('word:hello', 5);
    final restored = ProgressService();
    await restored.initialize();
    expect(restored.dialogueName, 'fox');
    expect(restored.name, 'Андрій');
    expect(restored.bio, 'Люблю море');
    expect(restored.avatar, 10);
    expect(restored.avatarColor, 4);
    expect(restored.profile.xp, 5);
    await expectLater(restored.saveProfile('a' * 25, 0), throwsArgumentError);
    expect(restored.name, 'Андрій');
    await restored.saveProfile('Андрій', 10, nickname: '');
    expect(restored.dialogueName, 'Андрій');
  });
}
