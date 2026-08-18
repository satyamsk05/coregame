import 'package:flutter/material.dart';

/// Displays mock player avatar, name tag, and balance.
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
  late Animation<double> _winOffset;
  late Animation<double> _winOpacity;
  late Animation<double> _winScale;
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
      duration: const Duration(milliseconds: 1600),
    );
    _winOffset = Tween<double>(begin: 0.0, end: -70.0).animate(
      CurvedAnimation(
        parent: _winController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _winOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_winController);

    _winScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
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
              if (widget.showNameTag) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLeft)
                      Icon(widget.iconData, color: widget.color, size: 10.0)
                    else
                      const SizedBox(),
                    const SizedBox(width: 4.0),
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    if (!widget.isLeft)
                      Icon(widget.iconData, color: widget.color, size: 10.0)
                    else
                      const SizedBox(),
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
                  border: Border.all(color: widget.color, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3.0)
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: const Color(0xFF1E2240),
                    alignment: Alignment.center,
                    child: widget.avatarPath != null
                        ? Image.asset(
                            widget.avatarPath!,
                            fit: BoxFit.cover,
                            width: 36.0,
                            height: 36.0,
                          )
                        : Icon(
                            widget.isLeft ? Icons.person : Icons.person_3,
                            color: Colors.white70,
                            size: 20.0,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 2.0),

              // Balance Box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Color(0xFFFFD700), size: 9.0),
                    const SizedBox(width: 2.0),
                    Text(
                      widget.balance.toStringAsFixed(0),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showWinText)
          Positioned(
            top: -25.0,
            left: widget.isLeft ? 45.0 : -95.0,
            child: AnimatedBuilder(
              animation: _winController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0.0, _winOffset.value),
                  child: Transform.scale(
                    scale: _winScale.value,
                    child: Opacity(
                      opacity: _winOpacity.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 6.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: Text(
                  '+${_lastDisplayedWinAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Displays the real user (bottom-left) avatar and balance with a nudge animation when betting.
class UserAvatarWidget extends StatefulWidget {
  final double balance;
  final String? avatarPath;
  final int betTrigger;
  final double winAmount;
  final int winTrigger;

  const UserAvatarWidget({
    super.key,
    required this.balance,
    this.avatarPath,
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
  late Animation<double> _winOffset;
  late Animation<double> _winOpacity;
  late Animation<double> _winScale;
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
      duration: const Duration(milliseconds: 1600),
    );
    _winOffset = Tween<double>(begin: 0.0, end: -70.0).animate(
      CurvedAnimation(
        parent: _winController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _winOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_winController);

    _winScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
    ]).animate(_winController);
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.betTrigger != oldWidget.betTrigger && widget.betTrigger > 0) {
      _controller.forward().then((_) => _controller.reverse());
    }
    if (widget.winTrigger != oldWidget.winTrigger && widget.winTrigger > 0) {
      debugPrint('Andar Bahar User Win Animation triggered. Amount: ${widget.winAmount}, Trigger: ${widget.winTrigger}');
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            // Nudge right and slightly up
            return Transform.translate(
              offset: Offset(_anim.value, -_anim.value * 0.5),
              child: child,
            );
          },
          child: Row(
            children: [
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                ),
                child: ClipOval(
                  child: Container(
                    color: const Color(0xFF1E2240),
                    alignment: Alignment.center,
                    child: widget.avatarPath != null
                        ? Image.asset(
                            widget.avatarPath!,
                            fit: BoxFit.cover,
                            width: 36.0,
                            height: 36.0,
                          )
                        : const Icon(Icons.face,
                            color: Colors.white70, size: 22.0),
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
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2.0),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0x4D000000),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Color(0xFFFFD700), size: 10.0),
                        const SizedBox(width: 2.0),
                        Text(
                          widget.balance.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_showWinText)
          Positioned(
            top: -25.0,
            left: 0,
            child: AnimatedBuilder(
              animation: _winController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(10.0, _winOffset.value),
                  child: Transform.scale(
                    scale: _winScale.value,
                    child: Opacity(
                      opacity: _winOpacity.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.white, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Text(
                  '+${_lastDisplayedWinAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF3E2723),
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 2.0,
                        offset: Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

      ],
    );
  }
}


