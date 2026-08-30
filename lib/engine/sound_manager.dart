import 'package:flutter/services.dart';

/// Sound effect types that can be played during the game
enum SoundEffect {
  movePiece,     // When a piece moves
  capture,       // When a piece is captured
  flip,          // When a piece is flipped (寝返り)
  victory,       // When the game is won
  defeat,        // When the game is lost
  draw,          // When the game is a draw
  buttonPress,   // UI button press
  invalid,       // Invalid move attempted
}

/// Manages game sound effects with optional muting
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();

  bool _soundEnabled = true;

  factory SoundManager() {
    return _instance;
  }

  SoundManager._internal();

  /// Enable or disable sound effects globally
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Check if sounds are currently enabled
  bool get isSoundEnabled => _soundEnabled;

  /// Play a sound effect
  Future<void> playSound(SoundEffect effect) async {
    if (!_soundEnabled) return;

    switch (effect) {
      case SoundEffect.movePiece:
        await _playSystemSound(SystemSoundType.click);
        break;
      case SoundEffect.capture:
        await _playSystemSound(SystemSoundType.click);
        // In a full implementation, this could play a unique sound
        break;
      case SoundEffect.flip:
        await _playSystemSound(SystemSoundType.click);
        break;
      case SoundEffect.victory:
        await _playSystemSound(SystemSoundType.alert);
        break;
      case SoundEffect.defeat:
        await _playSystemSound(SystemSoundType.click);
        break;
      case SoundEffect.draw:
        await _playSystemSound(SystemSoundType.click);
        break;
      case SoundEffect.buttonPress:
        await _playSystemSound(SystemSoundType.click);
        break;
      case SoundEffect.invalid:
        await _playSystemSound(SystemSoundType.click);
        break;
    }
  }

  /// Play a system sound
  Future<void> _playSystemSound(SystemSoundType type) async {
    try {
      await SystemSound.play(type);
    } catch (e) {
      // Silently fail if sound system is unavailable
    }
  }

  /// Trigger haptic feedback for better user feedback
  static Future<void> triggerHaptic(HapticFeedbackType type) async {
    try {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
        case HapticFeedbackType.heavy:
          await HapticFeedback.heavyImpact();
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
      }
    } catch (e) {
      // Silently fail if haptic is unavailable
    }
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}
