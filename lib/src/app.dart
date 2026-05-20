import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'services/recipe_service.dart';
import 'services/preferences_service.dart';
import 'services/sound_service.dart';
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
  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    appState = AppState(
      classifierService: GeminiService(
        apiKey: 'AIzaSyDagI2DoJllJumvfV2pZWYuJNwoFrw381A',
      ),
      recipeService: RecipeService(),
    );
  }

  Future<void> _loadPreferences() async {
    await PreferencesService.loadPreferences();
    await SoundService.init();
    setState(() {
      isDarkMode = PreferencesService.isDarkMode;
      _preferencesLoaded = true;
    });
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_preferencesLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final Widget startScreen;
    if (!appState.isReady) {
      startScreen = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (appState.isSignedIn) {
      startScreen = HomeScreen(
        appState: appState,
        isDarkMode: isDarkMode,
        onThemeChanged: (value) async {
          setState(() => isDarkMode = value);
          await PreferencesService.setDarkMode(value);
        },
      );
    } else if (appState.authFailed) {
      // If auth failed, show home screen in guest mode
      startScreen = HomeScreen(
        appState: appState,
        isDarkMode: isDarkMode,
        onThemeChanged: (value) async {
          setState(() => isDarkMode = value);
          await PreferencesService.setDarkMode(value);
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
  }
}
