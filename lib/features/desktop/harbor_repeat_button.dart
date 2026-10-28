import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio/audio_player_service.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';

/// Every mode has a visible badge; color alone never identifies repeat state.
class HarborRepeatButton extends ConsumerWidget {
  final RepeatState mode;
  final VoidCallback onPressed;
  const HarborRepeatButton(
      {super.key, required this.mode, required this.onPressed});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(harborThemeProvider);
    final active = mode != RepeatState.off;
    final color = active ? theme.accent : const Color(0xFFAFBDC5);
    final (badge, label) = switch (mode) {
      RepeatState.off => ('0', 'Repeat off'),
      RepeatState.one => ('1', 'Repeat once'),
      RepeatState.three => ('3', 'Repeat 3 times'),
      RepeatState.infinite => ('∞', 'Repeat forever'),
    };
    return SizedBox(
        width: 38,
        height: 36,
        child: IconButton(
          key: const ValueKey('repeat-mode-control'),
          tooltip: harborText(context, label),
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          style: IconButton.styleFrom(
              backgroundColor:
                  active ? theme.accent.withAlpha(14) : Colors.transparent),
          icon: SizedBox(
              width: 28,
              height: 27,
              child: Stack(children: [
                Positioned(
                    left: 0,
                    top: 0,
                    child: Icon(Icons.repeat_rounded, size: 23, color: color)),
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14),
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: theme.background,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: color.withAlpha(active ? 150 : 70),
                              width: .7)),
                      child: Text(badge,
                          key: const ValueKey('repeat-mode-badge'),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              color: color,
                              fontSize: mode == RepeatState.infinite ? 13 : 10,
                              height: 1,
                              fontWeight: FontWeight.w700)),
                    )),
              ])),
        ));
  }
}
