import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialect_duel/widgets/sentence_builder.dart';

Future<void> moveWord(
    WidgetTester tester, String key, Offset destination) async {
  final gesture =
      await tester.startGesture(tester.getCenter(find.byKey(Key(key))));
  await tester.pump(const Duration(milliseconds: 600));
  await gesture.moveTo(destination);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'drag repeated words, reorder and return at phone width / $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var chosen = <int>[];
      var enabled = true;
      late StateSetter rebuild;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: StatefulBuilder(builder: (context, setState) {
                    rebuild = setState;
                    return Padding(
                        padding: const EdgeInsets.all(20),
                        child: SentenceBuilder(
                          words: const ['I', 'think', 'I', 'can'],
                          bankOrder: const [3, 1, 2, 0],
                          chosen: chosen,
                          enabled: enabled,
                          onChanged: (value) => setState(() => chosen = value),
                        ));
                  })))));
      await tester.pumpAndSettle();
      final sentence = find.byKey(const Key('sentence_drop_area'));
      await moveWord(tester, 'bank_word_0', tester.getCenter(sentence));
      expect(chosen, [0]);
      expect(find.byKey(const Key('bank_word_2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('bank_word_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bank_word_2')));
      await tester.pumpAndSettle();
      final first = tester.getRect(find.byKey(const Key('sentence_word_0')));
      await moveWord(
          tester, 'sentence_word_2', Offset(first.left + 4, first.center.dy));
      expect(chosen, [2, 0, 1]);
      final last = tester.getRect(find.byKey(const Key('sentence_word_1')));
      await moveWord(
          tester, 'sentence_word_2', Offset(last.right - 4, last.center.dy));
      expect(chosen, [0, 1, 2]);
      // Releasing a held word in place must not append it to the sentence.
      await moveWord(tester, 'sentence_word_0',
          tester.getCenter(find.byKey(const Key('sentence_word_0'))));
      expect(chosen, [0, 1, 2]);
      await moveWord(tester, 'sentence_word_0',
          tester.getCenter(find.byKey(const Key('word_bank_drop_area'))));
      expect(chosen, [1, 2]);
      expect(find.byKey(const Key('bank_word_0')), findsOneWidget);
      rebuild(() => enabled = false);
      await tester.pumpAndSettle();
      await moveWord(tester, 'bank_word_0', tester.getCenter(sentence));
      expect(chosen, [1, 2]);
      expect(tester.takeException(), isNull);
    });
  }
}
