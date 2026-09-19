import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Music track type
enum MusicTrack {
  menu('メニュー'),
  game('ゲーム中'),
  victory('勝利'),
  defeat('敗北'),
  ambience('環境音');

  final String label;
  const MusicTrack(this.label);
}

/// Sound effect type
enum SoundEffect {
  move('駒を置く'),
  capture('駒を取る'),
  turnChange('ターン変更'),
  victory('勝利'),
  defeat('敗北'),
  notification('通知'),
  click('クリック'),
  error('エラー');

  final String label;
  const SoundEffect(this.label);
}

/// Audio settings
class AudioSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final double soundVolume; // 0.0 to 1.0
  final double musicVolume; // 0.0 to 1.0
  final bool muteDuringCalls;
  final bool muteWhenSilent;
  final Map<SoundEffect, bool> enabledSounds;
  final Map<MusicTrack, bool> enabledMusic;

  const AudioSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.soundVolume = 0.7,
    this.musicVolume = 0.5,
    this.muteDuringCalls = true,
    this.muteWhenSilent = false,
    this.enabledSounds = const {},
    this.enabledMusic = const {},
  });

  AudioSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    double? soundVolume,
    double? musicVolume,
    bool? muteDuringCalls,
    bool? muteWhenSilent,
    Map<SoundEffect, bool>? enabledSounds,
    Map<MusicTrack, bool>? enabledMusic,
  }) {
    return AudioSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      muteDuringCalls: muteDuringCalls ?? this.muteDuringCalls,
      muteWhenSilent: muteWhenSilent ?? this.muteWhenSilent,
      enabledSounds: enabledSounds ?? this.enabledSounds,
      enabledMusic: enabledMusic ?? this.enabledMusic,
    );
  }
}

/// Sound settings state
class SoundSettingsState {
  final AudioSettings audioSettings;
  final bool isLoading;
  final String? error;

  const SoundSettingsState({
    required this.audioSettings,
    this.isLoading = false,
    this.error,
  });

  SoundSettingsState copyWith({
    AudioSettings? audioSettings,
    bool? isLoading,
    String? error,
  }) {
    return SoundSettingsState(
      audioSettings: audioSettings ?? this.audioSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for sound settings
class SoundSettingsNotifier extends StateNotifier<SoundSettingsState> {
  SharedPreferences? _prefs;

  SoundSettingsNotifier() : super(_buildInitialState()) {
    _initializeSettings();
  }

  /// Initialize settings
  Future<void> _initializeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _loadSettings(prefs);
  }

  /// Build initial state
  static SoundSettingsState _buildInitialState() {
    return const SoundSettingsState(
      audioSettings: AudioSettings(),
    );
  }

  /// Load audio settings from preferences
  static AudioSettings _loadAudioSettings(SharedPreferences prefs) {
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final musicEnabled = prefs.getBool('music_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    final soundVolume = prefs.getDouble('sound_volume') ?? 0.7;
    final musicVolume = prefs.getDouble('music_volume') ?? 0.5;
    final muteDuringCalls = prefs.getBool('mute_during_calls') ?? true;
    final muteWhenSilent = prefs.getBool('mute_when_silent') ?? false;

    // Load enabled sounds
    final enabledSounds = <SoundEffect, bool>{};
    for (final effect in SoundEffect.values) {
      enabledSounds[effect] =
          prefs.getBool('sound_effect_${effect.name}') ?? true;
    }

    // Load enabled music
    final enabledMusic = <MusicTrack, bool>{};
    for (final track in MusicTrack.values) {
      enabledMusic[track] = prefs.getBool('music_track_${track.name}') ?? true;
    }

    return AudioSettings(
      soundEnabled: soundEnabled,
      musicEnabled: musicEnabled,
      vibrationEnabled: vibrationEnabled,
      soundVolume: soundVolume,
      musicVolume: musicVolume,
      muteDuringCalls: muteDuringCalls,
      muteWhenSilent: muteWhenSilent,
      enabledSounds: enabledSounds,
      enabledMusic: enabledMusic,
    );
  }

  /// Load settings from preferences
  void _loadSettings(SharedPreferences prefs) {
    final audioSettings = _loadAudioSettings(prefs);
    state = state.copyWith(audioSettings: audioSettings);
  }

  /// Toggle sound
  Future<void> toggleSound(bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', enabled);
      state = state.copyWith(
        audioSettings: state.audioSettings.copyWith(soundEnabled: enabled),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update sound setting: $e');
    }
  }

  /// Toggle music
  Future<void> toggleMusic(bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('music_enabled', enabled);
      state = state.copyWith(
        audioSettings: state.audioSettings.copyWith(musicEnabled: enabled),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update music setting: $e');
    }
  }

  /// Toggle vibration
  Future<void> toggleVibration(bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('vibration_enabled', enabled);
      state = state.copyWith(
        audioSettings:
            state.audioSettings.copyWith(vibrationEnabled: enabled),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update vibration setting: $e');
    }
  }

  /// Set sound volume
  Future<void> setSoundVolume(double volume) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setDouble('sound_volume', volume);
      state = state.copyWith(
        audioSettings: state.audioSettings.copyWith(soundVolume: volume),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update sound volume: $e');
    }
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setDouble('music_volume', volume);
      state = state.copyWith(
        audioSettings: state.audioSettings.copyWith(musicVolume: volume),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update music volume: $e');
    }
  }

  /// Toggle mute during calls
  Future<void> toggleMuteDuringCalls(bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('mute_during_calls', enabled);
      state = state.copyWith(
        audioSettings:
            state.audioSettings.copyWith(muteDuringCalls: enabled),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update setting: $e');
    }
  }

  /// Toggle mute when silent
  Future<void> toggleMuteWhenSilent(bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('mute_when_silent', enabled);
      state = state.copyWith(
        audioSettings:
            state.audioSettings.copyWith(muteWhenSilent: enabled),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update setting: $e');
    }
  }

  /// Toggle sound effect
  Future<void> toggleSoundEffect(SoundEffect effect, bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('sound_effect_${effect.name}', enabled);
      final updatedSounds = {...state.audioSettings.enabledSounds};
      updatedSounds[effect] = enabled;
      state = state.copyWith(
        audioSettings: state.audioSettings.copyWith(
          enabledSounds: updatedSounds,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update sound effect: $e');
    }
  }

  /// Toggle music track
  Future<void> toggleMusicTrack(MusicTrack track, bool enabled) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setBool('music_track_${track.name}', enabled);
      final updatedMusic = {...state.audioSettings.enabledMusic};
      updatedMusic[track] = enabled;
      state = state.copyWith(
        audioSettings: state.audioSettings.copyWith(
          enabledMusic: updatedMusic,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update music track: $e');
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      final defaultSettings = const AudioSettings();
      await prefs.setBool('sound_enabled', defaultSettings.soundEnabled);
      await prefs.setBool('music_enabled', defaultSettings.musicEnabled);
      await prefs.setBool(
          'vibration_enabled', defaultSettings.vibrationEnabled);
      await prefs.setDouble('sound_volume', defaultSettings.soundVolume);
      await prefs.setDouble('music_volume', defaultSettings.musicVolume);
      await prefs.setBool(
          'mute_during_calls', defaultSettings.muteDuringCalls);
      await prefs.setBool('mute_when_silent', defaultSettings.muteWhenSilent);

      state = state.copyWith(audioSettings: defaultSettings);
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset settings: $e');
    }
  }
}

/// Riverpod provider for sound settings
final soundSettingsProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettingsState>(
  (ref) => SoundSettingsNotifier(),
);

/// Alternative sync provider (for testing)
final soundSettingsSyncProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettingsState>((ref) {
  throw UnimplementedError();
});
