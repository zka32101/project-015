import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced victory animation with multiple visual effects
class VictoryAnimationController extends ChangeNotifier {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  VictoryAnimationController({required TickerProvider vsync}) {
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1200),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.3, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.elasticOut)),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeInOut)),
    );

    _controller.addListener(notifyListeners);
  }

  Animation<double> get opacityAnimation => _opacityAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get rotationAnimation => _rotationAnimation;

  Future<void> playVictoryAnimation() async {
    await _controller.forward();
  }

  void reset() {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Crown animation that appears on victory
class VictoryCrownWidget extends StatefulWidget {
  final Owner winner;
  final Duration animationDuration;
  final bool enabled;

  const VictoryCrownWidget({
    super.key,
    required this.winner,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.enabled = true,
  });

  @override
  State<VictoryCrownWidget> createState() => _VictoryCrownWidgetState();
}

enum Owner { playerA, playerB }

class _VictoryCrownWidgetState extends State<VictoryCrownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Bouncy animation
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Gentle rotation
    _rotationAnimation = Tween<double>(begin: -0.2, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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

    final color = widget.winner == Owner.playerA
        ? const Color(0xFF42a5f5) // blue for player A
        : const Color(0xFFef5350); // red for player B

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(_bounceAnimation.value)
            ..setEntry(3, 2, 0.001)
            ..rotateZ(_rotationAnimation.value),
          child: CustomPaint(
            painter: CrownPainter(color: color),
            size: const Size(80, 60),
          ),
        );
      },
    );
  }
}

/// Crown shape painter
class CrownPainter extends CustomPainter {
  final Color color;

  CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Glow
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 1.8,
      glowPaint,
    );

    // Base
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.7);
    path.close();

    canvas.drawPath(path, paint);

    // Jewel on top
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.1),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(CrownPainter oldDelegate) => false;
}

/// Victory celebration burst effect
class VictoryCelebrationBurst extends StatefulWidget {
  final Offset center;
  final Color color;
  final bool enabled;

  const VictoryCelebrationBurst({
    super.key,
    required this.center,
    required this.color,
    this.enabled = true,
  });

  @override
  State<VictoryCelebrationBurst> createState() => _VictoryCelebrationBurstState();
}

class _VictoryCelebrationBurstState extends State<VictoryCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        final progress = _controller.value;
        final ringSize = 30 + progress * 120;
        final opacity = (1 - progress) * 0.6;

        return Stack(
          children: [
            // Expanding rings
            for (int i = 0; i < 3; i++)
              Positioned(
                left: widget.center.dx - (ringSize + i * 30) / 2,
                top: widget.center.dy - (ringSize + i * 30) / 2,
                child: Opacity(
                  opacity: (opacity * (1 - i * 0.3)).clamp(0, 1).toDouble(),
                  child: Container(
                    width: ringSize + i * 30,
                    height: ringSize + i * 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color,
                        width: 2 - progress * 2,
                      ),
                    ),
                  ),
                ),
              ),
            // Central glow
            Positioned(
              left: widget.center.dx - 15,
              top: widget.center.dy - 15,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Victory text reveal animation
class VictoryTextAnimator extends StatefulWidget {
  final String text;
  final Color color;
  final Duration duration;
  final bool enabled;

  const VictoryTextAnimator({
    super.key,
    required this.text,
    required this.color,
    this.duration = const Duration(milliseconds: 800),
    this.enabled = true,
  });

  @override
  State<VictoryTextAnimator> createState() => _VictoryTextAnimatorState();
}

class _VictoryTextAnimatorState extends State<VictoryTextAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Text(
              widget.text,
              style: TextStyle(
                color: widget.color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

/// Victory star animation
class VictoryStarField extends StatefulWidget {
  final Color color;
  final int starCount;
  final bool enabled;

  const VictoryStarField({
    super.key,
    required this.color,
    this.starCount = 20,
    this.enabled = true,
  });

  @override
  State<VictoryStarField> createState() => _VictoryStarFieldState();
}

class _VictoryStarFieldState extends State<VictoryStarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _initializeStars();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _initializeStars() {
    final random = math.Random();
    _stars = List.generate(
      widget.starCount,
      (index) => Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2 + random.nextDouble() * 4,
        delay: random.nextDouble() * 0.3,
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
              for (final star in _stars) _buildStar(star),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStar(Star star) {
    var progress = _controller.value - star.delay;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    final opacity = progress < 0.7 ? 1.0 : 1.0 - ((progress - 0.7) / 0.3);
    final scale = math.sin(progress * math.pi);

    return Positioned(
      left: star.x * MediaQuery.of(context).size.width,
      top: star.y * MediaQuery.of(context).size.height,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: star.size,
            height: star.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Star data for field animation
class Star {
  final double x;
  final double y;
  final double size;
  final double delay;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
  });
}
