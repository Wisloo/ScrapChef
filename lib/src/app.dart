import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'services/gemini_service.dart';
import 'services/recipe_service.dart';
import 'services/sound_service.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/manual_verify_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

// Earthy color palette for food scrap theme
const Color kPrimary = Color(0xFF8B7355); // Warm earth brown
const Color kPrimaryLight = Color(0xFFA89070); // Light earth brown
const Color kSecondary = Color(0xFF6B8E23); // Olive green
const Color kAccent = Color(0xFFD2691E); // Chocolate orange
const Color kBackground = Color(0xFFF5F0E6); // Creamy beige
const Color kSurface = Color(0xFFFFFFFF); // White
const Color kText = Color(0xFF4A3F35); // Dark earth brown
const Color kTextLight = Color(0xFF6B5D52); // Medium earth brown
const Color kDivider = Color(0xFFE0D5C5); // Light beige

// Dark theme colors (earthy dark mode)
const Color kDarkBackground = Color(0xFF2A2520); // Dark earth brown
const Color kDarkSurface = Color(0xFF3A3530); // Dark brown surface
const Color kDarkText = Color(0xFFE8E0D8); // Light cream text
const Color kDarkTextLight = Color(0xFFB8B0A8); // Medium cream text
const Color kDarkDivider = Color(0xFF4A4540); // Dark divider

class ScrapChefApp extends StatefulWidget {
  const ScrapChefApp({super.key});

  @override
  State<ScrapChefApp> createState() => _ScrapChefAppState();
}

class _ScrapChefAppState extends State<ScrapChefApp> {
  late final AppState appState;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    appState = AppState(
      classifierService: GeminiService(), // Use GeminiService here
      recipeService: RecipeService(),
    );
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final Widget startScreen;
        if (!appState.isReady) {
          startScreen = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (appState.isSignedIn) {
          startScreen = HomeScreen(
            appState: appState,
            onThemeChanged: (value) {
              setState(() => isDarkMode = value);
            },
          );
        } else {
          startScreen = LoginScreen(appState: appState);
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ScrapChef',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              secondary: kSecondary,
              surface: kSurface,
              background: kBackground,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: kText,
              onBackground: kText,
            ),
            scaffoldBackgroundColor: kBackground,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
                color: kText,
                height: 1.4,
              ),
            ),
            cardTheme: CardThemeData(
              color: kSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: kDivider,
              thickness: 1,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: kPrimary,
              secondary: kSecondary,
              surface: kDarkSurface,
              background: kDarkBackground,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: kDarkText,
              onBackground: kDarkText,
            ),
            scaffoldBackgroundColor: kDarkBackground,
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
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
                color: kDarkText,
                height: 1.4,
              ),
            ),
            cardTheme: CardThemeData(
              color: kDarkSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: kDarkDivider,
              thickness: 1,
            ),
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: startScreen,
        );
      },
    );
  }
}
