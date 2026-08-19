import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders a gold-gradient styled winning text overlay (+15,000) matching the target design.
Widget _buildWinText(double amount) {
  // Format number with commas (e.g. 15000 -> 15,000)
  final String formattedAmount = amount.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );

  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Thinner '+' sign stack
      Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '+',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w400, // Thinner weight for '+'
                height: 1.0,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.0
                  ..color = const Color(0xFF4A2A00), // Dark bronze outline
              ),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF9C4), // Light gold top
                Color(0xFFFFD54F), // Gold middle
                Color(0xFFFFB300), // Warm gold bottom
                Color(0xFFD84315), // Dark amber bottom edge
              ],
              stops: [0.0, 0.4, 0.8, 1.0],
            ).createShader(bounds),
            child: Text(
              '+',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(width: 0.5),
      // Bold numbers stack
      Stack(
        alignment: Alignment.center,
        children: [
          Text(
            formattedAmount,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700, // Bold weight for numbers
                height: 1.0,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.4
                  ..color = const Color(0xFF4A2A00),
              ),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF9C4),
                Color(0xFFFFD54F),
                Color(0xFFFFB300),
                Color(0xFFD84315),
              ],
              stops: [0.0, 0.4, 0.8, 1.0],
            ).createShader(bounds),
            child: Text(
              formattedAmount,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Displays mock player avatar, name tag, and balance with a nudge animation when betting.
class MockPlayerWidget extends StatefulWidget {
  final String name;
  final double balance;
  final bool isLeft;
  final IconData iconData;
  final Color color;
  final bool showNameTag;
  final String? avatarPath;
  final int betTrigger;
  final double winAmount;
  final int winTrigger;

  const MockPlayerWidget({
    super.key,
    required this.name,
    required this.balance,
    required this.isLeft,
    required this.iconData,
    required this.color,
    required this.showNameTag,
    this.avatarPath,
    this.betTrigger = 0,
    this.winAmount = 0.0,
    this.winTrigger = 0,
  });

  @override
  State<MockPlayerWidget> createState() => _MockPlayerWidgetState();
}

class _MockPlayerWidgetState extends State<MockPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  late AnimationController _winController;
  late Animation<double> _winOpacity;
  double _lastDisplayedWinAmount = 0.0;
  bool _showWinText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _anim = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _winOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_winController);
  }

  @override
  void didUpdateWidget(covariant MockPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.betTrigger != oldWidget.betTrigger && widget.betTrigger > 0) {
      _controller.forward().then((_) => _controller.reverse());
    }
    if (widget.winTrigger != oldWidget.winTrigger && widget.winTrigger > 0) {
      setState(() {
        _lastDisplayedWinAmount = widget.winAmount;
        _showWinText = true;
      });
      _winController.reset();
      _winController.forward().then((_) {
        if (mounted) {
          setState(() {
            _showWinText = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _winController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map mock name to title, username, gradient, and showTitle status
    String statusTitle = "";
    String username = "";
    List<Color> titleGradient = [Colors.white, Colors.grey];
    bool showTitle = false;
    bool hasCrown = false;

    if (widget.name == 'Billionaire') {
      statusTitle = "Millionaire";
      username = "name304250";
      titleGradient = [const Color(0xFF8C9EFF), const Color(0xFFE040FB)];
      showTitle = true;
    } else if (widget.name == 'Richie') {
      statusTitle = "Richie Rich";
      username = "kFOJx";
      titleGradient = [const Color(0xFFFF4081), const Color(0xFFE040FB)];
      showTitle = true;
      hasCrown = true;
    } else if (widget.name == 'High Roller') {
      statusTitle = "High Roller";
      username = "name136668";
      showTitle = false;
    } else if (widget.name == 'Master') {
      statusTitle = "Grand Master";
      username = "proMaster99";
      titleGradient = [const Color(0xFF00E5FF), const Color(0xFF00B0FF)];
      showTitle = true;
    } else if (widget.name == 'Pro King') {
      statusTitle = "Pro King";
      username = "kingSlot88";
      titleGradient = [const Color(0xFF00E676), const Color(0xFF00B0FF)];
      showTitle = true;
    } else if (widget.name == 'Elite Player') {
      statusTitle = "Elite Pro";
      username = "eliteGamer";
      showTitle = false;
    } else {
      statusTitle = widget.name;
      username = widget.name.toLowerCase();
      showTitle = widget.showNameTag;
    }

    Widget titleWidget = const SizedBox(height: 2.0);
    if (showTitle) {
      titleWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star decorations
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('★', style: TextStyle(color: Color(0xFFE040FB), fontSize: 5.0, height: 1.0)),
              const SizedBox(width: 1.5),
              Text(hasCrown ? '👑' : '★', style: const TextStyle(fontSize: 5.5, height: 1.0)),
              const SizedBox(width: 1.5),
              const Text('★', style: TextStyle(color: Color(0xFFE040FB), fontSize: 5.0, height: 1.0)),
            ],
          ),
          const SizedBox(height: 0.5),
          // Shiny gradient font
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: titleGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              statusTitle,
              style: GoogleFonts.baloo2(
                textStyle: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1.5),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final double offset = widget.isLeft ? _anim.value : -_anim.value;
        return Transform.translate(
          offset: Offset(offset, 0.0),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,

          // Rounded rectangle portrait with golden border
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 37.0,
                height: 37.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.0),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 3.0,
                      offset: Offset(0, 1.5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7.0),
                  child: Container(
                    color: const Color(0xFF1E2240),
                    alignment: Alignment.center,
                    child: widget.avatarPath != null
                        ? Image.asset(
                            widget.avatarPath!,
                            fit: BoxFit.cover,
                            width: 37.0,
                            height: 37.0,
                          )
                        : Icon(
                            widget.isLeft ? Icons.person : Icons.person_3,
                            color: Colors.white70,
                            size: 22.0,
                          ),
                  ),
                ),
              ),
              
              // Win text overlay centered directly on the avatar face (no zoom animation)
              if (_showWinText)
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _winController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _winOpacity.value,
                          child: _buildWinText(_lastDisplayedWinAmount),
                        );
                      },
                    ),
                  ),
                ),
              if (widget.name == 'Master')
                Positioned(
                  top: -8.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 2.0,
                            offset: Offset(0, 1.0),
                          )
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
                          size: 13.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 2.0),

          // Username Tag Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: const Color(0xCC171B21),
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 1.0),

          // Balance Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: const Color(0xCC171B21),
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              widget.balance.toStringAsFixed(0),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 7.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the real user (bottom-left) avatar and balance with a nudge animation when betting.
class UserAvatarWidget extends StatefulWidget {
  final double balance;
  final String? avatarPath;
  final String? nickname;
  final int betTrigger;
  final double winAmount;
  final int winTrigger;

  const UserAvatarWidget({
    super.key,
    required this.balance,
    this.avatarPath,
    this.nickname,
    this.betTrigger = 0,
    this.winAmount = 0.0,
    this.winTrigger = 0,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  late AnimationController _winController;
  late Animation<double> _winOpacity;
  double _lastDisplayedWinAmount = 0.0;
  bool _showWinText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _anim = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _winOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_winController);
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.betTrigger != oldWidget.betTrigger && widget.betTrigger > 0) {
      _controller.forward().then((_) => _controller.reverse());
    }
    if (widget.winTrigger != oldWidget.winTrigger && widget.winTrigger > 0) {
      setState(() {
        _lastDisplayedWinAmount = widget.winAmount;
        _showWinText = true;
      });
      _winController.reset();
      _winController.forward().then((_) {
        if (mounted) {
          setState(() {
            _showWinText = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _winController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_anim.value, -_anim.value * 0.5),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User Avatar with gold border and win overlay
          Stack(
            children: [
              Container(
                width: 37.0,
                height: 37.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.0),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 3.0,
                      offset: Offset(0, 1.5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7.0),
                  child: Container(
                    color: const Color(0xFF1E2240),
                    alignment: Alignment.center,
                    child: widget.avatarPath != null
                        ? Image.asset(
                            widget.avatarPath!,
                            fit: BoxFit.cover,
                            width: 37.0,
                            height: 37.0,
                          )
                        : const Icon(
                            Icons.face,
                            color: Colors.white70,
                            size: 22.0,
                          ),
                  ),
                ),
              ),
              if (_showWinText)
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _winController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _winOpacity.value,
                          child: _buildWinText(_lastDisplayedWinAmount),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 5.0),
          
          // User Name & Balance boxes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xCC171B21),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  widget.nickname ?? 'Satyamsk',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xCC171B21),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  widget.balance.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 7.7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
