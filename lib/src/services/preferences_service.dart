import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _hapticFeedbackKey = 'haptic_feedback';

  static bool _isHapticFeedbackEnabled = true;

  static bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;

  /// Load preferences from storage
  static Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isHapticFeedbackEnabled = prefs.getBool(_hapticFeedbackKey) ?? true;
  }

  /// Save haptic feedback preference
  static Future<void> setHapticFeedback(bool value) async {
    _isHapticFeedbackEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, value);
  }
}
