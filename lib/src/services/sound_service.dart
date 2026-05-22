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
    _enabled = false; // Haptic feedback disabled by default
  }

  /// Click feedback for button taps
  static void playClick() {
    if (!_enabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Success chime - high pitch, happy
  static void playSuccess() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Error feedback - low pitch, alert
  static void playError() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Warning feedback - medium pitch
  static void playWarning() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Info feedback - light tap
  static void playInfo() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Selection feedback - very light
  static void playSelection() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Achievement unlock - triumphant
  static void playAchievement() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Scan complete - satisfying
  static void playScanComplete() {
    if (!_enabled) return;

    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
