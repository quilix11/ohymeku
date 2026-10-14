import 'package:flutter/material.dart';

// Legacy names retained for small reusable components.
class AppColors {
  // Misty sage and warm rose, with opaque inks for readable glass surfaces.
  static const background = Color(0xFFF2F3F5);
  static const backgroundDark = Color(0xFF171B1F);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF282F32);

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
  static const borderDark = Color(0xFF526259);

  static const emotionNeutral = secondary;
  static const emotionSuspicious = winGold;
  static const emotionAngry = bossRed;
  static const emotionSatisfied = primary;

  static const loseRed = bossRed;
  static const loseRedDark = bossRedDark;
}

/// Shared visual tokens. Transparency applies to surfaces, never their content.
/// Gradients and shadows provide depth without expensive backdrop filters.
class AppVisuals {
  static const radiusSmall = 14.0;
  static const radiusControl = 20.0;
  static const radiusCard = 28.0;

  static Color panelColor(BuildContext context, {bool rose = false}) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final fill =
        rose ? Color.lerp(c.surface, c.secondaryContainer, .45)! : c.surface;
    return fill.withValues(
        alpha: theme.brightness == Brightness.dark ? .88 : .84);
  }

  static Color panelBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.outline.withValues(alpha: .28)
        : Colors.white.withValues(alpha: .92);
  }

  static List<BoxShadow> panelShadows(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? .16 : .05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static BoxDecoration panelDecoration(BuildContext context,
      {bool rose = false, double radius = radiusCard}) {
    final c = Theme.of(context).colorScheme;
    final fill = panelColor(context, rose: rose);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fill, Color.lerp(fill, c.primaryContainer, .04)!],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: panelBorder(context)),
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
      primary: dark ? const Color(0xFFBFCC9A) : AppColors.primaryDark);
  final scheme = seedScheme.copyWith(
    onPrimary: dark ? const Color(0xFF263219) : Colors.white,
    primaryContainer: dark ? const Color(0xFF35432A) : const Color(0xFFE7EEDD),
    onPrimaryContainer:
        dark ? const Color(0xFFE1EACD) : const Color(0xFF354324),
    secondary: dark ? const Color(0xFFF1B9C5) : const Color(0xFF8D4D60),
    secondaryContainer:
        dark ? const Color(0xFF48313B) : const Color(0xFFF4E4E9),
    onSecondaryContainer:
        dark ? const Color(0xFFF9D1D9) : const Color(0xFF663748),
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
    outlineVariant: dark ? const Color(0xFF46584B) : const Color(0xFFD4DDD0),
    surfaceContainerLowest:
        dark ? const Color(0xFF1C2420) : const Color(0xFFFAFCF8),
    surfaceContainerLow:
        dark ? const Color(0xFF242E28) : const Color(0xFFF4F7F1),
    surfaceContainer: dark ? const Color(0xFF2B372E) : const Color(0xFFEDF2E8),
    surfaceContainerHigh:
        dark ? const Color(0xFF354138) : const Color(0xFFE6EDDF),
    surfaceContainerHighest:
        dark ? const Color(0xFF404D42) : const Color(0xFFDCE6D4),
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

  final glassSurface = scheme.surface.withValues(alpha: dark ? .88 : .82);
  final softOutline = scheme.outlineVariant.withValues(alpha: dark ? .6 : .58);
  final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppVisuals.radiusControl));
  final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppVisuals.radiusCard),
      side: BorderSide(
          color: dark ? softOutline : Colors.white.withValues(alpha: .92)));

  return base.copyWith(
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: glassSurface,
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(color: scheme.onSurface, fontFamily: 'Manrope'),
      side: BorderSide(color: softOutline),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    scaffoldBackgroundColor:
        dark ? AppColors.backgroundDark : AppColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
        backgroundColor: glassSurface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 56),
            elevation: 1,
            shadowColor: scheme.primary.withValues(alpha: .16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            side: BorderSide(color: scheme.primary.withValues(alpha: .5)),
            shape: controlShape,
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w800))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 56),
            backgroundColor: glassSurface,
            side: BorderSide(color: scheme.primary.withValues(alpha: .32)),
            textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: controlShape)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 56),
            foregroundColor: scheme.onPrimary,
            backgroundColor: scheme.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 1,
            shadowColor: scheme.primary.withValues(alpha: .16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            backgroundColor: glassSurface,
            foregroundColor: scheme.onSurface,
            shape: controlShape,
            side: BorderSide(color: softOutline.withValues(alpha: .3)))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: scheme.primaryContainer.withValues(alpha: .66),
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
        elevation: 1,
        shadowColor: scheme.shadow.withValues(alpha: dark ? .14 : .06),
        surfaceTintColor: Colors.transparent,
        color: glassSurface,
        margin: EdgeInsets.zero,
        shape: cardShape),
  );
}
