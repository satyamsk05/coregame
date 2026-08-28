import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/widgets/bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/win_overlay_card.dart';

class KenoGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const KenoGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<KenoGameScreen> createState() => _KenoGameScreenState();
}

class _KenoGameScreenState extends State<KenoGameScreen> with SingleTickerProviderStateMixin {
  final Set<int> _selectedNumbers = {};
  final List<int> _drawnNumbers = [];
  bool _isDrawing = false;
  
  final _betController = TextEditingController(text: '10.0');
  
  // Auto Bet and Tab States
  String _selectedTab = 'Manual'; // 'Manual', 'Auto', 'Advanced'
  bool _isAutoRunning = false;
  int _autoBetCountRemaining = 0;
  final _autoBetCountController = TextEditingController(text: '0'); // 0 = infinite
  
  bool _onWinIncrease = false;
  double _onWinIncreasePct = 0.0;
  final _onWinIncreaseController = TextEditingController(text: '0');
  
  bool _onLossIncrease = false;
  double _onLossIncreasePct = 0.0;
  final _onLossIncreaseController = TextEditingController(text: '0');
  
  double _baseBetAmount = 10.0;
  double _accumulatedProfitLoss = 0.0;
  
  final _stopProfitController = TextEditingController(text: '0');
  final _stopLossController = TextEditingController(text: '0');
  
  String _selectedStrategy = 'Martingale'; // Martingale, Paroli
  final double _strategyMultiplier = 2.0;

  int _hitsCount = 0;
  double _winAmount = 0.0;
  bool _showWinOverlay = false;
  String _statusText = 'SELECT 1 TO 12 SPOTS';

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

  // Animation controller for particle effects and overlays
  late AnimationController _animationController;
  final List<CoinParticle> _particles = [];
  Timer? _drawTimer;
  final Random _random = Random();

  // Presets for bets
  final List<double> _betPresets = [0.5, 1.0, 5.0, 10.0, 25.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _animationController.addListener(() {
      _updateParticles();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _drawTimer?.cancel();
    _animationController.dispose();
    _betController.dispose();
    _autoBetCountController.dispose();
    _onWinIncreaseController.dispose();
    _onLossIncreaseController.dispose();
    _stopProfitController.dispose();
    _stopLossController.dispose();
    super.dispose();
  }

  // Payout multiplier table
  Map<int, double> getPayTable(int spots) {
    switch (spots) {
      case 1:
        return {1: 3.0};
      case 2:
        return {1: 1.0, 2: 9.0};
      case 3:
        return {2: 2.0, 3: 16.0};
      case 4:
        return {2: 1.0, 3: 3.0, 4: 50.0};
      case 5:
        return {2: 1.0, 3: 2.0, 4: 15.0, 5: 250.0};
      case 6:
        return {3: 2.0, 4: 7.0, 5: 60.0, 6: 1000.0};
      case 7:
        return {3: 1.0, 4: 4.0, 5: 20.0, 6: 250.0, 7: 3000.0};
      case 8:
        return {4: 3.0, 5: 10.0, 6: 50.0, 7: 1000.0, 8: 10000.0};
      case 9:
        return {4: 2.0, 5: 6.0, 6: 25.0, 7: 150.0, 8: 2500.0, 9: 15000.0};
      case 10:
        return {0: 1.0, 5: 4.0, 6: 15.0, 7: 40.0, 8: 300.0, 9: 4000.0, 10: 20000.0};
      case 11:
        return {0: 1.0, 5: 2.0, 6: 10.0, 7: 25.0, 8: 150.0, 9: 1500.0, 10: 10000.0, 11: 25000.0};
      case 12:
        return {0: 1.0, 6: 5.0, 7: 15.0, 8: 50.0, 9: 250.0, 10: 1000.0, 11: 10000.0, 12: 50000.0};
      default:
        return {};
    }
  }

  void _onNumberTapped(int number) {
    if (_isDrawing) return;

    setState(() {
      _showWinOverlay = false;
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
      } else {
        if (_selectedNumbers.length >= 12) {
          _statusText = 'MAX 12 SPOTS ALLOWED!';
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isDrawing) {
              setState(() {
                _statusText = 'SELECT 1 TO 12 SPOTS';
              });
            }
          });
          return;
        }
        _selectedNumbers.add(number);
      }

      if (_selectedNumbers.isEmpty) {
        _statusText = 'SELECT 1 TO 12 SPOTS';
      } else {
        _statusText = 'SPOTS SELECTED: ${_selectedNumbers.length}';
      }
    });
  }

  void _quickPick() {
    if (_isDrawing) return;

    setState(() {
      _showWinOverlay = false;
      _selectedNumbers.clear();
      final List<int> allNumbers = List.generate(80, (i) => i + 1);
      allNumbers.shuffle(_random);
      _selectedNumbers.addAll(allNumbers.take(12));
      _statusText = 'SPOTS SELECTED: 12 (QUICK PICK)';
    });
  }

  void _clearSelection() {
    if (_isDrawing) return;

    setState(() {
      _showWinOverlay = false;
      _selectedNumbers.clear();
      _statusText = 'SELECT 1 TO 12 SPOTS';
    });
  }

  void _startDrawing() {
    if (_isDrawing || _selectedNumbers.isEmpty) return;

    final double bet = double.tryParse(_betController.text) ?? 10.0;

    if (widget.balance < bet) {
      _showErrorDialog('INSUFFICIENT BALANCE', 'Please recharge from the shop in the lobby.');
      setState(() {
        _isAutoRunning = false;
      });
      return;
    }

    // Deduct bet amount
    widget.onBalanceChanged(widget.balance - bet);

    setState(() {
      _isDrawing = true;
      _showWinOverlay = false;
      _drawnNumbers.clear();
      _hitsCount = 0;
      _winAmount = 0.0;
      _statusText = 'DRAWING IN PROGRESS...';
    });

    final List<int> kenoPool = List.generate(80, (i) => i + 1);
    kenoPool.shuffle(_random);
    final List<int> drawList = kenoPool.take(20).toList();

    int currentIndex = 0;
    _drawTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (currentIndex >= 20) {
        timer.cancel();
        _finishDrawing();
        return;
      }

      setState(() {
        final nextDrawn = drawList[currentIndex];
        _drawnNumbers.add(nextDrawn);
        if (_selectedNumbers.contains(nextDrawn)) {
          _hitsCount++;
        }
        _statusText = 'DRAWN: ${currentIndex + 1}/20  HITS: $_hitsCount';
        currentIndex++;
      });
    });
  }

  void _finishDrawing() {
    final double bet = double.tryParse(_betController.text) ?? 10.0;
    final payTable = getPayTable(_selectedNumbers.length);
    final multiplier = payTable[_hitsCount] ?? 0.0;
    final totalWin = bet * multiplier;

    setState(() {
      _isDrawing = false;
      if (totalWin > 0) {
        _winAmount = totalWin;
        widget.onBalanceChanged(widget.balance + totalWin);
        _statusText = 'HITS: $_hitsCount! WON: ₹${totalWin.toStringAsFixed(2)}';
        _triggerWinAnimation(totalWin);
        _triggerOutcomeOverlay(multiplier, totalWin, true);
      } else {
        _statusText = 'HITS: $_hitsCount! BETTER LUCK NEXT TIME!';
        _triggerOutcomeOverlay(0.0, 0.0, false);
      }
    });

    if (_isAutoRunning) {
      final bool isWin = totalWin > 0;
      final double profitLoss = isWin ? (bet * (multiplier - 1)) : -bet;
      _accumulatedProfitLoss += profitLoss;

      double nextBet = double.tryParse(_betController.text) ?? _baseBetAmount;

      if (_selectedTab == 'Advanced') {
        if (_selectedStrategy == 'Martingale') {
          if (isWin) {
            nextBet = _baseBetAmount;
          } else {
            nextBet = nextBet * 2;
          }
        } else if (_selectedStrategy == 'Paroli') {
          if (isWin) {
            nextBet = nextBet * 2;
          } else {
            nextBet = _baseBetAmount;
          }
        }
      } else {
        if (isWin) {
          if (_onWinIncrease && _onWinIncreasePct > 0) {
            nextBet = nextBet * (1 + _onWinIncreasePct / 100);
          } else {
            nextBet = _baseBetAmount;
          }
        } else {
          if (_onLossIncrease && _onLossIncreasePct > 0) {
            nextBet = nextBet * (1 + _onLossIncreasePct / 100);
          } else {
            nextBet = _baseBetAmount;
          }
        }
      }

      final double stopProfit = double.tryParse(_stopProfitController.text) ?? 0.0;
      final double stopLoss = double.tryParse(_stopLossController.text) ?? 0.0;

      bool shouldStop = false;
      if (stopProfit > 0 && _accumulatedProfitLoss >= stopProfit) shouldStop = true;
      if (stopLoss > 0 && _accumulatedProfitLoss <= -stopLoss) shouldStop = true;

      if (_autoBetCountRemaining > 0) {
        _autoBetCountRemaining--;
        _autoBetCountController.text = _autoBetCountRemaining.toString();
        if (_autoBetCountRemaining == 0) shouldStop = true;
      }

      if (widget.balance < nextBet) shouldStop = true;

      if (shouldStop) {
        setState(() {
          _isAutoRunning = false;
        });
      } else {
        _betController.text = nextBet.toStringAsFixed(2);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && _isAutoRunning) {
            _startDrawing();
          }
        });
      }
    }
  }

  void _triggerWinAnimation(double amount) {
    _particles.clear();
    final width = 844.0;
    final height = 390.0;

    for (int i = 0; i < 70; i++) {
      _particles.add(
        CoinParticle(
          x: width / 2 + (_random.nextDouble() - 0.5) * 200,
          y: height / 2 - 50 + (_random.nextDouble() - 0.5) * 80,
          vx: (_random.nextDouble() - 0.5) * 12.0,
          vy: -_random.nextDouble() * 12.0 - 5.0, // Upward initial explosion
          size: _random.nextDouble() * 14.0 + 8.0,
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
          isStar: _random.nextBool(),
        ),
      );
    }

    _showWinOverlay = true;
    _animationController.forward(from: 0.0);
  }

  void _updateParticles() {
    const double gravity = 0.5;
    final height = 390.0;

    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.vy += gravity;
      particle.rotation += particle.rotationSpeed;

      // Damp velocities
      particle.vx *= 0.98;

      // Wrap or bounce off floor
      if (particle.y > height) {
        particle.y = height;
        particle.vy = -particle.vy * 0.4; // Bounce bounce
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320.0,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1B6E), Color(0xFF13083B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFFF3355), width: 2.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.alfaSlabOne(color: const Color(0xFFFF3355), fontSize: 16.0),
              ),
              const SizedBox(height: 12.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3355),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final payTable = getPayTable(_selectedNumbers.length);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF4C220E), Color(0xFF1A0600)],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Stack(
          children: [
            // Safe Area Layout
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  children: [
                    // ================= HEADER ROW =================
                    _buildHeaderRow(),
                    const SizedBox(height: 8.0),

                    // ================= MAIN BODY SPLIT =================
                    Expanded(
                      child: Row(
                        children: [
                          // Left Panel (Wager Controls & Paytable)
                          _buildLeftControlsPanel(payTable),
                          const SizedBox(width: 12.0),

                          // Right Panel (Number Grid & Draw buttons)
                          Expanded(child: _buildRightGridPanel()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Particle Canvas Overlay
            if (_particles.isNotEmpty && _showWinOverlay)
              IgnorePointer(
                child: CustomPaint(
                  size: size,
                  painter: ParticlePainter(particles: _particles),
                ),
              ),

            // Big Win Banner Notification
            if (_showWinOverlay && _winAmount > 0)
              Center(
                child: IgnorePointer(
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Colors.white, width: 3.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20.0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BIG WIN!',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 28.0,
                              color: Colors.white,
                              shadows: [
                                const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2.0, 2.0))
                              ],
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            '+₹${_winAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 24.0,
                              color: Colors.white,
                              shadows: [
                                const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2.0, 2.0))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILD SECTIONS ====================

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Retro Back capsule button
        GestureDetector(
          onTap: () {
            if (_isDrawing) return;
            widget.onBackPressed();
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16.0),
          ),
        ),

        // Golden Keno Title with double shadows
        Text(
          'KENO 12',
          style: GoogleFonts.alfaSlabOne(
            textStyle: const TextStyle(
              fontSize: 22.0,
              color: Color(0xFFFFD700),
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Color(0xFF8A0000), offset: Offset(2.0, 2.0), blurRadius: 1.0),
                Shadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 2.0),
              ],
            ),
          ),
        ),

        // Coins balance capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: const Color(0xFF160E45),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFF9E84FF), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                widget.balance.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleAutoBet() {
    if (_isAutoRunning) {
      setState(() {
        _isAutoRunning = false;
      });
    } else {
      if (_selectedNumbers.isEmpty) {
        _showErrorDialog('NO SPOTS SELECTED', 'Please select at least 1 number to start auto bet.');
        return;
      }
      final double bet = double.tryParse(_betController.text) ?? 0.0;
      if (bet <= 0.0) {
        _showErrorDialog('INVALID BET', 'Auto bet requires a bet amount greater than 0.');
        return;
      }
      setState(() {
        _isAutoRunning = true;
        _baseBetAmount = bet;
        _accumulatedProfitLoss = 0.0;
        _autoBetCountRemaining = int.tryParse(_autoBetCountController.text) ?? 0;
        _onWinIncreasePct = double.tryParse(_onWinIncreaseController.text) ?? 0.0;
        _onWinIncrease = _onWinIncreasePct > 0;
        _onLossIncreasePct = double.tryParse(_onLossIncreaseController.text) ?? 0.0;
        _onLossIncrease = _onLossIncreasePct > 0;
      });
      _startDrawing();
    }
  }

  Widget _buildLeftControlsPanel(Map<int, double> payTable) {
    final double bet = double.tryParse(_betController.text) ?? 0.0;

    return Container(
      width: 280.0,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B30).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF3F356B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs: Manual / Auto / Advanced
          _buildTabBar(),
          const SizedBox(height: 8.0),

          // Bet Input Label
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

          // Custom Bet Amount input container
          Container(
            height: 38.0,
            decoration: BoxDecoration(
              color: const Color(0xFF131124),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: const Color(0xFF3F356B), width: 1.2),
            ),
            child: Row(
              children: [
                // Circular Rupees Badge
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
                // Field
                Expanded(
                  child: TextFormField(
                    controller: _betController,
                    enabled: !_isDrawing && !_isAutoRunning,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                    ),
                  ),
                ),
                // Inline multiplier buttons
                Row(
                  children: [
                    _buildBetActionTextButton('-', () {
                      if (_isDrawing || _isAutoRunning) return;
                      final double current = double.tryParse(_betController.text) ?? 0.0;
                      final double next = (current - 10.0).clamp(0.0, widget.balance);
                      _betController.text = next.toStringAsFixed(0);
                    }),
                    _buildBetActionTextButton('+', () {
                      if (_isDrawing || _isAutoRunning) return;
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

          // Flat Quick Bet Buttons in 2x2 grid
          Column(
            children: [
              Row(
                children: [
                  _buildFlatQuickBetButton('10', () {
                    if (_isDrawing || _isAutoRunning) return;
                    _betController.text = '10';
                  }),
                  _buildFlatQuickBetButton('100', () {
                    if (_isDrawing || _isAutoRunning) return;
                    _betController.text = '100';
                  }),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  _buildFlatQuickBetButton('500', () {
                    if (_isDrawing || _isAutoRunning) return;
                    _betController.text = '500';
                  }),
                  _buildFlatQuickBetButton('1000', () {
                    if (_isDrawing || _isAutoRunning) return;
                    _betController.text = '1000';
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          if (_selectedTab == 'Manual') ...[
            // Dynamic Paytable header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2C1B6E),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                _selectedNumbers.isEmpty ? 'PAYOUTS' : '${_selectedNumbers.length} SPOTS PAYOUTS',
                style: const TextStyle(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4.0),

            // Paytable contents list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131124),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _selectedNumbers.isEmpty
                    ? const Center(
                        child: Text(
                          'Select spots to\nview paytable',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 9.0, height: 1.3),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(4.0),
                        itemCount: payTable.length,
                        itemBuilder: (context, index) {
                          final hits = payTable.keys.elementAt(index);
                          final mult = payTable[hits]!;
                          final bool isHighlighted = _drawnNumbers.isNotEmpty && _hitsCount == hits;
                          final winEst = bet * mult;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.5),
                            margin: const EdgeInsets.only(bottom: 2.0),
                            decoration: BoxDecoration(
                              color: isHighlighted ? const Color(0xFF00C853).withValues(alpha: 0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4.0),
                              border: isHighlighted ? Border.all(color: const Color(0xFF00C853), width: 1.0) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$hits Hits:',
                                  style: TextStyle(
                                    color: isHighlighted ? const Color(0xFF00C853) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9.0,
                                  ),
                                ),
                                Text(
                                  '${mult.toStringAsFixed(0)}x (₹${winEst.toStringAsFixed(1)})',
                                  style: TextStyle(
                                    color: isHighlighted ? Colors.white : const Color(0xFFFFD700),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.0,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ] else if (_selectedTab == 'Auto') ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Number of Bets
                    const Text(
                      'Number of Bets (0 for infinite)',
                      style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 10.0),
                    ),
                    const SizedBox(height: 4.0),
                    _buildCustomInputRow(_autoBetCountController),
                    const SizedBox(height: 8.0),

                    // On Win / On Loss Percent increase
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('On Win Increase %', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 9.0, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4.0),
                              _buildCustomInputRow(_onWinIncreaseController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('On Loss Increase %', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 9.0, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4.0),
                              _buildCustomInputRow(_onLossIncreaseController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Stop Profit / Stop Loss
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stop on Profit', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 9.0, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4.0),
                              _buildCustomInputRow(_stopProfitController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stop on Loss', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 9.0, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4.0),
                              _buildCustomInputRow(_stopLossController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    // Start Auto Bet Button
                    Bounceable(
                      onTap: _toggleAutoBet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isAutoRunning ? const Color(0xFFFF3D00) : const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          _isAutoRunning ? 'Stop Autobet' : 'Start Autobet',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_selectedTab == 'Advanced') ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Strategy Selection
                    const Text(
                      'Select Strategy',
                      style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 10.0),
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131124),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: const Color(0xFF3F356B)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStrategy,
                          dropdownColor: const Color(0xFF1E1B30),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                          items: ['Martingale', 'Paroli'].map((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (_isAutoRunning) return;
                            setState(() {
                              _selectedStrategy = newValue ?? 'Martingale';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Start Strategy Button
                    Bounceable(
                      onTap: _toggleAutoBet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isAutoRunning ? const Color(0xFFFF3D00) : const Color(0xFF3F51B5),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          _isAutoRunning ? 'Stop Strategy' : 'Run Strategy',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBetActionTextButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFlatQuickBetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1B3C),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: const Color(0xFF3F356B), width: 1.0),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInputRow(TextEditingController controller) {
    return Container(
      height: 34.0,
      decoration: BoxDecoration(
        color: const Color(0xFF131124),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFF3F356B)),
      ),
      child: TextFormField(
        controller: controller,
        enabled: !_isAutoRunning,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF3F356B), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Manual', _selectedTab == 'Manual'),
          _buildTabButton('Auto', _selectedTab == 'Auto'),
          _buildTabButton('Advanced', _selectedTab == 'Advanced'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    return Expanded(
      child: Bounceable(
        onTap: () {
          if (_isAutoRunning || _isDrawing) return;
          setState(() {
            _selectedTab = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            border: isActive
                ? const Border(
                    bottom: BorderSide(color: Color(0xFF00C853), width: 2.0),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightGridPanel() {
    return Column(
      children: [
        // Status & instructions bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0736),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFF332677), width: 1.0),
          ),
          child: Text(
            _statusText.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.alfaSlabOne(
              textStyle: TextStyle(
                fontSize: 10.0,
                color: _statusText.contains('WON') ? const Color(0xFF00C853) : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),

        // Grid (80 numbers)
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF160E45).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFF9E84FF), width: 1.2),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 80,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final isSelected = _selectedNumbers.contains(number);
                    final isDrawn = _drawnNumbers.contains(number);
                    final isHit = isSelected && isDrawn;

                    _KenoCellState cellState;
                    if (isHit) {
                      cellState = _KenoCellState.hit;
                    } else if (isDrawn) {
                      cellState = _KenoCellState.drawnMiss;
                    } else if (isSelected) {
                      cellState = _KenoCellState.selected;
                    } else {
                      cellState = _KenoCellState.normal;
                    }

                    return _KenoNumberButton(
                      number: number,
                      state: cellState,
                      onTap: () => _onNumberTapped(number),
                    );
                  },
                ),
              ),

              // Win/Lose Overlay Card centered over Keno Grid
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
        ),
        const SizedBox(height: 8.0),

        // Action controls (Quick Pick, Clear, Play)
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'QUICK PICK',
                color: const Color(0xFF0288D1),
                onTap: _quickPick,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildActionButton(
                label: 'CLEAR',
                color: const Color(0xFFFF5252),
                onTap: _clearSelection,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: _buildPlayButton(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: _isDrawing ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF322878),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: const Color(0xFF9E84FF), width: 1.0),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCapsuleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isDrawing ? null : onTap,
      child: Container(
        height: 38.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isDrawing ? Colors.grey : color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            if (!_isDrawing)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    final bool isEnabled = _selectedNumbers.isNotEmpty && !_isDrawing;

    return InkWell(
      onTap: isEnabled ? _startDrawing : null,
      child: Container(
        height: 38.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)])
              : const LinearGradient(colors: [Color(0xFF424242), Color(0xFF616161)]),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: const Color(0xFF00C853).withValues(alpha: 0.4),
                blurRadius: 6.0,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          _isDrawing ? 'DRAWING...' : 'BET & PLAY',
          style: GoogleFonts.alfaSlabOne(
            textStyle: const TextStyle(color: Colors.white, fontSize: 12.0, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

// Particle model for wins
class CoinParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double rotationSpeed;
  bool isStar;

  CoinParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isStar,
  });
}

// Custom Painter to draw falling gold coins and star particles
class ParticlePainter extends CustomPainter {
  final List<CoinParticle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final coinPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final coinBorderPaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isStar) {
        // Draw small gold/white star
        final path = Path();
        final double outerRadius = p.size / 2;
        final double innerRadius = outerRadius * 0.4;
        const int points = 5;

        for (int i = 0; i < points * 2; i++) {
          final double angle = i * pi / points - pi / 2;
          final double r = i.isEven ? outerRadius : innerRadius;
          final double px = cos(angle) * r;
          final double py = sin(angle) * r;

          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, starPaint);
      } else {
        // Draw gold coin (double circles)
        canvas.drawCircle(Offset.zero, p.size / 2, coinPaint);
        canvas.drawCircle(Offset.zero, p.size / 2, coinBorderPaint);
        canvas.drawCircle(Offset.zero, p.size / 3, coinBorderPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Number grid cell styles
enum _KenoCellState { normal, selected, drawnMiss, hit }

class _KenoNumberButton extends StatefulWidget {
  final int number;
  final _KenoCellState state;
  final VoidCallback onTap;

  const _KenoNumberButton({
    required this.number,
    required this.state,
    required this.onTap,
  });

  @override
  State<_KenoNumberButton> createState() => _KenoNumberButtonState();
}

class _KenoNumberButtonState extends State<_KenoNumberButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color topColor;
    Color bottomColor;
    Color textColor = Colors.white;

    switch (widget.state) {
      case _KenoCellState.selected:
        topColor = const Color(0xFF00E5FF);
        bottomColor = const Color(0xFF00838F);
        textColor = Colors.black;
        break;
      case _KenoCellState.drawnMiss:
        topColor = const Color(0xFFFF5252).withValues(alpha: 0.4);
        bottomColor = const Color(0xFFB71C1C).withValues(alpha: 0.4);
        textColor = Colors.white70;
        break;
      case _KenoCellState.hit:
        topColor = const Color(0xFF00C853);
        bottomColor = const Color(0xFF1B5E20);
        textColor = Colors.white;
        break;
      case _KenoCellState.normal:
      default:
        topColor = const Color(0xFF160E45).withValues(alpha: 0.6);
        bottomColor = const Color(0xFF0D0630);
        textColor = Colors.white70;
        break;
    }

    final double shadowHeight = 3.0;
    final double offsetTop = _isPressed ? shadowHeight : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        height: 24.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Shadow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 21.0,
              child: Container(
                decoration: BoxDecoration(
                  color: bottomColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ),
            // Top Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: offsetTop,
              height: 21.0,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: topColor,
                  borderRadius: BorderRadius.circular(6.0),
                  border: widget.state == _KenoCellState.selected
                      ? Border.all(color: Colors.white, width: 1.0)
                      : widget.state == _KenoCellState.hit
                          ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
                          : Border.all(color: const Color(0xFF3F356B), width: 0.8),
                ),
                child: Text(
                  '${widget.number}',
                  style: GoogleFonts.alfaSlabOne(
                    textStyle: TextStyle(
                      color: textColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
