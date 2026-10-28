import 'dart:math' as math;

List<int> audioEditSampleRates(String format) => switch (format) {
      'mp3' => const [22050, 44100, 48000],
      'opus' => const [48000],
      _ => const [22050, 44100, 48000, 96000],
    };
List<int> audioEditBitrates(String format, int rate) =>
    format == 'mp3' && rate == 22050
        ? const [64, 96, 128, 160]
        : const [64, 96, 128, 160, 192, 256, 320];

class AudioEditEffects {
  final double speed, bass, mid, treble;
  final bool normalize, denoise;
  final int? channels, sampleRate, bitrateKbps;
  const AudioEditEffects(
      {this.speed = 1,
      this.bass = 0,
      this.mid = 0,
      this.treble = 0,
      this.normalize = false,
      this.denoise = false,
      this.channels,
      this.sampleRate,
      this.bitrateKbps});

  void validate() {
    if (!speed.isFinite ||
        speed < .5 ||
        speed > 2 ||
        [bass, mid, treble].any((v) => !v.isFinite || v < -12 || v > 12) ||
        (channels != null && channels != 1 && channels != 2) ||
        (sampleRate != null &&
            ![22050, 44100, 48000, 96000].contains(sampleRate)) ||
        (bitrateKbps != null &&
            ![64, 96, 128, 160, 192, 256, 320].contains(bitrateKbps))) {
      throw ArgumentError('Invalid audio effect settings');
    }
  }

  List<String> get filters => [
        if (speed != 1) 'atempo=$speed',
        if (denoise) 'afftdn=nf=-25',
        if (bass != 0) 'bass=g=$bass:f=120',
        if (mid != 0) 'equalizer=f=1000:t=q:w=1:g=$mid',
        if (treble != 0) 'treble=g=$treble:f=3000',
        if (normalize) 'loudnorm=I=-16:TP=-1.5:LRA=11',
      ];
}

/// Small immutable edit history; it never stores decoded audio or waveform data.
class AudioEditDraft {
  final double start, end, gainDb, fadeIn, fadeOut, speed, bass, mid, treble;
  final bool normalize, denoise, spatial;
  final double rotation, depth, reverb;
  final String format;
  final int sampleRate, bitrateKbps;
  final int? channels;
  const AudioEditDraft(
      {this.start = 0,
      this.end = 0,
      this.gainDb = 0,
      this.fadeIn = 0,
      this.fadeOut = 0,
      this.speed = 1,
      this.bass = 0,
      this.mid = 0,
      this.treble = 0,
      this.normalize = false,
      this.denoise = false,
      this.spatial = false,
      this.rotation = .125,
      this.depth = 1,
      this.reverb = .3,
      this.format = 'mp3',
      this.sampleRate = 48000,
      this.bitrateKbps = 192,
      this.channels});
  double get outputSeconds => math.max(0, end - start) / speed;
  double get volume => math.pow(10, gainDb / 20).toDouble();
  Object get signature => (
        start,
        end,
        gainDb,
        fadeIn,
        fadeOut,
        speed,
        bass,
        mid,
        treble,
        normalize,
        denoise,
        spatial,
        rotation,
        depth,
        reverb,
        format,
        sampleRate,
        bitrateKbps,
        channels
      );
  AudioEditEffects get effects => AudioEditEffects(
      speed: speed,
      bass: bass,
      mid: mid,
      treble: treble,
      normalize: normalize,
      denoise: denoise,
      channels: channels,
      sampleRate: sampleRate,
      bitrateKbps: bitrateKbps);
  AudioEditDraft copyWith(
          {double? start,
          double? end,
          double? gainDb,
          double? fadeIn,
          double? fadeOut,
          double? speed,
          double? bass,
          double? mid,
          double? treble,
          bool? normalize,
          bool? denoise,
          bool? spatial,
          double? rotation,
          double? depth,
          double? reverb,
          String? format,
          int? sampleRate,
          int? bitrateKbps,
          int? channels,
          bool sourceChannels = false}) =>
      AudioEditDraft(
          start: start ?? this.start,
          end: end ?? this.end,
          gainDb: gainDb ?? this.gainDb,
          fadeIn: fadeIn ?? this.fadeIn,
          fadeOut: fadeOut ?? this.fadeOut,
          speed: speed ?? this.speed,
          bass: bass ?? this.bass,
          mid: mid ?? this.mid,
          treble: treble ?? this.treble,
          normalize: normalize ?? this.normalize,
          denoise: denoise ?? this.denoise,
          spatial: spatial ?? this.spatial,
          rotation: rotation ?? this.rotation,
          depth: depth ?? this.depth,
          reverb: reverb ?? this.reverb,
          format: format ?? this.format,
          sampleRate: sampleRate ?? this.sampleRate,
          bitrateKbps: bitrateKbps ?? this.bitrateKbps,
          channels: sourceChannels ? null : channels ?? this.channels);
}

class AudioEditHistory {
  AudioEditDraft value;
  final int limit;
  final _undo = <AudioEditDraft>[], _redo = <AudioEditDraft>[];
  AudioEditDraft? _gesture;
  AudioEditHistory(this.value, {this.limit = 32});
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get retainedEdits => _undo.length + _redo.length;
  void begin() => _gesture ??= value;
  void end() {
    final original = _gesture;
    _gesture = null;
    if (original != null && original.signature != value.signature) {
      _remember(original);
    }
  }

  void _remember(AudioEditDraft previous) {
    _undo.add(previous);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  void update(AudioEditDraft next) {
    if (next.signature == value.signature) return;
    if (_gesture == null) _remember(value);
    value = next;
  }

  void undo() {
    end();
    if (!canUndo) return;
    _redo.add(value);
    value = _undo.removeLast();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(value);
    value = _redo.removeLast();
  }
}
