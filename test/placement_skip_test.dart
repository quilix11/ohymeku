import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/screens/placement_screen.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';

void main() {
  for (final started in [false, true]) {
    testWidgets(
        'skip placement persists onboarding without a score: started=$started',
        (tester) async {
      SharedPreferences.setMockInitialValues({'tts_enabled': false});
      final settings = SettingsService();
      await settings.load();
      final progress = ProgressService();
      await progress.initialize();
      final level = settings.effectiveLevel;
      await tester.pumpWidget(MaterialApp(
          home: PlacementScreen(settings: settings, progress: progress)));
      if (started) {
        await tester.tap(find.text('Почати тест'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Пропустити'));
      await tester.pumpAndSettle();
      expect(settings.hasTakenPlacement, true);
      expect(settings.learner.placement, isNull);
      expect(settings.effectiveLevel, level);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_taken_placement'), true);
      expect(tester.takeException(), isNull);
    });
  }
}
