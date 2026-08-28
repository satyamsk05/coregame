import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/bounceable.dart';
import '../../shared/widgets/win_overlay_card.dart';
import '../../shared/widgets/win_lose_toast.dart';
import '../../utils/sound_manager.dart';
import '../andar_bahar/widgets/player_widgets.dart';
import '../andar_bahar/widgets/chip_widgets.dart';

class DoubleSlot {
  final int number;
  final String color; // 'red', 'green', 'black'
  DoubleSlot({required this.number, required this.color});
}

class DoubleGameScreen extends StatefulWidget {
  final double balance;
  final bool soundOn;
  final bool musicOn;
  final String nickname;
  final String avatarPath;
  final ValueChanged<double> onBalanceChanged;
  final VoidCallback onBackPressed;

  const DoubleGameScreen({
    super.key,
    required this.balance,
    required this.soundOn,
    required this.musicOn,
    required this.nickname,
    required this.avatarPath,
    required this.onBalanceChanged,
    required this.onBackPressed,
  });

  @override
  State<DoubleGameScreen> createState() => _DoubleGameScreenState();
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 5.0;
    path.moveTo(w * 0.5, r);
    path.lineTo(w - r, h * 0.25 - r * 0.5);
    path.quadraticBezierTo(w, h * 0.25, w, h * 0.25 + r);
    path.lineTo(w, h * 0.75 - r);
    path.quadraticBezierTo(w, h * 0.75, w - r, h * 0.75 + r * 0.5);
    path.lineTo(w * 0.5 + r, h - r * 0.5);
    path.quadraticBezierTo(w * 0.5, h, w * 0.5 - r, h - r * 0.5);
    path.lineTo(r, h * 0.75 + r * 0.5);
    path.quadraticBezierTo(0, h * 0.75, 0, h * 0.75 - r);
    path.lineTo(0, h * 0.25 + r);
    path.quadraticBezierTo(0, h * 0.25, r, h * 0.25 - r * 0.5);
    path.lineTo(w * 0.5 - r, r * 0.5);
    path.quadraticBezierTo(w * 0.5, 0, w * 0.5 + r, r * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DoubleGameScreenState extends State<DoubleGameScreen> {
  final List<DoubleSlot> _slots = [
    DoubleSlot(number: 0, color: 'green'),
    DoubleSlot(number: 11, color: 'black'),
    DoubleSlot(number: 5, color: 'red'),
    DoubleSlot(number: 10, color: 'black'),
    DoubleSlot(number: 6, color: 'red'),
    DoubleSlot(number: 9, color: 'black'),
    DoubleSlot(number: 7, color: 'red'),
    DoubleSlot(number: 8, color: 'black'),
    DoubleSlot(number: 1, color: 'red'),
    DoubleSlot(number: 14, color: 'black'),
    DoubleSlot(number: 2, color: 'red'),
    DoubleSlot(number: 13, color: 'black'),
    DoubleSlot(number: 3, color: 'red'),
    DoubleSlot(number: 12, color: 'black'),
    DoubleSlot(number: 4, color: 'red'),
  ];

  late final ScrollController _scrollController;

  // Game loop variables
  String _gamePhase = 'betting'; // 'betting' -> 'spinning' -> 'result'
  double _timerSeconds = 15.0;
  Timer? _gameTimer;
  Timer? _countdownTimer;

  // Betting states
  String? _placedBetColor;
  double _placedBetAmount = 0.0;
  int _selectedChipValue = 10;

  // Spin result
  DoubleSlot? _winningSlot;
  final List<DoubleSlot> _previousRolls = [];

  // Flying chips and triggers for UserAvatarWidget
  int _triggerUserBet = 0;
  int _triggerUserWin = 0;
  double _winAmount = 0.0;

  // Animation layout sizes
  final double _itemWidth = 76.0;
  final double _itemMargin = 8.0;

  // Mock player data for sidebars
  final List<Map<String, dynamic>> _leftPlayers = [
    {'name': 'Billionaire', 'balance': 83450.0, 'avatar': 'assets/userprofile/user1.png'},
    {'name': 'Richie', 'balance': 24450.0, 'avatar': 'assets/userprofile/user2.png'},
    {'name': 'High Roller', 'balance': 9730.0, 'avatar': 'assets/userprofile/user3.png'},
  ];
  final List<Map<String, dynamic>> _rightPlayers = [
    {'name': 'Master', 'balance': 5350.0, 'avatar': 'assets/userprofile/user4.png'},
    {'name': 'Pro King', 'balance': 12790.0, 'avatar': 'assets/userprofile/user5.png'},
    {'name': 'Elite Player', 'balance': 7500.0, 'avatar': 'assets/userprofile/user6.png'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final rand = math.Random();
    for (int i = 0; i < 8; i++) {
      _previousRolls.add(_slots[rand.nextInt(_slots.length)]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _resetScrollToCenter();
          _startBettingPhase();
        }
      });
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double get _itemTotalWidth => _itemWidth + _itemMargin;

  void _resetScrollToCenter() {
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      final double startOffset = (3 * 15 * _itemTotalWidth) + (_itemTotalWidth / 2) - (viewportWidth / 2);
      _scrollController.jumpTo(startOffset);
    } else {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _scrollController.hasClients) {
          final double viewportWidth = _scrollController.position.viewportDimension;
          final double startOffset = (3 * 15 * _itemTotalWidth) + (_itemTotalWidth / 2) - (viewportWidth / 2);
          _scrollController.jumpTo(startOffset);
        }
      });
    }
  }

  void _startBettingPhase() {
    setState(() {
      _gamePhase = 'betting';
      _timerSeconds = 15.0;
      _placedBetColor = null;
      _placedBetAmount = 0.0;
    });
    _resetScrollToCenter();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0.1) {
            _timerSeconds -= 0.1;
          } else {
            _timerSeconds = 0.0;
            _countdownTimer?.cancel();
            _startSpinningPhase();
          }
        });
      }
    });
  }

  void _startSpinningPhase() {
    setState(() => _gamePhase = 'spinning');
    final rand = math.Random();
    final winNumIndex = rand.nextInt(_slots.length);
    _winningSlot = _slots[winNumIndex];
    final int targetPeriod = 12;
    final int targetIndex = targetPeriod * _slots.length + winNumIndex;
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      final double randomOffset = (rand.nextDouble() * 40.0) - 20.0;
      final double targetOffset = (targetIndex * _itemTotalWidth) + (_itemTotalWidth / 2) - (viewportWidth / 2) + randomOffset;
      SoundManager.playClick();
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 3800),
        curve: const Cubic(0.12, 0.8, 0.15, 1.0),
      ).then((_) {
        if (mounted) _showResultPhase();
      });
    } else {
      _showResultPhase();
    }
  }

  void _showResultPhase() {
    setState(() {
      _gamePhase = 'result';
      if (_winningSlot != null) {
        _previousRolls.insert(0, _winningSlot!);
        if (_previousRolls.length > 12) _previousRolls.removeLast();
      }
    });
    if (_placedBetColor != null && _winningSlot != null) {
      final String winningColor = _winningSlot!.color;
      final bool isWin = (_placedBetColor == winningColor);
      if (isWin) {
        final double multiplier = (winningColor == 'green') ? 14.0 : 2.0;
        final double winValue = _placedBetAmount * multiplier;
        widget.onBalanceChanged(widget.balance + winValue);
        setState(() {
          _winAmount = winValue;
          _triggerUserWin++;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showWinLoseToast(context, isWin: true, title: 'YOU WON!', message: 'Won ₹${winValue.toStringAsFixed(2)}');
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => Center(child: WinOverlayCard(multiplier: multiplier, winAmount: winValue, isWin: true)),
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showWinLoseToast(context, isWin: false, title: 'YOU LOST!', message: 'Lost ₹${_placedBetAmount.toStringAsFixed(2)}');
        });
      }
    }
    _gameTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) _startBettingPhase();
    });
  }

  void _placeBet(String color) {
    if (_gamePhase != 'betting' || _placedBetAmount > 0) return;
    final double betVal = _selectedChipValue.toDouble();
    if (betVal <= 0.0) return;
    if (widget.balance < betVal) {
      _showErrorDialog('Insufficient Balance', 'You do not have enough balance to place this bet.');
      return;
    }
    SoundManager.playClick();
    widget.onBalanceChanged(widget.balance - betVal);
    setState(() {
      _placedBetAmount = betVal;
      _placedBetColor = color;
      _triggerUserBet++;
    });
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        title: Text(title, style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold))),
        content: Text(content, style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFF24EE89), fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showGameDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
          child: Container(
            width: 320.0,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF23272C), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline, color: Color(0xFF24EE89), size: 18.0),
                      const SizedBox(width: 8.0),
                      Text('Double Rules', style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.bold))),
                      const Spacer(),
                      GestureDetector(onTap: () { SoundManager.playClick(); Navigator.of(context).pop(); }, child: const Icon(Icons.close, color: Colors.grey, size: 18.0)),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    '1. Select a chip denomination from the bottom bar.\n\n'
                    '2. Tap a multiplier button to bet:\n   • 2X Red — pays 2x\n   • 14X Green — pays 14x\n   • 2X Black — pays 2x\n\n'
                    '3. The carousel spins and decelerates onto a winning slot.\n\n'
                    '4. Correct color predictions receive the multiplier payout!',
                    style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.3)),
                  ),
                  const SizedBox(height: 16.0),
                  GestureDetector(
                    onTap: () { SoundManager.playClick(); Navigator.of(context).pop(); },
                    child: Container(
                      height: 36.0,
                      decoration: BoxDecoration(color: const Color(0xFF24EE89), borderRadius: BorderRadius.circular(8.0)),
                      alignment: Alignment.center,
                      child: const Text('Got it', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sidebar Player with DP Banner ──
  Widget _buildSidebarPlayer(Map<String, dynamic> p, String bannerPath) {
    final String name = p['name'] as String;
    final double balance = p['balance'] as double;
    final String avatar = p['avatar'] as String;

    String username = name.toLowerCase();
    if (name == 'Billionaire') username = "name304250";
    else if (name == 'Richie') username = "kFOJx";
    else if (name == 'High Roller') username = "name136668";
    else if (name == 'Master') username = "proMaster99";
    else if (name == 'Pro King') username = "kingSlot88";
    else if (name == 'Elite Player') username = "eliteGamer";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Banner Stack
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 35.3,
                height: 35.3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 2.0, offset: Offset(0, 1)),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(avatar, fit: BoxFit.cover),
                ),
              ),
              Image.asset(
                bannerPath,
                width: 48.5,
                height: 48.5,
                fit: BoxFit.contain,
              ),
              if (name == 'Master')
                Positioned(
                  top: -6.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 2.0, offset: Offset(0, 1.0))
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF3D00)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.star,
                        size: 12.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2.0),
          // Nickname below the banner
          Text(
            username,
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 7.9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 1.0),
          // Balance below the nickname
          Text(
            '₹${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 7.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Widget ──
  Widget _buildSidebar(List<Map<String, dynamic>> players, bool isLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0x3323272C), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: players.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;

          // Map to correct banner image
          String bannerPath = 'assets/dpbanner/IMG_20260821_135148.png';
          if (isLeft) {
            if (idx == 0) bannerPath = 'assets/dpbanner/IMG_20260821_135148.png';
            else if (idx == 1) bannerPath = 'assets/dpbanner/IMG_20260821_135204.png';
            else if (idx == 2) bannerPath = 'assets/dpbanner/IMG_20260821_135223.png';
          } else {
            if (idx == 0) bannerPath = 'assets/dpbanner/IMG_20260821_135255.png';
            else if (idx == 1) bannerPath = 'assets/dpbanner/IMG_20260821_135316.png';
            else if (idx == 2) bannerPath = 'assets/dpbanner/IMG_20260821_135338.png';
          }

          return _buildSidebarPlayer(p, bannerPath);
        }).toList(),
      ),
    );
  }

  // ── Previous Rolls Bar ──
  Widget _buildPreviousRolls() {
    return SizedBox(
      height: 30.0,
      child: Row(
        children: [
          Text('Previous Rolls', style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white54, fontSize: 9.0, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8.0),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: _previousRolls.length,
              itemBuilder: (context, idx) {
                final roll = _previousRolls[idx];
                Color cardBgColor = const Color(0xFF2B2D36);
                Color hexColor = const Color(0xFF16181C);
                bool isGreen = roll.color == 'green';
                if (roll.color == 'red') { cardBgColor = const Color(0xFFFE4541); hexColor = const Color(0xFF9E1F1D); }
                else if (roll.color == 'green') { cardBgColor = const Color(0xFF24EE89); }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  width: 26.0, height: 26.0,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(color: Colors.white12, width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: isGreen
                      ? Image.asset('assets/Double/Image (diamond).png', width: 14.0, height: 14.0, fit: BoxFit.contain)
                      : Stack(alignment: Alignment.center, children: [
                          CustomPaint(size: const Size(18.0, 18.0), painter: HexagonPainter(color: hexColor)),
                          Text('${roll.number}', style: const TextStyle(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.w900)),
                        ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Carousel Slider ──
  Widget _buildCarousel() {
    return SizedBox(
      height: 95.0,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: _slots.length * 30,
                  itemBuilder: (context, index) {
                    final slot = _slots[index % _slots.length];
                    final isGreen = slot.color == 'green';
                    Color cardBg = const Color(0xFF2B2D36);
                    Color hexColor = const Color(0xFF16181C);
                    if (slot.color == 'red') { cardBg = const Color(0xFFFE4541); hexColor = const Color(0xFF9E1F1D); }
                    else if (slot.color == 'green') { cardBg = const Color(0xFF24EE89); }
                    return Container(
                      width: _itemWidth,
                      margin: EdgeInsets.symmetric(horizontal: _itemMargin / 2, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.white10),
                      ),
                      alignment: Alignment.center,
                      child: isGreen
                          ? Container(
                              width: 48.0, height: 48.0, alignment: Alignment.center,
                              child: Image.asset('assets/Double/Image (diamond).png', width: 38.0, height: 38.0, fit: BoxFit.contain),
                            )
                          : Container(
                              width: 48.0, height: 48.0, alignment: Alignment.center,
                              child: ClipPath(
                                clipper: HexagonClipper(),
                                child: Container(
                                  color: hexColor, alignment: Alignment.center,
                                  child: Text('${slot.number}', style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w900))),
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Center indicator line
          Align(
            alignment: Alignment.center,
            child: Container(width: 3.0, height: double.infinity, color: Colors.white),
          ),
          // Left fade gradient (spin depth effect)
          Positioned(
            left: 0, top: 0, bottom: 0, width: 60.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right fade gradient (spin depth effect)
          Positioned(
            right: 0, top: 0, bottom: 0, width: 60.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Multiplier Buttons Row ──
  Widget _buildMultiplierButtons() {
    final bool canBet = _gamePhase == 'betting' && _placedBetAmount == 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double buttonsWidth = constraints.maxWidth * 0.78;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: buttonsWidth,
            child: Row(
              children: [
                _multiplierButton('2X', const Color(0xFFE53935), Colors.white, 'red', canBet),
                const SizedBox(width: 4.0),
                _multiplierButton('14X', const Color(0xFF24EE89), Colors.black, 'green', canBet),
                const SizedBox(width: 4.0),
                _multiplierButton('2X', const Color(0xFF3A3D44), Colors.white70, 'black', canBet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _multiplierButton(String label, Color bgColor, Color textColor, String color, bool enabled) {
    final bool isSelected = _placedBetColor == color;
    return Expanded(
      child: Bounceable(
        onTap: enabled ? () => _placeBet(color) : null,
        child: Opacity(
          opacity: enabled ? 0.9 : 0.55,
          child: Container(
            height: 88.0,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10.0),
              border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
              boxShadow: [
                BoxShadow(color: bgColor.withValues(alpha: 0.35), blurRadius: 6.0, offset: const Offset(0, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: textColor, fontSize: 16.0, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  // ── Bottom Bar: Player Info + Chip Selector ──
  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile section (left side, game-style like Andar Bahar)
        _buildGameProfile(),
        const SizedBox(width: 8.0),
        // Chips container (no background)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [10, 50, 100, 500, 1000].expand((val) {
              final isSelected = _selectedChipValue == val;
              return [
                GestureDetector(
                  onTap: (_gamePhase == 'betting' && _placedBetAmount == 0)
                      ? () { SoundManager.playClick(); setState(() => _selectedChipValue = val); }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.translationValues(0.0, isSelected ? -6.0 : 0.0, 0.0),
                    child: Transform.scale(
                      scale: isSelected ? 1.12 : 1.0,
                      child: PokerChipWidget(value: val, selected: isSelected, size: 33.0),
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
              ];
            }).toList()..removeLast(),
          ),
        ),
      ],
    );
  }

  // ── Game-Style Profile (Andar Bahar style with DP Banner) ──
  Widget _buildGameProfile() {
    final String userBanner = 'assets/dpbanner/IMG_20260821_135148.png';
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar + Banner Stack
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Inner Avatar
            Container(
              width: 35.7,
              height: 35.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 2.0, offset: Offset(0, 1)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(widget.avatarPath, fit: BoxFit.cover),
              ),
            ),
            // Outer DP Banner Frame
            Image.asset(
              userBanner,
              width: 50.4,
              height: 50.4,
              fit: BoxFit.contain,
            ),
            // Online indicator dot
            Positioned(
              right: 2.0, top: 2.0,
              child: Container(
                width: 8.0, height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676),
                  border: Border.all(color: Colors.black, width: 1.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6.0),
        // Nickname + Balance to the right side
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.nickname,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2.0),
            // Balance tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: const Color(0x4D000000),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '₹${widget.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen game design background
          Image.asset('assets/Double/doublebg.png', fit: BoxFit.cover),
          // Dark overlay for readability
          Container(color: Colors.black.withValues(alpha: 0.25)),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final double sidebarW = (w * 0.1365).clamp(92.4, 120.75);

                return Stack(
                  children: [
                    // Back button (top-left)
                    Positioned(
                      top: 6.0, left: 8.0,
                      child: GestureDetector(
                        onTap: _gamePhase == 'spinning' ? null : widget.onBackPressed,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0x66000000),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16.0),
                        ),
                      ),
                    ),
                    // Help button (top-right)
                    Positioned(
                      top: 6.0, right: 8.0,
                      child: GestureDetector(
                        onTap: () { SoundManager.playClick(); _showGameDetailsDialog(); },
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0x66000000),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.help_outline, color: Colors.white, size: 16.0),
                        ),
                      ),
                    ),

                    // Left sidebar
                    Positioned(
                      left: 6.0, top: 42.0, bottom: 6.0, width: sidebarW,
                      child: _buildSidebar(_leftPlayers, true),
                    ),
                    // Right sidebar
                    Positioned(
                      right: 6.0, top: 42.0, bottom: 6.0, width: sidebarW,
                      child: _buildSidebar(_rightPlayers, false),
                    ),

                    // Center content
                    Positioned(
                      left: sidebarW + 4.0,
                      right: sidebarW + 4.0,
                      top: 38.0,
                      bottom: 4.0,
                      child: Column(
                        children: [
                          _buildPreviousRolls(),
                          const SizedBox(height: 4.0),
                          // Countdown
                          Center(
                            child: Text(
                              _gamePhase == 'betting'
                                  ? 'Rolling In ${_timerSeconds.toStringAsFixed(1)}s'
                                  : (_gamePhase == 'spinning' ? 'Rolling...' : (_winningSlot != null ? '${_winningSlot!.color.toUpperCase()} ${_winningSlot!.number} Won!' : '')),
                              style: GoogleFonts.roboto(textStyle: TextStyle(
                                color: _gamePhase == 'result' && _winningSlot?.color == 'green' ? const Color(0xFF24EE89) : Colors.white,
                                fontSize: 16.0, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                              )),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          _buildCarousel(),
                          const SizedBox(height: 8.0),
                          _buildMultiplierButtons(),
                          const Spacer(),
                          _buildBottomBar(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 3.0;
    final points = [
      Offset(w * 0.5, 0.0), Offset(w, h * 0.25), Offset(w, h * 0.75),
      Offset(w * 0.5, h), Offset(0.0, h * 0.75), Offset(0.0, h * 0.25),
    ];
    for (int i = 0; i < 6; i++) {
      final pCurr = points[i];
      final pPrev = points[(i - 1 + 6) % 6];
      final pNext = points[(i + 1) % 6];
      final vPrev = pPrev - pCurr;
      final dPrev = vPrev.distance;
      final uPrev = vPrev / dPrev;
      final vNext = pNext - pCurr;
      final dNext = vNext.distance;
      final uNext = vNext / dNext;
      final pStart = pCurr + uPrev * math.min(r, dPrev * 0.5);
      final pEnd = pCurr + uNext * math.min(r, dNext * 0.5);
      if (i == 0) { path.moveTo(pStart.dx, pStart.dy); }
      else { path.lineTo(pStart.dx, pStart.dy); }
      path.quadraticBezierTo(pCurr.dx, pCurr.dy, pEnd.dx, pEnd.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
