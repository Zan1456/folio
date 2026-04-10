import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio/theme/observer.dart';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dev note: All of these could be constant variables, but this is better for
  //           development (you don't have to hot-restart)

  static const String _defaultFontFamily = "Montserrat";

  // Material You Expressive shape constants
  static const double _expressiveRadius = 28.0;
  static const double _cardRadius = 24.0;
  static const double _buttonRadius = 50.0; // pill shape
  static const double _inputRadius = 16.0;

  static Color? _paletteAccentLight(CorePalette? palette) =>
      palette != null ? Color(palette.primary.get(70)) : null;
  static Color? _paletteHighlightLight(CorePalette? palette) =>
      palette != null ? Color(palette.neutral.get(100)) : null;
  static Color? _paletteBackgroundLight(CorePalette? palette) =>
      palette != null ? Color(palette.neutral.get(95)) : null;

  static Color? _paletteAccentDark(CorePalette? palette) =>
      palette != null ? Color(palette.primary.get(80)) : null;
  static Color? _paletteBackgroundDark(CorePalette? palette) =>
      palette != null ? Color(palette.neutralVariant.get(10)) : null;
  static Color? _paletteHighlightDark(CorePalette? palette) =>
      palette != null ? Color(palette.neutralVariant.get(20)) : null;

  static Map<String, TextTheme?> googleFontsMap = {
    "Montserrat": GoogleFonts.montserratTextTheme(),
    "Figtree": GoogleFonts.figtreeTextTheme(),
  };

  // Light Theme
  static ThemeData lightTheme(BuildContext context, {CorePalette? palette}) {
    var lightColors = AppColors.fromBrightness(Brightness.light);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    AccentColor accentColor = settings.accentColor;
    final customAccentColor =
        accentColor == AccentColor.custom ? settings.customAccentColor : null;
    Color accent = customAccentColor ??
        accentColorMap[accentColor] ??
        const Color(0x00000000);

    if (accentColor == AccentColor.adaptive) {
      final userSeed = settings.adaptiveSeedColor;
      if (userSeed != null) {
        accent = userSeed;
      } else if (palette != null) {
        accent = _paletteAccentLight(palette)!;
      }
    } else {
      palette = null;
    }

    Color backgroundColor = (accentColor == AccentColor.custom
            ? settings.customBackgroundColor
            : _paletteBackgroundLight(palette)) ??
        lightColors.background;
    Color highlightColor = (accentColor == AccentColor.custom
            ? settings.customHighlightColor
            : _paletteHighlightLight(palette)) ??
        lightColors.highlight;
    Color textColor = lightColors.text;

    Color newSecondary = (accentColor == AccentColor.adaptive ||
                accentColor == AccentColor.custom ||
                accentColor == AccentColor.ogfilc) ||
            !settings.newColors
        ? accent
        : ColorsUtils().darken(accent, amount: 0.4);
    Color newTertiary = (accentColor == AccentColor.adaptive ||
                accentColor == AccentColor.custom ||
                accentColor == AccentColor.ogfilc) ||
            !settings.newColors
        ? accent
        : ColorsUtils().darken(accent, amount: 0.4);

    // Material You Expressive container colors (light)
    Color primaryContainer = accent.withValues(alpha: 0.15);
    Color onPrimaryContainer = ColorsUtils().darken(accent, amount: 0.35);
    Color secondaryContainer = newSecondary.withValues(alpha: 0.12);
    Color onSecondaryContainer =
        ColorsUtils().darken(newSecondary, amount: 0.4);
    Color tertiaryContainer = newTertiary.withValues(alpha: 0.10);
    Color onTertiaryContainer = ColorsUtils().darken(newTertiary, amount: 0.45);
    Color surfaceContainerHighest =
        ColorsUtils().darken(highlightColor, amount: 0.04);

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: _defaultFontFamily,
      textTheme: !settings.titleOnlyFont
          ? (googleFontsMap[settings.fontFamily]?.apply(bodyColor: textColor) ??
              const TextTheme().apply(bodyColor: textColor))
          : null,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: lightColors.filc,
      dividerColor: const Color(0x00000000),
      colorScheme: ColorScheme(
        primary: accent,
        onPrimary:
            (accent.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                .withValues(alpha: .9),
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: newSecondary,
        onSecondary: (newSecondary.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white)
            .withValues(alpha: .9),
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: newTertiary,
        onTertiary:
            (newTertiary.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                .withValues(alpha: .9),
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        brightness: Brightness.light,
        error: lightColors.red,
        onError: Colors.white.withValues(alpha: .9),
        surface: highlightColor,
        onSurface: Colors.black.withValues(alpha: .9),
        onSurfaceVariant: Colors.black.withValues(alpha: .6),
        outline: accent.withValues(alpha: 0.3),
        outlineVariant: Colors.black.withValues(alpha: 0.12),
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerHigh: highlightColor,
        surfaceContainer: backgroundColor,
        surfaceContainerLow: backgroundColor,
        surfaceTint: accent,
      ),
      shadowColor: lightColors.shadow.withValues(alpha: .5),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        centerTitle: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: _defaultFontFamily,
        ),
      ),
      indicatorColor: accent,
      iconTheme: IconThemeData(color: lightColors.text.withValues(alpha: .75)),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: accent.withValues(
            alpha: accentColor == AccentColor.adaptive ? 0.5 : 0.85),
        indicatorShape: const StadiumBorder(),
        iconTheme:
            WidgetStateProperty.all(IconThemeData(color: lightColors.text)),
        backgroundColor: highlightColor,
        labelTextStyle: WidgetStateProperty.all(TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: lightColors.text.withValues(alpha: 0.8),
        )),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80.0,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: highlightColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_expressiveRadius),
            topRight: Radius.circular(_expressiveRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_expressiveRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer,
        shape: const StadiumBorder(),
        elevation: 0,
        labelStyle: TextStyle(
          color: onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor:
            accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: accent.withValues(alpha: .25),
        activeTrackColor: accent,
        thumbColor: accent,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      expansionTileTheme: ExpansionTileThemeData(iconColor: accent),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: ColorsUtils().darken(backgroundColor, amount: 0.12),
        contentTextStyle: TextStyle(color: textColor),
      ),
      cardColor: highlightColor,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Provider.of<ThemeModeObserver>(context, listen: false)
                .updateNavbarColor
            ? backgroundColor
            : null,
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme(BuildContext context, {CorePalette? palette}) {
    var darkColors = AppColors.fromBrightness(Brightness.dark);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    AccentColor accentColor = settings.accentColor;
    final customAccentColor =
        accentColor == AccentColor.custom ? settings.customAccentColor : null;
    Color accent = customAccentColor ??
        accentColorMap[accentColor] ??
        const Color(0x00000000);

    if (accentColor == AccentColor.adaptive) {
      final userSeed = settings.adaptiveSeedColor;
      if (userSeed != null) {
        accent = userSeed;
      } else if (palette != null) {
        accent = _paletteAccentDark(palette)!;
      }
    } else {
      palette = null;
    }

    Color backgroundColor = (accentColor == AccentColor.custom
            ? settings.customBackgroundColor
            : _paletteBackgroundDark(palette)) ??
        darkColors.background;
    Color highlightColor = (accentColor == AccentColor.custom
            ? settings.customHighlightColor
            : _paletteHighlightDark(palette)) ??
        darkColors.highlight;
    Color textColor = darkColors.text;

    Color newSecondary = (accentColor == AccentColor.adaptive ||
                accentColor == AccentColor.custom ||
                accentColor == AccentColor.ogfilc) ||
            !settings.newColors
        ? accent
        : ColorsUtils().lighten(accent, amount: 0.22);
    Color newTertiary = (accentColor == AccentColor.adaptive ||
                accentColor == AccentColor.custom ||
                accentColor == AccentColor.ogfilc) ||
            !settings.newColors
        ? accent
        : ColorsUtils().darken(accent,
            amount: 0.1); // dark mode: tertiary is way darker than secondary

    // Material You Expressive container colors (dark)
    Color primaryContainer = accent.withValues(alpha: 0.20);
    Color onPrimaryContainer = ColorsUtils().lighten(accent, amount: 0.20);
    Color secondaryContainer = newSecondary.withValues(alpha: 0.15);
    Color onSecondaryContainer =
        ColorsUtils().lighten(newSecondary, amount: 0.15);
    Color tertiaryContainer = newTertiary.withValues(alpha: 0.12);
    Color onTertiaryContainer =
        ColorsUtils().lighten(newTertiary, amount: 0.25);
    Color surfaceContainerHighest =
        ColorsUtils().lighten(highlightColor, amount: 0.06);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: _defaultFontFamily,
      textTheme: !settings.titleOnlyFont
          ? (googleFontsMap[settings.fontFamily]?.apply(bodyColor: textColor))
          : null,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: darkColors.filc,
      dividerColor: const Color(0x00000000),
      colorScheme: ColorScheme(
        primary: accent,
        onPrimary:
            (accent.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                .withValues(alpha: .9),
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: newSecondary,
        onSecondary: (newSecondary.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white)
            .withValues(alpha: .9),
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: newTertiary,
        onTertiary:
            (newTertiary.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                .withValues(alpha: .9),
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        brightness: Brightness.dark,
        error: darkColors.red,
        onError: Colors.black.withValues(alpha: .9),
        surface: highlightColor,
        onSurface: Colors.white.withValues(alpha: .9),
        onSurfaceVariant: Colors.white.withValues(alpha: .6),
        outline: accent.withValues(alpha: 0.35),
        outlineVariant: Colors.white.withValues(alpha: 0.12),
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerHigh: highlightColor,
        surfaceContainer: backgroundColor,
        surfaceContainerLow: backgroundColor,
        surfaceTint: accent,
      ),
      shadowColor: highlightColor.withValues(alpha: .5),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        centerTitle: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: _defaultFontFamily,
        ),
      ),
      indicatorColor: accent,
      iconTheme: IconThemeData(color: darkColors.text.withValues(alpha: .75)),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: accent.withValues(
            alpha: accentColor == AccentColor.adaptive ? 0.5 : 0.85),
        indicatorShape: const StadiumBorder(),
        iconTheme:
            WidgetStateProperty.all(IconThemeData(color: darkColors.text)),
        backgroundColor: highlightColor,
        labelTextStyle: WidgetStateProperty.all(TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: darkColors.text.withValues(alpha: 0.8),
        )),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80.0,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: highlightColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_expressiveRadius),
            topRight: Radius.circular(_expressiveRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_expressiveRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer,
        shape: const StadiumBorder(),
        elevation: 0,
        labelStyle: TextStyle(
          color: onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor:
            accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: accent.withValues(alpha: .25),
        activeTrackColor: accent,
        thumbColor: accent,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      expansionTileTheme: ExpansionTileThemeData(iconColor: accent),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardColor: highlightColor,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Provider.of<ThemeModeObserver>(context, listen: false)
                .updateNavbarColor
            ? backgroundColor
            : null,
      ),
    );
  }
}
