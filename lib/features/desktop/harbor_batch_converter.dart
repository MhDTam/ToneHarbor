import 'dart:io';
import 'package:path/path.dart' as p;
import 'harbor_media_engine.dart';

enum BatchJobStatus { queued, converting, completed, failed, cancelled }

class BatchAudioJob {
  final String input;
  final String? output;
  final BatchJobStatus status;
  final double progress;
  final String? error;
  const BatchAudioJob(this.input,
      {this.output,
      this.status = BatchJobStatus.queued,
      this.progress = 0,
      this.error});
}

/// Sequential encoding keeps the UI responsive and avoids oversubscribing the
/// CPU. Each failure is reported independently, and existing files are kept.
class HarborBatchConverter {
  final HarborMediaEngine _engine;
  bool _cancelled = false;
  bool _running = false;
  HarborBatchConverter({HarborMediaEngine? engine})
      : _engine = engine ?? HarborMediaEngine();

  void cancel() {
    _cancelled = true;
    _engine.cancel();
  }

  Future<List<BatchAudioJob>> convert({
    required List<String> inputs,
    required String outputDirectory,
    required String format,
    required void Function(List<BatchAudioJob>) onUpdate,
  }) async {
    if (_running) throw StateError('A batch is already running');
    if (!{'mp3', 'm4a', 'wav', 'flac', 'ogg', 'opus'}.contains(format)) {
      throw ArgumentError('Unsupported output format');
    }
    _running = true;
    _cancelled = false;
    final jobs = inputs.map((file) => BatchAudioJob(file)).toList();
    void notify() => onUpdate(List.unmodifiable(jobs));
    try {
      if (!await Directory(outputDirectory).exists()) {
        throw const FileSystemException('Output folder does not exist');
      }
      notify();
      for (var i = 0; i < jobs.length; i++) {
        if (_cancelled) break;
        final input = jobs[i].input;
        String? output;
        try {
          final base = '${p.basenameWithoutExtension(input)}_toneharbor';
          var destination = p.join(outputDirectory, '$base.$format');
          var suffix = 2;
          while (await FileSystemEntity.type(destination) !=
              FileSystemEntityType.notFound) {
            destination =
                p.join(outputDirectory, '$base (${suffix++}).$format');
          }
          output = destination;
          jobs[i] = BatchAudioJob(input,
              output: output, status: BatchJobStatus.converting);
          notify();
          final duration = await _engine.duration(input);
          if (_cancelled) break;
          await _engine.export(
              input: input,
              output: destination,
              onProgress: (seconds) {
                final progress = duration != null && duration > 0
                    ? (seconds / duration).clamp(0.0, .99)
                    : 0.0;
                if (progress - jobs[i].progress >= .01) {
                  jobs[i] = BatchAudioJob(input,
                      output: output,
                      status: BatchJobStatus.converting,
                      progress: progress);
                  notify();
                }
              });
          jobs[i] = BatchAudioJob(input,
              output: output, status: BatchJobStatus.completed, progress: 1);
        } on MediaExportCancelled {
          _cancelled = true;
          break;
        } catch (e) {
          jobs[i] = BatchAudioJob(input,
              output: output, status: BatchJobStatus.failed, error: '$e');
        }
        notify();
      }
      if (_cancelled) {
        for (var i = 0; i < jobs.length; i++) {
          if (jobs[i].status == BatchJobStatus.queued ||
              jobs[i].status == BatchJobStatus.converting) {
            jobs[i] =
                BatchAudioJob(jobs[i].input, status: BatchJobStatus.cancelled);
          }
        }
        notify();
      }
      return List.unmodifiable(jobs);
    } finally {
      _running = false;
    }
  }
}
