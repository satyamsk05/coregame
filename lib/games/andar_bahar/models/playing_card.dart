import 'package:flutter/material.dart';

class PlayingCard {
  final int rank; // 1 (Ace) to 13 (King)
  final String suit; // Hearts, Diamonds, Spades, Clubs

  PlayingCard({required this.rank, required this.suit});

  String get rankLabel {
    if (rank == 1) return 'A';
    if (rank == 11) return 'J';
    if (rank == 12) return 'Q';
    if (rank == 13) return 'K';
    return '$rank';
  }

  Color get color {
    return (suit == 'Hearts' || suit == 'Diamonds')
        ? const Color(0xFFD32F2F)
        : const Color(0xFF212121);
  }
}
