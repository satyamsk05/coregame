import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';

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
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _betController.addListener(() => setState(() {}));
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

        // Check if all gems are revealed
        int maxGems = 25 - _minesCount;
        if (_revealedGems == maxGems) {
          _cashOut();
        }
      }
    });
  }

  void _cashOut() {
    if (!_isPlaying || _revealedGems == 0) return;

    final double bet = double.tryParse(_betController.text) ?? 0.0;
    final bool isDemoMode = bet <= 0.0;
    final double winAmount = bet * _currentMultiplier;

    if (!isDemoMode) {
      widget.onBalanceChanged(widget.balance + winAmount);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: isWin
                ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E575)])
                : const LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFFF5252)]),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: (isWin ? const Color(0xFF00C853) : const Color(0xFFFF1744)).withOpacity(0.4),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(isWin ? Icons.stars : Icons.error_outline, color: Colors.white, size: 24.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
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
              // Header bar
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

              // Main Split Panel
              Expanded(
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Panel: Bet Controls
                          _buildBetControls(bet, isLandscape: true),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manual / Auto Tabs
          _buildTabBar(),
          const SizedBox(height: 12.0),

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

          // Amount Text Input Box
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
                // Inline multiplier actions
                Row(
                  children: [
                    _buildBetActionTextButton('1/2', () {
                      if (_isPlaying) return;
                      final double current = double.tryParse(_betController.text) ?? 1.0;
                      _betController.text = (current / 2).toStringAsFixed(1);
                    }),
                    _buildBetActionTextButton('2x', () {
                      if (_isPlaying) return;
                      final double current = double.tryParse(_betController.text) ?? 1.0;
                      _betController.text = (current * 2).toStringAsFixed(1);
                    }),
                    _buildBetActionIconButton(Icons.unfold_more, () {
                      if (_isPlaying) return;
                      final double current = double.tryParse(_betController.text) ?? 1.0;
                      if (current < widget.balance) {
                        _betController.text = widget.balance.toInt().toString();
                      } else {
                        _betController.text = '10';
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),

          // Flat Quick Bet buttons in 2x2 grid
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
          const SizedBox(height: 12.0),

          // Mines Selection Row
          Row(
            children: [
              const Text(
                'Mines',
                style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11.0),
              ),
              const Spacer(),
              // Custom Mines dropdown selection
              Container(
                height: 28.0,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF181A1F),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: const Color(0xFF2C2F36), width: 1.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _minesCount,
                    dropdownColor: const Color(0xFF1E2024),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                    items: List.generate(24, (index) => index + 1).map((int val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text('$val'),
                      );
                    }).toList(),
                    onChanged: _isPlaying
                        ? null
                        : (newValue) {
                            setState(() {
                              _minesCount = newValue ?? 4;
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
          const SizedBox(height: 12.0),

          // Play Bet / Cash Out Button
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
                    ? const Color(0xFF311B92) // Purple Cashout
                    : const Color(0xFF00C853), // Green Bet
                borderRadius: BorderRadius.circular(6.0),
                boxShadow: [
                  BoxShadow(
                    color: (_isPlaying ? const Color(0xFF311B92) : const Color(0xFF00C853)).withOpacity(0.3),
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
                    style: TextStyle(color: Colors.grey[400], fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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

  Widget _buildBetActionIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32.0,
        height: 38.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.0)),
        ),
        child: Icon(icon, color: Colors.white, size: 16.0),
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

  Widget _buildMinesPlayfield() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 2.0),
      ),
      child: Stack(
        children: [
          // Multiplier Bubble indicator (top-left)
          Positioned(
            top: 12.0,
            left: 12.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _isPlaying 
                    ? '${_nextMultiplier.toStringAsFixed(2)}x'
                    : '${_calculateMultiplier(_minesCount, 1).toStringAsFixed(2)}x',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
              ),
            ),
          ),

          // Main 5x5 Grid
          Positioned.fill(
            top: 50.0,
            bottom: 12.0,
            left: 12.0,
            right: 12.0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 6.0;
                final double availableWidth = constraints.maxWidth;
                final double availableHeight = constraints.maxHeight;

                final double cardWidth = (availableWidth - (4 * spacing)) / 5;
                final double cardHeight = (availableHeight - (4 * spacing)) / 5;

                // Avoid division by zero
                final double aspectRatio = cardHeight > 0 ? (cardWidth / cardHeight) : 1.0;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 25,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    return _buildTileCard(index, tile);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileCard(int index, _MinesTile tile) {
    final bool isRevealed = tile.isRevealed;
    final bool isMine = tile.isMine;
    final bool isExploded = tile.isExploded;

    Color cardBgColor;
    Widget cardChild;

    if (!isRevealed) {
      cardBgColor = const Color(0xFF2E3138);
      cardChild = const SizedBox();
    } else {
      if (isMine) {
        cardBgColor = isExploded ? const Color(0xFFFF1744) : const Color(0xFFC62828).withOpacity(0.65);
        cardChild = Icon(
          isExploded ? Icons.whatshot : Icons.dangerous,
          color: Colors.white,
          size: 22.0,
        );
      } else {
        cardBgColor = const Color(0xFF00E5FF).withOpacity(0.8);
        cardChild = const Icon(
          Icons.diamond,
          color: Colors.white,
          size: 22.0,
        );
      }
    }

    return GestureDetector(
      onTap: () => _revealTile(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isExploded 
                ? const Color(0xFFFFD54F) 
                : (isRevealed ? Colors.white.withOpacity(0.4) : const Color(0xFF424242)),
            width: isExploded ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (!isRevealed)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 2.0,
              ),
          ],
        ),
        child: Center(
          child: cardChild,
        ),
      ),
    );
  }
}
