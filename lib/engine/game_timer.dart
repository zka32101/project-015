import 'dart:async';

/// Represents different time control modes for the game
enum TimeControlMode {
  unlimited,  // No time limit
  blitz,      // Fast time: 3 minutes per player
  rapid,      // Medium time: 10 minutes per player
  classical,  // Slow time: 30 minutes per player
  custom,     // Custom time setting
}

/// Manages time for a single player in a timed game
class PlayerTimer {
  final String playerName;
  int totalTimeMs;
  int remainingTimeMs;
  DateTime? _startTime;
  late final Timer _ticker;
  bool _isRunning = false;

  /// Callback when time runs out
  VoidCallback? onTimeOut;

  /// Callback for time updates
  void Function(int remainingMs)? onTimeUpdate;

  PlayerTimer({
    required this.playerName,
    required this.totalTimeMs,
  }) : remainingTimeMs = totalTimeMs;

  /// Start the timer
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _startTime = DateTime.now();

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isRunning && _startTime != null) {
        final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
        final newRemaining = totalTimeMs - elapsed;

        if (newRemaining <= 0) {
          remainingTimeMs = 0;
          pause();
          onTimeOut?.call();
        } else {
          remainingTimeMs = newRemaining;
          onTimeUpdate?.call(newRemaining);
        }
      }
    });
  }

  /// Pause the timer
  void pause() {
    _isRunning = false;
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
      totalTimeMs -= elapsed;
      remainingTimeMs = totalTimeMs;
    }
  }

  /// Resume the timer
  void resume() {
    if (!_isRunning) {
      start();
    }
  }

  /// Check if time is still remaining
  bool get hasTimeRemaining => remainingTimeMs > 0;

  /// Check if timer is running
  bool get isRunning => _isRunning;

  /// Get formatted time display (MM:SS)
  String getFormattedTime() {
    final seconds = (remainingTimeMs / 1000).ceil();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Dispose of the timer
  void dispose() {
    _ticker.cancel();
  }
}

/// Manages both players' timers in a timed game
class GameTimer {
  final TimeControlMode mode;
  final int timePerPlayerMs;
  late final PlayerTimer playerATimer;
  late final PlayerTimer playerBTimer;
  PlayerTimer? _currentPlayerTimer;

  GameTimer({
    required this.mode,
    required this.timePerPlayerMs,
  }) {
    playerATimer = PlayerTimer(
      playerName: 'Player A',
      totalTimeMs: timePerPlayerMs,
    );
    playerBTimer = PlayerTimer(
      playerName: 'Player B',
      totalTimeMs: timePerPlayerMs,
    );
  }

  /// Start timer for player A
  void startPlayerA() {
    _currentPlayerTimer?.pause();
    _currentPlayerTimer = playerATimer;
    playerATimer.start();
  }

  /// Start timer for player B
  void startPlayerB() {
    _currentPlayerTimer?.pause();
    _currentPlayerTimer = playerBTimer;
    playerBTimer.start();
  }

  /// Switch to the next player's timer
  void switchPlayer() {
    if (_currentPlayerTimer == playerATimer) {
      startPlayerB();
    } else {
      startPlayerA();
    }
  }

  /// Pause current timer
  void pauseCurrentTimer() {
    _currentPlayerTimer?.pause();
  }

  /// Check if either player is out of time
  bool get isGameOver =>
      !playerATimer.hasTimeRemaining || !playerBTimer.hasTimeRemaining;

  /// Get the player who ran out of time (if any)
  PlayerTimer? get timeoutPlayer {
    if (!playerATimer.hasTimeRemaining) return playerATimer;
    if (!playerBTimer.hasTimeRemaining) return playerBTimer;
    return null;
  }

  /// Dispose of all timers
  void dispose() {
    playerATimer.dispose();
    playerBTimer.dispose();
  }
}

/// Helper to get time control settings
class TimeControlPreset {
  final TimeControlMode mode;
  final int timePerPlayerMs;
  final String displayName;

  const TimeControlPreset({
    required this.mode,
    required this.timePerPlayerMs,
    required this.displayName,
  });

  static const List<TimeControlPreset> presets = [
    TimeControlPreset(
      mode: TimeControlMode.unlimited,
      timePerPlayerMs: 0,
      displayName: '無制限',
    ),
    TimeControlPreset(
      mode: TimeControlMode.blitz,
      timePerPlayerMs: 180000, // 3 minutes
      displayName: 'ブリッツ (3分)',
    ),
    TimeControlPreset(
      mode: TimeControlMode.rapid,
      timePerPlayerMs: 600000, // 10 minutes
      displayName: 'ラピッド (10分)',
    ),
    TimeControlPreset(
      mode: TimeControlMode.classical,
      timePerPlayerMs: 1800000, // 30 minutes
      displayName: 'クラシカル (30分)',
    ),
  ];

  static TimeControlPreset getPreset(TimeControlMode mode) {
    return presets.firstWhere((p) => p.mode == mode);
  }
}
