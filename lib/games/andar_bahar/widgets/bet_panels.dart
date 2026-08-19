import 'package:flutter/material.dart';

/// Andar / Bahar side bet panel with win blink animation support.
class SideBetPanel extends StatefulWidget {
  final String label;       // 'Andar' or 'Bahar'
  final double totalBet;
  final double userBet;
  final Color baseColor;
  final bool isLeft;
  final bool isWinner;
  final Animation<double> blinkAnimation;
  final bool hasMasterBet;

  const SideBetPanel({
    super.key,
    required this.label,
    required this.totalBet,
    required this.userBet,
    required this.baseColor,
    required this.isLeft,
    required this.isWinner,
    required this.blinkAnimation,
    this.hasMasterBet = false,
  });

  @override
  State<SideBetPanel> createState() => _SideBetPanelState();
}

class _SideBetPanelState extends State<SideBetPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  BoxDecoration _getPanelDecoration(bool winner) {
    final Color startColor = Color.lerp(Colors.black, widget.baseColor, 0.45)!;
    final Color endColor = Color.lerp(Colors.black, widget.baseColor, 0.22)!;

    if (winner) {
      final double val = widget.blinkAnimation.value;
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(startColor, const Color(0xFFB8860B), val)!,
            Color.lerp(endColor, const Color(0xFF5C4033), val)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Color.lerp(widget.baseColor, const Color(0xFFFFD700), val)!,
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
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(color: widget.baseColor, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        Positioned(
          top: 2.0,
          left: 2.0,
          child: Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: Color(0xFFFFD700), size: 10.0),
              const SizedBox(width: 2.0),
              Text(
                '${widget.totalBet.toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        Positioned(
          left: widget.isLeft ? 8.0 : null,
          right: !widget.isLeft ? 8.0 : null,
          top: 26.0,
          child: const Text(
            '1.9',
            style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 10.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            widget.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        if (widget.userBet > 0)
          Positioned(
            bottom: 4.0,
            left: !widget.isLeft ? 8.0 : null,
            right: widget.isLeft ? 8.0 : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'Mine: ${widget.userBet.toInt()}',
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Static dim star (always visible)
        Positioned(
          bottom: 4.0,
          left: widget.isLeft ? 8.0 : null,
          right: !widget.isLeft ? 8.0 : null,
          child: widget.hasMasterBet
              ? AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6F00)
                                .withValues(alpha: _glowAnim.value * 0.85),
                            blurRadius: 10.0 * _glowAnim.value,
                            spreadRadius: 3.0 * _glowAnim.value,
                          ),
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Color.lerp(const Color(0xFFFFB74D),
                                const Color(0xFFFF3D00), _glowAnim.value)!,
                            const Color(0xFFFF3D00),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Icon(
                          Icons.star,
                          size: 14.0 + 2.0 * _glowAnim.value,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                )
              : Icon(Icons.star_border,
                  color: Colors.yellow.withValues(alpha: 0.4), size: 14.0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isWinner) {
      return AnimatedBuilder(
        animation: widget.blinkAnimation,
        builder: (context, child) {
          return Container(
            decoration: _getPanelDecoration(true),
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: child,
          );
        },
        child: _buildContent(),
      );
    }
    return Container(
      decoration: _getPanelDecoration(false),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: _buildContent(),
    );
  }
}

/// Tie bet panel with win blink animation support.
class TieBetPanel extends StatefulWidget {
  final double totalBetTie;
  final double userBetTie;
  final bool isBetting;
  final bool isWinner;
  final Animation<double> blinkAnimation;
  final double height;
  final bool hasMasterBet;

  const TieBetPanel({
    super.key,
    required this.totalBetTie,
    required this.userBetTie,
    required this.isBetting,
    required this.isWinner,
    required this.blinkAnimation,
    required this.height,
    this.hasMasterBet = false,
  });

  @override
  State<TieBetPanel> createState() => _TieBetPanelState();
}

class _TieBetPanelState extends State<TieBetPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  BoxDecoration _getDecoration(bool winner) {
    const Color tieBaseColor = Color(0xFF2E7D32);
    if (winner) {
      final double val = widget.blinkAnimation.value;
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(const Color(0xFF0F3B20),
                const Color(0xFFFFD700).withValues(alpha: 0.5), val)!,
            Color.lerp(const Color(0xFF135A30),
                const Color(0xFFFFD700).withValues(alpha: 0.2), val)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color:
              Color.lerp(tieBaseColor, const Color(0xFFFFD700), val)!,
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

  Widget _buildContent() {
    return Stack(
      children: [
        Positioned(
          top: 2.0,
          left: 2.0,
          child: Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: Color(0xFFFFD700), size: 10.0),
              const SizedBox(width: 2.0),
              Text(
                '${widget.totalBetTie.toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Glowing star (top-right corner of Tie panel) — always present, glows when Master bet
        Positioned(
          top: 2.0,
          right: 4.0,
          child: widget.hasMasterBet
              ? AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6F00)
                                .withValues(alpha: _glowAnim.value * 0.85),
                            blurRadius: 10.0 * _glowAnim.value,
                            spreadRadius: 3.0 * _glowAnim.value,
                          ),
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Color.lerp(const Color(0xFFFFB74D),
                                const Color(0xFFFF3D00), _glowAnim.value)!,
                            const Color(0xFFFF3D00),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Icon(
                          Icons.star,
                          size: 13.0 + 2.0 * _glowAnim.value,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                )
              : Icon(Icons.star_border,
                  color: Colors.yellow.withValues(alpha: 0.3), size: 13.0),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '8.2',
                style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold),
              ),
              const Text(
                'TIE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              if (widget.isBetting)
                const Text(
                  'Start betting',
                  style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  'Betting Closed',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isWinner) {
      return AnimatedBuilder(
        animation: widget.blinkAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: widget.height * 0.16,
            decoration: _getDecoration(true),
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            child: child,
          );
        },
        child: _buildContent(),
      );
    }
    return Container(
      width: double.infinity,
      height: widget.height * 0.16,
      decoration: _getDecoration(false),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: _buildContent(),
    );
  }
}
