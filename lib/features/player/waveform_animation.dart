import 'dart:math';
import 'package:flutter/material.dart';

class WaveformAnimation extends StatefulWidget {
  final Color color;
  final int barCount;

  const WaveformAnimation({
    super.key,
    required this.color,
    this.barCount = 4,
  });

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.barCount; i++) {
      _heights.add(_random.nextDouble());
    }
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            final double value =
                (sin(_controller.value * 2 * pi + index) + 1) / 2;
            final double height = 4 + (value * 12);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color.withAlpha((value * 155 + 100).toInt()),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
