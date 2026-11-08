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
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppStartup());
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<DialectDuelApp> _startup = _loadApp();
  final _lightTheme = buildAppTheme();
  final _darkTheme = buildDarkTheme();
  bool _introFinished = false;
  bool _speaking = false;

  Future<DialectDuelApp> _loadApp() async {
    final settings = SettingsService();
    final progress = ProgressService();
    try {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      await dotenv.load(fileName: '.env', isOptional: true);
      await settings.load();
      await progress.initialize();
      return DialectDuelApp(settings: settings, progress: progress);
    } catch (_) {
      settings.dispose();
      progress.dispose();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DialectDuelApp>(
        future: _startup,
        builder: (context, snapshot) {
          final app = snapshot.data;
          if (app != null && _introFinished && !_speaking) return app;
          return MaterialApp(
            title: 'Ohymeku',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: switch (app?.settings.themeMode) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              _ => ThemeMode.system,
            },
            home: SplashScreen(
              animationsEnabled: app?.settings.animationsEnabled ?? true,
              onIntroFinished: () => setState(() => _introFinished = true),
              onSpeakingChanged: (speaking) =>
                  setState(() => _speaking = speaking),
              onRetry: snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasError
                  ? () => setState(() => _startup = _loadApp())
                  : null,
            ),
          );
        },
      );
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
      themeMode: switch (_mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
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
