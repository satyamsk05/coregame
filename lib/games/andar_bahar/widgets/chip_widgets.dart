import 'package:flutter/material.dart';

/// A single poker chip widget using PNG asset images.
class PokerChipWidget extends StatelessWidget {
  final int value;
  final double size;
  final bool selected;

  const PokerChipWidget({
    super.key,
    required this.value,
    this.size = 32.0,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    int val = value;
    if (val != 10 && val != 50 && val != 100 && val != 500 && val != 1000 && val != 5000) {
      if (val < 30) {
        val = 10;
      } else if (val < 75) {
        val = 50;
      } else if (val < 300) {
        val = 100;
      } else if (val < 750) {
        val = 500;
      } else if (val < 3000) {
        val = 1000;
      } else {
        val = 5000;
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF00E5FF) : Colors.white60,
          width: selected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: selected ? const Color(0x9900E5FF) : Colors.black45,
            blurRadius: selected ? 5.0 : 2.0,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/chips/chip_$val.png',
          fit: BoxFit.cover,
          width: size,
          height: size,
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
      case 50:
        return const Color(0xFFE91E63);
      case 100:
        return const Color(0xFF2E7D32);
      case 500:
        return const Color(0xFF1565C0);
      case 1000:
        return const Color(0xFF6A1B9A);
      case 5000:
        return const Color(0xFFFFD700);
      default:
        return Colors.blueGrey;
    }
  }

  static String getChipText(int val) {
    if (val >= 5000) return '5K';
    if (val >= 1000) return '1K';
    return '$val';
  }

  @override
  Widget build(BuildContext context) {
    final chipValues = [10, 50, 100, 500, 1000, 5000];



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
          return GestureDetector(
            onTap: () => onChipSelected(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(0.0, isSelected ? -8.0 : 0.0, 0.0),
              child: Transform.scale(
                scale: isSelected ? 1.12 : 1.0,
                child: PokerChipWidget(
                  value: val,
                  selected: isSelected,
                  size: 38.0,
                ),
              ),
            ),
          );

        }).toList(),
      ),
    );
  }
}

