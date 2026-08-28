import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/bounceable.dart';
import '../../shared/widgets/win_overlay_card.dart';
import '../../shared/widgets/win_lose_toast.dart';
import '../../utils/sound_manager.dart';
import '../andar_bahar/widgets/player_widgets.dart';
import '../andar_bahar/widgets/chip_widgets.dart';
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

  // Selected chip value
  int _selectedChipValue = 10;

  // Mock player data for sidebars
  final List<Map<String, dynamic>> _leftPlayers = [
    {'name': 'Billionaire', 'balance': 83450.0, 'avatar': 'assets/userprofile/user1.png'},
    {'name': 'Richie', 'balance': 24450.0, 'avatar': 'assets/userprofile/user2.png'},
    {'name': 'High Roller', 'balance': 9730.0, 'avatar': 'assets/userprofile/user3.png'},
  ];
  final List<Map<String, dynamic>> _rightPlayers = [
    {'name': 'Master', 'balance': 5350.0, 'avatar': 'assets/userprofile/user4.png'},
    {'name': 'Pro King', 'balance': 12790.0, 'avatar': 'assets/userprofile/user5.png'},
    {'name': 'Elite Player', 'balance': 7500.0, 'avatar': 'assets/userprofile/user6.png'},
  ];

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
    final betAmount = _selectedChipValue.toDouble();
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

  void _resetBets() {
    if (_gamePhase != 'betting') return;
    double totalBet = _placedBets.values.fold(0.0, (sum, val) => sum + val);
    if (totalBet > 0) {
      widget.onBalanceChanged(widget.balance + totalBet);
    }
    setState(() {
      _placedBets.updateAll((key, value) => 0.0);
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
        fit: StackFit.expand,
        children: [
          const NightForestBackground(),
          Container(color: Colors.black.withValues(alpha: 0.15)),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final double sidebarW = (w * 0.1365).clamp(92.4, 120.75);

                return Stack(
                  children: [
                    // Back button (top-left)
                    Positioned(
                      top: 6.0, left: 8.0,
                      child: GestureDetector(
                        onTap: isSpinning ? null : widget.onBackPressed,
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
                    ),

                    // Title center top
                    Positioned(
                      top: 10.0, left: 100.0, right: 100.0,
                      child: Center(
                        child: Text(
                          'RING OF FORTUNE',
                          style: GoogleFonts.outfit(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Help button (top-right)
                    Positioned(
                      top: 6.0, right: 8.0,
                      child: GestureDetector(
                        onTap: _showRulesDialog,
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
                    ),

                    // Left sidebar
                    Positioned(
                      left: 6.0, top: 42.0, bottom: 6.0, width: sidebarW,
                      child: _buildSidebar(_leftPlayers, true),
                    ),
                    // Right sidebar
                    Positioned(
                      right: 6.0, top: 42.0, bottom: 6.0, width: sidebarW,
                      child: _buildSidebar(_rightPlayers, false),
                    ),

                    // Center Content Column
                    Positioned(
                      left: sidebarW + 12.0,
                      right: sidebarW + 12.0,
                      top: 38.0,
                      bottom: 4.0,
                      child: Column(
                        children: [
                          // Previous Rolls
                          _buildPreviousRollsHistory(),
                          const SizedBox(height: 4.0),

                          // State / Countdown text
                          Center(
                            child: Text(
                              _gamePhase == 'betting'
                                  ? 'Rolling In ${_timerSeconds.toStringAsFixed(1)}s'
                                  : (_gamePhase == 'spinning' ? 'Spinning...' : (_winningSegment != null ? '${_winningSegment!.color.toUpperCase()} ${_winningSegment!.multiplier}x Won!' : '')),
                              style: GoogleFonts.roboto(textStyle: TextStyle(
                                color: _gamePhase == 'result' && _winningSegment?.color == 'green' ? const Color(0xFF24EE89) : Colors.white,
                                fontSize: 13.0, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                              )),
                            ),
                          ),
                          const SizedBox(height: 4.0),

                          // Wheel and Option Cards
                          Expanded(
                            child: Row(
                              children: [
                                // Left part of center: Segmented Fortune Wheel
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E222B).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // The segmented wheel CustomPaint
                                        AspectRatio(
                                          aspectRatio: 1.0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: CustomPaint(
                                              painter: FortuneWheelPainter(
                                                segments: _segments,
                                                currentRotationAngle: _rotationAngle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Center outcome display capsule info
                                        Container(
                                          width: 80.0,
                                          height: 38.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1F222B),
                                            borderRadius: BorderRadius.circular(6.0),
                                            border: Border.all(color: Colors.white10),
                                            boxShadow: const [
                                              BoxShadow(color: Colors.black45, blurRadius: 4.0, offset: Offset(0, 2)),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (interactionEnabled) ...[
                                                Text(
                                                  'ROLLING',
                                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 6.5, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  '${_timerSeconds.toStringAsFixed(0)}s',
                                                  style: GoogleFonts.roboto(color: const Color(0xFF24EE89), fontSize: 10.0, fontWeight: FontWeight.bold),
                                                ),
                                              ] else if (isSpinning) ...[
                                                Text(
                                                  'SPINNING',
                                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 6.5, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(
                                                  width: 10.0,
                                                  height: 10.0,
                                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF7E22CE)),
                                                ),
                                              ] else if (isResult) ...[
                                                Text(
                                                  'OUTCOME',
                                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 6.5, fontWeight: FontWeight.bold),
                                                ),
                                                Container(
                                                  width: 11.0,
                                                  height: 11.0,
                                                  decoration: BoxDecoration(
                                                    color: _winningSegment?.actualColor ?? Colors.grey,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Pointer pointing UP at the bottom center of the wheel
                                        Positioned(
                                          bottom: 2.0,
                                          child: Container(
                                            width: 14.0,
                                            height: 14.0,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFFF5252),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black38, blurRadius: 2.0, offset: Offset(0, 1)),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 9.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),

                                // Right part of center: Grid of 4 option cards
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildOptionCard(
                                              colorKey: 'grey',
                                              mainColor: const Color(0xFF3E434E),
                                              shadowColor: const Color(0xFF2B2F37),
                                              ringColor: const Color(0xFF9CA3AF),
                                              label: 'Grey',
                                              multiplier: '1.98',
                                              enabled: interactionEnabled,
                                            ),
                                          ),
                                          const SizedBox(width: 6.0),
                                          Expanded(
                                            child: _buildOptionCard(
                                              colorKey: 'purple',
                                              mainColor: const Color(0xFF7E22CE),
                                              shadowColor: const Color(0xFF5B179A),
                                              ringColor: const Color(0xFFD8B4FE),
                                              label: 'Purple',
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
                                              mainColor: const Color(0xFFEA580C),
                                              shadowColor: const Color(0xFFB43E06),
                                              ringColor: const Color(0xFFFDBA74),
                                              label: 'Orange',
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
                                              ringColor: const Color(0xFF86EFAC),
                                              label: 'Green',
                                              multiplier: '98.00',
                                              enabled: interactionEnabled,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6.0),

                          // Centered bottom bar
                          _buildBottomBar(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Player with DP Banner ──
  Widget _buildSidebarPlayer(Map<String, dynamic> p, String bannerPath) {
    final String name = p['name'] as String;
    final double balance = p['balance'] as double;
    final String avatar = p['avatar'] as String;

    String username = name.toLowerCase();
    if (name == 'Billionaire') username = "name304250";
    else if (name == 'Richie') username = "kFOJx";
    else if (name == 'High Roller') username = "name136668";
    else if (name == 'Master') username = "proMaster99";
    else if (name == 'Pro King') username = "kingSlot88";
    else if (name == 'Elite Player') username = "eliteGamer";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Banner Stack
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 35.3,
                height: 35.3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 2.0, offset: Offset(0, 1)),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(avatar, fit: BoxFit.cover),
                ),
              ),
              Image.asset(
                bannerPath,
                width: 48.5,
                height: 48.5,
                fit: BoxFit.contain,
              ),
              if (name == 'Master')
                Positioned(
                  top: -6.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 2.0, offset: Offset(0, 1.0))
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF3D00)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.star,
                        size: 12.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2.0),
          // Nickname below the banner
          Text(
            username,
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 7.9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 1.0),
          // Balance below the nickname
          Text(
            '₹${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 7.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Widget ──
  Widget _buildSidebar(List<Map<String, dynamic>> players, bool isLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0x3323272C), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: players.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;

          // Map to correct banner image
          String bannerPath = 'assets/dpbanner/IMG_20260821_135148.png';
          if (isLeft) {
            if (idx == 0) bannerPath = 'assets/dpbanner/IMG_20260821_135148.png';
            else if (idx == 1) bannerPath = 'assets/dpbanner/IMG_20260821_135204.png';
            else if (idx == 2) bannerPath = 'assets/dpbanner/IMG_20260821_135223.png';
          } else {
            if (idx == 0) bannerPath = 'assets/dpbanner/IMG_20260821_135255.png';
            else if (idx == 1) bannerPath = 'assets/dpbanner/IMG_20260821_135316.png';
            else if (idx == 2) bannerPath = 'assets/dpbanner/IMG_20260821_135338.png';
          }

          return _buildSidebarPlayer(p, bannerPath);
        }).toList(),
      ),
    );
  }

  Widget _buildPreviousRollsHistory() {
    return SizedBox(
      height: 24.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'History:',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(color: Colors.white54, fontSize: 9.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6.0),
          ..._previousRolls.map((color) {
            Color dotColor;
            if (color == 'green') dotColor = const Color(0xFF24EE89);
            else if (color == 'orange') dotColor = const Color(0xFFEA580C);
            else if (color == 'purple') dotColor = const Color(0xFF7E22CE);
            else dotColor = const Color(0xFF3E434E);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Game-Style Profile (Andar Bahar style with DP Banner) ──
  Widget _buildGameProfile() {
    final String userBanner = 'assets/dpbanner/IMG_20260821_135148.png';
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar + Banner Stack
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Inner Avatar
            Container(
              width: 35.7,
              height: 35.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 2.0, offset: Offset(0, 1)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(widget.avatarPath, fit: BoxFit.cover),
              ),
            ),
            // Outer DP Banner Frame
            Image.asset(
              userBanner,
              width: 50.4,
              height: 50.4,
              fit: BoxFit.contain,
            ),
            // Online indicator dot
            Positioned(
              right: 2.0, top: 2.0,
              child: Container(
                width: 8.0, height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676),
                  border: Border.all(color: Colors.black, width: 1.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6.0),
        // Nickname + Balance to the right side
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.nickname,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2.0),
            // Balance tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: const Color(0x4D000000),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '₹${widget.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Bottom Bar: Player Info + Chip Selector ──
  Widget _buildBottomBar() {
    final bool interactionEnabled = _gamePhase == 'betting';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile section (left side, game-style like Andar Bahar)
        _buildGameProfile(),
        const SizedBox(width: 8.0),
        // Chips container (no background)
        IgnorePointer(
          ignoring: !interactionEnabled,
          child: Opacity(
            opacity: interactionEnabled ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [10, 50, 100, 500, 1000].expand((val) {
                  final isSelected = _selectedChipValue == val;
                  return [
                    GestureDetector(
                      onTap: () {
                        if (widget.soundOn) SoundManager.playClick();
                        setState(() => _selectedChipValue = val);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(0.0, isSelected ? -6.0 : 0.0, 0.0),
                        child: Transform.scale(
                          scale: isSelected ? 1.12 : 1.0,
                          child: PokerChipWidget(value: val, selected: isSelected, size: 33.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),
                  ];
                }).toList()..removeLast(),
              ),
            ),
          ),
        ),
      ],
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
