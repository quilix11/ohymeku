import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/screens/main_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/theme/app_theme.dart';

void main() {
  for (final (size, scale) in [
    (const Size(375, 812), 1.0),
    (const Size(320, 568), 2.0),
  ]) {
    testWidgets('Meku keeps keyboard focus at $size and text scale $scale',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'tts_enabled': false,
        'has_taken_placement': true,
      });
      final settings = SettingsService();
      await settings.load();
      final progress = ProgressService();
      await progress.initialize();
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: MainScreen(settings: settings, progress: progress),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('meku_launcher')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final editor = tester.state<EditableTextState>(find.byType(EditableText));
      expect(editor.widget.focusNode.hasFocus, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = const FakeViewPadding(top: 24);
      await tester.pumpAndSettle();
      expect(tester.state<EditableTextState>(find.byType(EditableText)),
          same(editor));
      expect(editor.widget.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      // Send input through the existing keyboard connection, without the
      // automatic refocusing that tester.enterText would perform.
      tester.testTextInput.enterText('Привіт, Meku!');
      await tester.pumpAndSettle();
      expect(editor.widget.controller.text, 'Привіт, Meku!');
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      await tester.pumpAndSettle();
      expect(tester.state<EditableTextState>(find.byType(EditableText)),
          same(editor));
      expect(editor.widget.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
