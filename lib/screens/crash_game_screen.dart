import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_manager.dart';

class CrashGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const CrashGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<CrashGameScreen> createState() => _CrashGameScreenState();
}

class _StarParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;

  _StarParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
  });
}

class _CrashPlayer {
  final String name;
  final double bet;
  double? cashoutMultiplier;
  bool cashedOut = false;

  _CrashPlayer({required this.name, required this.bet});
}

class _CrashGameScreenState extends State<CrashGameScreen>
    with TickerProviderStateMixin {
  final _betController = TextEditingController(text: '10');
  final _autoCashoutController = TextEditingController(text: '2.00');

  bool _isAutoCashoutEnabled = false;
  bool _isPlaying = false;
  bool _hasPlacedBet = false;
  bool _hasCashedOut = false;
  bool _isCrashed = false;

  double _currentMultiplier = 1.00;
  double _crashPoint = 1.00;
  double _crashedAt = 1.00;

  Timer? _gameTimer;
  Timer? _tickSoundTimer;
  late AnimationController _pulseController;
  late AnimationController _crashController;

  final List<double> _history = [1.45, 12.80, 2.05, 1.12, 54.30, 1.89, 3.40];
  final List<_StarParticle> _particles = [];
  final List<_CrashPlayer> _players = [];
  final math.Random _random = math.Random();

  // Animation values for the rocket trajectory
  double _rocketProgress = 0.0; // 0.0 to 1.0

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
    _crashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _generateMockPlayers();
  }

  void _generateMockPlayers() {
    _players.clear();
    final names = ['RetroGamer', 'CryptoKing', 'LuckyStar', 'PixelRider', 'NeonNinja', 'SolHunter', 'StakeMaster', 'ViperX'];
    for (var name in names) {
      _players.add(_CrashPlayer(
        name: name,
        bet: (_random.nextInt(19) + 1) * 10.0,
      ));
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _tickSoundTimer?.cancel();
    _pulseController.dispose();
    _crashController.dispose();
    _betController.dispose();
    _autoCashoutController.dispose();
    super.dispose();
  }

  void _startBetting() {
    final double betAmount = double.tryParse(_betController.text) ?? 10.0;
    if (betAmount <= 0.0 || betAmount > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid bet amount or insufficient balance!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Deduct balance
    widget.onBalanceChanged(widget.balance - betAmount);
    SoundManager.playClick();

    setState(() {
      _isPlaying = true;
      _hasPlacedBet = true;
      _hasCashedOut = false;
      _isCrashed = false;
      _currentMultiplier = 1.00;
      _rocketProgress = 0.0;
      _particles.clear();
      _generateMockPlayers();
    });

    // Determine when the crash will happen
    // Mathematical formula to skew crash point towards lower multipliers (realistic crash probability)
    final double randVal = _random.nextDouble();
    if (randVal < 0.10) {
      // 10% chance to crash immediately at 1.00x - 1.05x
      _crashPoint = 1.00 + (_random.nextDouble() * 0.05);
    } else if (randVal < 0.65) {
      // 55% chance to crash between 1.05x and 2.50x
      _crashPoint = 1.05 + (_random.nextDouble() * 1.45);
    } else if (randVal < 0.90) {
      // 25% chance to crash between 2.50x and 10.0x
      _crashPoint = 2.50 + (_random.nextDouble() * 7.50);
    } else if (randVal < 0.98) {
      // 8% chance to crash between 10.0x and 50.0x
      _crashPoint = 10.0 + (_random.nextDouble() * 40.0);
    } else {
      // 2% chance to crash all the way up to 999.0x!
      _crashPoint = 50.0 + (_random.nextDouble() * 949.0);
    }

    _pulseController.repeat(reverse: true);

    const int stepMs = 30;
    _gameTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) return;

      setState(() {
        // Growth formula: exponential increase
        if (_currentMultiplier < 2.0) {
          _currentMultiplier += 0.008;
        } else if (_currentMultiplier < 5.0) {
          _currentMultiplier += 0.018;
        } else if (_currentMultiplier < 15.0) {
          _currentMultiplier += 0.08;
        } else if (_currentMultiplier < 50.0) {
          _currentMultiplier += 0.35;
        } else {
          _currentMultiplier += 1.8;
        }

        // Advance rocket animation progress
        _rocketProgress = (_currentMultiplier / 15.0).clamp(0.0, 1.0);

        // Spawn particles behind rocket tip
        _spawnParticles();

        // Update particle offsets
        for (var p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.alpha = (p.alpha - 0.03).clamp(0.0, 1.0);
        }
        _particles.removeWhere((p) => p.alpha <= 0.0);

        // Update mock players cashing out
        _updateMockPlayersCashout();

        // Check Auto Cashout
        if (_isAutoCashoutEnabled && !_hasCashedOut) {
          final double target = double.tryParse(_autoCashoutController.text) ?? 2.0;
          if (_currentMultiplier >= target) {
            _cashOut();
          }
        }

        // Check Crash limit
        if (_currentMultiplier >= _crashPoint) {
          _triggerCrash();
        }
      });
    });

    // Play periodic ticking sounds as multiplier increases
    _tickSoundTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_isPlaying && !_isCrashed && !_hasCashedOut) {
        SoundManager.playClick();
      }
    });
  }

  void _spawnParticles() {
    // Determine target location of rocket based on progress
    // Bezier curve mapping
    final double startX = 40.0;
    final double startY = 220.0;
    final double endX = 280.0;
    final double endY = 50.0;

    final double px = startX + (endX - startX) * _rocketProgress;
    final double py = startY + (endY - startY) * math.sin(_rocketProgress * math.pi / 2);

    for (int i = 0; i < 2; i++) {
      _particles.add(_StarParticle(
        x: px,
        y: py,
        vx: -_random.nextDouble() * 2.0 - 0.5,
        vy: _random.nextDouble() * 1.5 - 0.75,
        size: _random.nextDouble() * 3.0 + 1.5,
        alpha: 1.0,
      ));
    }
  }

  void _updateMockPlayersCashout() {
    for (var player in _players) {
      if (!player.cashedOut) {
        // Random cashout probability starting from 1.1x
        if (_currentMultiplier > 1.10 && _random.nextDouble() < 0.015) {
          player.cashedOut = true;
          player.cashoutMultiplier = _currentMultiplier;
        }
      }
    }
  }

  void _cashOut() {
    if (_hasCashedOut || _isCrashed) return;

    final double betAmount = double.tryParse(_betController.text) ?? 10.0;
    final double winnings = betAmount * _currentMultiplier;

    // Refund bet + winnings
    widget.onBalanceChanged(widget.balance + winnings);
    SoundManager.playClick();

    setState(() {
      _hasCashedOut = true;
    });
  }

  void _triggerCrash() {
    _gameTimer?.cancel();
    _tickSoundTimer?.cancel();
    _pulseController.stop();

    SoundManager.playClick(); // Trigger crash audio indicator

    setState(() {
      _isCrashed = true;
      _isPlaying = false;
      _crashedAt = _crashPoint;
      _hasPlacedBet = false;

      // Add to recent history
      _history.insert(0, double.parse(_crashPoint.toStringAsFixed(2)));
      if (_history.length > 8) {
        _history.removeLast();
      }
    });

    _crashController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0736),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav & Title Headers
            _buildTopBar(),

            // Main landscape display area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left panel: Betting Control panel
                  Container(
                    width: 250.0,
                    padding: const EdgeInsets.all(12.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF07021C),
                      border: Border(right: BorderSide(color: Color(0xFF1E1558), width: 1.5)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTabsLayout(),
                          const SizedBox(height: 10.0),

                          // Bet Input Field
                          const Text('Bet Amount', style: TextStyle(color: Colors.grey, fontSize: 10.0, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4.0),
                          _buildBetInputField(),
                          const SizedBox(height: 6.0),

                          // 2x2 Preset Grid
                          _build2x2PresetsGrid(),
                          const SizedBox(height: 12.0),

                          // Auto Cashout Multiplier Row
                          _buildAutoCashoutToggleRow(),
                          if (_isAutoCashoutEnabled) ...[
                            const SizedBox(height: 6.0),
                            _buildAutoCashoutInputField(),
                          ],
                          const SizedBox(height: 14.0),

                          // Launch / Cashout Trigger Button
                          _buildActionButton(),
                        ],
                      ),
                    ),
                  ),

                  // Middle panel: Interactive Flight Graph
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // Flight Arena
                          Expanded(
                            child: _buildFlightArena(),
                          ),
                          const SizedBox(height: 8.0),

                          // History Multipliers List
                          _buildHistoryBar(),
                        ],
                      ),
                    ),
                  ),

                  // Right panel: Other active players simulation
                  _buildPlayersPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFF07021C),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          GestureDetector(
            onTap: widget.onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: const BoxDecoration(
                color: Color(0xFF2C256B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16.0),
            ),
          ),

          // Title
          Text(
            '999X CRASH SPACE',
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Color(0xFF9E84FF), blurRadius: 4.0),
                ],
              ),
            ),
          ),

          // Balance Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF160E45),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Color(0xFF00E5FF), size: 14.0),
                const SizedBox(width: 6.0),
                Text(
                  '₹${widget.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsLayout() {
    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: const Color(0xFF16103A),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2C256B),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'Manual',
                style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Auto (Soon)',
                style: TextStyle(color: Colors.grey, fontSize: 11.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetInputField() {
    return Container(
      height: 38.0,
      decoration: BoxDecoration(
        color: const Color(0xFF16103A),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF2C256B), width: 1.2),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('₹', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: _betController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // - Button
          _buildBetActionTextButton('-', () {
            if (_isPlaying) return;
            double val = double.tryParse(_betController.text) ?? 0.0;
            val = (val - 10.0).clamp(0.0, widget.balance);
            _betController.text = val.toStringAsFixed(0);
          }),

          // + Button
          _buildBetActionTextButton('+', () {
            if (_isPlaying) return;
            double val = double.tryParse(_betController.text) ?? 0.0;
            val = (val + 10.0).clamp(0.0, widget.balance);
            _betController.text = val.toStringAsFixed(0);
          }),
        ],
      ),
    );
  }

  Widget _buildBetActionTextButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF2C256B), width: 1.0),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _build2x2PresetsGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildFlatQuickBetButton('10', () {
              if (_isPlaying) return;
              _betController.text = '10';
            }),
            _buildFlatQuickBetButton('100', () {
              if (_isPlaying) return;
              _betController.text = '100';
            }),
          ],
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            _buildFlatQuickBetButton('500', () {
              if (_isPlaying) return;
              _betController.text = '500';
            }),
            _buildFlatQuickBetButton('1000', () {
              if (_isPlaying) return;
              _betController.text = '1000';
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFlatQuickBetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2C256B),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoCashoutToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Auto Cashout',
          style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 24.0,
          child: Switch(
            value: _isAutoCashoutEnabled,
            onChanged: (val) {
              setState(() {
                _isAutoCashoutEnabled = val;
              });
            },
            activeColor: const Color(0xFF00E5FF),
            activeTrackColor: const Color(0xFF160E45),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.black26,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoCashoutInputField() {
    return Container(
      height: 38.0,
      decoration: BoxDecoration(
        color: const Color(0xFF16103A),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF2C256B), width: 1.2),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('x', style: TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: _autoCashoutController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isPlaying) {
      if (_hasCashedOut) {
        return Container(
          height: 44.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFF00C853), width: 1.5),
          ),
          child: const Text(
            'CASHED OUT!',
            style: TextStyle(color: Color(0xFF00C853), fontSize: 13.0, fontWeight: FontWeight.bold),
          ),
        );
      } else {
        final double betAmount = double.tryParse(_betController.text) ?? 10.0;
        final double currentPayout = betAmount * _currentMultiplier;

        return ElevatedButton(
          onPressed: _cashOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(44.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            elevation: 5.0,
          ),
          child: Text(
            'CASH OUT (₹${currentPayout.toStringAsFixed(2)})',
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
        );
      }
    } else {
      return ElevatedButton(
        onPressed: _startBetting,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 5.0,
        ),
        child: const Text(
          'PLACE BET',
          style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildFlightArena() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF07021C),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF1E1558), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Grid Drawing
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                isPlaying: _isPlaying,
                isCrashed: _isCrashed,
                progress: _rocketProgress,
                particles: _particles,
              ),
            ),
          ),

          // Central Live Multiplier Value
          Align(
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _pulseController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCrashed) ...[
                    Text(
                      'CRASHED',
                      style: GoogleFonts.pressStart2p(
                        textStyle: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '${_crashedAt.toStringAsFixed(2)}x',
                      style: GoogleFonts.pressStart2p(
                        textStyle: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 26.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${_currentMultiplier.toStringAsFixed(2)}x',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(
                          color: _hasCashedOut ? const Color(0xFF00C853) : Colors.yellowAccent,
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: _hasCashedOut ? const Color(0xFF00C853).withOpacity(0.5) : Colors.yellow.withOpacity(0.5),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Explosive burst on crash
          if (_isCrashed)
            Positioned.fill(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _crashController, curve: Curves.easeOutBack),
                child: Center(
                  child: Container(
                    width: 90.0,
                    height: 90.0,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2.0),
                    ),
                    child: const Icon(Icons.flash_on, color: Colors.orange, size: 48.0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryBar() {
    return SizedBox(
      height: 24.0,
      child: Row(
        children: [
          const Text(
            'Recent:',
            style: TextStyle(color: Colors.grey, fontSize: 9.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final double val = _history[index];
                final bool isHigh = val >= 2.0;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: isHigh ? const Color(0xFF00C853).withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: isHigh ? const Color(0xFF00C853) : Colors.red, width: 1.0),
                  ),
                  child: Text(
                    '${val.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: isHigh ? const Color(0xFF00C853) : Colors.redAccent,
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersPanel() {
    return Container(
      width: 170.0,
      decoration: const BoxDecoration(
        color: Color(0xFF07021C),
        border: Border(left: BorderSide(color: Color(0xFF1E1558), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            color: const Color(0xFF160E45),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Online players', style: TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold)),
                Text('${_players.length}', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9.0, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Players List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4.0),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: player.cashedOut ? const Color(0xFF00C853).withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 9.0)),
                          Text('₹${player.bet.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 8.0)),
                        ],
                      ),
                      if (player.cashedOut)
                        Text(
                          '${player.cashoutMultiplier?.toStringAsFixed(2)}x',
                          style: const TextStyle(color: Color(0xFF00C853), fontSize: 9.0, fontWeight: FontWeight.bold),
                        )
                      else
                        const Text(
                          'betting',
                          style: TextStyle(color: Colors.amber, fontSize: 8.0, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isPlaying;
  final bool isCrashed;
  final double progress;
  final List<_StarParticle> particles;

  _GridPainter({
    required this.isPlaying,
    required this.isCrashed,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid lines
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF1E1558).withOpacity(0.3)
      ..strokeWidth = 1.0;

    final double step = 30.0;
    for (double x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bezier Curve points
    final double startX = 40.0;
    final double startY = size.height - 40.0;
    final double endX = size.width - 40.0;
    final double endY = 40.0;

    final double midX = startX + (endX - startX) * progress;
    final double midY = startY + (endY - startY) * math.sin(progress * math.pi / 2);

    // Draw trajectory path trace
    if (isPlaying || isCrashed) {
      final Path tracePath = Path()..moveTo(startX, startY);

      // Draw quadratic bezier approximation
      for (double t = 0.0; t <= progress; t += 0.02) {
        final double currX = startX + (endX - startX) * t;
        final double currY = startY + (endY - startY) * math.sin(t * math.pi / 2);
        tracePath.lineTo(currX, currY);
      }

      // Neon rocket trace stroke paint
      final Paint tracePaint = Paint()
        ..color = isCrashed ? Colors.redAccent.withOpacity(0.5) : const Color(0xFF00E5FF)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawPath(tracePath, tracePaint);

      // Trajectory gradient fill
      final Path fillPath = Path()
        ..moveTo(startX, startY);
      for (double t = 0.0; t <= progress; t += 0.02) {
        final double currX = startX + (endX - startX) * t;
        final double currY = startY + (endY - startY) * math.sin(t * math.pi / 2);
        fillPath.lineTo(currX, currY);
      }
      fillPath.lineTo(midX, startY);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            isCrashed ? Colors.red.withOpacity(0.1) : const Color(0xFF00E5FF).withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(startX, endY, endX, startY))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw particle trail emitters
    for (var p in particles) {
      final Paint pPaint = Paint()
        ..color = const Color(0xFFFFD600).withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, pPaint);
    }

    // Draw Rocket tip marker
    if ((isPlaying || isCrashed) && !isCrashed) {
      final Paint rocketCorePaint = Paint()
        ..color = const Color(0xFFFFD600)
        ..style = PaintingStyle.fill;

      // Rocket flame / glow marker
      canvas.drawCircle(Offset(midX, midY), 8.0, rocketCorePaint);
      canvas.drawCircle(
        Offset(midX, midY),
        14.0,
        Paint()
          ..color = const Color(0xFFFFD600).withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}
