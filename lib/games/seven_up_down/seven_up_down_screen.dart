import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../shared/widgets/bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/win_overlay_card.dart';
import 'package:lottie/lottie.dart';
import '../andar_bahar/widgets/player_widgets.dart';
import '../andar_bahar/widgets/chip_widgets.dart';
import '../andar_bahar/models/chip_models.dart';
import '../../utils/sound_manager.dart';



class SevenUpDownGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const SevenUpDownGameScreen({
    Key? key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  State<SevenUpDownGameScreen> createState() => _SevenUpDownGameScreenState();
}

class _SevenUpDownGameScreenState extends State<SevenUpDownGameScreen> with TickerProviderStateMixin {
  final math.Random _random = math.Random();
  
  // Game states
  int _selectedChipValue = 10;
  int _betOn2to6 = 0;
  int _betOn7 = 0;
  int _betOn8to12 = 0;
  
  int _lastBetOn2to6 = 0;
  int _lastBetOn7 = 0;
  int _lastBetOn8to12 = 0;
  
  bool _isRolling = false;
  int _dice1Value = 1;
  int _dice2Value = 1;
  int _diceSum = 2;
  
  int _timerSeconds = 10;
  Timer? _countdownTimer;

  bool _showOutcomeCard = false;
  double _lastWinMultiplier = 1.96;
  double _lastWinAmount = 0.0;
  bool _lastOutcomeWin = true;
  Timer? _outcomeTimer;

  // Active room users and chip flight collections
  int _activeUsersCount = 45;
  double _userWinAmount = 0.0;
  int _userWinTrigger = 0;
  int _triggerUser = 0;
  
  final List<FlyingChip> _flyingChips = [];
  final List<TableChip> _tableChips = [];

  // Mock Player Balances (consistent with Andar Bahar)
  double _billionaireBalance = 84500.0;
  double _richieBalance = 24500.0;
  double _highRollerBalance = 9800.0;
  double _masterBalance = 120500.0;
  double _proKingBalance = 41200.0;
  double _elitePlayerBalance = 6300.0;

  // Triggers for bet nudge animation
  int _triggerBillionaire = 0;
  int _triggerRichie = 0;
  int _triggerHighRoller = 0;
  int _triggerMaster = 0;
  int _triggerProKing = 0;
  int _triggerElitePlayer = 0;

  // Mock player bets tracking maps
  Map<String, double> _mockBets2to6 = {};
  Map<String, double> _mockBets7 = {};
  Map<String, double> _mockBets8to12 = {};

  // Mock player win variables
  double _billionaireWinAmount = 0.0;
  int _billionaireWinTrigger = 0;
  double _richieWinAmount = 0.0;
  int _richieWinTrigger = 0;
  double _highRollerWinAmount = 0.0;
  int _highRollerWinTrigger = 0;
  double _masterWinAmount = 0.0;
  int _masterWinTrigger = 0;
  double _proKingWinAmount = 0.0;
  int _proKingWinTrigger = 0;
  double _elitePlayerWinAmount = 0.0;
  int _elitePlayerWinTrigger = 0;

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
  
  // Animation controllers
  late AnimationController _lottieController;
  
  // History outcomes
  final List<int> _history = [9, 8, 9, 10, 10, 12, 11, 10, 8, 7, 7, 3];



  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _timerSeconds = 10;
      _userWinAmount = 0.0;
      _tableChips.clear();
      _flyingChips.clear();
      
      // Reset mock bets tracking maps
      _mockBets2to6.clear();
      _mockBets7.clear();
      _mockBets8to12.clear();

      // Reset win text amounts
      _billionaireWinAmount = 0.0;
      _richieWinAmount = 0.0;
      _highRollerWinAmount = 0.0;
      _masterWinAmount = 0.0;
      _proKingWinAmount = 0.0;
      _elitePlayerWinAmount = 0.0;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
          final int betCount = _random.nextInt(4) + 2;
          for (int i = 0; i < betCount; i++) {
            _simulateMockBets();
          }
        });
      } else {
        _countdownTimer?.cancel();
        _rollDice();
      }
    });
  }

  void _simulateMockBets() {
    if (_random.nextDouble() > 0.30) return;

    if (_random.nextDouble() > 0.60) {
      setState(() {
        _activeUsersCount += _random.nextBool() ? _random.nextInt(2) : -_random.nextInt(2);
        _activeUsersCount = _activeUsersCount.clamp(30, 60);
      });
    }

    final double betValue = [
      10, 10, 10, 10, 10,
      50, 50, 50, 50, 50,
      100, 500, 1000, 5000
    ][_random.nextInt(14)].toDouble();
    final int spotIndex = _random.nextInt(3);
    final String spot =
        spotIndex == 0 ? '2-6' : (spotIndex == 1 ? '7' : '8-12');

    final bool isOtherPlayer = _random.nextDouble() < 0.40;

    if (isOtherPlayer) {
      double startX = 0.95;
      double startY = 0.92;

      setState(() {
        if (spot == '2-6') {
          _betOn2to6 += betValue.toInt();
          _mockBets2to6['activeUsers'] = (_mockBets2to6['activeUsers'] ?? 0.0) + betValue;
        } else if (spot == '7') {
          _betOn7 += betValue.toInt();
          _mockBets7['activeUsers'] = (_mockBets7['activeUsers'] ?? 0.0) + betValue;
        } else {
          _betOn8to12 += betValue.toInt();
          _mockBets8to12['activeUsers'] = (_mockBets8to12['activeUsers'] ?? 0.0) + betValue;
        }

        _triggerChipFlight(
          spot: spot,
          startX: startX,
          startY: startY,
          chipColor: ChipSelectorWidget.getChipColor(betValue.toInt()),
          chipLabel: ChipSelectorWidget.getChipText(betValue.toInt()),
          chipValue: betValue.toInt(),
        );
      });
      return;
    }

    final bool isLeft = _random.nextBool();
    final int playerIndex = _random.nextInt(3);
    final String playerKey = isLeft ? 'L$playerIndex' : 'R$playerIndex';

    double startX = isLeft ? 0.05 : 0.95;
    double startY = 0.30 + playerIndex * 0.18;

    bool placeBet = false;
    if (isLeft) {
      if (playerIndex == 0 && _billionaireBalance >= betValue) {
        _billionaireBalance = math.max(0.0, _billionaireBalance - betValue);
        placeBet = true;
        _triggerBillionaire++;
      } else if (playerIndex == 1 && _richieBalance >= betValue) {
        _richieBalance = math.max(0.0, _richieBalance - betValue);
        placeBet = true;
        _triggerRichie++;
      } else if (playerIndex == 2 && _highRollerBalance >= betValue) {
        _highRollerBalance = math.max(0.0, _highRollerBalance - betValue);
        placeBet = true;
        _triggerHighRoller++;
      }
    } else {
      if (playerIndex == 0 && _masterBalance >= betValue) {
        _masterBalance = math.max(0.0, _masterBalance - betValue);
        placeBet = true;
        _triggerMaster++;
      } else if (playerIndex == 1 && _proKingBalance >= betValue) {
        _proKingBalance = math.max(0.0, _proKingBalance - betValue);
        placeBet = true;
        _triggerProKing++;
      } else if (playerIndex == 2 && _elitePlayerBalance >= betValue) {
        _elitePlayerBalance = math.max(0.0, _elitePlayerBalance - betValue);
        placeBet = true;
        _triggerElitePlayer++;
      }
    }

    if (placeBet) {
      setState(() {
        if (spot == '2-6') {
          _betOn2to6 += betValue.toInt();
          _mockBets2to6[playerKey] = (_mockBets2to6[playerKey] ?? 0.0) + betValue;
        } else if (spot == '7') {
          _betOn7 += betValue.toInt();
          _mockBets7[playerKey] = (_mockBets7[playerKey] ?? 0.0) + betValue;
        } else {
          _betOn8to12 += betValue.toInt();
          _mockBets8to12[playerKey] = (_mockBets8to12[playerKey] ?? 0.0) + betValue;
        }

        _triggerChipFlight(
          spot: spot,
          startX: startX,
          startY: startY,
          chipColor: ChipSelectorWidget.getChipColor(betValue.toInt()),
          chipLabel: ChipSelectorWidget.getChipText(betValue.toInt()),
          chipValue: betValue.toInt(),
        );
      });
    }
  }

  void _triggerChipFlight({
    required String spot,
    required double startX,
    required double startY,
    required Color chipColor,
    required String chipLabel,
    required int chipValue,
  }) {
    double endX = 0.5;
    double endY = 0.5;
    if (spot == '2-6') {
      endX = 0.22 + _random.nextDouble() * 0.12;
      endY = 0.40 + _random.nextDouble() * 0.12;
    } else if (spot == '7') {
      endX = 0.44 + _random.nextDouble() * 0.12;
      endY = 0.40 + _random.nextDouble() * 0.12;
    } else if (spot == '8-12') {
      endX = 0.64 + _random.nextDouble() * 0.12;
      endY = 0.40 + _random.nextDouble() * 0.12;
    }

    final newChip = FlyingChip(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      color: chipColor,
      label: chipLabel,
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
      value: chipValue,
    );

    setState(() => _flyingChips.add(newChip));

    newChip.controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _flyingChips.remove(newChip);
        _tableChips.add(TableChip(
          x: newChip.endX,
          y: newChip.endY,
          color: newChip.color,
          label: newChip.label,
          value: newChip.value,
        ));
      });
    });
  }

  void _placeBet(String spot) {
    if (_isRolling) return;
    if (_timerSeconds <= 0) return;
    if (widget.balance < _selectedChipValue) {
      _showErrorSnackBar('Insufficient balance!');
      return;
    }

    widget.onBalanceChanged(widget.balance - _selectedChipValue);
    _triggerUser++;

    setState(() {
      if (spot == '2-6') {
        _betOn2to6 += _selectedChipValue;
      } else if (spot == '7') {
        _betOn7 += _selectedChipValue;
      } else if (spot == '8-12') {
        _betOn8to12 += _selectedChipValue;
      }
    });

    _triggerChipFlight(
      spot: spot,
      startX: 0.05,
      startY: 0.92,
      chipColor: ChipSelectorWidget.getChipColor(_selectedChipValue),
      chipLabel: ChipSelectorWidget.getChipText(_selectedChipValue),
      chipValue: _selectedChipValue,
    );
    SoundManager.playClick();
  }


  void _rollDice() {
    if (_isRolling) return;
    
    // Check if user has placed any bets
    final totalBet = _betOn2to6 + _betOn7 + _betOn8to12;
    if (totalBet == 0) {
      _showErrorSnackBar('Please place a bet first!');
      return;
    }

    _countdownTimer?.cancel();
    setState(() {
      _isRolling = true;
    });

    // Save last bets for Repeat button
    _lastBetOn2to6 = _betOn2to6;
    _lastBetOn7 = _betOn7;
    _lastBetOn8to12 = _betOn8to12;

    // Start Lottie animation
    _lottieController.forward(from: 0.0);
    
    // Roll outcomes
    final d1 = _random.nextInt(6) + 1;
    final d2 = _random.nextInt(6) + 1;
    final sum = d1 + d2;

    // The cup starts lifting at value 0.22 (approx 880ms). Update values.
    Future.delayed(const Duration(milliseconds: 880), () {
      if (!mounted) return;
      setState(() {
        _dice1Value = d1;
        _dice2Value = d2;
        _diceSum = sum;
      });
    });

    // Evaluate bets at 3.0 seconds (giving enough time for lift + show)
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      _evaluateBets(sum);
    });
  }

  void _evaluateBets(int sum) {
    double winnings = 0.0;
    String winnerSpot = '';
    
    if (sum < 7) {
      winnerSpot = '2-6';
      winnings += _betOn2to6 * 2.0; // 1:1 payout
    } else if (sum == 7) {
      winnerSpot = '7';
      winnings += _betOn7 * 5.0; // 1:4 payout
    } else if (sum > 7) {
      winnerSpot = '8-12';
      winnings += _betOn8to12 * 2.0; // 1:1 payout
    }

    if (winnings > 0) {
      _userWinAmount = winnings;
      _userWinTrigger++;
      widget.onBalanceChanged(widget.balance + winnings);
      _triggerOutcomeOverlay(sum == 7 ? 5.0 : 2.0, winnings, true);
      _triggerWinningsFlight(
        spot: winnerSpot,
        targetX: 0.05,
        targetY: 0.92,
        value: winnings,
      );
    } else {
      _triggerOutcomeOverlay(0.0, 0.0, false);
    }

    final Map<String, double> winningBets = winnerSpot == '2-6'
        ? _mockBets2to6
        : (winnerSpot == '7' ? _mockBets7 : _mockBets8to12);
    final double payoutMultiplier = winnerSpot == '7' ? 5.0 : 2.0;

    winningBets.forEach((playerKey, betValue) {
      if (betValue > 0) {
        final double playerWinnings = betValue * payoutMultiplier;

        if (playerKey == 'activeUsers') {
          _triggerWinningsFlight(
              spot: winnerSpot,
              targetX: 0.95,
              targetY: 0.92,
              value: playerWinnings);
          return;
        }

        final bool isLeft = playerKey.startsWith('L');
        final int index = int.parse(playerKey.substring(1));
        if (isLeft) {
          if (index == 0) {
            _billionaireBalance += playerWinnings;
            _billionaireWinAmount = playerWinnings;
            _billionaireWinTrigger++;
          } else if (index == 1) {
            _richieBalance += playerWinnings;
            _richieWinAmount = playerWinnings;
            _richieWinTrigger++;
          } else {
            _highRollerBalance += playerWinnings;
            _highRollerWinAmount = playerWinnings;
            _highRollerWinTrigger++;
          }
        } else {
          if (index == 0) {
            _masterBalance += playerWinnings;
            _masterWinAmount = playerWinnings;
            _masterWinTrigger++;
          } else if (index == 1) {
            _proKingBalance += playerWinnings;
            _proKingWinAmount = playerWinnings;
            _proKingWinTrigger++;
          } else {
            _elitePlayerBalance += playerWinnings;
            _elitePlayerWinAmount = playerWinnings;
            _elitePlayerWinTrigger++;
          }
        }
        _triggerWinningsFlight(
            spot: winnerSpot,
            targetX: isLeft ? 0.05 : 0.95,
            targetY: 0.30 + index * 0.18,
            value: playerWinnings);
      }
    });


    setState(() {
      _history.insert(0, sum);
      if (_history.length > 12) _history.removeLast();
      
      // Clear current bets
      _betOn2to6 = 0;
      _betOn7 = 0;
      _betOn8to12 = 0;
      
      _isRolling = false;
    });

    _lottieController.reset();
    _startCountdown();
  }

  void _triggerWinningsFlight({
    required String spot,
    required double targetX,
    required double targetY,
    required double value,
  }) {
    final count = (value / 50).clamp(2, 6).toInt();
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (!mounted) return;
        double startX = 0.5;
        double startY = 0.5;
        if (spot == '2-6') {
          startX = 0.32;
          startY = 0.5;
        } else if (spot == '7') {
          startX = 0.5;
          startY = 0.5;
        } else if (spot == '8-12') {
          startX = 0.68;
          startY = 0.5;
        }

        final chipValue = (value / count).toInt();
        final chip = FlyingChip(
          startX: startX,
          startY: startY,
          endX: targetX,
          endY: targetY,
          color: Colors.amber,
          label: '₹$chipValue',
          controller: AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 650),
          ),
          value: chipValue,
        );

        setState(() => _flyingChips.add(chip));
        chip.controller.forward().then((_) {
          if (!mounted) return;
          setState(() {
            _flyingChips.remove(chip);
          });
        });
      });
    }
  }

  void _showActiveUsersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Container(
            width: 280.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1224),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 15.0, spreadRadius: 2.0)
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Color(0xFF00E5FF), size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'Active Room Players',
                          style: GoogleFonts.pressStart2p(
                            textStyle: const TextStyle(color: Colors.white, fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white70, size: 18.0),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 16.0),
                const SizedBox(height: 4.0),
                Text(
                  'There are currently $_activeUsersCount active players betting at this table.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.0, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: const Column(
                    children: [
                      _ActiveUserRow7(name: 'Satyamsk (You)', isMe: true),
                      _ActiveUserRow7(name: 'Billionaire', isMe: false),
                      _ActiveUserRow7(name: 'Richie', isMe: false),
                      _ActiveUserRow7(name: 'Master', isMe: false),
                      _ActiveUserRow7(name: 'ProKing', isMe: false),
                      _ActiveUserRow7(name: 'Elite Player', isMe: false),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
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

  void _repeatLastBet() {

    if (_isRolling) return;
    final totalLastBet = _lastBetOn2to6 + _lastBetOn7 + _lastBetOn8to12;
    if (totalLastBet == 0) return;

    if (widget.balance < totalLastBet) {
      _showErrorSnackBar('Insufficient balance to repeat bet!');
      return;
    }

    widget.onBalanceChanged(widget.balance - totalLastBet);
    setState(() {
      _betOn2to6 = _lastBetOn2to6;
      _betOn7 = _lastBetOn7;
      _betOn8to12 = _lastBetOn8to12;
    });
  }

  void _clearBets() {
    if (_isRolling) return;
    final totalBet = _betOn2to6 + _betOn7 + _betOn8to12;
    if (totalBet == 0) return;

    widget.onBalanceChanged(widget.balance + totalBet);
    setState(() {
      _betOn2to6 = 0;
      _betOn7 = 0;
      _betOn8to12 = 0;
    });
  }

  void _doubleBets() {
    if (_isRolling) return;
    final totalBet = _betOn2to6 + _betOn7 + _betOn8to12;
    if (totalBet == 0) return;

    if (widget.balance < totalBet) {
      _showErrorSnackBar('Insufficient balance to double bet!');
      return;
    }

    widget.onBalanceChanged(widget.balance - totalBet);
    setState(() {
      _betOn2to6 *= 2;
      _betOn7 *= 2;
      _betOn8to12 *= 2;
    });
  }

  void _halveBets() {
    if (_isRolling) return;
    final totalBet = _betOn2to6 + _betOn7 + _betOn8to12;
    if (totalBet == 0) return;

    final oldBet2to6 = _betOn2to6;
    final oldBet7 = _betOn7;
    final oldBet8to12 = _betOn8to12;

    final newBet2to6 = oldBet2to6 ~/ 2;
    final newBet7 = oldBet7 ~/ 2;
    final newBet8to12 = oldBet8to12 ~/ 2;

    final returned = (oldBet2to6 - newBet2to6) + (oldBet7 - newBet7) + (oldBet8to12 - newBet8to12);

    widget.onBalanceChanged(widget.balance + returned);
    setState(() {
      _betOn2to6 = newBet2to6;
      _betOn7 = newBet7;
      _betOn8to12 = newBet8to12;
    });
  }



  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFF3D00),
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF070B1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: w,
            height: h,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/7updown_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // 1. Top Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopHeader(),
                ),

                // 2. Left mock players column
                Positioned(
                  top: h * 0.20,
                  left: w * 0.02,
                  child: Column(
                    children: [
                      MockPlayerWidget(
                        name: 'Billionaire',
                        balance: _billionaireBalance,
                        isLeft: true,
                        iconData: Icons.diamond,
                        color: const Color(0xFFE040FB),
                        showNameTag: false,
                        avatarPath: 'assets/userprofile/user1.png',
                        betTrigger: _triggerBillionaire,
                        winAmount: _billionaireWinAmount,
                        winTrigger: _billionaireWinTrigger,
                      ),
                      SizedBox(height: h * 0.045),
                      MockPlayerWidget(
                        name: 'Richie',
                        balance: _richieBalance,
                        isLeft: true,
                        iconData: Icons.monetization_on,
                        color: const Color(0xFFFF5252),
                        showNameTag: false,
                        avatarPath: 'assets/userprofile/user2.png',
                        betTrigger: _triggerRichie,
                        winAmount: _richieWinAmount,
                        winTrigger: _richieWinTrigger,
                      ),
                      SizedBox(height: h * 0.045),
                      MockPlayerWidget(
                        name: 'High Roller',
                        balance: _highRollerBalance,
                        isLeft: true,
                        iconData: Icons.star,
                        color: const Color(0xFFFFD740),
                        showNameTag: false,
                        avatarPath: 'assets/userprofile/user3.png',
                        betTrigger: _triggerHighRoller,
                        winAmount: _highRollerWinAmount,
                        winTrigger: _highRollerWinTrigger,
                      ),
                    ],
                  ),
                ),

                // 3. Right mock players column
                Positioned(
                  top: h * 0.20,
                  right: w * 0.02,
                  child: Column(
                    children: [
                      MockPlayerWidget(
                        name: 'Master',
                        balance: _masterBalance,
                        isLeft: false,
                        iconData: Icons.workspace_premium,
                        color: const Color(0xFF69F0AE),
                        showNameTag: false,
                        avatarPath: 'assets/userprofile/user4.png',
                        betTrigger: _triggerMaster,
                        winAmount: _masterWinAmount,
                        winTrigger: _masterWinTrigger,
                      ),
                      SizedBox(height: h * 0.045),
                      MockPlayerWidget(
                        name: 'Pro King',
                        balance: _proKingBalance,
                        isLeft: false,
                        iconData: Icons.bolt,
                        color: const Color(0xFF26C6DA),
                        showNameTag: false,
                        avatarPath: 'assets/userprofile/user5.png',
                        betTrigger: _triggerProKing,
                        winAmount: _proKingWinAmount,
                        winTrigger: _proKingWinTrigger,
                      ),
                      SizedBox(height: h * 0.045),
                      MockPlayerWidget(
                        name: 'Elite Player',
                        balance: _elitePlayerBalance,
                        isLeft: false,
                        iconData: Icons.auto_awesome,
                        color: const Color(0xFF00B0FF),
                        showNameTag: false,
                        avatarPath: 'assets/userprofile/user6.png',
                        betTrigger: _triggerElitePlayer,
                        winAmount: _elitePlayerWinAmount,
                        winTrigger: _elitePlayerWinTrigger,
                      ),
                    ],
                  ),
                ),

                // 4. Bottom User (Bottom Left)
                Positioned(
                  bottom: h * 0.05,
                  left: w * 0.02,
                  child: UserAvatarWidget(
                    balance: widget.balance,
                    avatarPath: 'assets/userprofile/user7.png',
                    betTrigger: _triggerUser,
                    winAmount: _userWinAmount,
                    winTrigger: _userWinTrigger,
                  ),
                ),

                // 4b. Bottom Active Users Count (Bottom Right)
                Positioned(
                  bottom: h * 0.05,
                  right: w * 0.02,
                  child: GestureDetector(
                    onTap: _showActiveUsersDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0x99000000),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.0),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 4.0, offset: Offset(0.0, 2.0))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: Color(0xFF00E5FF),
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 7.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '$_activeUsersCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Central Gameplay / Betting Area
                Positioned(
                  top: h * 0.16,
                  left: w * 0.16,
                  right: w * 0.16,
                  bottom: h * 0.18,
                  child: _buildGameBoard(),
                ),

                // 7. Chip Selector
                Positioned(
                  bottom: h * 0.03,
                  left: w * 0.32,
                  right: w * 0.32,
                  child: ChipSelectorWidget(
                    selectedChipValue: _selectedChipValue,
                    height: h,
                    onChipSelected: (val) {
                      setState(() => _selectedChipValue = val);
                      SoundManager.playClick();
                    },
                  ),
                ),

                // 8. Static Table Chips
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: _tableChips.map((chip) {
                        return Positioned(
                          left: w * chip.x - 12.0,
                          top: h * chip.y - 12.0,
                          child: PokerChipWidget(
                            value: chip.value,
                            size: 24.0,
                            selected: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 8b. Flying Chips Overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: _flyingChips.map((chip) {
                        return Positioned.fill(
                          child: AnimatedBuilder(
                            animation: chip.controller,
                            builder: (context, child) {
                              final double t = chip.controller.value;
                              final double currentX =
                                  chip.startX + (chip.endX - chip.startX) * t;
                              final double currentY =
                                  chip.startY + (chip.endY - chip.startY) * t;
                              return Stack(
                                children: [
                                  Positioned(
                                    left: currentX * w - 12.0,
                                    top: currentY * h - 12.0,
                                    child: PokerChipWidget(
                                      value: chip.value,
                                      size: 24.0,
                                      selected: false,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 10. Lottie 10-sec countdown
                if (!_isRolling &&
                    _timerSeconds <= 10 &&
                    _timerSeconds > 3)
                  Positioned(
                    left: w * 0.66,
                    top: h * 0.04,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 130.0,
                        height: 52.0,
                        child: Lottie.asset(
                          'assets/10_second_countdown_timer.json',
                          repeat: false,
                        ),
                      ),
                    ),
                  ),

                // 11. Lottie last-3-sec countdown (and dealing/winner loop phase)
                if ((!_isRolling && _timerSeconds <= 3 && _timerSeconds > 0) ||
                    _isRolling)
                  Positioned(
                    left: w * 0.66,
                    top: h * 0.04,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 130.0,
                        height: 52.0,
                        child: Lottie.asset(
                          'assets/10_second_countdown_timer_react_end_loop.json',
                          repeat: true,
                        ),
                      ),
                    ),
                  ),

                // 12. Center Lottie 3-sec warning animation
                if (!_isRolling &&
                    _timerSeconds <= 3 &&
                    _timerSeconds > 0)
                  Align(
                    alignment: Alignment.center,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 140.0,
                        height: 140.0,
                        child: Lottie.asset(
                          'assets/count_down_red_and_grey_3_to_1.json',
                          repeat: false,
                        ),
                      ),
                    ),
                  ),

                // 13. Win/Lose Overlay Card centered in playfield
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
        },
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: const Color(0xFF07021C),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: widget.onBackPressed,
            child: Container(
              width: 53.0,
              height: 41.0,
              decoration: BoxDecoration(
                color: const Color(0xFF3A4142),
                borderRadius: BorderRadius.circular(8.0),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/icons/home_icon.png',
                width: 23.0,
                height: 23.0,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16.0),

          // Statistics/Trend Icon
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: const BoxDecoration(color: Color(0xFF2C256B), shape: BoxShape.circle),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 16.0),
          ),
          const Spacer(),

          // Recent History Bar
          Row(
            children: _history.map((val) {
              final isSeven = val == 7;
              final isUnder = val < 7;
              Color badgeColor = const Color(0xFF0D5102); // Over 7 (Green)
              if (isSeven) {
                badgeColor = const Color(0xFF0B32A7); // Lucky 7 (Blue)
              } else if (isUnder) {
                badgeColor = const Color(0xFFA7100B); // Under 7 (Red)
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 25.0,
                height: 20.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '$val',
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),

          // Info and Settings Icon
          const Icon(Icons.info_outline, color: Colors.grey, size: 20.0),
          const SizedBox(width: 12.0),
          const Icon(Icons.settings, color: Colors.grey, size: 20.0),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    final bool hasBet2to6 = _betOn2to6 > 0;
    final bool hasBet7 = _betOn7 > 0;
    final bool hasBet8to12 = _betOn8to12 > 0;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151821),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _placeBet('2-6'),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF590D0B),
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(
                              color: hasBet2to6 ? const Color(0xFF24EE89) : Colors.transparent,
                              width: hasBet2to6 ? 2.5 : 1.0,
                            ),
                            boxShadow: hasBet2to6 ? [
                              BoxShadow(
                                color: const Color(0xFF24EE89).withOpacity(0.35),
                                blurRadius: 10.0,
                                spreadRadius: 1.0,
                              )
                            ] : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.04,
                                child: Text(
                                  '2-6',
                                  style: GoogleFonts.inter(
                                    fontSize: 64.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '7 DOWN',
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '2-6',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(color: Colors.white, fontSize: 32.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    '2.0x Payout',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  if (_betOn2to6 > 0) _buildBetChipsBadge(_betOn2to6),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _placeBet('7'),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF04334A),
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(
                              color: hasBet7 ? const Color(0xFF24EE89) : Colors.transparent,
                              width: hasBet7 ? 2.5 : 1.0,
                            ),
                            boxShadow: hasBet7 ? [
                              BoxShadow(
                                color: const Color(0xFF24EE89).withOpacity(0.35),
                                blurRadius: 10.0,
                                spreadRadius: 1.0,
                              )
                            ] : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.04,
                                child: Text(
                                  '7',
                                  style: GoogleFonts.inter(
                                    fontSize: 64.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'LUCKY',
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '7',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(color: Color(0xFFFFD700), fontSize: 34.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    '5.0x Payout',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  if (_betOn7 > 0) _buildBetChipsBadge(_betOn7),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _placeBet('8-12'),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D5102),
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(
                              color: hasBet8to12 ? const Color(0xFF24EE89) : Colors.transparent,
                              width: hasBet8to12 ? 2.5 : 1.0,
                            ),
                            boxShadow: hasBet8to12 ? [
                              BoxShadow(
                                color: const Color(0xFF24EE89).withOpacity(0.35),
                                blurRadius: 10.0,
                                spreadRadius: 1.0,
                              )
                            ] : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.04,
                                child: Text(
                                  '8-12',
                                  style: GoogleFonts.inter(
                                    fontSize: 64.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '7 UP',
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '8-12',
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(color: Colors.white, fontSize: 32.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    '2.0x Payout',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  if (_betOn8to12 > 0) _buildBetChipsBadge(_betOn8to12),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 240.0,
                      height: 240.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Lottie.asset(
                            'assets/7updown/seven_up_down_anim.json',
                            controller: _lottieController,
                            fit: BoxFit.contain,
                            onWarning: (w) {},
                          ),
                          AnimatedBuilder(
                            animation: _lottieController,
                            builder: (context, child) {
                              final double value = _lottieController.value;
                              final double opacity = (value >= 0.22)
                                  ? ((value - 0.22) / 0.08).clamp(0.0, 1.0)
                                  : 0.0;
                              if (opacity == 0.0) return const SizedBox.shrink();
                              return Opacity(
                                opacity: opacity,
                                child: child,
                              );
                            },
                            child: Positioned(
                              bottom: 45.0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildDiceWidget(_dice1Value),
                                        const SizedBox(width: 12.0),
                                        _buildDiceWidget(_dice2Value),
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: Text(
                                        'Total = $_diceSum',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickActionBtn('CLEAR', _clearBets, color: const Color(0xFFE91E63)),
              const SizedBox(width: 8.0),
              _buildQuickActionBtn('1/2', _halveBets),
              const SizedBox(width: 8.0),
              _buildQuickActionBtn('2X', _doubleBets),
              const SizedBox(width: 8.0),
              _buildQuickActionBtn('REPEAT', _repeatLastBet, color: const Color(0xFF00B0FF)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiceWidget(int value) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 2))],
      ),
      child: CustomPaint(
        painter: DiceDotsPainter(dots: value),
      ),
    );
  }

  Widget _buildBetChipsBadge(int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2.0)],
      ),
      child: Text(
        '₹$amount',
        style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: color?.withOpacity(0.5) ?? const Color(0xFF2C2F36), width: 1.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color != null ? Colors.white : const Color(0xFF90A4AE),
            fontSize: 9.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class DiceDotsPainter extends CustomPainter {
  final int dots;
  DiceDotsPainter({required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    void drawDot(double cx, double cy) {
      canvas.drawCircle(Offset(cx, cy), w * 0.08, paint);
    }

    if (dots == 1) {
      drawDot(w / 2, h / 2);
    } else if (dots == 2) {
      drawDot(w * 0.25, h * 0.25);
      drawDot(w * 0.75, h * 0.75);
    } else if (dots == 3) {
      drawDot(w * 0.25, h * 0.25);
      drawDot(w / 2, h / 2);
      drawDot(w * 0.75, h * 0.75);
    } else if (dots == 4) {
      drawDot(w * 0.25, h * 0.25);
      drawDot(w * 0.75, h * 0.25);
      drawDot(w * 0.25, h * 0.75);
      drawDot(w * 0.75, h * 0.75);
    } else if (dots == 5) {
      drawDot(w * 0.25, h * 0.25);
      drawDot(w * 0.75, h * 0.25);
      drawDot(w / 2, h / 2);
      drawDot(w * 0.25, h * 0.75);
      drawDot(w * 0.75, h * 0.75);
    } else if (dots == 6) {
      drawDot(w * 0.25, h * 0.25);
      drawDot(w * 0.75, h * 0.25);
      drawDot(w * 0.25, h / 2);
      drawDot(w * 0.75, h / 2);
      drawDot(w * 0.25, h * 0.75);
      drawDot(w * 0.75, h * 0.75);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ActiveUserRow7 extends StatelessWidget {
  final String name;
  final bool isMe;

  const _ActiveUserRow7({required this.name, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            name,
            style: TextStyle(
              color: isMe ? const Color(0xFF00E676) : Colors.white70,
              fontSize: 10.0,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            isMe ? 'BETTING' : 'ONLINE',
            style: TextStyle(
              color: isMe ? const Color(0xFF00E676) : Colors.white38,
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

