import 'package:flutter/material.dart';

// Legacy names retained for small reusable components.
class AppColors {
  // Milk and deep violet, with solid backgrounds and readable surface steps.
  static const background = Color(0xFFF7F6FF);
  static const backgroundDark = Color(0xFF191334);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF282044);

  static const primary = Color(0xFF49319A);
  static const primaryDark = Color(0xFF2D1B78);

  static const secondary = Color(0xFFEDE9FA);
  static const secondaryDark = Color(0xFF6A598F);

  static const bossRed = Color(0xFFD97777);
  static const bossRedDark = Color(0xFF9E4E4E);

  static const bossPurple = primary;
  static const bossPurpleDark = primaryDark;

  static const winGold = Color(0xFFE6C153);
  static const winGoldDark = Color(0xFFA88931);

  static const trustFill = primary;
  static const trustShadow = primaryDark;
  static const trustBg = Color(0xFFEAE5F7);

  static const patienceFill = winGold;
  static const patienceShadow = winGoldDark;
  static const patienceBg = trustBg;

  static const textPrimary = Color(0xFF281968);
  static const textPrimaryDark = Color(0xFFF7F6FF);

  static const textSecondary = Color(0xFF69617D);
  static const textHint = textSecondary;

  static const textOnPrimary = Colors.white;

  static const bubbleNpc = surface;
  static const bubbleNpcBorder = Color(0xFFDED8EC);

  static const bubblePlayer = Color(0xFFEAE5F7);
  static const bubblePlayerBorder = Color(0xFFC9BFDF);

  static const coachingBg = secondary;
  static const coachingBorder = Color(0xFFDED8EC);
  static const coachingText = Color(0xFF44365F);

  static const heartActive = bossRed;
  static const heartEmpty = Color(0xFFE4DEEE);

  static const micFill = primary;
  static const micShadow = primaryDark;

  static const borderDefault = Color(0xFFDED8EC);
  static const borderDark = Color(0xFF625573);

  static const emotionNeutral = secondary;
  static const emotionSuspicious = winGold;
  static const emotionAngry = bossRed;
  static const emotionSatisfied = primary;

  static const loseRed = bossRed;
  static const loseRedDark = bossRedDark;
}

/// Shared visual tokens. Transparency applies to surfaces, never their content.
/// Solid milk/violet surfaces keep both themes calm and consistent.
class AppVisuals {
  static const radiusSmall = 12.0;
  static const radiusControl = 16.0;
  static const radiusCard = 22.0;

  static Color panelColor(BuildContext context, {bool rose = false}) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final fill =
        rose ? Color.lerp(c.surface, c.secondaryContainer, .25)! : c.surface;
    return fill.withValues(
        alpha: theme.brightness == Brightness.dark ? .34 : .46);
  }

  static Color panelBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.outline.withValues(alpha: .22)
        : Colors.white.withValues(alpha: .64);
  }

  static List<BoxShadow> panelShadows(BuildContext context) => const [];

  static BoxDecoration panelDecoration(BuildContext context,
      {bool rose = false, double radius = radiusCard}) {
    final fill = panelColor(context, rose: rose);
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: panelBorder(context), width: .7),
      boxShadow: panelShadows(context),
    );
  }
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
      primary: dark ? const Color(0xFFC5B5FF) : AppColors.primaryDark);
  final scheme = seedScheme.copyWith(
    onPrimary: dark ? const Color(0xFF251457) : Colors.white,
    primaryContainer: dark ? const Color(0xFF3B2C63) : const Color(0xFFE9E3FA),
    onPrimaryContainer:
        dark ? const Color(0xFFEAE2FF) : const Color(0xFF302066),
    secondary: dark ? const Color(0xFFC5B5E3) : const Color(0xFF69538D),
    secondaryContainer:
        dark ? const Color(0xFF35294D) : const Color(0xFFEDE7F7),
    onSecondaryContainer:
        dark ? const Color(0xFFEEE6FA) : const Color(0xFF4C3769),
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
    onSurfaceVariant: dark ? const Color(0xFFC8BFD9) : AppColors.textSecondary,
    outline: dark ? const Color(0xFF9285AB) : const Color(0xFF9186A6),
    outlineVariant: dark ? const Color(0xFF4C3F64) : const Color(0xFFDFD9EC),
    surfaceContainerLowest:
        dark ? const Color(0xFF17112B) : const Color(0xFFFCFBFF),
    surfaceContainerLow:
        dark ? const Color(0xFF211937) : const Color(0xFFF3F0FB),
    surfaceContainer: dark ? const Color(0xFF2B2144) : const Color(0xFFEEEAF7),
    surfaceContainerHigh:
        dark ? const Color(0xFF35294F) : const Color(0xFFE8E2F2),
    surfaceContainerHighest:
        dark ? const Color(0xFF403359) : const Color(0xFFE0D8ED),
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
            fontSize: 30,
            height: 1.16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
            color: scheme.onSurface),
        headlineMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            color: scheme.onSurface),
        titleLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface),
        titleMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w600,
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

  final glassSurface = scheme.surface.withValues(alpha: dark ? .44 : .55);
  final softOutline = scheme.outlineVariant.withValues(alpha: dark ? .45 : .48);
  final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppVisuals.radiusControl));
  final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppVisuals.radiusCard),
      side: BorderSide(
          color: dark ? softOutline : Colors.white.withValues(alpha: .65),
          width: .7));

  return base.copyWith(
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: glassSurface,
      selectedColor: scheme.primaryContainer.withValues(alpha: .62),
      labelStyle: TextStyle(color: scheme.onSurface, fontFamily: 'Manrope'),
      side: BorderSide(color: softOutline),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    scaffoldBackgroundColor:
        dark ? AppColors.backgroundDark : AppColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 50),
            elevation: 0,
            shadowColor: scheme.primary.withValues(alpha: .16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: BorderSide.none,
            shape: controlShape,
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: glassSurface,
            side: BorderSide(color: scheme.primary.withValues(alpha: .32)),
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: controlShape)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 50),
            foregroundColor: scheme.onPrimary,
            backgroundColor: scheme.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: scheme.primary.withValues(alpha: .16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: controlShape)),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassSurface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppVisuals.radiusControl),
            borderSide: BorderSide(color: softOutline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppVisuals.radiusControl),
            borderSide: BorderSide(color: softOutline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppVisuals.radiusControl),
            borderSide: BorderSide(color: scheme.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            shape: controlShape,
            side: BorderSide.none)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: Colors.transparent,
            foregroundColor: scheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: controlShape,
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700))),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
    progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppVisuals.radiusSmall)),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface.withValues(alpha: .97),
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scheme.shadow.withValues(alpha: .38),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)))),
    dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface.withValues(alpha: .97),
        surfaceTintColor: Colors.transparent,
        shape: cardShape),
    drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface.withValues(alpha: .96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(32)))),
    popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface.withValues(alpha: .97),
        surfaceTintColor: Colors.transparent,
        shape: controlShape),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, shape: controlShape),
    listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: controlShape,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: .65)),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: glassSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
            fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w600))),
    cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: dark ? .14 : .06),
        surfaceTintColor: Colors.transparent,
        color: glassSurface,
        margin: EdgeInsets.zero,
        shape: cardShape),
  );
}
