import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'services/recipe_service.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/manual_verify_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

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
      classifierService: GeminiService(
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
      ),
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
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: startScreen,
        );
      },
    );
  }
}
