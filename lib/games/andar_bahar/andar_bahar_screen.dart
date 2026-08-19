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
  final String nickname;
  final String avatarPath;

  const AndarBaharGameScreen({
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
  int _timerSeconds = 15;
  Timer? _gameTimer;

  // ── User Bets ────────────────────────────────────────────────────────────────
  int _selectedChipValue = 10;
  double _userBetAndar = 0.0;
  double _userBetBahar = 0.0;
  double _userBetTie = 0.0;
  double _userWinAmount = 0.0;
  int _userWinTrigger = 0;
  int _activeUsersCount = 45;



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

  // ── Mock Player Bet Animation Triggers ───────────────────────────────────────
  int _triggerBillionaire = 0;
  int _triggerRichie = 0;
  int _triggerHighRoller = 0;
  int _triggerMaster = 0;
  int _triggerProKing = 0;
  int _triggerElitePlayer = 0;
  int _triggerUser = 0;

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

  // Mock player win triggers & amounts (matching User avatar win float animation)
  double _billionaireWinAmount = 0.0;
  int _billionaireWinTrigger = 0;
  double _richieWinAmount = 0.0;
  int _richieWinTrigger = 0;
  double _highRollerWinAmount = 0.0;
  int _highRollerWinTrigger = 0;
  double _masterWinAmount = 0.0;
  int _masterWinTrigger = 0;
  double _proKingWinAmount = 0.0;
  int _proKingWinTrigger = 0;
  double _elitePlayerWinAmount = 0.0;
  int _elitePlayerWinTrigger = 0;

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
      _userWinAmount = 0.0;
      _totalBetAndar = 0.0;

      _totalBetBahar = 0.0;
      _totalBetTie = 0.0;
      _andarCard = null;
      _baharCard = null;
      _mockBetsAndar.clear();
      _mockBetsBahar.clear();
      _mockBetsTie.clear();
      _tableChips.clear();



      // Reset win text amounts
      _billionaireWinAmount = 0.0;
      _richieWinAmount = 0.0;
      _highRollerWinAmount = 0.0;
      _masterWinAmount = 0.0;
      _proKingWinAmount = 0.0;
      _elitePlayerWinAmount = 0.0;
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
          final int betCount = _random.nextInt(4) + 2;
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
    if (_random.nextDouble() > 0.30) return;

    // Fluctuate active user count slightly
    if (_random.nextDouble() > 0.60) {
      setState(() {
        _activeUsersCount += _random.nextBool() ? _random.nextInt(2) : -_random.nextInt(2);
        _activeUsersCount = _activeUsersCount.clamp(30, 60);
      });
    }

    final double betValue = [
      10, 10, 10, 10, 10,
      50, 50, 50, 50, 50,
      100, 500, 1000, 5000
    ][_random.nextInt(14)].toDouble();

    final int spotIndex = _random.nextInt(3);
    final String spot =
        spotIndex == 0 ? 'andar' : (spotIndex == 1 ? 'bahar' : 'tie');

    // 40% chance the bet is placed by one of the "other" active room users (bottom-right corner)
    final bool isOtherPlayer = _random.nextDouble() < 0.40;

    if (isOtherPlayer) {
      // Matches the actual bottom-right corner position of the active users widget
      const double startX = 0.98;
      const double startY = 0.88;

      setState(() {
        if (spot == 'andar') {
          _totalBetAndar += betValue;
          _mockBetsAndar['activeUsers'] = (_mockBetsAndar['activeUsers'] ?? 0.0) + betValue;
        } else if (spot == 'bahar') {
          _totalBetBahar += betValue;
          _mockBetsBahar['activeUsers'] = (_mockBetsBahar['activeUsers'] ?? 0.0) + betValue;
        } else {
          _totalBetTie += betValue;
          _mockBetsTie['activeUsers'] = (_mockBetsTie['activeUsers'] ?? 0.0) + betValue;
        }

        _triggerChipFlight(
          spot: spot,
          startX: startX,
          startY: startY,
          chipColor: ChipSelectorWidget.getChipColor(betValue.toInt()),
          chipLabel: ChipSelectorWidget.getChipText(betValue.toInt()),
          chipValue: betValue.toInt(),
        );
      });
      return;
    }

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
        _triggerBillionaire++;
      } else if (playerIndex == 1 && _richieBalance >= betValue) {
        _richieBalance = math.max(0.0, _richieBalance - betValue);
        placeBet = true;
        _triggerRichie++;
      } else if (playerIndex == 2 && _highRollerBalance >= betValue) {
        _highRollerBalance = math.max(0.0, _highRollerBalance - betValue);
        placeBet = true;
        _triggerHighRoller++;
      }
    } else {
      if (playerIndex == 0 && _masterBalance >= betValue) {
        _masterBalance = math.max(0.0, _masterBalance - betValue);
        placeBet = true;
        _triggerMaster++;
      } else if (playerIndex == 1 && _proKingBalance >= betValue) {
        _proKingBalance = math.max(0.0, _proKingBalance - betValue);
        placeBet = true;
        _triggerProKing++;
      } else if (playerIndex == 2 && _elitePlayerBalance >= betValue) {
        _elitePlayerBalance = math.max(0.0, _elitePlayerBalance - betValue);
        placeBet = true;
        _triggerElitePlayer++;
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

      if (playerKey == 'R0') {
        // Profile center for Grand Master (right side, index 0)
        // Fractional coords matching Positioned(top: h*0.18, right: w*0.02)
        // Avatar is ~37px wide; screen ~390h → avatar center Y ≈ 0.18 + 18.5/h
        const double profileCX = 0.96; // X center of right-side profile
        const double profileCY = 0.22; // Y center of Grand Master avatar

        // Pre-compute a single fixed landing spot for all 20 stars
        double trailEndX;
        double trailEndY;
        if (spot == 'andar') {
          trailEndX = 0.22 + _random.nextDouble() * 0.22;
          trailEndY = 0.59 + _random.nextDouble() * 0.12;
        } else if (spot == 'bahar') {
          trailEndX = 0.56 + _random.nextDouble() * 0.22;
          trailEndY = 0.59 + _random.nextDouble() * 0.12;
        } else {
          trailEndX = 0.32 + _random.nextDouble() * 0.36;
          trailEndY = 0.36 + _random.nextDouble() * 0.08;
        }

        // 20 stars: first is largest (24px), last is smallest (4px).
        // Each star originates from a slightly different point around the
        // profile card (left/right/top/bottom edges) — 4-directional spread.
        const int total = 20;
        // 4 origin positions cycling: top, right, bottom, left of avatar
        const List<List<double>> offsets = [
          [ 0.00, -0.06], // top
          [ 0.04, -0.03], // top-right
          [ 0.04,  0.00], // right
          [ 0.04,  0.03], // bottom-right
          [ 0.00,  0.06], // bottom
          [-0.04,  0.03], // bottom-left
          [-0.04,  0.00], // left
          [-0.04, -0.03], // top-left
        ];
        for (int i = 0; i < total; i++) {
          final double sz = 24.0 - (20.0 * i / (total - 1)); // 24 → 4
          final List<double> off = offsets[i % offsets.length];
          final double sx = profileCX + off[0];
          final double sy = profileCY + off[1];
          Future.delayed(Duration(milliseconds: i * 45), () {
            if (!mounted) return;
            _triggerChipFlight(
              spot: spot,
              startX: sx,
              startY: sy,
              chipColor: ChipSelectorWidget.getChipColor(betValue.toInt()),
              chipLabel: ChipSelectorWidget.getChipText(betValue.toInt()),
              chipValue: betValue.toInt(),
              isStar: true,
              addToTable: i == total - 1,
              starSize: sz.clamp(4.0, 24.0),
              fixedEndX: trailEndX,
              fixedEndY: trailEndY,
            );
          });
        }
      } else {
        _triggerChipFlight(
          spot: spot,
          startX: startX,
          startY: startY,
          chipColor: ChipSelectorWidget.getChipColor(betValue.toInt()),
          chipLabel: ChipSelectorWidget.getChipText(betValue.toInt()),
          chipValue: betValue.toInt(),
          isStar: false,
          addToTable: true,
        );
      }
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
    });

    final String winningSpot = winner.toLowerCase();

    // 1. Gather Phase: Move chips from losing spots to the winning spot
    final List<TableChip> losingChips = [];
    final List<TableChip> winningChips = [];

    for (var chip in _tableChips) {
      if (chip.spot != winningSpot) {
        losingChips.add(chip);
      } else {
        winningChips.add(chip);
      }
    }

    // Clear losing chips from table display immediately, keeping winning chips visible
    setState(() {
      _tableChips.clear();
      _tableChips.addAll(winningChips);
    });

    // Animate losing chips to the winning spot (takes exactly 1 second)
    for (var chip in losingChips) {
      double targetX = 0.5;
      double targetY = 0.5;
      if (winningSpot == 'andar') {
        targetX = 0.22 + _random.nextDouble() * 0.22;
        targetY = 0.59 + _random.nextDouble() * 0.12;
      } else if (winningSpot == 'bahar') {
        targetX = 0.56 + _random.nextDouble() * 0.22;
        targetY = 0.59 + _random.nextDouble() * 0.12;
      } else if (winningSpot == 'tie') {
        targetX = 0.32 + _random.nextDouble() * 0.36;
        targetY = 0.36 + _random.nextDouble() * 0.08;
      }

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000), // Gather phase duration: 1 second
      );

      final flyingLosingChip = FlyingChip(
        startX: chip.x,
        startY: chip.y,
        endX: targetX,
        endY: targetY,
        color: chip.color,
        label: chip.label,
        controller: controller,
        value: chip.value,
      );

      setState(() => _flyingChips.add(flyingLosingChip));
      controller.forward().then((_) {
        if (!mounted) return;
        setState(() {
          _flyingChips.remove(flyingLosingChip);
          // Join the winning chips on the table
          _tableChips.add(TableChip(
            x: targetX,
            y: targetY,
            color: chip.color,
            label: chip.label,
            value: chip.value,
            spot: winningSpot,
          ));
        });
        controller.dispose();
      });
    }

    // 2. Payout Phase: Starts exactly 1 second later (when losing chips have gathered)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      // Clear all chips from the table as they begin flying to the winning players
      setState(() {
        _tableChips.clear();
      });

      // Calculate user winnings and trigger flight
      double winnings = 0.0;
      if (winner == 'Andar' && _userBetAndar > 0) {
        winnings = _userBetAndar * 1.9;
      } else if (winner == 'Bahar' && _userBetBahar > 0) {
        winnings = _userBetBahar * 1.9;
      } else if (winner == 'Tie' && _userBetTie > 0) {
        winnings = _userBetTie * 8.2;
      }

      if (winnings > 0) {
        setState(() {
          _userWinAmount = winnings;
          _userWinTrigger++;
        });
        widget.onBalanceChanged(widget.balance + winnings);
        _triggerWinningsFlight(
            spot: winningSpot,
            targetX: 0.15, // Land on user profile
            targetY: 0.95,
            value: winnings);
      }

      // Calculate mock player winnings and trigger flights
      final Map<String, double> winningBets = winner == 'Andar'
          ? _mockBetsAndar
          : (winner == 'Bahar' ? _mockBetsBahar : _mockBetsTie);
      final double payoutMultiplier = winner == 'Tie' ? 8.2 : 1.9;

      winningBets.forEach((playerKey, betValue) {
        if (betValue > 0) {
          final double playerWinnings = betValue * payoutMultiplier;

          if (playerKey == 'activeUsers') {
            _triggerWinningsFlight(
                spot: winningSpot,
                targetX: 0.85, // Land on online users badge
                targetY: 0.95,
                value: playerWinnings);
            return;
          }

          final bool isLeft = playerKey.startsWith('L');
          final int index = int.parse(playerKey.substring(1));
          
          double targetX = 0.05;
          double targetY = 0.3;
          if (isLeft) {
            targetX = 0.06;
            targetY = 0.18 + index * 0.20;
          } else {
            targetX = 0.94;
            targetY = 0.18 + index * 0.20;
          }

          _triggerWinningsFlight(
              spot: winningSpot,
              targetX: targetX,
              targetY: targetY,
              value: playerWinnings);

          // Update balances when chips arrive
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            setState(() {
              if (isLeft) {
                if (index == 0) {
                  _billionaireBalance += playerWinnings;
                  _billionaireWinAmount = playerWinnings;
                  _billionaireWinTrigger++;
                } else if (index == 1) {
                  _richieBalance += playerWinnings;
                  _richieWinAmount = playerWinnings;
                  _richieWinTrigger++;
                } else if (index == 2) {
                  _highRollerBalance += playerWinnings;
                  _highRollerWinAmount = playerWinnings;
                  _highRollerWinTrigger++;
                }
              } else {
                if (index == 0) {
                  _masterBalance += playerWinnings;
                  _masterWinAmount = playerWinnings;
                  _masterWinTrigger++;
                } else if (index == 1) {
                  _proKingBalance += playerWinnings;
                  _proKingWinAmount = playerWinnings;
                  _proKingWinTrigger++;
                } else if (index == 2) {
                  _elitePlayerBalance += playerWinnings;
                  _elitePlayerWinAmount = playerWinnings;
                  _elitePlayerWinTrigger++;
                }
              }
            });
          });
        }
      });
    });

    // Reset game and return to betting phase after all animations finish (3800 milliseconds)
    Future.delayed(const Duration(milliseconds: 3800), () {
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
      chipValue: _selectedChipValue,
    );

    widget.onBalanceChanged(widget.balance - _selectedChipValue);

    setState(() {
      _triggerUser++;
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
    required int chipValue,
    bool isStar = false,
    bool addToTable = true,
    double starSize = 18.0,
    double? fixedEndX,
    double? fixedEndY,
  }) {
    double endX = fixedEndX ?? 0.5;
    double endY = fixedEndY ?? 0.5;
    if (fixedEndX == null) {
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
        duration: const Duration(milliseconds: 600),
      ),
      value: chipValue,
      isStar: isStar,
      addToTable: addToTable,
      starSize: starSize,
    );

    setState(() => _flyingChips.add(newChip));

    newChip.controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _flyingChips.remove(newChip);
        if (addToTable) {
          _tableChips.add(TableChip(
            x: newChip.endX,
            y: newChip.endY,
            color: newChip.color,
            label: newChip.label,
            value: newChip.value,
            spot: spot,
          ));
        }
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
        value.toInt() > 0 ? value.toInt() : 50);
    final String chipLabel = ChipSelectorWidget.getChipText(
        value.toInt() > 0 ? value.toInt() : 50);

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
          value: value.toInt() > 0 ? value.toInt() : 50,
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ABbg.png'),
            fit: BoxFit.cover,
          ),
        ),
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
                top: h * 0.18,
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
                      avatarPath: 'assets/userprofile/user1.png',
                      betTrigger: _triggerBillionaire,
                      winAmount: _billionaireWinAmount,
                      winTrigger: _billionaireWinTrigger,
                    ),
                    const SizedBox(height: 12.0),
                    MockPlayerWidget(
                      name: 'Richie',
                      balance: _richieBalance,
                      isLeft: true,
                      iconData: Icons.workspace_premium,
                      color: const Color(0xFFFFB300),
                      showNameTag: false,
                      avatarPath: 'assets/userprofile/user2.png',
                      betTrigger: _triggerRichie,
                      winAmount: _richieWinAmount,
                      winTrigger: _richieWinTrigger,
                    ),
                    const SizedBox(height: 12.0),
                    MockPlayerWidget(
                      name: 'High Roller',
                      balance: _highRollerBalance,
                      isLeft: true,
                      iconData: Icons.insights,
                      color: const Color(0xFFFFA000),
                      showNameTag: false,
                      avatarPath: 'assets/userprofile/user3.png',
                      betTrigger: _triggerHighRoller,
                      winAmount: _highRollerWinAmount,
                      winTrigger: _highRollerWinTrigger,
                    ),
                  ],
                ),
              ),

              // 3. Right Mock Players
              Positioned(
                top: h * 0.18,
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
                      avatarPath: 'assets/userprofile/user4.png',
                      betTrigger: _triggerMaster,
                      winAmount: _masterWinAmount,
                      winTrigger: _masterWinTrigger,
                    ),
                    const SizedBox(height: 12.0),
                    MockPlayerWidget(
                      name: 'Pro King',
                      balance: _proKingBalance,
                      isLeft: false,
                      iconData: Icons.bolt,
                      color: const Color(0xFF26C6DA),
                      showNameTag: false,
                      avatarPath: 'assets/userprofile/user5.png',
                      betTrigger: _triggerProKing,
                      winAmount: _proKingWinAmount,
                      winTrigger: _proKingWinTrigger,
                    ),
                    const SizedBox(height: 12.0),
                    MockPlayerWidget(
                      name: 'Elite Player',
                      balance: _elitePlayerBalance,
                      isLeft: false,
                      iconData: Icons.auto_awesome,
                      color: const Color(0xFF00B0FF),
                      showNameTag: false,
                      avatarPath: 'assets/userprofile/user6.png',
                      betTrigger: _triggerElitePlayer,
                      winAmount: _elitePlayerWinAmount,
                      winTrigger: _elitePlayerWinTrigger,
                    ),
                  ],
                ),
              ),

              // 4. Bottom User (Left of Chip Selector / 10 Chip)
              Positioned(
                bottom: h * 0.03,
                left: w * 0.15,
                child: UserAvatarWidget(
                  balance: widget.balance,
                  avatarPath: widget.avatarPath,
                  nickname: widget.nickname,
                  betTrigger: _triggerUser,
                  winAmount: _userWinAmount,
                  winTrigger: _userWinTrigger,
                ),
              ),

              // 4b. Bottom Active Users Count (true bottom-right corner)
              Positioned(
                bottom: h * 0.03,
                right: w * 0.02,
                child: GestureDetector(
                  onTap: _showActiveUsersDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.0),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4.0, offset: Offset(0.0, 2.0))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Color(0xFF00E5FF),
                          size: 20.0,
                        ),
                        const SizedBox(width: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ONLINE',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 7.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              '$_activeUsersCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                          value: chip.value,
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
                      return Positioned.fill(
                        child: AnimatedBuilder(
                          animation: chip.controller,
                          builder: (context, child) {
                            final double t = chip.controller.value;
                            final double currentX =
                                chip.startX + (chip.endX - chip.startX) * t;
                            // For star trail: parabolic arc (quadratic bezier mid-point lift)
                            final double linearY =
                                chip.startY + (chip.endY - chip.startY) * t;
                            final double arcLift = chip.isStar
                                ? -0.18 * 4.0 * t * (1.0 - t) // peak lift at t=0.5
                                : 0.0;
                            final double currentY = linearY + arcLift;
                            return Stack(
                              children: [
                                Positioned(
                                  left: currentX * w - (chip.starSize / 2.0),
                                  top: currentY * h - (chip.starSize / 2.0),
                                  child: chip.isStar
                                      ? Container(
                                          width: chip.starSize,
                                          height: chip.starSize,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black38,
                                                blurRadius: 3.0,
                                                offset: Offset(0, 1.5),
                                              )
                                            ],
                                          ),
                                          child: ShaderMask(
                                            shaderCallback: (bounds) => const LinearGradient(
                                              colors: [Color(0xFFFFB74D), Color(0xFFFF3D00)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ).createShader(bounds),
                                            child: Icon(
                                              Icons.star,
                                              size: chip.starSize,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : PokerChipWidget(
                                          value: chip.value,
                                          size: 18.0,
                                          selected: true,
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 10. Custom Cartoon Capsule Timer
              if (_gamePhase == 'betting')
                Positioned(
                  left: w * 0.66,
                  top: h * 0.04,
                  child: SizedBox(
                    width: 120.0,
                    height: 36.0,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 105.0,
                          height: 30.0,
                          decoration: BoxDecoration(
                            color: const Color(0xCC263238),
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.white12, width: 1.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.only(left: 14.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '00:${_timerSeconds.toString().padLeft(2, '0')}',
                            style: GoogleFonts.robotoMono(
                              textStyle: TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w900,
                                color: _timerSeconds <= 3 
                                    ? const Color(0xFFFF3D00)
                                    : const Color(0xFFFFB300),
                                letterSpacing: 0.5,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1.5, 1.5),
                                    blurRadius: 0.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 6.0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: _timerSeconds <= 3 
                                    ? const Color(0xFFFF3D00) 
                                    : const Color(0xFFFF9100), 
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3.0,
                                  offset: Offset(0, 1.5),
                                )
                              ]
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: 2.0,
                                  left: 14.0,
                                  child: Container(
                                    width: 2.0,
                                    height: 3.5,
                                    color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2.0,
                                  left: 14.0,
                                  child: Container(
                                    width: 2.0,
                                    height: 3.5,
                                    color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                  ),
                                ),
                                Positioned(
                                  left: 2.0,
                                  top: 14.0,
                                  child: Container(
                                    width: 3.5,
                                    height: 2.0,
                                    color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                  ),
                                ),
                                Positioned(
                                  right: 2.0,
                                  top: 14.0,
                                  child: Container(
                                    width: 3.5,
                                    height: 2.0,
                                    color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                  ),
                                ),
                                Positioned(
                                  top: 9.0, // Center y is 15. Hour hand height is 6. 15 - 6 = 9.
                                  left: 14.0, // Center x is 15. Hour hand half-width is 1. 15 - 1 = 14.
                                  child: Transform.rotate(
                                    angle: -2.3 - (_timerSeconds * 0.15),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 2.0,
                                      height: 6.0,
                                      decoration: BoxDecoration(
                                        color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                        borderRadius: BorderRadius.circular(1.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 7.0, // Center y is 15. Minute hand height is 8. 15 - 8 = 7.
                                  left: 14.0, // Center x is 15. Minute hand half-width is 1. 15 - 1 = 14.
                                  child: Transform.rotate(
                                    angle: 1.1 + (_timerSeconds * 0.4),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 2.0,
                                      height: 8.0,
                                      decoration: BoxDecoration(
                                        color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                        borderRadius: BorderRadius.circular(1.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 13.0, // center (15) - half width (2) = 13.
                                  left: 13.0,
                                  child: Container(
                                    width: 4.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _timerSeconds <= 3 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 12. Center Lottie 3-sec warning animation
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

  void _showActiveUsersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Container(
            width: 280.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1224),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 15.0, spreadRadius: 2.0)
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Color(0xFF00E5FF), size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'Active Room Players',
                          style: GoogleFonts.pressStart2p(
                            textStyle: const TextStyle(color: Colors.white, fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white70, size: 18.0),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 16.0),
                const SizedBox(height: 4.0),
                Text(
                  'There are currently $_activeUsersCount active players betting at this table.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.0, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: const Column(
                    children: [
                      _ActiveUserRow(name: 'Satyamsk (You)', isMe: true),
                      _ActiveUserRow(name: 'Billionaire', isMe: false),
                      _ActiveUserRow(name: 'Richie', isMe: false),
                      _ActiveUserRow(name: 'Master', isMe: false),
                      _ActiveUserRow(name: 'ProKing', isMe: false),
                      _ActiveUserRow(name: 'Elite Player', isMe: false),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActiveUserRow extends StatelessWidget {
  final String name;
  final bool isMe;

  const _ActiveUserRow({required this.name, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            name,
            style: TextStyle(
              color: isMe ? const Color(0xFF00E676) : Colors.white70,
              fontSize: 10.0,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            isMe ? 'BETTING' : 'ONLINE',
            style: TextStyle(
              color: isMe ? const Color(0xFF00E676) : Colors.white38,
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

