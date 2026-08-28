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
  'andar_bahar': _GameMeta(
    title: 'ANDAR BAHAR',
    subtitle: 'Choose your side. Play your hand.',
    emoji: '🃏',
    primary: Color(0xFF0D47A1),
    secondary: Color(0xFFB71C1C),
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
  'double': _GameMeta(
    title: 'DOUBLE CAROUSEL',
    subtitle: 'Bet on colors. Double your fortune.',
    emoji: '🔴',
    primary: Color(0xFFFE4541),
    secondary: Color(0xFF24EE89),
  ),
  'ring_of_fortune': _GameMeta(
    title: 'RING OF FORTUNE',
    subtitle: 'Spin the wheel. Claim your destiny.',
    emoji: '🎡',
    primary: Color(0xFF24EE89),
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
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.alpha,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Clippers for Forest/Mountain Silhouettes
// ─────────────────────────────────────────────────────────────────────────────
class FarMountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.60);
    path.lineTo(w * 0.08, h * 0.45);
    path.lineTo(w * 0.16, h * 0.58);
    path.lineTo(w * 0.26, h * 0.38);
    path.lineTo(w * 0.36, h * 0.55);
    path.lineTo(w * 0.48, h * 0.30);
    path.lineTo(w * 0.58, h * 0.52);
    path.lineTo(w * 0.70, h * 0.40);
    path.lineTo(w * 0.82, h * 0.58);
    path.lineTo(w * 0.92, h * 0.42);
    path.lineTo(w, h * 0.55);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class NearMountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.70);
    path.lineTo(w * 0.10, h * 0.50);
    path.lineTo(w * 0.22, h * 0.68);
    path.lineTo(w * 0.34, h * 0.45);
    path.lineTo(w * 0.46, h * 0.65);
    path.lineTo(w * 0.60, h * 0.48);
    path.lineTo(w * 0.74, h * 0.66);
    path.lineTo(w * 0.88, h * 0.50);
    path.lineTo(w, h * 0.65);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TreesClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.60);
    path.lineTo(w * 0.02, h * 0.40);
    path.lineTo(w * 0.04, h * 0.60);
    path.lineTo(w * 0.06, h * 0.35);
    path.lineTo(w * 0.08, h * 0.60);
    path.lineTo(w * 0.12, h);
    path.lineTo(w * 0.14, h * 0.55);
    path.lineTo(w * 0.16, h * 0.30);
    path.lineTo(w * 0.18, h * 0.55);
    path.lineTo(w * 0.20, h);
    path.lineTo(w * 0.30, h);
    path.lineTo(w * 0.32, h * 0.50);
    path.lineTo(w * 0.34, h * 0.25);
    path.lineTo(w * 0.36, h * 0.50);
    path.lineTo(w * 0.38, h);
    path.lineTo(w * 0.50, h);
    path.lineTo(w * 0.52, h * 0.58);
    path.lineTo(w * 0.54, h * 0.32);
    path.lineTo(w * 0.56, h * 0.58);
    path.lineTo(w * 0.58, h);
    path.lineTo(w * 0.68, h);
    path.lineTo(w * 0.70, h * 0.48);
    path.lineTo(w * 0.72, h * 0.22);
    path.lineTo(w * 0.74, h * 0.48);
    path.lineTo(w * 0.76, h);
    path.lineTo(w * 0.86, h);
    path.lineTo(w * 0.88, h * 0.55);
    path.lineTo(w * 0.90, h * 0.30);
    path.lineTo(w * 0.92, h * 0.55);
    path.lineTo(w * 0.94, h);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class WantedPosterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h * 0.85);
    path.lineTo(w * 0.90, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Game Loading Screen Widget
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
  late AnimationController _entryCtrl; // fade + slide in
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
    for (int i = 0; i < 40; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2.0 + 0.8,
        speed: _rng.nextDouble() * 0.00004 + 0.00001,
        alpha: _rng.nextDouble() * 0.7 + 0.2,
      ));
    }

    // ── entry animation ─────────────────────────────────────────────────
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    // ── star ticker ──────────────────────────────────────────────────────
    _starTicker = createTicker(_onStarTick)..start();

    // ── progress timer ───────────────────────────────────────────────────
    const int totalMs = 2200;
    const int intervalMs = 30;
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
        Future.delayed(const Duration(milliseconds: 350),
            widget.onLoadingComplete);
      }
    });

    // ── status cycling ────────────────────────────────────────────────────
    _statusTimer = Timer.periodic(const Duration(milliseconds: 320), (_) {
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
        // Drifting stars animation
        s.x += s.speed * dt * 30;
        if (s.x > 1.0) {
          s.x = 0.0;
          s.y = _rng.nextDouble();
        }
        // Slight twinkle
        s.alpha = (s.alpha + (_rng.nextDouble() * 0.1 - 0.05)).clamp(0.1, 0.95);
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _entryCtrl.dispose();
    _starTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _getMeta(widget.gameKey);
    final int pct = (_progress * 100).round();
    final String statusStr = _statuses[_statusIndex];

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A4250), Color(0xFF5B6472)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Starfield background ──────────────────────────────────────
            CustomPaint(
              painter: _StarfieldPainter(_stars),
            ),

            // ── Moon ──────────────────────────────────────────────────────
            Positioned(
              top: screenHeight * 0.12,
              right: screenWidth * 0.10,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDCE1E6).withValues(alpha: 0.20),
                      blurRadius: 30.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.35),
                    radius: 0.75,
                    colors: [Color(0xFFE7EBEE), Color(0xFFB7C0C9)],
                  ),
                ),
              ),
            ),

            // ── Silhouette layers (Mountains & Trees) ──────────────────────
            // Far mountains
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.38,
              child: ClipPath(
                clipper: FarMountainClipper(),
                child: Container(
                  color: const Color(0xFF4A515C).withValues(alpha: 0.8),
                ),
              ),
            ),

            // Near mountains
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.26,
              child: ClipPath(
                clipper: NearMountainClipper(),
                child: Container(
                  color: const Color(0xFF333A44),
                ),
              ),
            ),

            // Pine Trees
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.20,
              child: ClipPath(
                clipper: TreesClipper(),
                child: Container(
                  color: const Color(0xFF1C2128),
                ),
              ),
            ),


            // ── Center Content ────────────────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildContent(meta, pct, statusStr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wanted Poster builder ──────────────────────────────────────────────────
  Widget _buildWantedPoster() {
    return Transform.rotate(
      angle: -3 * math.pi / 180,
      child: ClipPath(
        clipper: WantedPosterClipper(),
        child: Container(
          width: 90,
          height: 108,
          color: const Color(0xFFD8D3C4),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'WANTED',
                style: GoogleFonts.baloo2(
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1C),
                    letterSpacing: 1.0,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                'DEAD OR ALIVE',
                style: GoogleFonts.baloo2(
                  textStyle: const TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF555555),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '★',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEEEEEE),
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                'REWARD\n150,000',
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  textStyle: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1C),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main logo + progress bar builder ──────────────────────────────────────
  Widget _buildContent(_GameMeta meta, int pct, String status) {
    const double benchWidth = 300.0;
    const double plankHeight = 28.0;

    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Presenter Text
          Text(
            'SILENT PINES STUDIO PRESENTS',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: const Color(0xFFC9D1D9).withValues(alpha: 0.9),
                letterSpacing: 3.0,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    offset: Offset(1.5, 1.5),
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. Custom Game Logo (no emoji)
          Transform.rotate(
            angle: -2 * math.pi / 180,
            child: Stack(
              children: [
                // Dark border stroke background
                Text(
                  meta.title,
                  style: GoogleFonts.baloo2(
                    textStyle: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 5.0
                        ..color = const Color(0xFF14171B),
                    ),
                  ),
                ),
                // Gradient fill foreground
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE6EAEE),
                      Color(0xFFB6BFC8),
                      Color(0xFF838D97),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    meta.title,
                    style: GoogleFonts.baloo2(
                      textStyle: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          // 3. Wooden Bench Progress Bar
          SizedBox(
            width: benchWidth,
            height: plankHeight + 14,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bench Legs
                Positioned(
                  bottom: 0,
                  left: 14,
                  child: Container(
                    width: 7,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D0F13),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 14,
                  child: Container(
                    width: 7,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D0F13),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Wooden Plank
                Positioned(
                  top: 2,
                  left: 0,
                  right: 0,
                  height: plankHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF232830), Color(0xFF171B21)],
                      ),
                      border: Border.all(color: const Color(0xFF0D0F13), width: 3.0),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          offset: Offset(0, 4),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Progress Fill
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF8B96A3), Color(0xFF5E6873)],
                              ),
                            ),
                          ),
                        ),
                        // Middle line separator
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 3.0,
                            color: const Color(0xFF0D0F13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Knobs
                Positioned(
                  top: -4,
                  left: -3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3A4149),
                      border: Border.all(color: const Color(0xFF0D0F13), width: 2.0),
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3A4149),
                      border: Border.all(color: const Color(0xFF0D0F13), width: 2.0),
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  left: benchWidth / 2 - 7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3A4149),
                      border: Border.all(color: const Color(0xFF0D0F13), width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 4. Loading Text & Percent
          Text(
            pct >= 100 ? 'READY!' : 'LOADING... $pct%',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                color: const Color(0xFF8B96A3).withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
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
  _StarfieldPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var s in stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint..color = Colors.white.withValues(alpha: s.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => true;
}
