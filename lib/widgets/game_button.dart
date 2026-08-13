import 'package:flutter/material.dart';

class GameButton extends StatefulWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final double fontSize;

  const GameButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
    required this.onPressed,
    this.width,
    this.height = 50.0,
    this.fontSize = 15.0,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // Generate a darker color for the bottom 3D shadow rim
  Color _getDarkerColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    // Decrease value (brightness) to make it darker
    final double newValue = (hsv.value - 0.18).clamp(0.0, 1.0);
    // Increase saturation slightly to make it richer
    final double newSaturation = (hsv.saturation + 0.1).clamp(0.0, 1.0);
    return hsv.withValue(newValue).withSaturation(newSaturation).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final Color topColor = widget.backgroundColor;
    final Color bottomShadowColor = _getDarkerColor(topColor);

    // Duolingo-style button press offset:
    // When idle: top face is shifted up by 4px, showing the 4px shadow at the bottom.
    // When pressed: top face shifts down by 4px, covering the shadow.
    final double shadowHeight = 4.0;
    final double offsetTop = _isPressed ? shadowHeight : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: widget.width,
          height: widget.height + shadowHeight,
          child: Stack(
            children: [
              // 1. The Bottom 3D Shadow Layer
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: bottomShadowColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              // 2. The Interactive Top Face Layer
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: offsetTop,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isHovered 
                        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), topColor) 
                        : topColor,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: topColor.withValues(alpha: 0.35),
                        blurRadius: _isHovered ? 16.0 : 8.0,
                        spreadRadius: _isHovered ? 1.5 : 0.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Shimmer sheen overlay
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            final double offset = -2.0 + (_shimmerController.value * 4.0);
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(offset, -1.0),
                                  end: Alignment(offset + 1.5, 1.0),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.28),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Text content
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            widget.text.toUpperCase(),
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
