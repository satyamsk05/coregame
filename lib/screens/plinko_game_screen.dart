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
  
  bool _isAutoMode = false;
  String _riskLevel = 'Medium'; // Low, Medium, High
  int _rowCount = 8; // 8, 12, 16

  // Game loop ticker
  Timer? _gameTimer;
  final List<_PlinkoBall> _balls = [];
  final List<_ActivePegHit> _pegHits = [];
  final List<_ActiveBinFlash> _binFlashes = [];
  final List<double> _history = [];
  final math.Random _random = math.Random();

  // Multiplier configuration mapping [Risk][Rows] -> List of multipliers
  static const Map<String, Map<int, List<double>>> _multipliers = {
    'Low': {
      8: [5.6, 1.6, 1.1, 1.0, 0.5, 1.0, 1.1, 1.6, 5.6],
      12: [10.0, 5.0, 2.0, 1.4, 1.1, 1.0, 0.5, 1.0, 1.1, 1.4, 2.0, 5.0, 10.0],
      16: [16.0, 9.0, 2.0, 1.4, 1.3, 1.2, 1.1, 1.0, 0.5, 1.0, 1.1, 1.2, 1.3, 1.4, 2.0, 9.0, 16.0],
    },
    'Medium': {
      8: [13.0, 3.0, 1.3, 0.7, 0.4, 0.7, 1.3, 3.0, 13.0],
      12: [33.0, 11.0, 4.0, 2.0, 1.1, 0.6, 0.3, 0.6, 1.1, 2.0, 4.0, 11.0, 33.0],
      16: [110.0, 41.0, 10.0, 5.0, 3.0, 1.5, 1.0, 0.5, 0.3, 0.5, 1.0, 1.5, 3.0, 5.0, 10.0, 41.0, 110.0],
    },
    'High': {
      8: [29.0, 4.0, 1.5, 0.3, 0.2, 0.3, 1.5, 4.0, 29.0],
      12: [99.0, 25.0, 8.0, 3.0, 1.0, 0.2, 0.2, 0.2, 1.0, 3.0, 8.0, 25.0, 99.0],
      16: [1000.0, 130.0, 26.0, 9.0, 4.0, 2.0, 0.2, 0.2, 0.2, 0.2, 0.2, 2.0, 4.0, 9.0, 26.0, 130.0, 1000.0],
    }
  };

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
    // Find the relative peg X coordinate closest to the ball's X coordinate
    final Offset ballPos = ball.path[ball.currentFrame];
    final double dx = 0.9 / (ball.rows + 3);
    
    int closestPegIndex = 0;
    double minDistance = double.infinity;
    
    final int pegCount = rowIndex + 3;
    for (int i = 0; i < pegCount; i++) {
      final double pegX = 0.5 + (i - (rowIndex + 2) / 2.0) * dx;
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
    
    // Let's compute relative coordinates (0.0 to 1.0 for x and y of the board)
    // Board coordinates: x in [0.0, 1.0], y in [0.0, 1.0]
    // The top drop point is at (0.5, 0.02)
    // Pegs at row `r` are:
    // x = 0.5 + (i - (r + 2)/2) * dx
    // y = 0.08 + r * dy
    
    final double dy = 0.85 / rowCount;
    final double dx = 0.9 / (rowCount + 3); // Spacing relative to bottom row width
    
    // Target path selection
    // The target bin is index `targetBin` out of `rowCount + 1` bins (from 0 to rowCount).
    // The sequence of peg columns must lead to this bin.
    // Let's backtrack or build forward:
    // A path has `rowCount` segments. In each row `r` (0 to rowCount-1), the peg hit is `pegColumn`.
    // Let's choose path columns:
    final List<int> pathCols = [];
    int currentCol = 1; // Start at center peg of row 0 (which has index 1)
    pathCols.add(currentCol);
    
    // To land in `targetBin` (which corresponds to column B at the bottom):
    // The path must end at index B or B+1?
    // Let's build the columns list from 0 to rowCount-1:
    // At row 0: peg is at index 1.
    // At row `r`, peg is at index `c_r`.
    // At the bottom bin, the position is `targetBin`.
    // We can determine the steps (left/right) by generating a set of decisions (0 or 1)
    // such that the sum of decisions equals `targetBin`.
    // Let's distribute `targetBin` successes over `rowCount` trials!
    final List<int> steps = List.filled(rowCount, 0);
    final List<int> indices = List.generate(rowCount, (i) => i);
    indices.shuffle(_random);
    for (int i = 0; i < targetBin; i++) {
      if (i < rowCount) {
        steps[indices[i]] = 1;
      }
    }
    
    // Build path columns
    int col = 1; // start at center peg of row 0
    for (int r = 1; r < rowCount; r++) {
      col += steps[r];
      pathCols.add(col);
    }
    
    // Generate actual Offset coordinates
    Offset currentPos = const Offset(0.5, 0.02); // Top drop point
    points.add(currentPos);
    
    const int framesPerSegment = 16;
    
    // Segment 0: Drop to first peg
    final double firstPegX = 0.5 + (1 - (0 + 2) / 2.0) * dx;
    final double firstPegY = 0.08 + 0 * dy;
    final Offset firstPeg = Offset(firstPegX, firstPegY);
    
    for (int f = 1; f <= framesPerSegment; f++) {
      final double t = f / framesPerSegment;
      // Gravity drop (quadratic y interpolation)
      final double px = currentPos.dx + (firstPeg.dx - currentPos.dx) * t;
      final double py = currentPos.dy + (firstPeg.dy - currentPos.dy) * t * t;
      points.add(Offset(px, py));
    }
    currentPos = firstPeg;
    
    // Segments 1 to rowCount-1: Bouncing between pegs
    for (int r = 0; r < rowCount - 1; r++) {
      final int nextCol = pathCols[r + 1];
      final double nextPegX = 0.5 + (nextCol - (r + 1 + 2) / 2.0) * dx;
      final double nextPegY = 0.08 + (r + 1) * dy;
      final Offset nextPeg = Offset(nextPegX, nextPegY);
      
      // Arc interpolation (bezier curve)
      // Control point is elevated
      final double midX = (currentPos.dx + nextPeg.dx) / 2.0;
      final double midY = (currentPos.dy + nextPeg.dy) / 2.0 - dy * 0.28;
      final Offset control = Offset(midX, midY);
      
      for (int f = 1; f <= framesPerSegment; f++) {
        final double t = f / framesPerSegment;
        // Bezier formula: (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
        final double t1 = 1 - t;
        final double px = t1 * t1 * currentPos.dx + 2 * t1 * t * control.dx + t * t * nextPeg.dx;
        final double py = t1 * t1 * currentPos.dy + 2 * t1 * t * control.dy + t * t * nextPeg.dy;
        points.add(Offset(px, py));
      }
      currentPos = nextPeg;
    }
    
    // Final Segment: Fall into the bottom bin
    // Bins are located at y = 0.95
    // Bin x is centered between peg B and peg B+1 of row rowCount
    final double binX = 0.5 + (targetBin + 0.5 - (rowCount + 2) / 2.0) * dx;
    final double binY = 0.95;
    final Offset targetBinPos = Offset(binX, binY);
    
    // Control point for final bounce
    final double midX = (currentPos.dx + targetBinPos.dx) / 2.0;
    final double midY = (currentPos.dy + targetBinPos.dy) / 2.0 - dy * 0.3;
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

    // Deduct bet amount
    widget.onBalanceChanged(widget.balance - bet);

    // Pick target bin randomly based on bin weights (probabilities)
    // Low risk: center-heavy, High risk: edge-heavy
    final int binCount = _rowCount + 1;
    final int targetBin = _pickTargetBin(binCount, _riskLevel);
    
    final List<double> mList = _multipliers[_riskLevel]![_rowCount]!;
    final double multiplier = mList[targetBin];
    
    final path = _calculateBallPath(_rowCount, targetBin);
    
    setState(() {
      _balls.add(_PlinkoBall(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        betAmount: bet,
        risk: _riskLevel,
        rows: _rowCount,
        path: path,
        targetBin: targetBin,
        multiplier: multiplier,
      ));
    });
  }

  int _pickTargetBin(int binCount, String risk) {
    // We can simulate it realistically by doing N coin flips (50/50 left or right)
    // But since players want variance, let's adjust binomial distribution weights slightly
    // for Low vs High risk.
    // low risk: pull towards center. High risk: push towards edges.
    // Let's implement weighted choice!
    final int R = binCount - 1; // rowCount
    
    if (risk == 'Low') {
      // Standard binomial tends to center, which is perfect for low risk
      int col = 0;
      for (int i = 0; i < R; i++) {
        if (_random.nextDouble() < 0.5) col++;
      }
      return col;
    } else if (risk == 'Medium') {
      // Slighly wider than low risk
      int col = 0;
      for (int i = 0; i < R; i++) {
        // Add a small spread
        double p = 0.5;
        if (col < R / 2) {
          p = 0.46; // push right
        } else if (col > R / 2) {
          p = 0.54; // push left
        }
        if (_random.nextDouble() < p) col++;
      }
      return col;
    } else {
      // High risk: push balls heavily towards the edges!
      // We can generate path decisions that favor extreme slots
      // 30% chance of random binomial, 70% chance of extreme edge pull
      if (_random.nextDouble() < 0.4) {
        int col = 0;
        for (int i = 0; i < R; i++) {
          if (_random.nextDouble() < 0.5) col++;
        }
        return col;
      } else {
        // High risk force to edge
        // Choose index closer to edges
        final double bias = _random.nextDouble();
        if (bias < 0.5) {
          // left edge heavy (e.g. 0, 1, or 2)
          return _random.nextInt(3);
        } else {
          // right edge heavy (e.g. R-2, R-1, R)
          return R - _random.nextInt(3);
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
          // Manual / Auto Tabs
          Container(
            height: 40.0,
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isAutoPlaying) return;
                      setState(() => _isAutoMode = false);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isAutoMode ? const Color(0xFF2C2F36) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Text('Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isAutoPlaying) return;
                      setState(() => _isAutoMode = true);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isAutoMode ? const Color(0xFF2C2F36) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Text('Auto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0)),
                    ),
                  ),
                ),
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
                        // Half Bet Button
                        GestureDetector(
                          onTap: () {
                            if (_isAutoPlaying) return;
                            double val = double.tryParse(_betController.text) ?? 0.0;
                            val = (val / 2.0).clamp(0.0, widget.balance);
                            _betController.text = val.toStringAsFixed(0);
                          },
                          child: Container(
                            width: 38.0,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.2)),
                            ),
                            child: const Text('1/2', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        // Double Bet Button
                        GestureDetector(
                          onTap: () {
                            if (_isAutoPlaying) return;
                            double val = double.tryParse(_betController.text) ?? 0.0;
                            val = (val * 2.0).clamp(0.0, widget.balance);
                            _betController.text = val.toStringAsFixed(0);
                          },
                          child: Container(
                            width: 38.0,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Color(0xFF2C2F36), width: 1.2)),
                            ),
                            child: const Text('2x', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Risk Level Selector
                  const Text('Risk Level', style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6.0),
                  Container(
                    height: 38.0,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _riskLevel,
                        dropdownColor: const Color(0xFF1E2024),
                        style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        isExpanded: true,
                        onChanged: _isAutoPlaying ? null : (val) {
                          if (val != null) setState(() => _riskLevel = val);
                        },
                        items: ['Low', 'Medium', 'High'].map((String level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Row Count Selector
                  const Text('Row Count', style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6.0),
                  Container(
                    height: 38.0,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _rowCount,
                        dropdownColor: const Color(0xFF1E2024),
                        style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        isExpanded: true,
                        onChanged: _isAutoPlaying ? null : (val) {
                          if (val != null) setState(() => _rowCount = val);
                        },
                        items: [8, 12, 16].map((int r) {
                          return DropdownMenuItem<int>(
                            value: r,
                            child: Text('$r Rows'),
                          );
                        }).toList(),
                      ),
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
                      : 'Drop Ball',
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
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
                risk: _riskLevel,
                balls: _balls,
                history: _history,
                binFlashes: _binFlashes,
                pegHits: _pegHits,
                multipliers: _multipliers[_riskLevel]![_rowCount]!,
              ),
            ),
          ),
          
          // History display at the top right
          Positioned(
            top: 10.0,
            right: 12.0,
            child: Row(
              children: _history.map((val) => Container(
                margin: const EdgeInsets.only(left: 4.0),
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

  _PlinkoBoardPainter({
    required this.rowCount,
    required this.risk,
    required this.balls,
    required this.history,
    required this.binFlashes,
    required this.pegHits,
    required this.multipliers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    
    // Peg calculations
    final double dy = (size.height - 65.0) / rowCount;
    // Adapt spacing to rowCount to keep it compact
    final double dx = (size.width - 40.0) / (rowCount + 3);
    final double spacing = math.min(dx, dy * 1.15);
    final double spacingX = spacing;
    final double spacingY = spacing / 1.15;
    
    final double startY = 32.0;

    // 1. Paint bottom bins (slots)
    final double binY = startY + rowCount * spacingY + 16.0;
    final double binHeight = 22.0;
    
    for (int i = 0; i <= rowCount; i++) {
      final double binX = cx + (i + 0.5 - (rowCount + 2) / 2.0) * spacingX;
      final double mult = multipliers[i];
      
      // Slot color based on multiplier value
      Color binColor;
      if (mult >= 10.0) {
        binColor = const Color(0xFFFF1744); // Cyber ruby/red for high multipliers
      } else if (mult >= 2.0) {
        binColor = const Color(0xFFFF9100); // Orange
      } else if (mult >= 1.0) {
        binColor = const Color(0xFFFFD600); // Yellow
      } else {
        binColor = const Color(0xFF00E5FF); // Neon cyan for values < 1x
      }

      // Check if this bin is flashing
      double scale = 1.0;
      final int flashIndex = binFlashes.indexWhere((f) => f.index == i);
      if (flashIndex != -1) {
        final flash = binFlashes[flashIndex];
        scale = 1.0 + 0.25 * flash.intensity;
        binColor = Color.lerp(binColor, Colors.white, flash.intensity * 0.75) ?? binColor;
      }

      final double cardWidth = spacingX - 3.5;
      final Rect binRect = Rect.fromCenter(
        center: Offset(binX, binY),
        width: cardWidth * scale,
        height: binHeight * scale,
      );

      final RRect roundedBin = RRect.fromRectAndRadius(binRect, const Radius.circular(4.0));
      
      // Draw background glow
      final Paint glowPaint = Paint()
        ..color = binColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawRRect(roundedBin, glowPaint);

      // Draw slot card
      final Paint cardPaint = Paint()
        ..color = binColor.withOpacity(0.95)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(roundedBin, cardPaint);

      // Draw border
      final Paint borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawRRect(roundedBin, borderPaint);

      // Draw multiplier text inside slot
      final String label = '${mult.toStringAsFixed(mult >= 100 ? 0 : 1)}x';
      final textSpan = TextSpan(
        text: label,
        style: GoogleFonts.pressStart2p(
          textStyle: TextStyle(
            color: mult >= 2.0 ? Colors.white : Colors.black,
            fontSize: rowCount == 16 ? 5.2 : (rowCount == 12 ? 6.2 : 7.2),
            fontWeight: FontWeight.bold,
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

    // 2. Paint Peg board
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

    // 3. Paint Active Balls
    final Paint ballPaint = Paint()
      ..color = const Color(0xFFFFEB3B) // Cyber yellow ball
      ..style = PaintingStyle.fill;

    for (var ball in balls) {
      if (ball.currentFrame < ball.path.length) {
        // Map relative coordinates to screen space
        final Offset relativePos = ball.path[ball.currentFrame];
        
        // Calculate screen coordinate
        final double bxScreen = cx + (relativePos.dx - 0.5) / dx * spacingX;
        final double byScreen = startY + (relativePos.dy - 0.08) / dy * spacingY;
        
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

  @override
  bool shouldRepaint(covariant _PlinkoBoardPainter oldDelegate) {
    return true;
  }
}
