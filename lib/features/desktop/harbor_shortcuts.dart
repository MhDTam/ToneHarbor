import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/audio/audio_player_service.dart';
import 'harbor_strings.dart';

enum HarborAction { playPause, next, previous, volumeUp, volumeDown }

class HarborBinding {
  final int modifiers, key;
  const HarborBinding(this.modifiers, this.key);
  String get label {
    final modifiersText = [
      if (modifiers & 2 != 0) 'Ctrl',
      if (modifiers & 1 != 0) 'Alt',
      if (modifiers & 4 != 0) 'Shift'
    ];
    final keyText = switch (key) {
      0x25 => '←',
      0x26 => '↑',
      0x27 => '→',
      0x28 => '↓',
      0x20 => 'Space',
      >= 0x70 && <= 0x7b => 'F${key - 0x6f}',
      _ => String.fromCharCode(key)
    };
    return [...modifiersText, keyText].join(' + ');
  }

  bool sameAs(HarborBinding other) =>
      key == other.key && modifiers == other.modifiers;
}

const _defaults = <HarborAction, HarborBinding>{
  HarborAction.playPause: HarborBinding(3, 0x50),
  HarborAction.next: HarborBinding(3, 0x27),
  HarborAction.previous: HarborBinding(3, 0x25),
  HarborAction.volumeUp: HarborBinding(3, 0x26),
  HarborAction.volumeDown: HarborBinding(3, 0x28),
};

final harborShortcutsProvider =
    StateNotifierProvider<HarborShortcuts, Map<HarborAction, HarborBinding>>(
        (ref) => HarborShortcuts(ref));

class HarborShortcuts extends StateNotifier<Map<HarborAction, HarborBinding>> {
  final Ref ref;
  static const _channel = MethodChannel('toneharbor/hotkeys');
  final Set<HarborAction> unavailable = {};
  HarborShortcuts(this.ref) : super(Map.of(_defaults)) {
    if (Platform.isWindows) {
      _channel.setMethodCallHandler(_handle);
      _load();
    }
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final values = jsonDecode(prefs.getString('toneharbor_shortcuts') ?? '{}')
          as Map<String, dynamic>;
      final loaded = Map<HarborAction, HarborBinding>.of(_defaults);
      for (final action in HarborAction.values) {
        final v = values[action.name];
        if (v is List && v.length == 2 && v[0] is int && v[1] is int) {
          loaded[action] = HarborBinding(v[0] as int, v[1] as int);
        }
      }
      if (!mounted) return;
      state = loaded;
    } catch (_) {}
    for (final action in HarborAction.values) {
      try {
        if (!await _register(action, state[action]!)) unavailable.add(action);
      } catch (_) {
        unavailable.add(action);
      }
    }
    if (mounted) state = Map.of(state);
  }

  Future<bool> _register(HarborAction action, HarborBinding binding) async =>
      await _channel.invokeMethod<bool>('register', {
        'id': action.index + 1,
        'modifiers': binding.modifiers,
        'key': binding.key
      }) ??
      false;
  Future<bool> update(HarborAction action, HarborBinding binding) async {
    if (state.entries.any((e) => e.key != action && e.value.sameAs(binding))) {
      return false;
    }
    try {
      if (!Platform.isWindows || !await _register(action, binding)) {
        return false;
      }
      unavailable.remove(action);
      state = {...state, action: binding};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'toneharbor_shortcuts',
          jsonEncode(state.map((key, value) =>
              MapEntry(key.name, [value.modifiers, value.key]))));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reset() async {
    try {
      await _channel.invokeMethod<void>('unregisterAll');
      unavailable.clear();
      for (final entry in _defaults.entries) {
        try {
          if (!await _register(entry.key, entry.value)) {
            unavailable.add(entry.key);
          }
        } catch (_) {
          unavailable.add(entry.key);
        }
      }
      if (!mounted) return;
      state = Map.of(_defaults);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('toneharbor_shortcuts');
    } catch (_) {
      unavailable.addAll(HarborAction.values);
      if (mounted) state = Map.of(state);
    }
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'pressed' || call.arguments is! int) return;
    final index = (call.arguments as int) - 1;
    if (index < 0 || index >= HarborAction.values.length) return;
    final state = ref.read(audioPlayerProvider);
    final player = ref.read(audioPlayerProvider.notifier);
    switch (HarborAction.values[index]) {
      case HarborAction.playPause:
        if (state.currentSong != null) {
          if (state.isPlaying) {
            await player.pause();
          } else {
            await player.play();
          }
        }
      case HarborAction.next:
        await player.next();
      case HarborAction.previous:
        await player.previous();
      case HarborAction.volumeUp:
        await player.setVolume((state.volume + .05).clamp(0, 1));
      case HarborAction.volumeDown:
        await player.setVolume((state.volume - .05).clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}

String _actionName(HarborAction action) => switch (action) {
      HarborAction.playPause => 'Play / pause',
      HarborAction.next => 'Next track',
      HarborAction.previous => 'Previous track',
      HarborAction.volumeUp => 'Volume up',
      HarborAction.volumeDown => 'Volume down',
    };

Future<void> showHarborShortcuts(BuildContext context) => showDialog<void>(
    context: context, builder: (_) => const HarborShortcutEditor(dialog: true));

class HarborShortcutEditor extends ConsumerStatefulWidget {
  final bool dialog;
  final String query;
  const HarborShortcutEditor({super.key, this.dialog = false, this.query = ''});
  @override
  ConsumerState<HarborShortcutEditor> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends ConsumerState<HarborShortcutEditor> {
  HarborAction? _recording;
  String? _status;
  final _focus = FocusNode();
  String t(String s) => harborText(context, s);
  @override
  void didUpdateWidget(covariant HarborShortcutEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _recording = null;
      _status = null;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  int? _key(LogicalKeyboardKey key) {
    final label = key.keyLabel.toUpperCase();
    if (label.length == 1 && RegExp(r'^[A-Z0-9]$').hasMatch(label)) {
      return label.codeUnitAt(0);
    }
    final f = RegExp(r'^F(\d{1,2})$').firstMatch(label);
    if (f != null) {
      final n = int.parse(f[1]!);
      if (n >= 1 && n <= 12) return 0x6f + n;
    }
    if (key == LogicalKeyboardKey.arrowLeft) return 0x25;
    if (key == LogicalKeyboardKey.arrowUp) return 0x26;
    if (key == LogicalKeyboardKey.arrowRight) return 0x27;
    if (key == LogicalKeyboardKey.arrowDown) return 0x28;
    if (key == LogicalKeyboardKey.space) return 0x20;
    return null;
  }

  KeyEventResult _capture(FocusNode node, KeyEvent event) {
    if (_recording == null || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _recording = null);
      return KeyEventResult.handled;
    }
    final key = _key(event.logicalKey);
    final keyboard = HardwareKeyboard.instance;
    final modifiers = (keyboard.isAltPressed ? 1 : 0) |
        (keyboard.isControlPressed ? 2 : 0) |
        (keyboard.isShiftPressed ? 4 : 0);
    if (key == null || modifiers == 0) return KeyEventResult.handled;
    final action = _recording!;
    setState(() {
      _recording = null;
      _status = null;
    });
    ref
        .read(harborShortcutsProvider.notifier)
        .update(action, HarborBinding(modifiers, key))
        .then((ok) {
      if (mounted) {
        setState(() =>
            _status = t(ok ? 'Saved shortcut' : 'Shortcut is already in use.'));
      }
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final bindings = ref.watch(harborShortcutsProvider);
    final unavailable = ref.read(harborShortcutsProvider.notifier).unavailable;
    final query = widget.query.trim().toLowerCase();
    final actions = HarborAction.values
        .where((action) =>
            '${t(_actionName(action))} ${bindings[action]!.label}'
                .toLowerCase()
                .contains(query))
        .toList();
    final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('Use Ctrl, Alt or Shift with a key.'),
              style: const TextStyle(fontSize: 12, color: Colors.white60)),
          const SizedBox(height: 18),
          if (actions.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(t('No matching shortcuts'),
                    style: const TextStyle(color: Colors.white54))),
          for (final action in actions) ...[
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(t(_actionName(action)),
                            style: const TextStyle(fontSize: 13)),
                        if (unavailable.contains(action))
                          Text(t('Shortcut is already in use.'),
                              style: const TextStyle(
                                  color: Colors.orangeAccent, fontSize: 11)),
                      ])),
                  const SizedBox(width: 12),
                  OutlinedButton(
                      key: ValueKey('shortcut-binding-${action.name}'),
                      onPressed: () {
                        setState(() {
                          _recording = action;
                          _status = null;
                        });
                        _focus.requestFocus();
                      },
                      child: Text(
                          _recording == action
                              ? t('Press a key combination')
                              : bindings[action]!.label,
                          style: const TextStyle(fontSize: 12))),
                ])),
            const Divider(height: 1),
          ],
          if (_status != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_status!, style: const TextStyle(fontSize: 12))),
          const SizedBox(height: 18),
          Row(children: [
            TextButton(
                onPressed: () =>
                    ref.read(harborShortcutsProvider.notifier).reset(),
                child: Text(t('Reset defaults'))),
            if (widget.dialog) ...[
              const Spacer(),
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('Close')))
            ],
          ]),
        ]);
    return Focus(
        focusNode: _focus,
        onKeyEvent: _capture,
        child: widget.dialog
            ? AlertDialog(
                title: Text(t('Keyboard shortcuts')),
                content: SizedBox(
                    width: 560, child: SingleChildScrollView(child: content)),
              )
            : content);
  }
}
