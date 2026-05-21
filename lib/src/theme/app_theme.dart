import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Vibrant earthy colors from backup
const Color kPrimary = Color(0xFF5D4037);    // Modern Warm Brown
const Color kPrimaryLight = Color(0xFF8A6B55); // Modern Light Warm Brown
const Color kSecondary = Color(0xFFD9643E);  // Modern Terracotta Orange
const Color kAccent = Color(0xFF5A3D31);     // Dark Charcoal
const Color kBackground = Color(0xFFFBF8F0); // Soft Off-White
const Color kSurface = Color(0xFFFFFFFF);    // White
const Color kText = Color(0xFF2E2E2E);       // Near Black
const Color kTextLight = Color(0xFF8C7B6B);  // Muted Gray
const Color kDivider = Color(0xFFE2D7C5);    // Light Beige
const Color kMuted = Color(0xFF9A8B7E);      // Muted
const Color kSuccess = Color(0xFFA8D5BA);     // Light Green
// Additional colors for improved UI
const Color kError = Color(0xFFE57373); // Soft Red for errors
const Color kErrorDark = Color(0xFFB71C1C);
const Color kAccentDark = Color(0xFF8A7A6C); // Dark mode accent variant
const Color kSecondaryLight = Color(0xFFD99A6F); // Dark mode secondary variant
const Color kDarkSuccess = Color(0xFF2E7D32); // Dark mode success variant

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
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.lora(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: kText,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.lora(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: kText,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: kText,
      ),
      titleLarge: GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kText,
      ),
      titleMedium: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kText,
      ),
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16,
        color: kText,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14,
        color: kText,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12,
        color: kTextLight,
        height: 1.5,
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
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.lora(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: kDarkText,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.lora(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: kDarkText,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: kDarkText,
      ),
      titleLarge: GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kDarkText,
      ),
      titleMedium: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kDarkText,
      ),
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16,
        color: kDarkText,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14,
        color: kDarkText,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12,
        color: kDarkTextLight,
        height: 1.5,
      ),
    ),
  );
}