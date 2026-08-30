import 'package:shared_preferences/shared_preferences.dart';

/// Application preferences and settings
class AppPreferences {
  // Preference keys
  static const String soundEnabledKey = 'pref_sound_enabled';
  static const String hapticEnabledKey = 'pref_haptic_enabled';
  static const String threatPreviewKey = 'pref_threat_preview';
  static const String animationsEnabledKey = 'pref_animations_enabled';
  static const String moveDelayMsKey = 'pref_move_delay_ms';
  static const String showPieceCountKey = 'pref_show_piece_count';
  static const String autoSaveKey = 'pref_auto_save';
  static const String difficultyKey = 'pref_default_difficulty';

  late SharedPreferences _prefs;

  AppPreferences._();

  static final AppPreferences _instance = AppPreferences._();

  factory AppPreferences() {
    return _instance;
  }

  /// Initialize preferences (call this once at startup)
  static Future<AppPreferences> init() async {
    _instance._prefs = await SharedPreferences.getInstance();
    return _instance;
  }

  // Sound preferences
  bool get isSoundEnabled => _prefs.getBool(soundEnabledKey) ?? true;
  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(soundEnabledKey, enabled);

  // Haptic preferences
  bool get isHapticEnabled => _prefs.getBool(hapticEnabledKey) ?? true;
  Future<void> setHapticEnabled(bool enabled) =>
      _prefs.setBool(hapticEnabledKey, enabled);

  // Threat preview preferences
  bool get isThreatPreviewEnabled => _prefs.getBool(threatPreviewKey) ?? false;
  Future<void> setThreatPreviewEnabled(bool enabled) =>
      _prefs.setBool(threatPreviewKey, enabled);

  // Animation preferences
  bool get isAnimationsEnabled => _prefs.getBool(animationsEnabledKey) ?? true;
  Future<void> setAnimationsEnabled(bool enabled) =>
      _prefs.setBool(animationsEnabledKey, enabled);

  // AI move delay (milliseconds)
  int get aiMoveDelayMs => _prefs.getInt(moveDelayMsKey) ?? 500;
  Future<void> setAiMoveDelayMs(int ms) =>
      _prefs.setInt(moveDelayMsKey, ms);

  // Show piece count
  bool get showPieceCount => _prefs.getBool(showPieceCountKey) ?? true;
  Future<void> setShowPieceCount(bool show) =>
      _prefs.setBool(showPieceCountKey, show);

  // Auto-save games
  bool get autoSaveGames => _prefs.getBool(autoSaveKey) ?? true;
  Future<void> setAutoSaveGames(bool autoSave) =>
      _prefs.setBool(autoSaveKey, autoSave);

  // Default AI difficulty
  String? get defaultDifficulty => _prefs.getString(difficultyKey);
  Future<void> setDefaultDifficulty(String difficulty) =>
      _prefs.setString(difficultyKey, difficulty);

  /// Reset all preferences to defaults
  Future<void> resetAll() async {
    await _prefs.remove(soundEnabledKey);
    await _prefs.remove(hapticEnabledKey);
    await _prefs.remove(threatPreviewKey);
    await _prefs.remove(animationsEnabledKey);
    await _prefs.remove(moveDelayMsKey);
    await _prefs.remove(showPieceCountKey);
    await _prefs.remove(autoSaveKey);
    await _prefs.remove(difficultyKey);
  }
}
