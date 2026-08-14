import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_manager.dart';

class CrashGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const CrashGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<CrashGameScreen> createState() => _CrashGameScreenState();
}

enum CrashState {
  countdown,
  flying,
  crashed,
}

class _StarParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;

  _StarParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
  });
}

class _CrashGameScreenState extends State<CrashGameScreen>
    with TickerProviderStateMixin {
  final _betController = TextEditingController(text: '100');
  final _autoCashoutController = TextEditingController(text: '2.00');

  // Game Loop States
  CrashState _gameState = CrashState.countdown;
  double _countdownTime = 5.0; // 5 seconds countdown
  double _currentMultiplier = 1.00;
  double _crashPoint = 1.00;
  double _crashedAt = 1.00;

  bool _isAutoCashoutEnabled = false;
  bool _hasPlacedBet = false;
  bool _hasCashedOut = false;
  bool _betQueued = false; // Player placed bet during countdown

  Timer? _loopTimer;
  Timer? _tickSoundTimer;
  late AnimationController _pulseController;

  final List<double> _history = [1.45, 12.80, 2.05, 1.12, 5.30, 1.89, 3.40];
  final List<_StarParticle> _particles = [];
  final math.Random _random = math.Random();

  // Animation values for the trace line
  double _traceProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.05,
    );

    _startSystemLoop();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _tickSoundTimer?.cancel();
    _pulseController.dispose();
    _betController.dispose();
    _autoCashoutController.dispose();
    super.dispose();
  }

  // Central continuous loop manager for Crash
  void _startSystemLoop() {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;

      switch (_gameState) {
        case CrashState.countdown:
          _handleCountdownStep();
          break;
        case CrashState.flying:
          _handleFlightStep();
          break;
        case CrashState.crashed:
          _handleCrashedStep();
          break;
      }
    });
  }

  void _handleCountdownStep() {
    setState(() {
      _countdownTime -= 0.05;
      if (_countdownTime <= 0.0) {
        _startFlight();
      }
    });
  }

  void _startFlight() {
    // Generate crash point
    final double randVal = _random.nextDouble();
    if (randVal < 0.10) {
      _crashPoint = 1.00 + (_random.nextDouble() * 0.05);
    } else if (randVal < 0.65) {
      _crashPoint = 1.05 + (_random.nextDouble() * 1.45);
    } else if (randVal < 0.90) {
      _crashPoint = 2.50 + (_random.nextDouble() * 7.50);
    } else if (randVal < 0.98) {
      _crashPoint = 10.0 + (_random.nextDouble() * 40.0);
    } else {
      _crashPoint = 50.0 + (_random.nextDouble() * 949.0);
    }

    setState(() {
      _gameState = CrashState.flying;
      _currentMultiplier = 1.00;
      _traceProgress = 0.0;
      _particles.clear();
      _hasCashedOut = false;
      _hasPlacedBet = _betQueued;
      _betQueued = false;
    });

    _pulseController.repeat(reverse: true);

    // Play periodic ticking sounds
    _tickSoundTimer?.cancel();
    _tickSoundTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_gameState == CrashState.flying && !_hasCashedOut) {
        SoundManager.playClick();
      }
    });
  }

  void _handleFlightStep() {
    setState(() {
      // Exponential rate
      if (_currentMultiplier < 2.0) {
        _currentMultiplier += 0.007;
      } else if (_currentMultiplier < 5.0) {
        _currentMultiplier += 0.015;
      } else if (_currentMultiplier < 15.0) {
        _currentMultiplier += 0.06;
      } else if (_currentMultiplier < 50.0) {
        _currentMultiplier += 0.3;
      } else {
        _currentMultiplier += 1.5;
      }

      _traceProgress = (_currentMultiplier / 15.0).clamp(0.0, 1.0);

      // Spawn trace particles
      _spawnParticles();

      // Check Auto Cashout
      if (_isAutoCashoutEnabled && _hasPlacedBet && !_hasCashedOut) {
        final double target = double.tryParse(_autoCashoutController.text) ?? 2.0;
        if (_currentMultiplier >= target) {
          _cashOut();
        }
      }

      // Check if crashed
      if (_currentMultiplier >= _crashPoint) {
        _triggerCrash();
      }
    });
  }

  void _spawnParticles() {
    final double startX = 40.0;
    final double startY = 220.0;
    final double endX = 280.0;
    final double endY = 50.0;

    final double px = startX + (endX - startX) * _traceProgress;
    final double py = startY + (endY - startY) * math.sin(_traceProgress * math.pi / 2);

    for (int i = 0; i < 2; i++) {
      _particles.add(_StarParticle(
        x: px,
        y: py,
        vx: -_random.nextDouble() * 2.0 - 0.5,
        vy: _random.nextDouble() * 1.5 - 0.75,
        size: _random.nextDouble() * 3.0 + 1.0,
        alpha: 1.0,
      ));
    }

    // Update particles
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.alpha = (p.alpha - 0.05).clamp(0.0, 1.0);
    }
    _particles.removeWhere((p) => p.alpha <= 0.0);
  }

  void _triggerCrash() {
    _tickSoundTimer?.cancel();
    _pulseController.stop();

    SoundManager.playClick(); // Trigger crash alert sound

    setState(() {
      _gameState = CrashState.crashed;
      _crashedAt = _crashPoint;
      _countdownTime = 4.0; // 4 seconds delay in crashed state before next countdown
      _hasPlacedBet = false;

      // Add to recent history
      _history.insert(0, double.parse(_crashPoint.toStringAsFixed(2)));
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  void _handleCrashedStep() {
    setState(() {
      _countdownTime -= 0.05;
      if (_countdownTime <= 0.0) {
        _gameState = CrashState.countdown;
        _countdownTime = 5.0; // Reset next countdown to 5s
      }
    });
  }

  void _placeBet() {
    if (_betQueued || _hasPlacedBet) return;

    final double betAmount = double.tryParse(_betController.text) ?? 10.0;
    if (betAmount <= 0.0 || betAmount > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid bet amount or insufficient balance!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Deduct balance
    widget.onBalanceChanged(widget.balance - betAmount);
    SoundManager.playClick();

    setState(() {
      _betQueued = true;
    });
  }

  void _cashOut() {
    if (!_hasPlacedBet || _hasCashedOut || _gameState != CrashState.flying) return;

    final double betAmount = double.tryParse(_betController.text) ?? 10.0;
    final double winnings = betAmount * _currentMultiplier;

    // Credit balance
    widget.onBalanceChanged(widget.balance + winnings);
    SoundManager.playClick();

    setState(() {
      _hasCashedOut = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E), // Very dark clean background
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeader(),

            // Main Columns
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Interactive Display Graph
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildDisplayArena(),
                          ),
                          const SizedBox(height: 10.0),
                          _buildHistoryRow(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),

                    // Right Column: Controls Panel
                    Container(
                      width: 290.0,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131A), // Sleek dark panel card
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFF22222A), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'BET AMOUNT',
                            style: TextStyle(
                              color: Color(0xFF8A8A93),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),

                          // Clean Bet Input Box
                          _buildBetInput(),
                          const SizedBox(height: 10.0),

                          // Unified presets
                          _buildPresetsRow(),
                          const SizedBox(height: 16.0),

                          // Auto cashout setup
                          _buildAutoCashoutControl(),

                          const Spacer(),

                          // Big Action Button
                          _buildActionButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: const Color(0xFF0A0A0E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back navigation arrow
          GestureDetector(
            onTap: widget.onBackPressed,
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18.0),
          ),

          // Central title
          Text(
            'CRASH MULTIPLIER',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Balance display exactly as screenshots
          Text(
            '₹${widget.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayArena() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12), // Matching the dark arena layout
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF22222A), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Custom trace and particle line painter
          Positioned.fill(
            child: CustomPaint(
              painter: _ArenaPainter(
                state: _gameState,
                progress: _traceProgress,
                particles: _particles,
              ),
            ),
          ),

          // State-based central messages
          Align(
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _pulseController,
              child: _buildCentralInfoWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralInfoWidget() {
    switch (_gameState) {
      case CrashState.countdown:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NEXT ROUND IN',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Color(0xFF8A8A93),
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              '${_countdownTime.toStringAsFixed(1)}s',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 42.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      case CrashState.flying:
        return Text(
          '${_currentMultiplier.toStringAsFixed(2)}x',
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              color: _hasCashedOut ? const Color(0xFF00C853) : Colors.white,
              fontSize: 52.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case CrashState.crashed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CRASHED',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              '@ ${_crashedAt.toStringAsFixed(2)}x',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 42.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBetInput() {
    return Container(
      height: 42.0,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF22222A), width: 1.2),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Text('₹', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 14.0, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: _betController,
              keyboardType: TextInputType.number,
              enabled: _gameState == CrashState.countdown,
              style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // - adjustor
          _buildAdjustorButton('-', () {
            if (_gameState != CrashState.countdown) return;
            double val = double.tryParse(_betController.text) ?? 0.0;
            val = (val - 10.0).clamp(0.0, widget.balance);
            _betController.text = val.toStringAsFixed(0);
          }),

          // + adjustor
          _buildAdjustorButton('+', () {
            if (_gameState != CrashState.countdown) return;
            double val = double.tryParse(_betController.text) ?? 0.0;
            val = (val + 10.0).clamp(0.0, widget.balance);
            _betController.text = val.toStringAsFixed(0);
          }),
        ],
      ),
    );
  }

  Widget _buildAdjustorButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF22222A), width: 1.2),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPresetsRow() {
    return Column(
      children: [
        Row(
          children: [
            _buildPresetButton('10', () {
              if (_gameState != CrashState.countdown) return;
              _betController.text = '10';
            }),
            _buildPresetButton('100', () {
              if (_gameState != CrashState.countdown) return;
              _betController.text = '100';
            }),
          ],
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            _buildPresetButton('500', () {
              if (_gameState != CrashState.countdown) return;
              _betController.text = '500';
            }),
            _buildPresetButton('1000', () {
              if (_gameState != CrashState.countdown) return;
              _betController.text = '1000';
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFF2E2E3A), width: 1.0),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoCashoutControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AUTO CASHOUT',
              style: TextStyle(
                color: Color(0xFF8A8A93),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(
              height: 24.0,
              child: Switch(
                value: _isAutoCashoutEnabled,
                onChanged: (val) {
                  setState(() {
                    _isAutoCashoutEnabled = val;
                  });
                },
                activeColor: const Color(0xFF00E5FF),
                activeTrackColor: const Color(0xFF1E1E26),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.black26,
              ),
            ),
          ],
        ),
        if (_isAutoCashoutEnabled) ...[
          const SizedBox(height: 6.0),
          Container(
            height: 38.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0E),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFF22222A), width: 1.2),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text('x', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13.0, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: _autoCashoutController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton() {
    switch (_gameState) {
      case CrashState.countdown:
        if (_betQueued) {
          return Container(
            height: 48.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E26),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFF2E2E3A), width: 1.0),
            ),
            child: const Text(
              'BET PLACED',
              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13.0, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ElevatedButton(
          onPressed: _placeBet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF), // Beautiful cyan from screenshot
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            elevation: 0.0,
          ),
          child: const Text(
            'PLACE BET',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        );

      case CrashState.flying:
        if (!_hasPlacedBet) {
          return Container(
            height: 48.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E26),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Text(
              'ROUND RUNNING',
              style: TextStyle(color: Colors.grey, fontSize: 13.0, fontWeight: FontWeight.bold),
            ),
          );
        }

        if (_hasCashedOut) {
          return Container(
            height: 48.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFF00C853), width: 1.5),
            ),
            child: const Text(
              'CASHED OUT',
              style: TextStyle(color: Color(0xFF00C853), fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
          );
        }

        final double betAmount = double.tryParse(_betController.text) ?? 10.0;
        final double currentPayout = betAmount * _currentMultiplier;

        return ElevatedButton(
          onPressed: _cashOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600), // Amber cashout button
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          child: Text(
            'CASH OUT (₹${currentPayout.toStringAsFixed(2)})',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
          ),
        );

      case CrashState.crashed:
        return Container(
          height: 48.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3), width: 1.2),
          ),
          child: const Text(
            'CRASHED',
            style: TextStyle(color: Color(0xFFFF5252), fontSize: 13.5, fontWeight: FontWeight.w900),
          ),
        );
    }
  }

  Widget _buildHistoryRow() {
    return SizedBox(
      height: 24.0,
      child: Row(
        children: [
          const Text(
            'History:',
            style: TextStyle(color: Colors.grey, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final double val = _history[index];
                final bool isHigh = val >= 2.0;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: isHigh ? const Color(0xFF00C853).withOpacity(0.1) : const Color(0xFFFF5252).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: isHigh ? const Color(0xFF00C853) : const Color(0xFFFF5252), width: 1.0),
                  ),
                  child: Text(
                    '${val.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: isHigh ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  final CrashState state;
  final double progress;
  final List<_StarParticle> particles;

  _ArenaPainter({
    required this.state,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF22222A).withOpacity(0.2)
      ..strokeWidth = 1.0;

    final double step = 25.0;
    for (double x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double startX = 40.0;
    final double startY = size.height - 40.0;
    final double endX = size.width - 40.0;
    final double endY = 40.0;

    // Draw axis markers matching screenshot
    final Paint axisPaint = Paint()
      ..color = const Color(0xFF22222A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(startX, startY), Offset(size.width, startY), axisPaint);
    canvas.drawLine(Offset(startX, 0), Offset(startX, startY), axisPaint);

    if (state == CrashState.flying || state == CrashState.crashed) {
      final double midX = startX + (endX - startX) * progress;
      final double midY = startY + (endY - startY) * math.sin(progress * math.pi / 2);

      // Trajectory stroke
      final Path tracePath = Path()..moveTo(startX, startY);
      for (double t = 0.0; t <= progress; t += 0.01) {
        final double currX = startX + (endX - startX) * t;
        final double currY = startY + (endY - startY) * math.sin(t * math.pi / 2);
        tracePath.lineTo(currX, currY);
      }

      final Paint tracePaint = Paint()
        ..color = state == CrashState.crashed ? const Color(0xFFFF5252) : const Color(0xFF00E5FF)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawPath(tracePath, tracePaint);

      // Gradient shadow trace trace fill
      final Path fillPath = Path()..moveTo(startX, startY);
      for (double t = 0.0; t <= progress; t += 0.01) {
        final double currX = startX + (endX - startX) * t;
        final double currY = startY + (endY - startY) * math.sin(t * math.pi / 2);
        fillPath.lineTo(currX, currY);
      }
      fillPath.lineTo(midX, startY);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            state == CrashState.crashed ? const Color(0xFFFF5252).withOpacity(0.12) : const Color(0xFF00E5FF).withOpacity(0.12),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(startX, endY, endX, startY))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Trajectory end glowing marker
      final Paint markerPaint = Paint()
        ..color = state == CrashState.crashed ? const Color(0xFFFF5252) : const Color(0xFF00E5FF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(midX, midY), 6.0, markerPaint);
      canvas.drawCircle(
        Offset(midX, midY),
        12.0,
        Paint()
          ..color = (state == CrashState.crashed ? const Color(0xFFFF5252) : const Color(0xFF00E5FF)).withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }

    // Draw particle traces
    for (var p in particles) {
      final Paint pPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) => true;
}
