import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/win_lose_toast.dart';
import '../widgets/win_overlay_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';
import '../utils/sound_manager.dart';

class PlayingCard {
  final int rank; // 1 (Ace) to 13 (King)
  final String suit; // Hearts, Diamonds, Spades, Clubs

  PlayingCard({required this.rank, required this.suit});

  String get rankLabel {
    if (rank == 1) return 'A';
    if (rank == 11) return 'J';
    if (rank == 12) return 'Q';
    if (rank == 13) return 'K';
    return '$rank';
  }

  Color get color {
    return (suit == 'Hearts' || suit == 'Diamonds') ? const Color(0xFFFF1744) : Colors.white;
  }
}

class HiLoGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const HiLoGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<HiLoGameScreen> createState() => _HiLoGameScreenState();
}

class TriangleOutlinePainter extends CustomPainter {
  final bool isUp;
  final Color color;
  final double strokeWidth;

  TriangleOutlinePainter({required this.isUp, required this.color, this.strokeWidth = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isUp) {
      path.moveTo(size.width / 2, strokeWidth);
      path.lineTo(size.width - strokeWidth, size.height - strokeWidth);
      path.lineTo(strokeWidth, size.height - strokeWidth);
    } else {
      path.moveTo(strokeWidth, strokeWidth);
      path.lineTo(size.width - strokeWidth, strokeWidth);
      path.lineTo(size.width / 2, size.height - strokeWidth);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HiLoGameScreenState extends State<HiLoGameScreen> {
  final _betController = TextEditingController(text: '10');
  
  bool _isPlaying = false;
  bool _isAutoMode = false;
  
  PlayingCard _currentCard = PlayingCard(rank: 13, suit: 'Clubs'); // Start with King of Clubs
  double _currentMultiplier = 1.0;
  int _correctGuesses = 0;
  
  final List<double> _history = [];
  final List<String> _suits = ['Hearts', 'Diamonds', 'Spades', 'Clubs'];
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
    _outcomeTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showOutcomeCard = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _betController.addListener(() => setState(() {}));
    _drawRandomCard(initial: true);
  }

  @override
  void dispose() {
    _betController.dispose();
    super.dispose();
  }

  void _drawRandomCard({bool initial = false}) {
    setState(() {
      int rank = _random.nextInt(13) + 1;
      String suit = _suits[_random.nextInt(_suits.length)];
      _currentCard = PlayingCard(rank: rank, suit: suit);
      if (initial) {
        _currentMultiplier = 1.0;
        _correctGuesses = 0;
      }
    });
  }

  // Dynamic Probabilities & Multipliers based on current card rank
  double get _probHI => (14 - _currentCard.rank) / 13.0;
  double get _probLO => _currentCard.rank / 13.0;

  double get _multHI => double.parse((0.99 / _probHI).toStringAsFixed(2));
  double get _multLO => double.parse((0.99 / _probLO).toStringAsFixed(2));

  void _startGame() {
    if (_isPlaying) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;

    if (!isDemoMode && bet > widget.balance) {
      _showDialog('INSUFFICIENT BALANCE', 'You do not have enough balance to place this bet.');
      return;
    }

    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance - bet);
    }

    setState(() {
      _isPlaying = true;
      _currentMultiplier = 1.0;
      _correctGuesses = 0;
    });
    SoundManager.playCardPlace();
  }

  void _makeGuess(bool isHI) {
    if (!_isPlaying) return;

    SoundManager.playCardPlace();

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;

    // Draw next card
    int nextRank = _random.nextInt(13) + 1;
    String nextSuit = _suits[_random.nextInt(_suits.length)];
    final PlayingCard nextCard = PlayingCard(rank: nextRank, suit: nextSuit);

    bool isCorrect = false;
    double stepMultiplier = 1.0;

    if (isHI) {
      isCorrect = nextCard.rank >= _currentCard.rank;
      stepMultiplier = _multHI;
    } else {
      isCorrect = nextCard.rank <= _currentCard.rank;
      stepMultiplier = _multLO;
    }

    setState(() {
      _currentCard = nextCard;

      if (isCorrect) {
        // Correct prediction!
        _correctGuesses++;
        _currentMultiplier = double.parse((_currentMultiplier * stepMultiplier).toStringAsFixed(2));
        _history.add(stepMultiplier);
        if (_history.length > 4) {
          _history.removeAt(0);
        }
      } else {
        // Incorrect! Game Over.
        _isPlaying = false;
        _currentMultiplier = 1.0;
        _correctGuesses = 0;

        _triggerOutcomeOverlay(0.0, 0.0, false);
      }
    });
  }

  void _cashOut() {
    if (!_isPlaying || _correctGuesses == 0) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;
    final double winAmount = bet * _currentMultiplier;

    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance + winAmount);
    }

    _triggerOutcomeOverlay(_currentMultiplier, winAmount, true);

    setState(() {
      _isPlaying = false;
      _currentMultiplier = 1.0;
      _correctGuesses = 0;
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
                      onPressed: _isPlaying ? null : widget.onBackPressed,
                    ),
                    Text(
                      'HILO CARD PREDICTOR',
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
                          // Right Panel: HiLo Playfield
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                              child: _buildHiLoPlayfield(bet),
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
                              child: _buildHiLoPlayfield(bet),
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
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manual / Auto Tabs
          _buildTabBar(),
          const SizedBox(height: 12.0),

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
              borderRadius: BorderRadius.circular(4.0),
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
                    enabled: !_isPlaying,
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
                      if (_isPlaying) return;
                      final double current = double.tryParse(_betController.text) ?? 0.0;
                      final double next = (current - 10.0).clamp(0.0, widget.balance);
                      _betController.text = next.toStringAsFixed(0);
                    }),
                    _buildBetActionTextButton('+', () {
                      if (_isPlaying) return;
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
                    if (_isPlaying) return;
                    _betController.text = '10';
                  }),
                  _buildFlatQuickBetButton('100', () {
                    if (_isPlaying) return;
                    _betController.text = '100';
                  }),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  _buildFlatQuickBetButton('500', () {
                    if (_isPlaying) return;
                    _betController.text = '500';
                  }),
                  _buildFlatQuickBetButton('1000', () {
                    if (_isPlaying) return;
                    _betController.text = '1000';
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Predictions Buttons (HI / LO Selector in Left Panel)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => _makeGuess(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F36),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: _isPlaying ? Colors.yellow[600]! : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.yellow[600], size: 14.0),
                              const SizedBox(width: 4.0),
                              const Text(
                                'Higher Or Same',
                                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${(_probHI * 100).toStringAsFixed(2)}%',
                            style: TextStyle(color: Colors.yellow[600], fontSize: 9.0, fontWeight: FontWeight.bold),
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
                    onTap: () => _makeGuess(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F36),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: _isPlaying ? Colors.blue[400]! : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward, color: Colors.blue[400], size: 14.0),
                              const SizedBox(width: 4.0),
                              const Text(
                                'Lower Or Same',
                                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${(_probLO * 100).toStringAsFixed(2)}%',
                            style: TextStyle(color: Colors.blue[400], fontSize: 9.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Skip Card selector
          InkWell(
            onTap: () => _drawRandomCard(initial: !_isPlaying),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2E3138),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: const Color(0xFF424242), width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Skip Card',
                    style: TextStyle(color: Colors.grey[300], fontSize: 11.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(Icons.double_arrow, color: Colors.white, size: 12.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Play Bet / Cash Out Button
          GestureDetector(
            onTap: () {
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
                borderRadius: BorderRadius.circular(6.0),
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
              borderRadius: BorderRadius.circular(6.0),
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

  Widget _buildTabBar() {
    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAutoMode = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !_isAutoMode ? const Color(0xFF2E3138) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'Manual',
                  style: TextStyle(
                    color: !_isAutoMode ? Colors.white : Colors.grey[400],
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAutoMode = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isAutoMode ? const Color(0xFF2E3138) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'Auto',
                  style: TextStyle(
                    color: _isAutoMode ? Colors.white : Colors.grey[400],
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
              borderRadius: BorderRadius.circular(2.0),
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

  Widget _buildHiLoPlayfield(double bet) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 2.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;

          return Stack(
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
                          'No Payouts',
                          style: TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ..._history.map((val) => Container(
                          margin: const EdgeInsets.only(right: 6.0),
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: val > 1.0 ? const Color(0xFF00C853) : const Color(0xFF2C2F36),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            '${val.toStringAsFixed(2)}x',
                            style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                          ),
                        )),
                    const Spacer(),
                    // Current Multiplier
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

              // 2. Playfield center card and triangle buttons
              Positioned(
                top: 42.0,
                bottom: 86.0,
                left: 12.0,
                right: 12.0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // HI Button
                      _buildHiLoTriangleButton(isUp: true, label: 'HI', sublabel: 'Higher Or Same', onTap: () => _makeGuess(true)),
                      const SizedBox(width: 16.0),

                      // Card display with inner skip
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          _buildCardWidget(),
                          Positioned(
                            bottom: -15.0,
                            child: _buildCardSkipOverlayButton(),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16.0),
                      // LO Button
                      _buildHiLoTriangleButton(isUp: false, label: 'LO', sublabel: 'Lower Or Same', onTap: () => _makeGuess(false)),
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

              // 3. Profit Stats row at the bottom
              Positioned(
                bottom: 12.0,
                left: 12.0,
                right: 12.0,
                child: Row(
                  children: [
                    _buildProfitStatsBox(
                      title: 'Profit Higher',
                      value: bet * (_multHI - 1.0),
                      icon: Icons.arrow_upward,
                      iconColor: Colors.yellow[600]!,
                    ),
                    const SizedBox(width: 8.0),
                    _buildProfitStatsBox(
                      title: 'Total Profit',
                      value: bet * (_currentMultiplier - 1.0),
                      icon: Icons.monetization_on,
                      iconColor: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 8.0),
                    _buildProfitStatsBox(
                      title: 'Profit Lower',
                      value: bet * (_multLO - 1.0),
                      icon: Icons.arrow_downward,
                      iconColor: Colors.blue[400]!,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHiLoTriangleButton({
    required bool isUp,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    final Color color = isUp ? Colors.yellow[600]! : Colors.blue[400]!;

    return InkWell(
      onTap: _isPlaying ? onTap : null,
      borderRadius: BorderRadius.circular(16.0),
      child: CustomPaint(
        painter: TriangleOutlinePainter(isUp: isUp, color: _isPlaying ? color : Colors.grey[700]!),
        child: Container(
          width: 80.0,
          height: 80.0,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _isPlaying ? color : Colors.grey[600],
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isPlaying ? Colors.white70 : Colors.grey[600],
                  fontSize: 7.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWidget() {
    return Container(
      width: 95.0,
      height: 140.0,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252), // Coral red card face
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Diamond outline border inside card center
          Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
              ),
            ),
          ),

          // 2. Large Suit Icon in card center
          Center(
            child: _buildSuitIcon(_currentCard.suit, 24.0, _currentCard.color),
          ),

          // 3. Top-left rank & suit indicator
          Positioned(
            top: 6.0,
            left: 6.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentCard.rankLabel,
                  style: TextStyle(
                    color: _currentCard.color,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                _buildSuitIcon(_currentCard.suit, 8.0, _currentCard.color),
              ],
            ),
          ),

          // 4. Bottom-right rank & suit indicator (rotated)
          Positioned(
            bottom: 6.0,
            right: 6.0,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentCard.rankLabel,
                    style: TextStyle(
                      color: _currentCard.color,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  _buildSuitIcon(_currentCard.suit, 8.0, _currentCard.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkipOverlayButton() {
    return InkWell(
      onTap: () => _drawRandomCard(initial: !_isPlaying),
      child: Container(
        height: 20.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F36),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 2.0),
            Icon(Icons.play_arrow, color: Colors.white, size: 8.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSuitIcon(String suit, double size, Color color) {
    if (suit == 'Hearts') {
      return Icon(Icons.favorite, size: size, color: color);
    } else if (suit == 'Diamonds') {
      return Icon(Icons.diamond, size: size, color: color);
    } else if (suit == 'Spades') {
      return Icon(Icons.spa, size: size, color: color);
    } else {
      // Clubs: custom drawn Stack
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Stem
            Positioned(
              bottom: size * 0.05,
              child: Container(
                width: size * 0.16,
                height: size * 0.4,
                color: color,
              ),
            ),
            // Left circle
            Positioned(
              left: size * 0.1,
              top: size * 0.25,
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            // Right circle
            Positioned(
              right: size * 0.1,
              top: size * 0.25,
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            // Top circle
            Positioned(
              top: size * 0.05,
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfitStatsBox({
    required String title,
    required double value,
    required IconData icon,
    required Color iconColor,
  }) {
    final double displayValue = value < 0.0 ? 0.0 : value;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFF181A1F),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: const Color(0xFF2C2F36), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 8.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2.0),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 4.0),
                  width: 12.0,
                  height: 12.0,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '₹',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 7.5),
                  ),
                ),
                Expanded(
                  child: Text(
                    displayValue.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(icon, color: iconColor, size: 10.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
