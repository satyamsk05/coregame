import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../utils/sound_manager.dart';

class TowerLegendScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;
  final String nickname;
  final String avatarPath;

  const TowerLegendScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
    required this.nickname,
    required this.avatarPath,
  });

  @override
  State<TowerLegendScreen> createState() => _TowerLegendScreenState();
}

class _TowerLegendScreenState extends State<TowerLegendScreen> {
  // Game Configuration & State
  double _betAmount = 100.0;
  late double _balance;
  String _selectedDifficulty = 'EASY'; // EASY, MEDIUM, HARD, EXPERT, MASTER
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _activeRow = 8; // 8 is the bottom-most row, 0 is the top-most row
  double _currentMultiplier = 1.0;
  int? _failedRow;
  int? _failedCol;
  
  // Custom dropdown open state
  bool _isDropdownOpen = false;

  // Grid Data: 9 rows x 4 columns
  // Each cell can be: 'hidden', 'fruit', 'skull'
  final List<List<String>> _gridStates = List.generate(
    9,
    (_) => List.generate(4, (_) => 'hidden'),
  );

  // Skull placements per row: mapping row index (0-8) to set of skull column indices
  final Map<int, Set<int>> _rowSkulls = {};

  // Text editing controller for bet input
  late TextEditingController _betController;

  // Random generator
  final Random _random = Random();

  // Multipliers configuration per difficulty
  final Map<String, List<double>> _multipliers = {
    'EASY': [12.6, 9.5, 7.1, 5.3, 4.0, 3.0, 2.2, 1.7, 1.3],
    'MEDIUM': [486.4, 243.2, 121.6, 60.8, 30.4, 15.2, 7.6, 3.8, 1.9],
    'HARD': [249036.8, 62259.2, 15564.8, 3891.2, 972.8, 243.2, 60.8, 15.2, 3.8],
    'EXPERT': [500000.0, 100000.0, 25000.0, 6000.0, 1500.0, 400.0, 100.0, 25.0, 5.0],
    'MASTER': [1000000.0, 200000.0, 45000.0, 10000.0, 2500.0, 600.0, 150.0, 35.0, 7.0],
  };

  @override
  void initState() {
    super.initState();
    _balance = widget.balance;
    SoundManager.soundOn = widget.soundOn;
    _betController = TextEditingController(text: _betAmount.toStringAsFixed(0));
    _betController.addListener(() {
      final val = double.tryParse(_betController.text);
      if (val != null && val > 0) {
        setState(() {
          _betAmount = val;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant TowerLegendScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.balance != oldWidget.balance) {
      setState(() {
        _balance = widget.balance;
      });
    }
    if (widget.soundOn != oldWidget.soundOn) {
      SoundManager.soundOn = widget.soundOn;
    }
  }

  @override
  void dispose() {
    _betController.dispose();
    super.dispose();
  }

  // Helper to get fruit image path for current difficulty
  String _getFruitAsset() {
    switch (_selectedDifficulty) {
      case 'EASY':
        return 'assets/images/apple.png';
      case 'MEDIUM':
        return 'assets/images/banana.png';
      case 'HARD':
        return 'assets/images/watermelon.png';
      case 'EXPERT':
        return 'assets/images/mango.png';
      case 'MASTER':
        return 'assets/images/avocado.png';
      default:
        return 'assets/images/apple.png';
    }
  }

  // Potential winnings helper
  double get _potentialWin {
    if (_activeRow == 8 && _currentMultiplier == 1.0) return 0.0;
    return _betAmount * _currentMultiplier;
  }

  // Start game and place bet
  void _startGame() {
    if (_isPlaying) return;

    if (_betAmount <= 0) return;
    
    if (_betAmount > _balance) {
      _showErrorDialog('You do not have enough balance to place this bet.');
      return;
    }
    
    SoundManager.playClick();
    
    setState(() {
      _balance -= _betAmount;
      widget.onBalanceChanged(_balance);
      _isPlaying = true;
      _isGameOver = false;
      _failedRow = null;
      _failedCol = null;
      _activeRow = 8; // Reset to bottom row
      _currentMultiplier = 1.0;
      
      // Clear grid states
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 4; c++) {
          _gridStates[r][c] = 'hidden';
        }
      }

      // Generate skull placements for each row
      _rowSkulls.clear();
      int skullsCount = 1;
      if (_selectedDifficulty == 'EASY') {
        skullsCount = 1;
      } else if (_selectedDifficulty == 'MEDIUM') {
        skullsCount = 2;
      } else {
        skullsCount = 3; // Hard, Expert, Master have 3 skulls per row
      }

      for (int r = 0; r < 9; r++) {
        final Set<int> skulls = {};
        while (skulls.length < skullsCount) {
          skulls.add(_random.nextInt(4));
        }
        _rowSkulls[r] = skulls;
      }
      
      _isDropdownOpen = false;
    });
  }

  // Cash out and end game as winner
  void _cashOut() {
    if (!_isPlaying || _isGameOver || _activeRow == 8 && _currentMultiplier == 1.0) return;
    
    final winAmount = _potentialWin;
    SoundManager.playClick();
    setState(() {
      _balance += winAmount;
      widget.onBalanceChanged(_balance);
      _isPlaying = false;
      _isGameOver = false;
    });

    _showWinningsDialog(winAmount);
  }

  // Show winnings dialog
  void _showWinningsDialog(double amount) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6), // Dim background
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2E35), // Slate card background
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top multiplier row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sparkles Left
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '✦',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 24,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-2, -6),
                          child: const Text(
                            '✦',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentMultiplier.toStringAsFixed(2)}x',
                      style: GoogleFonts.sourceSans3(
                        color: const Color(0xFF10B981),
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sparkles Right
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(2, -6),
                          child: const Text(
                            '✦',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Text(
                          '✦',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Bottom winnings row
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        amount.toStringAsFixed(0),
                        style: GoogleFonts.sourceSans3(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Orange Coin
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE05315),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  // Show error dialog for insufficient balance
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'ERROR',
          style: GoogleFonts.creepster(
            color: const Color(0xFFEF4444),
            fontSize: 24,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: GoogleFonts.jaldi(
            color: Colors.white,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.jaldi(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Handle grid button click
  void _onCellClicked(int row, int col) {
    // Only allow clicking on the active row
    if (!_isPlaying || _isGameOver || row != _activeRow) return;

    final isSkull = _rowSkulls[row]!.contains(col);
    SoundManager.playClick();

    setState(() {
      if (isSkull) {
        // Revealed skull -> game over
        _failedRow = row;
        _failedCol = col;
        _isGameOver = true;
        _isPlaying = false;
        
        // Reveal all cards on the board (skulls and fruits)
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 4; c++) {
            if (_rowSkulls[r]!.contains(c)) {
              _gridStates[r][c] = 'skull';
            } else {
              _gridStates[r][c] = 'fruit';
            }
          }
        }
      } else {
        // Revealed fruit -> advance to next row
        _gridStates[row][col] = 'fruit';
        
        // Update multiplier for the cleared row
        final listMultipliers = _multipliers[_selectedDifficulty]!;
        // listMultipliers has length 9, corresponding from top (index 0) to bottom (index 8)
        // activeRow goes from 8 to 0. So index in multipliers array is activeRow.
        _currentMultiplier = listMultipliers[row];

        if (_activeRow > 0) {
          _activeRow--; // Unlock next row
        } else {
          // Cleared the top row! Auto cash out and win
          final winAmount = _potentialWin;
          _balance += winAmount;
          widget.onBalanceChanged(_balance);
          _isPlaying = false;
          _isGameOver = false;
          _showWinningsDialog(winAmount);
        }
      }
    });
  }

  // Custom Dropdown Picker widget (button only)
  Widget _buildDifficultyDropdown() {
    return GestureDetector(
      onTap: () {
        if (!_isPlaying) {
          SoundManager.playClick();
          setState(() {
            _isDropdownOpen = !_isDropdownOpen;
          });
        }
      },
      child: Container(
        width: 203,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF17191A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isDropdownOpen ? const Color(0xFF818CF8) : const Color(0xFF323638),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Fruit icon (left: 86px absolute, container left: 73px -> 13px relative)
            Positioned(
              left: 13,
              top: 8,
              width: 20,
              height: 20,
              child: Image.asset(
                _getFruitAsset(),
                fit: BoxFit.contain,
              ),
            ),
            // Text EASY/etc (left: 148px absolute, container left: 73px -> 75px relative)
            Positioned(
              left: 75,
              top: 8,
              child: Text(
                _selectedDifficulty,
                style: GoogleFonts.creepster(
                  color: const Color(0xCCFFFEFE),
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Styled Chevron Box (left: 238px absolute, container left: 73px -> 165px relative)
            Positioned(
              left: 165,
              top: 7,
              width: 26,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF333536),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Dark space background
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 917,
            height: 412,
            child: Stack(
              children: [
                // 1. Foundational Background Image
                Positioned(
                  left: -1,
                  top: -34,
                  width: 919,
                  height: 459,
                  child: Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // 2. Right Archway Background Blob
                Positioned(
                  left: 353,
                  top: 0,
                  width: 524,
                  height: 397,
                  child: Image.asset(
                    'assets/images/blob.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // 3. Right Archway Stone Frame Overlay
                Positioned(
                  left: 353,
                  top: 0,
                  width: 524,
                  height: 397,
                  child: Image.asset(
                    'assets/images/right_arch.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // 4. Left Panel Stone Frame Overlay
                Positioned(
                  left: -71,
                  top: 31,
                  width: 495,
                  height: 346,
                  child: Image.asset(
                    'assets/images/left_panel.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // Balance Indicator Box
                Positioned(
                  left: 180,
                  top: 123,
                  width: 92,
                  height: 29,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF17191A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF596C2E),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Coin Icon
                        const Positioned(
                          left: 8,
                          top: 7,
                          child: Icon(
                            Icons.monetization_on,
                            color: Color(0xFFFBBF24),
                            size: 15,
                          ),
                        ),
                        // Balance text
                        Positioned(
                          left: 28,
                          top: 4,
                          width: 58,
                          child: Text(
                            _balance.toStringAsFixed(0),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: GoogleFonts.jaldi(
                              color: const Color(0x80DEDAD0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. BET AMOUNT Label
                Positioned(
                  left: 76,
                  top: 142,
                  width: 81,
                  height: 15,
                  child: Text(
                    'BET AMOUNT',
                    style: GoogleFonts.jaldi(
                      color: const Color(0x80DEDAD0),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),

                // 4. Bet Input Container & Controls
                Positioned(
                  left: 73,
                  top: 157,
                  width: 203,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF17191A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF323638),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Currency symbol
                        Positioned(
                          left: 11,
                          top: 2,
                          child: Text(
                            '₹',
                            style: GoogleFonts.sourceSans3(
                              color: const Color(0xFFAD9B9B),
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        // Number Input TextField
                        Positioned(
                          left: 45,
                          top: 0,
                          width: 100,
                          height: 36,
                          child: TextField(
                            controller: _betController,
                            keyboardType: TextInputType.number,
                            enabled: !_isPlaying,
                            style: GoogleFonts.sourceSans3(
                              color: const Color(0xFF999393),
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 12),
                            ),
                          ),
                        ),
                        // '+' button
                        Positioned(
                          left: 148,
                          top: 0,
                          width: 26,
                          height: 36,
                          child: GestureDetector(
                            onTap: () {
                              if (!_isPlaying) {
                                SoundManager.playClick();
                                setState(() {
                                  _betAmount += 10;
                                  _betController.text = _betAmount.toStringAsFixed(0);
                                });
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Container(
                                width: 14,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333536),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+',
                                  style: GoogleFonts.creepster(
                                    color: const Color(0xCCFFFEFE),
                                    fontSize: 12,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // '-' button
                        Positioned(
                          left: 171,
                          top: 0,
                          width: 26,
                          height: 36,
                          child: GestureDetector(
                            onTap: () {
                              if (!_isPlaying && _betAmount > 10) {
                                SoundManager.playClick();
                                setState(() {
                                  _betAmount = max(10, _betAmount - 10);
                                  _betController.text = _betAmount.toStringAsFixed(0);
                                });
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Container(
                                width: 14,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333536),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '-',
                                  style: GoogleFonts.creepster(
                                    color: const Color(0xCCFFFEFE),
                                    fontSize: 12,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Presets (10+, 100+, 500+, 1000+)
                ..._buildPresetButtons(),

                // 6. SELECT DIFFICULTY Label
                Positioned(
                  left: 76,
                  top: 225,
                  width: 103,
                  height: 21,
                  child: Text(
                    'SELECT DIFFICULTY',
                    style: GoogleFonts.jaldi(
                      color: const Color(0x80DEDAD0),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),

                // 7. Custom Dropdown Difficulty Selector
                Positioned(
                  left: 73,
                  top: 239,
                  width: 203,
                  height: 36,
                  child: _buildDifficultyDropdown(),
                ),

                // 8. PLACE BET / CASH OUT Button
                Positioned(
                  left: 66,
                  top: 285,
                  width: 220,
                  height: 35,
                  child: GestureDetector(
                    onTap: () {
                      if (_isPlaying) {
                        _cashOut();
                      } else {
                        _startGame();
                      }
                    },
                    child: Image.asset(
                      _isPlaying 
                          ? 'assets/images/cashout.png'
                          : 'assets/images/btn_place_bet.png',
                      color: _isPlaying ? const Color(0xFFFBBF24) : null,
                      colorBlendMode: _isPlaying ? BlendMode.modulate : null,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                
                // Overlay text for PLACE BET / CASH OUT
                if (_isPlaying)
                  Positioned(
                    left: 66,
                    top: 285,
                    width: 220,
                    height: 35,
                    child: IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Cash out',
                            style: GoogleFonts.sourceSans3(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE05315),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${_potentialWin.toStringAsFixed(2)}',
                            style: GoogleFonts.sourceSans3(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 9. Interactive 9x4 Game Grid
                ..._buildGridButtons(),

                // Explosion Lottie Animation Overlay on GameOver Skull
                if (_isGameOver && _failedRow != null && _failedCol != null) ...[
                  Builder(
                    builder: (context) {
                      final List<double> colX = [467.0, 544.0, 621.0, 698.0];
                      final List<double> rowY = [88.0, 118.0, 147.0, 177.0, 207.0, 237.0, 267.0, 297.0, 329.0];
                      final double cX = colX[_failedCol!] + 34.5;
                      final double cY = rowY[_failedRow!] + 13.5;
                      return Positioned(
                        left: cX - 90.0,
                        top: cY - 63.0,
                        width: 180.0,
                        height: 126.0,
                        child: IgnorePointer(
                          child: Lottie.asset(
                            'assets/skull_boom.json',
                            repeat: false,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // 10. Dropdown choices panel overlaid on top
                if (_isDropdownOpen)
                  Positioned(
                    left: 73,
                    top: 275,
                    child: Container(
                      width: 203,
                      decoration: BoxDecoration(
                        color: const Color(0xFF17191A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF323638), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['EASY', 'MEDIUM', 'HARD', 'EXPERT', 'MASTER'].map((diff) {
                          String tempAsset = 'assets/images/apple.png';
                          if (diff == 'MEDIUM') {
                            tempAsset = 'assets/images/banana.png';
                          } else if (diff == 'HARD') {
                            tempAsset = 'assets/images/watermelon.png';
                          } else if (diff == 'EXPERT') {
                            tempAsset = 'assets/images/mango.png';
                          } else if (diff == 'MASTER') {
                            tempAsset = 'assets/images/avocado.png';
                          }

                          return GestureDetector(
                            onTap: () {
                              SoundManager.playClick();
                              setState(() {
                                _selectedDifficulty = diff;
                                _isDropdownOpen = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: _selectedDifficulty == diff 
                                  ? const Color(0xFF334155) 
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Image.asset(
                                    tempAsset,
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    diff,
                                    style: GoogleFonts.creepster(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Back Button
                Positioned(
                  left: 20,
                  top: 20,
                  child: GestureDetector(
                    onTap: _isPlaying ? null : widget.onBackPressed,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xAA17191A),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFF323638)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build preset buttons
  List<Widget> _buildPresetButtons() {
    final presets = [
      {'label': '10+', 'value': 10.0, 'left': 73.0},
      {'label': '100+', 'value': 100.0, 'left': 125.0},
      {'label': '500+', 'value': 500.0, 'left': 178.0},
      {'label': '1000+', 'value': 1000.0, 'left': 230.0},
    ];

    return presets.map((p) {
      final isSelected = _betAmount == p['value'];
      
      return Positioned(
        left: p['left'] as double,
        top: 197,
        width: 46,
        height: 22,
        child: GestureDetector(
          onTap: () {
            if (!_isPlaying) {
              SoundManager.playClick();
              setState(() {
                _betAmount = p['value'] as double;
                _betController.text = _betAmount.toStringAsFixed(0);
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF818CF8).withValues(alpha: 0.4) : const Color(0xFF292E2F),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF323638),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              p['label'] as String,
              style: GoogleFonts.jaldi(
                color: isSelected ? Colors.white : const Color(0x80DEDAD0),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Build grid buttons
  List<Widget> _buildGridButtons() {
    final List<Widget> widgets = [];
    final List<double> colX = [467.0, 544.0, 621.0, 698.0];
    final List<double> rowY = [88.0, 118.0, 147.0, 177.0, 207.0, 237.0, 267.0, 297.0, 329.0];

    for (int r = 0; r < 9; r++) {
      final isRowActive = _isPlaying && r == _activeRow;
      final isRowCleared = _isPlaying && r > _activeRow;

      for (int c = 0; c < 4; c++) {
        final cellState = _gridStates[r][c];
        final isFailedCell = _isGameOver && r == _failedRow && c == _failedCol;
        
        widgets.add(
          Positioned(
            left: colX[c],
            top: rowY[r],
            width: 69,
            height: 27,
            child: GestureDetector(
              onTap: () => _onCellClicked(r, c),
              child: Container(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/card.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isFailedCell
                        ? const Color(0xAAEF4444)
                        : isRowActive
                            ? const Color(0x44F59E0B)
                            : isRowCleared
                                ? const Color(0x2210B981)
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isFailedCell
                          ? const Color(0xFFEF4444)
                          : isRowActive 
                              ? const Color(0xFFF59E0B) 
                              : const Color(0x33FFFFFF),
                      width: (isRowActive || isFailedCell) ? 1.5 : 0.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (cellState == 'fruit') ...[
                        Image.asset(
                          _getFruitAsset(),
                          width: 15,
                          height: 16,
                          fit: BoxFit.contain,
                        )
                      ] else if (cellState == 'skull') ...[
                        Image.asset(
                          'assets/images/skull.png',
                          width: 15,
                          height: 15,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
