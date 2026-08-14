import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Game metadata per key
// ─────────────────────────────────────────────────────────────────────────────
class _GameMeta {
  final String title;
  final String subtitle;
  final String emoji;
  final Color primary;
  final Color secondary;

  const _GameMeta({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.primary,
    required this.secondary,
  });
}

const Map<String, _GameMeta> _gameMeta = {
  'plinko': _GameMeta(
    title: 'PLINKO CASCADE',
    subtitle: 'Drop the ball. Win the pot.',
    emoji: '🔵',
    primary: Color(0xFF00D2FF),
    secondary: Color(0xFF7B2FF7),
  ),
  'coin_flip': _GameMeta(
    title: 'COIN FLIP',
    subtitle: 'Heads or tails — your call.',
    emoji: '🪙',
    primary: Color(0xFFFFB800),
    secondary: Color(0xFFFF6B00),
  ),
  'limbo': _GameMeta(
    title: 'LIMBO',
    subtitle: 'How low can you go?',
    emoji: '⚡',
    primary: Color(0xFF00E396),
    secondary: Color(0xFF00A3FF),
  ),
  'dice': _GameMeta(
    title: 'CYBER DICE',
    subtitle: 'Roll. Predict. Win.',
    emoji: '🎲',
    primary: Color(0xFFE040FB),
    secondary: Color(0xFF7B2FF7),
  ),
  'roulette': _GameMeta(
    title: 'NEON ROULETTE',
    subtitle: 'Spin the wheel of fortune.',
    emoji: '🎡',
    primary: Color(0xFFFF4560),
    secondary: Color(0xFFFFB800),
  ),
  'mines': _GameMeta(
    title: 'CRYPTO MINES',
    subtitle: 'Navigate the minefield.',
    emoji: '💣',
    primary: Color(0xFFFF6B35),
    secondary: Color(0xFFFF4560),
  ),
  'hilo': _GameMeta(
    title: 'HI-LO',
    subtitle: 'Higher or lower — decide!',
    emoji: '🃏',
    primary: Color(0xFF00D2FF),
    secondary: Color(0xFF00E396),
  ),
  'seven_up_down': _GameMeta(
    title: '7 UP 7 DOWN',
    subtitle: 'Above, below or on the mark.',
    emoji: '🎯',
    primary: Color(0xFFFFB800),
    secondary: Color(0xFFFF4560),
  ),
  'keno': _GameMeta(
    title: 'RETRO KENO',
    subtitle: 'Pick numbers. Hit the jackpot.',
    emoji: '🔢',
    primary: Color(0xFF7B2FF7),
    secondary: Color(0xFF00D2FF),
  ),
  'crash': _GameMeta(
    title: '999× CRASH',
    subtitle: 'Cash out before it crashes.',
    emoji: '🚀',
    primary: Color(0xFF00D2FF),
    secondary: Color(0xFF7B2FF7),
  ),
};

_GameMeta _getMeta(String key) =>
    _gameMeta[key.toLowerCase()] ??
    const _GameMeta(
      title: 'LOADING GAME',
      subtitle: 'Preparing your experience...',
      emoji: '🎮',
      primary: Color(0xFF00D2FF),
      secondary: Color(0xFF7B2FF7),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Floating star particle for background
// ─────────────────────────────────────────────────────────────────────────────
class _Star {
  double x, y, size, speed, alpha;
  _Star({required this.x, required this.y, required this.size,
    required this.speed, required this.alpha});
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
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

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with TickerProviderStateMixin {

  // ── progress ────────────────────────────────────────────────────────────
  double _progress = 0.0;
  int _statusIndex = 0;
  bool _completed = false;
  Timer? _progressTimer;
  Timer? _statusTimer;

  // ── animations ──────────────────────────────────────────────────────────
  late AnimationController _entryCtrl;   // fade + slide in
  late AnimationController _pulseCtrl;   // emoji pulse
  late AnimationController _rotCtrl;     // rotating ring
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── stars ────────────────────────────────────────────────────────────────
  final List<_Star> _stars = [];
  final _rng = math.Random();
  Ticker? _starTicker;
  Duration _lastStarTick = Duration.zero;

  final List<String> _statuses = [
    'CONNECTING TO CASINO NODE...',
    'VERIFYING CRYPTO WALLET...',
    'LOADING GAME ASSETS...',
    'SYNCING BALANCES...',
    'GENERATING SEED...',
    'SPAWNING GAME BOARD...',
    'READY TO PLAY! 🎉',
  ];

  @override
  void initState() {
    super.initState();

    // ── seed stars ──────────────────────────────────────────────────────
    for (int i = 0; i < 80; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2.5 + 0.5,
        speed: _rng.nextDouble() * 0.00008 + 0.00003,
        alpha: _rng.nextDouble() * 0.6 + 0.2,
      ));
    }

    // ── entry animation ─────────────────────────────────────────────────
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    // ── pulse ────────────────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.92,
        upperBound: 1.08)
      ..repeat(reverse: true);

    // ── ring spin ────────────────────────────────────────────────────────
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    // ── star ticker ──────────────────────────────────────────────────────
    _starTicker = createTicker(_onStarTick)..start();

    // ── progress timer ───────────────────────────────────────────────────
    const int totalMs = 1800;
    const int intervalMs = 25;
    final int steps = totalMs ~/ intervalMs;
    int step = 0;
    _progressTimer = Timer.periodic(
        const Duration(milliseconds: intervalMs), (timer) {
      step++;
      if (mounted) setState(() => _progress = (step / steps).clamp(0.0, 1.0));
      if (step >= steps && !_completed) {
        _completed = true;
        timer.cancel();
        _statusTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 300),
            widget.onLoadingComplete);
      }
    });

    // ── status cycling ────────────────────────────────────────────────────
    _statusTimer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      if (_statusIndex < _statuses.length - 1 && mounted) {
        setState(() => _statusIndex++);
      }
    });
  }

  void _onStarTick(Duration elapsed) {
    if (!mounted) return;
    final double dt = _lastStarTick == Duration.zero
        ? 0.0
        : (elapsed - _lastStarTick).inMilliseconds / 1000.0;
    _lastStarTick = elapsed;
    setState(() {
      for (var s in _stars) {
        s.y -= s.speed * dt * 60;
        if (s.y < 0.0) {
          s.y = 1.0;
          s.x = _rng.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    _starTicker?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final meta = _getMeta(widget.gameKey);
    final int pct = (_progress * 100).round();
    final String status = _statuses[_statusIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF060810),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Starfield background ──────────────────────────────────────
          CustomPaint(
            painter: _StarfieldPainter(_stars, meta.primary, meta.secondary),
          ),

          // ── Radial gradient glow in center ────────────────────────────
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    meta.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildContent(meta, pct, status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_GameMeta meta, int pct, String status) {
    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Spinning ring + emoji ────────────────────────────────────
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating arc
                AnimatedBuilder(
                  animation: _rotCtrl,
                  builder: (_, __) => Transform.rotate(
                    angle: _rotCtrl.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(110, 110),
                      painter: _ArcPainter(
                        primary: meta.primary,
                        secondary: meta.secondary,
                      ),
                    ),
                  ),
                ),
                // Inner soft circle
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: meta.primary.withOpacity(0.08),
                    border: Border.all(
                        color: meta.primary.withOpacity(0.18), width: 1),
                  ),
                ),
                // Emoji
                ScaleTransition(
                  scale: _pulseCtrl,
                  child: Text(meta.emoji,
                      style: const TextStyle(fontSize: 36)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Game title ───────────────────────────────────────────────
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [meta.primary, meta.secondary],
            ).createShader(bounds),
            child: Text(
              meta.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Subtitle ─────────────────────────────────────────────────
          Text(
            meta.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Progress bar ─────────────────────────────────────────────
          Column(
            children: [
              // Percent label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status,
                    style: GoogleFonts.robotoMono(
                      textStyle: TextStyle(
                        color: meta.primary.withOpacity(0.75),
                        fontSize: 8,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: GoogleFonts.robotoMono(
                      textStyle: TextStyle(
                        color: meta.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Track
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 20),
                    widthFactor: _progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [meta.secondary, meta.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: meta.primary.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Dots progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  final bool filled = (_progress * 7).round() > i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: filled ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: filled
                          ? meta.primary
                          : Colors.white.withOpacity(0.12),
                      boxShadow: filled
                          ? [BoxShadow(color: meta.primary.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Starfield painter
// ─────────────────────────────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final Color primary;
  final Color secondary;
  _StarfieldPainter(this.stars, this.primary, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      final Color c = i.isEven ? primary : secondary;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = c.withOpacity(s.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Spinning arc painter
// ─────────────────────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  _ArcPainter({required this.primary, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = cx - 4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Main arc (270°)
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [secondary, primary, Colors.transparent],
          stops: const [0.0, 0.75, 1.0],
        ).createShader(rect)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Trailing glow dot at the end of the arc
    final double tipAngle = -math.pi / 2 + math.pi * 1.5;
    final double tipX = cx + r * math.cos(tipAngle);
    final double tipY = cy + r * math.sin(tipAngle);
    canvas.drawCircle(
      Offset(tipX, tipY),
      5.5,
      Paint()
        ..color = primary
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(Offset(tipX, tipY), 3.5, Paint()..color = primary);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => false;
}
