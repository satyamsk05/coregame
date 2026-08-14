import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/win_lose_toast.dart';
import '../widgets/win_overlay_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';

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
  final _betController = TextEditingController(text: '10');
  
  bool _isPlaying = false;
  bool _isAutoMode = false;
  bool _isHeadsSelected = true; // true = Heads (Gold), false = Tails (Silver)
  
  int _streak = 0;
  bool _isFlipping = false;
  bool _lastOutcomeHeads = true; // Displays the coin face when not flipping
  
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _heightAnimation;
  
  final List<double> _history = [];
  final math.Random _random = math.Random();

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
    _outcomeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showOutcomeCard = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _betController.addListener(() => setState(() {}));
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 8 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuad),
    );

    _heightAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.6).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.6, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 50,
      ),
    ]).animate(_animationController);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishFlip();
      }
    });
  }

  @override
  void dispose() {
    _betController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Multiplier math: 1.96^S (where S is streak)
  double _getStreakMultiplier(int streak) {
    if (streak == 0) return 1.0;
    return double.parse(math.pow(1.96, streak).toStringAsFixed(2));
  }

  double get _currentMultiplier => _getStreakMultiplier(_streak);
  double get _nextMultiplier => _getStreakMultiplier(_streak + 1);

  void _startGame() {
    if (_isFlipping) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;

    if (!isDemoMode && bet > widget.balance) {
      _showDialog('INSUFFICIENT BALANCE', 'You do not have enough balance to place this bet.');
      return;
    }

    if (!isDemoMode && !_isPlaying) {
      // Deduct bet amount on first flip of the round
      widget.onBalanceChanged(widget.balance - bet);
    }

    _triggerFlip();
  }

  void _triggerFlip() {
    setState(() {
      _isFlipping = true;
      _animationController.forward(from: 0.0);
    });
  }

  void _finishFlip() {
    // 50% probability outcome
    final bool flippedHeads = _random.nextBool();
    final bool isWin = flippedHeads == _isHeadsSelected;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;

    setState(() {
      _isFlipping = false;
      _lastOutcomeHeads = flippedHeads;

      if (isWin) {
        _streak++;
        _isPlaying = true;
        _history.add(1.96);
        if (_history.length > 5) {
          _history.removeAt(0);
        }
        
        // Auto cashout if streak reaches 10 to prevent infinite payout issues
        if (_streak >= 10) {
          _cashOut();
        }
      } else {
        // Lose round
        _isPlaying = false;
        _streak = 0;
        _history.add(0.00);
        if (_history.length > 5) {
          _history.removeAt(0);
        }

        _triggerOutcomeOverlay(0.0, 0.0, false);
      }
    });
  }

  void _cashOut() {
    if (!_isPlaying || _streak == 0) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;
    final double winAmount = bet * _currentMultiplier;

    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance + winAmount);
    }

    _triggerOutcomeOverlay(_currentMultiplier, winAmount, true);

    setState(() {
      _isPlaying = false;
      _streak = 0;
    });
  }

  void _showStatusMessage({required String title, required String message, required bool isWin}) {
    // Toast disabled to prevent duplicate overlay over WinOverlayCard
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        title: Text(
          title,
          style: GoogleFonts.pressStart2p(
            textStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 12.0),
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 14.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final double bet = double.tryParse(_betController.text) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      body: AnimatedGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isFlipping ? null : widget.onBackPressed,
                    ),
                    Text(
                      'COIN FLIP',
                      style: GoogleFonts.alfaSlabOne(
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16.0, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    // Balance Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2024),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFF37474F), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16.0),
                          const SizedBox(width: 6.0),
                          Text(
                            '₹${widget.balance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Split Panel
              Expanded(
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Panel: Bet Controls
                          _buildBetControls(bet, isLandscape: true),
                          const SizedBox(width: 12.0),
                          // Right Panel: Coin Flip Playfield
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                              child: _buildCoinPlayfield(),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Top Panel: Playfield
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildCoinPlayfield(),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          // Bottom Panel: Controls
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildBetControls(bet, isLandscape: false),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBetControls(double bet, {required bool isLandscape}) {
    return Container(
      width: isLandscape ? 280.0 : null,
      margin: isLandscape ? const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 12.0) : null,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bet Amount Label
          Row(
            children: [
              const Text(
                'Amount',
                style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11.0),
              ),
              const SizedBox(width: 4.0),
              Icon(Icons.info_outline, color: Colors.grey[400], size: 13.0),
            ],
          ),
          const SizedBox(height: 6.0),

          // Amount Text Input Box
          Container(
            height: 38.0,
            decoration: BoxDecoration(
              color: const Color(0xFF181A1F),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
            ),
            child: Row(
              children: [
                // Rupees gold badge
                Container(
                  margin: const EdgeInsets.only(left: 6.0, right: 8.0),
                  width: 20.0,
                  height: 20.0,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '₹',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                ),
                // Text input
                Expanded(
                  child: TextFormField(
                    controller: _betController,
                    enabled: !_isFlipping,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                    ),
                  ),
                ),
                // Inline multiplier actions
                Row(
                  children: [
                    _buildBetActionTextButton('-', () {
                      if (_isFlipping) return;
                      final double current = double.tryParse(_betController.text) ?? 0.0;
                      final double next = (current - 10.0).clamp(0.0, widget.balance);
                      _betController.text = next.toStringAsFixed(0);
                    }),
                    _buildBetActionTextButton('+', () {
                      if (_isFlipping) return;
                      final double current = double.tryParse(_betController.text) ?? 0.0;
                      final double next = (current + 10.0).clamp(0.0, widget.balance);
                      _betController.text = next.toStringAsFixed(0);
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),

          // Flat Quick Bet buttons in 2x2 grid
          Column(
            children: [
              Row(
                children: [
                  _buildFlatQuickBetButton('10', () {
                    if (_isFlipping) return;
                    _betController.text = '10';
                  }),
                  _buildFlatQuickBetButton('100', () {
                    if (_isFlipping) return;
                    _betController.text = '100';
                  }),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  _buildFlatQuickBetButton('500', () {
                    if (_isFlipping) return;
                    _betController.text = '500';
                  }),
                  _buildFlatQuickBetButton('1000', () {
                    if (_isFlipping) return;
                    _betController.text = '1000';
                  }),
                ],
              ),
            ],
          ),
          
          if (isLandscape) const Spacer(),
          if (!isLandscape) const SizedBox(height: 12.0),

          // Heads / Tails Selection Cards (Choice Selection)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () {
                      if (_isFlipping) return;
                      setState(() => _isHeadsSelected = true);
                      if (_isPlaying) {
                        _startGame(); // Directly trigger flip in active game
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.5, horizontal: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F36),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: _isHeadsSelected ? const Color(0xFFFFD700) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/coinflip/Figure.png',
                            width: 19.0,
                            height: 19.0,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle, color: Color(0xFFFFD700), size: 19.0),
                          ),
                          const SizedBox(width: 6.0),
                          const Text(
                            'Bet Heads',
                            style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: InkWell(
                    onTap: () {
                      if (_isFlipping) return;
                      setState(() => _isHeadsSelected = false);
                      if (_isPlaying) {
                        _startGame(); // Directly trigger flip in active game
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.5, horizontal: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F36),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: !_isHeadsSelected ? const Color(0xFFECEFF1) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/coinflip/Container.png',
                            width: 19.0,
                            height: 19.0,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle, color: Color(0xFFECEFF1), size: 19.0),
                          ),
                          const SizedBox(width: 6.0),
                          const Text(
                            'Bet Tails',
                            style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12.0),

          // Play Bet / Cash Out Button
          GestureDetector(
            onTap: () {
              if (_isFlipping) return;
              if (_isPlaying) {
                _cashOut();
              } else {
                _startGame();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isPlaying
                    ? const Color(0xFF311B92) // Purple Cashout
                    : const Color(0xFF00C853), // Green Bet
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: (_isPlaying ? const Color(0xFF311B92) : const Color(0xFF00C853)).withOpacity(0.3),
                    blurRadius: 6.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _isPlaying 
                    ? 'Cash Out (₹${(bet * _currentMultiplier).toStringAsFixed(2)})' 
                    : 'Bet',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // Demo Mode notice capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF181A1F),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFF2C2F36), width: 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 14.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Betting with 0 will enter demo mode.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBetActionTextButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32.0,
        height: 38.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.0)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBetActionIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32.0,
        height: 38.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.0)),
        ),
        child: Icon(icon, color: Colors.white, size: 16.0),
      ),
    );
  }

  Widget _buildFlatQuickBetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2E3138),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinPlayfield() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 2.0),
        image: const DecorationImage(
          image: AssetImage('assets/coinflip/bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // 1. History badges (top)
          Positioned(
            top: 10.0,
            left: 12.0,
            right: 12.0,
            child: Row(
              children: [
                if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181A1F),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: const Text(
                      'No Spins',
                      style: TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ..._history.map((val) => Container(
                      margin: const EdgeInsets.only(right: 6.0),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: val > 1.0 ? const Color(0xFF00C853) : const Color(0xFFFF1744),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        '${val.toStringAsFixed(2)}x',
                        style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                      ),
                    )),
                const Spacer(),
                if (_isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'Payout: ${_currentMultiplier.toStringAsFixed(2)}x',
                      style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Playfield center cards and 3D coin
          Positioned(
            top: 45.0,
            bottom: 12.0,
            left: 12.0,
            right: 12.0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Series Card (Left)
                  _buildStatsDisplayCard(
                    title: 'Series',
                    value: '$_streak',
                  ),
                  const SizedBox(width: 20.0),

                  // Center 3D Flipping Coin
                  _buildAnimatedCoinWidget(),

                  const SizedBox(width: 20.0),
                  // Multiply Card (Right)
                  _buildStatsDisplayCard(
                    title: 'Multiply',
                    value: 'x${_currentMultiplier.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),

          // Win/Lose Overlay Card centered in playfield
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
    );
  }

  Widget _buildStatsDisplayCard({required String title, required String value}) {
    return Container(
      width: 75.0,
      height: 120.0,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F36).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCoinWidget() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double rotationVal = _rotationAnimation.value;
        final double scaleVal = _heightAnimation.value;

        // 3D perspective Y-axis rotation
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0018) // perspective factor
          ..rotateY(rotationVal);

        final bool isHeadsShowing = math.cos(rotationVal) >= 0.0;
        final bool showHeadsFace = _isFlipping ? isHeadsShowing : _lastOutcomeHeads;

        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scaleVal,
            child: Container(
              width: 120.0,
              height: 120.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12.0 * scaleVal,
                    offset: Offset(0, 8 * scaleVal),
                  ),
                ],
              ),
              child: Image.asset(
                showHeadsFace ? 'assets/coinflip/Figure.png' : 'assets/coinflip/Container.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback vector drawing if assets fails to load
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: showHeadsFace 
                            ? [const Color(0xFFFFEE58), const Color(0xFFF57F17)]
                            : [const Color(0xFFECEFF1), const Color(0xFF78909C)],
                      ),
                      border: Border.all(
                        color: showHeadsFace ? const Color(0xFFFFD700) : const Color(0xFFB0BEC5),
                        width: 5.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        showHeadsFace ? Icons.star : Icons.circle,
                        color: Colors.white,
                        size: 40.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
