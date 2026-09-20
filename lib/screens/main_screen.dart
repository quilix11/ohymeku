// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/duo_app_bar.dart';
import '../widgets/duo_bottom_nav.dart';
import 'character_selection_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;

  const MainScreen({
    super.key,
    required this.settings,
    required this.progress,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_update);
    widget.settings.addListener(_update);
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.progress.removeListener(_update);
    widget.settings.removeListener(_update);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = widget.settings.isDark;
    final profile = widget.progress.profile;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
      appBar: DuoAppBar(
        streak: profile.streakDays,
        xp: profile.xp,
        hearts: profile.hearts,
        isDark: isDark,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CharacterSelectionScreen(settings: widget.settings, progress: widget.progress),
          const LeaderboardScreen(),
          ProfileScreen(settings: widget.settings, progress: widget.progress),
        ],
      ),
      bottomNavigationBar: DuoBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        isDark: isDark,
      ),
    );
  }
}
