import 'package:flutter/material.dart';

// Legacy names retained for small reusable components.
class AppColors {
  // White + sage in light mode; darker inks keep controls readable.
  static const background = Color(0xFFF8FAF5);
  static const backgroundDark = Color(0xFF191F19);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF252D25);

  static const primary = Color(0xFF838F58);
  static const primaryDark = Color(0xFF526137);

  static const secondary = Color(0xFFEEF1E8);
  static const secondaryDark = Color(0xFF57634B);

  static const bossRed = Color(0xFFD97777);
  static const bossRedDark = Color(0xFF9E4E4E);

  static const bossPurple = primary;
  static const bossPurpleDark = primaryDark;

  static const winGold = Color(0xFFE6C153);
  static const winGoldDark = Color(0xFFA88931);

  static const trustFill = primary;
  static const trustShadow = primaryDark;
  static const trustBg = Color(0xFFE7EEDD);

  static const patienceFill = winGold;
  static const patienceShadow = winGoldDark;
  static const patienceBg = trustBg;

  static const textPrimary = Color(0xFF283127);
  static const textPrimaryDark = Color(0xFFF4F4E9);

  static const textSecondary = Color(0xFF56604F);
  static const textHint = textSecondary;

  static const textOnPrimary = Colors.white;

  static const bubbleNpc = surface;
  static const bubbleNpcBorder = Color(0xFFD8DFD0);

  static const bubblePlayer = Color(0xFFE7EEDD);
  static const bubblePlayerBorder = Color(0xFFB2C09B);

  static const coachingBg = secondary;
  static const coachingBorder = Color(0xFFD8DFD0);
  static const coachingText = Color(0xFF354324);

  static const heartActive = bossRed;
  static const heartEmpty = Color(0xFFDFE5D9);

  static const micFill = primary;
  static const micShadow = primaryDark;

  static const borderDefault = Color(0xFFD8DFD0);
  static const borderDark = Color(0xFF69505A);

  static const emotionNeutral = secondary;
  static const emotionSuspicious = winGold;
  static const emotionAngry = bossRed;
  static const emotionSatisfied = primary;

  static const loseRed = bossRed;
  static const loseRedDark = bossRedDark;
}

class AppTextStyles {
  static TextStyle displayLarge = const TextStyle(
      fontFamily: 'Lora',
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -1);
  static TextStyle titleLarge = const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary);
  static TextStyle titleMedium = const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary);
  static TextStyle bodyLarge = const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      height: 1.4,
      color: AppColors.textPrimary);
  static TextStyle bodyMedium = const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      height: 1.4,
      color: AppColors.textSecondary);
  static TextStyle labelMedium = const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary);
  static TextStyle statLabel = labelMedium;
  static TextStyle coachingStyle = const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      height: 1.4,
      color: AppColors.coachingText);
  static TextStyle buttonText = const TextStyle(
      fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700);
}

ThemeData buildAppTheme() => _theme(Brightness.light);
ThemeData buildDarkTheme() => _theme(Brightness.dark);

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seedScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: dark ? AppColors.surfaceDark : AppColors.surface,
      primary: dark ? const Color(0xFFBFCC9A) : AppColors.primaryDark);
  final scheme = seedScheme.copyWith(
    onPrimary: dark ? const Color(0xFF263219) : Colors.white,
    primaryContainer: dark ? const Color(0xFF35432A) : const Color(0xFFE7EEDD),
    onPrimaryContainer:
        dark ? const Color(0xFFE1EACD) : const Color(0xFF354324),
    secondary: dark ? const Color(0xFFF1B9C5) : AppColors.secondaryDark,
    secondaryContainer: dark ? const Color(0xFF4A3039) : AppColors.secondary,
    onSecondaryContainer:
        dark ? const Color(0xFFF9D1D9) : const Color(0xFF323D2B),
    tertiary: dark ? const Color(0xFFE9CB92) : const Color(0xFF795622),
    tertiaryContainer: dark ? const Color(0xFF453A26) : const Color(0xFFF3E7CF),
    onTertiaryContainer:
        dark ? const Color(0xFFF3E7CF) : const Color(0xFF58411F),
    surface: dark ? AppColors.surfaceDark : AppColors.surface,
    error: dark ? seedScheme.error : const Color(0xFFA33D18),
    errorContainer: dark ? seedScheme.errorContainer : const Color(0xFFF9E8D2),
    onErrorContainer:
        dark ? seedScheme.onErrorContainer : const Color(0xFF6A2A0A),
    onSurface: dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    onSurfaceVariant: dark ? const Color(0xFFC1CAB8) : AppColors.textSecondary,
    outline: dark ? const Color(0xFF8E9986) : const Color(0xFF78836F),
    outlineVariant: dark ? const Color(0xFF46513E) : const Color(0xFFDBDFD2),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
  );

  // Bundled fonts keep typography available offline.
  final textTheme = base.textTheme.apply(fontFamily: 'Manrope').copyWith(
        headlineLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 32,
            height: 1.16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: scheme.onSurface),
        headlineMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: scheme.onSurface),
        titleLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface),
        titleMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface),
        bodyLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            height: 1.5,
            color: scheme.onSurface),
        bodyMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            height: 1.5,
            color: scheme.onSurfaceVariant),
      );

  return base.copyWith(
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: scheme.surface,
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(color: scheme.onSurface, fontFamily: 'Manrope'),
      side: BorderSide(color: scheme.outline, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    scaffoldBackgroundColor:
        dark ? AppColors.backgroundDark : AppColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.backgroundDark : AppColors.background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 56),
            elevation: 3,
            shadowColor: scheme.primary.withValues(alpha: .3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            side: BorderSide(color: scheme.primary, width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w800))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 56),
            backgroundColor: scheme.surface,
            side: BorderSide(color: scheme.outline, width: 2),
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: scheme.outlineVariant, width: 1.5))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700))),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
    progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary, linearTrackColor: scheme.primaryContainer),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBarrierColor: Colors.black.withValues(alpha: .5),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
            fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w600))),
    cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant, width: 1.5))),
  );
}
