import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WinOverlayCard extends StatelessWidget {
  final double multiplier;
  final double winAmount;
  final bool isWin;
  final String? customTitle;

  const WinOverlayCard({
    super.key,
    required this.multiplier,
    required this.winAmount,
    this.isWin = true,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = isWin ? const Color(0xFF00E676) : const Color(0xFFFF4560);

    return Container(
      width: 190.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024).withOpacity(0.96),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 18.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Multiplier / Title with sparkles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWin ? Icons.auto_awesome : Icons.dangerous_outlined,
                color: mainColor,
                size: 14.0,
              ),
              const SizedBox(width: 6.0),
              Text(
                customTitle ?? '${multiplier.toStringAsFixed(2)}x',
                style: GoogleFonts.robotoMono(
                  textStyle: TextStyle(
                    color: mainColor,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Icon(
                isWin ? Icons.auto_awesome : Icons.dangerous_outlined,
                color: mainColor,
                size: 14.0,
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Bottom Win/Loss Amount Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFF14161B),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWin ? winAmount.toStringAsFixed(2) : '0.00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  width: 17.0,
                  height: 17.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isWin ? Colors.orange : Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '₹',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
