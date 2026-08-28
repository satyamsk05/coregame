import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/win_overlay_card.dart';

// ─── Ring Configuration ─────────────────────────────────────────────────────
class _SegmentData {
  final String label;
  final double multiplier;
  final bool isBonus;
  final bool isLocked;

  const _SegmentData({
    required this.label,
    required this.multiplier,
    this.isBonus = false,
    this.isLocked = false,
  });
}

// Each ring: inner(0) → outer(2)
const List<List<_SegmentData>> _ringConfig = [
  // Inner ring (green) – 12 segments
  [
    _SegmentData(label: '1.6X', multiplier: 1.6),
    _SegmentData(label: '0.8X', multiplier: 0.8),
    _SegmentData(label: '5.0X', multiplier: 5.0),
    _SegmentData(label: '16.5X', multiplier: 16.5),
    _SegmentData(label: '53.0X', multiplier: 53.0),
    _SegmentData(label: '28.5X', multiplier: 28.5),
    _SegmentData(label: '13.0X', multiplier: 13.0),
    _SegmentData(label: '2.5X', multiplier: 2.5),
    _SegmentData(label: '4.0X', multiplier: 4.0),
    _SegmentData(label: '0.8X', multiplier: 0.8),
    _SegmentData(label: '1.6X', multiplier: 1.6),
    _SegmentData(label: '5.0X', multiplier: 5.0),
  ],
  // Middle ring (orange) – 12 segments
  [
    _SegmentData(label: '2.5X', multiplier: 2.5),
    _SegmentData(label: '10.5X', multiplier: 10.5),
    _SegmentData(label: '28.5X', multiplier: 28.5),
    _SegmentData(label: '53.0X', multiplier: 53.0),
    _SegmentData(label: '88.0X', multiplier: 88.0),
    _SegmentData(label: '28.5X', multiplier: 28.5),
    _SegmentData(label: '13.0X', multiplier: 13.0),
    _SegmentData(label: '+7.5X', multiplier: 7.5, isLocked: true),
    _SegmentData(label: '+21.0X', multiplier: 21.0, isLocked: true),
    _SegmentData(label: '45.0X', multiplier: 45.0),
    _SegmentData(label: '137.5X', multiplier: 137.5),
    _SegmentData(label: '205.0X', multiplier: 205.0),
  ],
  // Outer ring (purple) – 12 segments
  [
    _SegmentData(label: '4.0X', multiplier: 4.0),
    _SegmentData(label: '16.5X', multiplier: 16.5),
    _SegmentData(label: '53.0X', multiplier: 53.0),
    _SegmentData(label: '88.0X', multiplier: 88.0),
    _SegmentData(label: '137.5X', multiplier: 137.5),
    _SegmentData(label: '205.0X', multiplier: 205.0),
    _SegmentData(label: '28.5X', multiplier: 28.5),
    _SegmentData(label: '+21.0X', multiplier: 21.0, isLocked: true),
    _SegmentData(label: 'BONUS', multiplier: 500.0, isBonus: true),
    _SegmentData(label: '45.0X', multiplier: 45.0),
    _SegmentData(label: '137.5X', multiplier: 137.5),
    _SegmentData(label: '205.0X', multiplier: 205.0),
  ],
];

// Ring colors: green, orange, purple
const List<Color> _ringActiveColors = [
  Color(0xFF00C853),
  Color(0xFFE65100),
  Color(0xFF7B1FA2),
];

// ─── Twist Game Screen ──────────────────────────────────────────────────────
class TwistGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const TwistGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<TwistGameScreen> createState() => _TwistGameScreenState();
}

class _TwistGameScreenState extends State<TwistGameScreen>
    with TickerProviderStateMixin {

  // Spin animation controllers (one per ring)
  late List<AnimationController> _spinControllers;
  late List<Animation<double>> _spinAnims;

  // Current highlighted segment per ring (index into _ringConfig[ring])
  final List<int> _activeSegments = [0, 0, 0];

  // Stored final offsets in radians
  final List<double> _finalAngles = [0.0, 0.0, 0.0];

  bool _isSpinning = false;
  bool _showOverlay = false;
  bool _isWin = false;
  double _lastWinAmount = 0.0;
  double _lastMult = 1.0;
  double _totalProfit = 0.0;
  double _sessionMult = 1.0;

  final _betController = TextEditingController(text: '1.0');
  String _selectedTab = 'Manual';

  // History: each entry = total multiplier for that spin
  final List<double> _history = [];

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _spinControllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2800 + i * 500),
    ));
    _spinAnims = List.generate(3, (i) {
      return const AlwaysStoppedAnimation(0.0);
    });
  }

  @override
  void dispose() {
    for (final c in _spinControllers) {
      c.dispose();
    }
    _betController.dispose();
    super.dispose();
  }

  // ─── Spin ──────────────────────────────────────────────────────────────────
  void _startSpin() {
    final bet = double.tryParse(_betController.text) ?? 1.0;
    if (bet <= 0 || bet > widget.balance) return;
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _showOverlay = false;
    });

    widget.onBalanceChanged(widget.balance - bet);

    final newSegs = List.generate(3, (_) => _rng.nextInt(12));

    for (int i = 0; i < 3; i++) {
      final segAngle = (2 * pi) / 12;
      final targetSeg = newSegs[i];
      // Extra full rotations + target segment
      final extra = (5 + _rng.nextInt(5)) * 2 * pi;
      final target = _finalAngles[i] + extra + targetSeg * segAngle;

      _spinControllers[i].reset();
      _spinAnims[i] = Tween<double>(
        begin: _finalAngles[i],
        end: target,
      ).animate(CurvedAnimation(
        parent: _spinControllers[i],
        curve: Curves.easeOut,
      ));
      _spinControllers[i].forward();
    }

    _spinControllers[2].addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _spinControllers[2].removeStatusListener((s) {});
        _onSpinDone(newSegs, bet);
      }
    });

    setState(() {
      for (int i = 0; i < 3; i++) {
        _activeSegments[i] = newSegs[i];
      }
    });
  }

  void _onSpinDone(List<int> segs, double bet) {
    // Save final angles
    for (int i = 0; i < 3; i++) {
      _finalAngles[i] = _spinAnims[i].value % (2 * pi);
    }

    // Calc total multiplier (product of all 3 rings)
    double total = 1.0;
    for (int i = 0; i < 3; i++) {
      final seg = _ringConfig[i][segs[i]];
      if (seg.multiplier > 0) total *= seg.multiplier;
    }
    total = total.clamp(0.0, 5000.0);

    final isWin = total > 3.0;
    final winAmt = isWin ? bet * total : 0.0;

    setState(() {
      _isSpinning = false;
      _isWin = isWin;
      _lastMult = total;
      _lastWinAmount = winAmt;
      _totalProfit += winAmt - bet;
      _sessionMult = total;
      _showOverlay = isWin;

      _history.insert(0, total);
      if (_history.length > 6) _history.removeLast();
    });

    if (isWin) {
      widget.onBalanceChanged(widget.balance - bet + winAmt);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2030),
      body: Stack(
        children: [
          // ── Background night scene ─────────────────────────────────────
          _buildBackground(),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildHistoryStrip(),
                Expanded(
                  child: Row(
                    children: [
                      // Left: Bet panel
                      SizedBox(width: 150.0, child: _buildBetPanel()),
                      // Right: Wheel area
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildWheelArea(),
                            if (_showOverlay)
                              WinOverlayCard(
                                multiplier: _lastMult,
                                winAmount: _lastWinAmount,
                                isWin: _isWin,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.2),
            radius: 1.4,
            colors: [Color(0xFF1E2B40), Color(0xFF0D1117)],
          ),
        ),
        child: CustomPaint(painter: _StarFieldPainter()),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 40.0,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      color: Colors.black38,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBackPressed,
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
          const SizedBox(width: 8.0),
          Image.asset('assets/logos/twist_logo.png', width: 24.0, height: 24.0,
              errorBuilder: (_, e, _) =>
                  const Icon(Icons.rotate_right, color: Color(0xFF9B59B6), size: 22.0)),
          const SizedBox(width: 6.0),
          Text('TWIST',
              style: GoogleFonts.pressStart2p(
                  fontSize: 9.0, color: Colors.white, letterSpacing: 1.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Color(0xFFFFD700), size: 12.0),
              const SizedBox(width: 4.0),
              Text('₹${widget.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── History pill strip (top) ──────────────────────────────────────────────
  Widget _buildHistoryStrip() {
    final display = _history.isNotEmpty
        ? _history.take(6).toList()
        : [2.50, 0.00, 0.00, 4.00, 1.60, 3.40];

    return Container(
      height: 34.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: display.map((m) {
          final isLoss = m <= 1.0;
          final bg = isLoss ? const Color(0xFF2D3748) : const Color(0xFF00C853);
          final txt = isLoss ? Colors.white38 : Colors.white;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text('${m.toStringAsFixed(2)}x',
                style: TextStyle(
                    color: txt, fontSize: 9.5, fontWeight: FontWeight.w800)),
          );
        }).toList(),
      ),
    );
  }

  // ─── Wheel area ────────────────────────────────────────────────────────────
  Widget _buildWheelArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The animated wheel
        AnimatedBuilder(
          animation: Listenable.merge(_spinControllers),
          builder: (context, _) {
            final angles = List.generate(3, (i) =>
                _spinControllers[i].isAnimating ? _spinAnims[i].value : _finalAngles[i]);
            return SizedBox(
              width: 230.0,
              height: 230.0,
              child: CustomPaint(
                painter: _TwistWheelPainter(
                  angles: angles,
                  ringConfig: _ringConfig,
                  ringColors: _ringActiveColors,
                  activeSegments: _activeSegments,
                  isSpinning: _isSpinning,
                ),
                child: Center(child: _buildCenterGem()),
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),
        // Total profit badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            'Total profit  ₹${_totalProfit.toStringAsFixed(2)}  (${_sessionMult.toStringAsFixed(2)}x)',
            style: TextStyle(
              color: _totalProfit >= 0 ? const Color(0xFF00C853) : const Color(0xFFE53935),
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterGem() {
    return SizedBox(
      width: 64.0,
      height: 64.0,
      child: Image.asset('assets/twist/ring_inner.png',
          fit: BoxFit.contain,
          errorBuilder: (_, e, _) => const Icon(Icons.diamond, color: Color(0xFF00C853), size: 40.0)),
    );
  }

  // ─── Bet panel ─────────────────────────────────────────────────────────────
  Widget _buildBetPanel() {
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('BET AMOUNT'),
                  const SizedBox(height: 4.0),
                  _buildBetField(),
                  const SizedBox(height: 6.0),
                  Row(children: [
                    _buildQuickBtn('½', () {
                      final v = (double.tryParse(_betController.text) ?? 1.0) / 2;
                      _betController.text = v.toStringAsFixed(2);
                    }),
                    const SizedBox(width: 5.0),
                    _buildQuickBtn('2×', () {
                      final v = (double.tryParse(_betController.text) ?? 1.0) * 2;
                      _betController.text = v.toStringAsFixed(2);
                    }),
                  ]),
                  const SizedBox(height: 14.0),
                  _buildSpinButton(),
                  const SizedBox(height: 10.0),
                  // Ring gem legend
                  _buildRingLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingLegend() {
    final gems = [
      ('assets/twist/ring_inner.png', 'Inner', _ringActiveColors[0]),
      ('assets/twist/ring_middle.png', 'Middle', _ringActiveColors[1]),
      ('assets/twist/ring_outer.png', 'Outer', _ringActiveColors[2]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('RINGS'),
        const SizedBox(height: 5.0),
        ...gems.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(children: [
            Image.asset(g.$1, width: 16.0, height: 16.0,
                errorBuilder: (_, e, _) => Icon(Icons.circle, color: g.$3, size: 14.0)),
            const SizedBox(width: 6.0),
            Text(g.$2,
                style: TextStyle(color: g.$3, fontSize: 9.5, fontWeight: FontWeight.w700)),
          ]),
        )),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 34.0,
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        children: ['Manual', 'Auto'].map((tab) {
          final active = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? const Color(0xFF00C853) : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                ),
                child: Text(tab,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white38,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLabel(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white38, fontSize: 9.0, fontWeight: FontWeight.w600, letterSpacing: 0.8));

  Widget _buildBetField() {
    return Container(
      height: 34.0,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(7.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        const SizedBox(width: 8.0),
        const Icon(Icons.currency_rupee, color: Color(0xFFFFD700), size: 13.0),
        Expanded(
          child: TextField(
            controller: _betController,
            style: const TextStyle(color: Colors.white, fontSize: 12.0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 6.0),
                isDense: true),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 26.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10.0, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTap: _isSpinning ? null : _startSpin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSpinning
                ? [const Color(0xFF333742), const Color(0xFF333742)]
                : [const Color(0xFF00C853), const Color(0xFF007A33)],
          ),
          borderRadius: BorderRadius.circular(9.0),
          boxShadow: _isSpinning ? [] : [
            BoxShadow(
                color: const Color(0xFF00C853).withValues(alpha: 0.4),
                blurRadius: 10.0, spreadRadius: 1.0),
          ],
        ),
        child: Text(
          _isSpinning ? 'SPINNING...' : 'SPIN',
          style: GoogleFonts.pressStart2p(fontSize: 8.5, color: Colors.white, letterSpacing: 1.2),
        ),
      ),
    );
  }
}

// ─── Wheel Painter ─────────────────────────────────────────────────────────────
class _TwistWheelPainter extends CustomPainter {
  final List<double> angles;
  final List<List<_SegmentData>> ringConfig;
  final List<Color> ringColors;
  final List<int> activeSegments;
  final bool isSpinning;

  _TwistWheelPainter({
    required this.angles,
    required this.ringConfig,
    required this.ringColors,
    required this.activeSegments,
    required this.isSpinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    final innerR = [28.0, 53.0, 78.0];
    final outerR = [50.0, 75.0, maxR - 2];

    const int segCount = 12;
    final segAngle = (2 * pi) / segCount;
    const gap = 0.04; // gap between segments in radians

    for (int ring = 0; ring < 3; ring++) {
      final rotation = angles[ring];
      final activeIdx = activeSegments[ring];
      final ringColor = ringColors[ring];

      for (int seg = 0; seg < segCount; seg++) {
        final data = ringConfig[ring][seg];
        final startA = seg * segAngle + rotation - pi / 2;
        final sweepA = segAngle - gap;

        final isActive = (seg == activeIdx) && !isSpinning;
        final isHighBonus = data.isBonus;

        // Tile background
        Color tileColor;
        if (isActive && isHighBonus) {
          tileColor = const Color(0xFF7B1FA2);
        } else if (isActive) {
          tileColor = ringColor;
        } else {
          tileColor = const Color(0xFF232B3A); // dark tile
        }

        // Draw tile path (arc segment shape)
        final path = Path();
        final innerRadius = innerR[ring];
        final outerRadius = outerR[ring];

        // Outer arc
        path.arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          startA,
          sweepA,
          false,
        );
        // Line to inner end
        path.arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startA + sweepA,
          -sweepA,
          false,
        );
        path.close();

        // Draw tile fill
        final fillPaint = Paint()
          ..color = tileColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);

        // Active glow overlay
        if (isActive) {
          final glowPaint = Paint()
            ..color = ringColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
          canvas.drawPath(path, glowPaint);
        }

        // Tile border (slight highlight on top edge)
        final borderPaint = Paint()
          ..color = isActive ? ringColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 1.5 : 0.8;
        canvas.drawPath(path, borderPaint);

        // ── Text label ────────────────────────────────────────────────
        final midAngle = startA + sweepA / 2;
        final labelRadius = (innerRadius + outerRadius) / 2;
        final tx = center.dx + labelRadius * cos(midAngle);
        final ty = center.dy + labelRadius * sin(midAngle);

        canvas.save();
        canvas.translate(tx, ty);
        canvas.rotate(midAngle + pi / 2);

        final fontSize = ring == 0 ? 7.5 : ring == 1 ? 6.5 : 6.0;
        final textColor = isActive
            ? Colors.white
            : (data.isLocked ? Colors.white38 : Colors.white60);

        final tp = TextPainter(
          text: TextSpan(
            text: data.label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3.0)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();

        // Lock icon for locked segments
        if (data.isLocked && !isActive) {
          canvas.save();
          canvas.translate(tx, ty);
          canvas.rotate(midAngle + pi / 2);
          final lockPainter = TextPainter(
            text: const TextSpan(
              text: '🔒',
              style: TextStyle(fontSize: 5.0),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          lockPainter.paint(canvas, Offset(-lockPainter.width / 2, 4.0));
          canvas.restore();
        }
      }
    }

    // ── Ring separator glow circles ──────────────────────────────────────
    for (int r = 0; r < 3; r++) {
      final sepPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, innerR[r] - 1, sepPaint);
    }

    // ── Center dark circle for gem ──────────────────────────────────────
    final centerPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 27.0, centerPaint);

    // Center glow
    final centerGlow = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center, 26.0, centerGlow);

    // ── Gem pointers between rings (right side at 0° = 3 o'clock) ──────
    _drawGemPointer(canvas, center, innerR[0] + (innerR[1] - innerR[0]) / 2, 'G');
    _drawGemPointer(canvas, center, innerR[1] + (innerR[2] - innerR[1]) / 2, 'R');
    _drawGemPointer(canvas, center, innerR[2] + (outerR[2] - innerR[2]) / 2, 'b');
  }

  void _drawGemPointer(Canvas canvas, Offset center, double radius, String gemType) {
    // Position at ~340° (top-right)
    const angle = -0.35; // radians from -pi/2 (top)
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);

    Color gemColor;
    switch (gemType) {
      case 'G':
        gemColor = const Color(0xFF00C853);
        break;
      case 'R':
        gemColor = const Color(0xFFE65100);
        break;
      default:
        gemColor = const Color(0xFF7B1FA2);
    }

    // Small gem circle
    final gemPaint = Paint()
      ..color = gemColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 5.5, gemPaint);

    final gemBorder = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(x, y), 5.5, gemBorder);
  }

  @override
  bool shouldRepaint(_TwistWheelPainter old) =>
      angles != old.angles || activeSegments != old.activeSegments || isSpinning != old.isSpinning;
}

// ─── Star field background painter ────────────────────────────────────────────
class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => false;
}
