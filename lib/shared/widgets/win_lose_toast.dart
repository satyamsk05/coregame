import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a small centered win/lose toast overlay over the current screen.
/// Automatically dismisses after [duration].
void showWinLoseToast(
  BuildContext context, {
  required bool isWin,
  required String title,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _WinLoseToast(
      isWin: isWin,
      title: title,
      message: message,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
      duration: duration,
    ),
  );

  overlay.insert(entry);
}

// ─────────────────────────────────────────────────────────────────────────────

class _WinLoseToast extends StatefulWidget {
  final bool isWin;
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final Duration duration;

  const _WinLoseToast({
    required this.isWin,
    required this.title,
    required this.message,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_WinLoseToast> createState() => _WinLoseToastState();
}

class _WinLoseToastState extends State<_WinLoseToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    _dismissTimer = Timer(widget.duration, () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary =
        widget.isWin ? const Color(0xFF00E396) : const Color(0xFFFF4560);
    final Color bg =
        widget.isWin ? const Color(0xFF071A10) : const Color(0xFF1A0508);

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTap: () async {
                _dismissTimer?.cancel();
                await _ctrl.reverse();
                widget.onDismiss();
              },
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 260,
                  minWidth: 200,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 18.0),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 24.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon circle
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.15),
                        border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Icon(
                        widget.isWin ? Icons.emoji_events_rounded : Icons.close_rounded,
                        color: primary,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        textStyle: TextStyle(
                          color: primary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.0,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
