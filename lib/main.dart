// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/settings_service.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load .env
  await dotenv.load(fileName: '.env');

  // Load settings
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
  const DialectDuelApp({super.key, required this.settings, required this.progress});

  @override
  State<DialectDuelApp> createState() => _DialectDuelAppState();
}

class _DialectDuelAppState extends State<DialectDuelApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() => setState(() {});

  @override
  void dispose() {
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
          isDark ? const Color(0xFF111827) : AppColors.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'DialectDuel',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(settings: widget.settings, progress: widget.progress),
    );
  }
}
