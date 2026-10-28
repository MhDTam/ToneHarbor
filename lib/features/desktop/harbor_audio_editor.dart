import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/audio_formats.dart';
import '../../services/audio/audio_player_service.dart';
import 'harbor_audio_effects.dart';
import 'harbor_editor_preview.dart';
import 'harbor_editor_timeline.dart';
import 'harbor_media_engine.dart';
import 'harbor_output_play.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';
import 'harbor_waveform.dart';

class HarborAudioEditor extends ConsumerStatefulWidget {
  final String? initialFile;
  final HarborMediaEngine? engine;
  final HarborEditorPreview? preview;
  const HarborAudioEditor(
      {super.key, this.initialFile, this.engine, this.preview});
  @override
  ConsumerState<HarborAudioEditor> createState() => _HarborAudioEditorState();
}

class _HarborAudioEditorState extends ConsumerState<HarborAudioEditor> {
  late final _engine = widget.engine ?? HarborMediaEngine();
  late final _preview = widget.preview ?? HarborEditorPreview();
  var _history = AudioEditHistory(const AudioEditDraft());
  final _start = TextEditingController(text: '0.000');
  final _end = TextEditingController(text: '0.000');
  String? _input, _status, _completedOutput, _previewPath;
  Object? _previewSignature;
  Directory? _temporary;
  Future<void>? _activeRender;
  double _duration = 0, _progress = 0;
  bool _busy = false, _renderingPreview = false, _failed = false;
  String _tab = 'Sound';
  int _operation = 0;
  AudioEditDraft get d => _history.value;
  String get _preset {
    if (d.bass == -3 &&
        d.mid == 2 &&
        d.treble == 1 &&
        d.denoise &&
        d.normalize) {
      return 'Speech';
    }
    if (d.denoise || d.normalize) return 'Custom';
    if (d.bass == 0 && d.mid == 0 && d.treble == 0) return 'Flat';
    if (d.bass == 3 && d.mid == 0 && d.treble == -2) return 'Warm';
    if (d.bass == -1 && d.mid == 1 && d.treble == 3) return 'Bright';
    return 'Custom';
  }

  String t(String key) => harborText(context, key);
  void _outputSettings({String? format, int? rate}) {
    final nextFormat = format ?? d.format;
    final rates = audioEditSampleRates(nextFormat);
    final nextRate =
        rates.contains(rate ?? d.sampleRate) ? rate ?? d.sampleRate : 48000;
    final bitrates = audioEditBitrates(nextFormat, nextRate);
    _change(d.copyWith(
        format: nextFormat,
        sampleRate: nextRate,
        bitrateKbps:
            bitrates.contains(d.bitrateKbps) ? d.bitrateKbps : bitrates.last));
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) _load(widget.initialFile!);
  }

  @override
  void didUpdateWidget(covariant HarborAudioEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFile != widget.initialFile &&
        widget.initialFile != null) {
      _load(widget.initialFile!);
    }
  }

  @override
  void dispose() {
    _operation++;
    _engine.cancel();
    _start.dispose();
    _end.dispose();
    final temporary = _temporary;
    unawaited(_preview.close().then((_) async {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete(recursive: true);
      }
    }).catchError((Object e) {
      debugPrint('Editor preview cleanup: $e');
    }));
    super.dispose();
  }

  void _syncTimes() {
    _start.text = d.start.toStringAsFixed(3);
    _end.text = d.end.toStringAsFixed(3);
  }

  void _change(AudioEditDraft next) {
    if (_busy || next.signature == d.signature) return;
    final timeChanged = next.start != d.start || next.end != d.end;
    _history.update(next);
    _previewSignature = null;
    if (_preview.playing.value) unawaited(_preview.pause());
    if (timeChanged) _syncTimes();
    setState(() {
      _status = null;
      _completedOutput = null;
    });
  }

  void _undo({bool redo = false}) {
    if (_busy) return;
    redo ? _history.redo() : _history.undo();
    _previewSignature = null;
    _syncTimes();
    unawaited(_preview.pause());
    setState(() {
      _status = null;
    });
  }

  Future<void> _load(String file) async {
    final operation = ++_operation;
    _engine.cancel();
    unawaited(_preview.pause());
    unawaited(_preview.restart());
    _preview.position.value = Duration.zero;
    setState(() {
      _input = file;
      _duration = 0;
      _busy = false;
      _status = null;
      _completedOutput = null;
      _previewSignature = null;
      _history = AudioEditHistory(const AudioEditDraft());
      _syncTimes();
    });
    try {
      final duration = await _engine.duration(file);
      if (!mounted || operation != _operation) return;
      setState(() {
        _duration = duration ?? 0;
        _history = AudioEditHistory(AudioEditDraft(end: _duration));
        _syncTimes();
        if (_duration <= 0) {
          _failed = true;
          _status = t('Could not read audio duration.');
        }
      });
    } catch (e) {
      if (mounted && operation == _operation) _message('$e', failed: true);
    }
  }

  Future<void> _pick() async {
    try {
      final selected = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          dialogTitle: t('Choose audio'),
          allowedExtensions: libraryAudioExtensions.toList());
      final path = selected?.files.single.path;
      if (path != null && mounted) await _load(path);
    } catch (e) {
      if (mounted) _message('$e', failed: true);
    }
  }

  void _message(String message, {bool failed = false}) => setState(() {
        _status = message;
        _failed = failed;
      });
  bool _applyTimes() {
    final start = double.tryParse(_start.text.replaceAll(',', '.'));
    final end = double.tryParse(_end.text.replaceAll(',', '.'));
    if (start == null ||
        end == null ||
        !start.isFinite ||
        !end.isFinite ||
        start < 0 ||
        end <= start ||
        end > _duration + .001) {
      _message(t('Selection must fit inside the source.'), failed: true);
      return false;
    }
    _change(d.copyWith(start: start, end: end.clamp(0, _duration)));
    return true;
  }

  Future<void> _audition() async {
    if (_busy || _input == null || !_applyTimes()) return;
    if (_preview.playing.value) {
      await _preview.pause();
      return;
    }
    if (_previewSignature == d.signature && _previewPath != null) {
      try {
        if (ref.read(audioPlayerProvider).isPlaying) {
          await ref.read(audioPlayerProvider.notifier).pause();
        }
        await _preview.play(_previewPath!);
      } catch (e) {
        if (mounted) _message('$e', failed: true);
      }
      return;
    }
    final operation = ++_operation, draft = d;
    setState(() {
      _busy = true;
      _renderingPreview = true;
      _failed = false;
      _progress = 0;
      _status = t('Rendering preview…');
    });
    try {
      if (ref.read(audioPlayerProvider).isPlaying) {
        await ref.read(audioPlayerProvider.notifier).pause();
      }
      _temporary ??=
          await Directory.systemTemp.createTemp('toneharbor-editor-');
      final output = p.join(_temporary!.path,
          'preview-${DateTime.now().microsecondsSinceEpoch}.wav');
      final end = math.min(draft.end, draft.start + 30 * draft.speed);
      await _render(draft, output, previewEnd: end);
      if (!mounted || operation != _operation) return;
      await _preview.play(output);
      if (!mounted || operation != _operation) return;
      final previous = _previewPath;
      _previewPath = output;
      _previewSignature = draft.signature;
      if (previous != null && previous != output) {
        try {
          await File(previous).delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _status = t('Preview ready');
          _progress = 1;
        });
      }
    } on MediaExportCancelled {
      if (mounted && operation == _operation) _message(t('Cancelled'));
    } catch (e) {
      if (mounted && operation == _operation) _message('$e', failed: true);
    } finally {
      if (mounted && operation == _operation) setState(() => _busy = false);
    }
  }

  Future<void> _render(AudioEditDraft draft, String output,
      {double? previewEnd}) async {
    final operation = _operation;
    final rendering = _engine.export(
        input: _input!,
        output: output,
        start: draft.start,
        end: previewEnd ?? draft.end,
        volume: draft.volume,
        fadeIn: draft.fadeIn,
        fadeOut:
            previewEnd != null && previewEnd < draft.end ? 0 : draft.fadeOut,
        spatial: draft.spatial,
        rotation: draft.rotation,
        depth: draft.depth,
        reverb: draft.reverb,
        effects: draft.effects,
        onProgress: (seconds) {
          if (!mounted || operation != _operation) return;
          final length =
              ((previewEnd ?? draft.end) - draft.start) / draft.speed;
          setState(() =>
              _progress = length > 0 ? (seconds / length).clamp(0, 1) : 0);
        });
    _activeRender = rendering;
    try {
      await rendering;
    } finally {
      if (identical(_activeRender, rendering)) _activeRender = null;
    }
  }

  Future<void> _cancel() async {
    _operation++;
    _engine.cancel();
    await _preview.pause();
    try {
      await _activeRender;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _busy = false;
        _status = t('Cancelled');
        _failed = false;
      });
    }
  }

  Future<void> _export() async {
    if (_busy || _input == null || !_applyTimes()) return;
    try {
      final selected = await FilePicker.platform.saveFile(
          dialogTitle: t('Export audio'),
          fileName: '${p.basenameWithoutExtension(_input!)}_edited.${d.format}',
          type: FileType.custom,
          allowedExtensions: [d.format]);
      if (selected == null || !mounted) return;
      final output = p.extension(selected).toLowerCase() == '.${d.format}'
          ? selected
          : '$selected.${d.format}';
      await _preview.pause();
      final operation = ++_operation, draft = d;
      setState(() {
        _busy = true;
        _renderingPreview = false;
        _failed = false;
        _status = t('Working…');
        _progress = 0;
        _completedOutput = null;
      });
      try {
        await _render(draft, output);
        if (mounted && operation == _operation) {
          setState(() {
            _completedOutput = output;
            _status = '${t('Saved successfully')}: $output';
            _progress = 1;
          });
        }
      } on MediaExportCancelled {
        if (mounted) _message(t('Cancelled'));
      } finally {
        if (mounted && operation == _operation) setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) _message('$e', failed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(audioPlayerProvider.select((p) => p.isPlaying), (_, playing) {
      if (playing && _preview.playing.value) unawaited(_preview.pause());
    });
    final theme = ref.watch(harborThemeProvider);
    final waveform = _input == null || _duration <= 0
        ? const AsyncData<List<double>>([])
        : ref.watch(waveformProvider(_input!));
    return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
              _undo(redo: true),
        },
        child: Focus(
            autofocus: true,
            child: LayoutBuilder(builder: (_, bounds) {
              final beside = bounds.maxWidth >= 940;
              return SingleChildScrollView(
                  key: const ValueKey('audio-editor-workspace'),
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 26),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(t('Audio editing'),
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(t('Shape your sound. Keep your original.'),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                              ])),
                          IconButton(
                              tooltip: t('Undo'),
                              onPressed:
                                  !_busy && _history.canUndo ? _undo : null,
                              icon: const Icon(Icons.undo_rounded, size: 20)),
                          IconButton(
                              tooltip: t('Redo'),
                              onPressed: !_busy && _history.canRedo
                                  ? () => _undo(redo: true)
                                  : null,
                              icon: const Icon(Icons.redo_rounded, size: 20)),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                              onPressed:
                                  _busy || _duration <= 0 ? null : _export,
                              icon: const Icon(Icons.file_upload_outlined,
                                  size: 17),
                              label: Text(t('Export audio')))
                        ]),
                        const SizedBox(height: 22),
                        _panel(theme,
                            child: Row(children: [
                              Icon(Icons.audio_file_outlined,
                                  color: theme.accent, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        _input == null
                                            ? t('No file selected')
                                            : p.basename(_input!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    const SizedBox(height: 5),
                                    Text(
                                        _input ??
                                            'MP3 · WAV · FLAC · M4A · AAC · OGG · OPUS · WMA',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11)),
                                  ])),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                  onPressed: _busy ? null : _pick,
                                  icon: const Icon(Icons.folder_open_rounded,
                                      size: 17),
                                  label: Text(t('Choose file')))
                            ])),
                        const SizedBox(height: 18),
                        if (beside)
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _workbench(theme, waveform)),
                                const SizedBox(width: 18),
                                SizedBox(width: 310, child: _inspector(theme)),
                              ])
                        else ...[
                          _workbench(theme, waveform),
                          const SizedBox(height: 18),
                          _inspector(theme)
                        ],
                      ]));
            })));
  }

  Widget _panel(HarborTheme theme, {required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: theme.border)),
      child: child);

  Widget _workbench(HarborTheme theme, AsyncValue<List<double>> waveform) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _panel(theme,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t('Waveform'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${editorTime(_duration)}  ·  ${t('Source')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11))
              ]),
              const SizedBox(height: 8),
              if (waveform.isLoading)
                const LinearProgressIndicator(minHeight: 1),
              HarborEditorTimeline(
                  samples: waveform.valueOrNull ?? const [],
                  duration: _duration,
                  start: d.start,
                  end: d.end,
                  speed: d.speed,
                  color: theme.accent,
                  position: _preview.position,
                  enabled: !_busy,
                  onChangeStart: _history.begin,
                  onChangeEnd: () => setState(_history.end),
                  onChanged: (range) {
                    if (range.end - range.start >= .01) {
                      _change(d.copyWith(start: range.start, end: range.end));
                    }
                  }),
              const SizedBox(height: 6),
              Row(children: [
                ValueListenableBuilder<bool>(
                    valueListenable: _preview.playing,
                    builder: (_, playing, __) => FilledButton.tonalIcon(
                        key: const ValueKey('editor-preview'),
                        onPressed: _busy || _duration <= 0 ? null : _audition,
                        icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20),
                        label: Text(t(
                            playing ? 'Pause preview' : 'Preview selection')))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(t('Preview up to 30 seconds'),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10))),
                ValueListenableBuilder<Duration>(
                    valueListenable: _preview.position,
                    builder: (_, value, __) => Text(
                        editorTime(value.inMilliseconds / 1000),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)))
              ]),
              ValueListenableBuilder<String?>(
                  valueListenable: _preview.error,
                  builder: (_, error, __) => error == null
                      ? const SizedBox()
                      : Text(error,
                          style: const TextStyle(color: Colors.redAccent))),
            ])),
        const SizedBox(height: 18),
        _panel(theme,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t('Selection'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                    onPressed: _busy
                        ? null
                        : () => _change(d.copyWith(start: 0, end: _duration)),
                    child: Text(t('Select all')))
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        key: const ValueKey('editor-start'),
                        controller: _start,
                        enabled: !_busy,
                        onSubmitted: (_) => _applyTimes(),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: t('Start (seconds)'), isDense: true))),
                const SizedBox(width: 14),
                Expanded(
                    child: TextField(
                        key: const ValueKey('editor-end'),
                        controller: _end,
                        enabled: !_busy,
                        onSubmitted: (_) => _applyTimes(),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: t('End (seconds)'), isDense: true)))
              ]),
              const SizedBox(height: 14),
              Text('${t('Output duration')}: ${editorTime(d.outputSeconds)}',
                  style: TextStyle(color: theme.accent, fontSize: 12)),
              const SizedBox(height: 18),
              _slider(
                  'Fade in',
                  d.fadeIn,
                  0,
                  10,
                  (v) => _change(d.copyWith(fadeIn: v)),
                  '${d.fadeIn.toStringAsFixed(1)} s'),
              _slider(
                  'Fade out',
                  d.fadeOut,
                  0,
                  10,
                  (v) => _change(d.copyWith(fadeOut: v)),
                  '${d.fadeOut.toStringAsFixed(1)} s'),
            ])),
        if (_status != null || _busy) ...[
          const SizedBox(height: 18),
          _panel(theme,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_busy) ...[
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 12)
                    ],
                    Text(_status ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                _failed ? Colors.redAccent : Colors.white70)),
                    if (_busy)
                      TextButton(
                          onPressed: _cancel,
                          child: Text(t(_renderingPreview
                              ? 'Cancel preview'
                              : 'Cancel'))),
                    if (_completedOutput != null)
                      HarborOutputPlayButton(path: _completedOutput!),
                  ]))
        ],
      ]);

  Widget _slider(String label, double value, double min, double max,
          ValueChanged<double> changed, String display) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Text(t(label), style: const TextStyle(fontSize: 12))),
              Text(display,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 11, color: Colors.white60))
            ]),
            SizedBox(
                height: 30,
                child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: SliderComponentShape.noOverlay),
                    child: Slider(
                        key: ValueKey('editor-control-$label'),
                        value: value.clamp(min, max),
                        min: min,
                        max: max,
                        onChangeStart: (_) => _history.begin(),
                        onChangeEnd: (_) => setState(_history.end),
                        onChanged: _busy ? null : changed))),
          ]));

  Widget _inspector(HarborTheme theme) => _panel(theme,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (final tab in ['Sound', 'Space', 'Output'])
            Expanded(
                child: InkWell(
                    key: ValueKey('editor-tab-$tab'),
                    onTap: () => setState(() => _tab = tab),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: _tab == tab
                                        ? theme.accent
                                        : theme.border,
                                    width: 2))),
                        child: Text(t(tab),
                            style: TextStyle(
                                fontSize: 12,
                                color: _tab == tab
                                    ? theme.accent
                                    : Colors.white60)))))
        ]),
        const SizedBox(height: 22),
        if (_tab == 'Sound') ...[
          _dropdown<String>('Preset', _preset,
              const ['Custom', 'Flat', 'Speech', 'Warm', 'Bright'], (v) {
            if (v == 'Flat') {
              _change(d.copyWith(
                  bass: 0,
                  mid: 0,
                  treble: 0,
                  denoise: false,
                  normalize: false));
            }
            if (v == 'Speech') {
              _change(d.copyWith(
                  bass: -3, mid: 2, treble: 1, denoise: true, normalize: true));
            }
            if (v == 'Warm') {
              _change(d.copyWith(
                  bass: 3,
                  mid: 0,
                  treble: -2,
                  normalize: false,
                  denoise: false));
            }
            if (v == 'Bright') {
              _change(d.copyWith(
                  bass: -1,
                  mid: 1,
                  treble: 3,
                  normalize: false,
                  denoise: false));
            }
          }),
          _slider(
              'Gain',
              d.gainDb,
              -24,
              12,
              (v) => _change(d.copyWith(gainDb: v)),
              '${d.gainDb.toStringAsFixed(1)} dB'),
          _slider('Speed', d.speed, .5, 2, (v) => _change(d.copyWith(speed: v)),
              '${d.speed.toStringAsFixed(2)}×'),
          const Divider(),
          const SizedBox(height: 12),
          _slider('Bass', d.bass, -12, 12, (v) => _change(d.copyWith(bass: v)),
              '${d.bass.toStringAsFixed(1)} dB'),
          _slider('Mid', d.mid, -12, 12, (v) => _change(d.copyWith(mid: v)),
              '${d.mid.toStringAsFixed(1)} dB'),
          _slider(
              'Treble',
              d.treble,
              -12,
              12,
              (v) => _change(d.copyWith(treble: v)),
              '${d.treble.toStringAsFixed(1)} dB'),
          _switch('Normalize loudness', d.normalize,
              (v) => _change(d.copyWith(normalize: v))),
          _switch('Reduce steady noise', d.denoise,
              (v) => _change(d.copyWith(denoise: v))),
        ],
        if (_tab == 'Space') ...[
          _switch(
              '8D audio',
              d.spatial,
              (v) => _change(
                  d.copyWith(spatial: v, channels: v ? 2 : d.channels))),
          const SizedBox(height: 12),
          Text(t('Rotate the sound between left and right.'),
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          if (d.spatial) ...[
            const SizedBox(height: 20),
            _slider(
                'Rotation speed',
                d.rotation,
                .01,
                1,
                (v) => _change(d.copyWith(rotation: v)),
                '${d.rotation.toStringAsFixed(2)} Hz'),
            _slider(
                'Stereo depth',
                d.depth,
                0,
                1,
                (v) => _change(d.copyWith(depth: v)),
                '${(d.depth * 100).round()}%'),
            _slider(
                'Reverb',
                d.reverb,
                0,
                1,
                (v) => _change(d.copyWith(reverb: v)),
                '${(d.reverb * 100).round()}%'),
          ],
        ],
        if (_tab == 'Output') ...[
          _dropdown<String>(
              'Output format',
              d.format,
              const ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'opus'],
              (v) => _outputSettings(format: v),
              display: (v) => v.toUpperCase()),
          _dropdown<int>('Sample rate', d.sampleRate,
              audioEditSampleRates(d.format), (v) => _outputSettings(rate: v),
              display: (v) => '${v / 1000} kHz'),
          _dropdown<String>(
              'Channels',
              d.channels == null
                  ? 'Source'
                  : d.channels == 1
                      ? 'Mono'
                      : 'Stereo',
              d.spatial ? const ['Stereo'] : const ['Source', 'Mono', 'Stereo'],
              (v) => _change(d.copyWith(
                  channels: v == 'Mono' ? 1 : 2,
                  sourceChannels: v == 'Source'))),
          if (d.format == 'ogg')
            Text(t('Variable bitrate · quality 5'),
                style: TextStyle(color: theme.accent, fontSize: 12))
          else if (d.format != 'wav' && d.format != 'flac')
            _dropdown<int>(
                'Bitrate',
                d.bitrateKbps,
                audioEditBitrates(d.format, d.sampleRate),
                (v) => _change(d.copyWith(bitrateKbps: v)),
                display: (v) => '$v kbps')
          else
            Text(t('Lossless output'),
                style: TextStyle(color: theme.accent, fontSize: 12)),
        ],
        const SizedBox(height: 18),
        const Divider(),
        TextButton.icon(
            onPressed:
                _busy ? null : () => _change(AudioEditDraft(end: _duration)),
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: Text(t('Reset edits'))),
        const SizedBox(height: 4),
        Text(t('Export saves a new file.'),
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]));
  Widget _switch(String label, bool value, ValueChanged<bool> changed) =>
      Row(children: [
        Expanded(child: Text(t(label), style: const TextStyle(fontSize: 12))),
        Switch(value: value, onChanged: _busy ? null : changed),
      ]);
  Widget _dropdown<T>(
          String label, T value, List<T> items, ValueChanged<T> changed,
          {String Function(T)? display}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t(label),
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 7),
            DropdownButtonFormField<T>(
                key: ValueKey('editor-$label-$value'),
                initialValue: value,
                isExpanded: true,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
                items: items
                    .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(display?.call(item) ?? t('$item'),
                            style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) changed(value);
                      }),
          ]));
}
