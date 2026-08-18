import 'package:flutter/material.dart';
import '../../utils/sound_manager.dart';

class Bounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool playClickSound;

  const Bounceable({
    super.key,
    required this.child,
    required this.onTap,
    this.playClickSound = true,
  });

  @override
  State<Bounceable> createState() => _BounceableState();
}

class _BounceableState extends State<Bounceable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null ? null : (_) {
        setState(() => _isPressed = false);
        if (widget.playClickSound) {
          SoundManager.playClick();
        }
        widget.onTap!();
      },
      onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
