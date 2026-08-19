import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/widgets/bounceable.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/sound_manager.dart';
import '../../shared/widgets/win_overlay_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
enum CrashState { countdown, flying, crashed }

class _Particle {
  double fx, fy, vx, vy, sz, alpha;
  _Particle({
    required this.fx, required this.fy,
    required this.vx, required this.vy,
    required this.sz, required this.alpha,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class _CrashGameScreenState extends State<CrashGameScreen>
    with TickerProviderStateMixin {

  // ── game state ──────────────────────────────────────────────────────────
  CrashState _state = CrashState.countdown;
  double _countdown   = 5.0;
  double _crashDelay  = 4.0;
  double _elapsed     = 0.0;       // seconds since flight began
  double _multi       = 1.00;      // current multiplier
  double _crashPoint  = 2.00;      // randomised crash target
  double _crashedAt   = 1.00;      // frozen multi when crashed

  // ── bet / cashout ───────────────────────────────────────────────────────
  final _betCtrl = TextEditingController(text: '100');
  final _autoCashoutCtrl = TextEditingController(text: '2.00');
  bool _betQueued   = false;
  bool _hasBet      = false;
  bool _cashedOut   = false;
  bool _autoEnabled = false;

  double _cashedOutMulti = 1.0;
  double _cashedOutAmount = 0.0;

  // ── history (pending entry added after crash delay) ─────────────────────
  final List<double> _history = [3.40, 1.89, 5.30, 1.12, 2.05, 12.80, 1.45];
  double? _pendingHistory;

  // ── particles ───────────────────────────────────────────────────────────
  final List<_Particle> _particles = [];
  final _rng = math.Random();

  // ── animation ───────────────────────────────────────────────────────────
  static const double _vizDuration = 14.0; // secs for trace to reach canvas right edge
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  late AnimationController _pulseCtrl;
  late AnimationController _flashCtrl;   // crash flash overlay

  double get _traceProgress =>
      _state == CrashState.countdown ? 0.0 : (_elapsed / _vizDuration).clamp(0.0, 1.0);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700),
        lowerBound: 0.92, upperBound: 1.08)
      ..repeat(reverse: true);

    _flashCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    _betCtrl.dispose();
    _autoCashoutCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final double dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    setState(() {
      switch (_state) {
        case CrashState.countdown:
          _countdown = (_countdown - dt).clamp(0.0, 99.0);
          if (_countdown <= 0.0) _beginFlight();
          break;

        case CrashState.flying:
          _elapsed += dt;
          _multi = math.pow(math.e, 0.231 * _elapsed).toDouble();
          _spawnParticles();
          _fadeParticles(dt);
          // Auto cashout
          if (_autoEnabled && _hasBet && !_cashedOut) {
            final t = double.tryParse(_autoCashoutCtrl.text) ?? 2.0;
            if (_multi >= t) _cashOut();
          }
          if (_multi >= _crashPoint) _triggerCrash();
          break;

        case CrashState.crashed:
          _fadeParticles(dt);
          _crashDelay = (_crashDelay - dt).clamp(0.0, 99.0);
          if (_crashDelay <= 0.0) _beginCountdown();
          break;
      }
    });
  }

  void _spawnParticles() {
    final double prog = _traceProgress;
    // fractional coords – painter will scale to canvas
    final double fx = prog;
    final double fy = 1.0 - math.pow(prog, 0.55);
    for (int i = 0; i < 3; i++) {
      _particles.add(_Particle(
        fx: fx, fy: fy,
        vx: (_rng.nextDouble() - 0.6) * 0.009,
        vy: (_rng.nextDouble() - 0.3) * 0.007,
        sz: _rng.nextDouble() * 0.014 + 0.004,
        alpha: 1.0,
      ));
    }
    if (_particles.length > 120) _particles.removeRange(0, 20);
  }

  void _fadeParticles(double dt) {
    for (var p in _particles) {
      p.fx += p.vx;
      p.fy += p.vy;
      p.alpha = (p.alpha - dt * 2.8).clamp(0.0, 1.0);
    }
    _particles.removeWhere((p) => p.alpha <= 0.0);
  }

  void _beginFlight() {
    final double r = _rng.nextDouble();
    if (r < 0.08)       _crashPoint = 1.00 + _rng.nextDouble() * 0.10;
    else if (r < 0.60)  _crashPoint = 1.10 + _rng.nextDouble() * 1.40;
    else if (r < 0.88)  _crashPoint = 2.50 + _rng.nextDouble() * 7.50;
    else if (r < 0.97)  _crashPoint = 10.0 + _rng.nextDouble() * 40.0;
    else                _crashPoint = 50.0 + _rng.nextDouble() * 449.0;

    _state     = CrashState.flying;
    _multi     = 1.00;
    _elapsed   = 0.0;
    _cashedOut = false;
    _hasBet    = _betQueued;
    _betQueued = false;
    _particles.clear();
    _flashCtrl.reset();
  }

  void _triggerCrash() {
    _crashedAt      = _multi;
    _pendingHistory = double.parse(_multi.toStringAsFixed(2));
    _state          = CrashState.crashed;
    _crashDelay     = 4.0;
    _hasBet         = false;
    _flashCtrl.forward();
    SoundManager.playClick();
  }

  void _beginCountdown() {
    if (_pendingHistory != null) {
      _history.insert(0, _pendingHistory!);
      if (_history.length > 12) _history.removeLast();
      _pendingHistory = null;
    }
    _state     = CrashState.countdown;
    _countdown = 5.0;
    _elapsed   = 0.0;
    _particles.clear();
    _flashCtrl.reset();
  }

  void _placeBet() {
    if (_betQueued || _hasBet || _state != CrashState.countdown) return;
    final double bet = double.tryParse(_betCtrl.text) ?? 10.0;
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
    if (!_hasBet || _cashedOut || _state != CrashState.flying) return;
    final double bet = double.tryParse(_betCtrl.text) ?? 10.0;
    _cashedOutMulti = _multi;
    _cashedOutAmount = bet * _multi;
    widget.onBalanceChanged(widget.balance + _cashedOutAmount);
    SoundManager.playClick();
    setState(() => _cashedOut = true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isCrashed  = _state == CrashState.crashed;
    final isFlying   = _state == CrashState.flying;

    final Color accentColor = isCrashed
        ? const Color(0xFFFF4560)
        : isFlying && _cashedOut
            ? const Color(0xFF00E396)
            : const Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ────────────────────────────────────────────────
            _TopBar(
              balance: widget.balance,
              onBack: widget.onBackPressed,
              accentColor: accentColor,
            ),

            // ── CHART (fills remaining space) ──────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bet panel
                    _BetPanel(
                      state: _state,
                      betCtrl: _betCtrl,
                      autoCashoutCtrl: _autoCashoutCtrl,
                      balance: widget.balance,
                      betQueued: _betQueued,
                      hasBet: _hasBet,
                      cashedOut: _cashedOut,
                      autoEnabled: _autoEnabled,
                      currentMulti: _multi,
                      accentColor: accentColor,
                      onAutoToggle: (v) => setState(() => _autoEnabled = v),
                      onAdjust: (delta) {
                        if (_state != CrashState.countdown) return;
                        final v = (double.tryParse(_betCtrl.text) ?? 0.0) + delta;
                        _betCtrl.text = v.clamp(0.0, widget.balance).toStringAsFixed(0);
                      },
                      onPreset: (val) {
                        if (_state != CrashState.countdown) return;
                        _betCtrl.text = val;
                      },
                      onPlaceBet: _placeBet,
                      onCashOut: _cashOut,
                    ),
                    const SizedBox(width: 12),

                    // Chart arena
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _flashCtrl,
                        builder: (_, __) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCrashed
                                    ? const Color(0xFFFF4560).withOpacity(0.4 * (1 - _flashCtrl.value))
                                    : const Color(0xFF1A2033),
                                width: 1.2,
                              ),
                              color: Color.lerp(
                                const Color(0xFF0C101A),
                                const Color(0xFF2A0510),
                                isCrashed ? _flashCtrl.value * 0.35 : 0.0,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Grid + curve
                                CustomPaint(
                                  painter: _ChartPainter(
                                    state: _state,
                                    progress: _traceProgress,
                                    particles: _particles,
                                    accentColor: accentColor,
                                    multi: _multi,
                                    crashedAt: _crashedAt,
                                  ),
                                ),
                                // Centre HUD
                                Center(child: _buildHud(accentColor)),

                                // History Bar inside top of Chart Arena
                                Positioned(
                                  top: 8.0,
                                  left: 8.0,
                                  right: 8.0,
                                  child: _HistoryBar(history: _history),
                                ),

                                // Win Overlay Card in center of Chart Arena when cashed out
                                if (_cashedOut)
                                  Center(
                                    child: WinOverlayCard(
                                      multiplier: _cashedOutMulti,
                                      winAmount: _cashedOutAmount,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
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

  Widget _buildHud(Color accent) {
    switch (_state) {
      case CrashState.countdown:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('STARTING IN',
                style: GoogleFonts.robotoMono(
                    textStyle: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10, fontWeight: FontWeight.bold,
                        letterSpacing: 1.5))),
            const SizedBox(height: 4),
            Text(_countdown.toStringAsFixed(1),
                style: GoogleFonts.robotoMono(
                    textStyle: const TextStyle(
                        color: Color(0xFF00D2FF),
                        fontSize: 56, fontWeight: FontWeight.w900))),
            Text('seconds',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 10)),
          ],
        );

      case CrashState.flying:
        return ScaleTransition(
          scale: _pulseCtrl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_multi.toStringAsFixed(2)}×',
                  style: GoogleFonts.robotoMono(
                      textStyle: TextStyle(
                          color: accent,
                          fontSize: 58, fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: accent.withOpacity(0.6), blurRadius: 18),
                          ]))),
              if (_cashedOut)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E396).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00E396), width: 1),
                  ),
                  child: Text('CASHED OUT ✓',
                      style: const TextStyle(
                          color: Color(0xFF00E396),
                          fontSize: 11, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        );

      case CrashState.crashed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CRASHED',
                style: GoogleFonts.robotoMono(
                    textStyle: const TextStyle(
                        color: Color(0xFFFF4560),
                        fontSize: 13, fontWeight: FontWeight.w900,
                        letterSpacing: 2))),
            const SizedBox(height: 2),
            Text('@  ${_crashedAt.toStringAsFixed(2)}×',
                style: GoogleFonts.robotoMono(
                    textStyle: const TextStyle(
                        color: Color(0xFFFF4560),
                        fontSize: 46, fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                              color: Color(0xAAFF4560), blurRadius: 20)
                        ]))),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final double balance;
  final VoidCallback onBack;
  final Color accentColor;
  const _TopBar({required this.balance, required this.onBack, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF080B10),
        border: Border(bottom: BorderSide(color: Color(0xFF141825), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16.0),
            ),
          ),
          const SizedBox(width: 12),
          Text('CRASH', style: GoogleFonts.robotoMono(
              textStyle: const TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w900, letterSpacing: 2))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00D2FF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00D2FF).withOpacity(0.3)),
            ),
            child: const Text('999×',
                style: TextStyle(color: Color(0xFF00D2FF), fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          // Balance chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141825),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: accentColor, size: 13),
                const SizedBox(width: 5),
                Text('₹${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: accentColor, fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History bar
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryBar extends StatelessWidget {
  final List<double> history;
  const _HistoryBar({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF0C101A),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('HISTORY',
              style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                      color: Color(0xFF3A4460),
                      fontSize: 8, fontWeight: FontWeight.bold,
                      letterSpacing: 1.2))),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              itemBuilder: (_, i) {
                final v = history[i];
                final high = v >= 2.0;
                final mega = v >= 10.0;
                Color c = high
                    ? (mega ? const Color(0xFFFFB800) : const Color(0xFF00E396))
                    : const Color(0xFFFF4560);
                return Container(
                  margin: const EdgeInsets.only(right: 5, top: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withOpacity(0.5), width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${v.toStringAsFixed(2)}×',
                      style: TextStyle(
                          color: c, fontSize: 9,
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bet panel (left column)
// ─────────────────────────────────────────────────────────────────────────────
class _BetPanel extends StatelessWidget {
  final CrashState state;
  final TextEditingController betCtrl;
  final TextEditingController autoCashoutCtrl;
  final double balance;
  final bool betQueued, hasBet, cashedOut, autoEnabled;
  final double currentMulti;
  final Color accentColor;
  final ValueChanged<bool> onAutoToggle;
  final ValueChanged<double> onAdjust;
  final ValueChanged<String> onPreset;
  final VoidCallback onPlaceBet;
  final VoidCallback onCashOut;

  const _BetPanel({
    required this.state, required this.betCtrl, required this.autoCashoutCtrl,
    required this.balance, required this.betQueued, required this.hasBet,
    required this.cashedOut, required this.autoEnabled, required this.currentMulti,
    required this.accentColor, required this.onAutoToggle, required this.onAdjust,
    required this.onPreset, required this.onPlaceBet, required this.onCashOut,
  });

  @override
  Widget build(BuildContext context) {
    final bool locked = state != CrashState.countdown;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0C101A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF141825), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label
          Text('BET AMOUNT',
              style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                      color: Color(0xFF3A4460), fontSize: 9,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2))),
          const SizedBox(height: 8),

          // Input row
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF080B10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A2033), width: 1.2),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('₹', style: TextStyle(
                      color: Color(0xFF00D2FF), fontSize: 15,
                      fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: betCtrl,
                    enabled: !locked,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                        border: InputBorder.none, isDense: true,
                        contentPadding: EdgeInsets.zero),
                  ),
                ),
                _SmallBtn('-', () => onAdjust(-10)),
                _SmallBtn('+', () => onAdjust(10)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Presets 2×2
          _PresetGrid(onPreset: onPreset, locked: locked),
          const SizedBox(height: 14),

          // Auto cashout
          _AutoCashout(
            enabled: autoEnabled,
            ctrl: autoCashoutCtrl,
            onToggle: onAutoToggle,
          ),
          const Spacer(),

          // Action button
          _ActionBtn(
            state: state,
            betQueued: betQueued, hasBet: hasBet, cashedOut: cashedOut,
            currentMulti: currentMulti,
            betCtrl: betCtrl,
            onPlace: onPlaceBet,
            onCash: onCashOut,
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFF1A2033), width: 1)),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      );
}

class _PresetGrid extends StatelessWidget {
  final ValueChanged<String> onPreset;
  final bool locked;
  const _PresetGrid({required this.onPreset, required this.locked});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            _chip('10', onPreset, locked), const SizedBox(width: 6),
            _chip('100', onPreset, locked),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _chip('500', onPreset, locked), const SizedBox(width: 6),
            _chip('1000', onPreset, locked),
          ]),
        ],
      );

  Widget _chip(String val, ValueChanged<String> fn, bool locked) => Expanded(
        child: GestureDetector(
          onTap: locked ? null : () => fn(val),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF141825),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E2538), width: 1),
            ),
            child: Text(val,
                style: TextStyle(
                    color: locked ? Colors.white30 : Colors.white70,
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      );
}

class _AutoCashout extends StatelessWidget {
  final bool enabled;
  final TextEditingController ctrl;
  final ValueChanged<bool> onToggle;
  const _AutoCashout({required this.enabled, required this.ctrl, required this.onToggle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('AUTO CASHOUT',
                    style: GoogleFonts.robotoMono(
                        textStyle: const TextStyle(
                            color: Color(0xFF3A4460), fontSize: 9,
                            fontWeight: FontWeight.bold, letterSpacing: 1.2))),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: const Color(0xFF00D2FF),
                activeTrackColor: const Color(0xFF0C2232),
                inactiveThumbColor: Colors.grey.shade600,
                inactiveTrackColor: const Color(0xFF141825),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 6),
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF080B10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A2033), width: 1.2),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('×', style: TextStyle(
                        color: Color(0xFF00D2FF), fontSize: 14,
                        fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                          border: InputBorder.none, isDense: true,
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

class _ActionBtn extends StatelessWidget {
  final CrashState state;
  final bool betQueued, hasBet, cashedOut;
  final double currentMulti;
  final TextEditingController betCtrl;
  final VoidCallback onPlace, onCash;
  const _ActionBtn({required this.state, required this.betQueued,
    required this.hasBet, required this.cashedOut, required this.currentMulti,
    required this.betCtrl, required this.onPlace, required this.onCash});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case CrashState.countdown:
        if (betQueued) {
          return _chip('BET PLACED', const Color(0xFF00D2FF), null);
        }
        return _primary('PLACE BET', const Color(0xFF00D2FF), Colors.black, onPlace);

      case CrashState.flying:
        if (!hasBet) return _chip('ROUND RUNNING', Colors.white24, null);
        if (cashedOut) return _chip('CASHED OUT ✓', const Color(0xFF00E396), null);
        final double bet = double.tryParse(betCtrl.text) ?? 10.0;
        final double out = bet * currentMulti;
        return _primary(
          'CASH OUT  ₹${out.toStringAsFixed(2)}',
          const Color(0xFFFFB800),
          Colors.black,
          onCash,
        );

      case CrashState.crashed:
        return _chip('CRASHED', const Color(0xFFFF4560), null);
    }
  }

  Widget _primary(String lbl, Color bg, Color fg, VoidCallback? fn) =>
      ElevatedButton(
        onPressed: fn,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, foregroundColor: fg,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(lbl,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                letterSpacing: 0.4)),
      );

  Widget _chip(String lbl, Color color, VoidCallback? fn) => GestureDetector(
        onTap: fn,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35), width: 1.2),
          ),
          child: Text(lbl,
              style: TextStyle(color: color, fontSize: 13,
                  fontWeight: FontWeight.w900)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final CrashState state;
  final double progress;
  final List<_Particle> particles;
  final Color accentColor;
  final double multi;
  final double crashedAt;

  _ChartPainter({
    required this.state, required this.progress, required this.particles,
    required this.accentColor, required this.multi, required this.crashedAt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    const double pL = 38, pB = 28, pR = 14, pT = 14;
    final double gL = pL, gR = w - pR, gT = pT, gB = h - pB;
    final double gW = gR - gL, gH = gB - gT;

    // ── subtle grid ──────────────────────────────────────────────────────
    final gridP = Paint()..color = const Color(0xFF141825)..strokeWidth = 0.7;
    for (int i = 0; i <= 5; i++) {
      canvas.drawLine(Offset(gL, gT + gH * i / 5), Offset(gR, gT + gH * i / 5), gridP);
    }
    for (int i = 0; i <= 8; i++) {
      canvas.drawLine(Offset(gL + gW * i / 8, gT), Offset(gL + gW * i / 8, gB), gridP);
    }

    // ── axes ─────────────────────────────────────────────────────────────
    final axisP = Paint()..color = const Color(0xFF1E2538)..strokeWidth = 1.5;
    canvas.drawLine(Offset(gL, gB), Offset(gR, gB), axisP);
    canvas.drawLine(Offset(gL, gT), Offset(gL, gB), axisP);

    // ── axis labels ───────────────────────────────────────────────────────
    void label(String s, Offset pos) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: const TextStyle(color: Color(0xFF3A4460), fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }
    label('1.0×', Offset(2, gB - 12));
    label('10×',  Offset(2, gT + gH * 0.45));
    label('99×',  Offset(2, gT));

    if (state == CrashState.flying || state == CrashState.crashed) {
      final bool isCrashed = state == CrashState.crashed;
      final double t = progress.clamp(0.0, 1.0);

      // Compute path using power-ease curve
      Offset ptAt(double p) {
        final double x = gL + gW * p;
        final double ease = p < 0.0001 ? 0.0 : math.pow(p, 0.52).toDouble();
        return Offset(x, (gB - gH * ease).clamp(gT, gB));
      }

      const int steps = 80;
      final path = Path()..moveTo(gL, gB);
      for (int i = 1; i <= steps; i++) {
        final p = ptAt(t * i / steps);
        path.lineTo(p.dx, p.dy);
      }
      final Offset tip = ptAt(t);

      // Gradient fill under curve
      final fillPath = Path.from(path)
        ..lineTo(tip.dx, gB)
        ..close();
      canvas.drawPath(fillPath,
          Paint()
            ..shader = LinearGradient(
              colors: [accentColor.withOpacity(0.22), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTRB(gL, gT, gR, gB))
            ..style = PaintingStyle.fill);

      // Curve stroke
      canvas.drawPath(path,
          Paint()
            ..color = accentColor
            ..strokeWidth = 2.8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Tip glow rings
      if (!isCrashed) {
        for (final r in [18.0, 10.0]) {
          canvas.drawCircle(tip, r,
              Paint()..color = accentColor.withOpacity(r == 18 ? 0.10 : 0.20));
        }
      }
      canvas.drawCircle(tip, 5.5, Paint()..color = accentColor);

      // Particles
      for (final p in particles) {
        final double px = gL + p.fx * gW;
        final double py = gT + (1.0 - (1.0 - p.fy)) * gH;
        canvas.drawCircle(
          Offset(px, py),
          p.sz * gW,
          Paint()
            ..color = accentColor.withOpacity(p.alpha * 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      // Live multiplier label near tip
      if (!isCrashed && t > 0.04) {
        final labelTp = TextPainter(
          text: TextSpan(text: '${multi.toStringAsFixed(2)}×',
              style: TextStyle(color: accentColor, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        final double lx = (tip.dx + 10).clamp(gL, gR - labelTp.width);
        final double ly = (tip.dy - labelTp.height - 6).clamp(gT, gB);
        labelTp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Win Overlay Card Widget (Centered in Game Playfield Arena)
// ─────────────────────────────────────────────────────────────────────────────
class WinOverlayCard extends StatelessWidget {
  final double multiplier;
  final double winAmount;

  const WinOverlayCard({
    super.key,
    required this.multiplier,
    required this.winAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024).withOpacity(0.96),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 18.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Multiplier with sparkle icons (✦ 1.96x ✦)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 14.0),
              const SizedBox(width: 6.0),
              Text(
                '${multiplier.toStringAsFixed(2)}x',
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 26.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              const Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 14.0),
            ],
          ),
          const SizedBox(height: 10.0),

          // Bottom Win Amount Container with Gold Rupees Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFF14161B),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  winAmount.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  width: 17.0,
                  height: 17.0,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '₹',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
