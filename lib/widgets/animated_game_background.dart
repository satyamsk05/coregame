import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedGameBackground extends StatefulWidget {
  final Widget child;
  final bool showStars;

  const AnimatedGameBackground({
    super.key,
    required this.child,
    this.showStars = true,
  });

  @override
  State<AnimatedGameBackground> createState() => _AnimatedGameBackgroundState();
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Initialize 80 space warp stars with random angles and starting distances
    final List<Color> starColors = [
      const Color(0xFFFFFFFF), // Pure white
      const Color(0xFF00E5FF), // Cyber cyan
      const Color(0xFFE040FB), // Glowing magenta
      const Color(0xFFE3F2FD), // Neon light blue
    ];

    for (int i = 0; i < 80; i++) {
      _stars.add(_Star(
        angle: _random.nextDouble() * 2 * math.pi,
        distance: _random.nextDouble(), // Start at different depths
        speed: (_random.nextDouble() * 0.010 + 0.004) / 6.0,
        size: _random.nextDouble() * 1.8 + 0.6,
        color: starColors[_random.nextInt(starColors.length)],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update Starfield depths if enabled
        if (widget.showStars) {
          for (var star in _stars) {
            final double acceleration = 1.0 + (star.distance * 1.8);
            star.distance += star.speed * acceleration;

            if (star.distance > 1.0) {
              star.distance = 0.02;
              star.angle = _random.nextDouble() * 2 * math.pi;
              star.speed = (_random.nextDouble() * 0.010 + 0.004) / 6.0;
            }
          }
        }

        return CustomPaint(
          painter: _GridBackgroundPainter(
            animationValue: _controller.value,
            stars: widget.showStars ? _stars : const [],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _Star {
  double angle; // Trajectory angle in radians from screen center
  double distance; // Normalized distance factor from center (0.0 to 1.0)
  double speed;
  final double size;
  final Color color;

  _Star({
    required this.angle,
    required this.distance,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _GridBackgroundPainter extends CustomPainter {
  final double animationValue;
  final List<_Star> stars;

  _GridBackgroundPainter({
    required this.animationValue,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // 1. Draw solid space-dark background color
    final bgPaint = Paint()..color = const Color(0xFF0B0523);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw Slow-Pulsing Nebula Clouds (Overlapping soft radial glows)
    // Nebula 1: Top-Left Indigo Glow, drifting slowly
    final double nebula1Radius = size.width * (0.65 + math.sin(animationValue * 2 * math.pi) * 0.06);
    final double n1x = cx - 60.0 + math.cos(animationValue * 2 * math.pi) * 35.0;
    final double n1y = cy - 50.0 + math.sin(animationValue * 2 * math.pi) * 35.0;
    final Rect nebula1Rect = Rect.fromCircle(center: Offset(n1x, n1y), radius: nebula1Radius);
    final Paint nebula1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF311B92).withValues(alpha: 0.32), // Indigo space glow
          const Color(0xFF0B0523).withValues(alpha: 0.0),
        ],
      ).createShader(nebula1Rect);
    canvas.drawCircle(Offset(n1x, n1y), nebula1Radius, nebula1Paint);

    // Nebula 2: Bottom-Right Ruby-Magenta Glow, breathing
    final double nebula2Radius = size.width * (0.55 + math.cos(animationValue * 2 * math.pi) * 0.05);
    final double n2x = cx + 80.0 + math.sin(animationValue * 2 * math.pi) * 30.0;
    final double n2y = cy + 40.0 + math.cos(animationValue * 2 * math.pi) * 30.0;
    final Rect nebula2Rect = Rect.fromCircle(center: Offset(n2x, n2y), radius: nebula2Radius);
    final Paint nebula2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF880E4F).withValues(alpha: 0.22), // Deep ruby glow
          const Color(0xFF0B0523).withValues(alpha: 0.0),
        ],
      ).createShader(nebula2Rect);
    canvas.drawCircle(Offset(n2x, n2y), nebula2Radius, nebula2Paint);

    // 3. Draw Hyperspace Space Warp Stars
    final double maxRadius = math.sqrt(cx * cx + cy * cy);

    for (var star in stars) {
      final double currentRadius = maxRadius * star.distance;

      // Calculate current star coordinate
      final double x = cx + math.cos(star.angle) * currentRadius;
      final double y = cy + math.sin(star.angle) * currentRadius;

      // Calculate previous star coordinate for radial trail stretching
      // As the star travels further, the trail elongates to simulate warp speed
      final double trailLength = 0.03 + (star.distance * 0.06);
      final double prevDistance = (star.distance - trailLength).clamp(0.0, 1.0);
      final double prevRadius = maxRadius * prevDistance;
      final double px = cx + math.cos(star.angle) * prevRadius;
      final double py = cy + math.sin(star.angle) * prevRadius;

      // Soft fade-in near center and fade-out near screen edges
      double alphaFactor = 1.0;
      if (star.distance < 0.15) {
        alphaFactor = star.distance / 0.15;
      } else if (star.distance > 0.8) {
        alphaFactor = (1.0 - star.distance) / 0.2;
      }

      final starPaint = Paint()
        ..color = star.color.withValues(alpha: alphaFactor.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = star.size * (0.8 + star.distance * 1.5);

      // Paint 3D light trail line
      canvas.drawLine(Offset(px, py), Offset(x, y), starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) {
    return true; // Repaint continuously on animation frames
  }
}
