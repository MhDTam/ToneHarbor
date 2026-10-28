import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'harbor_waveform.dart';

String editorTime(double seconds) {
  final milliseconds = (math.max(0, seconds) * 1000).round();
  final total = milliseconds ~/ 1000;
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}.${(milliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
}

class HarborEditorTimeline extends StatefulWidget {
  final List<double> samples;
  final double duration, start, end, speed;
  final Color color;
  final bool enabled;
  final ValueNotifier<Duration> position;
  final ValueChanged<RangeValues> onChanged;
  final VoidCallback onChangeStart, onChangeEnd;
  const HarborEditorTimeline(
      {super.key,
      required this.samples,
      required this.duration,
      required this.start,
      required this.end,
      required this.speed,
      required this.color,
      required this.position,
      required this.onChanged,
      required this.onChangeStart,
      required this.onChangeEnd,
      this.enabled = true});
  @override
  State<HarborEditorTimeline> createState() => _HarborEditorTimelineState();
}

class _HarborEditorTimelineState extends State<HarborEditorTimeline> {
  final _bars = WaveformDisplayCache();
  @override
  Widget build(BuildContext context) => RepaintBoundary(
          child: SizedBox(
        height: 206,
        child: LayoutBuilder(builder: (_, bounds) {
          final count = (bounds.maxWidth / 3).floor().clamp(32, 512);
          final total = math.max(.001, widget.duration);
          final start = widget.start.clamp(0.0, total),
              end = widget.end.clamp(start, total);
          return Stack(fit: StackFit.expand, children: [
            CustomPaint(
                painter: _TimelinePainter(
                    _bars.amplitudes(widget.samples, count),
                    total,
                    start,
                    end,
                    widget.color)),
            IgnorePointer(
                child: CustomPaint(
                    painter: _TimelineCursor(widget.position, total, start,
                        widget.speed, widget.color))),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 27),
                child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        trackHeight: 0,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        overlayShape: SliderComponentShape.noOverlay,
                        rangeThumbShape: const _SelectionHandle(),
                        rangeTrackShape:
                            const RectangularRangeSliderTrackShape(),
                        minThumbSeparation: 0),
                    child: RangeSlider(
                        key: const ValueKey('editor-selection-range'),
                        min: 0,
                        max: total,
                        values: RangeValues(start, end),
                        labels: RangeLabels(editorTime(start), editorTime(end)),
                        onChangeStart: (_) => widget.onChangeStart(),
                        onChangeEnd: (_) => widget.onChangeEnd(),
                        onChanged: widget.enabled && widget.duration > 0
                            ? widget.onChanged
                            : null))),
          ]);
        }),
      ));
}

class _SelectionHandle extends RangeSliderThumbShape {
  const _SelectionHandle();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 120);
  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      bool isDiscrete = false,
      bool isEnabled = false,
      bool isOnTop = false,
      required SliderThemeData sliderTheme,
      TextDirection? textDirection,
      Thumb? thumb,
      bool isPressed = false}) {
    final paint = Paint()..color = sliderTheme.thumbColor ?? Colors.cyanAccent;
    context.canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 4, height: 126),
            const Radius.circular(2)),
        paint);
    context.canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 12, height: 24),
            const Radius.circular(4)),
        paint);
  }
}

class _TimelinePainter extends CustomPainter {
  final List<double> bars;
  final double duration, start, end;
  final Color color;
  _TimelinePainter(this.bars, this.duration, this.start, this.end, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final area =
        Rect.fromLTWH(10, 30, math.max(1, size.width - 20), size.height - 60);
    final left = area.left + area.width * start / duration;
    final right = area.left + area.width * end / duration;
    canvas.drawRect(Rect.fromLTRB(left, area.top, right, area.bottom),
        Paint()..color = color.withAlpha(22));
    final label = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 5; i++) {
      final x = area.left + area.width * i / 5;
      canvas.drawLine(Offset(x, area.top), Offset(x, area.bottom),
          Paint()..color = color.withAlpha(18));
      label.text = TextSpan(
          text: editorTime(duration * i / 5),
          style: const TextStyle(
              fontFamily: 'Segoe UI', fontSize: 10, color: Color(0xFF93A6B2)));
      label.layout();
      label.paint(canvas,
          Offset((x - label.width / 2).clamp(0, size.width - label.width), 6));
    }
    label.dispose();
    final peak = bars.fold<double>(0, math.max);
    final gain = peak > 0 ? math.min(4.0, .9 / peak) : 1.0;
    final paint = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < bars.length; i++) {
      final x = area.left + area.width * (i + .5) / bars.length;
      paint.color = x >= left && x <= right ? color : color.withAlpha(55);
      final height = bars[i] * gain * (area.height - 12);
      if (height > 0) {
        canvas.drawLine(Offset(x, area.center.dy - height / 2),
            Offset(x, area.center.dy + height / 2), paint);
      }
    }
    canvas.drawLine(
        Offset(area.left, area.center.dy),
        Offset(area.right, area.center.dy),
        Paint()..color = color.withAlpha(30));
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.bars != bars ||
      old.start != start ||
      old.end != end ||
      old.duration != duration ||
      old.color != color;
}

class _TimelineCursor extends CustomPainter {
  final ValueNotifier<Duration> position;
  final double duration, start, speed;
  final Color color;
  _TimelineCursor(
      this.position, this.duration, this.start, this.speed, this.color)
      : super(repaint: position);
  @override
  void paint(Canvas canvas, Size size) {
    final seconds = start + position.value.inMilliseconds / 1000 * speed;
    final x = 10 + (size.width - 20) * (seconds / duration).clamp(0, 1);
    canvas.drawLine(
        Offset(x, 28),
        Offset(x, size.height - 28),
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 1);
    canvas.drawCircle(Offset(x, 27), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TimelineCursor old) =>
      old.start != start ||
      old.duration != duration ||
      old.speed != speed ||
      old.color != color;
}
