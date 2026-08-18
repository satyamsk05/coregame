import 'package:flutter/material.dart';

class SwipeSlider extends StatefulWidget {
  final VoidCallback onSwipeComplete;
  final String text;
  final Color activeColor;

  const SwipeSlider({
    super.key,
    required this.onSwipeComplete,
    this.text = 'SLIDE TO WITHDRAW',
    this.activeColor = const Color(0xFFFF5252), // Coral red
  });

  @override
  State<SwipeSlider> createState() => _SwipeSliderState();
}

class _SwipeSliderState extends State<SwipeSlider> {
  double _dragPosition = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    const double handleSize = 44.0;
    const double sliderHeight = 54.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragDistance = constraints.maxWidth - handleSize - 10.0;

        return Container(
          width: double.infinity,
          height: sliderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.black, width: 3.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFD0D0D0),
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Sliding Progress Fill
              AnimatedContainer(
                duration: Duration(milliseconds: _dragPosition == 0 ? 200 : 0),
                width: _dragPosition + handleSize / 2 + 5.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: widget.activeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),

              // 2. Center Slider Prompt Text
              Center(
                child: Text(
                  _isFinished ? 'PROCESSING...' : widget.text.toUpperCase(),
                  style: TextStyle(
                    color: _isFinished ? widget.activeColor : Colors.grey[700],
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              // 3. Draggable Handle Block
              AnimatedPositioned(
                duration: Duration(milliseconds: _dragPosition == 0 ? 200 : 0),
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDragDistance);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isFinished) return;
                    if (_dragPosition >= maxDragDistance - 5.0) {
                      // Trigger complete action
                      setState(() {
                        _dragPosition = maxDragDistance;
                        _isFinished = true;
                      });
                      widget.onSwipeComplete();
                    } else {
                      // Reset to start
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.black, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.double_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
