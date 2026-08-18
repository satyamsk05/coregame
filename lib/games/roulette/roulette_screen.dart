import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/widgets/bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/sound_helper.dart';
import '../../shared/widgets/win_overlay_card.dart';

class RouletteGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const RouletteGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<RouletteGameScreen> createState() => _RouletteGameScreenState();
}

class RouletteParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double vRotation;
  Color color;
  bool isStar;

  RouletteParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.vRotation,
    required this.color,
    this.isStar = false,
  });
}

class _RouletteGameScreenState extends State<RouletteGameScreen> with SingleTickerProviderStateMixin {
  // Gameplay state
  double _betAmount = 1.0;
  String _betType = 'color'; // 'color', 'parity', 'number'
  String _betValue = 'red'; // 'red', 'black', 'even', 'odd', or string number '0'-'36'
  
  bool _isSpinning = false;
  int _winningNumber = 0;
  double _winAmount = 0.0;
  bool _showWinOverlay = false;
  String _statusText = 'PLACE YOUR BETS AND SPIN!';
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _spinAnimation;
  
  final List<int> _history = [];
  final List<RouletteParticle> _particles = [];
  Timer? _particlesTimer;
  final Random _random = Random();

  bool _showOutcomeCard = false;
  double _lastWinMultiplier = 1.96;
  double _lastWinAmount = 0.0;
  bool _lastOutcomeWin = true;
  Timer? _outcomeTimer;

  void _triggerOutcomeOverlay(double multi, double amount, bool isWin) {
    _outcomeTimer?.cancel();
    setState(() {
      _lastWinMultiplier = multi;
      _lastWinAmount = amount;
      _lastOutcomeWin = isWin;
      _showOutcomeCard = true;
    });
    _outcomeTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showOutcomeCard = false);
    });
  }
  int _lastSectorIndex = -1;

  // European Roulette Numbers order on the wheel clockwise
  static const List<int> rouletteNumbers = [
    0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _spinAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.addListener(() {
      _updateParticles();
      
      // Calculate sector crossings during spin to play mechanical ticking sound
      final double t = _spinAnimation.value;
      final double wheelAngle = t * 6 * pi; // total 3 full spins
      const double sectorAngle = 2 * pi / 37;
      final int currentSectorIndex = (wheelAngle / sectorAngle).floor();
      
      if (currentSectorIndex != _lastSectorIndex) {
        _lastSectorIndex = currentSectorIndex;
        // Bouncing audio ticks on wheel sector crossing
        if (widget.soundOn && _isSpinning) {
          playTick();
        }
      }
      
      // Additional ball drop bounce sounds at the end
      if (t >= 0.85 && t < 0.98) {
        final double settleT = (t - 0.85) / 0.13;
        final int bounceTick = (settleT * 6).floor();
        if (bounceTick != _lastSectorIndex && widget.soundOn) {
          _lastSectorIndex = bounceTick;
          playTick();
        }
      }

      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishSpin();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isRed(int n) {
    if (n == 0) return false;
    const red = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36};
    return red.contains(n);
  }

  bool _isBlack(int n) {
    if (n == 0) return false;
    return !_isRed(n);
  }

  Color _getNumberColor(int n) {
    if (n == 0) return const Color(0xFF00C853);
    return _isRed(n) ? const Color(0xFFFF5252) : const Color(0xFF1E2024);
  }

  void _onBetTypeChanged(String type) {
    if (_isSpinning) return;
    setState(() {
      _betType = type;
      if (type == 'color') _betValue = 'red';
      if (type == 'parity') _betValue = 'even';
      if (type == 'number') _betValue = '7';
      _showWinOverlay = false;
    });
  }

  void _startSpin() {
    if (_isSpinning) return;

    if (widget.balance < _betAmount) {
      _showErrorDialog('INSUFFICIENT BALANCE', 'Please top up your balance from the lobby.');
      return;
    }

    // Deduct bet amount
    widget.onBalanceChanged(widget.balance - _betAmount);

    setState(() {
      _isSpinning = true;
      _showWinOverlay = false;
      _winAmount = 0.0;
      _statusText = 'THE WHEEL IS SPINNING...';
    });

    // Randomize winning number
    _winningNumber = _random.nextInt(37);

    // Reset ticks tracking
    _lastSectorIndex = -1;

    // Start rotation animation
    _animationController.forward(from: 0.0);
  }

  void _finishSpin() {
    bool isWin = false;
    double payoutMultiplier = 0.0;

    if (_betType == 'color') {
      if (_betValue == 'red' && _isRed(_winningNumber)) {
        isWin = true;
        payoutMultiplier = 2.0;
      } else if (_betValue == 'black' && _isBlack(_winningNumber)) {
        isWin = true;
        payoutMultiplier = 2.0;
      }
    } else if (_betType == 'parity') {
      if (_winningNumber != 0) {
        if (_betValue == 'even' && _winningNumber % 2 == 0) {
          isWin = true;
          payoutMultiplier = 2.0;
        } else if (_betValue == 'odd' && _winningNumber % 2 != 0) {
          isWin = true;
          payoutMultiplier = 2.0;
        }
      }
    } else if (_betType == 'number') {
      final int chosenNum = int.tryParse(_betValue) ?? -1;
      if (chosenNum == _winningNumber) {
        isWin = true;
        payoutMultiplier = 35.0; // Standard single number payout
      }
    }

    setState(() {
      _isSpinning = false;
      _history.add(_winningNumber);
      if (_history.length > 8) {
        _history.removeAt(0);
      }

      if (isWin) {
        _winAmount = _betAmount * payoutMultiplier;
        widget.onBalanceChanged(widget.balance + _winAmount);
        _showWinOverlay = true;
        _statusText = 'WON! LANDED ON $_winningNumber';
        _spawnParticles();
        _triggerOutcomeOverlay(payoutMultiplier, _winAmount, true);
        if (widget.soundOn) {
          playWin();
        }
      } else {
        _winAmount = 0.0;
        _statusText = 'LOST. LANDED ON $_winningNumber';
        _triggerOutcomeOverlay(0.0, 0.0, false);
        if (widget.soundOn) {
          playLose();
        }
      }
    });
  }

  void _spawnParticles() {
    _particles.clear();
    final winColor = _getNumberColor(_winningNumber);
    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 3.0 + _random.nextDouble() * 5.0;
      _particles.add(
        RouletteParticle(
          x: 520.0, // Centered on wheel area
          y: 200.0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 2.0, // slight upward drift
          size: 4.0 + _random.nextDouble() * 6.0,
          rotation: _random.nextDouble() * 2 * pi,
          vRotation: -0.1 + _random.nextDouble() * 0.2,
          color: i.isEven ? winColor : const Color(0xFFFFD700), // Mix winning color with gold
          isStar: _random.nextBool(),
        ),
      );
    }
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.15; // gravity
      p.rotation += p.vRotation;
    }
    _particles.removeWhere((p) => p.y > 390.0 || p.x < 0.0 || p.x > 844.0);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320.0,
          padding: const EdgeInsets.all(20.0),
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF0F0A30), Color(0xFF050312)],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Header Area
                    _buildHeaderRow(),
                    const SizedBox(height: 8.0),

                    // Main Layout Area Split (Left Controls, Right Game Playfield)
                    Expanded(
                      child: Row(
                        children: [
                          _buildLeftControlsPanel(),
                          const SizedBox(width: 12.0),
                          Expanded(child: _buildRightGamePanel()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Particle overlay layer
            if (_particles.isNotEmpty && _showWinOverlay)
              IgnorePointer(
                child: CustomPaint(
                  size: size,
                  painter: _RouletteParticlePainter(particles: _particles),
                ),
              ),

            // Victory scale popup overlay
            if (_showWinOverlay && _winAmount > 0.0)
              Center(
                child: IgnorePointer(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20.0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'WINNER!',
                            style: GoogleFonts.alfaSlabOne(fontSize: 24.0, color: Colors.white),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '+₹${_winAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.alfaSlabOne(fontSize: 20.0, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Win/Lose Overlay Card centered over Roulette Wheel
            if (_showOutcomeCard)
              Center(
                child: WinOverlayCard(
                  multiplier: _lastWinMultiplier,
                  winAmount: _lastWinAmount,
                  isWin: _lastOutcomeWin,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Exit to Lobby button
        _buildCapsuleButton(
          icon: Icons.arrow_back,
          label: 'LOBBY',
          color: const Color(0xFFFF5252),
          onTap: () {
            if (_isSpinning) return;
            widget.onBackPressed();
          },
        ),

        // Double shadow game title
        Text(
          'ROULETTE RUSH',
          style: GoogleFonts.alfaSlabOne(
            textStyle: const TextStyle(
              fontSize: 22.0,
              color: Color(0xFF00E5FF),
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Color(0xFF006064), offset: Offset(2.0, 2.0), blurRadius: 1.0),
                Shadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 2.0),
              ],
            ),
          ),
        ),

        // User Wallet balance
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

  Widget _buildCapsuleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: const Color(0xFF160E45),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14.0),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftControlsPanel() {
    return Container(
      width: 200.0,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF160E45).withValues(alpha: 0.85),
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

          // Wager presets
          Row(
            children: [
              _buildPresetBtn('MIN', () => setState(() => _betAmount = 0.5)),
              const SizedBox(width: 4.0),
              _buildPresetBtn('x2', () => setState(() => _betAmount = (_betAmount * 2).clamp(0.5, 200.0))),
              const SizedBox(width: 4.0),
              _buildPresetBtn('/2', () => setState(() => _betAmount = (_betAmount / 2).clamp(0.5, 200.0))),
            ],
          ),
          const SizedBox(height: 8.0),

          // Bet categories header
          const Text(
            'BET TYPE',
            style: TextStyle(color: Color(0xFF9E84FF), fontSize: 8.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),

          // Bet type selectors
          Row(
            children: [
              _buildCategorySelect('COLOR', _betType == 'color', () => _onBetTypeChanged('color')),
              _buildCategorySelect('PARITY', _betType == 'parity', () => _onBetTypeChanged('parity')),
              _buildCategorySelect('NUMBER', _betType == 'number', () => _onBetTypeChanged('number')),
            ],
          ),
          const SizedBox(height: 10.0),

          // Bet Value Selection Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0736),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _buildBetValueSelector(),
            ),
          ),
          const SizedBox(height: 6.0),

          // Action Spin button
          GestureDetector(
            onTap: _isSpinning ? null : _startSpin,
            child: Container(
              height: 40.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isSpinning ? const Color(0xFF5E5E6E) : const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: _isSpinning
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.4),
                          blurRadius: 8.0,
                        ),
                      ],
              ),
              child: Text(
                _isSpinning ? 'SPINNING...' : 'SPIN WHEEL',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSpinning ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1154),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelect(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF9E84FF) : const Color(0xFF0D062B),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: active ? Colors.white : Colors.transparent, width: 1.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white70,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBetValueSelector() {
    if (_betType == 'color') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSelectionTile('RED (2.0x)', _betValue == 'red', const Color(0xFFFF5252), () => setState(() => _betValue = 'red')),
          const SizedBox(height: 8.0),
          _buildSelectionTile('BLACK (2.0x)', _betValue == 'black', const Color(0xFF1A1D20), () => setState(() => _betValue = 'black')),
        ],
      );
    } else if (_betType == 'parity') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSelectionTile('EVEN (2.0x)', _betValue == 'even', const Color(0xFF9E84FF), () => setState(() => _betValue = 'even')),
          const SizedBox(height: 8.0),
          _buildSelectionTile('ODD (2.0x)', _betValue == 'odd', const Color(0xFF00E5FF), () => setState(() => _betValue = 'odd')),
        ],
      );
    } else {
      // Grid of 0-36 numbers
      return Scrollbar(
        thumbVisibility: true,
        child: GridView.builder(
          padding: const EdgeInsets.all(4.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
            childAspectRatio: 1.0,
          ),
          itemCount: 37,
          itemBuilder: (context, index) {
            final String numStr = index.toString();
            final bool isSelected = _betValue == numStr;
            final Color color = _getNumberColor(index);
            
            return GestureDetector(
              onTap: _isSpinning ? null : () => setState(() => _betValue = numStr),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 4.0,
                          )
                        ]
                      : [],
                ),
                child: Text(
                  numStr,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: index == 0 ? 11.0 : 10.0,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildSelectionTile(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isSpinning ? null : onTap,
      child: Container(
        height: 34.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 1.0 : 0.3),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: active ? Colors.white : color, width: active ? 2.0 : 1.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w900,
            fontSize: 10.0,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRightGamePanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background layout
          Column(
            children: [
              // Top recent spin results display
              Container(
                height: 38.0,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                color: const Color(0xFF212529).withValues(alpha: 0.8),
                child: Row(
                  children: [
                    const Text(
                      'RECENT:',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 9.0),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final int val = _history[_history.length - 1 - index];
                          final Color col = _getNumberColor(val);
                          return Container(
                            width: 24.0,
                            height: 24.0,
                            margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 7.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                            child: Text(
                              '$val',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Game Main graphics row
              Expanded(
                child: Row(
                  children: [
                    // Spinning Wheel graphic (Left)
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CustomPaint(
                              painter: _RouletteWheelPainter(
                                progress: _spinAnimation.value,
                                winningNumber: _winningNumber,
                                isSpinning: _isSpinning,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bet placement info panel (Right)
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12.0, 14.0, 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoValueRow('ACTIVE BET', _betType.toUpperCase()),
                            const SizedBox(height: 6.0),
                            _buildInfoValueRow('BET SELECTION', _betValue.toUpperCase()),
                            const SizedBox(height: 6.0),
                            _buildInfoValueRow(
                              'PAYOUT MULTIPLIER',
                              _betType == 'color' || _betType == 'parity' ? '2.00x' : '35.00x',
                            ),
                            const SizedBox(height: 12.0),

                            // Display status bar
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF13083B),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: const Color(0xFF9E84FF).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _statusText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pressStart2p(
                                  textStyle: TextStyle(
                                    color: _statusText.contains('WON') ? const Color(0xFF00C853) : Colors.white,
                                    fontSize: 8.0,
                                    height: 1.4,
                                  ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoValueRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF13151A),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 8.5, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: GoogleFonts.alfaSlabOne(color: Colors.white, fontSize: 10.0, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _RouletteWheelPainter extends CustomPainter {
  final double progress;
  final int winningNumber;
  final bool isSpinning;

  _RouletteWheelPainter({
    required this.progress,
    required this.winningNumber,
    required this.isSpinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width / 2;
    final centerOffset = Offset(center, center);

    // 1. Draw outer gold decorative rim ring
    final rimPaint = Paint()
      ..color = const Color(0xFF0C0A0E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, radius, rimPaint);

    final goldEdgePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(centerOffset, radius - 1.5, goldEdgePaint);

    // Draw little gold studs around rim
    final studPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final double studAngle = i * (2 * pi / 12);
      final double studX = center + (radius - 5.0) * cos(studAngle);
      final double studY = center + (radius - 5.0) * sin(studAngle);
      canvas.drawCircle(Offset(studX, studY), 2.0, studPaint);
    }

    // 2. Draw Wheel slices
    // Current wheel rotation angle (radians clockwise)
    final double wheelRotation = progress * 6 * pi;
    const double sectorAngle = 2 * pi / 37;

    final redPaint = Paint()..color = const Color(0xFFFF5252);
    final blackPaint = Paint()..color = const Color(0xFF1E2024);
    final greenPaint = Paint()..color = const Color(0xFF00C853);
    final dividerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw 37 colored sectors
    for (int i = 0; i < 37; i++) {
      final double startAngle = wheelRotation + (i * sectorAngle) - (pi / 2) - (sectorAngle / 2);
      final int number = _RouletteGameScreenState.rouletteNumbers[i];
      final Paint sectorPaint = number == 0
          ? greenPaint
          : (_isRedNumber(number) ? redPaint : blackPaint);

      canvas.drawArc(
        Rect.fromCircle(center: centerOffset, radius: radius - 6.0),
        startAngle,
        sectorAngle,
        true,
        sectorPaint,
      );

      // Draw Golden divider lines
      canvas.drawArc(
        Rect.fromCircle(center: centerOffset, radius: radius - 6.0),
        startAngle,
        sectorAngle,
        true,
        dividerPaint,
      );
    }

    // Draw number labels inside sectors
    for (int i = 0; i < 37; i++) {
      final double angle = wheelRotation + (i * sectorAngle) - (pi / 2);
      final int number = _RouletteGameScreenState.rouletteNumbers[i];
      
      canvas.save();
      canvas.translate(center, center);
      canvas.rotate(angle);
      
      // Paint text vertically oriented inside sector slice
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$number',
          style: const TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position near outer rim
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -radius + 14.0));
      canvas.restore();
    }

    // 3. Inner spinner bowl center
    final bowlPaint = Paint()
      ..color = const Color(0xFF110C1B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, radius * 0.65, bowlPaint);

    final innerGoldRim = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(centerOffset, radius * 0.65, innerGoldRim);

    // Draw central golden brass turret dome spinner
    final domePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, 12.0, domePaint);

    // Draw spinner handles/pins (4 spokes)
    final handlePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (int i = 0; i < 4; i++) {
      final double handleAngle = wheelRotation + i * (2 * pi / 4);
      final double hx = center + 22.0 * cos(handleAngle);
      final double hy = center + 22.0 * sin(handleAngle);
      canvas.drawLine(centerOffset, Offset(hx, hy), handlePaint);
      canvas.drawCircle(Offset(hx, hy), 3.0, domePaint);
    }

    // 4. Draw Ball!
    // Ball physics trajectory mapping (Rim orbit -> spiraling settle down with bounce)
    final int winningIndex = _RouletteGameScreenState.rouletteNumbers.indexOf(winningNumber);
    final double winningAngle = (winningIndex * sectorAngle) - (pi / 2);

    double ballAngle;
    double ballDist;

    if (progress < 0.85) {
      // Phase 1: High speed reverse orbit
      final double ballT = progress / 0.85;
      ballAngle = -10 * pi * (1.0 - ballT) + wheelRotation + winningAngle;
      ballDist = radius * 0.82;
    } else {
      // Phase 2: Drop into slot and bounce-settle
      final double settleT = (progress - 0.85) / 0.15;
      ballAngle = wheelRotation + winningAngle + sin((1.0 - settleT) * 4 * pi) * 0.15 * (1.0 - settleT);
      ballDist = radius * (0.82 - 0.14 * settleT + cos(settleT * 3 * pi).abs() * 0.05 * (1.0 - settleT));
    }

    final double bx = center + ballDist * cos(ballAngle);
    final double by = center + ballDist * sin(ballAngle);

    // Ball shadows
    canvas.drawCircle(
      Offset(bx + 1.0, by + 1.0),
      4.5,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    // Draw ball itself
    canvas.drawCircle(
      Offset(bx, by),
      4.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  bool _isRedNumber(int n) {
    if (n == 0) return false;
    const red = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36};
    return red.contains(n);
  }

  @override
  bool shouldRepaint(covariant _RouletteWheelPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.winningNumber != winningNumber ||
        oldDelegate.isSpinning != isSpinning;
  }
}

class _RouletteParticlePainter extends CustomPainter {
  final List<RouletteParticle> particles;

  _RouletteParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isStar) {
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
        canvas.drawCircle(Offset.zero, p.size / 2, Paint()..color = p.color);
        canvas.drawCircle(
          Offset.zero,
          p.size / 2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
