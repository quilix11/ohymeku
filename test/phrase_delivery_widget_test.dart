import 'package:dialect_duel/models/phrase_delivery.dart';
import 'package:dialect_duel/screens/phrase_delivery_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/vocabulary_service.dart';
import 'package:dialect_duel/widgets/ohymeku_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('delivery adapts to each audience, speaks and saves a phrase',
      (tester) async {
    SharedPreferences.setMockInitialValues({'offline_mode': true});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsService();
    await settings.load();
    addTearDown(settings.dispose);
    final drill = phraseDeliveries.values.first;
    final spoken = <String>[], rates = <double>[];
    const channel = MethodChannel('flutter_tts');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVoices') {
        return [
          {'name': 'Local English', 'locale': 'en-US'}
        ];
      }
      if (call.method == 'speak') spoken.add(call.arguments as String);
      if (call.method == 'setSpeechRate') rates.add(call.arguments as double);
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        final scrollable = find.byType(Scrollable).last;
        tester.state<ScrollableState>(scrollable).position.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(finder, 100, scrollable: scrollable);
      }
      await Scrollable.ensureVisible(tester.element(finder.first),
          alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!),
      home: PhraseDeliveryScreen(settings: settings),
    ));
    await tap(find.text(drill.title));
    await tap(find.text(drill.polite.english));
    expect(find.text('Другий адресат'), findsNothing);
    await tap(find.text(drill.casual.english));
    final next = find.text('Другий адресат').hitTestable();
    expect(next, findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tap(find.text(drill.polite.english));
    await tap(find.text('Порівняти фрази'));
    final casualPanel = find.ancestor(
        of: find.text(drill.casual.english), matching: find.byType(SilkPanel));
    Finder action(String label) =>
        find.descendant(of: casualPanel, matching: find.text(label));
    await tap(action('Послухати'));
    await tap(action('Повільно'));
    expect(spoken, [drill.casual.english, drill.casual.english]);
    expect(rates.last, lessThan(rates.first));
    await tap(action('У «Мої слова»'));
    expect(find.text('У словнику'), findsOneWidget);
    final restored = VocabularyService();
    await restored.load();
    expect(restored.custom.single.word, drill.casual.english);
    expect(restored.custom.single.translation, drill.casual.translation);
    expect(tester.takeException(), isNull);
  });
}
