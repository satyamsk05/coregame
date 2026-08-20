import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/bounceable.dart';
import '../../shared/widgets/win_overlay_card.dart';
import '../../shared/widgets/win_lose_toast.dart';
import '../../utils/sound_manager.dart';
import '../andar_bahar/widgets/player_widgets.dart';
import '../../shared/widgets/night_forest_background.dart';

class DoubleSlot {
  final int number;
  final String color; // 'red', 'green', 'black'
  DoubleSlot({required this.number, required this.color});
}

class DoubleGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final String nickname;
  final String avatarPath;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const DoubleGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.nickname,
    required this.avatarPath,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<DoubleGameScreen> createState() => _DoubleGameScreenState();
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 5.0; // soft corner radius

    path.moveTo(w * 0.5, r);
    
    // Corner B (top right)
    path.lineTo(w - r, h * 0.25 - r * 0.5);
    path.quadraticBezierTo(w, h * 0.25, w, h * 0.25 + r);
    
    // Corner C (bottom right)
    path.lineTo(w, h * 0.75 - r);
    path.quadraticBezierTo(w, h * 0.75, w - r, h * 0.75 + r * 0.5);
    
    // Corner D (bottom)
    path.lineTo(w * 0.5 + r, h - r * 0.5);
    path.quadraticBezierTo(w * 0.5, h, w * 0.5 - r, h - r * 0.5);
    
    // Corner E (bottom left)
    path.lineTo(r, h * 0.75 + r * 0.5);
    path.quadraticBezierTo(0, h * 0.75, 0, h * 0.75 - r);
    
    // Corner F (top left)
    path.lineTo(0, h * 0.25 + r);
    path.quadraticBezierTo(0, h * 0.25, r, h * 0.25 - r * 0.5);
    
    // Corner A (top)
    path.lineTo(w * 0.5 - r, r * 0.5);
    path.quadraticBezierTo(w * 0.5, 0, w * 0.5 + r, r * 0.5);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DoubleGameScreenState extends State<DoubleGameScreen> {
  final List<DoubleSlot> _slots = [
    DoubleSlot(number: 0, color: 'green'),
    DoubleSlot(number: 11, color: 'black'),
    DoubleSlot(number: 5, color: 'red'),
    DoubleSlot(number: 10, color: 'black'),
    DoubleSlot(number: 6, color: 'red'),
    DoubleSlot(number: 9, color: 'black'),
    DoubleSlot(number: 7, color: 'red'),
    DoubleSlot(number: 8, color: 'black'),
    DoubleSlot(number: 1, color: 'red'),
    DoubleSlot(number: 14, color: 'black'),
    DoubleSlot(number: 2, color: 'red'),
    DoubleSlot(number: 13, color: 'black'),
    DoubleSlot(number: 3, color: 'red'),
    DoubleSlot(number: 12, color: 'black'),
    DoubleSlot(number: 4, color: 'red'),
  ];

  late final ScrollController _scrollController;
  final TextEditingController _betController = TextEditingController(text: '10');

  // Game loop variables
  String _gamePhase = 'betting'; // 'betting' -> 'spinning' -> 'result'
  double _timerSeconds = 15.0;
  Timer? _gameTimer;
  Timer? _countdownTimer;

  // Betting states
  String? _selectedColor; // 'red', 'green', 'black'
  String? _placedBetColor;
  double _placedBetAmount = 0.0;

  // Spin result
  DoubleSlot? _winningSlot;
  final List<DoubleSlot> _previousRolls = [];

  // Flying chips and triggers for UserAvatarWidget
  int _triggerUserBet = 0;
  int _triggerUserWin = 0;
  double _winAmount = 0.0;

  // Animation layout sizes
  final double _itemWidth = 76.0;
  final double _itemMargin = 8.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Seed initial previous rolls history
    final rand = math.Random();
    for (int i = 0; i < 5; i++) {
      _previousRolls.add(_slots[rand.nextInt(_slots.length)]);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _resetScrollToCenter();
          _startBettingPhase();
        }
      });
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _betController.dispose();
    super.dispose();
  }

  double get _itemTotalWidth => _itemWidth + _itemMargin;

  void _resetScrollToCenter() {
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      // Start in the middle of repeated list
      final double startOffset = (3 * 15 * _itemTotalWidth) + (_itemTotalWidth / 2) - (viewportWidth / 2);
      _scrollController.jumpTo(startOffset);
    } else {
      // Retry in next frame if clients are not registered yet
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _scrollController.hasClients) {
          final double viewportWidth = _scrollController.position.viewportDimension;
          final double startOffset = (3 * 15 * _itemTotalWidth) + (_itemTotalWidth / 2) - (viewportWidth / 2);
          _scrollController.jumpTo(startOffset);
        }
      });
    }
  }

  void _startBettingPhase() {
    setState(() {
      _gamePhase = 'betting';
      _timerSeconds = 15.0;
      _placedBetColor = null;
      _placedBetAmount = 0.0;
    });

    _resetScrollToCenter();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0.1) {
            _timerSeconds -= 0.1;
          } else {
            _timerSeconds = 0.0;
            _countdownTimer?.cancel();
            _startSpinningPhase();
          }
        });
      }
    });
  }

  void _startSpinningPhase() {
    setState(() {
      _gamePhase = 'spinning';
    });

    // Select random winning slot
    final rand = math.Random();
    final winNumIndex = rand.nextInt(_slots.length);
    _winningSlot = _slots[winNumIndex];

    // Pick target repeated index around 12 to 14 periods deep
    final int targetPeriod = 12;
    final int targetIndex = targetPeriod * _slots.length + winNumIndex;

    // Calculate centering offset
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      // Land in center with a slight random offset for realism (+/- 20 pixels)
      final double randomOffset = (rand.nextDouble() * 40.0) - 20.0;
      final double targetOffset = (targetIndex * _itemTotalWidth) + (_itemTotalWidth / 2) - (viewportWidth / 2) + randomOffset;

      SoundManager.playClick(); // Play initial spin click

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 3800),
        curve: const Cubic(0.12, 0.8, 0.15, 1.0), // Realistic spin deceleration
      ).then((_) {
        if (mounted) {
          _showResultPhase();
        }
      });
    } else {
      _showResultPhase();
    }
  }

  void _showResultPhase() {
    setState(() {
      _gamePhase = 'result';
      if (_winningSlot != null) {
        _previousRolls.insert(0, _winningSlot!);
        if (_previousRolls.length > 8) {
          _previousRolls.removeLast();
        }
      }
    });

    // Calculate bet outcomes
    if (_placedBetColor != null && _winningSlot != null) {
      final String winningColor = _winningSlot!.color;
      final bool isWin = (_placedBetColor == winningColor);

      if (isWin) {
        final double multiplier = (winningColor == 'green') ? 14.0 : 2.0;
        final double winValue = _placedBetAmount * multiplier;
        widget.onBalanceChanged(widget.balance + winValue);

        setState(() {
          _winAmount = winValue;
          _triggerUserWin++;
        });

        // Trigger Overlay Card or Toast
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showWinLoseToast(
            context,
            isWin: true,
            title: 'YOU WON!',
            message: 'Won ₹${winValue.toStringAsFixed(2)}',
          );
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => Center(
              child: WinOverlayCard(
                multiplier: multiplier,
                winAmount: winValue,
                isWin: true,
              ),
            ),
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showWinLoseToast(
            context,
            isWin: false,
            title: 'YOU LOST!',
            message: 'Lost ₹${_placedBetAmount.toStringAsFixed(2)}',
          );
        });
      }
    }

    // Hold result for 3.8s then restart
    _gameTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        _startBettingPhase();
      }
    });
  }

  void _placeBet() {
    if (_selectedColor == null) {
      _showErrorDialog('Select Color', 'Please select a color to bet on!');
      return;
    }

    final double betVal = double.tryParse(_betController.text) ?? 0.0;
    if (betVal <= 0.0) {
      _showErrorDialog('Invalid Bet', 'Bet amount must be greater than 0.');
      return;
    }

    if (widget.balance < betVal) {
      _showErrorDialog('Insufficient Balance', 'You do not have enough balance to place this bet.');
      return;
    }

    SoundManager.playClick();
    widget.onBalanceChanged(widget.balance - betVal);

    setState(() {
      _placedBetAmount = betVal;
      _placedBetColor = _selectedColor;
      _triggerUserBet++;
    });
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        title: Text(
          title,
          style: GoogleFonts.pressStart2p(
            textStyle: const TextStyle(color: Colors.white, fontSize: 12.0),
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.grey, fontSize: 12.0),
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFF24EE89), fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(double w, double h) {
    return Row(
      children: [
        // Exit/Back Button
        GestureDetector(
          onTap: _gamePhase == 'spinning' ? null : widget.onBackPressed,
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
        const Spacer(),
        // DOUBLE Brand Name
        Text(
          'DOUBLE',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: Color(0xFF24EE89),
              fontWeight: FontWeight.w900,
              fontSize: 20.0,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const Spacer(),
        // Help/Details Button
        GestureDetector(
          onTap: () {
            SoundManager.playClick();
            _showGameDetailsDialog();
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.help_outline, color: Colors.white, size: 16.0),
          ),
        ),
      ],
    );
  }

  void _showGameDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
          child: Container(
            width: 320.0,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF23272C), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline, color: Color(0xFF24EE89), size: 18.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'Double Rules',
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          SoundManager.playClick();
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.close, color: Colors.grey, size: 18.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    '1. Select your target bet color: Red (pays 2x), Black (pays 2x), or Green (pays 14x).\n\n'
                    '2. Enter your bet amount using the suggested bet boxes or the +/- buttons.\n\n'
                    '3. Confirm your bet before the countdown timer reaches 0.0s.\n\n'
                    '4. The horizontal carousel spins and decelerates onto a winning color slot.\n\n'
                    '5. Correct predictions receive the multiplier payout directly added to the wallet balance!',
                    style: GoogleFonts.roboto(
                      textStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  GestureDetector(
                    onTap: () {
                      SoundManager.playClick();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF24EE89),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftPanel(double w, double h) {
    String headerText = "Game result will be displayed";
    if (_gamePhase == 'spinning') {
      headerText = "Rolling...";
    } else if (_gamePhase == 'result' && _winningSlot != null) {
      headerText = "${_winningSlot!.color.toUpperCase()} won!";
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161618).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF24272C), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: Text(
              headerText,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Spacer(),

          // Countdown section
          Center(
            child: Text(
              _gamePhase == 'betting'
                  ? "Rolling In ${_timerSeconds.toStringAsFixed(1)}s"
                  : (_winningSlot != null ? "Result: Slot ${_winningSlot!.number}" : "Result Details"),
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const Spacer(),

          // Horizontal Slider with vertical target line
          SizedBox(
            height: 100.0,
            child: Stack(
              children: [
                // Cards list viewport wrapper
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      color: const Color(0xFF0F1115),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const NeverScrollableScrollPhysics(), // Only programmatically scrolled
                        scrollDirection: Axis.horizontal,
                        itemCount: _slots.length * 30, // Large number for pseudo-infinite scroll
                        itemBuilder: (context, index) {
                          final slot = _slots[index % _slots.length];
                          final isGreen = slot.color == 'green';

                          Color cardBg = const Color(0xFF2B2D36);
                          Color hexColor = const Color(0xFF16181C);

                          if (slot.color == 'red') {
                            cardBg = const Color(0xFFFE4541);
                            hexColor = const Color(0xFF9E1F1D);
                          } else if (slot.color == 'green') {
                            cardBg = const Color(0xFF24EE89);
                          }

                          return Container(
                            width: _itemWidth,
                            margin: EdgeInsets.symmetric(horizontal: _itemMargin / 2, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.white10),
                            ),
                            alignment: Alignment.center,
                            child: isGreen
                                ? Container(
                                    width: 48.0,
                                    height: 48.0,
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      'assets/Double/Image (diamond).png',
                                      width: 38.0,
                                      height: 38.0,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Container(
                                    width: 48.0,
                                    height: 48.0,
                                    alignment: Alignment.center,
                                    child: ClipPath(
                                      clipper: HexagonClipper(),
                                      child: Container(
                                        color: hexColor,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${slot.number}',
                                          style: GoogleFonts.roboto(
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Center vertical solid white line indicator
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 3.0,
                    height: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Previous Rolls history list
          Row(
            children: [
              Text(
                'Previous Rolls',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(color: Colors.white54, fontSize: 10.0, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 28.0,
                width: 280.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: _previousRolls.length,
                  itemBuilder: (context, idx) {
                    final roll = _previousRolls[idx];
                    
                    Color cardBgColor = const Color(0xFF2B2D36);
                    Color hexColor = const Color(0xFF16181C);
                    bool isGreen = roll.color == 'green';

                    if (roll.color == 'red') {
                      cardBgColor = const Color(0xFFFE4541);
                      hexColor = const Color(0xFF9E1F1D);
                    } else if (roll.color == 'green') {
                      cardBgColor = const Color(0xFF24EE89);
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: Colors.white12, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: isGreen
                          ? Image.asset(
                              'assets/Double/Image (diamond).png',
                              width: 16.0,
                              height: 16.0,
                              fit: BoxFit.contain,
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(20.0, 20.0),
                                  painter: HexagonPainter(color: hexColor),
                                ),
                                Text(
                                  '${roll.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w900,
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
        ],
      ),
    );
  }

  Widget _buildRightPanel(double w, double h) {
    final bool isBetting = _gamePhase == 'betting';
    final bool hasActiveBet = _placedBetAmount > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161618).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF24272C), width: 1.5),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount section
          Row(
            children: [
              Text(
                'Amount',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(color: Colors.white70, fontSize: 11.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4.0),
              GestureDetector(
                onTap: () {
                  _showErrorDialog(
                    'Rules & Multipliers',
                    'Place a bet on Red (2x), Black (2x), or Green (14x).\nIf the slider halts on your chosen color, you win!',
                  );
                },
                child: const Icon(Icons.info_outline, color: Colors.grey, size: 12.0),
              ),
            ],
          ),
          const SizedBox(height: 6.0),

          // Amount Textbox & Action buttons
          Container(
            height: 42.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10.0),
                const Text('₹', style: TextStyle(color: Colors.white54, fontSize: 14.0, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6.0),
                Expanded(
                  child: TextField(
                    controller: _betController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    enabled: isBetting && !hasActiveBet,
                  ),
                ),
                // - Button
                GestureDetector(
                  onTap: (isBetting && !hasActiveBet)
                      ? () {
                          SoundManager.playClick();
                          double curVal = double.tryParse(_betController.text) ?? 0.0;
                          curVal = (curVal / 2).clamp(1.0, widget.balance);
                          _betController.text = curVal.toInt().toString();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    alignment: Alignment.center,
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: (isBetting && !hasActiveBet) ? Colors.white : Colors.white30,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Vertical divider
                Container(width: 1.0, height: 20.0, color: Colors.white12),
                // + Button
                GestureDetector(
                  onTap: (isBetting && !hasActiveBet)
                      ? () {
                          SoundManager.playClick();
                          double curVal = double.tryParse(_betController.text) ?? 0.0;
                          curVal = (curVal * 2).clamp(0.0, widget.balance);
                          _betController.text = curVal.toInt().toString();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    alignment: Alignment.center,
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: (isBetting && !hasActiveBet) ? Colors.white : Colors.white30,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          // Suggested bet amounts: 10, 100, 500, 1000
          Row(
            children: [10, 100, 500, 1000].map((suggestedAmount) {
              final isEnabled = isBetting && !hasActiveBet;
              return Expanded(
                child: GestureDetector(
                  onTap: isEnabled
                      ? () {
                          SoundManager.playClick();
                          _betController.text = suggestedAmount.toString();
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    height: 28.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      '$suggestedAmount',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: isEnabled ? Colors.white70 : Colors.white30,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),

          // Select Color Header
          Text(
            'Select Color',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(color: Colors.white70, fontSize: 11.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8.0),

          // Color selector cards (Red, Green, Black)
          Row(
            children: [
              // Red
              Expanded(
                child: GestureDetector(
                  onTap: (isBetting && !hasActiveBet) ? () => setState(() => _selectedColor = 'red') : null,
                  child: Container(
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: _selectedColor == 'red' ? const Color(0xFFE53935) : Colors.white12,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12.0,
                          height: 12.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text('X2', style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Green
              Expanded(
                child: GestureDetector(
                  onTap: (isBetting && !hasActiveBet) ? () => setState(() => _selectedColor = 'green') : null,
                  child: Container(
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: _selectedColor == 'green' ? const Color(0xFF00C853) : Colors.white12,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12.0,
                          height: 12.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text('X14', style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Black/Grey
              Expanded(
                child: GestureDetector(
                  onTap: (isBetting && !hasActiveBet) ? () => setState(() => _selectedColor = 'black') : null,
                  child: Container(
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: _selectedColor == 'black' ? Colors.white60 : Colors.white12,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12.0,
                          height: 12.0,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text('X2', style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // User Profile Row (Avatar / Name), Balance Capsule & Place Bet Button in one row!
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Unified Player Info Box
              Container(
                height: 72.0,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1115),
                  borderRadius: BorderRadius.circular(13.0),
                  border: Border.all(color: Colors.white10, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatarWidget(
                      balance: widget.balance,
                      avatarPath: widget.avatarPath,
                      nickname: widget.nickname,
                      betTrigger: _triggerUserBet,
                      winAmount: _winAmount,
                      winTrigger: _triggerUserWin,
                      showBalance: false,
                      showNickname: false,
                    ),
                    const SizedBox(width: 8.0),
                    // Nickname and Amount column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nickname (bda)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4.0),
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0xCC171B21),
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            widget.nickname,
                            style: GoogleFonts.roboto(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Wallet Balance display (Gold text directly under nickname)
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Text(
                            '₹${widget.balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 13.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              // Place Bet Button on the same row, taking remaining space!
              Expanded(
                child: Bounceable(
                  onTap: (isBetting && !hasActiveBet) ? _placeBet : null,
                  child: Opacity(
                    opacity: (isBetting && !hasActiveBet) ? 1.0 : 0.5,
                    child: Container(
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF24EE89),
                        borderRadius: BorderRadius.circular(13.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF24EE89).withOpacity(0.3),
                            blurRadius: 6.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hasActiveBet ? 'Bet Placed' : 'Bet',
                        style: const TextStyle(color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightForestBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double h = constraints.maxHeight;
                final double w = constraints.maxWidth;

                return Column(
                  children: [
                    // Header row
                    _buildTopHeader(w, h),
                    const SizedBox(height: 12.0),

                    // Grid content
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Panel (Betting console)
                          Expanded(
                            flex: 4,
                            child: _buildRightPanel(w, h),
                          ),
                          const SizedBox(width: 16.0),

                          // Right Panel (Slider / Game details)
                          Expanded(
                            flex: 5,
                            child: _buildLeftPanel(w, h),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 3.0; // soft corner radius for history items

    final points = [
      Offset(w * 0.5, 0.0),
      Offset(w, h * 0.25),
      Offset(w, h * 0.75),
      Offset(w * 0.5, h),
      Offset(0.0, h * 0.75),
      Offset(0.0, h * 0.25),
    ];

    for (int i = 0; i < 6; i++) {
      final pCurr = points[i];
      final pPrev = points[(i - 1 + 6) % 6];
      final pNext = points[(i + 1) % 6];
      
      final vPrev = pPrev - pCurr;
      final dPrev = vPrev.distance;
      final uPrev = vPrev / dPrev;
      
      final vNext = pNext - pCurr;
      final dNext = vNext.distance;
      final uNext = vNext / dNext;
      
      final pStart = pCurr + uPrev * math.min(r, dPrev * 0.5);
      final pEnd = pCurr + uNext * math.min(r, dNext * 0.5);
      
      if (i == 0) {
        path.moveTo(pStart.dx, pStart.dy);
      } else {
        path.lineTo(pStart.dx, pStart.dy);
      }
      path.quadraticBezierTo(pCurr.dx, pCurr.dy, pEnd.dx, pEnd.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
