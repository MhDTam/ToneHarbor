import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/song_model.dart';

/// Animate only the old/new playing row. The child and its hit targets stay
/// stationary; range selection never starts a playback transition.
class HarborTrackHighlight extends StatelessWidget {
  final bool active, selected;
  final Color accent, idleColor;
  final Duration duration;
  final Widget child;
  const HarborTrackHighlight(
      {super.key,
      required this.active,
      required this.selected,
      required this.accent,
      required this.idleColor,
      required this.duration,
      required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: active ? 1 : 0, end: active ? 1 : 0),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
        builder: (_, activity, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected
                ? accent.withAlpha(15)
                : Color.lerp(idleColor, accent.withAlpha(24), activity),
          ),
          child: child,
        ),
      );
}

/// Desktop range selection with drag capture, long-press activation and edge
/// scrolling. The fixed row extent keeps hit testing independent of row builds.
class HarborTrackList extends StatefulWidget {
  final List<SongModel> songs;
  final bool selectionMode;
  final Set<int> selected;
  final void Function(Set<int> ids, int anchor) onSelection;
  final VoidCallback onCancelSelection;
  final Widget Function(SongModel song, int index) rowBuilder;
  const HarborTrackList(
      {super.key,
      required this.songs,
      required this.selectionMode,
      required this.selected,
      required this.onSelection,
      required this.onCancelSelection,
      required this.rowBuilder});
  @override
  State<HarborTrackList> createState() => _HarborTrackListState();
}

class _HarborTrackListState extends State<HarborTrackList> {
  static const extent = 64.0;
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _viewport = GlobalKey();
  Timer? _edgeTimer;
  Offset? _down, _pointer, _contentStart;
  Set<int> _base = {};
  int _anchor = 0;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant HarborTrackList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectionMode && !oldWidget.selectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectionMode) _focus.requestFocus();
      });
    }
    if (!listEquals(oldWidget.songs, widget.songs) || !widget.selectionMode) {
      _dragging = false;
      _edgeTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  RenderBox? get _box =>
      _viewport.currentContext?.findRenderObject() as RenderBox?;

  void _begin(int index, Offset point) {
    _focus.requestFocus();
    final box = _box;
    if (box == null) return;
    _anchor = index;
    _base = widget.selectionMode || HardwareKeyboard.instance.isControlPressed
        ? Set.of(widget.selected)
        : <int>{};
    final local = box.globalToLocal(_down ?? point);
    _contentStart = local + Offset(0, _scroll.offset);
    _pointer = point;
    _dragging = true;
    _update(point);
    _edgeTimer?.cancel();
    _edgeTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _edgeScroll());
  }

  void _update(Offset point) {
    if (!_dragging || widget.songs.isEmpty) return;
    final box = _box;
    if (box == null) return;
    _pointer = point;
    final local = box.globalToLocal(point);
    final index = ((local.dy + _scroll.offset) / extent)
        .floor()
        .clamp(0, widget.songs.length - 1);
    final first = math.min(_anchor, index), last = math.max(_anchor, index);
    final ids = {
      ..._base,
      for (var i = first; i <= last; i++) widget.songs[i].id
    };
    if (!widget.selectionMode || !setEquals(ids, widget.selected)) {
      widget.onSelection(ids, _anchor);
    }
    setState(() {});
  }

  void _edgeScroll() {
    if (!_dragging || _pointer == null || !_scroll.hasClients) return;
    final box = _box;
    if (box == null) return;
    final y = box.globalToLocal(_pointer!).dy;
    final speed = y < 38
        ? -((38 - y) / 3).clamp(2, 18)
        : y > box.size.height - 38
            ? ((y - box.size.height + 38) / 3).clamp(2, 18)
            : 0.0;
    if (speed == 0) return;
    final target =
        (_scroll.offset + speed).clamp(0.0, _scroll.position.maxScrollExtent);
    if (target == _scroll.offset) return;
    _scroll.jumpTo(target);
    _update(_pointer!);
  }

  void _finish() {
    _edgeTimer?.cancel();
    if (_dragging && mounted) setState(() => _dragging = false);
    _down = null;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.selectionMode) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _finish();
      widget.onCancelSelection();
      return KeyEventResult.handled;
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        widget.onSelection(widget.songs.map((s) => s.id).toSet(), 0);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyI) {
        widget.onSelection(
            widget.songs
                .where((s) => !widget.selected.contains(s.id))
                .map((s) => s.id)
                .toSet(),
            0);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final box = _box;
    Rect? marquee;
    if (_dragging && _contentStart != null && _pointer != null && box != null) {
      final start = _contentStart! - Offset(0, _scroll.offset);
      final end = box.globalToLocal(_pointer!);
      if ((end - start).distance > 12) {
        marquee = Rect.fromPoints(start, end).intersect(Offset.zero & box.size);
      }
    }
    final color = Theme.of(context).colorScheme.primary;
    return Stack(key: _viewport, clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(
          child: Focus(
              focusNode: _focus,
              onKeyEvent: _key,
              child: Listener(
                onPointerDown: (_) => _focus.requestFocus(),
                onPointerMove: (event) {
                  if (_dragging) _update(event.position);
                },
                onPointerUp: (_) => _finish(),
                onPointerCancel: (_) => _finish(),
                child: ListView.builder(
                  controller: _scroll,
                  itemExtent: extent,
                  itemCount: widget.songs.length,
                  itemBuilder: (_, index) => GestureDetector(
                    key: ValueKey('library-row-${widget.songs[index].id}'),
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _down = d.globalPosition,
                    onPanStart: (d) => _begin(index, d.globalPosition),
                    onPanUpdate: (d) => _update(d.globalPosition),
                    onPanEnd: (_) => _finish(),
                    onLongPressStart: (d) => _begin(index, d.globalPosition),
                    onLongPressMoveUpdate: (d) => _update(d.globalPosition),
                    onLongPressEnd: (_) => _finish(),
                    child: widget.rowBuilder(widget.songs[index], index),
                  ),
                ),
              ))),
      if (marquee != null && !marquee.isEmpty)
        Positioned.fromRect(
            rect: marquee,
            child: IgnorePointer(
                child: DecoratedBox(
              decoration: BoxDecoration(
                  color: color.withAlpha(14),
                  border: Border.all(color: color.withAlpha(125)),
                  borderRadius: BorderRadius.circular(3)),
            ))),
    ]);
  }
}
