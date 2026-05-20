import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _darkModeKey = 'dark_mode';
  static const String _hapticFeedbackKey = 'haptic_feedback';

  static bool _isDarkMode = false;
  static bool _isHapticFeedbackEnabled = true;

  static bool get isDarkMode => _isDarkMode;
  static bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;

  /// Load preferences from storage
  static Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _isHapticFeedbackEnabled = prefs.getBool(_hapticFeedbackKey) ?? true;
  }

  /// Save dark mode preference
  static Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  /// Save haptic feedback preference
  static Future<void> setHapticFeedback(bool value) async {
    _isHapticFeedbackEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, value);
  }
}
