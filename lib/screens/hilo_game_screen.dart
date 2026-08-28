import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
    return (suit == 'Hearts' || suit == 'Diamonds') ? const Color(0xFFE53935) : const Color(0xFF1A1D20);
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

class TrianglePainter extends CustomPainter {
  final bool isUp;
  final Color strokeColor;
  final double strokeWidth;
  final double cornerRadius;

  TrianglePainter({
    required this.isUp,
    required this.strokeColor,
    this.strokeWidth = 3.5,
    this.cornerRadius = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;

    final Offset p1, p2, p3;
    if (isUp) {
      p1 = Offset(w / 2, strokeWidth + r * 0.4);
      p2 = Offset(w - strokeWidth - r * 0.4, h - strokeWidth - r * 0.4);
      p3 = Offset(strokeWidth + r * 0.4, h - strokeWidth - r * 0.4);
    } else {
      p1 = Offset(strokeWidth + r * 0.4, strokeWidth + r * 0.4);
      p2 = Offset(w - strokeWidth - r * 0.4, strokeWidth + r * 0.4);
      p3 = Offset(w / 2, h - strokeWidth - r * 0.4);
    }

    final path = Path();
    final pts = [p1, p2, p3];
    for (int i = 0; i < 3; i++) {
      final current = pts[i];
      final prev = pts[(i + 2) % 3];
      final next = pts[(i + 1) % 3];

      final vPrev = (prev - current);
      final vPrevNorm = vPrev / vPrev.distance;
      final vNext = (next - current);
      final vNextNorm = vNext / vNext.distance;

      final pStart = current + vPrevNorm * r;
      final pEnd = current + vNextNorm * r;

      if (i == 0) {
        path.moveTo(pStart.dx, pStart.dy);
      } else {
        path.lineTo(pStart.dx, pStart.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, pEnd.dx, pEnd.dy);
    }
    path.close();

    // 1. Fill gradient (matching photos 3 & 4)
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        strokeColor.withValues(alpha: 0.35),
        strokeColor.withValues(alpha: 0.08),
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Crisp stroke border
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CardHistoryItem {
  final PlayingCard card;
  final String label;

  _CardHistoryItem({required this.card, required this.label});
}

class _HiLoGameScreenState extends State<HiLoGameScreen> {
  final _betController = TextEditingController(text: '10');
  
  bool _isPlaying = false;
  bool _isAutoMode = false;
  
  PlayingCard _currentCard = PlayingCard(rank: 13, suit: 'Clubs'); // Start with King of Clubs
  double _currentMultiplier = 1.0;
  int _correctGuesses = 0;
  
  final List<double> _history = [2.24, 3.64, 0.00, 1.81];
  final List<_CardHistoryItem> _cardSequenceHistory = [];
  final ScrollController _historyScrollController = ScrollController();
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
    _historyScrollController.dispose();
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
        _cardSequenceHistory.clear();
        _cardSequenceHistory.add(_CardHistoryItem(card: _currentCard, label: 'Start Card'));
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
      _cardSequenceHistory.clear();
      _cardSequenceHistory.add(_CardHistoryItem(card: _currentCard, label: 'Start Card'));
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
        _cardSequenceHistory.add(_CardHistoryItem(card: nextCard, label: '${_currentMultiplier.toStringAsFixed(2)}x'));
        if (_cardSequenceHistory.length > 5) {
          _cardSequenceHistory.removeAt(0);
        }
        _history.add(stepMultiplier);
        if (_history.length > 6) {
          _history.removeAt(0);
        }
      } else {
        // Incorrect! Game Over.
        _isPlaying = false;
        _currentMultiplier = 1.0;
        _correctGuesses = 0;
        _cardSequenceHistory.add(_CardHistoryItem(card: nextCard, label: '0.00x'));
        if (_cardSequenceHistory.length > 5) {
          _cardSequenceHistory.removeAt(0);
        }

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Image.asset(
                        'assets/logos/hilo_logo.png',
                        height: 26.0,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.style, color: Color(0xFF00E5FF), size: 24.0),
                      ),
                    ),
                    const SizedBox(width: 8.0),
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
                          SingleChildScrollView(
                            child: _buildBetControls(bet, isLandscape: true),
                          ),
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
      child: SingleChildScrollView(
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
                    ? const Color(0xFFFFC107) // Gold Amber Cashout matching screenshot 2
                    : const Color(0xFF00C853), // Green Bet
                borderRadius: BorderRadius.circular(6.0),
                boxShadow: [
                  BoxShadow(
                    color: (_isPlaying ? const Color(0xFFFFC107) : const Color(0xFF00C853)).withValues(alpha: 0.3),
                    blurRadius: 6.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _isPlaying 
                    ? 'Cash out  ₹${(bet * _currentMultiplier).toStringAsFixed(2)}' 
                    : 'Bet',
                style: TextStyle(
                  color: _isPlaying ? const Color(0xFF1E2024) : Colors.white,
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

  Widget _buildCardSequenceHistoryStrip() {
    if (_cardSequenceHistory.isEmpty) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_historyScrollController.hasClients) {
        _historyScrollController.animateTo(
          _historyScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    return SizedBox(
      height: 70.0,
      child: ListView.builder(
        controller: _historyScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _cardSequenceHistory.length,
        itemBuilder: (context, index) {
          final item = _cardSequenceHistory[index];
          final bool isLoss = item.label == '0.00x';
          final bool isStart = item.label == 'Start Card';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCardWidget(card: item.card, width: 36.0, height: 50.0),
                const SizedBox(height: 3.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isLoss
                        ? const Color(0xFF333742)
                        : (isStart ? const Color(0xFF00C853) : const Color(0xFF00E676)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isLoss ? Colors.white70 : Colors.black,
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHiLoPlayfield(double bet) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                // 1. History badges (top)
                Row(
                  children: [
                    ..._history.map((val) => Container(
                          margin: const EdgeInsets.only(right: 6.0),
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: val > 1.0 ? const Color(0xFF00C853) : const Color(0xFF2C2F36),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            '${val.toStringAsFixed(2)}x',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
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
                const Spacer(),

                // 2. Playfield center card and triangle buttons (matching screenshot 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // HI Button (Up Triangle)
                    _buildHiLoTriangleButton(isUp: true, label: 'HI', sublabel: 'Higher Or Same', onTap: () => _makeGuess(true)),
                    const SizedBox(width: 20.0),

                    // Card display with inner skip
                    Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        _buildCardWidget(width: 95.0, height: 138.0),
                        Positioned(
                          bottom: -12.0,
                          child: _buildCardSkipOverlayButton(),
                        ),
                      ],
                    ),

                    const SizedBox(width: 20.0),
                    // LO Button (Down Triangle)
                    _buildHiLoTriangleButton(isUp: false, label: 'LO', sublabel: 'Lower Or Same', onTap: () => _makeGuess(false)),
                  ],
                ),

                const Spacer(),

                // 3. Profit Stats row (matching screenshot 2)
                Row(
                  children: [
                    _buildProfitStatsBox(
                      title: 'Profit Higher (${_multHI.toStringAsFixed(2)}x)',
                      value: bet * (_multHI - 1.0),
                      icon: Icons.arrow_upward,
                      iconColor: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 8.0),
                    _buildProfitStatsBox(
                      title: 'Total Profit (${_currentMultiplier.toStringAsFixed(2)}x)',
                      value: bet * (_currentMultiplier - 1.0),
                      icon: Icons.monetization_on,
                      iconColor: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 8.0),
                    _buildProfitStatsBox(
                      title: 'Profit Lower (${_multLO.toStringAsFixed(2)}x)',
                      value: bet * (_multLO - 1.0),
                      icon: Icons.arrow_downward,
                      iconColor: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),

                // 4. Card Sequence History Strip (matching screenshot 2)
                _buildCardSequenceHistoryStrip(),
              ],
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

  Widget _buildHiLoTriangleButton({
    required bool isUp,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    final Color color = isUp ? const Color(0xFFFFD700) : const Color(0xFF00E5FF);
    final String percentText = isUp
        ? '${(_probHI * 100).toStringAsFixed(2)}%'
        : '${(_probLO * 100).toStringAsFixed(2)}%';

    // Triangle visual centroid alignment offset:
    // UP triangle (base at bottom) -> Centroid is lower -> Alignment(0.0, 0.25)
    // DOWN triangle (base at top) -> Centroid is higher -> Alignment(0.0, -0.25)
    final Alignment textAlignment = isUp ? const Alignment(0.0, 0.25) : const Alignment(0.0, -0.25);

    return InkWell(
      onTap: _isPlaying ? onTap : null,
      borderRadius: BorderRadius.circular(16.0),
      child: SizedBox(
        width: 95.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Label/Percent
            Text(
              isUp ? percentText : sublabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5.0),

            // Triangle shape (+10% size) with visual centroid text alignment
            CustomPaint(
              painter: TrianglePainter(
                isUp: isUp,
                strokeColor: _isPlaying ? color : const Color(0xFF757575),
                strokeWidth: 3.8,
                cornerRadius: 11.0,
              ),
              child: Container(
                width: 90.0,
                height: 75.0,
                alignment: textAlignment, // Perfectly centered inside triangle shape!
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5.0),

            // Bottom Label/Percent
            Text(
              isUp ? sublabel : percentText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWidget({PlayingCard? card, double width = 95.0, double height = 138.0}) {
    final targetCard = card ?? _currentCard;
    final bool isMini = width < 50.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Clean white card face matching screenshot 2
        borderRadius: BorderRadius.circular(isMini ? 4.0 : 10.0),
        border: Border.all(color: const Color(0xFFD0D5DD), width: isMini ? 1.0 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: isMini ? 2.0 : 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Large Suit Icon in card center
          Center(
            child: _buildSuitIcon(targetCard.suit, isMini ? 16.0 : 34.0, targetCard.color),
          ),

          // 2. Top-left rank & suit indicator
          Positioned(
            top: isMini ? 2.0 : 5.0,
            left: isMini ? 2.0 : 5.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  targetCard.rankLabel,
                  style: TextStyle(
                    color: targetCard.color,
                    fontSize: isMini ? 11.0 : 18.0,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                if (!isMini) ...[
                  const SizedBox(height: 1.0),
                  _buildSuitIcon(targetCard.suit, 11.0, targetCard.color),
                ],
              ],
            ),
          ),

          // 3. Bottom-right rank & suit indicator (rotated 180 degrees)
          if (!isMini)
            Positioned(
              bottom: 5.0,
              right: 5.0,
              child: Transform.rotate(
                angle: math.pi,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      targetCard.rankLabel,
                      style: TextStyle(
                        color: targetCard.color,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 1.0),
                    _buildSuitIcon(targetCard.suit, 11.0, targetCard.color),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
