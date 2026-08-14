import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

enum CrashState { countdown, flying, crashed }

class _Particle {
  double x, y, vx, vy, size, alpha;
  _Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.size, required this.alpha,
  });
}

class _CrashGameScreenState extends State<CrashGameScreen>
    with TickerProviderStateMixin {
  final _betController = TextEditingController(text: '100');
  final _autoCashoutController = TextEditingController(text: '2.00');

  CrashState _gameState = CrashState.countdown;

  // Countdown
  double _countdownSeconds = 5.0;

  // Flight
  double _currentMultiplier = 1.00;
  double _crashPoint = 2.00;
  double _crashedAtMultiplier = 1.00;

  // Time-based trace: 0.0 → 1.0 over FLIGHT_DURATION seconds
  // The visual trace uses elapsed flight time, independent of multiplier.
  double _flightElapsed = 0.0;
  static const double _flightDuration = 12.0; // seconds to reach end of canvas

  // Post-crash delay before next round
  double _crashedDelay = 4.0;
  // Value to add to history only once, after crash overlay is shown
  double? _pendingHistoryEntry;

  // Bet state
  bool _hasPlacedBet = false;
  bool _betQueued = false;
  bool _hasCashedOut = false;
  bool _isAutoCashoutEnabled = false;

  // History (initially empty-looking, will fill with rounds)
  final List<double> _history = [3.40, 1.89, 5.30, 1.12, 2.05, 12.80, 1.45];

  // Particles attached to the tip of the trace line
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  // Ticker — fires every frame for smooth animation
  Ticker? _ticker; // from flutter/scheduler.dart
  Duration _lastTick = Duration.zero;

  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.93,
      upperBound: 1.07,
    );

    // Use a Ticker (frame-by-frame) instead of a Timer so animation is smooth
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _pulseAnim.dispose();
    _betController.dispose();
    _autoCashoutController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // Calculate delta in seconds since last frame
    final double dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    setState(() {
      switch (_gameState) {
        case CrashState.countdown:
          _countdownSeconds = (_countdownSeconds - dt).clamp(0.0, 100.0);
          if (_countdownSeconds <= 0.0) _beginFlight();
          break;

        case CrashState.flying:
          _flightElapsed += dt;

          // Multiplier grows exponentially with time
          _currentMultiplier = _exponentialMultiplier(_flightElapsed);

          // Spawn particles at current tip
          _spawnParticles();

          // Fade existing particles
          for (var p in _particles) {
            p.x += p.vx;
            p.y += p.vy;
            p.alpha = (p.alpha - dt * 2.5).clamp(0.0, 1.0);
          }
          _particles.removeWhere((p) => p.alpha <= 0.0);

          // Auto cashout
          if (_isAutoCashoutEnabled && _hasPlacedBet && !_hasCashedOut) {
            final double target =
                double.tryParse(_autoCashoutController.text) ?? 2.0;
            if (_currentMultiplier >= target) _cashOut();
          }

          // Check crash
          if (_currentMultiplier >= _crashPoint) _triggerCrash();
          break;

        case CrashState.crashed:
          // Particles still fade during crashed state
          for (var p in _particles) {
            p.alpha = (p.alpha - dt * 3.0).clamp(0.0, 1.0);
          }
          _particles.removeWhere((p) => p.alpha <= 0.0);

          _crashedDelay = (_crashedDelay - dt).clamp(0.0, 100.0);
          if (_crashedDelay <= 0.0) _beginCountdown();
          break;
      }
    });
  }

  // Exponential multiplier that starts at 1.0 and accelerates
  double _exponentialMultiplier(double t) {
    // Starts at 1.0, roughly doubles every 3 seconds
    return math.pow(math.e, 0.231 * t).toDouble();
  }

  void _beginFlight() {
    // Generate crash point using a house-edge curve
    final double r = _rng.nextDouble();
    if (r < 0.08) {
      _crashPoint = 1.00 + _rng.nextDouble() * 0.10;
    } else if (r < 0.60) {
      _crashPoint = 1.10 + _rng.nextDouble() * 1.40;
    } else if (r < 0.88) {
      _crashPoint = 2.50 + _rng.nextDouble() * 7.50;
    } else if (r < 0.97) {
      _crashPoint = 10.0 + _rng.nextDouble() * 40.0;
    } else {
      _crashPoint = 50.0 + _rng.nextDouble() * 449.0;
    }

    _gameState = CrashState.flying;
    _currentMultiplier = 1.00;
    _flightElapsed = 0.0;
    _particles.clear();
    _hasCashedOut = false;
    _hasPlacedBet = _betQueued;
    _betQueued = false;
    _pulseAnim.repeat(reverse: true);
  }

  void _triggerCrash() {
    _crashedAtMultiplier = _currentMultiplier;
    _pendingHistoryEntry = double.parse(_currentMultiplier.toStringAsFixed(2));
    _pulseAnim.stop();
    _gameState = CrashState.crashed;
    _crashedDelay = 4.0;
    _hasPlacedBet = false;
    SoundManager.playClick();
  }

  void _beginCountdown() {
    // Add to history now (so it appears AFTER the crashed overlay)
    if (_pendingHistoryEntry != null) {
      _history.insert(0, _pendingHistoryEntry!);
      if (_history.length > 10) _history.removeLast();
      _pendingHistoryEntry = null;
    }

    _gameState = CrashState.countdown;
    _countdownSeconds = 5.0;
    _flightElapsed = 0.0;
    _particles.clear();
  }

  // Spawn glowing particles at the current tip position
  void _spawnParticles() {
    // We'll pass size-relative coords through a GlobalKey approach is complex,
    // so we use normalised [0–1] coords and let the painter resolve them.
    // Instead, spawn directly in fractional space and let painter scale.
    final double prog = _traceProgress;
    // Fractional tip x,y (will be multiplied by canvas size in painter)
    final double fx = prog;
    final double fy = 1.0 - math.sin(prog * math.pi / 2);
    for (int i = 0; i < 2; i++) {
      _particles.add(_Particle(
        x: fx,
        y: fy,
        vx: (_rng.nextDouble() - 0.7) * 0.008,
        vy: (_rng.nextDouble() - 0.5) * 0.006,
        size: _rng.nextDouble() * 0.012 + 0.004,
        alpha: 1.0,
      ));
    }
  }

  // Visual trace progress: time-based, goes 0→1 over _flightDuration seconds
  double get _traceProgress {
    if (_gameState == CrashState.countdown) return 0.0;
    return (_flightElapsed / _flightDuration).clamp(0.0, 1.0);
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _placeBet() {
    if (_betQueued || _hasPlacedBet || _gameState != CrashState.countdown) return;
    final double bet = double.tryParse(_betController.text) ?? 10.0;
    if (bet <= 0.0 || bet > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid bet or insufficient balance!'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    widget.onBalanceChanged(widget.balance - bet);
    SoundManager.playClick();
    setState(() => _betQueued = true);
  }

  void _cashOut() {
    if (!_hasPlacedBet || _hasCashedOut || _gameState != CrashState.flying) return;
    final double bet = double.tryParse(_betController.text) ?? 10.0;
    widget.onBalanceChanged(widget.balance + bet * _currentMultiplier);
    SoundManager.playClick();
    setState(() => _hasCashedOut = true);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left: Bet Panel ──────────────────────────────────
                    _buildBetPanel(),
                    const SizedBox(width: 14.0),

                    // ── Right: History + Arena ───────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHistoryRow(),
                          const SizedBox(height: 8.0),
                          Expanded(child: _buildArena()),
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

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: const Color(0xFF0A0A0E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBackPressed,
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18.0),
          ),
          Text('CRASH MULTIPLIER',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              )),
          Text(
            '₹${widget.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF00E5FF), fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─── History Row ──────────────────────────────────────────────────────────

  Widget _buildHistoryRow() {
    return SizedBox(
      height: 26.0,
      child: Row(
        children: [
          Text('History:',
              style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                      color: Color(0xFF8A8A93),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 6.0),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              itemBuilder: (context, i) {
                final v = _history[i];
                final high = v >= 2.0;
                final color = high ? const Color(0xFF00C853) : const Color(0xFFFF5252);
                return Container(
                  margin: const EdgeInsets.only(right: 6.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: color, width: 1.0),
                  ),
                  child: Text('${v.toStringAsFixed(2)}x',
                      style: TextStyle(
                          color: color,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Arena ────────────────────────────────────────────────────────────────

  Widget _buildArena() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFF1E1E26), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated trace canvas
          CustomPaint(
            painter: _ArenaPainter(
              state: _gameState,
              progress: _traceProgress,
              particles: _particles,
              multiplier: _currentMultiplier,
            ),
          ),

          // Central overlay
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCenterOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterOverlay() {
    switch (_gameState) {
      case CrashState.countdown:
        return Column(
          key: const ValueKey('countdown'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NEXT ROUND IN',
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        color: Color(0xFF8A8A93),
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4))),
            const SizedBox(height: 6.0),
            Text('${_countdownSeconds.toStringAsFixed(1)}s',
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 44.0,
                        fontWeight: FontWeight.w900))),
          ],
        );

      case CrashState.flying:
        return ScaleTransition(
          scale: _pulseAnim,
          child: Text(
            '${_currentMultiplier.toStringAsFixed(2)}x',
            key: const ValueKey('flying'),
            style: GoogleFonts.roboto(
                textStyle: TextStyle(
                    color: _hasCashedOut
                        ? const Color(0xFF00C853)
                        : Colors.white,
                    fontSize: 52.0,
                    fontWeight: FontWeight.w900)),
          ),
        );

      case CrashState.crashed:
        return Column(
          key: const ValueKey('crashed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CRASHED',
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5))),
            const SizedBox(height: 4.0),
            Text('@ ${_crashedAtMultiplier.toStringAsFixed(2)}x',
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 42.0,
                        fontWeight: FontWeight.w900))),
          ],
        );
    }
  }

  // ─── Bet Panel ────────────────────────────────────────────────────────────

  Widget _buildBetPanel() {
    return Container(
      width: 280.0,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFF1E1E26), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('BET AMOUNT',
              style: TextStyle(
                  color: Color(0xFF8A8A93),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6.0),
          _buildBetInput(),
          const SizedBox(height: 10.0),
          _buildPresets(),
          const SizedBox(height: 14.0),
          _buildAutoCashout(),
          const Spacer(),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildBetInput() {
    final bool locked = _gameState != CrashState.countdown;
    return Container(
      height: 42.0,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF1E1E26), width: 1.2),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Text('₹',
                style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: _betController,
              enabled: !locked,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            ),
          ),
          _adjBtn('-', () {
            if (locked) return;
            final v = (double.tryParse(_betController.text) ?? 0.0) - 10.0;
            _betController.text = v.clamp(0.0, widget.balance).toStringAsFixed(0);
          }),
          _adjBtn('+', () {
            if (locked) return;
            final v = (double.tryParse(_betController.text) ?? 0.0) + 10.0;
            _betController.text = v.clamp(0.0, widget.balance).toStringAsFixed(0);
          }),
        ],
      ),
    );
  }

  Widget _adjBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFF1E1E26), width: 1.2))),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13.0, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildPresets() {
    return Column(
      children: [
        Row(children: [
          _presetBtn('10', '10'),
          const SizedBox(width: 6.0),
          _presetBtn('100', '100'),
        ]),
        const SizedBox(height: 6.0),
        Row(children: [
          _presetBtn('500', '500'),
          const SizedBox(width: 6.0),
          _presetBtn('1000', '1000'),
        ]),
      ],
    );
  }

  Widget _presetBtn(String label, String value) => Expanded(
        child: GestureDetector(
          onTap: () {
            if (_gameState != CrashState.countdown) return;
            _betController.text = value;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF2A2A34), width: 1.0),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _buildAutoCashout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AUTO CASHOUT',
                style: TextStyle(
                    color: Color(0xFF8A8A93),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            SizedBox(
              height: 24.0,
              child: Switch(
                value: _isAutoCashoutEnabled,
                onChanged: (v) => setState(() => _isAutoCashoutEnabled = v),
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
              border: Border.all(color: const Color(0xFF1E1E26), width: 1.2),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text('x',
                      style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: _autoCashoutController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero),
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
          return _statusBox('BET PLACED', const Color(0xFF00E5FF));
        }
        return ElevatedButton(
          onPressed: _placeBet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            elevation: 0.0,
          ),
          child: const Text('PLACE BET',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        );

      case CrashState.flying:
        if (!_hasPlacedBet) return _statusBox('ROUND RUNNING', Colors.grey);
        if (_hasCashedOut) {
          return _statusBox('CASHED OUT ✓', const Color(0xFF00C853));
        }
        final double bet = double.tryParse(_betController.text) ?? 10.0;
        final double payout = bet * _currentMultiplier;
        return ElevatedButton(
          onPressed: _cashOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          child: Text('CASH OUT  ₹${payout.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w900)),
        );

      case CrashState.crashed:
        return _statusBox('CRASHED', const Color(0xFFFF5252));
    }
  }

  Widget _statusBox(String label, Color color) => Container(
        height: 48.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 13.5, fontWeight: FontWeight.w900)),
      );
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _ArenaPainter extends CustomPainter {
  final CrashState state;
  final double progress; // 0→1 time-based
  final List<_Particle> particles;
  final double multiplier;

  _ArenaPainter({
    required this.state,
    required this.progress,
    required this.particles,
    required this.multiplier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Padding for the graph area
    const double padL = 36.0;
    const double padB = 30.0;
    const double padR = 16.0;
    const double padT = 16.0;

    final double gLeft = padL;
    final double gRight = w - padR;
    final double gTop = padT;
    final double gBot = h - padB;
    final double gW = gRight - gLeft;
    final double gH = gBot - gTop;

    // ── Grid ──
    final gridP = Paint()
      ..color = const Color(0xFF1E1E26)
      ..strokeWidth = 0.8;
    final int hLines = 5;
    final int vLines = 8;
    for (int i = 0; i <= hLines; i++) {
      final double y = gTop + gH * i / hLines;
      canvas.drawLine(Offset(gLeft, y), Offset(gRight, y), gridP);
    }
    for (int i = 0; i <= vLines; i++) {
      final double x = gLeft + gW * i / vLines;
      canvas.drawLine(Offset(x, gTop), Offset(x, gBot), gridP);
    }

    // ── Axes ──
    final axisP = Paint()
      ..color = const Color(0xFF2E2E3A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(gLeft, gBot), Offset(gRight, gBot), axisP); // X
    canvas.drawLine(Offset(gLeft, gTop), Offset(gLeft, gBot), axisP); // Y

    // Axis labels
    final labelStyle = const TextStyle(color: Color(0xFF555560), fontSize: 9.0);
    void drawLabel(String text, Offset pos) {
      final span = TextSpan(text: text, style: labelStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, pos);
    }
    drawLabel('1.0x', Offset(0, gBot - 8));
    drawLabel('10x', Offset(0, gTop + gH * 0.4));
    drawLabel('99x', Offset(0, gTop));

    if (state == CrashState.flying || state == CrashState.crashed) {
      final bool crashed = state == CrashState.crashed;
      final Color lineColor =
          crashed ? const Color(0xFFFF5252) : const Color(0xFF00E5FF);

      // Map progress → canvas coords using a curved path
      // X grows linearly. Y uses a sigmoid-like curve so the line starts
      // nearly flat then curves upward — matching typical crash game look.
      Offset ptAt(double t) {
        final double x = gLeft + gW * t;
        // Ease: starts slow, accelerates upward
        final double easedY = t < 0.0001 ? 0.0 : math.pow(t, 0.55).toDouble();
        final double y = gBot - gH * easedY;
        return Offset(x, y.clamp(gTop, gBot));
      }

      final double tipT = progress.clamp(0.0, 1.0);

      // Build trace path
      final tracePath = Path();
      tracePath.moveTo(gLeft, gBot);
      const int steps = 80;
      for (int i = 1; i <= steps; i++) {
        final double t = tipT * i / steps;
        final p = ptAt(t);
        tracePath.lineTo(p.dx, p.dy);
      }

      final Offset tip = ptAt(tipT);

      // Fill under the curve
      final fillPath = Path.from(tracePath);
      fillPath.lineTo(tip.dx, gBot); // close fill under curve
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            colors: [lineColor.withOpacity(0.18), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTRB(gLeft, gTop, gRight, gBot))
          ..style = PaintingStyle.fill,
      );

      // Draw the curve itself
      canvas.drawPath(
        tracePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Tip marker glow
      if (!crashed) {
        canvas.drawCircle(
          tip,
          10.0,
          Paint()..color = lineColor.withOpacity(0.20),
        );
      }
      canvas.drawCircle(tip, 5.0, Paint()..color = lineColor);

      // ── Particles (fractional coords scaled to canvas) ──
      for (final p in particles) {
        final double px = gLeft + p.x * gW;
        final double py = gTop + p.y * gH;
        canvas.drawCircle(
          Offset(px, py),
          p.size * gW,
          Paint()
            ..color = lineColor.withOpacity(p.alpha * 0.85)
            ..style = PaintingStyle.fill,
        );
      }

      // Live multiplier label near the tip
      if (!crashed && tipT > 0.02) {
        final labelSpan = TextSpan(
          text: '${multiplier.toStringAsFixed(2)}x',
          style: TextStyle(
            color: lineColor,
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(
          canvas,
          Offset(
            (tip.dx + 8.0).clamp(gLeft, gRight - tp.width),
            (tip.dy - tp.height - 4.0).clamp(gTop, gBot),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter old) =>
      old.progress != progress ||
      old.state != state ||
      old.particles.length != particles.length;
}
