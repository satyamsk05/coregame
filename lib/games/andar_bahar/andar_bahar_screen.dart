import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/widgets/bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../utils/sound_manager.dart';
import 'models/playing_card.dart';
import 'models/chip_models.dart';
import 'widgets/card_widgets.dart';
import 'widgets/chip_widgets.dart';
import 'widgets/player_widgets.dart';
import 'widgets/history_bar_widget.dart';
import 'widgets/bet_panels.dart';

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

class _AndarBaharGameScreenState extends State<AndarBaharGameScreen>
    with TickerProviderStateMixin {
  final math.Random _random = math.Random();

  // ── Game Phase ──────────────────────────────────────────────────────────────
  // 'betting' → betting open, countdown running
  // 'dealing' → dealing cards, betting closed
  // 'winner'  → winner revealed, overlay + winnings count-up
  String _gamePhase = 'betting';
  int _timerSeconds = 12;
  Timer? _gameTimer;

  // ── User Bets ────────────────────────────────────────────────────────────────
  int _selectedChipValue = 10;
  double _userBetAndar = 0.0;
  double _userBetBahar = 0.0;
  double _userBetTie = 0.0;

  // ── Table Totals (user + mock players) ──────────────────────────────────────
  double _totalBetAndar = 3970.0;
  double _totalBetBahar = 650.0;
  double _totalBetTie = 250.0;

  // ── Mock Player Balances ─────────────────────────────────────────────────────
  double _billionaireBalance = 84500.0;
  double _richieBalance = 24500.0;
  double _highRollerBalance = 9800.0;
  double _masterBalance = 5400.0;
  double _proKingBalance = 12800.0;
  double _elitePlayerBalance = 7500.0;

  // ── Mock Player Bet Tracking ─────────────────────────────────────────────────
  final Map<String, double> _mockBetsAndar = {};
  final Map<String, double> _mockBetsBahar = {};
  final Map<String, double> _mockBetsTie = {};

  // ── Table Chips (static — already placed) ────────────────────────────────────
  final List<TableChip> _tableChips = [];

  // ── Round History ────────────────────────────────────────────────────────────
  final List<String> _history = [
    'B', 'B', 'B', 'A', 'A', 'A', 'B', 'A', 'B', 'B', 'B', 'A', 'B', 'B', 'B', 'A'
  ];

  // ── Dealt Cards ──────────────────────────────────────────────────────────────
  PlayingCard? _andarCard;
  PlayingCard? _baharCard;

  // ── Card Animation ────────────────────────────────────────────────────────────
  bool _isDealingCard = false;
  PlayingCard? _currentlyDealingCard;
  String _dealingTarget = 'joker'; // 'joker' | 'andar' | 'bahar'
  late AnimationController _dealController;
  late AnimationController _blinkController;

  // ── Flying Chips ─────────────────────────────────────────────────────────────
  final List<FlyingChip> _flyingChips = [];

  // ── Winner ───────────────────────────────────────────────────────────────────
  String _winnerName = ''; // 'Andar' | 'Bahar' | 'Tie'

  // ── Layout Keys ──────────────────────────────────────────────────────────────
  final GlobalKey _andarPanelKey = GlobalKey();
  final GlobalKey _baharPanelKey = GlobalKey();
  final GlobalKey _tiePanelKey = GlobalKey();

  // ════════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ════════════════════════════════════════════════════════════════════════════

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
    for (final chip in _flyingChips) {
      chip.controller.dispose();
    }
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Game Loop
  // ════════════════════════════════════════════════════════════════════════════

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
    if (_random.nextDouble() > 0.70) return;

    final double betValue =
        [10, 100, 500, 1000][_random.nextInt(4)].toDouble();
    final int spotIndex = _random.nextInt(3);
    final String spot =
        spotIndex == 0 ? 'andar' : (spotIndex == 1 ? 'bahar' : 'tie');

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
        _mockBetsAndar[playerKey] =
            (_mockBetsAndar[playerKey] ?? 0) + betValue;
      } else if (spot == 'bahar') {
        _totalBetBahar += betValue;
        _mockBetsBahar[playerKey] =
            (_mockBetsBahar[playerKey] ?? 0) + betValue;
      } else {
        _totalBetTie += betValue;
        _mockBetsTie[playerKey] =
            (_mockBetsTie[playerKey] ?? 0) + betValue;
      }

      _triggerChipFlight(
        spot: spot,
        startX: startX,
        startY: startY,
        chipColor: ChipSelectorWidget.getChipColor(betValue.toInt()),
        chipLabel: ChipSelectorWidget.getChipText(betValue.toInt()),
      );
    }
  }

  void _startDealingPhase() {
    setState(() => _gamePhase = 'dealing');
    _dealAndarCard().then((_) {
      _dealBaharCard().then((_) {
        _evaluateRoundWinner();
      });
    });
  }

  Future<void> _dealAndarCard() async {
    final card = _generateRandomCard();
    await _animateCardDeal(card, 'andar');
    setState(() => _andarCard = card);
  }

  Future<void> _dealBaharCard() async {
    final card = _generateRandomCard();
    await _animateCardDeal(card, 'bahar');
    setState(() => _baharCard = card);
  }

  void _evaluateRoundWinner() {
    if (_andarCard == null || _baharCard == null) return;
    final int a = _andarCard!.rank;
    final int b = _baharCard!.rank;
    String winner;
    if (a > b) {
      winner = 'Andar';
    } else if (b > a) {
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
    await _dealController.animateTo(1.0,
        duration: const Duration(milliseconds: 650));
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
      _history.insert(
          0, winner == 'Andar' ? 'A' : (winner == 'Bahar' ? 'B' : 'T'));
      if (_history.length > 20) _history.removeLast();
      _tableChips.clear();

      double winnings = 0.0;
      if (winner == 'Andar' && _userBetAndar > 0) {
        winnings = _userBetAndar * 1.9;
      } else if (winner == 'Bahar' && _userBetBahar > 0) {
        winnings = _userBetBahar * 1.9;
      } else if (winner == 'Tie' && _userBetTie > 0) {
        winnings = _userBetTie * 8.2;
      }

      if (winnings > 0) {
        widget.onBalanceChanged(widget.balance + winnings);
        _triggerWinningsFlight(
            spot: winner.toLowerCase(),
            targetX: 0.05,
            targetY: 0.92,
            value: winnings);
      }

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
          _triggerWinningsFlight(
              spot: winner.toLowerCase(),
              targetX: isLeft ? 0.05 : 0.95,
              targetY: 0.30 + 0.08 + index * 0.145,
              value: playerWinnings);
        }
      });
    });

    // Reset game and return to betting after exactly 3 blinks (2100 milliseconds)
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) _startBettingPhase();
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Betting Actions
  // ════════════════════════════════════════════════════════════════════════════

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

    _triggerChipFlight(
      spot: spot,
      startX: 0.05,
      startY: 0.92,
      chipColor: ChipSelectorWidget.getChipColor(_selectedChipValue),
      chipLabel: ChipSelectorWidget.getChipText(_selectedChipValue),
    );

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

  // ════════════════════════════════════════════════════════════════════════════
  // Chip Flight Animations
  // ════════════════════════════════════════════════════════════════════════════

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
      endY = 0.36 + _random.nextDouble() * 0.08;
    }

    final newChip = FlyingChip(
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

    setState(() => _flyingChips.add(newChip));

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
      startY = 0.40;
    }

    final Color chipColor = ChipSelectorWidget.getChipColor(
        value.toInt() > 0 ? value.toInt() : 10);
    final String chipLabel = ChipSelectorWidget.getChipText(
        value.toInt() > 0 ? value.toInt() : 10);

    final int count = value >= 1000 ? 3 : (value >= 100 ? 2 : 1);
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (!mounted) return;
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        );
        final chip = FlyingChip(
          startX: startX,
          startY: startY,
          endX: targetX,
          endY: targetY,
          color: chipColor,
          label: chipLabel,
          controller: controller,
        );
        setState(() => _flyingChips.add(chip));
        controller.forward().then((_) {
          setState(() => _flyingChips.remove(chip));
          controller.dispose();
        });
      });
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B1E),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;
          final double w = constraints.maxWidth;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Top Header
              Positioned(
                top: h * 0.04,
                left: w * 0.02,
                right: w * 0.02,
                child: _buildTopHeader(w, h),
              ),

              // 2. Left Mock Players
              Positioned(
                top: h * 0.25,
                left: w * 0.02,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MockPlayerWidget(
                      name: 'Billionaire',
                      balance: _billionaireBalance,
                      isLeft: true,
                      iconData: Icons.diamond,
                      color: const Color(0xFFFFD700),
                      showNameTag: true,
                    ),
                    SizedBox(height: h * 0.045),
                    MockPlayerWidget(
                      name: 'Richie',
                      balance: _richieBalance,
                      isLeft: true,
                      iconData: Icons.workspace_premium,
                      color: const Color(0xFFFFB300),
                      showNameTag: false,
                    ),
                    SizedBox(height: h * 0.045),
                    MockPlayerWidget(
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

              // 3. Right Mock Players
              Positioned(
                top: h * 0.25,
                right: w * 0.02,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MockPlayerWidget(
                      name: 'Master',
                      balance: _masterBalance,
                      isLeft: false,
                      iconData: Icons.star,
                      color: const Color(0xFF00E5FF),
                      showNameTag: true,
                    ),
                    SizedBox(height: h * 0.045),
                    MockPlayerWidget(
                      name: 'Pro King',
                      balance: _proKingBalance,
                      isLeft: false,
                      iconData: Icons.bolt,
                      color: const Color(0xFF26C6DA),
                      showNameTag: false,
                    ),
                    SizedBox(height: h * 0.045),
                    MockPlayerWidget(
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

              // 4. Bottom User
              Positioned(
                bottom: h * 0.05,
                left: w * 0.02,
                child: UserAvatarWidget(balance: widget.balance),
              ),

              // 5. Central Gameplay / Betting Area
              Positioned(
                top: h * 0.22,
                left: w * 0.18,
                right: w * 0.18,
                bottom: h * 0.19,
                child: Column(
                  children: [
                    SizedBox(
                      height: h * 0.08,
                      child: HistoryBarWidget(history: _history),
                    ),
                    SizedBox(height: h * 0.02),
                    Expanded(child: _buildBettingBoard(w, h)),
                  ],
                ),
              ),

              // 6. Dealing cards overlay (placeholder — expand as needed)
              const SizedBox.shrink(),

              // 7. Chip Selector
              Positioned(
                bottom: h * 0.03,
                left: w * 0.32,
                right: w * 0.32,
                child: ChipSelectorWidget(
                  selectedChipValue: _selectedChipValue,
                  height: h,
                  onChipSelected: (val) {
                    setState(() => _selectedChipValue = val);
                    SoundManager.playClick();
                  },
                ),
              ),

              // 8. Static placed chips
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: _tableChips.map((chip) {
                      return Positioned(
                        left: chip.x * w - 9.0,
                        top: chip.y * h - 9.0,
                        child: PokerChipWidget(
                          color: chip.color,
                          label: chip.label,
                          size: 18.0,
                          selected: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 9. Flying chips
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: _flyingChips.map((chip) {
                      return AnimatedBuilder(
                        animation: chip.controller,
                        builder: (context, child) {
                          final double t = chip.controller.value;
                          final double currentX =
                              chip.startX + (chip.endX - chip.startX) * t;
                          final double arcY =
                              -0.15 * math.sin(t * math.pi);
                          final double currentY = chip.startY +
                              (chip.endY - chip.startY) * t +
                              arcY;
                          final double scale =
                              1.0 + 0.15 * math.sin(t * math.pi);
                          return Positioned(
                            left: currentX * w - 9.0,
                            top: currentY * h - 9.0,
                            child: Transform.scale(
                              scale: scale,
                              child: PokerChipWidget(
                                color: chip.color,
                                label: chip.label,
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

              // 10. Lottie 10-sec countdown
              if (_gamePhase == 'betting' &&
                  _timerSeconds <= 10 &&
                  _timerSeconds > 3)
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

              // 11. Lottie last-3-sec countdown
              if (_gamePhase == 'betting' &&
                  _timerSeconds <= 3 &&
                  _timerSeconds > 0)
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

  // ════════════════════════════════════════════════════════════════════════════
  // Sub-build methods
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTopHeader(double w, double h) {
    final double cardWidth = w * 0.055;
    final double cardHeight = h * 0.15;

    return SizedBox(
      height: h * 0.16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back button
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
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16.0),
              ),
            ),
          ),

          // Center card group
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
                                ? Transform(
                                    transform: Matrix4.rotationY(math.pi),
                                    alignment: Alignment.center,
                                    child: GameCardWidget(
                                        card: _currentlyDealingCard!,
                                        width: cardWidth,
                                        height: cardHeight),
                                  )
                                : CardBackWidget(
                                    width: cardWidth, height: cardHeight),
                          );
                        },
                      )
                    : (_andarCard != null
                        ? GameCardWidget(
                            card: _andarCard!,
                            width: cardWidth,
                            height: cardHeight)
                        : CardPlaceholderWidget(
                            label: 'A',
                            color: const Color(0xFF1565C0),
                            width: cardWidth,
                            height: cardHeight)),

                const SizedBox(width: 14.0),

                // VS text
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFF9C4),
                      Color(0xFFFFB300),
                      Color(0xFFFFF9C4)
                    ],
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
                                ? Transform(
                                    transform: Matrix4.rotationY(math.pi),
                                    alignment: Alignment.center,
                                    child: GameCardWidget(
                                        card: _currentlyDealingCard!,
                                        width: cardWidth,
                                        height: cardHeight),
                                  )
                                : CardBackWidget(
                                    width: cardWidth, height: cardHeight),
                          );
                        },
                      )
                    : (_baharCard != null
                        ? GameCardWidget(
                            card: _baharCard!,
                            width: cardWidth,
                            height: cardHeight)
                        : CardPlaceholderWidget(
                            label: 'B',
                            color: const Color(0xFFC62828),
                            width: cardWidth,
                            height: cardHeight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBettingBoard(double w, double h) {
    return Column(
      children: [
        GestureDetector(
          key: _tiePanelKey,
          onTap: () => _placeBet('tie'),
          child: TieBetPanel(
            totalBetTie: _totalBetTie,
            userBetTie: _userBetTie,
            isBetting: _gamePhase == 'betting',
            isWinner: _gamePhase == 'winner' && _winnerName == 'Tie',
            blinkAnimation: _blinkController,
            height: h,
          ),
        ),
        SizedBox(height: h * 0.02),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: _andarPanelKey,
                  onTap: () => _placeBet('andar'),
                  child: SideBetPanel(
                    label: 'Andar',
                    totalBet: _totalBetAndar,
                    userBet: _userBetAndar,
                    baseColor: const Color(0xFF1565C0),
                    isLeft: true,
                    isWinner:
                        _gamePhase == 'winner' && _winnerName == 'Andar',
                    blinkAnimation: _blinkController,
                  ),
                ),
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: GestureDetector(
                  key: _baharPanelKey,
                  onTap: () => _placeBet('bahar'),
                  child: SideBetPanel(
                    label: 'Bahar',
                    totalBet: _totalBetBahar,
                    userBet: _userBetBahar,
                    baseColor: const Color(0xFFC62828),
                    isLeft: false,
                    isWinner:
                        _gamePhase == 'winner' && _winnerName == 'Bahar',
                    blinkAnimation: _blinkController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
