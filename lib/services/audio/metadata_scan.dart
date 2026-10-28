import 'dart:async';
import 'dart:isolate';
import 'safe_metadata_reader.dart';

/// One library scan owns its worker. Invalidating a provider kills obsolete
/// synchronous metadata I/O, rather than merely ignoring its eventual result.
class MetadataScan {
  bool _cancelled = false;
  Isolate? _worker;
  Completer<List<List<Object>>>? _result;
  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _worker?.kill(priority: Isolate.beforeNextEvent);
    final result = _result;
    if (result != null && !result.isCompleted) result.complete([]);
  }

  Future<List<List<Object>>> read(List<String> paths) async {
    if (_cancelled || paths.isEmpty) return [];
    if (_result != null) throw StateError('Metadata scan already started');
    final replies = ReceivePort();
    final exits = ReceivePort();
    final exited =
        exits.first.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    final result = _result = Completer<List<List<Object>>>();
    final subscription = replies.listen((message) {
      if (result.isCompleted) return;
      if (message is List<List<Object>>) {
        result.complete(message);
      } else if (message == null) {
        result.complete([]);
      } else {
        result.completeError(StateError('Metadata worker failed: $message'));
      }
    });
    try {
      final starting = Isolate.spawn(_readMetadata, (replies.sendPort, paths),
              onError: replies.sendPort,
              onExit: exits.sendPort,
              debugName: 'harbor-metadata')
          .then((worker) {
        _worker = worker;
        if (_cancelled) worker.kill(priority: Isolate.beforeNextEvent);
      });
      // Observe startup and result errors immediately, including workers that
      // fail before Isolate.spawn has returned its handle.
      final values = await Future.wait<Object?>([starting, result.future],
          eagerError: true);
      return values[1] as List<List<Object>>;
    } finally {
      _worker?.kill(priority: Isolate.beforeNextEvent);
      if (_worker != null) {
        try {
          await exited.timeout(const Duration(seconds: 2));
        } on TimeoutException {/* Slow device I/O finishes safely. */}
      }
      _worker = null;
      if (!result.isCompleted) result.complete([]);
      await subscription.cancel();
      replies.close();
      exits.close();
    }
  }
}

Future<void> _readMetadata((SendPort, List<String>) input) async {
  final rows = <List<Object>>[];
  var processed = 0;
  for (final path in input.$2) {
    var title = '', artist = '';
    var durationMs = 0;
    var ok = false;
    try {
      final metadata = readAudioTags(path);
      title = metadata.title?.trim() ?? '';
      artist = metadata.artist?.trim() ?? '';
      durationMs = metadata.duration?.inMilliseconds ?? 0;
      ok = true;
    } catch (_) {}
    rows.add([path, title, artist, durationMs, ok]);
    // Deliver cancellation between files, after synchronous reader cleanup.
    if (++processed % 8 == 0) await Future<void>.delayed(Duration.zero);
  }
  input.$1.send(rows);
}
