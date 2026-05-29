import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'services/recipe_service.dart';
import 'services/preferences_service.dart';
import 'services/sound_service.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scan_screen.dart';
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
    debugPrint('[App] initState called');
    super.initState();
    _loadPreferences();
    debugPrint('[App] Creating appState');
    appState = AppState(
      classifierService: GeminiService(
        apiKey: 'AIzaSyDagI2DoJllJumvfV2pZWYuJNwoFrw381A',
      ),
      recipeService: RecipeService(),
    );
    debugPrint('[App] appState created');
    // Listen to appState changes to trigger rebuild
    appState.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadPreferences() async {
    debugPrint('[App] Loading preferences');
    await PreferencesService.loadPreferences();
    await SoundService.init();
    setState(() {
      isDarkMode = PreferencesService.isDarkMode;
      _preferencesLoaded = true;
    });
    debugPrint('[App] Preferences loaded');
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[App] Build called');
    if (!_preferencesLoaded) {
      debugPrint('[App] Preferences not loaded yet');
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    debugPrint('[App] Preferences loaded, checking appState.isReady=${appState.isReady}');
    final Widget startScreen;
    if (!appState.isReady) {
      debugPrint('[App] appState not ready yet');
      startScreen = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (appState.isSignedIn) {
      debugPrint('[App] User signed in, showing HomeScreen');
      startScreen = HomeScreen(
        appState: appState,
        isDarkMode: isDarkMode,
        onThemeChanged: (value) async {
          setState(() => isDarkMode = value);
          await PreferencesService.setDarkMode(value);
        },
      );
    } else if (appState.authFailed) {
      debugPrint('[App] Auth failed, showing HomeScreen in guest mode');
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
      debugPrint('[App] Not signed in, showing LoginScreen');
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
