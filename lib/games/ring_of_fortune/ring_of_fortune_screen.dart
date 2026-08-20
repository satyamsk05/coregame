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

class FortuneWheelSegment {
  final int index;
  final String color; // 'grey', 'purple', 'orange', 'green'
  final Color actualColor;
  final double multiplier;

  const FortuneWheelSegment({
    required this.index,
    required this.color,
    required this.actualColor,
    required this.multiplier,
  });
}

class RingOfFortuneGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final String nickname;
  final String avatarPath;
  final int vipLevel;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const RingOfFortuneGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.nickname,
    required this.avatarPath,
    required this.vipLevel,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<RingOfFortuneGameScreen> createState() => _RingOfFortuneGameScreenState();
}

class _RingOfFortuneGameScreenState extends State<RingOfFortuneGameScreen> with SingleTickerProviderStateMixin {
  late final List<FortuneWheelSegment> _segments;
  late final AnimationController _spinController;
  late Animation<double> _spinAnimation;

  // Global settings
  final TextEditingController _amountController = TextEditingController(text: '10.00');

  // Game phases: 'betting' -> 'spinning' -> 'result'
  String _gamePhase = 'betting';
  double _timerSeconds = 15.0;
  Timer? _gameTimer;
  Timer? _countdownTimer;

  // Spin rotation details
  double _rotationAngle = 0.0;
  FortuneWheelSegment? _winningSegment;
  final List<String> _previousRolls = [];

  // Active placed bets mapping to lock during spinning
  final Map<String, double> _placedBets = {
    'grey': 0.0,
    'purple': 0.0,
    'orange': 0.0,
    'green': 0.0,
  };

  // Animation triggers
  int _triggerUserBet = 0;
  int _triggerUserWin = 0;
  double _winAmount = 0.0;
  bool _dialogOpened = false;

  @override
  void initState() {
    super.initState();
    _segments = _generateSegments();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    // Initial random rotation to make the wheel start nicely offset
    _rotationAngle = math.Random().nextDouble() * 2 * math.pi;

    // Seed initial rolls history
    final rand = math.Random();
    final colors = ['grey', 'purple', 'orange', 'green'];
    for (int i = 0; i < 5; i++) {
      _previousRolls.add(colors[rand.nextInt(colors.length)]);
    }

    _startNewBettingCycle();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  List<FortuneWheelSegment> _generateSegments() {
    final List<FortuneWheelSegment> list = [];
    for (int i = 0; i < 30; i++) {
      String colorStr;
      Color actualColor;
      double multiplier;

      if (i == 0) {
        colorStr = 'green';
        actualColor = const Color(0xFF24EE89);
        multiplier = 98.0;
      } else if (i == 6 || i == 12 || i == 18 || i == 24) {
        colorStr = 'orange';
        actualColor = const Color(0xFFEA580C);
        multiplier = 5.94;
      } else if (i == 3 || i == 5 || i == 9 || i == 11 || i == 15 || i == 17 || i == 21 || i == 23 || i == 27 || i == 29) {
        colorStr = 'purple';
        actualColor = const Color(0xFF7E22CE);
        multiplier = 2.97;
      } else {
        colorStr = 'grey';
        actualColor = const Color(0xFF3E434E);
        multiplier = 1.98;
      }

      list.add(FortuneWheelSegment(
        index: i,
        color: colorStr,
        actualColor: actualColor,
        multiplier: multiplier,
      ));
    }
    return list;
  }

  void _startNewBettingCycle() {
    if (_dialogOpened) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpened = false;
    }

    setState(() {
      _gamePhase = 'betting';
      _timerSeconds = 15.0;
      _winningSegment = null;
      // Reset locked bets
      _placedBets.updateAll((key, value) => 0.0);
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0.09) {
            _timerSeconds -= 0.1;
          } else {
            _timerSeconds = 0.0;
            _countdownTimer?.cancel();
            _triggerSpinPhase();
          }
        });
      }
    });
  }

  void _handleOptionTap(String colorKey) {
    if (_gamePhase != 'betting') return;
    final betAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (betAmount <= 0) return;
    if (betAmount > widget.balance) {
      showWinLoseToast(
        context,
        title: 'ERROR',
        message: 'Insufficient balance!',
        isWin: false,
      );
      return;
    }
    widget.onBalanceChanged(widget.balance - betAmount);
    setState(() {
      _placedBets[colorKey] = (_placedBets[colorKey] ?? 0.0) + betAmount;
      _triggerUserBet++;
    });
    if (widget.soundOn) SoundManager.playClick();
  }

  void _triggerSpinPhase() {
    // Bets are already locked in _placedBets via instant taps.
    // Verify balance check was already performed during tapping.
    double totalBet = _placedBets.values.fold(0.0, (sum, val) => sum + val);

    if (totalBet > 0) {
      setState(() {
        _triggerUserBet++;
      });
      if (widget.soundOn) SoundManager.playClick();
    }

    setState(() {
      _gamePhase = 'spinning';
    });

    // Pick winning segment
    final rand = math.Random();
    final targetIndex = rand.nextInt(30);
    final targetSegment = _segments[targetIndex];

    // Pointer is at bottom (i.e. angle math.pi / 2).
    // Segment i starting angle in CustomPainter is: -math.pi / 2 + i * segmentAngle + currentRotationAngle.
    // To align segment i to bottom pointer:
    // -math.pi / 2 + i * segmentAngle + currentRotationAngle = math.pi / 2
    // currentRotationAngle = math.pi - i * segmentAngle.
    final double segmentAngle = (2 * math.pi) / 30;
    final double baseTargetAngle = math.pi - (targetIndex * segmentAngle);
    
    // Smooth infinite rotation with physics deceleration
    final double currentAngleMod = _rotationAngle % (2 * math.pi);
    final double targetAngle = currentAngleMod + (8 * 2 * math.pi) + (baseTargetAngle - currentAngleMod);

    _spinAnimation = Tween<double>(
      begin: _rotationAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCirc,
    ));

    _spinController.reset();
    _spinController.addListener(() {
      setState(() {
        _rotationAngle = _spinAnimation.value;
      });
    });

    _spinController.forward().then((_) {
      _triggerResultPhase(targetSegment);
    });
  }

  void _triggerResultPhase(FortuneWheelSegment segment) {
    double totalPayout = 0.0;
    _placedBets.forEach((color, betAmt) {
      if (segment.color == color) {
        totalPayout += betAmt * segment.multiplier;
      }
    });

    setState(() {
      _gamePhase = 'result';
      _winningSegment = segment;
      _previousRolls.insert(0, segment.color);
      if (_previousRolls.length > 8) {
        _previousRolls.removeLast();
      }

      if (totalPayout > 0) {
        _winAmount = totalPayout;
        _triggerUserWin++;
        widget.onBalanceChanged(widget.balance + totalPayout);
        if (widget.soundOn) SoundManager.playClick();

        // Show win toast and dialog overlay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showWinLoseToast(
            context,
            isWin: true,
            title: 'YOU WON!',
            message: 'Won ₹${totalPayout.toStringAsFixed(2)}',
          );
          _dialogOpened = true;
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => Center(
              child: WinOverlayCard(
                multiplier: segment.multiplier,
                winAmount: totalPayout,
                isWin: true,
              ),
            ),
          );
        });
      } else {
        _winAmount = 0.0;
        if (widget.soundOn && _placedBets.values.any((v) => v > 0)) {
          SoundManager.playClick();
        }

        // Show loss toast
        double totalPlacedBet = _placedBets.values.fold(0.0, (sum, val) => sum + val);
        if (totalPlacedBet > 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showWinLoseToast(
              context,
              isWin: false,
              title: 'YOU LOST!',
              message: 'Lost ₹${totalPlacedBet.toStringAsFixed(2)}',
            );
          });
        }
      }
    });

    // 3.8 seconds display result overlay then restart
    _gameTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        _startNewBettingCycle();
      }
    });
  }

  void _adjustGlobalAmount(double amount) {
    if (_gamePhase != 'betting') return;
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  void _incrementGlobalAmount(double delta) {
    if (_gamePhase != 'betting') return;
    double current = double.tryParse(_amountController.text) ?? 1.0;
    double newValue = math.max(0.1, current + delta);
    setState(() {
      _amountController.text = newValue.toStringAsFixed(2);
    });
  }

  void _placeBetFromGlobalAmount() {
    if (_gamePhase != 'betting') return;
    double totalBet = _placedBets.values.fold(0.0, (sum, val) => sum + val);
    if (totalBet <= 0) {
      _handleOptionTap('grey');
    }
    _triggerSpinPhase();
  }

  void _resetBets() {
    if (_gamePhase != 'betting') return;
    double totalBet = _placedBets.values.fold(0.0, (sum, val) => sum + val);
    if (totalBet > 0) {
      widget.onBalanceChanged(widget.balance + totalBet);
    }
    setState(() {
      _placedBets.updateAll((key, value) => 0.0);
      _amountController.text = '10.00';
    });
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E222B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            width: 420.0,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ring of Fortune Rules',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Ring of Fortune is a continuous 30-segment wheel game consisting of four colors. Each color offers different payouts based on segment frequency:',
                          style: GoogleFonts.roboto(color: Colors.white70, fontSize: 13.0),
                        ),
                        const SizedBox(height: 12.0),
                        _buildRuleRow('Grey Circle (1.98x)', '15 segments on the wheel (50% win probability). Wins double your bet.'),
                        _buildRuleRow('Purple Circle (2.97x)', '10 segments on the wheel (33.3% win probability). Wins triple your bet.'),
                        _buildRuleRow('Orange Circle (5.94x)', '4 segments on the wheel (13.3% win probability). Pays ~6x your bet.'),
                        _buildRuleRow('Green Circle (98x)', '1 single segment on the wheel (3.3% win probability). Rare Jackpot color paying 98x!'),
                        const SizedBox(height: 12.0),
                        Text(
                          'How to Play:',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          '1. Set the bet amount using the input field or SUGGEST AMOUNT quick buttons.\n'
                          '2. Tap any Option card in the 2x2 grid to instantly place a bet of that amount on that color. Amount is deducted immediately from your balance. You may tap the same card multiple times to accumulate bets.\n'
                          '3. Active bet amounts appear as gold badges on the top-right corner of each Option card.\n'
                          '4. Tap the green "Bet" button (or wait for the timer) to spin the wheel. If no bets are placed, pressing "Bet" will place a default bet on Option 1.\n'
                          '5. Use the "Reset" button at any time during betting to refund all currently placed bets back to your balance.\n'
                          '6. Correct color bets receive their respective payouts automatically after the wheel settles.',
                          style: GoogleFonts.roboto(color: Colors.white70, fontSize: 12.0, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(color: const Color(0xFF24EE89), fontSize: 13.0, fontWeight: FontWeight.bold),
          ),
          Text(
            desc,
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 12.0),
          ),
          const SizedBox(height: 4.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpinning = _gamePhase == 'spinning';
    final bool isResult = _gamePhase == 'result';
    final bool interactionEnabled = _gamePhase == 'betting';

    return Scaffold(
      body: Stack(
        children: [
          const NightForestBackground(),

          SafeArea(
            child: Column(
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      Bounceable(
                        onTap: () {
                          if (widget.soundOn) SoundManager.playClick();
                          widget.onBackPressed();
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.0),
                        ),
                      ),

                      // App Game Brand Label
                      Text(
                        'RING OF FORTUNE',
                        style: GoogleFonts.outfit(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      // Rules Help Button
                      Bounceable(
                        onTap: _showRulesDialog,
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(Icons.help_outline, color: Colors.white, size: 22.0),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Game Split Columns Layout
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      children: [
                        // Left Betting Console panel
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. 2x2 Grid of Option Cards
                              Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E222B),
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildOptionCard(
                                            colorKey: 'grey',
                                            mainColor: const Color(0xFF2563EB),
                                            shadowColor: const Color(0xFF1D4ED8),
                                            ringColor: const Color(0xFFBFDBFE),
                                            label: 'Option 1',
                                            multiplier: '1.98',
                                            enabled: interactionEnabled,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Expanded(
                                          child: _buildOptionCard(
                                            colorKey: 'purple',
                                            mainColor: const Color(0xFF9333EA),
                                            shadowColor: const Color(0xFF7E22CE),
                                            ringColor: const Color(0xFFE9D5FF),
                                            label: 'Option 2',
                                            multiplier: '2.97',
                                            enabled: interactionEnabled,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildOptionCard(
                                            colorKey: 'orange',
                                            mainColor: const Color(0xFFF97316),
                                            shadowColor: const Color(0xFFEA580C),
                                            ringColor: const Color(0xFFFED7AA),
                                            label: 'Option 3',
                                            multiplier: '5.94',
                                            enabled: interactionEnabled,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Expanded(
                                          child: _buildOptionCard(
                                            colorKey: 'green',
                                            mainColor: const Color(0xFF24EE89),
                                            shadowColor: const Color(0xFF0FAD5C),
                                            ringColor: const Color(0xFFBBF7D0),
                                            label: 'Option 4',
                                            multiplier: '98.00',
                                            enabled: interactionEnabled,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 5.0),

                              // 2. SUGGEST AMOUNT Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
                                    child: Text(
                                      'SUGGEST AMOUNT',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [10, 100, 500, 1000].map((val) {
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                          child: Bounceable(
                                            onTap: () => _adjustGlobalAmount(val.toDouble()),
                                            child: Container(
                                              height: 25.0,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E222B).withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(6.0),
                                                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.55), width: 1.2),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '+$val',
                                                style: GoogleFonts.roboto(
                                                  color: const Color(0xFF93C5FD),
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
                                ],
                              ),

                              const SizedBox(height: 5.0),

                              // 3. ENTER AMOUNT Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
                                    child: Text(
                                      'ENTER AMOUNT',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E222B),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22.0,
                                          height: 24.0,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '₹',
                                            style: TextStyle(color: Color(0xFF24EE89), fontSize: 13.0, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 2.0),
                                        Expanded(
                                          child: Container(
                                            height: 26.0,
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16181C),
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: TextField(
                                              controller: _amountController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              enabled: interactionEnabled,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5.0),
                                        Bounceable(
                                          onTap: () => _incrementGlobalAmount(-10.0),
                                          child: Container(
                                            width: 24.0,
                                            height: 24.0,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                            child: const Icon(Icons.remove, color: Colors.white, size: 13.0),
                                          ),
                                        ),
                                        const SizedBox(width: 3.0),
                                        Bounceable(
                                          onTap: () => _incrementGlobalAmount(10.0),
                                          child: Container(
                                            width: 24.0,
                                            height: 24.0,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                            child: const Icon(Icons.add, color: Colors.white, size: 13.0),
                                          ),
                                        ),
                                        const SizedBox(width: 5.0),
                                        Bounceable(
                                          onTap: _resetBets,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF24EE89).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(5.0),
                                              border: Border.all(color: const Color(0xFF24EE89).withValues(alpha: 0.4), width: 0.8),
                                            ),
                                            child: Text(
                                              'Reset',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF24EE89),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),
                              const SizedBox(height: 4.0),

                              // 4. Footer: Profile Card and Bet Button row inside Left Column!
                              Row(
                                children: [
                                  // Unified Player Info Box
                                  Container(
                                    height: 52.0,
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F1115),
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(color: Colors.white10, width: 1.0),
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
                                        const SizedBox(width: 6.0),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              widget.nickname,
                                              style: GoogleFonts.roboto(
                                                textStyle: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              '₹${widget.balance.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  // Large green Bet button taking remaining space
                                  Expanded(
                                    child: Opacity(
                                      opacity: interactionEnabled ? 1.0 : 0.5,
                                      child: Bounceable(
                                        onTap: interactionEnabled ? _placeBetFromGlobalAmount : null,
                                        child: Builder(
                                          builder: (context) {
                                            final totalActiveBet = _placedBets.values.fold<double>(0.0, (sum, v) => sum + v);
                                            return Container(
                                              height: 52.0,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF24EE89),
                                                borderRadius: BorderRadius.circular(10.0),
                                              ),
                                              alignment: Alignment.center,
                                              child: _gamePhase == 'betting'
                                                  ? Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          totalActiveBet > 0 ? 'BET  ₹${totalActiveBet.toStringAsFixed(2)}' : 'Bet',
                                                          style: GoogleFonts.outfit(
                                                            color: const Color(0xFF0F1115),
                                                            fontSize: 15.0,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        if (totalActiveBet > 0)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 1.0),
                                                            child: Text(
                                                              'TAP TO SPIN',
                                                              style: GoogleFonts.outfit(
                                                                color: const Color(0xFF0F1115).withValues(alpha: 0.6),
                                                                fontSize: 8.0,
                                                                fontWeight: FontWeight.w900,
                                                                letterSpacing: 0.6,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    )
                                                  : Text(
                                                      'Rolling...',
                                                      style: GoogleFonts.outfit(
                                                        color: const Color(0xFF0F1115),
                                                        fontSize: 16.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16.0),

                        // Right Fortune Wheel panel
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Multiplier tags history at the top of the wheel panel
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildMultiplierTag('1.98x', const Color(0xFF3E434E)),
                                  _buildMultiplierTag('2.97x', const Color(0xFF7E22CE)),
                                  _buildMultiplierTag('5.94x', const Color(0xFFEA580C)),
                                  _buildMultiplierTag('98x', const Color(0xFF24EE89)),
                                ],
                              ),

                              const SizedBox(height: 8.0),

                              // Wheel container area
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E222B).withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // The segments wheel
                                      AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: CustomPaint(
                                            painter: FortuneWheelPainter(
                                              segments: _segments,
                                              currentRotationAngle: _rotationAngle,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Center display capsule info
                                      Container(
                                        width: 120.0,
                                        height: 50.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F222B),
                                          borderRadius: BorderRadius.circular(8.0),
                                          border: Border.all(color: Colors.white10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black45,
                                              blurRadius: 8.0,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (interactionEnabled) ...[
                                              Text(
                                                'ROLLING IN',
                                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 8.0, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '${_timerSeconds.toStringAsFixed(1)}s',
                                                style: GoogleFonts.roboto(color: const Color(0xFF24EE89), fontSize: 13.0, fontWeight: FontWeight.bold),
                                              ),
                                            ] else if (isSpinning) ...[
                                              Text(
                                                'SPINNING',
                                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 8.0, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                width: 12.0,
                                                height: 12.0,
                                                child: CircularProgressIndicator(strokeWidth: 2.0, color: Color(0xFF7E22CE)),
                                              ),
                                            ] else if (isResult) ...[
                                              Text(
                                                'OUTCOME',
                                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 8.0, fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                width: 14.0,
                                                height: 14.0,
                                                decoration: BoxDecoration(
                                                  color: _winningSegment?.actualColor ?? Colors.grey,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Orange Pointer pointing UP at the bottom center of the wheel
                                      Positioned(
                                        bottom: 4.0,
                                        child: Container(
                                          width: 18.0,
                                          height: 18.0,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.arrow_drop_up,
                                            color: Color(0xFFEA580C),
                                            size: 26.0,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String colorKey,
    required Color mainColor,
    required Color shadowColor,
    required Color ringColor,
    required String label,
    required String multiplier,
    required bool enabled,
  }) {
    final activeBet = _placedBets[colorKey] ?? 0.0;
    final hasActiveBet = activeBet > 0;

    return Bounceable(
      onTap: enabled ? () => _handleOptionTap(colorKey) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: SizedBox(
          height: 72.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: 3.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: shadowColor,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.black26, width: 0.5),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 3.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.white12, width: 0.8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        mainColor.withValues(alpha: 1.0),
                        mainColor.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42.0,
                        height: 42.0,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ringColor.withValues(alpha: 0.22),
                                border: Border.all(color: ringColor, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: ringColor.withValues(alpha: 0.45),
                                    blurRadius: 6.0,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24.0,
                              height: 24.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ringColor.withValues(alpha: 0.35),
                                border: Border.all(color: ringColor.withValues(alpha: 0.9), width: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'x $multiplier',
                                style: GoogleFonts.roboto(
                                  color: const Color(0xFFFFF8A5),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasActiveBet)
                Positioned(
                  top: -6.0,
                  right: -4.0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 28.0),
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFFB8860B), width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 3.0, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '₹${activeBet.toStringAsFixed(activeBet == activeBet.roundToDouble() ? 0 : 2)}',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF1A120B),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FortuneWheelPainter extends CustomPainter {
  final List<FortuneWheelSegment> segments;
  final double currentRotationAngle;

  FortuneWheelPainter({
    required this.segments,
    required this.currentRotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final double segmentAngle = (2 * math.pi) / 30;

    // Draw segment by segment
    for (int i = 0; i < 30; i++) {
      final seg = segments[i];
      // Offset start angle so that index 0 starts aligned to math.pi / 2 (pointer) when currentRotationAngle = 0.
      final double startAngle = -math.pi / 2 + (i * segmentAngle) + currentRotationAngle;

      final paint = Paint()
        ..color = seg.actualColor
        ..style = PaintingStyle.fill;

      // Draw arc sector
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.02, // subtle gap
        segmentAngle - 0.04, // subtle gap
        true,
        paint,
      );
    }

    // Draw an inner circle mask to make it a ring/donut wheel
    final maskPaint = Paint()
      ..color = const Color(0xFF1E222B) // matched background color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.72, maskPaint);

    // Draw outer rim edge line
    final outerEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, outerEdgePaint);
    canvas.drawCircle(center, radius * 0.72, outerEdgePaint);
  }

  @override
  bool shouldRepaint(covariant FortuneWheelPainter oldDelegate) {
    return oldDelegate.currentRotationAngle != currentRotationAngle;
  }
}
