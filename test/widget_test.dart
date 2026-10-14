import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/main.dart';
import 'package:dialect_duel/models/game_state.dart' as game;
import 'package:dialect_duel/models/scenario.dart';
import 'package:dialect_duel/screens/game_screen.dart';
import 'package:dialect_duel/screens/main_screen.dart';
import 'package:dialect_duel/screens/meku_screen.dart';
import 'package:dialect_duel/screens/settings_screen.dart';
import 'package:dialect_duel/screens/practice_screen.dart';
import 'package:dialect_duel/screens/placement_screen.dart';
import 'package:dialect_duel/screens/generation_screen.dart';
import 'package:dialect_duel/services/meku_service.dart';
import 'package:dialect_duel/services/ai_service.dart';
import 'package:dialect_duel/services/learning_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/theme/app_theme.dart';
import 'package:dialect_duel/widgets/chat_bubble.dart';
import 'package:dialect_duel/widgets/ohymeku_design.dart';
import 'package:dialect_duel/models/meku_emotion.dart';
import 'package:dialect_duel/widgets/meku_avatar.dart';

class EnglishTutor extends LearningService {
  @override
  Future<LanguageHelp> prepare(String text, String context,
          {bool help = false, String level = 'A2'}) async =>
      const LanguageHelp(true, '', []);
}

class ReplyAi extends AiService {
  @override
  Future<game.NpcResponse> sendMessage(
          {required game.GameCharacter character,
          required List<game.ChatMessage> chatHistory,
          required int currentTrust,
          required int currentPatience,
          List<String>? interests,
          required String playerMessage}) async =>
      game.NpcResponse(
          npcResponse: 'Tell me more about your experience.',
          npcEmotion: game.NpcEmotion.happy,
          trustDelta: 5,
          patienceDelta: 5,
          currentTrust: 55,
          currentPatience: 55,
          gameStatus: game.GameStatus.inProgress,
          feedback: game.Feedback.empty());
}

Future<(SettingsService, ProgressService)> services() async {
  SharedPreferences.setMockInitialValues(
      {'tts_enabled': false, 'has_taken_placement': true});
  final settings = SettingsService();
  await settings.load();
  final progress = ProgressService();
  await progress.initialize();
  return (settings, progress);
}

Future<void> capture(WidgetTester tester, String name) async {
  final context = tester.element(find.byKey(const Key('preview')));
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((widget) => widget.image)
      .toSet();
  // Cache the rendered providers, including their actual decode sizes.
  await tester.runAsync(() => Future.wait(
      providers.map((provider) => precacheImage(provider, context))));
  await tester.pumpAndSettle();
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final family in ['Manrope', 'Lora', 'NotoSans']) {
      final loader = FontLoader(family)
        ..addFont(File('assets/fonts/$family.ttf')
            .readAsBytes()
            .then(ByteData.sublistView));
      await loader.load();
    }
    final font = File(
        '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/segoeui.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(
            font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  testWidgets('carousel, navigation and profile editing work on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await services();
    await tester.pumpWidget(RepaintBoundary(
        key: const Key('preview'),
        child: DialectDuelApp(settings: settings, progress: progress)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'ohymeku_home');
    expect(find.byType(NavigationDestination), findsNothing);
    await tester.tap(find.byKey(const Key('meku_launcher')));
    await tester.pumpAndSettle();
    expect(find.byType(MekuScreen), findsOneWidget);
    await capture(tester, 'meku_sheet');
    await tester.tap(find.byTooltip('Закрити Meku'));
    await tester.pumpAndSettle();
    expect(find.byType(MekuScreen), findsNothing);
    await tester.tap(find.byTooltip('Слова'));
    await tester.pumpAndSettle();
    await capture(tester, 'ohymeku_words');
    await tester.tap(find.byTooltip('Головна'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open_conversations')));
    await tester.tap(find.byKey(const Key('open_conversations')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('character_carousel')));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const Key('character_carousel')), const Offset(-330, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hannah'));
    await tester.pumpAndSettle();
    expect(settings.lastCharacter, 1);
    expect(find.text('Hannah'), findsOneWidget);
    await capture(tester, 'hannah');
    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Твій прогрес'), findsOneWidget);
    await capture(tester, 'ohymeku_progress');
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    await capture(tester, 'ohymeku_profile');
    await tester.tap(find.byTooltip('Редагувати профіль'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile_name')), 'Андрій');
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(progress.name, 'Андрій');
    expect(find.text('Андрій'), findsOneWidget);
    expect(find.text('Олена'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first theme change works independently of animations',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final animations in [true, false]) {
      final (settings, progress) = await services();
      await settings.setAnimationsEnabled(animations);
      await tester.pumpWidget(DialectDuelApp(
          key: UniqueKey(), settings: settings, progress: progress));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(MainScreen))).brightness,
          Brightness.light);

      await settings.setTheme(AppThemeMode.dark);
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(MainScreen))).brightness,
          Brightness.dark);
      expect(settings.animationsEnabled, animations);

      await settings.setTheme(AppThemeMode.light);
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(MainScreen))).brightness,
          Brightness.light);
      expect(settings.animationsEnabled, animations);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('game opens with NPC and retains visible history after a reply',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await services();
    await tester.pumpWidget(RepaintBoundary(
        key: const Key('preview'),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: GameScreen(
                settings: settings,
                progress: progress,
                character: game.GameCharacter.hr,
                tutor: EnglishTutor(),
                ai: ReplyAi()))));
    await tester.pumpAndSettle();
    expect(
        find.text(Scenario.of(game.GameCharacter.hr).opening), findsOneWidget);
    await capture(tester, 'conversation');
    await tester.enterText(find.byKey(const Key('message_input')),
        'I led a team of five engineers.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(find.text('Tell me more about your experience.'), findsOneWidget);
    expect(find.byType(ChatBubble), findsNWidgets(3));
    expect(
        find.descendant(
            of: find.byType(ChatBubble), matching: find.byType(FadeTransition)),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meku chat changes level and displays the actual receipt',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await services();
    final meku = MekuService(settings, progress,
        request: (_, __) async => {
              'reply':
                  'Ого, давай! Спробуємо B1. Почнемо з короткої розмови про твої плани?',
              'emotion': 'excited',
              'action': {'type': 'level', 'value': 'B1'},
            });
    addTearDown(meku.dispose);
    await tester.pumpWidget(RepaintBoundary(
      key: const Key('preview'),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: Scaffold(
              body: SafeArea(child: MekuScreen(meku: meku, navigate: (_) {})))),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),
        'Я краще розумію англійську. Піднімімо рівень.');
    await tester.pump();
    await tester.tap(find.byTooltip('Надіслати Meku'));
    await tester.pumpAndSettle();
    expect(settings.effectiveLevel, 'B1');
    expect(find.text('Результат дії'), findsOneWidget);
    expect(find.textContaining('Рівень змінено на B1'), findsOneWidget);
    expect(
        tester
            .widgetList<MekuAvatar>(find.byType(MekuAvatar))
            .every((avatar) => avatar.emotion == MekuEmotion.excited),
        isTrue);
    expect(tester.takeException(), isNull);
    await capture(tester, 'meku_chat');
  });

  testWidgets('Meku keeps response emotions with large text and a keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final (settings, progress) = await services();
    var mood = 'sad';
    final meku = MekuService(settings, progress,
        request: (_, __) async => {
              'reply': mood == 'sad'
                  ? 'Розумію, це дратує. Давай розберемо помилку.'
                  : 'Гей, лапки геть від моєї гідності. Чим допомогти?',
              'emotion': mood,
              'action': null
            });
    addTearDown(meku.dispose);
    await meku.send('Злюся через помилку.', navigate: (_) {});
    mood = 'annoyed';
    await meku.send('Ти дурна.', navigate: (_) {});
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2), disableAnimations: true),
          child: child!),
      home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SizedBox(
              height: 292, child: MekuScreen(meku: meku, navigate: (_) {}))),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),
        'Довге повідомлення\nз кількома рядками\nі ще один рядок.');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Надіслати Meku').hitTestable(), findsOneWidget);
    expect(
        meku.messages
            .where((m) => m['role'] == 'assistant')
            .map((m) => m['emotion']),
        ['sad', 'annoyed']);
  });

  testWidgets('all Meku portraits render in both themes', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await tester.pumpWidget(RepaintBoundary(
          key: const Key('preview'),
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? buildDarkTheme() : buildAppTheme(),
              home: Scaffold(
                  body: SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Meku · 8 емоцій',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Expanded(
                                    child: GridView.count(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.1,
                                        children: [
                                      for (final emotion in MekuEmotion.values)
                                        Column(children: [
                                          MekuAvatar(
                                              size: 110, emotion: emotion),
                                          const SizedBox(height: 4),
                                          Text(emotion.label)
                                        ])
                                    ]))
                              ])))))));
      await tester.pumpAndSettle();
      await capture(
          tester, dark ? 'meku_emotions_dark' : 'meku_emotions_light');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('chat controls fit large text and an open keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final (settings, progress) = await services();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!),
      home: GameScreen(
          settings: settings,
          progress: progress,
          character: game.GameCharacter.hr,
          tutor: EnglishTutor(),
          ai: ReplyAi()),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('message_input')), 'I enjoy working with people.');
    await tester.pump();
    expect(find.byKey(const Key('send_message')).hitTestable(), findsOneWidget);
    expect(find.byTooltip('Допоможи сказати англійською').hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('send_message')));
    await tester.pumpAndSettle();
    expect(find.text('Tell me more about your experience.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary pages share the redesign and remain usable',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await services();
    final pages = <String, Widget>{
      'ohymeku_settings': SettingsScreen(settings: settings),
      'ohymeku_practice':
          PracticeScreen(settings: settings, progress: progress),
      'ohymeku_placement':
          PlacementScreen(settings: settings, progress: progress),
      'ohymeku_generation': GenerationScreen(
          boss: false,
          level: settings.effectiveLevel,
          interests: const [],
          onSave: (_, __, ___, ____) async {}),
    };
    for (final entry in pages.entries) {
      await tester.pumpWidget(RepaintBoundary(
          key: const Key('preview'),
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              home: entry.value)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.key);
      if (entry.value is SettingsScreen) {
        expect(find.text('Плавні анімації'), findsNothing);
      }
      await capture(tester, entry.key);
      if (entry.key == 'ohymeku_practice') {
        final exercise = settings.learner
            .due(settings.effectiveLevel, settings.interests)
            .first;
        await tester
            .ensureVisible(find.text(exercise.options[exercise.answer]));
        await tester.tap(find.text(exercise.options[exercise.answer]));
        await tester.pumpAndSettle();
        expect(find.text('Так, правильно!'), findsOneWidget);
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets(
        'expanded interests and reminders render and accept a custom topic (${dark ? "dark" : "light"})',
        (tester) async {
      tester.view.physicalSize =
          dark ? const Size(320, 568) : const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, _) = await services();
      await settings.setTheme(dark ? AppThemeMode.dark : AppThemeMode.light);
      await tester.pumpWidget(RepaintBoundary(
          key: const Key('preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? buildDarkTheme() : buildAppTheme(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(dark ? 2 : 1)),
                child: child!),
            home: SettingsScreen(settings: settings),
          )));
      await tester.pumpAndSettle();
      final list = find
          .descendant(
              of: find.byType(ListView), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
          find.text('Твої інтереси й нагадування').hitTestable(), 100,
          scrollable: list);
      await tester.tap(find.text('Твої інтереси й нагадування'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      await tester.scrollUntilVisible(find.text('Свій інтерес'), 100,
          scrollable: list);
      await tester.enterText(
          find.widgetWithText(TextField, 'Свій інтерес'), 'Фотографія');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Додати інтерес'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Додати інтерес'));
      await tester.pumpAndSettle();
      expect(settings.interests, contains('Фотографія'));
      await tester.scrollUntilVisible(find.text('Час нагадування'), 100,
          scrollable: list);
      expect(find.text('Щоденне нагадування'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester,
          dark ? 'interests_reminders_dark' : 'interests_reminders_light');
      await tester.tap(find.text('Час нагадування'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.text('Твої інтереси й нагадування').hitTestable(), -100,
          scrollable: list);
      await tester.tap(find.text('Твої інтереси й нагадування'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Свій інтерес'), findsNothing);
      await tester.ensureVisible(find.text('Твої інтереси й нагадування'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Твої інтереси й нагадування'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Свій інтерес'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      final restored = SettingsService();
      await restored.load();
      expect(restored.interests, contains('Фотографія'));
    });
  }

  testWidgets('Meku opens over the selected page and adapts to keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final (settings, progress) = await services();
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: MainScreen(settings: settings, progress: progress)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Слова'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meku_launcher')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Привіт');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Закрити Meku'));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Словник'), findsOneWidget);
    expect(find.byType(MekuScreen), findsNothing);
  });

  testWidgets('learning pages fit a small phone at 200 percent text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await services();
    final pages = <Widget>[
      SettingsScreen(settings: settings),
      PracticeScreen(settings: settings, progress: progress),
      PlacementScreen(settings: settings, progress: progress),
      GenerationScreen(
          boss: false,
          level: settings.effectiveLevel,
          onSave: (_, __, ___, ____) async {}),
    ];
    for (final page in pages) {
      await tester.pumpWidget(MaterialApp(
        theme: buildDarkTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!),
        home: page,
      ));
      // Advance native voice discovery's timeout in the mocked platform.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
      if (page is PracticeScreen) {
        await tester.scrollUntilVisible(
            find.byWidgetPredicate(
                (widget) => widget is AnswerTile && widget.marker == 'A'),
            200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('conversation action is visible and stories support large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final (size, scale, dark) in [
      (const Size(375, 812), 1.0, false),
      (const Size(320, 568), 2.0, true),
      (const Size(320, 568), 3.2, true),
      (const Size(812, 375), 2.0, false),
    ]) {
      tester.view.physicalSize = size;
      final (settings, progress) = await services();
      await tester.pumpWidget(MaterialApp(
        theme: dark ? buildDarkTheme() : buildAppTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child!),
        home: MainScreen(
            key: UniqueKey(), settings: settings, progress: progress),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const Key('open_conversations')), 160,
          scrollable: find.byType(Scrollable).first);
      await Scrollable.ensureVisible(
          tester.element(find.byKey(const Key('open_conversations'))),
          alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_conversations')));
      await tester.pumpAndSettle();
      final start = find.byKey(const Key('start_officer'));
      if (scale == 1) {
        expect(start.hitTestable(), findsOneWidget,
            reason: 'The primary action should be visible on a phone');
      }
      await tester.scrollUntilVisible(
          find.byKey(const Key('character_carousel')), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size / $scale');
      await tester.scrollUntilVisible(start, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(start.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size / $scale');
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(812, 375),
    const Size(768, 1024)
  ]) {
    testWidgets('menus adapt to $size with large text and dark theme',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, progress) = await services();
      await settings.setTheme(AppThemeMode.dark);
      await tester.pumpWidget(RepaintBoundary(
          key: const Key('preview'),
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildDarkTheme(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.6),
                      disableAnimations: true),
                  child: child!),
              home: MainScreen(settings: settings, progress: progress))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'ohymeku_dark_${size.width.toInt()}');
      await tester.tap(find.byTooltip('Слова'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('meku_launcher')));
      await tester.pumpAndSettle();
      expect(find.byType(MekuScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Закрити Meku'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
