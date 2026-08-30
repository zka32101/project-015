import 'package:flutter/material.dart';

/// Animation effect types
enum AnimationEffectType {
  pieceMove,
  capture,
  victory,
  defeat,
  selection,
  threat,
}

/// Configuration for animation effects
class AnimationEffectsConfig {
  final bool enablePieceMoveAnimation;
  final bool enableCaptureParticles;
  final bool enableVictoryAnimation;
  final bool enableTransitions;
  final Duration pieceMoveAnimationDuration;
  final Duration captureAnimationDuration;
  final Duration victoryAnimationDuration;

  const AnimationEffectsConfig({
    this.enablePieceMoveAnimation = true,
    this.enableCaptureParticles = true,
    this.enableVictoryAnimation = true,
    this.enableTransitions = true,
    this.pieceMoveAnimationDuration = const Duration(milliseconds: 400),
    this.captureAnimationDuration = const Duration(milliseconds: 600),
    this.victoryAnimationDuration = const Duration(milliseconds: 1200),
  });

  // Predefined configurations for different performance levels
  static const full = AnimationEffectsConfig(
    enablePieceMoveAnimation: true,
    enableCaptureParticles: true,
    enableVictoryAnimation: true,
    enableTransitions: true,
    pieceMoveAnimationDuration: Duration(milliseconds: 400),
    captureAnimationDuration: Duration(milliseconds: 600),
    victoryAnimationDuration: Duration(milliseconds: 1200),
  );

  static const minimal = AnimationEffectsConfig(
    enablePieceMoveAnimation: true,
    enableCaptureParticles: false,
    enableVictoryAnimation: true,
    enableTransitions: false,
    pieceMoveAnimationDuration: Duration(milliseconds: 200),
    captureAnimationDuration: Duration(milliseconds: 300),
    victoryAnimationDuration: Duration(milliseconds: 600),
  );

  static const disabled = AnimationEffectsConfig(
    enablePieceMoveAnimation: false,
    enableCaptureParticles: false,
    enableVictoryAnimation: false,
    enableTransitions: false,
    pieceMoveAnimationDuration: Duration.zero,
    captureAnimationDuration: Duration.zero,
    victoryAnimationDuration: Duration.zero,
  );
}

/// Global animation effects manager
class AnimationEffectsManager {
  static final AnimationEffectsManager _instance = AnimationEffectsManager._internal();
  late AnimationEffectsConfig _config;

  AnimationEffectsManager._internal() {
    _config = AnimationEffectsConfig.full;
  }

  factory AnimationEffectsManager() {
    return _instance;
  }

  AnimationEffectsConfig get config => _config;

  void setConfig(AnimationEffectsConfig config) {
    _config = config;
  }

  void enableAll() {
    _config = AnimationEffectsConfig.full;
  }

  void disableAll() {
    _config = AnimationEffectsConfig.disabled;
  }

  void setMinimal() {
    _config = AnimationEffectsConfig.minimal;
  }
}

/// Easing curves for smooth animations
class AnimationCurves {
  // Smooth easing for piece movements
  static const pieceMove = Cubic(0.34, 1.56, 0.64, 1); // slight overshoot
  static const pieceMoveEaseInOut = Cubic(0.42, 0.0, 0.58, 1.0);
  static const capture = Curves.easeInOutQuart;
  static const victory = Curves.easeOutElastic;
  static const threat = Curves.easeInOut;
}

/// Particle configuration for effects
class ParticleConfig {
  final Color color;
  final double size;
  final double maxDistance;
  final Duration duration;
  final int count;

  const ParticleConfig({
    required this.color,
    this.size = 6.0,
    this.maxDistance = 60.0,
    this.duration = const Duration(milliseconds: 600),
    this.count = 8,
  });

  // Predefined particle configurations
  static ParticleConfig victoryParticles(Color color) => ParticleConfig(
    color: color,
    size: 5.0,
    maxDistance: 80.0,
    duration: const Duration(milliseconds: 800),
    count: 12,
  );

  static ParticleConfig captureParticles(Color color) => ParticleConfig(
    color: color,
    size: 4.0,
    maxDistance: 50.0,
    duration: const Duration(milliseconds: 600),
    count: 8,
  );

  static ParticleConfig threatHighlight(Color color) => ParticleConfig(
    color: color,
    size: 3.0,
    maxDistance: 40.0,
    duration: const Duration(milliseconds: 500),
    count: 6,
  );
}

/// Transition style for screen navigation
enum TransitionStyle {
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  fade,
  scale,
}

/// Extension for transition routes
extension TransitionRouteExtension on TransitionStyle {
  PageRouteBuilder buildRoute(Widget Function(BuildContext) builder) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (this) {
          case TransitionStyle.slideLeft:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          case TransitionStyle.slideRight:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(-1, 0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          case TransitionStyle.slideUp:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 1), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          case TransitionStyle.slideDown:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, -1), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          case TransitionStyle.fade:
            return FadeTransition(opacity: animation, child: child);
          case TransitionStyle.scale:
            return ScaleTransition(scale: animation, child: child);
        }
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

/// Board animation controller for coordinated effects
class BoardAnimationController {
  final AnimationController moveController;
  final AnimationController captureController;
  final AnimationController victoryController;

  BoardAnimationController({
    required TickerProvider vsync,
    required AnimationEffectsConfig config,
  })  : moveController = AnimationController(
          vsync: vsync,
          duration: config.pieceMoveAnimationDuration,
        ),
        captureController = AnimationController(
          vsync: vsync,
          duration: config.captureAnimationDuration,
        ),
        victoryController = AnimationController(
          vsync: vsync,
          duration: config.victoryAnimationDuration,
        );

  void playMoveAnimation() {
    if (moveController.duration != Duration.zero) {
      moveController.forward(from: 0);
    }
  }

  void playCaptureAnimation() {
    if (captureController.duration != Duration.zero) {
      captureController.forward(from: 0);
    }
  }

  void playVictoryAnimation() {
    if (victoryController.duration != Duration.zero) {
      victoryController.forward(from: 0);
    }
  }

  void dispose() {
    moveController.dispose();
    captureController.dispose();
    victoryController.dispose();
  }
}

/// Helper class for creating smooth piece transition paths
class PieceTransitionPath {
  final Offset from;
  final Offset to;
  final double arcHeight;

  PieceTransitionPath({
    required this.from,
    required this.to,
    this.arcHeight = 20.0,
  });

  /// Calculate position at time t (0.0 to 1.0)
  Offset getPosition(double t) {
    // Quadratic curve for smooth arc motion
    final x = from.dx + (to.dx - from.dx) * t;
    final arcY = 4 * arcHeight * t * (1 - t); // parabolic arc
    final y = from.dy + (to.dy - from.dy) * t - arcY;
    return Offset(x, y);
  }

  /// Get rotation angle for 3D effect during movement
  double getRotation(double t) {
    return (t * 360) * 0.2; // gentle rotation during movement
  }
}
