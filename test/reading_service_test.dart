import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/models/reading_article.dart';
import 'package:dialect_duel/services/reading_service.dart';
import 'package:dialect_duel/services/learning_service.dart';
import 'package:dialect_duel/services/ai_service.dart';

const passage =
    'Coffee is a drink made from roasted seeds of a plant. People often drink coffee in the morning because it contains caffeine. Coffee shops are places where people can meet friends and enjoy a warm drink together.';
Map<String, dynamic> wiki({bool empty = false}) => {
      'query': {
        'pages': empty
            ? []
            : [
                {
                  'pageid': 42,
                  'title': 'Coffee',
                  'extract': passage,
                  'index': 1,
                  'fullurl': 'https://simple.wikipedia.org/wiki/Coffee'
                }
              ]
      }
    };
http.Response response(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

class QuizFixture extends LearningService {
  bool grounded = true;
  int calls = 0;
  @override
  Future<Map<String, dynamic>> request(String rules, Map<String, dynamic> input,
      {Map<String, dynamic>? schema, int maxOutputTokens = 4096}) async {
    calls++;
    expect(rules, contains('untrusted data'));
    expect(input['article'], passage);
    return {
      'questions': List.generate(
          3,
          (i) => {
                'question': 'What is coffee? $i',
                'options': ['A drink', 'A chair', 'A phone', 'A boat'],
                'answer': 0,
                'explanation': 'У тексті кава описана як напій.',
                'evidence': grounded
                    ? 'Coffee is a drink made from roasted seeds of a plant.'
                    : 'This quote does not occur in the article.'
              })
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'search uses public CORS API; bookmarks and downloaded texts work offline',
      () async {
    var calls = 0;
    final service = ReadingService(client: MockClient((r) async {
      calls++;
      expect(r.url.host, 'simple.wikipedia.org');
      expect(r.url.queryParameters['origin'], '*');
      expect(r.url.queryParameters['explaintext'], '1');
      expect(r.url.queryParameters['gsrsearch'], 'Coffee');
      return response(wiki());
    }));
    addTearDown(service.dispose);
    final found = await service.search('Coffee');
    expect(found.single.text, passage);
    expect(found.single.url, 'https://simple.wikipedia.org/wiki/Coffee');
    expect(found.single.license, 'CC BY-SA 4.0');
    await service.search('coffee');
    expect(calls, 1);
    await service.setBookmark(found.single.id, true);
    final restored = ReadingService(
        client:
            MockClient((_) async => throw StateError('No offline network')));
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.bookmarks, contains(found.single.id));
    expect((await restored.search('Coffee', offline: true)).map((a) => a.id),
        contains(found.single.id));
  });
  test('empty Simple search falls back to English Wikipedia', () async {
    final hosts = <String>[];
    final service = ReadingService(client: MockClient((r) async {
      hosts.add(r.url.host);
      return response(wiki(empty: hosts.length == 1));
    }));
    addTearDown(service.dispose);
    final result = await service.search('Coffee');
    expect(hosts, ['simple.wikipedia.org', 'en.wikipedia.org']);
    expect(result.single.url, startsWith('https://en.wikipedia.org/'));
  });
  test(
      'AI questions must quote article; results use actual answers and persist',
      () async {
    final ai = QuizFixture();
    final service = ReadingService(
        ai: ai, client: MockClient((_) async => response(wiki())));
    addTearDown(service.dispose);
    final article = (await service.search('Coffee')).single;
    final quiz = await service.quizFor(article);
    expect(quiz.kind, 'ai');
    expect(quiz.questions.length, 3);
    expect(await service.complete(article, quiz, [0, 1, 0]), 2);
    expect(service.results[article.id]?['correct'], 2);
    await service.quizFor(article);
    expect(ai.calls, 1);
    final restored = ReadingService();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.results[article.id]?['correct'], 2);
    await expectLater(service.complete(article, quiz, [0, 4, 0]),
        throwsA(isA<AiException>()));
  });
  test(
      'ungrounded AI output falls back to a local quiz with quotes from the article',
      () async {
    final ai = QuizFixture()..grounded = false;
    final service = ReadingService(
        ai: ai, client: MockClient((_) async => response(wiki())));
    addTearDown(service.dispose);
    final article = (await service.search('Coffee')).single;
    final quiz = await service.quizFor(article);
    expect(quiz.kind, 'extractive');
    expect(quiz.questions.length, 3);
    for (final q in quiz.questions) {
      expect(passage, contains(q.evidence));
      expect(q.options.toSet().length, 4);
    }
    expect(
        await service.complete(
            article, quiz, quiz.questions.map((q) => q.answer).toList()),
        3);
  });
  test('all original starter articles have valid grounded offline questions',
      () async {
    final service = ReadingService(
        client: MockClient((_) async => throw StateError('offline')));
    addTearDown(service.dispose);
    for (final article in starterReadings) {
      final quiz = await service.quizFor(article, offline: true);
      expect(quiz.kind, 'authored');
      expect(
          await service.complete(
              article, quiz, quiz.questions.map((q) => q.answer).toList()),
          3);
    }
  });
  test('persisted article links reject arbitrary domains and credentials', () {
    final data = starterReadings.first.toJson();
    for (final url in [
      'http://simple.wikipedia.org/wiki/Coffee',
      'https://evil.example/',
      'https://user:pass@simple.wikipedia.org/wiki/Coffee'
    ]) {
      expect(() => ReadingArticle.fromJson({...data, 'url': url}),
          throwsFormatException);
    }
  });
}
