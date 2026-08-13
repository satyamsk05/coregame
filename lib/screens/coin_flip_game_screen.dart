import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoinFlipGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const CoinFlipGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<CoinFlipGameScreen> createState() => _CoinFlipGameScreenState();
}

class _CoinFlipGameScreenState extends State<CoinFlipGameScreen> with SingleTickerProviderStateMixin {
  bool _isHeadsSelected = true; // true for Heads (Gold), false for Tails (Silver)
  bool _isFlipping = false;
  double _betAmount = 1.0;
  int _streak = 0;
  double _winAmount = 0.0;
  bool _showWinOverlay = false;
  String _statusText = 'SELECT SIDE & PLACE BET';

  // Spin animation state
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _heightAnimation;

  final List<CoinFlipParticle> _particles = [];
  final List<bool> _history = []; // true for Heads (Gold), false for Tails (Silver)
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Default animations (will be re-created dynamically per flip)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 8 * pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuad),
    );
    _heightAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.7).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.7, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)), weight: 50),
    ]).animate(_animationController);

    _animationController.addListener(() {
      _updateParticles();
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishFlip();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get active streak payout multiplier
  double _getStreakMultiplier() {
    if (_streak <= 1) return 1.98; // Base payout: 1.98x bet (representing ~1% house edge)
    if (_streak == 2) return 2.02; // Streak bonus! 2.02x
    if (_streak == 3) return 2.08; // 2.08x
    if (_streak == 4) return 2.15; // 2.15x
    return 2.25; // 5+ wins: 2.25x payout!
  }

  void _onSideSelected(bool isHeads) {
    if (_isFlipping) return;
    setState(() {
      _isHeadsSelected = isHeads;
      _showWinOverlay = false;
      _statusText = 'SIDE SELECTED: ${isHeads ? "HEADS (GOLD)" : "TAILS (SILVER)"}';
    });
  }

  void _startFlip() {
    if (_isFlipping) return;

    if (widget.balance < _betAmount) {
      _showErrorDialog('INSUFFICIENT BALANCE', 'Please recharge from the shop in the lobby.');
      return;
    }

    // Deduct bet amount
    widget.onBalanceChanged(widget.balance - _betAmount);

    setState(() {
      _isFlipping = true;
      _showWinOverlay = false;
      _winAmount = 0.0;
      _statusText = 'COIN IS IN THE AIR...';
    });

    // Randomize result
    final bool landsOnHeads = _random.nextBool();

    // Re-create animations based on outcome to ensure it lands on correct face
    // Heads is even multiples of pi, Tails is odd multiples of pi
    final double startRotation = _rotationAnimation.value % (2 * pi);
    final double targetRotation = landsOnHeads ? (12 * pi) : (13 * pi);

    _rotationAnimation = Tween<double>(begin: startRotation, end: targetRotation).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuad),
    );

    // Start spin
    _animationController.forward(from: 0.0);
  }

  void _finishFlip() {
    // Check outcome
    final double finalRotation = _rotationAnimation.value;
    final int halfRotations = (finalRotation / pi).round();
    final bool outcomeIsHeads = halfRotations % 2 == 0;

    final bool playerWon = outcomeIsHeads == _isHeadsSelected;
    double payoutMultiplier = _getStreakMultiplier();
    double win = _betAmount * payoutMultiplier;

    setState(() {
      _isFlipping = false;

      // Add to history (keep max 10 logs)
      _history.add(outcomeIsHeads);
      if (_history.length > 10) {
        _history.removeAt(0);
      }

      if (playerWon) {
        _streak++;
        _winAmount = win;
        widget.onBalanceChanged(widget.balance + win);
        _statusText = 'WON ₹${win.toStringAsFixed(2)}! (STREAK: $_streak)';
        _triggerWinParticles(outcomeIsHeads, win);
      } else {
        _streak = 0;
        _statusText = 'LOST! COIN LANDED ON ${outcomeIsHeads ? "HEADS" : "TAILS"}.';
      }
    });
  }

  void _triggerWinParticles(bool isHeadsWin, double winValue) {
    _particles.clear();
    final width = 844.0;
    final height = 390.0;

    // Spawn 70 particles
    for (int i = 0; i < 70; i++) {
      _particles.add(
        CoinFlipParticle(
          x: width / 2 + (_random.nextDouble() - 0.5) * 150,
          y: height / 2 - 30 + (_random.nextDouble() - 0.5) * 60,
          vx: (_random.nextDouble() - 0.5) * 14.0,
          vy: -_random.nextDouble() * 14.0 - 4.0, // Upward initial explosion
          size: _random.nextDouble() * 12.0 + 8.0,
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.4,
          isGold: isHeadsWin,
          isStar: _random.nextDouble() < 0.35,
        ),
      );
    }

    _showWinOverlay = true;
  }

  void _updateParticles() {
    if (!_showWinOverlay) return;

    const double gravity = 0.55;
    final height = 390.0;

    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += gravity;
      p.rotation += p.rotationSpeed;

      // Damp velocities
      p.vx *= 0.98;

      // Floor bounce
      if (p.y > height) {
        p.y = height;
        p.vy = -p.vy * 0.35;
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320.0,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1B6E), Color(0xFF13083B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFFF3355), width: 2.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.alfaSlabOne(color: const Color(0xFFFF3355), fontSize: 16.0),
              ),
              const SizedBox(height: 12.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3355),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentStreakMult = _getStreakMultiplier();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF4C270E), Color(0xFF190700)],
            center: Alignment.center,
            radius: 1.25,
          ),
        ),
        child: Stack(
          children: [
            // Safe Area Layout
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  children: [
                    // ================= HEADER ROW =================
                    _buildHeaderRow(),
                    const SizedBox(height: 8.0),

                    // ================= MAIN BODY SPLIT =================
                    Expanded(
                      child: Row(
                        children: [
                          // Left Panel (Wager presets, selections & Streak)
                          _buildLeftControlsPanel(currentStreakMult),
                          const SizedBox(width: 14.0),

                          // Right Panel (The Flipping Coin)
                          Expanded(child: _buildRightCoinPanel()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Particle Canvas Overlay
            if (_particles.isNotEmpty && _showWinOverlay)
              IgnorePointer(
                child: CustomPaint(
                  size: size,
                  painter: ParticlePainter(particles: _particles),
                ),
              ),

            // Major Streak/Win Banner
            if (_showWinOverlay && _winAmount > 0)
              Center(
                child: IgnorePointer(
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isHeadsSelected
                              ? [const Color(0xFFFFD700), const Color(0xFFFF8F00)]
                              : [const Color(0xFFECEFF1), const Color(0xFF90A4AE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.55),
                            blurRadius: 18.0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _streak >= 3 ? 'STREAK WIN!' : 'YOU WON!',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 24.0,
                              color: _isHeadsSelected ? Colors.white : const Color(0xFF1A0600),
                              shadows: _isHeadsSelected
                                  ? [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1.5, 1.5))]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '+₹${_winAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 20.0,
                              color: _isHeadsSelected ? Colors.white : const Color(0xFF1A0600),
                              shadows: _isHeadsSelected
                                  ? [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1.5, 1.5))]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILD SECTIONS ====================

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Retro Back capsule
        _buildCapsuleButton(
          icon: Icons.arrow_back,
          label: 'LOBBY',
          color: const Color(0xFFFF5252),
          onTap: () {
            if (_isFlipping) return;
            widget.onBackPressed();
          },
        ),

        // Double shadow Title
        Text(
          'COIN FLIP',
          style: GoogleFonts.alfaSlabOne(
            textStyle: const TextStyle(
              fontSize: 22.0,
              color: Color(0xFFFFD700),
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Color(0xFF8A0000), offset: Offset(2.0, 2.0), blurRadius: 1.0),
                Shadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 2.0),
              ],
            ),
          ),
        ),

        // Coins balance capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: const Color(0xFF160E45),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFF9E84FF), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                widget.balance.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftControlsPanel(double streakMultiplier) {
    return Container(
      width: 210.0,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF160E45).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF9E84FF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bet display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0736),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                const Text(
                  'BET AMOUNT',
                  style: TextStyle(color: Color(0xFF9E84FF), fontSize: 8.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${_betAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.alfaSlabOne(color: const Color(0xFFFFD700), fontSize: 13.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),

          // Presets Grid
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPresetButton('MIN', () => setState(() => _betAmount = 0.5)),
                _buildPresetButton('1.0', () => setState(() => _betAmount = 1.0)),
                _buildPresetButton('5.0', () => setState(() => _betAmount = 5.0)),
                _buildPresetButton('10', () => setState(() => _betAmount = 10.0)),
                _buildPresetButton('x2', () {
                  setState(() {
                    _betAmount = (_betAmount * 2).clamp(0.5, 500.0);
                  });
                }),
                _buildPresetButton('/2', () {
                  setState(() {
                    _betAmount = (_betAmount / 2).clamp(0.5, 500.0);
                  });
                }),
              ],
            ),
          ),
          const SizedBox(height: 6.0),

          // Streak Bonus Badge
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C0F02), Color(0xFF0F0736)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: _streak >= 2 ? const Color(0xFFFFD700) : const Color(0xFF322878),
                  width: _streak >= 2 ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: _streak >= 2 ? const Color(0xFFFF9100) : Colors.grey,
                        size: 20.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'STREAK: $_streak',
                        style: GoogleFonts.alfaSlabOne(
                          fontSize: 11.0,
                          color: _streak >= 2 ? const Color(0xFFFFD700) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'PAYOUT: ${streakMultiplier.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: _streak >= 2 ? const Color(0xFF00E5FF) : Colors.grey,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.0,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  const Text(
                    'Streak of 2+ wins gets multipliers up to 2.25x!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 7.0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Pick Side labels
          const Center(
            child: Text(
              'SELECT SIDE TO BET ON',
              style: TextStyle(color: Color(0xFF9E84FF), fontSize: 8.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4.0),

          // Heads / Tails buttons
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: _buildSideSelectionCard(
                    isHeads: true,
                    label: 'HEADS',
                    color: const Color(0xFFFFD700),
                    borderColor: const Color(0xFFC7A000),
                    isSelected: _isHeadsSelected,
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: _buildSideSelectionCard(
                    isHeads: false,
                    label: 'TAILS',
                    color: const Color(0xFFECEFF1),
                    borderColor: const Color(0xFF90A4AE),
                    isSelected: !_isHeadsSelected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightCoinPanel() {
    return Column(
      children: [
        // Status Row indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0736),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFF332677), width: 1.0),
          ),
          child: Text(
            _statusText.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.alfaSlabOne(
              textStyle: TextStyle(
                fontSize: 10.0,
                color: _statusText.contains('WON')
                    ? const Color(0xFF00C853)
                    : _statusText.contains('LOST')
                        ? const Color(0xFFFF5252)
                        : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Flip Playfield
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final double rotationVal = _rotationAnimation.value;
                final double scaleVal = _heightAnimation.value;

                // 3D perspective transformation matrix
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // perspective factor
                  ..rotateY(rotationVal);

                // Determine showing face
                final bool isHeadsShowing = cos(rotationVal) >= 0.0;

                return Transform(
                  transform: matrix,
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: scaleVal,
                    child: Container(
                      width: 140.0,
                      height: 140.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 16.0 * scaleVal,
                            offset: Offset(0, 10 * scaleVal), // shadow shifts down as coin flies high
                          ),
                        ],
                      ),
                      child: isHeadsShowing ? _buildHeadsCoinFace() : _buildTailsCoinFace(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Win Log History (Heads vs Tails)
        Container(
          height: 38.0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF160E45).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFF322878), width: 1.0),
          ),
          child: Row(
            children: [
              const Text(
                'HISTORY:',
                style: TextStyle(color: Color(0xFF9E84FF), fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8.0),
              if (_history.isEmpty)
                const Text(
                  'No spins yet. Flip to record results!',
                  style: TextStyle(color: Colors.grey, fontSize: 8.5, fontStyle: FontStyle.italic),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _history.map((isHeads) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Container(
                          width: 18.0,
                          height: 18.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isHeads
                                  ? [const Color(0xFFFFD700), const Color(0xFFF57F17)]
                                  : [const Color(0xFFECEFF1), const Color(0xFF90A4AE)],
                            ),
                            border: Border.all(color: Colors.white, width: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isHeads ? 'H' : 'T',
                            style: TextStyle(
                              fontSize: 8.0,
                              color: isHeads ? Colors.black : const Color(0xFF1A0600),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // Flip Button
              _buildFlipPlayButton(),
            ],
          ),
        ),
      ],
    );
  }

  // Coin Face heads (Gold themed, ribbed rim, star center)
  Widget _buildHeadsCoinFace() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFEE58), Color(0xFFF57F17)],
        ),
        border: Border.all(color: const Color(0xFFFFD700), width: 6.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0C0C0E), // logo background black
          ),
          child: const Center(
            child: Icon(
              Icons.star,
              color: Color(0xFFFFD700),
              size: 58.0,
            ),
          ),
        ),
      ),
    );
  }

  // Coin Face tails (Silver themed, ribbed rim, curved double arrows center)
  Widget _buildTailsCoinFace() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFCFD8DC), Color(0xFF546E7A)],
        ),
        border: Border.all(color: const Color(0xFFB0BEC5), width: 6.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0C0C0E), // logo background black
          ),
          child: const Center(
            child: Icon(
              Icons.sync, // Represents flipped double arrows
              color: Color(0xFFECEFF1),
              size: 58.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideSelectionCard({
    required bool isHeads,
    required String label,
    required Color color,
    required Color borderColor,
    required bool isSelected,
  }) {
    final double offsetTop = isSelected ? 3.0 : 0.0;

    return GestureDetector(
      onTap: () => _onSideSelected(isHeads),
      child: Container(
        height: 52.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Shadow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? borderColor : const Color(0xFF22184F),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            // Top Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: offsetTop,
              height: 48.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? color : const Color(0xFF332677),
                  borderRadius: BorderRadius.circular(10.0),
                  border: isSelected ? Border.all(color: Colors.white, width: 1.2) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isHeads ? Icons.monetization_on : Icons.stars,
                      color: isSelected
                          ? (isHeads ? const Color(0xFFF57F17) : const Color(0xFF37474F))
                          : Colors.white70,
                      size: 16.0,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      label,
                      style: GoogleFonts.alfaSlabOne(
                        textStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: _isFlipping ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF322878),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: const Color(0xFF9E84FF), width: 1.0),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCapsuleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipPlayButton() {
    final bool isEnabled = !_isFlipping;

    return InkWell(
      onTap: isEnabled ? _startFlip : null,
      child: Container(
        height: 28.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)])
              : const LinearGradient(colors: [Color(0xFF424242), Color(0xFF616161)]),
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: const Color(0xFF00C853).withOpacity(0.4),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          _isFlipping ? 'FLIPPING...' : 'FLIP COIN',
          style: GoogleFonts.alfaSlabOne(
            textStyle: const TextStyle(color: Colors.white, fontSize: 9.0, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

// Particle model for wins
class CoinFlipParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double rotationSpeed;
  bool isGold;
  bool isStar;

  CoinFlipParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isGold,
    required this.isStar,
  });
}

// Custom Painter to draw falling gold/silver coins and star particles
class ParticlePainter extends CustomPainter {
  final List<CoinFlipParticle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final goldBorderPaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final silverPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.fill;

    final silverBorderPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isStar) {
        // Draw small star
        final path = Path();
        final double outerRadius = p.size / 2;
        final double innerRadius = outerRadius * 0.45;
        const int points = 5;

        for (int i = 0; i < points * 2; i++) {
          final double angle = i * pi / points - pi / 2;
          final double r = i.isEven ? outerRadius : innerRadius;
          final double px = cos(angle) * r;
          final double py = sin(angle) * r;

          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, starPaint);
      } else {
        // Draw coin (Gold or Silver)
        final fillPaint = p.isGold ? goldPaint : silverPaint;
        final borderPaint = p.isGold ? goldBorderPaint : silverBorderPaint;

        canvas.drawCircle(Offset.zero, p.size / 2, fillPaint);
        canvas.drawCircle(Offset.zero, p.size / 2, borderPaint);
        canvas.drawCircle(Offset.zero, p.size / 3, borderPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
