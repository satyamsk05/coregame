import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/win_lose_toast.dart';
import '../widgets/win_overlay_card.dart';
import 'package:google_fonts/google_fonts.dart';

class LimboGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const LimboGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<LimboGameScreen> createState() => _LimboGameScreenState();
}

class _StaticStar {
  double x;
  double y;
  double speed;
  double size;

  _StaticStar({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}

class _LimboGameScreenState extends State<LimboGameScreen>
    with TickerProviderStateMixin {
  final _betController = TextEditingController(text: '1.0');
  final _targetController = TextEditingController(text: '2.00');
  final _winChanceController = TextEditingController(text: '49.50');

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
  
  double _baseBetAmount = 1.0;
  double _accumulatedProfitLoss = 0.0;
  
  final _stopProfitController = TextEditingController(text: '0');
  final _stopLossController = TextEditingController(text: '0');
  
  String _selectedStrategy = 'Martingale'; // Martingale, Paroli
  double _strategyMultiplier = 2.0;

  final FocusNode _targetFocusNode = FocusNode();
  final FocusNode _winChanceFocusNode = FocusNode();

  bool _isPlaying = false;
  bool _isCrashed = false;
  bool _hasWonCurrent = false;
  double _currentMultiplier = 1.00;
  String _statusText = 'Game result will be displayed';

  Timer? _gameTimer;
  late AnimationController _launchController;
  late AnimationController _explosionController;
  
  final List<double> _history = [1.24, 5.40, 1.88, 15.02, 2.05, 1.03];
  final List<_StaticStar> _staticStars = [];
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

    _betController.addListener(_updateBetDetails);
    _targetController.addListener(_updatePayoutDetails);
    _winChanceController.addListener(_updateWinChanceDetails);

    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Initialize 60 static/slow-drifting tiny stars matching the Stake/BC.Game style
    for (int i = 0; i < 60; i++) {
      _staticStars.add(_StaticStar(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: _random.nextDouble() * 0.0006 + 0.0002, // ultra slow drift
        size: _random.nextDouble() * 1.5 + 0.5, // 0.5px to 2.0px circular dots
      ));
    }
  }

  void _updateBetDetails() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updatePayoutDetails() {
    if (!_targetFocusNode.hasFocus) return; // Only process if user is actively editing target multiplier
    final double target = double.tryParse(_targetController.text) ?? 2.0;
    if (target > 0.0) {
      final double chance = double.parse((99.0 / target).toStringAsFixed(2)).clamp(0.01, 98.0);
      _winChanceController.removeListener(_updateWinChanceDetails);
      _winChanceController.text = chance.toStringAsFixed(2);
      _winChanceController.addListener(_updateWinChanceDetails);
    }
  }

  void _updateWinChanceDetails() {
    if (!_winChanceFocusNode.hasFocus) return; // Only process if user is actively editing win chance
    final double chance = double.tryParse(_winChanceController.text) ?? 49.5;
    if (chance > 0.0) {
      final double target = double.parse((99.0 / chance).toStringAsFixed(2)).clamp(1.01, 1000.0);
      _targetController.removeListener(_updatePayoutDetails);
      _targetController.text = target.toStringAsFixed(2);
      _targetController.addListener(_updatePayoutDetails);
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _betController.removeListener(_updateBetDetails);
    _targetController.removeListener(_updatePayoutDetails);
    _winChanceController.removeListener(_updateWinChanceDetails);
    _launchController.dispose();
    _explosionController.dispose();
    _betController.dispose();
    _targetController.dispose();
    _winChanceController.dispose();
    _targetFocusNode.dispose();
    _winChanceFocusNode.dispose();
    
    _autoBetCountController.dispose();
    _onWinIncreaseController.dispose();
    _onLossIncreaseController.dispose();
    _stopProfitController.dispose();
    _stopLossController.dispose();
    
    super.dispose();
  }

  double _generateCrashPoint() {
    final rand = _random.nextDouble();
    final val = 0.99 / (1.0 - rand);
    return double.parse(val.clamp(1.01, 1000.0).toStringAsFixed(2));
  }

  void _playGame() {
    if (_isPlaying) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final double target = double.tryParse(_targetController.text) ?? 1.5;

    if (bet < 0.0) {
      _showErrorDialog('INVALID BET', 'Please enter a valid bet amount.');
      return;
    }
    
    final bool isDemoMode = bet == 0.0;

    if (!isDemoMode && widget.balance < bet) {
      _showErrorDialog('INSUFFICIENT BALANCE', 'Please recharge from the shop in the lobby.');
      return;
    }

    // Deduct bet amount if not in demo mode
    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance - bet);
    }

    setState(() {
      _isPlaying = true;
      _currentMultiplier = 1.00;
      _isCrashed = false;
      _hasWonCurrent = false;
      _statusText = isDemoMode ? 'DEMO ROCKET BLASTING OFF!' : 'ROCKET IS BLASTING OFF!';
    });

    final double crashPoint = _generateCrashPoint();

    // Scale flight duration based on multiplier height
    final double durationSec = (0.8 + math.log(crashPoint) * 0.8).clamp(0.8, 4.5);
    _launchController.duration = Duration(milliseconds: (durationSec * 1000).round());
    _launchController.forward(from: 0.0);

    const int fps = 50;
    final int stepCount = (durationSec * fps).round();
    int currentStep = 0;

    _gameTimer = Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (timer) {
      currentStep++;
      final double progress = currentStep / stepCount;

      // Exponential counter
      final double nextMult = 1.00 + (progress * progress * (crashPoint - 1.00));

      setState(() {
        _currentMultiplier = nextMult;

        // Slow drift the background stars
        for (var star in _staticStars) {
          star.y += star.speed;
          if (star.y > 1.0) {
            star.y = 0.0;
            star.x = _random.nextDouble();
          }
        }

        if (_currentMultiplier >= target && !_hasWonCurrent) {
          _hasWonCurrent = true;
        }

        if (currentStep >= stepCount || _currentMultiplier >= crashPoint) {
          _currentMultiplier = crashPoint;
          _isCrashed = true;
          _isPlaying = false;
          timer.cancel();
          _finishGame(bet, target, crashPoint, isDemoMode);
        }
      });
    });
  }

  void _finishGame(double bet, double target, double crashPoint, bool isDemoMode) {
    final bool playerWon = crashPoint >= target;

    _explosionController.forward(from: 0.0);

    setState(() {
      _history.add(crashPoint);
      if (_history.length > 6) {
        _history.removeAt(0);
      }
    });

    if (playerWon) {
      final double winAmount = bet * target;
      if (!isDemoMode) {
        widget.onBalanceChanged(widget.balance + winAmount);
      }
      setState(() {
        _statusText = isDemoMode 
            ? 'DEMO WON ${target.toStringAsFixed(2)}x!' 
            : 'YOU WON ₹${winAmount.toStringAsFixed(2)}!';
      });
      _triggerOutcomeOverlay(target, winAmount, true);
    } else {
      setState(() {
        _statusText = 'CRASHED @ ${crashPoint.toStringAsFixed(2)}x';
      });
      _triggerOutcomeOverlay(0.0, 0.0, false);
    }

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _isCrashed = false;
          _currentMultiplier = 1.00;
          _hasWonCurrent = false;
          _statusText = 'Game result will be displayed';
        });
        _launchController.reset();

        if (_isAutoRunning) {
          final bool isWin = playerWon;
          final double profitLoss = isWin ? (bet * (target - 1)) : -bet;
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
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _isAutoRunning) {
                _playGame();
              }
            });
          }
        }
        _explosionController.reset();
      }
    });
  }

  void _showWinNotification(double amount, double multiplier, bool isDemoMode) {
    showWinLoseToast(
      context,
      isWin: true,
      title: isDemoMode ? 'DEMO TARGET HIT!' : 'TARGET REACHED!',
      message: isDemoMode
          ? 'Demo Payout ${multiplier.toStringAsFixed(2)}x'
          : 'Won ₹${amount.toStringAsFixed(2)} (${multiplier.toStringAsFixed(2)}x)',
    );
  }

  void _showErrorDialog(String title, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFF37474F), width: 1.5),
        ),
        title: Text(
          title,
          style: GoogleFonts.alfaSlabOne(textStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 14.0)),
        ),
        content: Text(
          desc,
          style: const TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context),
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
      backgroundColor: const Color(0xFF181A1F),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Stats Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _isPlaying ? null : widget.onBackPressed,
                  ),
                  Text(
                    'LIMBO ROCKET',
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

            // Game Playfield Split Layout
            Expanded(
              child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Bet Controls
                    _buildBetControlsCard(bet, isLandscape: true),
                    const SizedBox(width: 12.0),
                    // Right Column: Rocket Animation Canvas
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                        child: _buildRocketCanvasView(),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Top Section: Rocket Viewport
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildRocketCanvasView(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    // Bottom Section: Bet Controls
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildBetControlsCard(bet, isLandscape: false),
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

  void _toggleAutoBet() {
    if (_isAutoRunning) {
      setState(() {
        _isAutoRunning = false;
      });
    } else {
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
      _playGame();
    }
  }

  Widget _buildBetControlsCard(double bet, {required bool isLandscape}) {
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
          // Manual / Auto / Advanced Tab Selection
          _buildTabBar(),

          // Amount Row Title and Conversion
          Row(
            children: [
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
              const Spacer(),
              Text(
                '≈${(bet * 0.012).toStringAsFixed(4)} BCD',
                style: TextStyle(color: Colors.grey[400], fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6.0),

          // Custom Amount Input with circular currency and inline multiplier controls
          Container(
            height: 38.0,
            decoration: BoxDecoration(
              color: const Color(0xFF181A1F),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
            ),
            child: Row(
              children: [
                // Rupees Orange Circle badge
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
                    enabled: !_isPlaying && !_isAutoRunning,
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
                      if (_isPlaying || _isAutoRunning) return;
                      final double current = double.tryParse(_betController.text) ?? 0.0;
                      final double next = (current - 10.0).clamp(0.0, widget.balance);
                      _betController.text = next.toStringAsFixed(0);
                    }),
                    _buildBetActionTextButton('+', () {
                      if (_isPlaying || _isAutoRunning) return;
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

          // Flat Quick buttons in 2x2 grid
          Column(
            children: [
              Row(
                children: [
                  _buildFlatQuickBetButton('10', () {
                    if (_isPlaying || _isAutoRunning) return;
                    _betController.text = '10';
                  }),
                  _buildFlatQuickBetButton('100', () {
                    if (_isPlaying || _isAutoRunning) return;
                    _betController.text = '100';
                  }),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  _buildFlatQuickBetButton('500', () {
                    if (_isPlaying || _isAutoRunning) return;
                    _betController.text = '500';
                  }),
                  _buildFlatQuickBetButton('1000', () {
                    if (_isPlaying || _isAutoRunning) return;
                    _betController.text = '1000';
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          if (_selectedTab == 'Manual') ...[
            if (isLandscape) const Spacer(),
            if (!isLandscape) const SizedBox(height: 12.0),

            // Play Bet Button
            GestureDetector(
              onTap: _isPlaying ? null : _playGame,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPlaying ? const Color(0xFF5E5E6E) : const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  _isPlaying ? 'LAUNCHING...' : 'Bet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ] else if (_selectedTab == 'Auto') ...[
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
            if (isLandscape) const Spacer(),
            if (!isLandscape) const SizedBox(height: 12.0),

            // Start Auto Bet Button
            GestureDetector(
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
          ] else if (_selectedTab == 'Advanced') ...[
            // Strategy Selection
            const Text(
              'Select Strategy',
              style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 10.0),
            ),
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF181A1F),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: const Color(0xFF2C2F36)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStrategy,
                  dropdownColor: const Color(0xFF1E2024),
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
            if (isLandscape) const Spacer(),
            if (!isLandscape) const SizedBox(height: 12.0),

            // Start Strategy Button
            GestureDetector(
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
                    style: TextStyle(color: Colors.grey[400], fontSize: 10.0, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInputRow(TextEditingController controller) {
    return Container(
      height: 34.0,
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFF2C2F36)),
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
          bottom: BorderSide(color: Color(0xFF2C2F36), width: 1.5),
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
      child: GestureDetector(
        onTap: () {
          if (_isAutoRunning || _isPlaying) return;
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

  Widget _buildBetActionTextButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF2C2F36), width: 1.0),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBetActionIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF2C2F36), width: 1.0),
          ),
        ),
        child: Icon(icon, color: Colors.grey, size: 16.0),
      ),
    );
  }

  Widget _buildFlatQuickBetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F36),
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildRocketCanvasView() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom Painted Drifting Stars, Trajectory Path, Rocket & Explosion
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_launchController, _explosionController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _LimboCanvasPainter(
                    launchProgress: _launchController.value,
                    explosionProgress: _explosionController.value,
                    isPlaying: _isPlaying,
                    isCrashed: _isCrashed,
                    stars: _staticStars,
                  ),
                );
              },
            ),
          ),

          // Top Result Display Bar matching the Stake style
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: const Color(0xFF212529).withValues(alpha: 0.8),
              alignment: Alignment.center,
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Space history row (positioned right below the status bar)
          Positioned(
            top: 40.0,
            left: 10.0,
            right: 10.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _history.map((val) {
                  final bool isBigWin = val >= 2.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isBigWin
                          ? const Color(0xFF00C853).withValues(alpha: 0.15)
                          : const Color(0xFFFF5252).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isBigWin
                            ? const Color(0xFF00C853).withValues(alpha: 0.4)
                            : const Color(0xFFFF5252).withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '${val.toStringAsFixed(2)}x',
                      style: TextStyle(
                        color: isBigWin ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Multiplier Text in the center
          Positioned(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentMultiplier.toStringAsFixed(2)}x',
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      fontSize: 54.0,
                      fontWeight: FontWeight.w900,
                      color: _isCrashed
                          ? const Color(0xFFFF5252)
                          : (_hasWonCurrent ? const Color(0xFF00C853) : Colors.white),
                      shadows: [
                        Shadow(
                          color: _isCrashed
                              ? const Color(0xFFFF5252).withValues(alpha: 0.4)
                              : (_hasWonCurrent ? const Color(0xFF00C853).withValues(alpha: 0.4) : Colors.black),
                          blurRadius: 8.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom linked Payout & Win Chance inputs
          Positioned(
            bottom: 12.0,
            left: 12.0,
            right: 12.0,
            child: _buildPayoutWinChancePanel(),
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

  Widget _buildPayoutWinChancePanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: [
          // Payout Box (Target Multiplier)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payout',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 10.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Container(
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F36),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _targetController,
                          focusNode: _targetFocusNode,
                          enabled: !_isPlaying,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                            suffixText: 'x',
                            suffixStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Chevron buttons
                      _buildChevronButton(Icons.chevron_left, () {
                        if (_isPlaying) return;
                        final double current = double.tryParse(_targetController.text) ?? 2.0;
                        final double target = (current - 0.1).clamp(1.01, 1000.0);
                        _targetController.text = target.toStringAsFixed(2);
                        final double chance = double.parse((99.0 / target).toStringAsFixed(2)).clamp(0.01, 98.0);
                        _winChanceController.text = chance.toStringAsFixed(2);
                        setState(() {});
                      }),
                      _buildChevronButton(Icons.chevron_right, () {
                        if (_isPlaying) return;
                        final double current = double.tryParse(_targetController.text) ?? 2.0;
                        final double target = (current + 0.1).clamp(1.01, 1000.0);
                        _targetController.text = target.toStringAsFixed(2);
                        final double chance = double.parse((99.0 / target).toStringAsFixed(2)).clamp(0.01, 98.0);
                        _winChanceController.text = chance.toStringAsFixed(2);
                        setState(() {});
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),

          // Win Chance Box
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Win Chance',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 10.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Container(
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F36),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _winChanceController,
                          focusNode: _winChanceFocusNode,
                          enabled: !_isPlaying,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                            suffixText: '%',
                            suffixStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Chevron buttons
                      _buildChevronButton(Icons.chevron_left, () {
                        if (_isPlaying) return;
                        final double current = double.tryParse(_winChanceController.text) ?? 49.5;
                        final double chance = (current - 1.0).clamp(0.01, 98.0);
                        _winChanceController.text = chance.toStringAsFixed(2);
                        final double target = double.parse((99.0 / chance).toStringAsFixed(2)).clamp(1.01, 1000.0);
                        _targetController.text = target.toStringAsFixed(2);
                        setState(() {});
                      }),
                      _buildChevronButton(Icons.chevron_right, () {
                        if (_isPlaying) return;
                        final double current = double.tryParse(_winChanceController.text) ?? 49.5;
                        final double chance = (current + 1.0).clamp(0.01, 98.0);
                        _winChanceController.text = chance.toStringAsFixed(2);
                        final double target = double.parse((99.0 / chance).toStringAsFixed(2)).clamp(1.01, 1000.0);
                        _targetController.text = target.toStringAsFixed(2);
                        setState(() {});
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChevronButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.0,
        height: 38.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF1E2024), width: 1.0),
          ),
        ),
        child: Icon(icon, color: Colors.grey, size: 16.0),
      ),
    );
  }
}

class _LimboCanvasPainter extends CustomPainter {
  final double launchProgress;
  final double explosionProgress;
  final bool isPlaying;
  final bool isCrashed;
  final List<_StaticStar> stars;

  _LimboCanvasPainter({
    required this.launchProgress,
    required this.explosionProgress,
    required this.isPlaying,
    required this.isCrashed,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw solid dark background color matching reference Stake screen
    final bgPaint = Paint()..color = const Color(0xFF181A1F);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Draw tiny circular stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (var star in stars) {
      canvas.drawCircle(Offset(star.x * w, star.y * h), star.size, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LimboCanvasPainter oldDelegate) {
    return true;
  }
}
