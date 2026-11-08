import 'dart:async';

import 'package:dialect_duel/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pose = ValueKey('meku_dance_pose');

  for (final reducedMotion in [false, true]) {
    testWidgets('Meku greets and finishes the intro once ($reducedMotion)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var completed = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: reducedMotion,
                textScaler: const TextScaler.linear(2)),
            child: child!),
        home: SplashScreen(
          animationsEnabled: true,
          onIntroFinished: () => completed++,
          onSpeakingChanged: (_) {},
        ),
      ));
      expect(find.text('Hi! Ready for an adventure?'), findsOneWidget);
      final initial =
          tester.widget<Transform>(find.byKey(pose)).transform.clone();
      await tester.pump(const Duration(milliseconds: 280));
      final moved = tester.widget<Transform>(find.byKey(pose)).transform;
      if (reducedMotion) {
        expect(moved, initial);
        expect(completed, 1);
      } else {
        expect(moved, isNot(initial));
        expect(completed, 0);
      }
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('voice playback keeps startup informed until the greeting ends',
      (tester) async {
    final playing = Completer<void>();
    final changes = <bool>[];
    final spoken = <String>[];
    const channel = MethodChannel('flutter_tts');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVoices') {
        return [
          {'name': 'Local English', 'locale': 'en-US'}
        ];
      }
      if (call.method == 'speak') {
        spoken.add(call.arguments as String);
        await playing.future;
      }
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(
        animationsEnabled: false,
        onIntroFinished: () {},
        onSpeakingChanged: changes.add,
      ),
    ));
    final play = find.byTooltip('Послухати привітання Meku');
    await tester.tap(play);
    await tester.pump();
    expect(changes, [true]);
    expect(spoken, ['Hi! Ready for an adventure?']);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    playing.complete();
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash uses separate artwork for portrait and wide layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 820);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(
        animationsEnabled: false,
        onIntroFinished: () {},
        onSpeakingChanged: (_) {},
      ),
    ));

    Finder artwork(String file) => find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == 'assets/images/$file');
    expect(artwork('meku_splash_pass_portrait.webp'), findsOneWidget);
    expect(tester.getCenter(find.text('Ohymeku')).dy,
        lessThan(tester.getCenter(find.byKey(pose)).dy));

    tester.view.physicalSize = const Size(1100, 700);
    await tester.pumpAndSettle();
    expect(artwork('meku_splash_pass.webp'), findsOneWidget);
    expect(tester.getCenter(find.byKey(pose)).dx,
        lessThan(tester.getCenter(find.text('Ohymeku')).dx));
    expect(tester.takeException(), isNull);
  });
}
