import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedCharacter extends StatefulWidget {
  final double width;
  final double height;

  const AnimatedCharacter({
    super.key,
    this.width = 150.0,
    this.height = 150.0,
  });

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
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
        // Bobbing vertical offset: -10.0 to 10.0
        final double bobOffset = math.sin(_controller.value * 2 * math.pi) * 10.0;
        // Rotation tilt: -0.05 to 0.05 radians
        final double tilt = math.cos(_controller.value * 2 * math.pi) * 0.04;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft shadow on the grid below the character (shrinks & grows with bobbing height)
              Positioned(
                bottom: 8.0,
                child: Transform.scale(
                  scale: (1.0 - (bobOffset.abs() * 0.02)).clamp(0.7, 1.0),
                  child: Container(
                    width: 60.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.all(Radius.elliptical(30.0, 4.0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 2. Animated Character Body
              Positioned(
                top: 10.0 + bobOffset,
                child: Transform.rotate(
                  angle: tilt,
                  child: CustomPaint(
                    size: Size(widget.width - 20.0, widget.height - 30.0),
                    painter: _SpaceDroidPainter(
                      animationValue: _controller.value,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpaceDroidPainter extends CustomPainter {
  final double animationValue;

  _SpaceDroidPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw coordinate helpers
    final double centerX = w / 2;
    final double centerY = h / 2;

    // 1. Draw Jetpack Thrusters behind body
    final jetpackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5E35B1), Color(0xFF311B92)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(centerX - 35, centerY, 70, 40));

    // Left and Right thruster bodies
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - 42, centerY + 5, 16, 26), const Radius.circular(6.0)),
      jetpackPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX + 26, centerY + 5, 16, 26), const Radius.circular(6.0)),
      jetpackPaint,
    );

    // Thruster fire particles (flickering flame)
    final double flameFlicker = 0.8 + (math.sin(animationValue * 12 * math.pi) * 0.2);

    // Left fire
    canvas.save();
    canvas.translate(centerX - 34, centerY + 32);
    canvas.scale(1.0, flameFlicker);
    canvas.drawPath(
      Path()
        ..moveTo(-6, 0)
        ..quadraticBezierTo(0, 18, 0, 22)
        ..quadraticBezierTo(0, 18, 6, 0)
        ..close(),
      Paint()..color = const Color(0xFFFF9100),
    );
    // Add inner yellow flame core
    canvas.drawPath(
      Path()
        ..moveTo(-3, 0)
        ..quadraticBezierTo(0, 10, 0, 13)
        ..quadraticBezierTo(0, 10, 3, 0)
        ..close(),
      Paint()..color = const Color(0xFFFFEA00),
    );
    canvas.restore();

    // Right fire
    canvas.save();
    canvas.translate(centerX + 34, centerY + 32);
    canvas.scale(1.0, flameFlicker);
    canvas.drawPath(
      Path()
        ..moveTo(-6, 0)
        ..quadraticBezierTo(0, 18, 0, 22)
        ..quadraticBezierTo(0, 18, 6, 0)
        ..close(),
      Paint()..color = const Color(0xFFFF9100),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-3, 0)
        ..quadraticBezierTo(0, 10, 0, 13)
        ..quadraticBezierTo(0, 10, 3, 0)
        ..close(),
      Paint()..color = const Color(0xFFFFEA00),
    );
    canvas.restore();

    // 2. Draw Droid Head (Helmet)
    final headPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFB0BEC5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY - 15), radius: 32.0));

    // Draw circular head shadow
    canvas.drawCircle(Offset(centerX, centerY - 13), 32.0, Paint()..color = Colors.black.withValues(alpha: 0.15));
    // Head shape
    canvas.drawCircle(Offset(centerX, centerY - 15), 32.0, headPaint);

    // 3. Draw Visor (Glossy Dark Glass)
    final visorRect = Rect.fromLTWH(centerX - 24, centerY - 25, 48, 22);
    final visorPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF100720), Color(0xFF02000A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(visorRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, const Radius.circular(11.0)),
      visorPaint,
    );

    // Visor glowing neon border
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, const Radius.circular(11.0)),
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Glowing Eyes (Neon cyan lights that pulse/blink)
    final double eyeBlink = math.sin(animationValue * math.pi);
    final double eyeHeight = eyeBlink.abs() < 0.08 ? 1.0 : 4.0; // blink logic
    
    final eyePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    
    final eyeGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Draw left eye capsule
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - 13, centerY - 16 - (eyeHeight/2), 6, eyeHeight), const Radius.circular(2.0)),
      eyeGlow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - 13, centerY - 16 - (eyeHeight/2), 6, eyeHeight), const Radius.circular(2.0)),
      eyePaint,
    );

    // Draw right eye capsule
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX + 7, centerY - 16 - (eyeHeight/2), 6, eyeHeight), const Radius.circular(2.0)),
      eyeGlow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX + 7, centerY - 16 - (eyeHeight/2), 6, eyeHeight), const Radius.circular(2.0)),
      eyePaint,
    );

    // Glass Visor reflection curve (White gloss)
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(
      Path()
        ..moveTo(centerX - 20, centerY - 20)
        ..quadraticBezierTo(centerX, centerY - 24, centerX + 20, centerY - 20),
      reflectionPaint,
    );

    // 4. Draw Antenna
    final antennaPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    // draw line
    canvas.drawLine(Offset(centerX, centerY - 47), Offset(centerX, centerY - 55), antennaPaint);
    // draw glowing tip
    final double antennaPulse = 0.5 + (math.sin(animationValue * 8 * math.pi).abs() * 0.5);
    final antennaGlowColor = const Color(0xFFE040FB).withValues(alpha: antennaPulse);
    canvas.drawCircle(Offset(centerX, centerY - 56), 4.5, Paint()..color = antennaGlowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
    canvas.drawCircle(Offset(centerX, centerY - 56), 3.0, Paint()..color = const Color(0xFFE040FB));

    // 5. Draw Droid Body (Armor Suit)
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFECEFF1), Color(0xFF78909C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(centerX - 25, centerY + 10, 50, 36));

    // Neck ring
    canvas.drawOval(
      Rect.fromLTWH(centerX - 12, centerY + 11, 24, 6),
      Paint()..color = const Color(0xFF37474F),
    );

    // Main chest plate shape
    final Path bodyPath = Path()
      ..moveTo(centerX - 16, centerY + 14)
      ..lineTo(centerX + 16, centerY + 14)
      ..lineTo(centerX + 22, centerY + 34)
      ..quadraticBezierTo(centerX, centerY + 42, centerX - 22, centerY + 34)
      ..close();
    
    // Draw body shadow
    canvas.drawPath(bodyPath, Paint()..color = Colors.black.withValues(alpha: 0.15));
    // Draw body
    canvas.drawPath(bodyPath, bodyPaint);

    // Chest center neon plate (Glowing logo or circle)
    final double chestGlow = 0.4 + (math.sin(animationValue * 4 * math.pi).abs() * 0.6);
    canvas.drawCircle(
      Offset(centerX, centerY + 24),
      6.0,
      Paint()..color = const Color(0xFF00E5FF).withValues(alpha: chestGlow * 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
    canvas.drawCircle(
      Offset(centerX, centerY + 24),
      4.0,
      Paint()..color = const Color(0xFF00E5FF),
    );

    // 6. Cute floating hands
    final leftHandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFCFD8DC)],
      ).createShader(Rect.fromCircle(center: Offset(centerX - 32, centerY + 20), radius: 5.5));
      
    final rightHandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFCFD8DC)],
      ).createShader(Rect.fromCircle(center: Offset(centerX + 32, centerY + 20), radius: 5.5));

    // Floating animation offset for hands (sway back and forth)
    final double handSway = math.sin(animationValue * 2 * math.pi) * 3.0;

    canvas.drawCircle(Offset(centerX - 32, centerY + 20 + handSway), 5.5, Paint()..color = Colors.black.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(centerX - 32, centerY + 19 + handSway), 5.5, leftHandPaint);

    canvas.drawCircle(Offset(centerX + 32, centerY + 20 - handSway), 5.5, Paint()..color = Colors.black.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(centerX + 32, centerY + 19 - handSway), 5.5, rightHandPaint);
  }

  @override
  bool shouldRepaint(covariant _SpaceDroidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
