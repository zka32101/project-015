import 'models.dart';

/// Animation configuration for game visual effects
class AnimationConfig {
  /// Duration for piece movement animation
  final Duration pieceMoveSpeed;

  /// Duration for piece flip/capture animation
  final Duration pieceFlipSpeed;

  /// Duration for board update animation
  final Duration boardUpdateSpeed;

  /// Whether animations are enabled
  final bool animationsEnabled;

  /// Animation speed multiplier (1.0 = normal, 0.5 = half speed, 2.0 = double speed)
  final double speedMultiplier;

  const AnimationConfig({
    this.pieceMoveSpeed = const Duration(milliseconds: 300),
    this.pieceFlipSpeed = const Duration(milliseconds: 200),
    this.boardUpdateSpeed = const Duration(milliseconds: 100),
    this.animationsEnabled = true,
    this.speedMultiplier = 1.0,
  });

  /// Get actual duration considering animation speed
  Duration getActualDuration(Duration baseDuration) {
    if (!animationsEnabled) return Duration.zero;
    return Duration(
      milliseconds: (baseDuration.inMilliseconds * speedMultiplier).toInt(),
    );
  }

  /// Create a copy with modified values
  AnimationConfig copyWith({
    Duration? pieceMoveSpeed,
    Duration? pieceFlipSpeed,
    Duration? boardUpdateSpeed,
    bool? animationsEnabled,
    double? speedMultiplier,
  }) {
    return AnimationConfig(
      pieceMoveSpeed: pieceMoveSpeed ?? this.pieceMoveSpeed,
      pieceFlipSpeed: pieceFlipSpeed ?? this.pieceFlipSpeed,
      boardUpdateSpeed: boardUpdateSpeed ?? this.boardUpdateSpeed,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      speedMultiplier: (speedMultiplier ?? this.speedMultiplier).clamp(0.1, 3.0),
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'pieceMoveSpeed': pieceMoveSpeed.inMilliseconds,
        'pieceFlipSpeed': pieceFlipSpeed.inMilliseconds,
        'boardUpdateSpeed': boardUpdateSpeed.inMilliseconds,
        'animationsEnabled': animationsEnabled,
        'speedMultiplier': speedMultiplier,
      };

  /// JSON deserialization
  factory AnimationConfig.fromJson(Map<String, dynamic> json) {
    return AnimationConfig(
      pieceMoveSpeed: Duration(milliseconds: json['pieceMoveSpeed'] ?? 300),
      pieceFlipSpeed: Duration(milliseconds: json['pieceFlipSpeed'] ?? 200),
      boardUpdateSpeed: Duration(milliseconds: json['boardUpdateSpeed'] ?? 100),
      animationsEnabled: json['animationsEnabled'] ?? true,
      speedMultiplier: (json['speedMultiplier'] ?? 1.0).toDouble(),
    );
  }
}

/// Represents an animation for a single piece movement
class PieceAnimation {
  final Move move;
  final DateTime startTime;
  final Duration duration;
  final PieceAnimationType type;

  PieceAnimation({
    required this.move,
    required this.startTime,
    required this.duration,
    required this.type,
  });

  /// Check if animation is still active
  bool isActive(DateTime currentTime) {
    return currentTime.difference(startTime).inMilliseconds < duration.inMilliseconds;
  }

  /// Get animation progress (0.0 to 1.0)
  double getProgress(DateTime currentTime) {
    final elapsed = currentTime.difference(startTime).inMilliseconds;
    final progress = elapsed / duration.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }
}

/// Types of piece animations
enum PieceAnimationType {
  /// Normal piece movement
  move,

  /// Piece flip/capture animation
  flip,

  /// Capture animation showing piece conversion
  capture,

  /// King capture - special animation for game ending
  kingCapture,
}

/// Visual effect event for displaying temporary effects
class VisualEffect {
  final Square position;
  final VisualEffectType type;
  final DateTime createdAt;
  final Duration duration;

  VisualEffect({
    required this.position,
    required this.type,
    required this.createdAt,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Check if effect is still visible
  bool isVisible(DateTime currentTime) {
    return currentTime.difference(createdAt).inMilliseconds < duration.inMilliseconds;
  }

  /// Get effect opacity (fade out towards end)
  double getOpacity(DateTime currentTime) {
    final elapsed = currentTime.difference(createdAt).inMilliseconds;
    final progress = elapsed / duration.inMilliseconds;
    return (1.0 - progress).clamp(0.0, 1.0);
  }

  /// Get effect scale (pop in animation)
  double getScale(DateTime currentTime) {
    final progress = getProgress(currentTime);
    // Scale up quickly then down
    if (progress < 0.3) {
      return 0.5 + progress * 1.67;
    } else {
      return 1.0 - (progress - 0.3) * 0.33;
    }
  }

  /// Get animation progress (0.0 to 1.0)
  double getProgress(DateTime currentTime) {
    final elapsed = currentTime.difference(createdAt).inMilliseconds;
    final progress = elapsed / duration.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }
}

/// Types of visual effects
enum VisualEffectType {
  /// Capture effect - shows piece being taken
  capture,

  /// Flip effect - shows piece flip animation
  flip,

  /// King capture - special effect for king pieces
  kingCapture,

  /// Check warning - shows king is under threat
  check,

  /// Selected highlight - shows selected piece
  selected,

  /// Legal move highlight - shows legal destinations
  legalMove,

  /// Last move highlight - shows previous move
  lastMove,

  /// Undo effect - shows undone move
  undo,

  /// Redo effect - shows redone move
  redo,

  /// Particle effect for visual feedback
  particle,
}

/// Manager for animation state and queuing
class AnimationManager {
  final List<PieceAnimation> activeAnimations = [];
  final List<VisualEffect> visibleEffects = [];
  final AnimationConfig config;

  AnimationManager({AnimationConfig? config}) : config = config ?? const AnimationConfig();

  /// Add a piece movement animation
  void addMoveAnimation(Move move, DateTime now) {
    if (!config.animationsEnabled) return;

    final duration = config.getActualDuration(config.pieceMoveSpeed);
    activeAnimations.add(
      PieceAnimation(
        move: move,
        startTime: now,
        duration: duration,
        type: PieceAnimationType.move,
      ),
    );
  }

  /// Add a piece flip animation
  void addFlipAnimation(Move move, DateTime now) {
    if (!config.animationsEnabled) return;

    final duration = config.getActualDuration(config.pieceFlipSpeed);
    activeAnimations.add(
      PieceAnimation(
        move: move,
        startTime: now,
        duration: duration,
        type: PieceAnimationType.flip,
      ),
    );
  }

  /// Add a visual effect
  void addEffect(Square position, VisualEffectType type, DateTime now) {
    if (!config.animationsEnabled) return;

    visibleEffects.add(
      VisualEffect(
        position: position,
        type: type,
        createdAt: now,
      ),
    );
  }

  /// Update animations, removing completed ones
  void update(DateTime now) {
    activeAnimations.removeWhere((anim) => !anim.isActive(now));
    visibleEffects.removeWhere((effect) => !effect.isVisible(now));
  }

  /// Clear all active animations
  void clear() {
    activeAnimations.clear();
    visibleEffects.clear();
  }

  /// Get animation for a specific move
  PieceAnimation? getAnimationForMove(Move move) {
    try {
      return activeAnimations.firstWhere(
        (anim) => anim.move.from == move.from && anim.move.to == move.to,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all effects at a specific position
  List<VisualEffect> getEffectsAt(Square position) {
    return visibleEffects.where((effect) => effect.position == position).toList();
  }
}
