import 'package:flutter/material.dart';

/// Andar / Bahar side bet panel with win blink animation support.
class SideBetPanel extends StatelessWidget {
  final String label;       // 'Andar' or 'Bahar'
  final double totalBet;
  final double userBet;
  final Color baseColor;
  final bool isLeft;
  final bool isWinner;
  final Animation<double> blinkAnimation;

  const SideBetPanel({
    super.key,
    required this.label,
    required this.totalBet,
    required this.userBet,
    required this.baseColor,
    required this.isLeft,
    required this.isWinner,
    required this.blinkAnimation,
  });

  BoxDecoration _getPanelDecoration(bool winner) {
    if (winner) {
      final double val = blinkAnimation.value;
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(baseColor.withValues(alpha: 0.4),
                const Color(0xFFFFD700).withValues(alpha: 0.5), val)!,
            Color.lerp(baseColor.withValues(alpha: 0.15),
                const Color(0xFFFFD700).withValues(alpha: 0.2), val)!,
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
        colors: [
          baseColor.withValues(alpha: 0.4),
          baseColor.withValues(alpha: 0.15)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(color: baseColor, width: 1.5),
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
                '${totalBet.toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold),
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
        Positioned(
          left: isLeft ? 8.0 : null,
          right: !isLeft ? 8.0 : null,
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
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        if (userBet > 0)
          Positioned(
            bottom: 4.0,
            left: !isLeft ? 8.0 : null,
            right: isLeft ? 8.0 : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'Mine: ${userBet.toInt()}',
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Positioned(
          bottom: 4.0,
          left: isLeft ? 8.0 : null,
          right: !isLeft ? 8.0 : null,
          child: Icon(Icons.star_border,
              color: Colors.yellow.withValues(alpha: 0.4), size: 14.0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWinner) {
      return AnimatedBuilder(
        animation: blinkAnimation,
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
class TieBetPanel extends StatelessWidget {
  final double totalBetTie;
  final double userBetTie;
  final bool isBetting;
  final bool isWinner;
  final Animation<double> blinkAnimation;
  final double height;

  const TieBetPanel({
    super.key,
    required this.totalBetTie,
    required this.userBetTie,
    required this.isBetting,
    required this.isWinner,
    required this.blinkAnimation,
    required this.height,
  });

  BoxDecoration _getDecoration(bool winner) {
    const Color tieBaseColor = Color(0xFF2E7D32);
    if (winner) {
      final double val = blinkAnimation.value;
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
                '${totalBetTie.toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold),
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
                style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold),
              ),
              const Text(
                'TIE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              if (isBetting)
                const Text(
                  'Start betting',
                  style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  'Betting Closed',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 8.0,
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
    if (isWinner) {
      return AnimatedBuilder(
        animation: blinkAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: height * 0.16,
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
      height: height * 0.16,
      decoration: _getDecoration(false),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: _buildContent(),
    );
  }
}
