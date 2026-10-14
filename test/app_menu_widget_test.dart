import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dialect_duel/main.dart';
import 'package:dialect_duel/services/settings_service.dart';
import 'package:dialect_duel/services/progress_service.dart';
import 'package:dialect_duel/screens/reading_screen.dart';
import 'package:dialect_duel/screens/settings_screen.dart';

Future<void> menuItem(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(const Key('app_menu_button')));
  await tester.pumpAndSettle();
  final item = find.byKey(Key(key));
  await tester.scrollUntilVisible(item, 180,
      scrollable: find
          .descendant(
              of: find.byType(Drawer), matching: find.byType(Scrollable))
          .first);
  await Scrollable.ensureVisible(tester.element(item), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(320, 568), const Size(812, 375)]) {
    testWidgets(
        'side menu opens teacher scenes and reading at $size with large text',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'has_taken_placement': true,
        'tts_enabled': false,
        'animations_enabled': false,
        'text_scale': 2.0
      });
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => call.method == 'getVoices' ? <dynamic>[] : 1);
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null));
      final settings = SettingsService();
      await settings.load();
      addTearDown(settings.dispose);
      final progress = ProgressService();
      await progress.initialize();
      await tester
          .pumpWidget(DialectDuelApp(settings: settings, progress: progress));
      await tester.pumpAndSettle();
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.isDark, false);
      expect(find.text('Розмови поруч'), findsNothing);
      expect(find.byKey(const Key('free_chat_j12')), findsNothing);
      await menuItem(tester, 'menu_chat_j12');
      expect(find.text('Придумай історію'), findsOneWidget);
      expect(find.text('Клуб допитливих'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await menuItem(tester, 'menu_reading');
      expect(find.byType(ReadingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Налаштування'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Автоматична тема'), findsNothing);
      expect(find.text('Вигляд'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app_menu_button')));
      await tester.pumpAndSettle();
      final generator = find.byKey(const Key('menu_character_generation'));
      await tester.scrollUntilVisible(generator, 200,
          scrollable: find
              .descendant(
                  of: find.byType(Drawer), matching: find.byType(Scrollable))
              .first);
      expect(generator, findsOneWidget);
      await tester.tap(find.byTooltip('Закрити меню'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
