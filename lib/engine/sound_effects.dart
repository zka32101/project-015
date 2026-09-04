/// Sound effects system for game audio management
class SoundEffect {
  final String name;
  final String assetPath;
  final double volume;

  const SoundEffect({
    required this.name,
    required this.assetPath,
    this.volume = 0.8,
  });

  @override
  String toString() => name;
}

/// Collection of predefined sound effects
class SoundEffects {
  /// Sound played when a piece moves
  static const SoundEffect moveSound = SoundEffect(
    name: 'move',
    assetPath: 'assets/sounds/move.mp3',
    volume: 0.6,
  );

  /// Sound played when capturing opponent piece
  static const SoundEffect captureSound = SoundEffect(
    name: 'capture',
    assetPath: 'assets/sounds/capture.mp3',
    volume: 0.7,
  );

  /// Sound played when king piece is captured/game ends
  static const SoundEffect kingCaptureSound = SoundEffect(
    name: 'king_capture',
    assetPath: 'assets/sounds/king_capture.mp3',
    volume: 0.9,
  );

  /// Sound played when game ends in victory
  static const SoundEffect victorySound = SoundEffect(
    name: 'victory',
    assetPath: 'assets/sounds/victory.mp3',
    volume: 0.8,
  );

  /// Sound played when game ends in defeat
  static const SoundEffect defeatSound = SoundEffect(
    name: 'defeat',
    assetPath: 'assets/sounds/defeat.mp3',
    volume: 0.8,
  );

  /// Sound played when game ends in draw
  static const SoundEffect drawSound = SoundEffect(
    name: 'draw',
    assetPath: 'assets/sounds/draw.mp3',
    volume: 0.7,
  );

  /// UI sound for button click
  static const SoundEffect buttonClickSound = SoundEffect(
    name: 'button_click',
    assetPath: 'assets/sounds/button_click.mp3',
    volume: 0.4,
  );

  /// UI sound for selection/highlighting
  static const SoundEffect selectSound = SoundEffect(
    name: 'select',
    assetPath: 'assets/sounds/select.mp3',
    volume: 0.5,
  );

  /// Sound for invalid move attempt
  static const SoundEffect invalidSound = SoundEffect(
    name: 'invalid',
    assetPath: 'assets/sounds/invalid.mp3',
    volume: 0.5,
  );

  /// Sound for undo action
  static const SoundEffect undoSound = SoundEffect(
    name: 'undo',
    assetPath: 'assets/sounds/undo.mp3',
    volume: 0.6,
  );

  /// All sound effects for easy iteration
  static const List<SoundEffect> allSounds = [
    moveSound,
    captureSound,
    kingCaptureSound,
    victorySound,
    defeatSound,
    drawSound,
    buttonClickSound,
    selectSound,
    invalidSound,
    undoSound,
  ];
}

/// Sound effect playback settings
class SoundSettings {
  /// Whether sound effects are enabled
  final bool soundEnabled;

  /// Master volume level (0.0 to 1.0)
  final double masterVolume;

  /// Whether ambient music is enabled
  final bool musicEnabled;

  /// Music volume level (0.0 to 1.0)
  final double musicVolume;

  const SoundSettings({
    this.soundEnabled = true,
    this.masterVolume = 1.0,
    this.musicEnabled = false,
    this.musicVolume = 0.5,
  });

  /// Create a copy with modified values
  SoundSettings copyWith({
    bool? soundEnabled,
    double? masterVolume,
    bool? musicEnabled,
    double? musicVolume,
  }) {
    return SoundSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      masterVolume: (masterVolume ?? this.masterVolume).clamp(0.0, 1.0),
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: (musicVolume ?? this.musicVolume).clamp(0.0, 1.0),
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'masterVolume': masterVolume,
        'musicEnabled': musicEnabled,
        'musicVolume': musicVolume,
      };

  /// JSON deserialization
  factory SoundSettings.fromJson(Map<String, dynamic> json) {
    return SoundSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      masterVolume: (json['masterVolume'] ?? 1.0).toDouble(),
      musicEnabled: json['musicEnabled'] ?? false,
      musicVolume: (json['musicVolume'] ?? 0.5).toDouble(),
    );
  }
}
