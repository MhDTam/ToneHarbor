import 'package:flutter/material.dart';

/// A single live surface: outgoing content is removed immediately, so rapid
/// changes cannot accumulate translucent pages or covers in a switcher stack.
class HarborEntrance extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  const HarborEntrance({super.key, required this.trigger, required this.child});
  @override
  State<HarborEntrance> createState() => _HarborEntranceState();
}

class _HarborEntranceState extends State<HarborEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180), value: 1);
  late final _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(covariant HarborEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      if (MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
      child: AnimatedBuilder(
          animation: _curve,
          child: RepaintBoundary(child: widget.child),
          builder: (_, child) {
            final value = _curve.value;
            return Transform.translate(
                offset: Offset(0, 5 * (1 - value)),
                child: Opacity(opacity: .94 + .06 * value, child: child));
          }));
}
