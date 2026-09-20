// lib/screens/character_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;

  const CharacterSelectionScreen({
    super.key,
    required this.settings,
    required this.progress,
  });

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  GameCharacter _selectedBoss = GameCharacter.officer;
  bool _fightPressed = false;

  void _startGame() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => GameScreen(
          settings: widget.settings,
          progress: widget.progress,
          character: _selectedBoss,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.progress.profile;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR (Matches "ВИБІР БОСА")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ВИБІР БОСА', // "CHOOSE BOSS" in UA
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // Hearts
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, color: AppColors.heartActive, size: 16),
                      const SizedBox(width: 4),
                      Text('${profile.hearts}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.heartActive)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Diamonds / XP
                  Row(
                    children: [
                      const Icon(Icons.diamond_rounded, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 4),
                      Text('${profile.xp}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  // MAIN ACTIVE BOSS CARD (Red Card)
                  _MainBossCard(
                    character: _selectedBoss,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // BOSS LIST
                  _BossListItem(
                    title: 'Венс', // Vance
                    subtitle: 'Рівень 12',
                    iconEmoji: '👮',
                    iconColor: AppColors.bossRed,
                    isSelected: _selectedBoss == GameCharacter.officer,
                    onTap: () => setState(() => _selectedBoss = GameCharacter.officer),
                  ),
                  const SizedBox(height: 12),
                  _BossListItem(
                    title: 'Ханна', // Hannah HR
                    subtitle: 'Рівень 18',
                    iconEmoji: '👩‍💼',
                    iconColor: AppColors.bossPurple,
                    isSelected: _selectedBoss == GameCharacter.hr,
                    onTap: () => setState(() => _selectedBoss = GameCharacter.hr),
                  ),
                ],
              ),
            ),
            
            // BOTTOM FIGHT BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _fightPressed = true),
                onTapUp: (_) {
                  setState(() => _fightPressed = false);
                  _startGame();
                },
                onTapCancel: () => setState(() => _fightPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  margin: EdgeInsets.only(top: _fightPressed ? 6 : 0),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryDark, width: 2),
                    boxShadow: _fightPressed
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.primaryDark,
                              offset: const Offset(0, 6),
                              blurRadius: 0,
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      'БИТИСЯ', // "FIGHT"
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainBossCard extends StatelessWidget {
  final GameCharacter character;
  const _MainBossCard({required this.character});

  @override
  Widget build(BuildContext context) {
    final title = character == GameCharacter.officer ? 'Венс' : 'Ханна';
    final subtitle = character == GameCharacter.officer ? 'Офіцер Кордону' : 'Директорка HR';
    final emoji = character == GameCharacter.officer ? '👮' : '👩‍💼';
    final mainColor = character == GameCharacter.officer ? AppColors.bossRed : AppColors.bossPurple;
    final shadowColor = character == GameCharacter.officer ? AppColors.bossRedDark : Color(0xFF863DBE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: shadowColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 8),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star_rounded, color: AppColors.winGold, size: 24),
              Icon(Icons.star_rounded, color: AppColors.winGold, size: 24),
              Icon(Icons.star_rounded, color: AppColors.winGold, size: 24),
              Icon(Icons.star_rounded, color: Colors.white30, size: 24),
              Icon(Icons.star_rounded, color: Colors.white30, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          // Health bar
          Row(
            children: [
              const Text(
                'ЗДОРОВ\'Я БОСА',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              const Text(
                '100%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                // 100% means full white, but let's give a little empty space visually for effect if we wanted
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _BossListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconEmoji;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _BossListItem({
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDefault,
            width: 3,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(iconEmoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Stars indicator
            Row(
              children: const [
                Icon(Icons.star_rounded, color: AppColors.winGold, size: 16),
                Icon(Icons.star_rounded, color: AppColors.winGold, size: 16),
                Icon(Icons.star_rounded, color: AppColors.winGold, size: 16),
                Icon(Icons.star_rounded, color: AppColors.borderDefault, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
