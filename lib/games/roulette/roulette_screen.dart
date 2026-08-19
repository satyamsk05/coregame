import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../shared/widgets/bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/sound_helper.dart';
import '../../shared/widgets/win_overlay_card.dart';
import '../andar_bahar/widgets/chip_widgets.dart';
import '../andar_bahar/widgets/player_widgets.dart';

class RouletteGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;
  final String nickname;
  final String avatarPath;

  const RouletteGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
    required this.nickname,
    required this.avatarPath,
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
  // Game phase: 'betting' → 'spinning' → 'result' → loop
  String _gamePhase = 'betting';
  int _timerSeconds = 15;
  Timer? _gameTimer;

  // Gameplay state
  double _betAmount = 0.0;
  String _betType = ''; // 'color', 'parity', 'number', 'dozen', 'column', 'half'
  String _betValue = ''; // 'red', 'black', 'even', 'odd', '1'/'2'/'3', or string number '0'-'36'
  int _selectedChipValue = 10;
  int _triggerUserBet = 0;
  int _triggerUserWin = 0;
  
  bool _isSpinning = false;
  int _winningNumber = 0;
  double _winAmount = 0.0;
  bool _showWinOverlay = false;
  String _statusText = 'PLACE YOUR BETS!';
  
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
      duration: const Duration(milliseconds: 3900),
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
      
      // Additional ball drop bounce sounds during settle phase
      if (t >= 0.6 && t < 0.95) {
        final double settleT = (t - 0.6) / 0.35;
        final int bounceTick = (settleT * 8).floor();
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

    // Start the auto-countdown game loop
    _startBettingPhase();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _outcomeTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Auto-Countdown Game Loop (like Andar Bahar)
  // ════════════════════════════════════════════════════════════════════════════

  void _startBettingPhase() {
    setState(() {
      _gamePhase = 'betting';
      _timerSeconds = 15;
      _isSpinning = false;
      _showWinOverlay = false;
      _showOutcomeCard = false;
      _betAmount = 0.0;
      _betType = '';
      _betValue = '';
      _winAmount = 0.0;
      _statusText = 'PLACE YOUR BETS!';
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        _gameTimer?.cancel();
        _startSpin();
      }
    });
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

  void _placeBet(String type, String value) {
    if (_gamePhase != 'betting') return;
    if (widget.balance < _selectedChipValue) return;
    setState(() {
      if (_betType == type && _betValue == value) {
        _betAmount += _selectedChipValue;
      } else {
        _betType = type;
        _betValue = value;
        _betAmount = _selectedChipValue.toDouble();
      }
      _showWinOverlay = false;
      _triggerUserBet++;
    });
  }

  void _clearBet() {
    if (_gamePhase != 'betting') return;
    setState(() {
      _betAmount = 0.0;
      _betType = '';
      _betValue = '';
      _showWinOverlay = false;
    });
  }

  void _startSpin() {
    // Deduct bet amount if user has placed a bet
    if (_betAmount > 0.0 && widget.balance >= _betAmount) {
      widget.onBalanceChanged(widget.balance - _betAmount);
    } else {
      // No valid bet, just spin without deduction
      _betAmount = 0.0;
      _betType = '';
      _betValue = '';
    }

    setState(() {
      _gamePhase = 'spinning';
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
    } else if (_betType == 'dozen') {
      if (_winningNumber != 0) {
        if (_betValue == '1' && _winningNumber >= 1 && _winningNumber <= 12) {
          isWin = true;
          payoutMultiplier = 3.0;
        } else if (_betValue == '2' && _winningNumber >= 13 && _winningNumber <= 24) {
          isWin = true;
          payoutMultiplier = 3.0;
        } else if (_betValue == '3' && _winningNumber >= 25 && _winningNumber <= 36) {
          isWin = true;
          payoutMultiplier = 3.0;
        }
      }
    } else if (_betType == 'column') {
      if (_winningNumber != 0) {
        if (_betValue == '1' && _winningNumber % 3 == 0) {
          isWin = true;
          payoutMultiplier = 3.0;
        } else if (_betValue == '2' && _winningNumber % 3 == 2) {
          isWin = true;
          payoutMultiplier = 3.0;
        } else if (_betValue == '3' && _winningNumber % 3 == 1) {
          isWin = true;
          payoutMultiplier = 3.0;
        }
      }
    } else if (_betType == 'half') {
      if (_winningNumber != 0) {
        if (_betValue == '1' && _winningNumber >= 1 && _winningNumber <= 18) {
          isWin = true;
          payoutMultiplier = 2.0;
        } else if (_betValue == '2' && _winningNumber >= 19 && _winningNumber <= 36) {
          isWin = true;
          payoutMultiplier = 2.0;
        }
      }
    }

    setState(() {
      _gamePhase = 'result';
      _isSpinning = false;
      _history.add(_winningNumber);
      if (_history.length > 8) {
        _history.removeAt(0);
      }

      if (isWin && _betAmount > 0.0) {
        _winAmount = _betAmount * payoutMultiplier;
        widget.onBalanceChanged(widget.balance + _winAmount);
        _showWinOverlay = true;
        _statusText = 'WON! LANDED ON $_winningNumber';
        _spawnParticles();
        _triggerOutcomeOverlay(payoutMultiplier, _winAmount, true);
        _triggerUserWin++;
        if (widget.soundOn) {
          playWin();
        }
      } else if (_betAmount > 0.0) {
        _winAmount = 0.0;
        _statusText = 'LOST. LANDED ON $_winningNumber';
        _triggerOutcomeOverlay(0.0, 0.0, false);
        if (widget.soundOn) {
          playLose();
        }
      } else {
        _statusText = 'LANDED ON $_winningNumber';
      }
    });

    // Auto-restart betting phase after result display
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) _startBettingPhase();
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

  Widget _buildWheelContainer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Recent history list (compact style at the top of the wheel panel)
          Container(
            height: 28.0,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Row(
              children: [
                const Text(
                  'RECENT:',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 8.0),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final int val = _history[_history.length - 1 - index];
                      final Color col = _getNumberColor(val);
                      return Container(
                        width: 18.0,
                        height: 18.0,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                        child: Text(
                          '$val',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8.0),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          // Spinner
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _RouletteWheelPainter(
                  progress: _spinAnimation.value,
                  winningNumber: _winningNumber,
                  isSpinning: _isSpinning,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // Status text display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF13083B),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                textStyle: TextStyle(
                  color: _statusText.contains('WON') ? const Color(0xFF00C853) : Colors.white,
                  fontSize: 7.0,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
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
            colors: [Color(0xFF141A29), Color(0xFF0A0D14)],
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

                    // Main Layout Area Split (Left Wheel, Right Board)
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildWheelContainer(),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            flex: 9,
                            child: _buildInteractiveBoard(),
                          ),
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
      children: [
        // Exit to Lobby button
        GestureDetector(
          onTap: () {
            if (_isSpinning) return;
            widget.onBackPressed();
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16.0),
          ),
        ),
        const SizedBox(width: 8.0),

        // Total Bet Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: const Color(0x1F000000),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TOTAL BET',
                style: TextStyle(color: Colors.grey, fontSize: 7.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 1.0),
              Text(
                '₹${_betAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Stylized Roulette Title
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'R O U',
                style: GoogleFonts.robotoCondensed(
                  textStyle: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                ),
              ),
              TextSpan(
                text: ' L E T T E',
                style: GoogleFonts.robotoCondensed(
                  textStyle: const TextStyle(color: Color(0xFFFF2A54), fontSize: 18.0, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),

        // User Wallet balance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14.0),
              const SizedBox(width: 4.0),
              Text(
                '₹${widget.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),

        // Trends Icon
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(Icons.trending_up, color: Colors.white70, size: 16.0),
        ),
        const SizedBox(width: 8.0),

        // Settings Icon
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(Icons.settings, color: Colors.white70, size: 16.0),
        ),
      ],
    );
  }

  Widget _buildChipOverlay(double amount) {
    return Center(
      child: PokerChipWidget(
        value: amount.toInt(),
        size: 20.0,
      ),
    );
  }

  Widget _buildBoardCell({
    String? label,
    Widget? child,
    required Color color,
    required double width,
    required double height,
    required VoidCallback onTap,
    required bool hasChip,
    double fontSize = 9.0,
  }) {
    return GestureDetector(
      onTap: _isSpinning ? null : onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.white10, width: 0.8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (child != null) Center(child: child),
            if (label != null)
              Center(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ),
            if (hasChip && _betAmount > 0.0) _buildChipOverlay(_betAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveBoard() {
    const double cellHeight = 28.0;
    const double cellWidth = 32.0;
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid Row (0, Numbers Grid, 2 TO 1 Column)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0 Cell
                _buildBoardCell(
                  label: '0',
                  color: const Color(0xFF2E7D32),
                  width: cellWidth,
                  height: cellHeight * 3 + 4.0, // accounting for borders
                  onTap: () => _placeBet('number', '0'),
                  hasChip: _betType == 'number' && _betValue == '0',
                ),
                const SizedBox(width: 2.0),
                
                // Numbers Grid (Column with 3 Rows)
                Column(
                  children: [
                    // Row 1 (top row): 3, 6, 9... 36
                    Row(
                      children: List.generate(12, (index) {
                        final num = 3 * (index + 1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                          child: _buildBoardCell(
                            label: '$num',
                            color: _getNumberColor(num),
                            width: cellWidth,
                            height: cellHeight,
                            onTap: () => _placeBet('number', '$num'),
                            hasChip: _betType == 'number' && _betValue == '$num',
                          ),
                        );
                      }),
                    ),
                    // Row 2 (middle row): 2, 5, 8... 35
                    Row(
                      children: List.generate(12, (index) {
                        final num = 3 * index + 2;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                          child: _buildBoardCell(
                            label: '$num',
                            color: _getNumberColor(num),
                            width: cellWidth,
                            height: cellHeight,
                            onTap: () => _placeBet('number', '$num'),
                            hasChip: _betType == 'number' && _betValue == '$num',
                          ),
                        );
                      }),
                    ),
                    // Row 3 (bottom row): 1, 4, 7... 34
                    Row(
                      children: List.generate(12, (index) {
                        final num = 3 * index + 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                          child: _buildBoardCell(
                            label: '$num',
                            color: _getNumberColor(num),
                            width: cellWidth,
                            height: cellHeight,
                            onTap: () => _placeBet('number', '$num'),
                            hasChip: _betType == 'number' && _betValue == '$num',
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(width: 2.0),
                
                // 2 TO 1 Column
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: _buildBoardCell(
                        label: '2 TO 1',
                        color: const Color(0xFF1E2024),
                        width: cellWidth + 8.0,
                        height: cellHeight,
                        fontSize: 7.5,
                        onTap: () => _placeBet('column', '1'),
                        hasChip: _betType == 'column' && _betValue == '1',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: _buildBoardCell(
                        label: '2 TO 1',
                        color: const Color(0xFF1E2024),
                        width: cellWidth + 8.0,
                        height: cellHeight,
                        fontSize: 7.5,
                        onTap: () => _placeBet('column', '2'),
                        hasChip: _betType == 'column' && _betValue == '2',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: _buildBoardCell(
                        label: '2 TO 1',
                        color: const Color(0xFF1E2024),
                        width: cellWidth + 8.0,
                        height: cellHeight,
                        fontSize: 7.5,
                        onTap: () => _placeBet('column', '3'),
                        hasChip: _betType == 'column' && _betValue == '3',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2.0),
            
            // Dozens Row (1ST 12, 2ND 12, 3RD 12)
            Row(
              children: [
                SizedBox(width: cellWidth + 3.0), // alignment offset for 0 cell
                _buildBoardCell(
                  label: '1ST 12',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 4 + 6.0,
                  height: cellHeight,
                  onTap: () => _placeBet('dozen', '1'),
                  hasChip: _betType == 'dozen' && _betValue == '1',
                ),
                const SizedBox(width: 2.0),
                _buildBoardCell(
                  label: '2ND 12',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 4 + 6.0,
                  height: cellHeight,
                  onTap: () => _placeBet('dozen', '2'),
                  hasChip: _betType == 'dozen' && _betValue == '2',
                ),
                const SizedBox(width: 2.0),
                _buildBoardCell(
                  label: '3RD 12',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 4 + 6.0,
                  height: cellHeight,
                  onTap: () => _placeBet('dozen', '3'),
                  hasChip: _betType == 'dozen' && _betValue == '3',
                ),
              ],
            ),
            const SizedBox(height: 2.0),
            
            // Halves & Color Diamonds Row
            Row(
              children: [
                SizedBox(width: cellWidth + 3.0), // alignment offset
                _buildBoardCell(
                  label: '1 TO 18',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 2 + 2.0,
                  height: cellHeight,
                  fontSize: 8.5,
                  onTap: () => _placeBet('half', '1'),
                  hasChip: _betType == 'half' && _betValue == '1',
                ),
                const SizedBox(width: 2.0),
                _buildBoardCell(
                  label: 'EVEN',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 2 + 2.0,
                  height: cellHeight,
                  fontSize: 8.5,
                  onTap: () => _placeBet('parity', 'even'),
                  hasChip: _betType == 'parity' && _betValue == 'even',
                ),
                const SizedBox(width: 2.0),
                
                // RED diamond
                _buildBoardCell(
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 10.0,
                      height: 10.0,
                      color: const Color(0xFFFF5252),
                    ),
                  ),
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 2 + 2.0,
                  height: cellHeight,
                  onTap: () => _placeBet('color', 'red'),
                  hasChip: _betType == 'color' && _betValue == 'red',
                ),
                const SizedBox(width: 2.0),
                
                // BLACK diamond
                _buildBoardCell(
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 10.0,
                      height: 10.0,
                      color: const Color(0xFF15171C),
                    ),
                  ),
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 2 + 2.0,
                  height: cellHeight,
                  onTap: () => _placeBet('color', 'black'),
                  hasChip: _betType == 'color' && _betValue == 'black',
                ),
                const SizedBox(width: 2.0),
                
                _buildBoardCell(
                  label: 'ODD',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 2 + 2.0,
                  height: cellHeight,
                  fontSize: 8.5,
                  onTap: () => _placeBet('parity', 'odd'),
                  hasChip: _betType == 'parity' && _betValue == 'odd',
                ),
                const SizedBox(width: 2.0),
                _buildBoardCell(
                  label: '19 TO 36',
                  color: const Color(0xFF1E2024),
                  width: cellWidth * 2 + 2.0,
                  height: cellHeight,
                  fontSize: 8.5,
                  onTap: () => _placeBet('half', '2'),
                  hasChip: _betType == 'half' && _betValue == '2',
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        
        // Chips list & action buttons
        _buildBottomActionRow(),
      ],
    );
  }

  Widget _buildBottomActionRow() {
    final chips = [10, 50, 100, 500, 1000, 5000];
    final bool canInteract = _gamePhase == 'betting';
    
    return Row(
      children: [
        Transform.scale(
          scale: 1.2,
          child: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: UserAvatarWidget(
              balance: widget.balance,
              avatarPath: widget.avatarPath,
              nickname: widget.nickname,
              betTrigger: _triggerUserBet,
              winAmount: _winAmount,
              winTrigger: _triggerUserWin,
            ),
          ),
        ),
        const SizedBox(width: 14.0),

        const Icon(Icons.chevron_left, color: Colors.grey, size: 20.0),
        
        ...chips.map((val) {
          final isSelected = _selectedChipValue == val;
          return GestureDetector(
            onTap: canInteract ? () => setState(() => _selectedChipValue = val) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              transform: Matrix4.translationValues(0.0, isSelected ? -4.0 : 0.0, 0.0),
              child: Opacity(
                opacity: canInteract ? 1.0 : 0.5,
                child: Transform.scale(
                  scale: isSelected ? 1.08 : 1.0,
                  child: PokerChipWidget(
                    value: val,
                    size: 34.0,
                    selected: isSelected,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20.0),
        const Spacer(),
        
        // Clear Bet Action Button
        GestureDetector(
          onTap: canInteract ? _clearBet : null,
          child: Opacity(
            opacity: canInteract ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16.0),
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        
        // Countdown Timer Capsule (replaces SPIN button)
        _buildTimerCapsule(),
      ],
    );
  }

  Widget _buildTimerCapsule() {
    final bool isUrgent = _timerSeconds <= 3 && _gamePhase == 'betting';
    final Color timerColor = isUrgent ? const Color(0xFFFF3D00) : const Color(0xFFFFB300);
    final Color borderColor = isUrgent ? const Color(0xFFFF3D00) : const Color(0xFFFF9100);

    String displayText;
    if (_gamePhase == 'betting') {
      displayText = '00:${_timerSeconds.toString().padLeft(2, '0')}';
    } else if (_gamePhase == 'spinning') {
      displayText = 'SPINNING';
    } else {
      displayText = 'RESULT';
    }

    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: const Color(0xCC263238),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white12, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 14.0),
          alignment: Alignment.centerLeft,
          child: Text(
            displayText,
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(
                fontSize: _gamePhase == 'betting' ? 17.0 : 10.0,
                fontWeight: FontWeight.w900,
                color: timerColor,
                letterSpacing: 0.5,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0.0,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Mini clock face
        Positioned(
          right: 4.0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: borderColor,
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3.0,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 12 o'clock tick
                Positioned(
                  top: 2.0,
                  left: 12.5,
                  child: Container(width: 2.0, height: 3.0, color: borderColor),
                ),
                // 6 o'clock tick
                Positioned(
                  bottom: 2.0,
                  left: 12.5,
                  child: Container(width: 2.0, height: 3.0, color: borderColor),
                ),
                // 9 o'clock tick
                Positioned(
                  left: 2.0,
                  top: 12.5,
                  child: Container(width: 3.0, height: 2.0, color: borderColor),
                ),
                // 3 o'clock tick
                Positioned(
                  right: 2.0,
                  top: 12.5,
                  child: Container(width: 3.0, height: 2.0, color: borderColor),
                ),
                // Hour hand
                Positioned(
                  top: 8.0,
                  left: 12.5,
                  child: Transform.rotate(
                    angle: -2.3 - (_timerSeconds * 0.15),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 2.0,
                      height: 5.5,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(1.0),
                      ),
                    ),
                  ),
                ),
                // Minute hand
                Positioned(
                  top: 6.5,
                  left: 12.5,
                  child: Transform.rotate(
                    angle: 1.1 + (_timerSeconds * 0.4),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 2.0,
                      height: 7.0,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(1.0),
                      ),
                    ),
                  ),
                ),
                // Center dot
                Positioned(
                  top: 11.5,
                  left: 11.5,
                  child: Container(
                    width: 4.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final double side = min(size.width, size.height);
    final double radius = (side / 2) * 0.95;
    final centerOffset = Offset(size.width / 2, size.height / 2);

    // 1. Draw outer dark metallic ring
    final rimPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF5B5D66),
          const Color(0xFF292C33),
          const Color(0xFF111319),
          const Color(0xFF07080A),
        ],
        stops: const [0.0, 0.45, 0.8, 1.0],
        center: const Alignment(-0.2, -0.3),
      ).createShader(Rect.fromCircle(center: centerOffset, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, radius, rimPaint);

    final goldEdgePaint = Paint()
      ..color = const Color(0xFFD0A43E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.007;
    canvas.drawCircle(centerOffset, radius - (side * 0.0035), goldEdgePaint);

    // 2. Draw outer "twist" ticks
    final double wheelRotation = progress * 6 * pi;
    final tickPaintEven = Paint()
      ..color = const Color(0xFFE1B84F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.003;
    final tickPaintOdd = Paint()
      ..color = const Color(0xFF6B5424)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.003;

    for (int i = 0; i < 24; i++) {
      final double a = i * 2 * pi / 24 + wheelRotation * 0.15;
      final double x1 = centerOffset.dx + cos(a) * (radius * 0.94);
      final double y1 = centerOffset.dy + sin(a) * (radius * 0.94);
      final double x2 = centerOffset.dx + cos(a) * (radius * 0.88);
      final double y2 = centerOffset.dy + sin(a) * (radius * 0.88);
      
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        (i % 2 == 0) ? tickPaintEven : tickPaintOdd,
      );
    }

    // 3. Main number ring backing
    final double numRingOuter = radius * 0.78;
    final double numRingInner = radius * 0.54;
    final backingPaint = Paint()
      ..color = const Color(0xFFC99B36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (numRingOuter - numRingInner) + (side * 0.018);
    canvas.drawCircle(centerOffset, (numRingOuter + numRingInner) / 2, backingPaint);

    const double sectorAngle = 2 * pi / 37;
    final dividerPaint = Paint()
      ..color = const Color(0xFFECBD4F).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.0017;

    // Draw 37 colored sectors
    for (int i = 0; i < 37; i++) {
      final double startAngle = wheelRotation + (i * sectorAngle) - (pi / 2) - (sectorAngle / 2);
      final int number = _RouletteGameScreenState.rouletteNumbers[i];
      
      final double midAngle = startAngle + sectorAngle / 2;
      final Offset p1 = Offset(
        centerOffset.dx + cos(midAngle) * numRingInner,
        centerOffset.dy + sin(midAngle) * numRingInner,
      );
      final Offset p2 = Offset(
        centerOffset.dx + cos(midAngle) * numRingOuter,
        centerOffset.dy + sin(midAngle) * numRingOuter,
      );

      final sectorPaint = Paint()..style = PaintingStyle.fill;
      if (number == 0) {
        sectorPaint.shader = ui.Gradient.linear(
          p1, p2,
          [const Color(0xFF38AD55), const Color(0xFF08602E)],
        );
      } else if (_isRedNumber(number)) {
        sectorPaint.shader = ui.Gradient.linear(
          p1, p2,
          [const Color(0xFFED4A47), const Color(0xFF9E161B)],
        );
      } else {
        sectorPaint.shader = ui.Gradient.linear(
          p1, p2,
          [const Color(0xFF34363C), const Color(0xFF101216)],
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: centerOffset, radius: numRingOuter),
        startAngle,
        sectorAngle,
        true,
        sectorPaint,
      );

      // Draw Gold divider lines
      final double spokeX = centerOffset.dx + cos(startAngle + sectorAngle / 2) * numRingOuter;
      final double spokeY = centerOffset.dy + sin(startAngle + sectorAngle / 2) * numRingOuter;
      final double spokeInnerX = centerOffset.dx + cos(startAngle + sectorAngle / 2) * numRingInner;
      final double spokeInnerY = centerOffset.dy + sin(startAngle + sectorAngle / 2) * numRingInner;
      
      canvas.drawLine(
        Offset(spokeInnerX, spokeInnerY),
        Offset(spokeX, spokeY),
        dividerPaint,
      );
    }

    // Draw number labels inside sectors
    for (int i = 0; i < 37; i++) {
      final double angle = wheelRotation + (i * sectorAngle) - (pi / 2);
      final int number = _RouletteGameScreenState.rouletteNumbers[i];
      
      canvas.save();
      canvas.translate(centerOffset.dx, centerOffset.dy);
      canvas.rotate(angle);
      
      // Paint text vertically oriented inside sector slice
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$number',
          style: const TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position centered inside the number ring
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -(numRingInner + numRingOuter) / 2 - textPainter.height / 2));
      canvas.restore();
    }

    // 4. Inner metallic bowl center
    final double bowlRadius = numRingInner - (side * 0.025);
    final bowlPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4B4F5A),
          const Color(0xFF262932),
          const Color(0xFF0C0E13),
        ],
        stops: const [0.0, 0.42, 1.0],
        center: const Alignment(-0.2, -0.24),
      ).createShader(Rect.fromCircle(center: centerOffset, radius: bowlRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, bowlRadius, bowlPaint);

    final bowlEdgePaint = Paint()
      ..color = const Color(0xFFD4A43D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.006;
    canvas.drawCircle(centerOffset, bowlRadius, bowlEdgePaint);

    // 5. Draw opposite rotating curved bands inside the bowl
    canvas.save();
    canvas.translate(centerOffset.dx, centerOffset.dy);
    final double rotB = -wheelRotation * 1.5;
    canvas.rotate(rotB);
    
    for (int i = 0; i < 8; i++) {
      final double a = i * pi / 4;
      final bandPaint = Paint()
        ..color = (i % 2 == 0)
            ? const Color(0x33DEA341) // rgba(222,171,65,.20)
            : const Color(0x0FFFFFFF) // rgba(255,255,255,.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.028;
      
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: bowlRadius * 0.75),
        a + 0.08,
        (pi / 4) - 0.16,
        false,
        bandPaint,
      );
    }
    canvas.restore();

    // 6. Central spindle base
    final double hRadius = bowlRadius * 0.19;
    final hubPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF0A1),
          const Color(0xFFF0BE4C),
          const Color(0xFFB5761D),
          const Color(0xFF4D2B07),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: centerOffset, radius: hRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, hRadius, hubPaint);

    final hubEdgePaint = Paint()
      ..color = const Color(0xFFFFE08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.005;
    canvas.drawCircle(centerOffset, hRadius, hubEdgePaint);

    // 7. Rotating handles (twist arms)
    canvas.save();
    canvas.translate(centerOffset.dx, centerOffset.dy);
    canvas.rotate(-rotB * 1.8);
    
    final spokePaint = Paint()
      ..color = const Color(0xFFDCA439)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.008
      ..strokeCap = StrokeCap.round;
      
    final knobPaint = Paint()
      ..color = const Color(0xFFF3C45C)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 4; i++) {
      final double a = i * pi / 2;
      final double x1 = cos(a) * (hRadius * 0.35);
      final double y1 = sin(a) * (hRadius * 0.35);
      final double x2 = cos(a) * (hRadius * 1.65);
      final double y2 = sin(a) * (hRadius * 1.65);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), spokePaint);
      canvas.drawCircle(Offset(x2, y2), side * 0.012, knobPaint);
    }
    canvas.restore();

    // 8. Draw Ball!
    final int winningIndex = _RouletteGameScreenState.rouletteNumbers.indexOf(winningNumber);
    final double winningAngle = (winningIndex * sectorAngle) - (pi / 2);

    double ballAngle;
    double ballDist;

    // Outer track radius where ball spins freely
    final double outerTrackR = radius * 0.83;
    // Pocket center radius where ball settles
    final double pocketR = (numRingInner + numRingOuter) / 2;

    // Total ball spin: spins opposite direction to wheel, many full rotations
    final double totalBallSpin = -12.0 * pi;

    if (progress < 0.6) {
      // Phase 1: Ball spinning fast on outer track
      final double ballT = progress / 0.6;
      // Ease out the ball rotation
      final double ballEase = 1.0 - pow(1.0 - ballT, 3).toDouble();
      ballAngle = totalBallSpin * ballEase;
      ballDist = outerTrackR;
    } else {
      // Phase 2: Ball drops inward into the winning pocket
      final double dropP = (progress - 0.6) / 0.4;
      // Smooth Hermite ease for the drop
      final double dropEase = dropP * dropP * (3.0 - 2.0 * dropP);

      // Interpolate radius from outer track to pocket center
      ballDist = outerTrackR + (pocketR - outerTrackR) * dropEase;

      // Ball angle at start of drop phase
      final double ballAngleAtDrop = totalBallSpin * (1.0 - pow(1.0 - 1.0, 3).toDouble());
      // Continue some rotation during drop but slow down
      final double extraSpin = totalBallSpin * (1.0 - pow(1.0 - (0.6 + dropP * 0.4) / 0.6.clamp(0.0, 1.0), 3).toDouble());

      // Target angle: the winning pocket center, aligned to wheel rotation
      final double targetAngle = wheelRotation + winningAngle;
      // Current free-spinning angle
      final double freeAngle = totalBallSpin * (1.0 - pow(1.0 - progress, 3).toDouble());

      // Smoothly blend from free spinning towards locked-in pocket
      ballAngle = freeAngle + (targetAngle - freeAngle) * dropEase;

      // Add subtle bounce oscillation as ball settles into pocket
      if (dropP > 0.3) {
        final double bounceP = (dropP - 0.3) / 0.7;
        ballDist += cos(bounceP * 3.0 * pi) * (outerTrackR - pocketR) * 0.08 * (1.0 - bounceP);
      }
    }

    final double bx = centerOffset.dx + ballDist * cos(ballAngle);
    final double by = centerOffset.dy + ballDist * sin(ballAngle);

    // Ball shadow
    canvas.drawCircle(
      Offset(bx + 1.0, by + 1.0),
      side * 0.012,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Ball gradient
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFEEEEEE),
          const Color(0xFF999999),
        ],
        stops: const [0.0, 0.55, 1.0],
        center: const Alignment(-0.35, -0.35),
      ).createShader(Rect.fromCircle(center: Offset(bx, by), radius: side * 0.014))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bx, by), side * 0.014, ballPaint);

    // 9. Draw Pointer!
    final pointerPath = Path()
      ..moveTo(centerOffset.dx, centerOffset.dy - radius - side * 0.015)
      ..lineTo(centerOffset.dx - side * 0.018, centerOffset.dy - radius + side * 0.02)
      ..lineTo(centerOffset.dx + side * 0.018, centerOffset.dy - radius + side * 0.02)
      ..close();
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0xFFF3C64F)
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
