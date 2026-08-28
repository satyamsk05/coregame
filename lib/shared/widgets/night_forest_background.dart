import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NightForestBackground extends StatefulWidget {
  final Widget? child;
  const NightForestBackground({super.key, this.child});

  @override
  State<NightForestBackground> createState() => _NightForestBackgroundState();
}

class _NightForestBackgroundState extends State<NightForestBackground>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  final List<StarParticle> _stars = [];
  Ticker? _starTicker;
  Duration _lastStarTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Seed stars exactly like loading screen
    for (int i = 0; i < 40; i++) {
      _stars.add(StarParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2.0 + 0.8,
        speed: _rng.nextDouble() * 0.00004 + 0.00001,
        alpha: _rng.nextDouble() * 0.7 + 0.2,
      ));
    }
    _starTicker = createTicker(_onStarTick)..start();
  }

  void _onStarTick(Duration elapsed) {
    if (!mounted) return;
    final double dt = _lastStarTick == Duration.zero
        ? 0.0
        : (elapsed - _lastStarTick).inMilliseconds / 1000.0;
    _lastStarTick = elapsed;
    setState(() {
      for (var s in _stars) {
        s.x += s.speed * dt * 30;
        if (s.x > 1.0) {
          s.x = 0.0;
          s.y = _rng.nextDouble();
        }
        s.alpha = (s.alpha + (_rng.nextDouble() * 0.1 - 0.05)).clamp(0.1, 0.95);
      }
    });
  }

  @override
  void dispose() {
    _starTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A4250), Color(0xFF5B6472)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Starfield background ──────────────────────────────────────
          CustomPaint(
            painter: StarfieldPainter(_stars),
          ),

          // ── Moon ──────────────────────────────────────────────────────
          Positioned(
            top: screenHeight * 0.12,
            right: screenWidth * 0.10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDCE1E6).withValues(alpha: 0.20),
                    blurRadius: 30.0,
                    spreadRadius: 2.0,
                  ),
                ],
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.35),
                  radius: 0.75,
                  colors: [Color(0xFFE7EBEE), Color(0xFFB7C0C9)],
                ),
              ),
            ),
          ),

          // ── Silhouette layers (Mountains & Trees) ──────────────────────
          // Far mountains
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.38,
            child: ClipPath(
              clipper: FarMountainClipper(),
              child: Container(
                color: const Color(0xFF4A515C).withValues(alpha: 0.8),
              ),
            ),
          ),

          // Near mountains
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.26,
            child: ClipPath(
              clipper: NearMountainClipper(),
              child: Container(
                color: const Color(0xFF333A44),
              ),
            ),
          ),

          // Pine Trees
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.20,
            child: ClipPath(
              clipper: TreesClipper(),
              child: Container(
                color: const Color(0xFF1C2128),
              ),
            ),
          ),

          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class StarParticle {
  double x, y, size, speed, alpha;
  StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.alpha,
  });
}

class StarfieldPainter extends CustomPainter {
  final List<StarParticle> stars;
  StarfieldPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var s in stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint..color = Colors.white.withValues(alpha: s.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter old) => true;
}

// Custom Clippers
class FarMountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.60);
    path.lineTo(w * 0.15, h * 0.35);
    path.lineTo(w * 0.30, h * 0.50);
    path.lineTo(w * 0.50, h * 0.25);
    path.lineTo(w * 0.70, h * 0.52);
    path.lineTo(w * 0.85, h * 0.40);
    path.lineTo(w, h * 0.55);
    path.lineTo(w, h);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class NearMountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.65);
    path.lineTo(w * 0.22, h * 0.30);
    path.lineTo(w * 0.45, h * 0.55);
    path.lineTo(w * 0.65, h * 0.20);
    path.lineTo(w * 0.88, h * 0.50);
    path.lineTo(w, h * 0.45);
    path.lineTo(w, h);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TreesClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.70);
    path.lineTo(w * 0.08, h * 0.45);
    path.lineTo(w * 0.14, h * 0.62);
    path.lineTo(w * 0.20, h * 0.35);
    path.lineTo(w * 0.25, h * 0.58);
    path.lineTo(w * 0.32, h * 0.48);
    path.lineTo(w * 0.38, h * 0.65);
    path.lineTo(w * 0.44, h * 0.50);
    path.lineTo(w * 0.50, h * 0.60);
    path.lineTo(w * 0.56, h * 0.42);
    path.lineTo(w * 0.62, h * 0.55);
    path.lineTo(w * 0.68, h * 0.38);
    path.lineTo(w * 0.75, h * 0.58);
    path.lineTo(w * 0.82, h * 0.46);
    path.lineTo(w * 0.89, h * 0.62);
    path.lineTo(w * 0.94, h * 0.30);
    path.lineTo(w, h * 0.55);
    path.lineTo(w, h);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
