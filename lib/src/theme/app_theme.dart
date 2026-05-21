import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/ui_constants.dart';

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: UIConstants.kPrimary,
    secondary: UIConstants.kSecondary,
    tertiary: UIConstants.kAccent,
    surface: UIConstants.kSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: UIConstants.kText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: UIConstants.kBackground,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: UIConstants.kText),
      titleTextStyle: TextStyle(
        color: UIConstants.kText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: UIConstants.kPrimaryFont,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UIConstants.kPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: UIConstants.kMuted,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: UIConstants.kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: UIConstants.kDivider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F0E6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UIConstants.kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UIConstants.kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UIConstants.kPrimary, width: 2),
      ),
      labelStyle: const TextStyle(color: UIConstants.kTextLight, fontFamily: UIConstants.kPrimaryFont),
      hintStyle: const TextStyle(color: UIConstants.kMuted, fontFamily: UIConstants.kPrimaryFont),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: UIConstants.kText,
        letterSpacing: -0.5,
        height: UIConstants.kHeadlineLineHeight,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: UIConstants.kText,
        letterSpacing: -0.5,
        height: UIConstants.kSubheadlineLineHeight,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: UIConstants.kText,
        height: UIConstants.kSubheadlineLineHeight,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: UIConstants.kText,
        height: UIConstants.kBodyLineHeight,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: UIConstants.kText,
        height: UIConstants.kBodyLineHeight,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: UIConstants.kText,
        height: UIConstants.kBodyLineHeight,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: UIConstants.kText,
        height: UIConstants.kBodyLineHeight,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: UIConstants.kTextLight,
        height: UIConstants.kSmallLineHeight,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: UIConstants.kPrimaryLight,
    secondary: UIConstants.kSecondary,
    tertiary: UIConstants.kAccent,
    surface: UIConstants.kDarkSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: UIConstants.kDarkText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: UIConstants.kDarkBackground,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: UIConstants.kDarkText),
      titleTextStyle: TextStyle(
        color: UIConstants.kDarkText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: UIConstants.kPrimaryFont,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UIConstants.kPrimaryLight,
        foregroundColor: Colors.white,
        disabledBackgroundColor: UIConstants.kDarkTextLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: UIConstants.kDarkSurfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: UIConstants.kDarkDivider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: UIConstants.kDarkSurfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UIConstants.kDarkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UIConstants.kDarkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UIConstants.kPrimaryLight, width: 2),
      ),
      labelStyle: const TextStyle(color: UIConstants.kDarkTextLight, fontFamily: UIConstants.kPrimaryFont),
      hintStyle: const TextStyle(color: UIConstants.kDarkTextLight, fontFamily: UIConstants.kPrimaryFont),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: UIConstants.kDarkText,
        letterSpacing: -0.5,
        height: UIConstants.kHeadlineLineHeight,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: UIConstants.kDarkText,
        letterSpacing: -0.5,
        height: UIConstants.kSubheadlineLineHeight,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: UIConstants.kDarkText,
        height: UIConstants.kSubheadlineLineHeight,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: UIConstants.kDarkText,
        height: UIConstants.kBodyLineHeight,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: UIConstants.kDarkText,
        height: UIConstants.kBodyLineHeight,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: UIConstants.kDarkText,
        height: UIConstants.kBodyLineHeight,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: UIConstants.kDarkText,
        height: UIConstants.kBodyLineHeight,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: UIConstants.kDarkTextMuted,
        height: UIConstants.kSmallLineHeight,
      ),
    ),
  );
}