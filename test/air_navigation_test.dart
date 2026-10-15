import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialect_duel/theme/app_theme.dart';
import 'package:dialect_duel/widgets/air_navigation.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('slim navigation stays usable: dark=$dark scale=$scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(bottom: 34);
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          final selections = <int>[];
          var mekuOpens = 0;
          var settingsOpens = 0;
          await tester.pumpWidget(MaterialApp(
              theme: dark ? buildDarkTheme() : buildAppTheme(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: Scaffold(
                  bottomNavigationBar: AirNavigation(
                      selectedIndex: 0,
                      onSelect: selections.add,
                      onSettings: () => settingsOpens++,
                      onMeku: () => mekuOpens++))));
          await tester.pumpAndSettle();
          final panel = find.byKey(const Key('air_navigation_panel'));
          expect(tester.getSize(panel).height, lessThanOrEqualTo(56));
          expect(tester.getRect(panel).bottom, lessThanOrEqualTo(568 - 34));
          final surface = tester.widget<DecoratedBox>(find
              .ancestor(of: panel, matching: find.byType(DecoratedBox))
              .first);
          expect((surface.decoration as BoxDecoration).color!.a, lessThan(.3));
          for (final label in [
            'Пригода',
            'Слова',
            'Meku',
            'Прогрес',
            'Налаштування'
          ]) {
            expect(find.bySemanticsLabel(label), findsOneWidget);
            final control = find.descendant(
                of: find.byTooltip(label), matching: find.byType(InkWell));
            expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
            await tester.tap(control);
            await tester.pump();
          }
          expect(selections, [0, 1, 2]);
          expect(mekuOpens, 1);
          expect(settingsOpens, 1);
          expect(tester.getCenter(find.byTooltip('Meku')).dx, 160);
          expect(tester.getCenter(find.byTooltip('Налаштування')).dx,
              greaterThan(tester.getCenter(find.byTooltip('Прогрес')).dx));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}
