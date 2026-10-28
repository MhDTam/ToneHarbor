import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'platform_utils.dart';
import '../../features/desktop/harbor_themes.dart';
import '../../features/desktop/harbor_strings.dart';

/// Status conveyed by an application notice.
enum ToastType { success, error, warning, info }

/// Desktop notices use the current Harbor palette and a compact dismissible row.
class AppToast {
  static OverlayEntry? _currentToast;
  static VoidCallback? _dismissCurrent;
  static void dismiss() => _dismissCurrent?.call();

  /// Replace the current notice; at most one notice owns a timer and overlay.
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any existing toast
    dismiss();

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    var removed = false;
    void release() {
      removed = true;
      if (identical(_currentToast, entry)) {
        _currentToast = null;
        _dismissCurrent = null;
      }
    }

    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
      entry.dispose();
      release();
    }

    entry = OverlayEntry(
      builder: (ctx) => isDesktop
          ? _DesktopToast(
              message: message,
              type: type,
              duration: duration,
              onDismiss: remove,
              onDisposed: release,
            )
          : _ToastWidget(
              message: message,
              type: type,
              duration: duration,
              onDismiss: remove,
              onDisposed: release,
            ),
    );

    _currentToast = entry;
    _dismissCurrent = remove;
    overlay.insert(entry);
  }

  /// Convenience methods
  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, String message) => show(context,
      message: message,
      type: ToastType.error,
      duration: const Duration(seconds: 4));

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.info);
}

class _DesktopToast extends ConsumerStatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss, onDisposed;
  const _DesktopToast(
      {required this.message,
      required this.type,
      required this.duration,
      required this.onDismiss,
      required this.onDisposed});
  @override
  ConsumerState<_DesktopToast> createState() => _DesktopToastState();
}

class _DesktopToastState extends ConsumerState<_DesktopToast>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 120));
  Timer? _timer;
  bool _closing = false;
  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _arm();
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    try {
      await _controller.reverse().orCancel;
      if (mounted) widget.onDismiss();
    } on TickerCanceled {/* Replaced or the owning overlay closed. */}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(harborThemeProvider);
    final media = MediaQuery.of(context);
    final color = switch (widget.type) {
      ToastType.error => const Color(0xFFEE9AA6),
      ToastType.warning => const Color(0xFFE9BD7C),
      _ => theme.accent,
    };
    final icon = switch (widget.type) {
      ToastType.success => Icons.check_circle_outline_rounded,
      ToastType.error => Icons.error_outline_rounded,
      ToastType.warning => Icons.warning_amber_rounded,
      ToastType.info => Icons.info_outline_rounded,
    };
    return PositionedDirectional(
      top: media.padding.top + (media.size.height < 260 ? 12 : 76),
      end: 22,
      width: (media.size.width - 44).clamp(0.0, 380.0),
      child: FadeTransition(
          opacity: _controller,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -.08), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: _controller, curve: Curves.easeOutCubic)),
            child: MouseRegion(
                onEnter: (_) => _timer?.cancel(),
                onExit: (_) {
                  if (!_closing) _arm();
                },
                child: Material(
                  key: const ValueKey('desktop-notice'),
                  color: theme.surface,
                  elevation: 4,
                  shadowColor: const Color(0x44000000),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.border)),
                  child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(12, 10, 5, 10),
                      child: Row(children: [
                        Container(
                            width: 2,
                            height: 28,
                            decoration: BoxDecoration(
                                color: color.withAlpha(180),
                                borderRadius: BorderRadius.circular(1))),
                        const SizedBox(width: 10),
                        Icon(icon, color: color, size: 19),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Semantics(
                                liveRegion: true,
                                child: Text(widget.message,
                                    key: const ValueKey(
                                        'desktop-notice-message'),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'Segoe UI',
                                        fontSize: 12,
                                        color: Color(0xFFE2EBEF),
                                        height: 1.4)))),
                        const SizedBox(width: 6),
                        SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                                key: const ValueKey('desktop-notice-close'),
                                padding: EdgeInsets.zero,
                                tooltip: harborText(context, 'Close'),
                                onPressed: _dismiss,
                                icon: const Icon(Icons.close_rounded,
                                    size: 16, color: Color(0xFF9BACB7)))),
                      ])),
                )),
          )),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback onDisposed;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    required this.onDisposed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF00E676);
      case ToastType.error:
        return const Color(0xFFFF5252);
      case ToastType.warning:
        return const Color(0xFFFFAB40);
      case ToastType.info:
        return const Color(0xFF448AFF);
    }
  }

  Color get _glowColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF00E676).withAlpha(60);
      case ToastType.error:
        return const Color(0xFFFF5252).withAlpha(60);
      case ToastType.warning:
        return const Color(0xFFFFAB40).withAlpha(60);
      case ToastType.info:
        return const Color(0xFF448AFF).withAlpha(60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Positioned(
      top: mq.padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < -50) {
                  _controller.reverse().then((_) {
                    if (mounted) widget.onDismiss();
                  });
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accentColor.withAlpha(80),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _glowColor,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Animated icon with glow
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accentColor.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _icon,
                            color: _accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message
                        Expanded(
                          child: Text(
                            widget.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              decoration: TextDecoration.none,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Close button
                        GestureDetector(
                          onTap: () {
                            _controller.reverse().then((_) {
                              if (mounted) widget.onDismiss();
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withAlpha(150),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
