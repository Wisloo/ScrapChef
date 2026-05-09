import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/test_classifier.dart';
import 'services/mock_real_classifier.dart';
import 'services/recipe_service.dart';
import 'state/app_state.dart';

// Warm earthy solid color palette
const Color kCream = Color(0xFFFAF7F2);
const Color kTerracotta = Color(0xFFC17A4A);
const Color kSage = Color(0xFF7A9E7E);
const Color kDeepBrown = Color(0xFF3D2914);

class ScrapChefApp extends StatelessWidget {
  const ScrapChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState(
      classifierService: MockRealClassifier(),
      recipeService: RecipeService(),
    );

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
      ),
      home: HomeScreen(appState: appState),
      routes: {
        '/test': (context) => const TestClassifierScreen(),
      },
    );
  }
}
