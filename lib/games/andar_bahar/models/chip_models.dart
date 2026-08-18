import 'package:flutter/material.dart';

class TableChip {
  final double x;
  final double y;
  final Color color;
  final String label;

  TableChip({
    required this.x,
    required this.y,
    required this.color,
    required this.label,
  });
}

class FlyingChip {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final String label;
  final AnimationController controller;

  FlyingChip({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.label,
    required this.controller,
  });
}
