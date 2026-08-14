import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_game_background.dart';

class PlinkoGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const PlinkoGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<PlinkoGameScreen> createState() => _PlinkoGameScreenState();
}

class _PlinkoBall {
  final String id;
  final double betAmount;
  final String risk;
  final int rows;
  final List<Offset> path; // Pre-calculated positions for animation
  final int targetBin;
  final double multiplier;
  int currentFrame = 0;

  _PlinkoBall({
    required this.id,
    required this.betAmount,
    required this.risk,
    required this.rows,
    required this.path,
    required this.targetBin,
    required this.multiplier,
  });
}

class _ActivePegHit {
  final int row;
  final int index;
  double intensity = 1.0; // Fades out over time

  _ActivePegHit({required this.row, required this.index});
}

class _ActiveBinFlash {
  final int index;
  double intensity = 1.0; // Fades out over time

  _ActiveBinFlash({required this.index});
}

class _PlinkoGameScreenState extends State<PlinkoGameScreen> with SingleTickerProviderStateMixin {
  final _betController = TextEditingController(text: '10');
  
  int _currentTab = 0; // 0: Manual, 1: Auto, 2: Advanced
  bool _isAutoMode = false;
  String _gameMode = 'Nightmare'; // Regular, High, Nightmare, Lightning
  int _rowCount = 9; // 8 to 16 rows, default 9 matching screenshot
  bool _hyperMode = false;

  // Game loop ticker
  Timer? _gameTimer;
  final List<_PlinkoBall> _balls = [];
  final List<_ActivePegHit> _pegHits = [];
  final List<_ActiveBinFlash> _binFlashes = [];
  final List<double> _history = [];
  final math.Random _random = math.Random();

  // Predefined and dynamic symmetrical Plinko multipliers
  List<double> getMultipliers(String mode, int rows) {
    // Symmetrical multipliers.
    // Center is lowest, edges are highest.
    final List<double> list = List.filled(rows + 1, 0.0);
    final double center = rows / 2.0;
    
    double edgeValue;
    double centerValue;
    
    if (mode == 'Regular') {
      edgeValue = 5.6 + (rows - 8) * 1.5;
      centerValue = 0.5;
    } else if (mode == 'High') {
      edgeValue = 13.0 + (rows - 8) * 8.0;
      centerValue = 0.3;
    } else if (mode == 'Nightmare') {
      edgeValue = rows == 9 ? 100.0 : (rows == 12 ? 750.0 : 29.0 + (rows - 8) * 100.0);
      centerValue = 0.1;
    } else { // Lightning (extreme)
      edgeValue = 100.0 + (rows - 8) * 250.0;
      centerValue = 0.05;
    }
    
    for (int i = 0; i <= rows; i++) {
      final double dist = (i - center).abs() / center; // 0.0 at center, 1.0 at edges
      double val = centerValue + (edgeValue - centerValue) * math.pow(dist, 3.2);
      
      // Let's round to nice values:
      if (val >= 100) {
        val = (val / 5.0).round() * 5.0;
      } else if (val >= 10) {
        val = (val * 2).round() / 2.0;
      } else if (val >= 1.0) {
        val = (val * 10).round() / 10.0;
      } else {
        val = (val * 10).round() / 10.0;
        if (val < 0.1) val = 0.1;
      }
      list[i] = val;
    }
    
    // Exact hardcoded overrides from screenshots
    if (mode == 'Nightmare' && rows == 9) {
      return [100.0, 8.3, 1.3, 0.2, 0.1, 0.1, 0.2, 1.3, 8.3, 100.0];
    }
    if (mode == 'Nightmare' && rows == 12) {
      return [750.0, 15.0, 5.5, 1.2, 0.5, 0.2, 0.1, 0.2, 0.5, 1.2, 5.5, 15.0, 750.0];
    }
    if (mode == 'Regular' && rows == 8) {
      return [5.6, 1.6, 1.1, 1.0, 0.5, 1.0, 1.1, 1.6, 5.6];
    }
    if (mode == 'High' && rows == 8) {
      return [13.0, 3.0, 1.3, 0.7, 0.4, 0.7, 1.3, 3.0, 13.0];
    }
    
    // Force strict symmetry
    for (int i = 0; i <= rows / 2; i++) {
      list[rows - i] = list[i];
    }
    
    return list;
  }

  // Auto-play state
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  int _autoBetsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _betController.addListener(() => setState(() {}));
    
    // Start game animation loop (60 FPS)
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _updatePhysics);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _autoPlayTimer?.cancel();
    _betController.dispose();
    super.dispose();
  }

  // physics loop update
  void _updatePhysics(Timer timer) {
    if (!mounted) return;

    setState(() {
      // 1. Update balls positions
      for (int i = _balls.length - 1; i >= 0; i--) {
        final ball = _balls[i];
        ball.currentFrame++;

        // Detect peg hits along the path
        // The path points are sampled. Every peg hit occurs at keyframe steps.
        // Let's check if the ball just hit a peg.
        // Since we have RowCount peg hits, and each segment takes e.g. 15 frames:
        const int framesPerSegment = 16;
        if (ball.currentFrame > 0 && ball.currentFrame % framesPerSegment == 0) {
          final int segmentIndex = (ball.currentFrame ~/ framesPerSegment) - 1;
          if (segmentIndex >= 0 && segmentIndex < ball.rows) {
            // Find peg index hit. In our path calculation, we store which peg is hit.
            // Let's trigger a hit flash!
            _triggerPegHit(segmentIndex, ball);
          }
        }

        // If ball finished path
        if (ball.currentFrame >= ball.path.length) {
          // Add to bin flash
          _binFlashes.add(_ActiveBinFlash(index: ball.targetBin));
          
          // Credit winnings
          final double winnings = ball.betAmount * ball.multiplier;
          if (winnings > 0) {
            widget.onBalanceChanged(widget.balance + winnings);
          }

          // Add to history
          _history.insert(0, ball.multiplier);
          if (_history.length > 8) {
            _history.removeLast();
          }

          // Remove ball
          _balls.removeAt(i);
        }
      }

      // 2. Fade out peg hits
      for (int i = _pegHits.length - 1; i >= 0; i--) {
        _pegHits[i].intensity -= 0.08;
        if (_pegHits[i].intensity <= 0) {
          _pegHits.removeAt(i);
        }
      }

      // 3. Fade out bin flashes
      for (int i = _binFlashes.length - 1; i >= 0; i--) {
        _binFlashes[i].intensity -= 0.1;
        if (_binFlashes[i].intensity <= 0) {
          _binFlashes.removeAt(i);
        }
      }
    });
  }

  void _triggerPegHit(int rowIndex, _PlinkoBall ball) {
    final Offset ballPos = ball.path[ball.currentFrame];
    
    int closestPegIndex = 0;
    double minDistance = double.infinity;
    
    final int pegCount = rowIndex + 3;
    for (int i = 0; i < pegCount; i++) {
      final double pegX = i - (rowIndex + 2) / 2.0;
      final double dist = (ballPos.dx - pegX).abs();
      if (dist < minDistance) {
        minDistance = dist;
        closestPegIndex = i;
      }
    }

    _pegHits.add(_ActivePegHit(row: rowIndex, index: closestPegIndex));
  }

  // Pre-calculate path points for a ball
  List<Offset> _calculateBallPath(int rowCount, int targetBin) {
    final List<Offset> points = [];
    
    final List<int> pathCols = [];
    int currentCol = 1; // Start at center peg of row 0 (which has index 1)
    pathCols.add(currentCol);
    
    final List<int> steps = List.filled(rowCount, 0);
    final List<int> indices = List.generate(rowCount, (i) => i);
    indices.shuffle(_random);
    for (int i = 0; i < targetBin; i++) {
      if (i < rowCount) {
        steps[indices[i]] = 1;
      }
    }
    
    int col = 1; // start at center peg of row 0
    for (int r = 1; r < rowCount; r++) {
      col += steps[r];
      pathCols.add(col);
    }
    
    // Start above the board (relative y = -1.0)
    Offset currentPos = const Offset(0.0, -1.0);
    points.add(currentPos);
    
    const int framesPerSegment = 16;
    
    // Segment 0: Drop to first peg (Row 0, index 1)
    // Relative X of Row 0, index 1 is: 1 - (0 + 2)/2.0 = 0.0
    // Relative Y of Row 0 is 0.0
    final Offset firstPeg = const Offset(0.0, 0.0);
    
    for (int f = 1; f <= framesPerSegment; f++) {
      final double t = f / framesPerSegment;
      final double px = currentPos.dx + (firstPeg.dx - currentPos.dx) * t;
      final double py = currentPos.dy + (firstPeg.dy - currentPos.dy) * t * t;
      points.add(Offset(px, py));
    }
    currentPos = firstPeg;
    
    // Segments 1 to rowCount-1: Bouncing between pegs
    for (int r = 0; r < rowCount - 1; r++) {
      final int nextCol = pathCols[r + 1];
      final double nextPegX = nextCol - (r + 1 + 2) / 2.0;
      final double nextPegY = (r + 1).toDouble();
      final Offset nextPeg = Offset(nextPegX, nextPegY);
      
      // Arc interpolation (bezier curve)
      // Control point is elevated (midpoint in x, midpoint - 0.28 in y)
      final double midX = (currentPos.dx + nextPeg.dx) / 2.0;
      final double midY = (currentPos.dy + nextPeg.dy) / 2.0 - 0.28;
      final Offset control = Offset(midX, midY);
      
      for (int f = 1; f <= framesPerSegment; f++) {
        final double t = f / framesPerSegment;
        final double t1 = 1 - t;
        final double px = t1 * t1 * currentPos.dx + 2 * t1 * t * control.dx + t * t * nextPeg.dx;
        final double py = t1 * t1 * currentPos.dy + 2 * t1 * t * control.dy + t * t * nextPeg.dy;
        points.add(Offset(px, py));
      }
      currentPos = nextPeg;
    }
    
    // Final Segment: Fall into the bottom bin
    // Relative X of bin targetBin is: targetBin + 0.5 - (rowCount + 2)/2.0
    // Relative Y of bin is rowCount + 0.5
    final double binX = targetBin + 0.5 - (rowCount + 2) / 2.0;
    final double binY = rowCount.toDouble() + 0.55;
    final Offset targetBinPos = Offset(binX, binY);
    
    // Control point for final bounce
    final double midX = (currentPos.dx + targetBinPos.dx) / 2.0;
    final double midY = (currentPos.dy + targetBinPos.dy) / 2.0 - 0.3;
    final Offset control = Offset(midX, midY);
    
    for (int f = 1; f <= framesPerSegment; f++) {
      final double t = f / framesPerSegment;
      final double t1 = 1 - t;
      final double px = t1 * t1 * currentPos.dx + 2 * t1 * t * control.dx + t * t * targetBinPos.dx;
      final double py = t1 * t1 * currentPos.dy + 2 * t1 * t * control.dy + t * t * targetBinPos.dy;
      points.add(Offset(px, py));
    }
    
    return points;
  }

  void _spawnBall() {
    final double bet = double.tryParse(_betController.text) ?? 0.0;
    
    if (bet > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance to place bet.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _stopAutoPlay();
      return;
    }

    final int binCount = _rowCount + 1;
    final int targetBin = _pickTargetBin(binCount, _gameMode);
    
    final List<double> mList = getMultipliers(_gameMode, _rowCount);
    final double multiplier = mList[targetBin];

    if (_hyperMode) {
      final double winnings = bet * multiplier;
      final double netChange = winnings - bet;
      widget.onBalanceChanged(widget.balance + netChange);

      setState(() {
        _history.insert(0, multiplier);
        if (_history.length > 8) {
          _history.removeLast();
        }
        _binFlashes.add(_ActiveBinFlash(index: targetBin));
      });
    } else {
      widget.onBalanceChanged(widget.balance - bet);
      
      final path = _calculateBallPath(_rowCount, targetBin);
      
      setState(() {
        _balls.add(_PlinkoBall(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          betAmount: bet,
          risk: _gameMode,
          rows: _rowCount,
          path: path,
          targetBin: targetBin,
          multiplier: multiplier,
        ));
      });
    }
  }

  int _pickTargetBin(int binCount, String risk) {
    final int R = binCount - 1;
    
    if (risk == 'Regular') {
      int col = 0;
      for (int i = 0; i < R; i++) {
        if (_random.nextDouble() < 0.5) col++;
      }
      return col;
    } else if (risk == 'High') {
      int col = 0;
      for (int i = 0; i < R; i++) {
        double p = 0.5;
        if (col < R / 2) {
          p = 0.46;
        } else if (col > R / 2) {
          p = 0.54;
        }
        if (_random.nextDouble() < p) col++;
      }
      return col;
    } else if (risk == 'Nightmare') {
      if (_random.nextDouble() < 0.35) {
        int col = 0;
        for (int i = 0; i < R; i++) {
          if (_random.nextDouble() < 0.5) col++;
        }
        return col;
      } else {
        final double bias = _random.nextDouble();
        if (bias < 0.5) {
          return _random.nextInt(3);
        } else {
          return R - _random.nextInt(3);
        }
      }
    } else { // Lightning (extreme risk)
      if (_random.nextDouble() < 0.15) {
        int col = 0;
        for (int i = 0; i < R; i++) {
          if (_random.nextDouble() < 0.5) col++;
        }
        return col;
      } else {
        final double bias = _random.nextDouble();
        if (bias < 0.5) {
          return _random.nextInt(2);
        } else {
          return R - _random.nextInt(2);
        }
      }
    }
  }

  void _startAutoPlay() {
    final int bets = int.tryParse(_betController.text) ?? 0;
    if (bets <= 0) return;
    
    setState(() {
      _isAutoPlaying = true;
    });

    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_isAutoPlaying) {
        timer.cancel();
        return;
      }

      _spawnBall();
      
      setState(() {
        _autoBetsRemaining--;
        if (_autoBetsRemaining <= 0) {
          _stopAutoPlay();
        }
      });
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    setState(() {
      _isAutoPlaying = false;
    });
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
                      onPressed: _isAutoPlaying ? null : widget.onBackPressed,
                    ),
                    Text(
                      'PLINKO CASCADE',
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
                          // Right Panel: Plinko Playfield
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
                              child: _buildPlinkoPlayfield(),
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
                              child: _buildPlinkoPlayfield(),
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
      ),
      child: Column(
        children: [
          // Manual / Auto / Advanced Tabs
          Container(
            height: 40.0,
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                _buildTab('Manual', 0),
                _buildTab('Auto', 1),
                _buildTab('Advanced', 2, hasBadge: true),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),
                  // Bet Amount Input Header
                  Row(
                    children: [
                      const Text('Bet Amount', style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('₹${bet.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  // Bet Input Row
                  Container(
                    height: 42.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16.0),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _betController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        // 1/2 Button
                        _buildQuickAmountBtn('1/2', () {
                          if (_isAutoPlaying) return;
                          double val = double.tryParse(_betController.text) ?? 0.0;
                          val = (val / 2.0).clamp(0.0, widget.balance);
                          _betController.text = val.toStringAsFixed(0);
                        }),
                        // 2x Button
                        _buildQuickAmountBtn('2x', () {
                          if (_isAutoPlaying) return;
                          double val = double.tryParse(_betController.text) ?? 0.0;
                          val = (val * 2.0).clamp(0.0, widget.balance);
                          _betController.text = val.toStringAsFixed(0);
                        }),
                        // Up/Down Arrows Column
                        Container(
                          width: 32.0,
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.2)),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isAutoPlaying) return;
                                    double val = double.tryParse(_betController.text) ?? 0.0;
                                    _betController.text = (val + 1.0).clamp(0.0, widget.balance).toStringAsFixed(0);
                                  },
                                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.grey, size: 14.0),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isAutoPlaying) return;
                                    double val = double.tryParse(_betController.text) ?? 0.0;
                                    _betController.text = (val - 1.0).clamp(0.0, widget.balance).toStringAsFixed(0);
                                  },
                                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickBetPreset('10', 10.0),
                      _buildQuickBetPreset('100', 100.0),
                      _buildQuickBetPreset('1.0k', 1000.0),
                      _buildQuickBetPreset('10.0k', 10000.0),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Game Mode Selector
                  const Text('Game Mode', style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6.0),
                  Container(
                    height: 38.0,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        _buildModePill('Regular', isSelected: _gameMode == 'Regular'),
                        _buildModePill('High', isSelected: _gameMode == 'High'),
                        _buildModePill('Nightmare', isSelected: _gameMode == 'Nightmare'),
                        _buildModePill('Lightning', isSelected: _gameMode == 'Lightning', hasIcon: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Row Count Slider
                  const Text('Row', style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Text('$_rowCount', style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF00C853),
                              inactiveTrackColor: const Color(0xFF2C2F36),
                              thumbColor: Colors.white,
                              overlayColor: const Color(0xFF00C853).withOpacity(0.2),
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                            ),
                            child: Slider(
                              value: _rowCount.toDouble(),
                              min: 8.0,
                              max: 16.0,
                              divisions: 8,
                              onChanged: _isAutoPlaying ? null : (val) {
                                setState(() => _rowCount = val.round());
                              },
                            ),
                          ),
                        ),
                        const Text('16', style: TextStyle(color: Colors.grey, fontSize: 12.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Auto mode settings
                  if (_isAutoMode) ...[
                    const Text('Number of Bets', style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6.0),
                    Container(
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Text(
                                _autoBetsRemaining == double.infinity ? '∞' : '$_autoBetsRemaining',
                                style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_isAutoPlaying) return;
                              setState(() => _autoBetsRemaining = 10);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: const Text('10', style: TextStyle(color: Colors.grey, fontSize: 11.0, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_isAutoPlaying) return;
                              setState(() => _autoBetsRemaining = 100);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: const Text('100', style: TextStyle(color: Colors.grey, fontSize: 11.0, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ],
              ),
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 48.0,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_isAutoMode) {
                    if (_isAutoPlaying) {
                      _stopAutoPlay();
                    } else {
                      _startAutoPlay();
                    }
                  } else {
                    _spawnBall();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAutoPlaying ? Colors.redAccent : const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  elevation: 4.0,
                ),
                child: Text(
                  _isAutoMode
                      ? (_isAutoPlaying ? 'Stop Auto' : 'Start Auto')
                      : 'Bet',
                  style: const TextStyle(color: Colors.black, fontSize: 15.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, {bool hasBadge = false}) {
    final bool isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isAutoPlaying) return;
          setState(() {
            _currentTab = index;
            _isAutoMode = index == 1;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2C2F36) : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
            if (hasBadge)
              Positioned(
                top: -4.0,
                right: 2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text(
                    'New✦',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 6.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickBetPreset(String label, double amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isAutoPlaying) return;
          final double val = amount.clamp(0.0, widget.balance);
          _betController.text = val.toStringAsFixed(0);
        },
        child: Container(
          height: 28.0,
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F36).withOpacity(0.5),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(String mode, {required bool isSelected, bool hasIcon = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isAutoPlaying) return;
          setState(() => _gameMode = mode);
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2F36) : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasIcon) ...[
                const Icon(Icons.flash_on, color: Colors.greenAccent, size: 10.0),
                const SizedBox(width: 2.0),
              ],
              Text(
                mode,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlinkoPlayfield() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0728).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF9E84FF).withOpacity(0.4), width: 1.5),
      ),
      child: Stack(
        children: [
          // Dynamic peg and bin painter
          Positioned.fill(
            child: CustomPaint(
              painter: _PlinkoBoardPainter(
                rowCount: _rowCount,
                risk: _gameMode,
                balls: _balls,
                history: _history,
                binFlashes: _binFlashes,
                pegHits: _pegHits,
                multipliers: getMultipliers(_gameMode, _rowCount),
                hyperMode: _hyperMode,
              ),
            ),
          ),

          // Hyper Mode toggle in top right
          Positioned(
            top: 10.0,
            right: 12.0,
            child: Row(
              children: [
                const Text(
                  'Hyper Mode',
                  style: TextStyle(color: Colors.grey, fontSize: 11.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6.0),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _hyperMode,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (val) {
                      setState(() => _hyperMode = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // History display at top left
          Positioned(
            top: 10.0,
            left: 12.0,
            child: Row(
              children: _history.map((val) => Container(
                margin: const EdgeInsets.only(right: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: val > 1.5
                      ? const Color(0xFF00C853)
                      : (val < 1.0 ? const Color(0xFF6B7280).withOpacity(0.3) : const Color(0xFFFFD700).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: val > 1.5
                        ? const Color(0xFF00E676)
                        : (val < 1.0 ? Colors.grey.withOpacity(0.5) : const Color(0xFFFFD700)),
                    width: 0.8
                  ),
                ),
                child: Text(
                  '${val.toStringAsFixed(1)}x',
                  style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlinkoBoardPainter extends CustomPainter {
  final int rowCount;
  final String risk;
  final List<_PlinkoBall> balls;
  final List<double> history;
  final List<_ActiveBinFlash> binFlashes;
  final List<_ActivePegHit> pegHits;
  final List<double> multipliers;
  final bool hyperMode;

  _PlinkoBoardPainter({
    required this.rowCount,
    required this.risk,
    required this.balls,
    required this.history,
    required this.binFlashes,
    required this.pegHits,
    required this.multipliers,
    required this.hyperMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    
    // Peg calculations
    final double dy = (size.height - 40.0) / rowCount;
    final double dx = (size.width - 40.0) / (rowCount + 3);
    final double spacing = math.min(dx, dy * 1.25);
    final double spacingX = spacing;
    final double spacingY = spacing / 1.25;
    
    final double startY = 24.0;

    // 1. Paint bottom bins (slots)
    final double binY = hyperMode
        ? size.height * 0.55
        : startY + rowCount * spacingY + 16.0;
        
    final double binHeight = 26.0;
    
    for (int i = 0; i <= rowCount; i++) {
      final double binX = cx + (i + 0.5 - (rowCount + 2) / 2.0) * spacingX;
      final double mult = multipliers[i];
      
      // Slot color based on multiplier value
      Color binColor;
      if (mult >= 100.0) {
        binColor = const Color(0xFFFF1744); // Cyber ruby/red for high multipliers
      } else if (mult >= 10.0) {
        binColor = const Color(0xFFFF9100); // Orange
      } else if (mult >= 2.0) {
        binColor = const Color(0xFFFFD600); // Yellow
      } else if (mult >= 1.0) {
        binColor = const Color(0xFFFFD600); // Light Yellow
      } else if (mult >= 0.5) {
        binColor = const Color(0xFFC0CA33); // Lime green
      } else {
        binColor = const Color(0xFF00E5FF); // Neon cyan for values < 1x
      }

      // Check if this bin is flashing
      double scale = 1.0;
      final int flashIndex = binFlashes.indexWhere((f) => f.index == i);
      if (flashIndex != -1) {
        final flash = binFlashes[flashIndex];
        scale = 1.0 + 0.3 * flash.intensity;
        binColor = Color.lerp(binColor, Colors.white, flash.intensity * 0.8) ?? binColor;
      }

      final double cardWidth = spacingX - 3.5;
      final Rect binRect = Rect.fromCenter(
        center: Offset(binX, binY),
        width: cardWidth * scale,
        height: binHeight * scale,
      );

      final RRect roundedBin = RRect.fromRectAndRadius(binRect, const Radius.circular(6.0));
      
      // Paint bin body
      final Paint bodyPaint = Paint()
        ..color = binColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(roundedBin, bodyPaint);
      
      // Draw a thick black border matching the screenshot!
      final Paint borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(roundedBin, borderPaint);

      final String label = mult % 1.0 == 0.0 ? mult.toStringAsFixed(0) : mult.toStringAsFixed(1);
      final textSpan = TextSpan(
        text: label,
        style: GoogleFonts.pressStart2p(
          textStyle: TextStyle(
            color: Colors.black, // Always black text
            fontSize: rowCount == 16 ? 6.0 : (rowCount == 12 ? 7.0 : 8.0),
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(binX - textPainter.width / 2, binY - textPainter.height / 2),
      );
    }

    // 2. Paint Peg board (only if not hyperMode)
    if (!hyperMode) {
      final Paint pegGlowPaint = Paint()
        ..color = const Color(0xFF9E84FF).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      for (int r = 0; r < rowCount; r++) {
        final int pegCount = r + 3;
        final double py = startY + r * spacingY;
        
        for (int i = 0; i < pegCount; i++) {
          final double px = cx + (i - (r + 2) / 2.0) * spacingX;
          
          // Check if peg has been hit
          final int hitIndex = pegHits.indexWhere((h) => h.row == r && h.index == i);
          double hitIntensity = 0.0;
          if (hitIndex != -1) {
            hitIntensity = pegHits[hitIndex].intensity;
          }

          // Draw hit highlight
          if (hitIntensity > 0) {
            final Paint hitPaint = Paint()
              ..color = const Color(0xFF00E5FF).withOpacity(hitIntensity * 0.8) // Glowing cyan
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
            canvas.drawCircle(Offset(px, py), 6.0 + 4.0 * hitIntensity, hitPaint);
          }

          // Draw peg glow
          canvas.drawCircle(Offset(px, py), 3.0, pegGlowPaint);
          
          // Draw peg dot
          final Color pColor = Color.lerp(const Color(0xFFE3F2FD), const Color(0xFF00E5FF), hitIntensity) ?? const Color(0xFFE3F2FD);
          final Paint currentPegPaint = Paint()
            ..color = pColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px, py), 2.2 + 0.8 * hitIntensity, currentPegPaint);
        }
      }
    }

    // 3. Paint Active Balls (only if not hyperMode)
    if (!hyperMode) {
      final Paint ballPaint = Paint()
        ..color = const Color(0xFFFFEB3B) // Cyber yellow ball
        ..style = PaintingStyle.fill;

      for (var ball in balls) {
        if (ball.currentFrame < ball.path.length) {
          final Offset relativePos = ball.path[ball.currentFrame];
          
          final double bxScreen = cx + relativePos.dx * spacingX;
          
          double byScreen;
          if (relativePos.dy >= rowCount - 1) {
            final double lastPegY = startY + (rowCount - 1) * spacingY;
            final double t = ((relativePos.dy - (rowCount - 1)) / 1.55).clamp(0.0, 1.0);
            byScreen = lastPegY + (binY - lastPegY) * t;
          } else {
            byScreen = startY + relativePos.dy * spacingY;
          }
          
          // Draw ball glow
          final Paint ballGlowPaint = Paint()
            ..color = const Color(0xFFFFEB3B).withOpacity(0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
          canvas.drawCircle(Offset(bxScreen, byScreen), 7.5, ballGlowPaint);
          
          // Draw ball itself
          canvas.drawCircle(Offset(bxScreen, byScreen), 5.0, ballPaint);
          
          // Highlight active trail
          final Paint trailPaint = Paint()
            ..color = const Color(0xFFFFEB3B).withOpacity(0.15)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(bxScreen, byScreen), 10.0, trailPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlinkoBoardPainter oldDelegate) {
    return true;
  }
}
