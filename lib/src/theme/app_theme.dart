import 'package:flutter/material.dart';

// Vibrant earthy colors from backup
const Color kPrimary = Color(0xFF8B7355);    // Warm Brown
const Color kPrimaryLight = Color(0xFFA89070); // Light Warm Brown
const Color kSecondary = Color(0xFFC17A4A);  // Terracotta Orange
const Color kAccent = Color(0xFF6B5D4F);     // Charcoal
const Color kBackground = Color(0xFFFAF8F5); // Paper Cream
const Color kSurface = Color(0xFFFFFFFF);    // White
const Color kText = Color(0xFF3C3C3C);       // Ink Dark
const Color kTextLight = Color(0xFF9A8B7E);  // Caption Gray
const Color kDivider = Color(0xFFE0D5C5);    // Light Beige
const Color kMuted = Color(0xFF7A6958);      // Muted
const Color kSuccess = Color(0xFFD4E5D0);     // Herb Sage

const Color kDarkBackground = Color(0xFF1E1A16);
const Color kDarkSurface = Color(0xFF2C251F);
const Color kDarkSurfaceElevated = Color(0xFF352D26);
const Color kDarkText = Color(0xFFE8DCCF);
const Color kDarkTextLight = Color(0xFFB8AA9A);
const Color kDarkDivider = Color(0xFF473D34);

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: kPrimary,
    secondary: kSecondary,
    tertiary: kAccent,
    surface: kSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: kText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackground,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: kText),
      titleTextStyle: TextStyle(
        color: kText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kMuted,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kDivider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F0E6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      labelStyle: const TextStyle(color: kTextLight),
      hintStyle: const TextStyle(color: kMuted),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: kText,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: kText,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: kText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: kText,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: kText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: kTextLight,
        height: 1.4,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: kPrimaryLight,
    secondary: kSecondary,
    tertiary: kAccent,
    surface: kDarkSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: kDarkText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kDarkBackground,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: kDarkText),
      titleTextStyle: TextStyle(
        color: kDarkText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimaryLight,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kDarkTextLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: kDarkSurfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kDarkDivider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkSurfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDarkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDarkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryLight, width: 2),
      ),
      labelStyle: const TextStyle(color: kDarkTextLight),
      hintStyle: const TextStyle(color: kDarkTextLight),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: kDarkText,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: kDarkText,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: kDarkText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kDarkText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kDarkText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: kDarkText,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: kDarkText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: kDarkTextLight,
        height: 1.4,
      ),
    ),
  );
}