import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/playing_card.dart';

/// Renders the face of a playing card.
class GameCardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;

  const GameCardWidget({
    super.key,
    required this.card,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 4.0, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          Positioned(
            top: 2.0,
            left: 2.0,
            child: Column(
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                      color: card.color,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      height: 1.0),
                ),
                _getSuitIcon(card.suit, card.color, size: 8.0),
              ],
            ),
          ),
          Center(child: _getSuitIcon(card.suit, card.color, size: 16.0)),
          Positioned(
            bottom: 2.0,
            right: 2.0,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                children: [
                  Text(
                    card.rankLabel,
                    style: TextStyle(
                        color: card.color,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        height: 1.0),
                  ),
                  _getSuitIcon(card.suit, card.color, size: 8.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _getSuitIcon(String suit, Color color, {double size = 12.0}) {
    String symbol;
    switch (suit) {
      case 'Hearts':
        symbol = '♥';
        break;
      case 'Diamonds':
        symbol = '♦';
        break;
      case 'Spades':
        symbol = '♠';
        break;
      default:
        symbol = '♣';
        break;
    }
    return Text(
      symbol,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
    );
  }
}

/// Renders the back face of a card (for dealing animation).
class CardBackWidget extends StatelessWidget {
  final double width;
  final double height;

  const CardBackWidget({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4.0)],
      ),
      child: const Center(
        child: Icon(Icons.style, color: Colors.white70, size: 18.0),
      ),
    );
  }
}

/// Placeholder shown before a card is dealt.
class CardPlaceholderWidget extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  final double height;

  const CardPlaceholderWidget({
    super.key,
    required this.label,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 2))
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
