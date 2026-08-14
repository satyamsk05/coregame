import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  
  int _timerSeconds = 15;
  Timer? _countdownTimer;
  
  // Animation controllers
  late AnimationController _shakerController;
  late AnimationController _diceRevealController;
  
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
    _shakerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _diceRevealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakerController.dispose();
    _diceRevealController.dispose();
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
      _startCountdown(); // Restart timer if no bet placed
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

    // Shake animation
    _shakerController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _shakerController.stop();
      
      // Roll outcomes
      final d1 = _random.nextInt(6) + 1;
      final d2 = _random.nextInt(6) + 1;
      final sum = d1 + d2;

      setState(() {
        _dice1Value = d1;
        _dice2Value = d2;
        _diceSum = sum;
      });

      // Lift dome to reveal
      _diceRevealController.forward(from: 0.0);

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        _evaluateBets(sum);
      });
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
      _showWinNotification(winnings);
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

    _diceRevealController.reverse();
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

  void _showWinNotification(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 24.0),
              const SizedBox(width: 12.0),
              Text(
                'You Won ₹${amount.toStringAsFixed(2)}!',
                style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
      backgroundColor: const Color(0xFF0F0736),
      body: SafeArea(
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
              padding: const EdgeInsets.all(6.0),
              decoration: const BoxDecoration(color: Color(0xFF2C256B), shape: BoxShape.circle),
              child: const Icon(Icons.home, color: Colors.white, size: 16.0),
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
              Color color = Colors.green;
              if (isSeven) {
                color = Colors.blue;
              } else if (isUnder) {
                color = Colors.red;
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 22.0,
                height: 22.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '$val',
                  style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
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

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF4C1060),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: const Color(0xFFFFD700), width: 3.0),
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
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        border: Border(right: BorderSide(color: Color(0xFFFFD700), width: 1.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '2-6',
                            style: TextStyle(color: Colors.white, fontSize: 32.0, fontWeight: FontWeight.w900),
                          ),
                          const Text('1:1 Payout', style: TextStyle(color: Colors.white70, fontSize: 10.0)),
                          const SizedBox(height: 10.0),
                          if (_betOn2to6 > 0) _buildBetChipsBadge(_betOn2to6),
                        ],
                      ),
                    ),
                  ),
                ),

                // 7 (Center Zone)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _placeBet('7'),
                    child: Container(
                      color: Colors.black26,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '7',
                            style: TextStyle(color: Color(0xFFFFD700), fontSize: 36.0, fontWeight: FontWeight.w900),
                          ),
                          const Text('1:4 Payout', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10.0)),
                          const SizedBox(height: 10.0),
                          if (_betOn7 > 0) _buildBetChipsBadge(_betOn7),
                        ],
                      ),
                    ),
                  ),
                ),

                // 8-12 (7 Up)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _placeBet('8-12'),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        border: Border(left: BorderSide(color: Color(0xFFFFD700), width: 1.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '8-12',
                            style: TextStyle(color: Colors.white, fontSize: 32.0, fontWeight: FontWeight.w900),
                          ),
                          const Text('1:1 Payout', style: TextStyle(color: Colors.white70, fontSize: 10.0)),
                          const SizedBox(height: 10.0),
                          if (_betOn8to12 > 0) _buildBetChipsBadge(_betOn8to12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Top center: Dice Shaker Dome cup representation
            Positioned(
              top: 10.0,
              child: AnimatedBuilder(
                animation: _shakerController,
                builder: (context, child) {
                  final double angle = math.sin(_shakerController.value * math.pi * 10) * 0.1;
                  return Transform.rotate(
                    angle: _isRolling ? angle : 0.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 55.0,
                  height: 55.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2024),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4.0)],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.blur_on, color: Colors.orange, size: 28.0),
                ),
              ),
            ),

            // Timer display badge
            Positioned(
              top: 70.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12.0)),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.amber, size: 12.0),
                    const SizedBox(width: 4.0),
                    Text(
                      'Betting: $_timerSeconds s',
                      style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Dice reveal animation popup
            if (_isRolling)
              AnimatedBuilder(
                animation: _diceRevealController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _diceRevealController.value,
                    child: Opacity(
                      opacity: _diceRevealController.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0736).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFFFD700), width: 2.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDiceWidget(_dice1Value),
                          const SizedBox(width: 16.0),
                          _buildDiceWidget(_dice2Value),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Total = $_diceSum',
                        style: GoogleFonts.alfaSlabOne(
                          textStyle: const TextStyle(color: Color(0xFFFFD700), fontSize: 16.0, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
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
      color: const Color(0xFF07021C),
      child: Row(
        children: [
          // Player balance & avatar badge
          Row(
            children: [
              CircleAvatar(
                radius: 14.0,
                backgroundColor: Colors.orange,
                child: const Text('₹', style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance', style: TextStyle(color: Colors.grey, fontSize: 8.0)),
                  Text(
                    '₹${widget.balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Chips selector row
          Row(
            children: [10, 50, 100, 500, 1000, 5000].map((val) {
              final isSelected = _selectedChipValue == val;
              String label = '$val';
              if (val >= 1000) {
                label = '${(val / 1000).toStringAsFixed(0)}k';
              }
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedChipValue = val;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 32.0,
                  height: 32.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : const Color(0xFF2C256B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: isSelected ? 2.0 : 1.0),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2.0)],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3138),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text('REPEAT', style: TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: _rollDice,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text('ROLL', style: TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
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
