import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../utils/sound_manager.dart';

class PlayingCard {
  final int rank; // 1 (Ace) to 13 (King)
  final String suit; // Hearts, Diamonds, Spades, Clubs

  PlayingCard({required this.rank, required this.suit});

  String get rankLabel {
    if (rank == 1) return 'A';
    if (rank == 11) return 'J';
    if (rank == 12) return 'Q';
    if (rank == 13) return 'K';
    return '$rank';
  }

  Color get color {
    return (suit == 'Hearts' || suit == 'Diamonds') ? const Color(0xFFD32F2F) : const Color(0xFF212121);
  }
}

class AndarBaharGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const AndarBaharGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<AndarBaharGameScreen> createState() => _AndarBaharGameScreenState();
}

class _AndarBaharGameScreenState extends State<AndarBaharGameScreen> with TickerProviderStateMixin {
  final math.Random _random = math.Random();

  // Game Phase State
  // 'betting' - betting is open, countdown is running
  // 'dealing' - dealing cards, betting is closed
  // 'winner'  - winner revealed, showing overlay, counting up winnings
  String _gamePhase = 'betting';
  int _timerSeconds = 12;
  Timer? _gameTimer;



  // Active bets
  int _selectedChipValue = 10;
  double _userBetAndar = 0.0;
  double _userBetBahar = 0.0;
  double _userBetTie = 0.0;

  // Total bets (including mock players)
  double _totalBetAndar = 3970.0;
  double _totalBetBahar = 650.0;
  double _totalBetTie = 250.0;

  // Player mock balances
  double _billionaireBalance = 84500.0;
  double _richieBalance = 24500.0;
  double _highRollerBalance = 9800.0;

  double _masterBalance = 5400.0;
  double _proKingBalance = 12800.0;
  double _elitePlayerBalance = 7500.0;

  // Mock player bets tracking maps for Andar, Bahar, Tie
  final Map<String, double> _mockBetsAndar = {};
  final Map<String, double> _mockBetsBahar = {};
  final Map<String, double> _mockBetsTie = {};

  // Static chips displayed on Andar, Bahar, Tie panels
  final List<TableChip> _tableChips = [];

  // History outcomes: 'A' for Andar (blue), 'B' for Bahar (red)
  final List<String> _history = [
    'B', 'B', 'B', 'A', 'A', 'A', 'B', 'A', 'B', 'B', 'B', 'A', 'B', 'B', 'B', 'A'
  ];

  // Card Dealer States
  PlayingCard? _andarCard;
  PlayingCard? _baharCard;

  // Card Animation states
  bool _isDealingCard = false;
  PlayingCard? _currentlyDealingCard;
  String _dealingTarget = 'joker'; // 'joker', 'andar', 'bahar'
  late AnimationController _dealController;
  late AnimationController _blinkController;

  // Flying Chips Overlay
  final List<_FlyingChip> _flyingChips = [];

  // Win Overlay Screen
  String _winnerName = ''; // 'Andar' or 'Bahar'

  // Layout Keys to calculate coordinates for Flying Chips
  final GlobalKey _andarPanelKey = GlobalKey();
  final GlobalKey _baharPanelKey = GlobalKey();
  final GlobalKey _tiePanelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _startBettingPhase();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _dealController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  // --- Game Loop States ---

  void _startBettingPhase() {
    _blinkController.stop();
    _blinkController.reset();
    setState(() {
      _gamePhase = 'betting';
      _timerSeconds = 15;
      _userBetAndar = 0.0;
      _userBetBahar = 0.0;
      _userBetTie = 0.0;
      _totalBetAndar = 0.0;
      _totalBetBahar = 0.0;
      _totalBetTie = 0.0;
      _andarCard = null;
      _baharCard = null;
      _mockBetsAndar.clear();
      _mockBetsBahar.clear();
      _mockBetsTie.clear();
      _tableChips.clear();
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
          // Random mock players placing bets on every second
          final int betCount = _random.nextInt(3) + 1;
          for (int i = 0; i < betCount; i++) {
            _simulateMockBets();
          }
        });
      } else {
        _gameTimer?.cancel();
        _startDealingPhase();
      }
    });
  }

  void _simulateMockBets() {
    setState(() {
      // 6 profiles random bet pattern (70% probability per tick)
      if (_random.nextDouble() > 0.70) return;

      final double betValue = [10, 100, 500, 1000][_random.nextInt(4)].toDouble();
      final int spotIndex = _random.nextInt(3);
      final String spot = spotIndex == 0 ? 'andar' : (spotIndex == 1 ? 'bahar' : 'tie');

      final bool isLeft = _random.nextBool();
      final int playerIndex = _random.nextInt(3);
      final String playerKey = isLeft ? 'L$playerIndex' : 'R$playerIndex';

      double startX = isLeft ? 0.05 : 0.95;
      double startY = 0.30 + 0.08 + playerIndex * 0.145;

      bool placeBet = false;
      if (isLeft) {
        if (playerIndex == 0 && _billionaireBalance >= betValue) {
          _billionaireBalance = math.max(0.0, _billionaireBalance - betValue);
          placeBet = true;
        } else if (playerIndex == 1 && _richieBalance >= betValue) {
          _richieBalance = math.max(0.0, _richieBalance - betValue);
          placeBet = true;
        } else if (playerIndex == 2 && _highRollerBalance >= betValue) {
          _highRollerBalance = math.max(0.0, _highRollerBalance - betValue);
          placeBet = true;
        }
      } else {
        if (playerIndex == 0 && _masterBalance >= betValue) {
          _masterBalance = math.max(0.0, _masterBalance - betValue);
          placeBet = true;
        } else if (playerIndex == 1 && _proKingBalance >= betValue) {
          _proKingBalance = math.max(0.0, _proKingBalance - betValue);
          placeBet = true;
        } else if (playerIndex == 2 && _elitePlayerBalance >= betValue) {
          _elitePlayerBalance = math.max(0.0, _elitePlayerBalance - betValue);
          placeBet = true;
        }
      }

      if (placeBet) {
        if (spot == 'andar') {
          _totalBetAndar += betValue;
          _mockBetsAndar[playerKey] = (_mockBetsAndar[playerKey] ?? 0) + betValue;
        } else if (spot == 'bahar') {
          _totalBetBahar += betValue;
          _mockBetsBahar[playerKey] = (_mockBetsBahar[playerKey] ?? 0) + betValue;
        } else {
          _totalBetTie += betValue;
          _mockBetsTie[playerKey] = (_mockBetsTie[playerKey] ?? 0) + betValue;
        }

        final chipColor = _getChipColor(betValue.toInt());
        final chipLabel = _getChipText(betValue.toInt());

        _triggerChipFlight(
          spot: spot,
          startX: startX,
          startY: startY,
          chipColor: chipColor,
          chipLabel: chipLabel,
        );
      }
    });
  }

  void _startDealingPhase() {
    setState(() {
      _gamePhase = 'dealing';
    });

    _dealAndarCard().then((_) {
      _dealBaharCard().then((_) {
        _evaluateRoundWinner();
      });
    });
  }

  Future<void> _dealAndarCard() async {
    final card = _generateRandomCard();
    await _animateCardDeal(card, 'andar');
    setState(() {
      _andarCard = card;
    });
  }

  Future<void> _dealBaharCard() async {
    final card = _generateRandomCard();
    await _animateCardDeal(card, 'bahar');
    setState(() {
      _baharCard = card;
    });
  }

  void _evaluateRoundWinner() {
    if (_andarCard == null || _baharCard == null) return;

    final int andarRank = _andarCard!.rank;
    final int baharRank = _baharCard!.rank;

    String winner;
    if (andarRank > baharRank) {
      winner = 'Andar';
    } else if (baharRank > andarRank) {
      winner = 'Bahar';
    } else {
      winner = 'Tie';
    }

    _triggerWinner(winner);
  }

  PlayingCard _generateRandomCard() {
    final suits = ['Hearts', 'Diamonds', 'Spades', 'Clubs'];
    final rank = _random.nextInt(13) + 1;
    final suit = suits[_random.nextInt(suits.length)];
    return PlayingCard(rank: rank, suit: suit);
  }

  Future<void> _animateCardDeal(PlayingCard card, String target) async {
    SoundManager.playCardPlace();
    setState(() {
      _currentlyDealingCard = card;
      _dealingTarget = target;
      _isDealingCard = true;
    });

    _dealController.reset();

    // Custom animation simulation for 3D flip mid-flight
    await _dealController.animateTo(1.0, duration: const Duration(milliseconds: 650));

    setState(() {
      _isDealingCard = false;
      _currentlyDealingCard = null;
    });
  }

  void _triggerWinner(String winner) {
    _blinkController.repeat(reverse: true);
    setState(() {
      _gamePhase = 'winner';
      _winnerName = winner;
      _history.insert(0, winner == 'Andar' ? 'A' : (winner == 'Bahar' ? 'B' : 'T'));
      if (_history.length > 20) _history.removeLast();

      // Calculate Winnings
      double winnings = 0.0;
      if (winner == 'Andar' && _userBetAndar > 0) {
        winnings = _userBetAndar * 1.9;
      } else if (winner == 'Bahar' && _userBetBahar > 0) {
        winnings = _userBetBahar * 1.9;
      } else if (winner == 'Tie' && _userBetTie > 0) {
        winnings = _userBetTie * 8.2;
      }

      // Clear static table chips as evaluation begins
      _tableChips.clear();

      if (winnings > 0) {
        widget.onBalanceChanged(widget.balance + winnings);
        _triggerWinningsFlight(spot: winner.toLowerCase(), targetX: 0.05, targetY: 0.92, value: winnings);
      }

      // Mock players winnings return flight
      final Map<String, double> winningBets = winner == 'Andar'
          ? _mockBetsAndar
          : (winner == 'Bahar' ? _mockBetsBahar : _mockBetsTie);

      final double payoutMultiplier = winner == 'Tie' ? 8.2 : 1.9;

      winningBets.forEach((playerKey, betValue) {
        if (betValue > 0) {
          final double playerWinnings = betValue * payoutMultiplier;
          final bool isLeft = playerKey.startsWith('L');
          final int index = int.parse(playerKey.substring(1));

          if (isLeft) {
            if (index == 0) {
              _billionaireBalance += playerWinnings;
            } else if (index == 1) {
              _richieBalance += playerWinnings;
            } else {
              _highRollerBalance += playerWinnings;
            }
          } else {
            if (index == 0) {
              _masterBalance += playerWinnings;
            } else if (index == 1) {
              _proKingBalance += playerWinnings;
            } else {
              _elitePlayerBalance += playerWinnings;
            }
          }

          double targetX = isLeft ? 0.05 : 0.95;
          double targetY = 0.30 + 0.08 + index * 0.145;

          _triggerWinningsFlight(spot: winner.toLowerCase(), targetX: targetX, targetY: targetY, value: playerWinnings);
        }
      });
    });

    // Reset game and return to betting after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _startBettingPhase();
      }
    });
  }

  // --- Betting actions ---

  void _placeBet(String spot) {
    if (_gamePhase != 'betting') return;

    if (widget.balance < _selectedChipValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient Balance!'),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final chipColor = _getChipColor(_selectedChipValue);
    final chipLabel = _getChipText(_selectedChipValue);

    // Trigger Chip Flight Animation from Satyamsk position
    _triggerChipFlight(
      spot: spot,
      startX: 0.05,
      startY: 0.92,
      chipColor: chipColor,
      chipLabel: chipLabel,
    );

    // Sync state
    widget.onBalanceChanged(widget.balance - _selectedChipValue);
    setState(() {
      if (spot == 'andar') {
        _userBetAndar += _selectedChipValue;
        _totalBetAndar += _selectedChipValue;
      } else if (spot == 'bahar') {
        _userBetBahar += _selectedChipValue;
        _totalBetBahar += _selectedChipValue;
      } else if (spot == 'tie') {
        _userBetTie += _selectedChipValue;
        _totalBetTie += _selectedChipValue;
      }
    });

    SoundManager.playClick();
  }

  void _triggerChipFlight({
    required String spot,
    required double startX,
    required double startY,
    required Color chipColor,
    required String chipLabel,
  }) {
    double endX = 0.5;
    double endY = 0.5;

    if (spot == 'andar') {
      endX = 0.22 + _random.nextDouble() * 0.22;
      endY = 0.59 + _random.nextDouble() * 0.12;
    } else if (spot == 'bahar') {
      endX = 0.56 + _random.nextDouble() * 0.22;
      endY = 0.59 + _random.nextDouble() * 0.12;
    } else if (spot == 'tie') {
      endX = 0.32 + _random.nextDouble() * 0.36;
      endY = 0.41 + _random.nextDouble() * 0.08;
    }

    final newChip = _FlyingChip(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      color: chipColor,
      label: chipLabel,
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
    );

    setState(() {
      _flyingChips.add(newChip);
    });

    newChip.controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _flyingChips.remove(newChip);
        _tableChips.add(TableChip(
          x: newChip.endX,
          y: newChip.endY,
          color: newChip.color,
          label: newChip.label,
        ));
      });
      newChip.controller.dispose();
    });
  }

  void _triggerWinningsFlight({
    required String spot,
    required double targetX,
    required double targetY,
    required double value,
  }) {
    double startX = 0.5;
    double startY = 0.5;
    if (spot == 'andar') {
      startX = 0.33;
      startY = 0.65;
    } else if (spot == 'bahar') {
      startX = 0.67;
      startY = 0.65;
    } else {
      startX = 0.50;
      startY = 0.45;
    }

    final Color chipColor = _getChipColor(value.toInt() > 0 ? value.toInt() : 10);
    final String chipLabel = _getChipText(value.toInt() > 0 ? value.toInt() : 10);

    final int count = value >= 1000 ? 3 : (value >= 100 ? 2 : 1);
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (!mounted) return;
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        );

        final chip = _FlyingChip(
          startX: startX,
          startY: startY,
          endX: targetX,
          endY: targetY,
          color: chipColor,
          label: chipLabel,
          controller: controller,
        );

        setState(() {
          _flyingChips.add(chip);
        });

        controller.forward().then((_) {
          setState(() {
            _flyingChips.remove(chip);
          });
          controller.dispose();
        });
      });
    }
  }

  Color _getChipColor(int val) {
    switch (val) {
      case 10:
        return const Color(0xFF1E1E24); // Black
      case 100:
        return const Color(0xFF2E7D32); // Green
      case 500:
        return const Color(0xFF1565C0); // Blue
      case 1000:
        return const Color(0xFF6A1B9A); // Purple (1K)
      case 10000:
        return const Color(0xFFD84315); // Orange/Gold (10K)
      default:
        return Colors.blueGrey;
    }
  }

  String _getChipText(int val) {
    if (val >= 10000) return '10K';
    if (val >= 1000) return '1K';
    return '$val';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1E), // Premium deep navy backdrop
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;
          final double w = constraints.maxWidth;

          // Main Game Layout
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Top Header Row
              Positioned(
                top: h * 0.04,
                left: w * 0.02,
                right: w * 0.02,
                child: _buildTopHeader(w, h),
              ),

              // 2. Left side Stacked Players Avatars
              Positioned(
                top: h * 0.30,
                left: w * 0.02,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayerWidget(
                      name: 'Billionaire',
                      balance: _billionaireBalance,
                      isLeft: true,
                      iconData: Icons.diamond,
                      color: const Color(0xFFFFD700),
                      showNameTag: true,
                    ),
                    SizedBox(height: h * 0.065),
                    _buildPlayerWidget(
                      name: 'Richie',
                      balance: _richieBalance,
                      isLeft: true,
                      iconData: Icons.workspace_premium,
                      color: const Color(0xFFFFB300),
                      showNameTag: false,
                    ),
                    SizedBox(height: h * 0.065),
                    _buildPlayerWidget(
                      name: 'High Roller',
                      balance: _highRollerBalance,
                      isLeft: true,
                      iconData: Icons.insights,
                      color: const Color(0xFFFFA000),
                      showNameTag: false,
                    ),
                  ],
                ),
              ),

              // 3. Right side Stacked Players Avatars
              Positioned(
                top: h * 0.30,
                right: w * 0.02,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayerWidget(
                      name: 'Master',
                      balance: _masterBalance,
                      isLeft: false,
                      iconData: Icons.star,
                      color: const Color(0xFF00E5FF),
                      showNameTag: true,
                    ),
                    SizedBox(height: h * 0.065),
                    _buildPlayerWidget(
                      name: 'Pro King',
                      balance: _proKingBalance,
                      isLeft: false,
                      iconData: Icons.bolt,
                      color: const Color(0xFF26C6DA),
                      showNameTag: false,
                    ),
                    SizedBox(height: h * 0.065),
                    _buildPlayerWidget(
                      name: 'Elite Player',
                      balance: _elitePlayerBalance,
                      isLeft: false,
                      iconData: Icons.auto_awesome,
                      color: const Color(0xFF00B0FF),
                      showNameTag: false,
                    ),
                  ],
                ),
              ),

              // 4. Bottom Left Satyamsk (Real User)
              Positioned(
                bottom: h * 0.05,
                left: w * 0.02,
                child: _buildBottomUserWidget(),
              ),

              // 5. Central Gameplay / Betting Area
              Positioned(
                top: h * 0.28,
                left: w * 0.18,
                right: w * 0.18,
                bottom: h * 0.14,
                child: Column(
                  children: [
                    // History Bar
                    SizedBox(
                      height: h * 0.08,
                      child: _buildHistoryBar(),
                    ),
                    SizedBox(height: h * 0.02),

                    // Betting Board Panels
                    Expanded(
                      child: _buildBettingBoard(w, h),
                    ),
                  ],
                ),
              ),

              // 6. Center Cards Dealing overlay
              _buildDealingCardsOverlay(w, h),

              // 7. Bottom Chip Selector (center)
              Positioned(
                bottom: h * 0.03,
                left: w * 0.32,
                right: w * 0.32,
                child: _buildChipSelector(h),
              ),

              // 8. Static Table Chips (already placed on Andar/Bahar/Tie panels)
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: _tableChips.map((chip) {
                      return Positioned(
                        left: chip.x * w - 9.0,
                        top: chip.y * h - 9.0,
                        child: _buildPokerChipWidget(
                          chip.color,
                          chip.label,
                          size: 18.0,
                          selected: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 9. Flying Chips Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: _flyingChips.map((chip) {
                      return AnimatedBuilder(
                        animation: chip.controller,
                        builder: (context, child) {
                          final double t = chip.controller.value;
                          final double currentX = chip.startX + (chip.endX - chip.startX) * t;
                          final double arcY = -0.15 * math.sin(t * math.pi);
                          final double currentY = chip.startY + (chip.endY - chip.startY) * t + arcY;

                          final double scale = 1.0 + 0.15 * math.sin(t * math.pi);

                          return Positioned(
                            left: currentX * w - 9.0,
                            top: currentY * h - 9.0,
                            child: Transform.scale(
                              scale: scale,
                              child: _buildPokerChipWidget(
                                chip.color,
                                chip.label,
                                size: 18.0,
                                selected: true,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 9. 10-Second Lottie Countdown (top right, slightly below the corner)
              if (_gamePhase == 'betting' && _timerSeconds <= 10 && _timerSeconds > 3)
                Positioned(
                  right: w * 0.03,
                  top: h * 0.08,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 100.0,
                      height: 40.0,
                      child: Lottie.asset(
                        'assets/10_second_countdown_timer.json',
                        repeat: false,
                      ),
                    ),
                  ),
                ),

              // 10. Last 3 Seconds Lottie Countdown (center)
              if (_gamePhase == 'betting' && _timerSeconds <= 3 && _timerSeconds > 0)
                Align(
                  alignment: Alignment.center,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 140.0,
                      height: 140.0,
                      child: Lottie.asset(
                        'assets/count_down_red_and_grey_3_to_1.json',
                        repeat: false,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Top Header Widget ---
  Widget _buildTopHeader(double w, double h) {
    final double cardWidth = w * 0.055;
    final double cardHeight = h * 0.15;

    return SizedBox(
      height: h * 0.16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Back Button (left aligned)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: widget.onBackPressed,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16.0),
              ),
            ),
          ),

          // 2. Centered Card Group: Card A VS Card B
          Positioned(
            left: w * 0.35,
            right: w * 0.35,
            top: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card A (Andar)
                _isDealingCard && _dealingTarget == 'andar'
                    ? AnimatedBuilder(
                        animation: _dealController,
                        builder: (context, child) {
                          final double t = _dealController.value;
                          final double angle = t * math.pi;
                          final bool showFront = angle > (math.pi / 2);

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: showFront
                                ? _buildGameCard(_currentlyDealingCard!, cardWidth, cardHeight)
                                : _buildCardBack(cardWidth, cardHeight),
                          );
                        },
                      )
                    : (_andarCard != null
                        ? _buildGameCard(_andarCard!, cardWidth, cardHeight)
                        : _buildMiniCardPlaceholder('A', const Color(0xFF1565C0), cardWidth, cardHeight)),
                
                const SizedBox(width: 14.0),

                // VS middle text
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFFFFF9C4)],
                  ).createShader(bounds),
                  child: Text(
                    'VS',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14.0),

                // Card B (Bahar)
                _isDealingCard && _dealingTarget == 'bahar'
                    ? AnimatedBuilder(
                        animation: _dealController,
                        builder: (context, child) {
                          final double t = _dealController.value;
                          final double angle = t * math.pi;
                          final bool showFront = angle > (math.pi / 2);

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: showFront
                                ? _buildGameCard(_currentlyDealingCard!, cardWidth, cardHeight)
                                : _buildCardBack(cardWidth, cardHeight),
                          );
                        },
                      )
                    : (_baharCard != null
                        ? _buildGameCard(_baharCard!, cardWidth, cardHeight)
                        : _buildMiniCardPlaceholder('B', const Color(0xFFC62828), cardWidth, cardHeight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCardPlaceholder(String label, Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Players Widgets (Billionaire / Master) ---
  Widget _buildPlayerWidget({
    required String name,
    required double balance,
    required bool isLeft,
    required IconData iconData,
    required Color color,
    required bool showNameTag,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNameTag) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft) Icon(iconData, color: color, size: 10.0) else const SizedBox(),
              const SizedBox(width: 4.0),
              Text(
                name,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4.0),
              if (!isLeft) Icon(iconData, color: color, size: 10.0) else const SizedBox(),
            ],
          ),
          const SizedBox(height: 2.0),
        ],

        // Circular portrait
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3.0)],
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF1E2240),
              alignment: Alignment.center,
              child: Icon(
                isLeft ? Icons.person : Icons.person_3,
                color: Colors.white70,
                size: 20.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2.0),

        // Balance Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 9.0),
              const SizedBox(width: 2.0),
              Text(
                balance.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Bottom User (Real User Satyamsk) ---
  Widget _buildBottomUserWidget() {
    return Row(
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF1E2240),
              alignment: Alignment.center,
              child: const Icon(Icons.face, color: Colors.white70, size: 22.0),
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Satyamsk',
              style: TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0x4D000000),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 10.0),
                  const SizedBox(width: 2.0),
                  Text(
                    widget.balance.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- History Bar ---
  Widget _buildHistoryBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6.0),
              itemBuilder: (context, index) {
                final isA = _history[index] == 'A';
                return Container(
                  width: 18.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isA ? const Color(0xFF1565C0) : const Color(0xFFC62828),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _history[index],
                    style: const TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.white10),
          ),
          child: const Icon(Icons.trending_up, color: Colors.white, size: 16.0),
        ),
      ],
    );
  }

  // --- Betting Board panels ---
  Widget _buildBettingBoard(double w, double h) {
    return Column(
      children: [
        GestureDetector(
          key: _tiePanelKey,
          onTap: () => _placeBet('tie'),
          child: _buildTiePanel(h),
        ),
        SizedBox(height: h * 0.02),

        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: _andarPanelKey,
                  onTap: () => _placeBet('andar'),
                  child: _buildSideBetPanel('Andar', _totalBetAndar, _userBetAndar, const Color(0xFF1565C0), isLeft: true),
                ),
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: GestureDetector(
                  key: _baharPanelKey,
                  onTap: () => _placeBet('bahar'),
                  child: _buildSideBetPanel('Bahar', _totalBetBahar, _userBetBahar, const Color(0xFFC62828), isLeft: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTiePanel(double h) {
    final bool showStartBetting = _gamePhase == 'betting';
    final bool isWinner = _gamePhase == 'winner' && _winnerName == 'Tie';

    Widget panelContent = Stack(
      children: [
        Positioned(
          top: 2.0,
          left: 2.0,
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 10.0),
              const SizedBox(width: 2.0),
              Text(
                '${_totalBetTie.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 2.0,
          right: 2.0,
          child: Text(
            'Can bet: 2147483397',
            style: TextStyle(color: Colors.white54, fontSize: 7.5),
          ),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '8.2',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10.0, fontWeight: FontWeight.bold),
              ),
              const Text(
                'TIE',
                style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              if (showStartBetting)
                const Text(
                  'Start betting',
                  style: TextStyle(color: Color(0xFF00E676), fontSize: 8.0, fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  'Betting Closed',
                  style: TextStyle(color: Colors.grey, fontSize: 8.0, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    );

    if (isWinner) {
      return AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: h * 0.16,
            decoration: _getTiePanelDecoration(true),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            child: child,
          );
        },
        child: panelContent,
      );
    } else {
      return Container(
        width: double.infinity,
        height: h * 0.16,
        decoration: _getTiePanelDecoration(false),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: panelContent,
      );
    }
  }

  BoxDecoration _getTiePanelDecoration(bool isWinner) {
    const Color tieBaseColor = Color(0xFF2E7D32);
    if (isWinner) {
      final double val = _blinkController.value;
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(const Color(0xFF0F3B20), const Color(0xFFFFD700).withValues(alpha: 0.5), val)!,
            Color.lerp(const Color(0xFF135A30), const Color(0xFFFFD700).withValues(alpha: 0.2), val)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Color.lerp(tieBaseColor, const Color(0xFFFFD700), val)!,
          width: 1.5 + 2.0 * val,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.8 * val),
            blurRadius: 12.0 * val,
            spreadRadius: 2.0 * val,
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0F3B20), Color(0xFF135A30)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(color: tieBaseColor, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
    );
  }

  Widget _buildSideBetPanel(String label, double totalBet, double userBet, Color baseColor, {required bool isLeft}) {
    final bool isWinner = _gamePhase == 'winner' && _winnerName.toLowerCase() == label.toLowerCase();

    Widget panelContent = Stack(
      children: [
        Positioned(
          top: 2.0,
          left: 2.0,
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 10.0),
              const SizedBox(width: 2.0),
              Text(
                '${totalBet.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        Positioned(
          top: 2.0,
          right: 2.0,
          child: Text(
            isLeft ? 'Can bet: 2147480327' : 'Can bet: 2147486967',
            style: const TextStyle(color: Colors.white54, fontSize: 7.5),
          ),
        ),

        // Odds "1.9" on the side (left for Andar, right for Bahar)
        Positioned(
          left: isLeft ? 8.0 : null,
          right: !isLeft ? 8.0 : null,
          top: 26.0,
          child: const Text(
            '1.9',
            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10.0, fontWeight: FontWeight.bold),
          ),
        ),

        // Large Center label
        Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),

        if (userBet > 0)
          Positioned(
            bottom: 4.0,
            left: !isLeft ? 8.0 : null,
            right: isLeft ? 8.0 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'Mine: ${userBet.toInt()}',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Star outline aligned on the side (left for Andar, right for Bahar)
        Positioned(
          bottom: 4.0,
          left: isLeft ? 8.0 : null,
          right: !isLeft ? 8.0 : null,
          child: Icon(Icons.star_border, color: Colors.yellow.withValues(alpha: 0.4), size: 14.0),
        ),
      ],
    );

    if (isWinner) {
      return AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          return Container(
            decoration: _getPanelDecoration(baseColor, true),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: child,
          );
        },
        child: panelContent,
      );
    } else {
      return Container(
        decoration: _getPanelDecoration(baseColor, false),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: panelContent,
      );
    }
  }

  BoxDecoration _getPanelDecoration(Color baseColor, bool isWinner) {
    if (isWinner) {
      final double val = _blinkController.value;
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(baseColor.withValues(alpha: 0.4), const Color(0xFFFFD700).withValues(alpha: 0.5), val)!,
            Color.lerp(baseColor.withValues(alpha: 0.15), const Color(0xFFFFD700).withValues(alpha: 0.2), val)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Color.lerp(baseColor, const Color(0xFFFFD700), val)!,
          width: 1.5 + 2.0 * val,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.8 * val),
            blurRadius: 12.0 * val,
            spreadRadius: 2.0 * val,
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [baseColor.withValues(alpha: 0.4), baseColor.withValues(alpha: 0.15)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(color: baseColor, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
    );
  }

  // --- Cards Dealing Animations Overlay ---
  Widget _buildDealingCardsOverlay(double w, double h) {
    return const SizedBox.shrink();
  }


  Widget _buildGameCard(PlayingCard card, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4.0, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          Positioned(
            top: 2.0,
            left: 2.0,
            child: Column(
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(color: card.color, fontSize: 10.0, fontWeight: FontWeight.bold, height: 1.0),
                ),
                _getSuitIcon(card.suit, card.color, size: 8.0),
              ],
            ),
          ),
          Center(
            child: _getSuitIcon(card.suit, card.color, size: 16.0),
          ),
          Positioned(
            bottom: 2.0,
            right: 2.0,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                children: [
                  Text(
                    card.rankLabel,
                    style: TextStyle(color: card.color, fontSize: 10.0, fontWeight: FontWeight.bold, height: 1.0),
                  ),
                  _getSuitIcon(card.suit, card.color, size: 8.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4.0)],
      ),
      child: const Center(
        child: Icon(Icons.style, color: Colors.white70, size: 18.0),
      ),
    );
  }

  Widget _getSuitIcon(String suit, Color color, {double size = 12.0}) {
    String symbol;
    switch (suit) {
      case 'Hearts':
        symbol = '♥';
        break;
      case 'Diamonds':
        symbol = '♦';
        break;
      case 'Spades':
        symbol = '♠';
        break;
      default:
        symbol = '♣';
        break;
    }
    return Text(
      symbol,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
    );
  }

  // --- Bottom Chip Selector ---
  Widget _buildChipSelector(double h) {
    final chipValues = [10, 100, 500, 1000, 10000];
    return Container(
      height: h * 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: chipValues.map((val) {
          final isSelected = _selectedChipValue == val;
          final color = _getChipColor(val);
          final label = _getChipText(val);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChipValue = val;
              });
              SoundManager.playClick();
            },
            child: Transform.scale(
              scale: isSelected ? 1.12 : 1.0,
              child: _buildPokerChipWidget(color, label, selected: isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPokerChipWidget(Color color, String label, {double size = 32.0, bool selected = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.9), color],
          radius: 0.8,
        ),
        border: Border.all(
          color: selected ? const Color(0xFF00E5FF) : Colors.white60,
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selected ? const Color(0x9900E5FF) : Colors.black45,
            blurRadius: selected ? 6.0 : 3.0,
            spreadRadius: selected ? 1.0 : 0.0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size - 8.0,
        height: size - 8.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, style: BorderStyle.solid),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

}

class _FlyingChip {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final String label;
  final AnimationController controller;

  _FlyingChip({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.label,
    required this.controller,
  });
}

class TableChip {
  final double x;
  final double y;
  final Color color;
  final String label;

  TableChip({
    required this.x,
    required this.y,
    required this.color,
    required this.label,
  });
}
