import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/platform_utils.dart';
import 'audio_player_service.dart';
import 'audio_player_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sleep Timer Options
// ─────────────────────────────────────────────────────────────────────────────
enum SleepTimerMode { timeEndLock, trackEndLock, playlistEndLock }

class SleepTimerState {
  final bool isActive;
  final SleepTimerMode mode;
  final int remainingSeconds;
  final int totalSeconds;
  final bool closeApp;

  const SleepTimerState({
    this.isActive = false,
    this.mode = SleepTimerMode.timeEndLock,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.closeApp = false,
  });

  SleepTimerState copyWith({
    bool? isActive,
    SleepTimerMode? mode,
    int? remainingSeconds,
    int? totalSeconds,
    bool? closeApp,
  }) =>
      SleepTimerState(
        isActive: isActive ?? this.isActive,
        mode: mode ?? this.mode,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        closeApp: closeApp ?? this.closeApp,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Close app helper – platform aware
// ─────────────────────────────────────────────────────────────────────────────
void _triggerCloseApp() {
  if (isMobile) {
    // Mobile: use method channel for lock screen
    const lockChannel = MethodChannel('com.musiconvert.mp3noads/lock');
    try {
      lockChannel.invokeMethod('closeApp');
    } catch (_) {}
    SystemNavigator.pop();
    Future.delayed(const Duration(milliseconds: 500), () => exit(0));
  } else {
    // Desktop: just exit gracefully
    exit(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep Timer Notifier
// ─────────────────────────────────────────────────────────────────────────────
class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final AudioPlayerNotifier _player;
  Timer? _ticker;
  StreamSubscription? _trackEndSub;

  SleepTimerNotifier(this._player) : super(const SleepTimerState());

  Future<void> startTimer({
    required SleepTimerMode mode,
    int minutes = 15,
    bool closeApp = false,
  }) async {
    cancel();
    state = SleepTimerState(
      isActive: true,
      mode: mode,
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
      closeApp: closeApp,
    );
    _player.setSleepBoundary(
        track: mode == SleepTimerMode.trackEndLock,
        queue: mode == SleepTimerMode.playlistEndLock);

    switch (mode) {
      case SleepTimerMode.trackEndLock:
        _listenForEvent(trackEnd: true);
      case SleepTimerMode.playlistEndLock:
        _listenForEvent(trackEnd: false);
      case SleepTimerMode.timeEndLock:
        _startCountdown(onExpire: (shouldClose) async {
          try {
            await _player.pause();
          } catch (_) {}
          if (shouldClose) _triggerCloseApp();
        });
    }
  }

  void _startCountdown(
      {required Future<void> Function(bool shouldClose) onExpire}) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        final shouldClose = state.closeApp;
        cancel();
        await onExpire(shouldClose);
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  int? _trackingIndex;

  void _listenForEvent({required bool trackEnd}) {
    _trackingIndex = _player.state.currentIndex;
    _trackEndSub = _player.stream.listen((ps) async {
      if (!state.isActive) return;

      if (trackEnd) {
        if (ps.currentIndex != _trackingIndex) {
          cancel();
          return;
        }

        if (ps.processingState == AppProcessingState.completed) {
          final shouldClose = state.closeApp;
          cancel(clearBoundary: false);
          try {
            await _player.pause();
          } catch (_) {}
          if (shouldClose) _triggerCloseApp();
          return;
        }
      } else {
        if (ps.processingState == AppProcessingState.completed &&
            ps.queue.isNotEmpty &&
            ps.currentIndex == ps.queue.length - 1) {
          final shouldClose = state.closeApp;
          cancel(clearBoundary: false);
          try {
            await _player.pause();
          } catch (_) {}
          if (shouldClose) _triggerCloseApp();
        }
      }
    });
  }

  void cancel({bool clearBoundary = true}) {
    if (clearBoundary) _player.setSleepBoundary();
    _ticker?.cancel();
    _ticker = null;
    _trackEndSub?.cancel();
    _trackEndSub = null;
    state = const SleepTimerState();
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  final player = ref.watch(audioPlayerProvider.notifier);
  return SleepTimerNotifier(player);
});
