import 'dart:io';

import 'package:flutter/services.dart';
import 'preferences_service.dart';

/// Simple sound service using system sounds
/// For a real app, you'd use audioplayers package with custom sounds
class SoundService {
  static bool _enabled = true;

  static bool get isEnabled => _enabled;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Initialize with saved preference
  static Future<void> init() async {
    _enabled = PreferencesService.isHapticFeedbackEnabled;
  }

  /// Success chime - high pitch, happy
  static void playSuccess() {
    if (!_enabled) return;
    
    // Use haptic feedback as fallback for sound
    HapticFeedback.heavyImpact();
    
    // On iOS, we can use system sounds
    if (Platform.isIOS) {
      // SystemSoundType.click is the only cross-platform option
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Button click - subtle
  static void playClick() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Achievement unlock - triumphant
  static void playAchievement() {
    if (!_enabled) return;
    
    // Pattern: short, short, long
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Error/Warning buzz
  static void playError() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  /// Scan complete - satisfying
  static void playScanComplete() {
    if (!_enabled) return;
    
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.lightImpact();
    });
  }
}
