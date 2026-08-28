import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/win_overlay_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';
import '../utils/sound_manager.dart';
import '../utils/sound_helper.dart' as helper;

class MinesGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const MinesGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<MinesGameScreen> createState() => _MinesGameScreenState();
}

class _MinesTile {
  bool isMine = false;
  bool isRevealed = false;
  bool isExploded = false;
}

class _MinesGameScreenState extends State<MinesGameScreen> {
  final _betController = TextEditingController(text: '10');

  bool _isPlaying = false;
  bool _gameOver = false;
  int _minesCount = 4;
  int _revealedGems = 0;
  bool _isAutoMode = false; // Manual vs Auto tabs

  List<_MinesTile> _tiles = List.generate(25, (_) => _MinesTile());
  final List<double> _historyList = [1.96, 1.96, 0.00, 2.55, 0.00, 1.18];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _betController.addListener(() => setState(() {}));
    SoundManager.soundOn = widget.soundOn;
  }

  @override
  void dispose() {
    _betController.dispose();
    super.dispose();
  }

  // Combination formula (nCr)
  double _nCr(int n, int r) {
    if (r < 0 || r > n) return 0.0;
    if (r == 0 || r == n) return 1.0;
    double val = 1.0;
    for (int i = 1; i <= r; i++) {
      val = val * (n - r + i) / i;
    }
    return val;
  }

  // Calculate Stake/BC.Game style multiplier
  double _calculateMultiplier(int totalMines, int gems) {
    if (gems == 0) return 1.0;
    if (gems > 25 - totalMines) return 0.0;

    double totalCombinations = _nCr(25, gems);
    double safeCombinations = _nCr(25 - totalMines, gems);
    if (safeCombinations == 0) return 0.0;

    // Payout = 0.99 (house edge) * (total / safe)
    double result = 0.99 * (totalCombinations / safeCombinations);
    return double.parse(result.toStringAsFixed(2));
  }

  // Calculate current multiplier
  double get _currentMultiplier => _calculateMultiplier(_minesCount, _revealedGems);

  // Calculate next multiplier
  double get _nextMultiplier => _calculateMultiplier(_minesCount, _revealedGems + 1);

  void _startGame() {
    if (_isPlaying) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;

    if (!isDemoMode && bet > widget.balance) {
      _showDialog('INSUFFICIENT BALANCE', 'You do not have enough balance to place this bet.');
      return;
    }

    if (_minesCount < 1 || _minesCount > 24) {
      _showDialog('INVALID MINES', 'Please select between 1 and 24 mines.');
      return;
    }

    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance - bet);
    }

    SoundManager.playClick();

    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _revealedGems = 0;

      // Reset tiles
      _tiles = List.generate(25, (_) => _MinesTile());

      // Place mines randomly
      int minesPlaced = 0;
      while (minesPlaced < _minesCount) {
        int index = _random.nextInt(25);
        if (!_tiles[index].isMine) {
          _tiles[index].isMine = true;
          minesPlaced++;
        }
      }
    });
  }

  void _revealTile(int index) {
    if (!_isPlaying || _tiles[index].isRevealed || _gameOver) return;

    setState(() {
      _tiles[index].isRevealed = true;

      if (_tiles[index].isMine) {
        // Exploded! Game Over.
        _tiles[index].isExploded = true;
        _gameOver = true;
        _isPlaying = false;

        _historyList.insert(0, 0.0);
        if (_historyList.length > 10) {
          _historyList.removeLast();
        }

        helper.playLose();

        // Reveal all tiles
        for (var tile in _tiles) {
          tile.isRevealed = true;
        }

        _showStatusMessage(
          title: 'BOOM!',
          message: 'You hit a mine! Bet forfeited.',
          isWin: false,
        );
      } else {
        // Safe! Gem found.
        _revealedGems++;
        helper.playTick();

        // Check if all gems are revealed
        int maxGems = 25 - _minesCount;
        if (_revealedGems == maxGems) {
          _cashOut();
        }
      }
    });
  }

  void _pickRandomTile() {
    if (!_isPlaying || _gameOver) return;
    List<int> unrevealedIndices = [];
    for (int i = 0; i < _tiles.length; i++) {
      if (!_tiles[i].isRevealed) {
        unrevealedIndices.add(i);
      }
    }
    if (unrevealedIndices.isNotEmpty) {
      final randomIndex = unrevealedIndices[_random.nextInt(unrevealedIndices.length)];
      _revealTile(randomIndex);
    }
  }

  void _cashOut() {
    if (!_isPlaying || _revealedGems == 0) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;
    final double winAmount = bet * _currentMultiplier;

    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance + winAmount);
    }

    helper.playWin();

    _historyList.insert(0, _currentMultiplier);
    if (_historyList.length > 10) {
      _historyList.removeLast();
    }

    setState(() {
      _isPlaying = false;
      _gameOver = true;

      // Reveal all tiles to show mines/gems positions
      for (var tile in _tiles) {
        tile.isRevealed = true;
      }
    });

    _showStatusMessage(
      title: 'CASHOUT SUCCESS!',
      message: isDemoMode
          ? 'Demo Won ${_currentMultiplier.toStringAsFixed(2)}x!'
          : 'You won ₹${winAmount.toStringAsFixed(2)} (${_currentMultiplier.toStringAsFixed(2)}x)!',
      isWin: true,
    );
  }

  void _showStatusMessage({required String title, required String message, required bool isWin}) {
    // Toast disabled to prevent duplicate overlay over WinOverlayCard
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        title: Text(
          title,
          style: GoogleFonts.pressStart2p(
            textStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 12.0),
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 14.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFF161618),
      body: AnimatedGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header bar styled exactly like Coin Flip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isPlaying ? null : widget.onBackPressed,
                    ),
                    Text(
                      'MINES MULTIPLIER',
                      style: GoogleFonts.alfaSlabOne(
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16.0, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    // Balance Capsule (Coin Flip Style)
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

              // Main Split Panel
              Expanded(
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Panel: Bet Controls
                          SingleChildScrollView(
                            child: _buildBetControls(bet, isLandscape: true),
                          ),
                          const SizedBox(width: 12.0),
                          // Right Panel: 5x5 Mines Playfield
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                              child: _buildMinesPlayfield(),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Top Panel: Playfield
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildMinesPlayfield(),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          // Bottom Panel: Controls
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildBetControls(bet, isLandscape: false),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBetControls(double bet, {required bool isLandscape}) {
    return Container(
      width: isLandscape ? 280.0 : null,
      margin: isLandscape ? const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 12.0) : null,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Manual / Auto Tabs
            _buildTabBar(),
            const SizedBox(height: 10.0),

            // Bet Amount Label
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

            // Amount Text Input Box (Coin Flip style)
            Container(
              height: 38.0,
              decoration: BoxDecoration(
                color: const Color(0xFF181A1F),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
              ),
              child: Row(
                children: [
                  // Rupees gold badge
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
                      enabled: !_isPlaying,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                      ),
                    ),
                  ),
                  // Inline actions: 1/2 and 2x
                  Row(
                    children: [
                      _buildBetActionTextButton('1/2', () {
                        if (_isPlaying) return;
                        final double current = double.tryParse(_betController.text) ?? 0.0;
                        final double next = (current / 2).clamp(0.0, widget.balance);
                        _betController.text = next.toStringAsFixed(0);
                      }),
                      _buildBetActionTextButton('2x', () {
                        if (_isPlaying) return;
                        final double current = double.tryParse(_betController.text) ?? 0.0;
                        final double next = (current * 2).clamp(0.0, widget.balance);
                        _betController.text = next.toStringAsFixed(0);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6.0),

            // Flat Quick Bet buttons in 2x2 grid (Coin Flip style)
            Column(
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
            ),
            const SizedBox(height: 10.0),

            // Mines Slider Label
            Row(
              children: [
                const Text(
                  'Mines',
                  style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11.0),
                ),
                const Spacer(),
                Text(
                  '$_minesCount',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                ),
              ],
            ),
            const SizedBox(height: 2.0),

            // Custom Slider layout matching CoinFlip style
            Row(
              children: [
                const Text(
                  '1',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11.0),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00C853),
                      inactiveTrackColor: const Color(0xFF181A1F),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF00C853).withValues(alpha: 0.2),
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                    ),
                    child: Slider(
                      value: _minesCount.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 23,
                      onChanged: _isPlaying
                          ? null
                          : (val) {
                              setState(() {
                                _minesCount = val.toInt();
                              });
                            },
                    ),
                  ),
                ),
                const Text(
                  '24',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11.0),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Main Play / Cash Out Button (Coin Flip Style: Green Bet / Purple Cashout with White Text)
            GestureDetector(
              onTap: () {
                if (_isPlaying) {
                  _cashOut();
                } else {
                  _startGame();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPlaying
                      ? const Color(0xFF311B92) // Purple Cashout (CoinFlip style)
                      : const Color(0xFF00C853), // Green Bet (CoinFlip style)
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPlaying ? const Color(0xFF311B92) : const Color(0xFF00C853)).withValues(alpha: 0.3),
                      blurRadius: 6.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _isPlaying
                      ? 'Cash Out (₹${(bet * _currentMultiplier).toStringAsFixed(2)})'
                      : 'Bet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),

            // Pick a Tile Randomly button
            if (_isPlaying) ...[
              GestureDetector(
                onTap: _pickRandomTile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F36),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 13.0),
                      SizedBox(width: 6.0),
                      Text(
                        'Pick a Tile Randomly',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
            ],

            // Remaining Gems Info Row
            _buildInfoRow('Remaining Gems', '${25 - _minesCount - _revealedGems}'),
            const SizedBox(height: 6.0),

            // Total Profit Info Row
            _buildInfoRow('Total profit (${_currentMultiplier.toStringAsFixed(2)}x)', '₹${(bet * _currentMultiplier).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.0),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAutoMode = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !_isAutoMode ? const Color(0xFF2E3138) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'Manual',
                  style: TextStyle(
                    color: !_isAutoMode ? Colors.white : Colors.grey[400],
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAutoMode = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isAutoMode ? const Color(0xFF2E3138) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'Auto',
                  style: TextStyle(
                    color: _isAutoMode ? Colors.white : Colors.grey[400],
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetActionTextButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32.0,
        height: 38.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.0)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFlatQuickBetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2E3138),
              borderRadius: BorderRadius.circular(2.0),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryBar() {
    return SizedBox(
      height: 24.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _historyList.length,
        itemBuilder: (context, index) {
          final val = _historyList[index];
          final isWin = val > 1.0;
          return Container(
            margin: const EdgeInsets.only(right: 5.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: isWin ? const Color(0xFF00E676) : const Color(0xFF2E3138),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '${val.toStringAsFixed(2)}x',
              style: TextStyle(
                color: isWin ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinesPlayfield() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(8.0),
        image: const DecorationImage(
          image: AssetImage('assets/mines/bg_frame.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic aspect-ratio math to ensure 5x5 grid NEVER overflows screen height
          final double playfieldWidth = constraints.maxWidth;
          final double playfieldHeight = constraints.maxHeight;

          const double spacing = 4.0;
          final double maxGridWidth = playfieldWidth * 0.90;
          final double maxGridHeight = playfieldHeight * 0.74;

          final double maxCardWidth = (maxGridWidth - (4 * spacing)) / 5;
          final double maxCardHeight = (maxGridHeight - (4 * spacing)) / 5;

          final double tileSize = math.max(10.0, math.min(maxCardWidth, maxCardHeight));

          final double gridWidth = (5 * tileSize) + (4 * spacing);
          final double gridHeight = (5 * tileSize) + (4 * spacing);

          final double gridLeft = (playfieldWidth - gridWidth) / 2;
          final double gridTop = (playfieldHeight - gridHeight) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Crack Decor (Top Left of Grid)
              Positioned(
                left: math.max(0.0, gridLeft - 8.0),
                top: math.max(0.0, gridTop - 6.0),
                width: 32.0,
                height: 12.0,
                child: Image.asset(
                  'assets/mines/crack_decor.png',
                  fit: BoxFit.contain,
                ),
              ),

              // 2. Skull Decor (Top Right of Grid)
              Positioned(
                right: math.max(0.0, gridLeft - 10.0),
                top: math.max(0.0, gridTop - 16.0),
                width: 52.0,
                height: 24.0,
                child: Image.asset(
                  'assets/mines/skull_decor.png',
                  fit: BoxFit.contain,
                ),
              ),

              // 3. Multiplier History & Next Multiplier Bar (top-left)
              Positioned(
                top: 8.0,
                left: 8.0,
                right: 8.0,
                child: Row(
                  children: [
                    Expanded(child: _buildHistoryBar()),
                    const SizedBox(width: 8.0),
                    // Current Next Multiplier badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        '${_isPlaying ? _nextMultiplier.toStringAsFixed(2) : _calculateMultiplier(_minesCount, 1).toStringAsFixed(2)}x',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.0),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Main 5x5 Grid Area
              Positioned(
                left: gridLeft,
                top: gridTop,
                width: gridWidth,
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 25,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    return MinesTileWidget(
                      key: ValueKey('tile_$index'),
                      index: index,
                      tile: tile,
                      isGameOver: _gameOver,
                      isPlaying: _isPlaying,
                      onTap: () => _revealTile(index),
                    );
                  },
                ),
              ),

              // 5. Bottom Cashout Next Tile Details
              if (_isPlaying && _revealedGems > 0)
                Positioned(
                  bottom: 6.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2024).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontFamily: 'Roboto'),
                          children: [
                            const TextSpan(text: 'Cashout on next tile: '),
                            TextSpan(
                              text: '₹${((double.tryParse(_betController.text) ?? 0.0) * _nextMultiplier).toStringAsFixed(2)} ',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '(${_nextMultiplier.toStringAsFixed(2)}x)',
                              style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 6. Win Overlay Card Centered inside Playfield Box (Stake style overlay)
              if (_gameOver && _revealedGems > 0)
                Center(
                  child: WinOverlayCard(
                    multiplier: _currentMultiplier,
                    winAmount: (double.tryParse(_betController.text) ?? 0.0) * _currentMultiplier,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class MinesTileWidget extends StatefulWidget {
  final int index;
  final _MinesTile tile;
  final bool isGameOver;
  final bool isPlaying;
  final VoidCallback onTap;

  const MinesTileWidget({
    super.key,
    required this.index,
    required this.tile,
    required this.isGameOver,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<MinesTileWidget> createState() => _MinesTileWidgetState();
}

class _MinesTileWidgetState extends State<MinesTileWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.isPlaying && !widget.tile.isRevealed && !widget.isGameOver) {
          widget.onTap();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()..scale(animation.value, 1.0, 1.0),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: child,
          );
        },
        child: widget.tile.isRevealed
            ? _buildBackCard(key: const ValueKey('back'))
            : _buildFrontCard(key: const ValueKey('front')),
      ),
    );
  }

  // Front card (Hidden / Unrevealed Tile - CoinFlip styled dark tile)
  Widget _buildFrontCard({required Key key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: const Color(0xFF2E3138),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF42454E), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 2.0,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: const Color(0xFF23252B),
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),
    );
  }

  // Back card (Revealed Tile)
  Widget _buildBackCard({required Key key}) {
    final bool isMine = widget.tile.isMine;
    final bool isExploded = widget.tile.isExploded;

    if (isMine) {
      // BOMB/MINE CARD
      return Container(
        key: key,
        decoration: BoxDecoration(
          color: isExploded ? const Color(0xFFD50000) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isExploded ? const Color(0xFFFFEB3B) : const Color(0xFF37474F),
            width: isExploded ? 2.0 : 1.0,
          ),
          boxShadow: isExploded
              ? [
                  BoxShadow(
                    color: const Color(0xFFD50000).withValues(alpha: 0.6),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  )
                ]
              : null,
        ),
        child: Opacity(
          opacity: widget.tile.isExploded || !widget.isGameOver ? 1.0 : 0.45,
          child: Container(
            padding: const EdgeInsets.all(5.0),
            child: Image.asset(
              'assets/mines/bomb.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else {
      // GEM CARD (glowing purple square with premium diamond)
      return Container(
        key: key,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8C34FF),
              Color(0xFF5D00E6),
            ],
          ),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFFB388FF).withValues(alpha: 0.5), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C34FF).withValues(alpha: 0.4),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: widget.isPlaying || !widget.isGameOver ? 1.0 : 0.45,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom painted highly detailed 3D Diamond Vector
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CustomPaint(
                    painter: DiamondPainter(),
                  ),
                ),
              ),
              // Glow spark reflection
              Positioned(
                top: 4.0,
                left: 4.0,
                child: Icon(
                  Icons.star,
                  size: 10.0,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// 3D Facet Diamond Vector Painter
class DiamondPainter extends CustomPainter {
  const DiamondPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Define vertices for a diamond gemstone shape
    final pTopLeft = Offset(w * 0.28, h * 0.22);
    final pTopRight = Offset(w * 0.72, h * 0.22);
    final pMidLeft = Offset(w * 0.1, h * 0.44);
    final pMidRight = Offset(w * 0.9, h * 0.44);
    final pBottom = Offset(w * 0.5, h * 0.88);
    final pCenter = Offset(w * 0.5, h * 0.41);

    void drawFacet(List<Offset> points, Color color) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint..color = color);
    }

    // Gradient faceting overlays (varying opacity levels)
    final Color cTable = Colors.white.withValues(alpha: 0.55);
    final Color cLight1 = Colors.white.withValues(alpha: 0.35);
    final Color cLight2 = Colors.white.withValues(alpha: 0.2);
    final Color cDark1 = Colors.black.withValues(alpha: 0.15);
    final Color cDark2 = Colors.black.withValues(alpha: 0.28);

    // Facet rendering
    drawFacet([pTopLeft, pTopRight, pCenter], cTable);
    drawFacet([pTopLeft, pMidLeft, pCenter], cLight1);
    drawFacet([pTopRight, pMidRight, pCenter], cLight2);
    drawFacet([pMidLeft, pBottom, pCenter], cDark1);
    drawFacet([pMidRight, pBottom, pCenter], cDark2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// End of MinesGameScreen

