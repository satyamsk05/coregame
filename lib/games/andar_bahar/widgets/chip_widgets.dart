import 'package:flutter/material.dart';

/// A single poker chip widget used in the chip selector and flying chip animations.
class PokerChipWidget extends StatelessWidget {
  final Color color;
  final String label;
  final double size;
  final bool selected;

  const PokerChipWidget({
    super.key,
    required this.color,
    required this.label,
    this.size = 32.0,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
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
          style: const TextStyle(
              color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// The bottom chip selector row where the user picks a chip denomination.
class ChipSelectorWidget extends StatelessWidget {
  final int selectedChipValue;
  final void Function(int val) onChipSelected;
  final double height;

  const ChipSelectorWidget({
    super.key,
    required this.selectedChipValue,
    required this.onChipSelected,
    required this.height,
  });

  static Color getChipColor(int val) {
    switch (val) {
      case 10:
        return const Color(0xFF1E1E24);
      case 100:
        return const Color(0xFF2E7D32);
      case 500:
        return const Color(0xFF1565C0);
      case 1000:
        return const Color(0xFF6A1B9A);
      case 10000:
        return const Color(0xFFD84315);
      default:
        return Colors.blueGrey;
    }
  }

  static String getChipText(int val) {
    if (val >= 10000) return '10K';
    if (val >= 1000) return '1K';
    return '$val';
  }

  @override
  Widget build(BuildContext context) {
    final chipValues = [10, 100, 500, 1000, 10000];
    return Container(
      height: height * 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: chipValues.map((val) {
          final isSelected = selectedChipValue == val;
          final color = getChipColor(val);
          final label = getChipText(val);
          return GestureDetector(
            onTap: () => onChipSelected(val),
            child: Transform.scale(
              scale: isSelected ? 1.12 : 1.0,
              child: PokerChipWidget(
                color: color,
                label: label,
                selected: isSelected,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
