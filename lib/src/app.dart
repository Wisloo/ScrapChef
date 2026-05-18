import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/mock_real_classifier.dart';
import 'services/recipe_service.dart';
import 'state/app_state.dart';

// Warm earthy solid color palette
const Color kCream = Color(0xFFF6F1E8);
const Color kTerracotta = Color(0xFFB86137);
const Color kSage = Color(0xFF58765C);
const Color kDeepBrown = Color(0xFF2D1F16);

class ScrapChefApp extends StatefulWidget {
  const ScrapChefApp({super.key});

  @override
  State<ScrapChefApp> createState() => _ScrapChefAppState();
}

class _ScrapChefAppState extends State<ScrapChefApp> {
  late final AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState(
      classifierService: MockRealClassifier(),
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
          startScreen = HomeScreen(appState: appState);
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
          primary: kTerracotta,
          secondary: kSage,
          surface: Colors.white,
          background: kCream,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: kDeepBrown,
          onBackground: kDeepBrown,
        ),
        scaffoldBackgroundColor: kCream,
        fontFamily: GoogleFonts.manrope().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: kDeepBrown),
          titleTextStyle: TextStyle(
            color: kDeepBrown,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kTerracotta,
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
            color: kDeepBrown,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: kDeepBrown,
            letterSpacing: -0.5,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kDeepBrown,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDeepBrown,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kDeepBrown,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: kDeepBrown,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: kDeepBrown,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: kDeepBrown,
            height: 1.4,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFDFBF7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: kDeepBrown.withAlpha(18),
          thickness: 1,
        ),
      ),
          home: startScreen,
        );
      },
    );
  }
}
