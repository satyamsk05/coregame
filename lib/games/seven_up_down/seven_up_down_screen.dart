import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/win_overlay_card.dart';
import 'package:lottie/lottie.dart';

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
  int _selectedChipValue = 50;
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
  
  int _timerSeconds = 15;
  Timer? _countdownTimer;

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
  
  // Animation controllers
  late AnimationController _lottieController;
  
  // History outcomes
  final List<int> _history = [9, 8, 9, 10, 10, 12, 11, 10, 8, 7, 7, 3];
  
  // Mock player avatars placing bets automatically
  final List<Map<String, dynamic>> _leftPlayers = [
    {'name': 'Richie Rich', 'balance': 80761.70, 'betSpot': '2-6', 'betAmount': 500},
    {'name': 'Millionaire', 'balance': 67853.55, 'betSpot': '2-6', 'betAmount': 200},
    {'name': 'name902763', 'balance': 48608.99, 'betSpot': '7', 'betAmount': 0},
  ];
  
  final List<Map<String, dynamic>> _rightPlayers = [
    {'name': 'Human Calculator', 'balance': 358.54, 'betSpot': '8-12', 'betAmount': 0},
    {'name': 'name817773', 'balance': 59503.12, 'betSpot': '8-12', 'betAmount': 5000},
    {'name': 'name292405', 'balance': 5238.95, 'betSpot': '8-12', 'betAmount': 100},
  ];

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
      _timerSeconds = 15;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds == 0) {
        _countdownTimer?.cancel();
        _rollDice();
      } else {
        setState(() {
          _timerSeconds--;
        });
        // Mock players placing bets during countdown
        if (_timerSeconds % 3 == 0) {
          _placeMockBets();
        }
      }
    });
  }

  void _placeMockBets() {
    setState(() {
      for (var player in _leftPlayers) {
        if (_random.nextBool()) {
          player['betAmount'] = (player['betAmount'] + [10, 50, 100][_random.nextInt(3)]).clamp(0, 10000);
        }
      }
      for (var player in _rightPlayers) {
        if (_random.nextBool()) {
          player['betAmount'] = (player['betAmount'] + [50, 100, 500][_random.nextInt(3)]).clamp(0, 10000);
        }
      }
    });
  }

  void _placeBet(String spot) {
    if (_isRolling) return;
    if (widget.balance < _selectedChipValue) {
      _showErrorSnackBar('Insufficient balance!');
      return;
    }

    widget.onBalanceChanged(widget.balance - _selectedChipValue);
    setState(() {
      if (spot == '2-6') {
        _betOn2to6 += _selectedChipValue;
      } else if (spot == '7') {
        _betOn7 += _selectedChipValue;
      } else if (spot == '8-12') {
        _betOn8to12 += _selectedChipValue;
      }
    });
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
    
    if (sum < 7) {
      winnings += _betOn2to6 * 2.0; // 1:1 payout
    } else if (sum == 7) {
      winnings += _betOn7 * 5.0; // 1:4 payout
    } else if (sum > 7) {
      winnings += _betOn8to12 * 2.0; // 1:1 payout
    }

    if (winnings > 0) {
      widget.onBalanceChanged(widget.balance + winnings);
      _triggerOutcomeOverlay(sum == 7 ? 5.0 : 2.0, winnings, true);
    } else {
      _triggerOutcomeOverlay(0.0, 0.0, false);
    }

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F1118),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/7updown_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.82,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header: Navigation & Recent History
              _buildTopHeader(),

              // Main Playfield split layout
              Expanded(
                child: Row(
                  children: [
                    // Left Avatars Column
                    _buildAvatarsColumn(_leftPlayers),

                    // Middle Gaming Board Table
                    Expanded(
                      child: _buildGameBoard(),
                    ),

                    // Right Avatars Column
                    _buildAvatarsColumn(_rightPlayers),
                  ],
                ),
              ),

              // Bottom chip selector & control panel
              _buildBottomControls(),
            ],
          ),
        ),
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
                'assets/home_icon.png',
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

  Widget _buildAvatarsColumn(List<Map<String, dynamic>> players) {
    return Container(
      width: 75.0,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((player) {
          return Column(
            children: [
              CircleAvatar(
                radius: 18.0,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.grey[200], size: 18.0),
              ),
              const SizedBox(height: 2.0),
              Text(
                player['name'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 8.0),
              ),
              Text(
                '₹${player['balance'].toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 8.0, fontWeight: FontWeight.bold),
              ),
              if (player['betAmount'] > 0)
                Container(
                  margin: const EdgeInsets.only(top: 2.0),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                  decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(4.0)),
                  child: Text(
                    '₹${player['betAmount']}',
                    style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(builder: (context, constraints) {
      final double height = constraints.maxHeight;

      final bool hasBet2to6 = _betOn2to6 > 0;
      final bool hasBet7 = _betOn7 > 0;
      final bool hasBet8to12 = _betOn8to12 > 0;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF151821), // BC.Game Board Background
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Table Split bet zones
            Row(
              children: [
                // 2-6 (7 Down)
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
                          // Faint Background Text
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

                // 7 (Center Zone)
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
                          // Faint Background Text
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
                                'LUCKY 7',
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

                // 8-12 (7 Up)
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
                          // Faint Background Text
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

            // Centered Lottie Shaker & Reveal
            Center(
              child: IgnorePointer(
                child: SizedBox(
                  width: 240.0,
                  height: 240.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Lottie.asset(
                        'assets/7updown/Comp 1.json',
                        controller: _lottieController,
                        fit: BoxFit.contain,
                        onWarning: (w) {},
                      ),
                      // Dice overlay: visible when the cup starts lifting (value >= 0.22)
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
                          bottom: 45.0, // Aligned with the center of the base table in Lottie
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

            // Timer display badge
            Positioned(
              top: 12.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1118).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF3BC113).withOpacity(0.4), width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF3BC113), size: 13.0),
                    const SizedBox(width: 6.0),
                    Text(
                      'Betting: $_timerSeconds s',
                      style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
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
    });
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

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFF11141E), // BC.Game Dark Bottom Bar
      child: Row(
        children: [
          // Player balance & avatar badge
          Row(
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
                ),
                child: const Text('₹', style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('BALANCE', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 8.0, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Text(
                    '₹${widget.balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Quick Action buttons: CLEAR, 1/2, 2X
          Row(
            children: [
              _buildQuickActionBtn('CLEAR', _clearBets, color: const Color(0xFFE91E63)),
              const SizedBox(width: 4.0),
              _buildQuickActionBtn('1/2', _halveBets),
              const SizedBox(width: 4.0),
              _buildQuickActionBtn('2X', _doubleBets),
            ],
          ),
          const SizedBox(width: 12.0),

          // Chips selector row
          Row(
            children: [50, 100, 500, 1000].map((val) {
              final isSelected = _selectedChipValue == val;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedChipValue = val;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: isSelected ? 48.0 : 40.0,
                  height: isSelected ? 48.0 : 40.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF24EE89) : Colors.transparent,
                      width: isSelected ? 2.5 : 0.0,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF24EE89).withOpacity(0.5),
                        blurRadius: 8.0,
                        spreadRadius: 1.0,
                      )
                    ] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99.0),
                    child: Image.asset(
                      'assets/chip_$val.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),

          // Repeat & bet controls
          Row(
            children: [
              GestureDetector(
                onTap: _repeatLastBet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F36),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: const Color(0xFF424752), width: 1.0),
                  ),
                  child: const Text('REPEAT', style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: _rollDice,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 9.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3BC113), Color(0xFF00C853)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withOpacity(0.35),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Text('ROLL', style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
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
