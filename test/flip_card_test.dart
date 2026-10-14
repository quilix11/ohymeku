import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/screens/vocabulary_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/widgets/flip_card.dart';

void main() {
  testWidgets('mobile flip keeps actions stable, reverses and saves review',
      (tester) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'tts_enabled': false});
    final settings = SettingsService();
    await settings.load();
    addTearDown(settings.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: VocabularyScreen(settings: settings))));
    await tester.pumpAndSettle();
    final card = settings.vocabulary.cards.first;
    final flip = find.byType(FlipCard);
    await tester.ensureVisible(flip);
    await tester.pumpAndSettle();
    final size = tester.getSize(flip);
    final actions = find.text('Знаю');
    final originalActions = tester.getRect(actions);
    await tester
        .tap(find.descendant(of: flip, matching: find.byType(InkWell)).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.binding.hasScheduledFrame, true);
    expect(tester.getSize(flip), size);
    final turningFace =
        find.descendant(of: flip, matching: find.byType(Material)).first;
    expect(tester.getRect(turningFace).width, lessThan(size.width - 1));
    // A second tap during the turn reverses smoothly back to English.
    await tester
        .tap(find.descendant(of: flip, matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
    expect(tester.widget<FlipCard>(flip).flipped, false);
    expect(tester.getRect(actions), originalActions);
    await tester
        .tap(find.descendant(of: flip, matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
    expect(tester.widget<FlipCard>(flip).flipped, true);
    expect(tester.getSize(flip), size);
    expect(tester.getRect(actions), originalActions);
    await tester.ensureVisible(actions);
    await tester.pumpAndSettle();
    await tester.tap(actions);
    await tester.pumpAndSettle();
    expect(settings.vocabulary.known, contains(card.id));
    expect(tester.widget<FlipCard>(flip).flipped, false);
    expect(tester.takeException(), isNull);
  });

  for (final systemReducedMotion in [false, true]) {
    testWidgets(
        'flip honors reduced motion at large text: $systemReducedMotion',
        (tester) async {
      var flipped = false;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MediaQuery(
        data: MediaQueryData(
            disableAnimations: systemReducedMotion,
            textScaler: const TextScaler.linear(2)),
        child: StatefulBuilder(
            builder: (context, setState) => SizedBox(
                  width: 280,
                  child: FlipCard(
                    flipped: flipped,
                    animate: systemReducedMotion,
                    onTap: () => setState(() => flipped = !flipped),
                    front: const Padding(
                        padding: EdgeInsets.all(20), child: Text('Front')),
                    back: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Translation and example on the back')),
                  ),
                )),
      ))));
      await tester.pumpAndSettle();
      await tester.tap(find
          .descendant(of: find.byType(FlipCard), matching: find.byType(InkWell))
          .first);
      await tester.pump();

      final visibility = tester.widget<Visibility>(find
          .ancestor(
              of: find.text('Translation and example on the back'),
              matching: find.byType(Visibility))
          .first);
      expect(visibility.visible, true);
      expect(tester.takeException(), isNull);
    });
  }
}
