import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';

class GameLoadingScreen extends StatefulWidget {
  final String gameKey;
  final VoidCallback onLoadingComplete;

  const GameLoadingScreen({
    super.key,
    required this.gameKey,
    required this.onLoadingComplete,
  });

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen> {
  double _progress = 0.0;
  String _statusText = "INITIALIZING SYSTEM...";
  Timer? _progressTimer;
  Timer? _statusTimer;
  int _statusIndex = 0;

  final List<String> _statuses = [
    "CONNECTING TO CASINO NODE...",
    "VERIFYING CRYPTO WALLET...",
    "LOADING RETRO SHADERS...",
    "SYNCHRONIZING BALANCES...",
    "GENERATING CRYPTOGRAPHIC SEED...",
    "SPAWNING GAME BOARD...",
    "READY TO PLAY!"
  ];

  @override
  void initState() {
    super.initState();
    
    // Animate progress bar from 0.0 to 1.0 over 1.8 seconds
    const int totalDurationMs = 1800;
    const int intervalMs = 30;
    final int steps = totalDurationMs ~/ intervalMs;
    int currentStep = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = (currentStep / steps).clamp(0.0, 1.0);
        });
      }

      if (currentStep >= steps) {
        _progressTimer?.cancel();
        _statusTimer?.cancel();
        widget.onLoadingComplete();
      }
    });

    // Cycle status messages
    _statusTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_statusIndex < _statuses.length - 1) {
        _statusIndex++;
        if (mounted) {
          setState(() {
            _statusText = _statuses[_statusIndex];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  String _getGameTitle(String key) {
    switch (key.toLowerCase()) {
      case 'plinko':
        return 'PLINKO CASCADE';
      case 'coin_flip':
        return 'COIN SPIN CYBER';
      case 'limbo':
        return 'LIMBO MULTIPLIER';
      case 'dice':
        return 'CYBER ROLL DICE';
      case 'roulette':
        return 'NEON ROULETTE';
      case 'mines':
        return 'CRYPTO MINES';
      case 'hilo':
        return 'HI-LO PREDICT';
      case 'seven_up_down':
        return '7 UP 7 DOWN';
      case 'keno':
        return 'RETRO KENO';
      default:
        return 'LOADING GAME';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String gameTitle = _getGameTitle(widget.gameKey);
    final int percent = (_progress * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0523),
      body: AnimatedGameBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 200.0,
              maxWidth: 420.0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF16103A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.4),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.15),
                  blurRadius: 20.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Title
                Text(
                  gameTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(color: Color(0xFFE040FB), blurRadius: 8.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Custom Retro progress bar
                Container(
                  height: 18.0,
                  width: double.infinity,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: const Color(0xFF00E5FF),
                      width: 1.5,
                    ),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(3.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF00C853)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Percentage and Status info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _statusText,
                        style: GoogleFonts.pressStart2p(
                          textStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 6.0,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '$percent%',
                      style: GoogleFonts.pressStart2p(
                        textStyle: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
