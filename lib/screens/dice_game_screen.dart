import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_game/utils/sound_helper.dart';


class DiceGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const DiceGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<DiceGameScreen> createState() => _DiceGameScreenState();
}

class _DiceStar {
  double x;
  double y;
  double speed;
  double size;

  _DiceStar({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}

class _DiceGameScreenState extends State<DiceGameScreen>
    with TickerProviderStateMixin {
  final _betController = TextEditingController(text: '1.0');
  final _payoutController = TextEditingController(text: '1.96');
  final _targetController = TextEditingController(text: '50');
  final _winChanceController = TextEditingController(text: '50');

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

  final FocusNode _payoutFocusNode = FocusNode();
  final FocusNode _targetFocusNode = FocusNode();
  final FocusNode _winChanceFocusNode = FocusNode();

  bool _isPlaying = false;
  bool _isRollUnder = true; // true for Roll Under, false for Roll Over
  double _targetValue = 50.0;
  double _winChance = 50.0;
  double _payout = 1.96;

  // Dice roll outcome states
  double _rollResult = 50.00;
  bool _hasRolled = false;
  bool _wonLastRound = false;
  String _statusText = 'Game result will be displayed';

  Timer? _gameTimer;
  late AnimationController _rollController;
  final List<double> _history = [48.12, 12.04, 75.82, 92.15, 33.45];
  final List<_DiceStar> _staticStars = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _betController.addListener(_updateBetDetails);
    _payoutController.addListener(_updatePayoutDetails);
    _targetController.addListener(_updateTargetDetails);
    _winChanceController.addListener(_updateWinChanceDetails);

    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initialize 50 slow-drifting tiny stars for Stake/BC.Game style background
    for (int i = 0; i < 50; i++) {
      _staticStars.add(_DiceStar(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: _random.nextDouble() * 0.0005 + 0.0001,
        size: _random.nextDouble() * 1.5 + 0.5,
      ));
    }
  }

  void _updateBetDetails() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updatePayoutDetails() {
    if (!_payoutFocusNode.hasFocus) return;
    final double payout = double.tryParse(_payoutController.text) ?? 1.96;
    if (payout >= 1.01 && payout <= 980.0) {
      final double chance = double.parse((98.0 / payout).toStringAsFixed(2)).clamp(0.01, 98.0);
      final double target = _isRollUnder ? chance : 100.0 - chance;

      _targetController.removeListener(_updateTargetDetails);
      _winChanceController.removeListener(_updateWinChanceDetails);
      
      setState(() {
        _payout = payout;
        _winChance = chance;
        _targetValue = double.parse(target.toStringAsFixed(2));
        
        _targetController.text = _targetValue.toStringAsFixed(0);
        _winChanceController.text = _winChance.toStringAsFixed(0);
      });

      _targetController.addListener(_updateTargetDetails);
      _winChanceController.addListener(_updateWinChanceDetails);
    }
  }

  void _updateTargetDetails() {
    if (!_targetFocusNode.hasFocus) return;
    final double target = double.tryParse(_targetController.text) ?? 50.0;
    if (target >= 0.01 && target <= 99.9) {
      _updateTargetValue(target);
    }
  }

  void _updateTargetValue(double target) {
    if (widget.soundOn && target != _targetValue) {
      playTick();
    }
    final double chance = _isRollUnder ? target : 100.0 - target;
    final double payout = double.parse((98.0 / chance).toStringAsFixed(4)).clamp(1.01, 980.0);

    _payoutController.removeListener(_updatePayoutDetails);
    _winChanceController.removeListener(_updateWinChanceDetails);

    setState(() {
      _targetValue = target;
      _winChance = chance;
      _payout = payout;

      _payoutController.text = _payout.toStringAsFixed(2);
      _winChanceController.text = _winChance.toStringAsFixed(0);
    });

    _payoutController.addListener(_updatePayoutDetails);
    _winChanceController.addListener(_updateWinChanceDetails);
  }

  void _updateWinChanceDetails() {
    if (!_winChanceFocusNode.hasFocus) return;
    final double chance = double.tryParse(_winChanceController.text) ?? 50.0;
    if (chance >= 0.01 && chance <= 98.0) {
      final double target = _isRollUnder ? chance : 100.0 - chance;
      final double payout = double.parse((98.0 / chance).toStringAsFixed(4)).clamp(1.01, 980.0);

      _payoutController.removeListener(_updatePayoutDetails);
      _targetController.removeListener(_updateTargetDetails);

      setState(() {
        _winChance = chance;
        _targetValue = double.parse(target.toStringAsFixed(2));
        _payout = payout;

        _payoutController.text = _payout.toStringAsFixed(2);
        _targetController.text = _targetValue.toStringAsFixed(0);
      });

      _payoutController.addListener(_updatePayoutDetails);
      _targetController.addListener(_updateTargetDetails);
    }
  }

  void _toggleRollMode() {
    if (_isPlaying) return;
    setState(() {
      _isRollUnder = !_isRollUnder;
      // Recalculate target boundary
      _targetValue = 100.0 - _targetValue;
      _targetController.text = _targetValue.toStringAsFixed(0);
      _updateTargetValue(_targetValue);
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _betController.removeListener(_updateBetDetails);
    _payoutController.removeListener(_updatePayoutDetails);
    _targetController.removeListener(_updateTargetDetails);
    _winChanceController.removeListener(_updateWinChanceDetails);
    _rollController.dispose();
    _betController.dispose();
    _payoutController.dispose();
    _targetController.dispose();
    _winChanceController.dispose();
    _payoutFocusNode.dispose();
    _targetFocusNode.dispose();
    _winChanceFocusNode.dispose();
    
    _autoBetCountController.dispose();
    _onWinIncreaseController.dispose();
    _onLossIncreaseController.dispose();
    _stopProfitController.dispose();
    _stopLossController.dispose();
    
    super.dispose();
  }

  void _playDiceRoll() {
    if (_isPlaying) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    if (bet < 0.0) {
      _showErrorDialog('INVALID BET', 'Please enter a valid bet amount.');
      return;
    }

    final bool isDemo = bet == 0.0;

    if (!isDemo && widget.balance < bet) {
      _showErrorDialog('INSUFFICIENT BALANCE', 'Please recharge from the shop in the lobby.');
      return;
    }

    if (!isDemo) {
      widget.onBalanceChanged(widget.balance - bet);
    }

    setState(() {
      _isPlaying = true;
      _hasRolled = true;
      _statusText = isDemo ? 'DEMO ROLL IN PROGRESS...' : 'ROLL IN PROGRESS...';
    });

    final double finalRoll = _random.nextDouble() * 100.0;
    _rollController.forward(from: 0.0);

    const int fps = 50;
    final int stepCount = (0.9 * fps).round();
    int currentStep = 0;

    _gameTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      currentStep++;
      final double progress = currentStep / stepCount;

      setState(() {
        // Starfield drift
        for (var star in _staticStars) {
          star.y += star.speed;
          if (star.y > 1.0) {
            star.y = 0.0;
            star.x = _random.nextDouble();
          }
        }

        // Animate marker location randomly before final landing
        if (currentStep < stepCount) {
          _rollResult = _random.nextDouble() * 100.0;
        } else {
          _rollResult = double.parse(finalRoll.toStringAsFixed(2));
          _isPlaying = false;
          timer.cancel();
          _finishGame(bet, finalRoll, isDemo);
        }
      });
    });
  }

  void _finishGame(double bet, double finalRoll, bool isDemo) {
    // Check outcome
    final bool isWin = _isRollUnder ? (finalRoll < _targetValue) : (finalRoll > _targetValue);
    
    setState(() {
      _wonLastRound = isWin;
      _history.add(finalRoll);
      if (_history.length > 6) {
        _history.removeAt(0);
      }
    });

    if (isWin) {
      final double winAmount = bet * _payout;
      if (!isDemo) {
        widget.onBalanceChanged(widget.balance + winAmount);
      }
      setState(() {
        _statusText = isDemo
            ? 'DEMO WON ${_payout.toStringAsFixed(2)}x!'
            : 'YOU WON ₹${winAmount.toStringAsFixed(2)}!';
      });
      _showWinNotification(isDemo ? 0.0 : winAmount, _payout, isDemo);
    } else {
      setState(() {
        _statusText = 'LOST ROLL @ ${finalRoll.toStringAsFixed(2)}';
      });
    }

    // Auto / Advanced Strategy execution
    if (_isAutoRunning) {
      final double profitLoss = isWin ? (bet * (_payout - 1)) : -bet;
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
        // Standard Auto Bet Tab
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

      // Check limits
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

      // Check balance limit
      if (widget.balance < nextBet) shouldStop = true;

      if (shouldStop) {
        setState(() {
          _isAutoRunning = false;
        });
      } else {
        _betController.text = nextBet.toStringAsFixed(2);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _isAutoRunning) {
            _playDiceRoll();
          }
        });
      }
    }
  }

  void _showWinNotification(double amount, double multiplier, bool isDemo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E575)]),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withValues(alpha: 0.4),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 24.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDemo ? 'DEMO DICE TARGET REACHED!' : 'DICE TARGET REACHED!',
                      style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isDemo
                          ? 'Demo Win Payout ${multiplier.toStringAsFixed(2)}x success'
                          : 'Won ₹${amount.toStringAsFixed(2)} (${multiplier.toStringAsFixed(2)}x Payout)',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFF2C2F36), width: 1.5),
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
    final double winProfit = bet * _payout;

    return Scaffold(
      backgroundColor: const Color(0xFF181A1F),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Balance stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _isPlaying ? null : widget.onBackPressed,
                  ),
                  Text(
                    'CLASSIC DICE',
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

            // Game Split Layout
            Expanded(
              child: isLandscape
                  ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Bet Controls
                    _buildBetControlsCard(bet, winProfit, isLandscape: true),
                    const SizedBox(width: 12.0),
                    // Right Column: Slider Canvas Viewport
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                        child: _buildSliderCanvasView(),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Top Section: Slider Viewport
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildSliderCanvasView(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    // Bottom Section: Bet Controls
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildBetControlsCard(bet, winProfit, isLandscape: false),
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
      _playDiceRoll();
    }
  }

  Widget _buildBetControlsCard(double bet, double winProfit, {required bool isLandscape}) {
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
          // Tabs: Manual / Auto / Advanced
          _buildTabBar(),

          // Bet Input Label and Conversion
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

          // Custom Bet Amount input container
          Container(
            height: 38.0,
            decoration: BoxDecoration(
              color: const Color(0xFF181A1F),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
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
                // Inline multiplier buttons
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

          // Flat Quick Bet Buttons in 2x2 grid
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
            // Win Amount (Read-only Profit Box)
            const Text(
              'Win Amount',
              style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11.0),
            ),
            const SizedBox(height: 6.0),
            Container(
              height: 38.0,
              decoration: BoxDecoration(
                color: const Color(0xFF181A1F),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
              ),
              child: Row(
                children: [
                  // Circular Rupees Badge (Gray)
                  Container(
                    margin: const EdgeInsets.only(left: 6.0, right: 8.0),
                    width: 20.0,
                    height: 20.0,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '₹',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                    ),
                  ),
                  Text(
                    winProfit.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (isLandscape) const Spacer(),
            if (!isLandscape) const SizedBox(height: 14.0),

            // Play Bet Button
            GestureDetector(
              onTap: _isPlaying ? null : _playDiceRoll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPlaying ? const Color(0xFF5E5E6E) : const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  _isPlaying ? 'ROLLING...' : 'Bet',
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

          // Demo Notice Capsule
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

  Widget _buildSliderCanvasView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

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
              // 1. Custom painted drifting stars, background grid track
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiceBackgroundPainter(
                    stars: _staticStars,
                  ),
                ),
              ),

              // 2. Drag listener for adjusting the target boundary slider
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isPlaying) return;
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    // Match slider track padding (left/right 24.0)
                    final double trackWidth = renderBox.size.width - 48.0;
                    final double relativeX = (localPos.dx - 24.0).clamp(0.0, trackWidth);
                    final double newTarget = (relativeX / trackWidth) * 100.0;
                    _updateTargetValue(double.parse(newTarget.toStringAsFixed(0)));
                  },
                  child: CustomPaint(
                    painter: _DiceTrackPainter(
                      targetValue: _targetValue,
                      isRollUnder: _isRollUnder,
                      rollResult: _rollResult,
                      isPlaying: _isPlaying,
                      hasRolled: _hasRolled,
                      wonLastRound: _wonLastRound,
                    ),
                  ),
                ),
              ),

              // 3. Top results indicator bar
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

              // 4. Center roll outcome text overlay
              Positioned(
                top: height * 0.28,
                child: Text(
                  _isPlaying ? '...' : '${_rollResult.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.w900,
                      color: _isPlaying
                          ? Colors.white
                          : (_wonLastRound ? const Color(0xFF00C853) : const Color(0xFFFF5252)),
                      shadows: [
                        Shadow(
                          color: _isPlaying
                              ? Colors.black
                              : (_wonLastRound ? const Color(0xFF00C853).withValues(alpha: 0.4) : const Color(0xFFFF5252).withValues(alpha: 0.4)),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Recent history row
              Positioned(
                top: 40.0,
                left: 10.0,
                right: 10.0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _history.map((val) {
                      final bool isLesserThan50 = val < 50.0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isLesserThan50
                              ? const Color(0xFF00C853).withValues(alpha: 0.15)
                              : const Color(0xFFFF5252).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isLesserThan50
                                ? const Color(0xFF00C853).withValues(alpha: 0.4)
                                : const Color(0xFFFF5252).withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          val.toStringAsFixed(2),
                          style: TextStyle(
                            color: isLesserThan50 ? const Color(0xFF00C853) : const Color(0xFFFF5252),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 6. Bottom linked payout, target, and win chance dashboards
              Positioned(
                bottom: 12.0,
                left: 12.0,
                right: 12.0,
                child: _buildBottomDashboardsRow(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomDashboardsRow() {
    return Row(
      children: [
        // Payout box
        Expanded(
          flex: 4,
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
                        controller: _payoutController,
                        focusNode: _payoutFocusNode,
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),

        // Target box (Roll Under / Roll Over)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRollUnder ? 'Roll Under' : 'Roll Over',
                style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 10.0, fontWeight: FontWeight.bold),
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
                        ),
                      ),
                    ),
                    // Swap Button icon
                    GestureDetector(
                      onTap: _toggleRollMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        height: 38.0,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0xFF1E2024), width: 1.0),
                          ),
                        ),
                        child: const Icon(Icons.swap_horizontal_circle, color: Color(0xFF00C853), size: 20.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),

        // Win Chance box
        Expanded(
          flex: 4,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiceBackgroundPainter extends CustomPainter {
  final List<_DiceStar> stars;

  _DiceBackgroundPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    // Background Slate
    final bgPaint = Paint()..color = const Color(0xFF181A1F);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Drifting stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.65);
    for (var star in stars) {
      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.size, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiceBackgroundPainter oldDelegate) {
    return true; // Redraw stars drift
  }
}

class _DiceTrackPainter extends CustomPainter {
  final double targetValue;
  final bool isRollUnder;
  final double rollResult;
  final bool isPlaying;
  final bool hasRolled;
  final bool wonLastRound;

  _DiceTrackPainter({
    required this.targetValue,
    required this.isRollUnder,
    required this.rollResult,
    required this.isPlaying,
    required this.hasRolled,
    required this.wonLastRound,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Track coordinates
    final double paddingX = 24.0;
    final double trackY = h * 0.55;
    final double trackWidth = w - (paddingX * 2);
    final double trackHeight = 12.0;

    // 1. Draw track boundary background
    final bgPaint = Paint()
      ..color = const Color(0xFF2C2F36)
      ..style = PaintingStyle.fill;
    
    // Draw horizontal track segments
    final double targetX = paddingX + (targetValue / 100.0) * trackWidth;

    // Left and Right segment rects
    final RRect leftRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(paddingX, trackY - (trackHeight / 2), targetX, trackY + (trackHeight / 2)),
      const Radius.circular(6.0),
    );
    final RRect rightRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(targetX, trackY - (trackHeight / 2), w - paddingX, trackY + (trackHeight / 2)),
      const Radius.circular(6.0),
    );

    // Green is winning range, Orange/Red is losing range
    final Paint winPaint = Paint()..color = const Color(0xFF00C853);
    final Paint losePaint = Paint()..color = const Color(0xFFFF9100);

    if (isRollUnder) {
      // Under target wins (Left is Green, Right is Orange)
      canvas.drawRRect(leftRect, winPaint);
      canvas.drawRRect(rightRect, losePaint);
    } else {
      // Over target wins (Left is Orange, Right is Green)
      canvas.drawRRect(leftRect, losePaint);
      canvas.drawRRect(rightRect, winPaint);
    }

    // 2. Draw slider labels under the track (0, 25, 50, 75, 100)
    final textStyle = TextStyle(color: Colors.grey[500], fontSize: 10.0, fontWeight: FontWeight.bold);
    
    _drawLabel(canvas, '0', Offset(paddingX, trackY + 18.0), textStyle);
    _drawLabel(canvas, '25', Offset(paddingX + (0.25 * trackWidth), trackY + 18.0), textStyle);
    _drawLabel(canvas, '50', Offset(paddingX + (0.50 * trackWidth), trackY + 18.0), textStyle);
    _drawLabel(canvas, '75', Offset(paddingX + (0.75 * trackWidth), trackY + 18.0), textStyle);
    _drawLabel(canvas, '100', Offset(w - paddingX, trackY + 18.0), textStyle);

    // 3. Draw dragging vertical handle bar
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw rounded handle box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(targetX - 8.0, trackY - 14.0, 16.0, 28.0),
        const Radius.circular(4.0),
      ),
      handlePaint,
    );

    // Draw three vertical groove lines inside the handle
    final groovePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(targetX - 3.0, trackY - 8.0), Offset(targetX - 3.0, trackY + 8.0), groovePaint);
    canvas.drawLine(Offset(targetX, trackY - 8.0), Offset(targetX, trackY + 8.0), groovePaint);
    canvas.drawLine(Offset(targetX + 3.0, trackY - 8.0), Offset(targetX + 3.0, trackY + 8.0), groovePaint);

    // 5. Draw roll result dot indicator if rolled
    if (hasRolled && !isPlaying) {
      final double resultX = paddingX + (rollResult / 100.0) * trackWidth;

      // Draw circular glow point
      canvas.drawCircle(
        Offset(resultX, trackY),
        7.0,
        Paint()..color = wonLastRound ? const Color(0xFF00C853).withValues(alpha: 0.6) : const Color(0xFFFF5252).withValues(alpha: 0.6),
      );
      canvas.drawCircle(
        Offset(resultX, trackY),
        4.0,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawLabel(Canvas canvas, String label, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(position.dx - (textPainter.width / 2), position.dy));
  }

  void _drawHexagonalBubble(
    Canvas canvas,
    double x,
    double y,
    String value, {
    Color bgColor = Colors.white,
    Color textColor = Colors.black,
  }) {
    final Path hexPath = Path();
    final double radiusW = 26.0;
    final double radiusH = 14.0;

    // Draw speech bubble hexagon shape
    hexPath.moveTo(x - radiusW, y - radiusH);
    hexPath.lineTo(x + radiusW, y - radiusH);
    hexPath.lineTo(x + radiusW + 6.0, y);
    hexPath.lineTo(x + radiusW, y + radiusH);
    hexPath.lineTo(x + 5.0, y + radiusH);
    hexPath.lineTo(x, y + radiusH + 6.0); // Little pointer arrow
    hexPath.lineTo(x - 5.0, y + radiusH);
    hexPath.lineTo(x - radiusW, y + radiusH);
    hexPath.lineTo(x - radiusW - 6.0, y);
    hexPath.close();

    canvas.drawPath(hexPath, Paint()..color = bgColor);

    // Text target value
    final textPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x - (textPainter.width / 2), y - (textPainter.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _DiceTrackPainter oldDelegate) {
    return true; // repaint constantly
  }
}
