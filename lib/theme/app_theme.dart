// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF3F7FA); // Light grayish blue background
  static const Color surface = Colors.white;
  static const Color surfaceCard = Colors.white;
  
  // Brand colors from Boss mockup
  static const Color primary = Color(0xFF63C910); // Vibrant Green from Profile/Boss
  static const Color primaryDark = Color(0xFF4FA808);
  
  static const Color secondary = Color(0xFF2CB1FE); // Diamond Blue
  static const Color secondaryDark = Color(0xFF1B9AE0);
  
  static const Color bossRed = Color(0xFFFF5252);
  static const Color bossRedDark = Color(0xFFE53939);
  static const Color bossPurple = Color(0xFFB15FEE);
  
  static const Color trustFill = Color(0xFF63C910); // green
  static const Color trustShadow = Color(0xFF4FA808);
  static const Color trustBg = Color(0xFFE5E5E5);
  static const Color patienceFill = Color(0xFFFF9600);
  static const Color patienceShadow = Color(0xFFCC7A00);
  static const Color patienceBg = Color(0xFFE5E5E5);
  
  static const Color textPrimary = Color(0xFF2C3E50); // Darker blue-gray text
  static const Color textSecondary = Color(0xFF8A9BA8);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Colors.white;
  
  static const Color bubbleNpc = Colors.white;
  static const Color bubbleNpcBorder = Color(0xFFEAEAEA);
  static const Color bubblePlayer = Color(0xFFDFF6C1);
  static const Color bubblePlayerBorder = Color(0xFFB8E086);
  
  static const Color coachingBg = Color(0xFFFFFBE6);
  static const Color coachingBorder = Color(0xFFFFD700);
  static const Color coachingText = Color(0xFF5C4A00);
  
  static const Color heartActive = Color(0xFFFF5252);
  static const Color heartEmpty = Color(0xFFE5E5E5);
  
  static const Color micFill = Color(0xFF63C910);
  static const Color micShadow = Color(0xFF4FA808);
  
  static const Color borderDefault = Color(0xFFE5E5E5);
  static const Color borderDark = Color(0xFF3C3C3C);
  
  static const Color emotionNeutral = Color(0xFF4B83CF);
  static const Color emotionSuspicious = Color(0xFFFF9600);
  static const Color emotionAngry = Color(0xFFFF5252);
  static const Color emotionSatisfied = Color(0xFF63C910);
  
  static const Color winGold = Color(0xFFFFC107);
  static const Color winGoldDark = Color(0xFFE0A800);
  static const Color loseRed = Color(0xFFFF5252);
  static const Color loseRedDark = Color(0xFFE53939);
}

class AppTextStyles {
  // Bold, rounded feeling font
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );
  static const TextStyle coachingStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.coachingText,
    height: 1.5,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      labelMedium: AppTextStyles.labelMedium,
    ),
    useMaterial3: true,
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1F24),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF262C33),
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF262C33),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: Colors.white),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: Colors.white),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: Colors.white),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF9CA3AF)),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF9CA3AF)),
    ),
    useMaterial3: true,
  );
}
