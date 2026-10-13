import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/services/learning_service.dart';
import 'package:dialect_duel/services/meku_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';

class RealNetwork extends HttpOverrides {}

// Explicit opt-in only. Uses synthetic topics and mock storage, never user saves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'live Gemini creates a character and interprets colloquial flashcard requests',
      () => HttpOverrides.runWithHttpOverrides(() async {
            dotenv.testLoad(fileInput: await File('.env').readAsString());
            SharedPreferences.setMockInitialValues({});
            final settings = SettingsService();
            await settings.load();
            final progress = ProgressService();
            await progress.initialize();
            final ai = LearningService();
            addTearDown(ai.dispose);
            final character = await ai.generate(
                'A playful coffee shop barista', 'A2', 1, true,
                warm: true);
            expect(character['opening'], isNotEmpty);
            expect(character['description'], isNotEmpty);
            final meku = MekuService(settings, progress);
            addTearDown(meku.dispose);
            await meku.send('Можеш зробити 8 карточок на тему кави?',
                navigate: (_) {});
            expect(meku.error, isNull);
            expect(meku.messages.where((m) => m['status'] == 'error'), isEmpty);
            expect(settings.vocabulary.custom.length, 8);
            final articles = await settings.reading.search('Coffee');
            expect(articles, isNotEmpty);
            final quiz = await settings.reading.quizFor(articles.first);
            expect(quiz.kind, 'ai');
            expect(quiz.questions.length, 3);
          }, RealNetwork()),
      skip: !const bool.fromEnvironment('RUN_LIVE_GEMINI'),
      timeout: const Timeout(Duration(minutes: 4)));
}
