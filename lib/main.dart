import 'dart:async';
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/settings_service.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/placement_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load .env
  await dotenv.load(fileName: '.env', isOptional: true);

  // Load settings
  final settings = SettingsService();
  await settings.load();

  // Load progress
  final progress = ProgressService();
  await progress.initialize();

  runApp(DialectDuelApp(settings: settings, progress: progress));
}

class DialectDuelApp extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  const DialectDuelApp(
      {super.key, required this.settings, required this.progress});

  @override
  State<DialectDuelApp> createState() => _DialectDuelAppState();
}

class _DialectDuelAppState extends State<DialectDuelApp>
    with WidgetsBindingObserver {
  late AppThemeMode _mode;
  late bool _animations;
  late double _textScale;
  late bool _hasTakenPlacement;
  final _lightTheme = buildAppTheme();
  final _darkTheme = buildDarkTheme();
  @override
  void initState() {
    super.initState();
    // Capture the initial values before the first settings notification.
    // Lazy initializers would read the already changed value and skip it.
    _mode = widget.settings.themeMode;
    _animations = widget.settings.animationsEnabled;
    _textScale = widget.settings.textScale;
    _hasTakenPlacement = widget.settings.hasTakenPlacement;
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.settings.restoreReminder());
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.settings.restoreReminder());
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (widget.settings.themeMode == AppThemeMode.system && mounted) {
      setState(() {});
    }
  }

  void _onSettingsChanged() {
    if (_mode == widget.settings.themeMode &&
        _animations == widget.settings.animationsEnabled &&
        _textScale == widget.settings.textScale &&
        _hasTakenPlacement == widget.settings.hasTakenPlacement) {
      return;
    }
    setState(() {
      _mode = widget.settings.themeMode;
      _animations = widget.settings.animationsEnabled;
      _textScale = widget.settings.textScale;
      _hasTakenPlacement = widget.settings.hasTakenPlacement;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.settings.isDark;
    // Update system UI to match theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Ohymeku',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      themeAnimationDuration: widget.settings.animationsEnabled
          ? const Duration(milliseconds: 220)
          : Duration.zero,
      themeAnimationCurve: Curves.easeInOutCubic,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(1) * _textScale),
              disableAnimations: MediaQuery.disableAnimationsOf(context) ||
                  !widget.settings.animationsEnabled),
          child: child!),
      home: widget.settings.hasTakenPlacement
          ? MainScreen(settings: widget.settings, progress: widget.progress)
          : PlacementScreen(
              settings: widget.settings, progress: widget.progress),
    );
  }
}
