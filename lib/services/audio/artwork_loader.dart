import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

class _ArtworkEntry {
  final Object version;
  final Uint8List? bytes;
  _ArtworkEntry(this.version, this.bytes);
}

class _ArtworkJob {
  final String path;
  final result = Completer<Uint8List?>();
  bool cancelled = false;
  _ArtworkJob(this.path);
}

/// Bounded disk readers and LRU storage, including files without embedded art.
/// A fresh file version prevents stale covers after metadata edits.
class ArtworkLoader {
  final Future<Uint8List?> Function(String) read;
  final Future<Object> Function(String) version;
  final int concurrency, maxEntries, maxBytes;
  final _cache = <String, _ArtworkEntry>{};
  final _pending = <String, _ArtworkJob>{};
  final _waiting = Queue<_ArtworkJob>();
  int _active = 0, _bytes = 0;
  bool _closed = false;
  ArtworkLoader(
      {required this.read,
      required this.version,
      this.concurrency = 2,
      this.maxEntries = 128,
      this.maxBytes = 8 * 1024 * 1024})
      : assert(concurrency > 0),
        assert(maxEntries > 0),
        assert(maxBytes > 0);
  int get cachedBytes => _bytes;
  int get cachedEntries => _cache.length;

  Future<Uint8List?> load(String path) {
    if (_closed) return Future.value(null);
    final existing = _pending[path];
    if (existing != null) return existing.result.future;
    final job = _ArtworkJob(path);
    _pending[path] = job;
    _waiting.add(job);
    _pump();
    return job.result.future;
  }

  void cancel(String path, Future<Uint8List?> request) {
    final job = _pending[path];
    if (job == null || !identical(job.result.future, request)) return;
    job.cancelled = true;
    _pending.remove(path);
    _waiting.remove(job);
    if (!job.result.isCompleted) job.result.complete(null);
  }

  void _pump() {
    while (!_closed && _active < concurrency && _waiting.isNotEmpty) {
      final job = _waiting.removeFirst();
      if (job.cancelled) continue;
      _active++;
      unawaited(_run(job));
    }
  }

  Future<void> _run(_ArtworkJob job) async {
    Uint8List? bytes;
    try {
      final stamp = await version(job.path);
      if (_closed || job.cancelled) return;
      final cached = _cache.remove(job.path);
      if (cached != null) _bytes -= cached.bytes?.length ?? 0;
      if (cached != null && cached.version == stamp) {
        bytes = cached.bytes;
      } else {
        bytes = await read(job.path);
      }
      if (_closed || job.cancelled) return;
      if ((bytes?.length ?? 0) <= maxBytes) {
        _cache[job.path] = _ArtworkEntry(stamp, bytes);
        _bytes += bytes?.length ?? 0;
        while (_cache.length > maxEntries || _bytes > maxBytes) {
          final oldest = _cache.remove(_cache.keys.first)!;
          _bytes -= oldest.bytes?.length ?? 0;
        }
      }
    } catch (_) {
      // Unreadable/unsupported artwork recovers to the normal UI fallback.
    } finally {
      if (!job.result.isCompleted) job.result.complete(bytes);
      if (identical(_pending[job.path], job)) _pending.remove(job.path);
      _active--;
      _pump();
    }
  }

  void close() {
    _closed = true;
    for (final job in _pending.values) {
      job.cancelled = true;
      if (!job.result.isCompleted) job.result.complete(null);
    }
    _pending.clear();
    _waiting.clear();
    _cache.clear();
    _bytes = 0;
  }
}
