// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final ProgressService progress;
  final SettingsService settings;
  const ProfileScreen({super.key, required this.progress, required this.settings});

  @override
  Widget build(BuildContext context) {
    final profile = progress.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // TOP GREEN AREA
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(settings: settings),
                          ));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // AVATAR
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                    ),
                    child: const Center(
                      child: Text('O', style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Олена',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const Text(
                    '@olena_boss',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.winGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.emoji_events, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Приєдналась у 2026',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // WHITE OVERLAP CARD
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -5), blurRadius: 10)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // STATS GRID
                    Row(
                      children: [
                        Expanded(child: _StatBox(icon: '🔥', iconColor: AppColors.bossRed, title: '${profile.streakDays}', subtitle: 'СЕРІЯ')),
                        const SizedBox(width: 16),
                        Expanded(child: _StatBox(icon: '⚡', iconColor: AppColors.winGold, title: '${profile.xp}', subtitle: 'ВСЬОГО XP')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatBox(icon: '🏆', iconColor: AppColors.secondary, title: 'Діам...', subtitle: 'ЛІГА')),
                        const SizedBox(width: 16),
                        Expanded(child: _StatBox(icon: '🏅', iconColor: AppColors.bossPurple, title: '9', subtitle: 'ТОП-3')),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    const Text(
                      'ДОСЯГНЕННЯ', // ACHIEVEMENTS
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    // ACHIEVEMENTS SCROLL
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _AchievementBadge(color: AppColors.bossRed, icon: Icons.sports_kabaddi, label: 'Мисливець'),
                          _AchievementBadge(color: AppColors.winGold, icon: Icons.workspace_premium, label: 'Чемпіон'),
                          _AchievementBadge(color: AppColors.secondary, icon: Icons.shield_moon, label: 'Захисник'),
                          _AchievementBadge(color: AppColors.bossPurple, icon: Icons.gps_fixed, label: 'Снайпер'),
                          _AchievementBadge(color: AppColors.borderDark, icon: Icons.lock, label: 'Зачинено'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _StatBox({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault, width: 2),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 24, color: iconColor)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
            ],
          )
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _AchievementBadge({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
