import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Particle effect widget for explosive animations (captures, victories)
class ParticleEffectWidget extends StatefulWidget {
  final Offset position;
  final Color color;
  final double size;
  final double maxDistance;
  final int particleCount;
  final Duration duration;
  final bool enabled;

  const ParticleEffectWidget({
    super.key,
    required this.position,
    required this.color,
    this.size = 6.0,
    this.maxDistance = 60.0,
    this.particleCount = 8,
    this.duration = const Duration(milliseconds: 600),
    this.enabled = true,
  });

  @override
  State<ParticleEffectWidget> createState() => _ParticleEffectWidgetState();
}

class _ParticleEffectWidgetState extends State<ParticleEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _initializeParticles();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(
      widget.particleCount,
      (index) {
        final angle = (2 * math.pi * index) / widget.particleCount;
        final distance = widget.maxDistance * (0.7 + random.nextDouble() * 0.3);
        return Particle(
          angle: angle,
          distance: distance,
          size: widget.size * (0.6 + random.nextDouble() * 0.8),
          rotation: random.nextDouble() * 360,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            for (final particle in _particles)
              _buildParticle(particle, _controller.value),
          ],
        );
      },
    );
  }

  Widget _buildParticle(Particle particle, double progress) {
    // Ease out for smooth deceleration
    final easedProgress = 1 - (1 - progress) * (1 - progress);

    // Calculate particle position
    final distance = particle.distance * easedProgress;
    final dx = distance * math.cos(particle.angle);
    final dy = distance * math.sin(particle.angle);

    // Calculate opacity fade
    final opacity = (1 - progress) * 0.8;

    // Calculate scale (start small, grow slightly, then shrink)
    final scale = (0.3 + easedProgress * 0.7) * (1 - progress);

    return Positioned(
      left: widget.position.dx + dx - (particle.size * scale) / 2,
      top: widget.position.dy + dy - (particle.size * scale) / 2,
      child: Transform.rotate(
        angle: (particle.rotation + progress * 360) * math.pi / 180,
        child: Opacity(
          opacity: opacity.clamp(0, 1).toDouble(),
          child: Container(
            width: particle.size * scale,
            height: particle.size * scale,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single particle in the effect
class Particle {
  final double angle;
  final double distance;
  final double size;
  final double rotation;

  Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotation,
  });
}

/// Confetti effect for victories
class ConfettiWidget extends StatefulWidget {
  final Duration duration;
  final bool enabled;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;

  const ConfettiWidget({
    super.key,
    this.duration = const Duration(milliseconds: 2000),
    this.enabled = true,
    this.primaryColor = Colors.amber,
    this.secondaryColor = Colors.orange,
    this.particleCount = 30,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Confetti> _confetti;

  @override
  void initState() {
    super.initState();
    _initializeConfetti();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _initializeConfetti() {
    final random = math.Random();
    _confetti = List.generate(
      widget.particleCount,
      (index) => Confetti(
        initialX: random.nextDouble(),
        initialY: -0.1,
        angle: random.nextDouble() * 2 * math.pi,
        speed: 0.3 + random.nextDouble() * 0.5,
        size: 4 + random.nextDouble() * 8,
        rotation: random.nextDouble() * 360,
        rotationSpeed: -5 + random.nextDouble() * 10,
        color: random.nextBool() ? widget.primaryColor : widget.secondaryColor,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              for (final conf in _confetti)
                _buildConfetti(conf, _controller.value),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfetti(Confetti conf, double progress) {
    // Gravity and acceleration effect
    final gravity = 0.5 * progress * progress; // accelerating downward
    final y = conf.initialY + (conf.speed * progress) + gravity;
    final x = conf.initialX + (math.sin(conf.angle) * progress * 0.3);

    // Fade out at the end
    final opacity = progress < 0.7 ? 1.0 : 1.0 - ((progress - 0.7) / 0.3);

    // Rotation
    final rotation = conf.rotation + (conf.rotationSpeed * progress * 360);

    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Transform.rotate(
        angle: rotation * math.pi / 180,
        child: Opacity(
          opacity: opacity.clamp(0, 1).toDouble(),
          child: Container(
            width: conf.size,
            height: conf.size * 0.5,
            decoration: BoxDecoration(
              color: conf.color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confetti particle
class Confetti {
  final double initialX;
  final double initialY;
  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final Color color;

  Confetti({
    required this.initialX,
    required this.initialY,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
  });
}

/// Starburst effect for special events
class StarburstWidget extends StatefulWidget {
  final Offset center;
  final Color color;
  final Duration duration;
  final bool enabled;
  final int rayCount;

  const StarburstWidget({
    super.key,
    required this.center,
    required this.color,
    this.duration = const Duration(milliseconds: 1000),
    this.enabled = true,
    this.rayCount = 12,
  });

  @override
  State<StarburstWidget> createState() => _StarburstWidgetState();
}

class _StarburstWidgetState extends State<StarburstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.enabled) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            for (int i = 0; i < widget.rayCount; i++)
              _buildRay(i, _controller.value),
          ],
        );
      },
    );
  }

  Widget _buildRay(int index, double progress) {
    final angle = (2 * math.pi * index) / widget.rayCount;
    final distance = 100 * progress;
    final dx = distance * math.cos(angle);
    final dy = distance * math.sin(angle);

    // Fade out
    final opacity = (1 - progress) * 0.8;

    // Size animation
    final size = 3 * (1 - progress);

    return Positioned(
      left: widget.center.dx + dx - size / 2,
      top: widget.center.dy + dy - size / 2,
      child: Opacity(
        opacity: opacity.clamp(0, 1).toDouble(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
