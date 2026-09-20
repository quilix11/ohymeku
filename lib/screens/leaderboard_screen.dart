// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // TOP BLUE AREA
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // DIAMOND ICON
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.diamond_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Діамантова ліга', // Diamond league
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Топ-3 переходять далі • 2 дні', // Top 3 progress • 2 days
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'ЗОНА ПІДВИЩЕННЯ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  
                  // LIST OF USERS
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      children: [
                        _LeaderboardRow(rank: 1, initial: 'М', name: 'Максим', xp: 3820, avatarColor: AppColors.winGold),
                        _LeaderboardRow(rank: 2, initial: 'С', name: 'Софія', xp: 3610, avatarColor: AppColors.textHint),
                        _LeaderboardRow(rank: 3, initial: 'Д', name: 'Данило', xp: 3345, avatarColor: Color(0xFFC8824D)), // Bronze
                        
                        // Current User Highlighted
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: _LeaderboardRow(rank: 4, initial: 'О', name: 'Олена (ти)', xp: 3180, avatarColor: AppColors.primary, isHighlight: true),
                        ),
                        const SizedBox(height: 8),
                        
                        _LeaderboardRow(rank: 5, initial: 'А', name: 'Артем', xp: 2940, avatarColor: AppColors.secondary),
                        _LeaderboardRow(rank: 6, initial: 'М', name: 'Марія', xp: 2710, avatarColor: AppColors.bossPurple),
                        _LeaderboardRow(rank: 7, initial: 'І', name: 'Ігор', xp: 1980, avatarColor: AppColors.bossRed),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String initial;
  final String name;
  final int xp;
  final Color avatarColor;
  final bool isHighlight;

  const _LeaderboardRow({
    required this.rank,
    required this.initial,
    required this.name,
    required this.xp,
    required this.avatarColor,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isHighlight ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isHighlight ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.flash_on_rounded, color: AppColors.winGold, size: 16),
          const SizedBox(width: 4),
          Text(
            '$xp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isHighlight ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
