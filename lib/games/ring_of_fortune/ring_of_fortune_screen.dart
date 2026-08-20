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
  final TextEditingController _amountController = TextEditingController(text: '1.00');
  
  // Bet controllers for each of the 4 colors
  final Map<String, TextEditingController> _betControllers = {
    'grey': TextEditingController(text: '0'),
    'purple': TextEditingController(text: '0'),
    'orange': TextEditingController(text: '0'),
    'green': TextEditingController(text: '0'),
  };

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
    for (var ctrl in _betControllers.values) {
      ctrl.dispose();
    }
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

  void _triggerSpinPhase() {
    // Collect bets
    double totalBet = 0.0;
    final Map<String, double> tempBets = {};
    _betControllers.forEach((color, controller) {
      final val = double.tryParse(controller.text) ?? 0.0;
      tempBets[color] = val;
      totalBet += val;
    });

    if (totalBet > widget.balance) {
      // User placed more bets than balance, cap bets to balance proportionally or prompt error
      showWinLoseToast(
        context,
        title: 'ERROR',
        message: 'Insufficient balance to place bets!',
        isWin: false,
      );
      _startNewBettingCycle();
      return;
    }

    if (totalBet > 0) {
      widget.onBalanceChanged(widget.balance - totalBet);
      _placedBets.addAll(tempBets);
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

  void _applyMultiplierToColor(String color, double factor) {
    if (_gamePhase != 'betting') return;
    final ctrl = _betControllers[color]!;
    double current = double.tryParse(ctrl.text) ?? 0.0;
    double newValue = current * factor;
    setState(() {
      ctrl.text = newValue.round().toString();
    });
  }

  void _incrementColorBet(String color, int delta) {
    if (_gamePhase != 'betting') return;
    final ctrl = _betControllers[color]!;
    int current = int.tryParse(ctrl.text) ?? 0;
    int newValue = math.max(0, current + delta);
    setState(() {
      ctrl.text = newValue.toString();
    });
  }

  void _placeBetFromGlobalAmount() {
    if (_gamePhase != 'betting') return;
    _triggerSpinPhase();
  }

  void _resetBets() {
    if (_gamePhase != 'betting') return;
    setState(() {
      _betControllers.forEach((key, ctrl) {
        ctrl.text = '0';
      });
      _amountController.text = '1.00';
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
                          '1. Place your bet amounts in the color input fields during the 15-second betting countdown.\n'
                          '2. Tap "Bet" to lock in your selections. You can place bets on multiple colors simultaneously.\n'
                          '3. Once the timer hits 0, the wheel spins and settles on a random segment.\n'
                          '4. Correct color bets receive their respective payouts automatically.',
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
                              // Global bet Amount setup bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E222B),
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Amount',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Container(
                                        height: 30.0,
                                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16181C),
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            const Text('₹', style: TextStyle(color: Color(0xFF24EE89), fontSize: 13.0, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 4.0),
                                            Expanded(
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
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    // Suffix increment/decrement buttons
                                    Row(
                                      children: [
                                        Bounceable(
                                          onTap: () => _incrementGlobalAmount(-10.0),
                                          child: Container(
                                            width: 26.0,
                                            height: 26.0,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: const Icon(Icons.remove, color: Colors.white, size: 14.0),
                                          ),
                                        ),
                                        const SizedBox(width: 4.0),
                                        Bounceable(
                                          onTap: () => _incrementGlobalAmount(10.0),
                                          child: Container(
                                            width: 26.0,
                                            height: 26.0,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: const Icon(Icons.add, color: Colors.white, size: 14.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    GestureDetector(
                                      onTap: _resetBets,
                                      child: Text(
                                        'Reset',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF24EE89),
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 4.0),

                              // Quick Bet shortcuts suggestions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [10, 100, 500, 1000].map((val) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: Bounceable(
                                        onTap: () => _adjustGlobalAmount(val.toDouble()),
                                        child: Container(
                                          height: 24.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E222B),
                                            borderRadius: BorderRadius.circular(6.0),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '+$val',
                                            style: GoogleFonts.roboto(
                                              color: Colors.white70,
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

                              const SizedBox(height: 4.0),

                              // Color rows selections list
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E222B),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildColorBetRow('grey', const Color(0xFF3E434E), interactionEnabled),
                                      _buildColorBetRow('purple', const Color(0xFF7E22CE), interactionEnabled),
                                      _buildColorBetRow('orange', const Color(0xFFEA580C), interactionEnabled),
                                      _buildColorBetRow('green', const Color(0xFF24EE89), interactionEnabled),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6.0),

                              // Profile Card and Bet Button row inside Left Column!
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
                                        child: Container(
                                          height: 52.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF24EE89),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _gamePhase == 'betting' ? 'Bet' : 'Rolling...',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF0F1115),
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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

  Widget _build3DColorIndicator(String colorKey) {
    Color mainColor;
    Color shadowColor;

    switch (colorKey) {
      case 'grey':
        mainColor = const Color(0xFF555B68);
        shadowColor = const Color(0xFF33373E);
        break;
      case 'purple':
        mainColor = const Color(0xFF9333EA);
        shadowColor = const Color(0xFF6B21A8);
        break;
      case 'orange':
        mainColor = const Color(0xFFF97316);
        shadowColor = const Color(0xFFC2410C);
        break;
      case 'green':
        mainColor = const Color(0xFF24EE89);
        shadowColor = const Color(0xFF0FAD5C);
        break;
      default:
        mainColor = Colors.grey;
        shadowColor = Colors.black;
    }

    return SizedBox(
      width: 32.0,
      height: 24.0,
      child: Stack(
        children: [
          // Bottom shadow/bevel layer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 21.0,
            child: Container(
              decoration: BoxDecoration(
                color: shadowColor,
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          // Top main colored button layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 21.0,
            child: Container(
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBetRow(String colorKey, Color colorTheme, bool enabled) {
    final ctrl = _betControllers[colorKey]!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          // 3D Bevel Color Multiplier Indicator
          _build3DColorIndicator(colorKey),
          const SizedBox(width: 8.0),

          // Numeric Bet Input Container
          Expanded(
            child: Container(
              height: 26.0,
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFF16181C),
                borderRadius: BorderRadius.circular(6.0),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                enabled: enabled,
              ),
            ),
          ),

          const SizedBox(width: 6.0),

          // Helper shortcuts 1/2 and 2x
          Row(
            children: [
              Bounceable(
                onTap: () => _applyMultiplierToColor(colorKey, 0.5),
                child: Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '1/2',
                    style: GoogleFonts.roboto(color: Colors.white70, fontSize: 9.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Bounceable(
                onTap: () => _applyMultiplierToColor(colorKey, 2.0),
                child: Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '2x',
                    style: GoogleFonts.roboto(color: Colors.white70, fontSize: 9.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),

              // Up/Down Arrows
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Bounceable(
                    onTap: () => _incrementColorBet(colorKey, 10),
                    child: Container(
                      width: 18.0,
                      height: 11.5,
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(2.0),
                          topRight: Radius.circular(2.0),
                        ),
                      ),
                      child: const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 12.0),
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  Bounceable(
                    onTap: () => _incrementColorBet(colorKey, -10),
                    child: Container(
                      width: 18.0,
                      height: 11.5,
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(2.0),
                          bottomRight: Radius.circular(2.0),
                        ),
                      ),
                      child: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 12.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
