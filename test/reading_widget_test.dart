import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialect_duel/models/reading_article.dart';
import 'package:dialect_duel/screens/reading_screen.dart';
import 'package:dialect_duel/screens/reader_screen.dart';
import 'package:dialect_duel/theme/app_theme.dart';
import 'package:dialect_duel/widgets/dictionary_sheet.dart';
import 'package:dialect_duel/widgets/word_clickable_text.dart';
import 'widget_test.dart' as helpers;

Future<void> reveal(WidgetTester tester, Finder target, double distance) async {
    await tester.scrollUntilVisible(target, distance,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    for (final family in ['Manrope', 'Lora', 'NotoSans']) {
      await (FontLoader(family)
            ..addFont(File('assets/fonts/$family.ttf')
                .readAsBytes()
                .then(ByteData.sublistView)))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(File(
                  'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView)))
        .load();
  });
  testWidgets(
      'reader translates a tapped word, saves it, checks answers and prevents repeated XP',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (settings, progress) = await helpers.services();
    final article = starterReadings.first;
    await tester.pumpWidget(RepaintBoundary(
        key: const Key('preview'),
        child: MaterialApp(
            theme: buildAppTheme(),
            home: ReaderScreen(
                settings: settings, progress: progress, article: article))));
    await tester.pumpAndSettle();
    await helpers.capture(tester, 'reading_article_light');
    final selectable = find.descendant(
        of: find.byType(WordClickableText),
        matching: find.byType(EditableText));
    final editable = tester.state<EditableTextState>(selectable).renderEditable;
    final start = article.text.indexOf('coffee');
    final boxes = editable.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + 6));
    await tester.tapAt(editable.localToGlobal(boxes.first.toRect().center));
    await tester.pumpAndSettle();
    expect(find.byType(DictionarySheet), findsOneWidget);
    expect(find.text('кава'), findsOneWidget);
    await tester.ensureVisible(find.text('Додати до карток'));
    await tester.tap(find.text('Додати до карток'));
    await tester.pumpAndSettle();
    expect(settings.vocabulary.custom.map((c) => c.word), contains('coffee'));
    Navigator.of(tester.element(find.byType(DictionarySheet))).pop();
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Перевірити розуміння'), 350);
    await tester.tap(find.text('Перевірити розуміння'));
    await tester.pumpAndSettle();
    Future<void> answer(int i, int j) async {
      final target = find.byKey(Key('reading_answer_${i}_$j'));
      await reveal(tester, target, 350);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await answer(0, 0);
    await answer(1, 1);
    await answer(2, 1);
    final finish = find.byKey(const Key('finish_reading_quiz'));
    await reveal(tester, finish, 350);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(settings.reading.results[article.id]?['correct'], 2);
    expect(progress.profile.xp, 8);
    await helpers.capture(tester, 'reading_quiz_result');
    await reveal(tester, find.text('Спробувати ще раз'), 250);
    await tester.tap(find.text('Спробувати ще раз'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await answer(i, article.authoredQuestions[i].answer);
    }
    await reveal(tester, finish, 350);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(settings.reading.results[article.id]?['correct'], 3);
    expect(progress.profile.xp, 10);
    await reveal(tester,find.text('Спробувати ще раз'),250);
    await tester.tap(find.text('Спробувати ще раз'));
    await tester.pumpAndSettle();
    for(var i=0;i<3;i++) { await answer(i,article.authoredQuestions[i].answer); }
    await reveal(tester,finish,350);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(progress.profile.xp,10);
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('library and reader fit 320px with 200 percent text ($dark)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, progress) = await helpers.services();
      await tester.pumpWidget(RepaintBoundary(
          key: const Key('preview'),
          child: MaterialApp(
              theme: dark ? buildDarkTheme() : buildAppTheme(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!),
              home: ReadingScreen(settings: settings, progress: progress))));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('read_starter:cafe')), 300);
      await tester.tap(find.byKey(const Key('read_starter:cafe')));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      await helpers.capture(tester,
          dark ? 'reading_accessible_dark' : 'reading_accessible_light');
      await reveal(tester, find.text('Перевірити розуміння'), 300);
      await tester.tap(find.text('Перевірити розуміння'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('bookmarked articles appear in the library', (tester) async {
    final (settings, progress) = await helpers.services();
    await settings.reading.setBookmark(starterReadings.first.id, true);
    await tester.pumpWidget(MaterialApp(
        theme: buildDarkTheme(),
        home: ReadingScreen(settings: settings, progress: progress)));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Закладки · 1'), 200);
    await tester.tap(find.text('Закладки · 1'));
    await tester.pumpAndSettle();
    expect(find.text(starterReadings.first.title), findsOneWidget);
    expect(find.text(starterReadings[1].title), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
