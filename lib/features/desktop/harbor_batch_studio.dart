import 'dart:math' as math;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'harbor_batch_converter.dart';
import 'harbor_strings.dart';
import 'harbor_output_play.dart';

class HarborBatchStudio extends StatefulWidget {
  final String? initialFile;
  final List<String>? initialFiles;
  const HarborBatchStudio({super.key, this.initialFile, this.initialFiles});
  @override
  State<HarborBatchStudio> createState() => _HarborBatchStudioState();
}

class _HarborBatchStudioState extends State<HarborBatchStudio> {
  final _converter = HarborBatchConverter();
  List<BatchAudioJob> _jobs = [];
  String _format = 'mp3';
  String? _outputDirectory, _error;
  bool _busy = false, _stopping = false, _choosingOutput = false;
  String t(String value) => harborText(context, value);

  @override
  void initState() {
    super.initState();
    _jobs = {
      ...?widget.initialFiles,
      if (widget.initialFile != null) widget.initialFile!
    }.map(BatchAudioJob.new).toList();
  }

  @override
  void dispose() {
    _converter.cancel();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'mp4',
          'mkv',
          'mov',
          'webm',
          'avi',
          'm4v',
          'wmv',
          '3gp',
          'mp3',
          'wav',
          'm4a',
          'flac',
          'ogg',
          'opus',
          'aac',
          'wma'
        ],
      );
      if (result == null || !mounted) return;
      final unique = <String>{for (final job in _jobs) _key(job.input)};
      setState(() {
        _error = null;
        _jobs = [
          ..._jobs,
          for (final file in result.files)
            if (file.path != null && unique.add(_key(file.path!)))
              BatchAudioJob(file.path!)
        ];
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  String _key(String file) =>
      Platform.isWindows ? p.normalize(file).toLowerCase() : p.normalize(file);

  Future<void> _convert() async {
    if (_jobs.isEmpty || _busy || _choosingOutput) return;
    setState(() => _choosingOutput = true);
    try {
      final folder = await FilePicker.platform
          .getDirectoryPath(dialogTitle: t('Choose output folder'));
      if (folder == null || !mounted) return;
      setState(() {
        _busy = true;
        _stopping = false;
        _error = null;
        _outputDirectory = folder;
      });
      await _converter.convert(
        inputs: _jobs.map((job) => job.input).toList(),
        outputDirectory: folder,
        format: _format,
        onUpdate: (jobs) {
          if (mounted) setState(() => _jobs = jobs);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stopping = false;
          _choosingOutput = false;
        });
      }
    }
  }

  String _status(BatchAudioJob job) => t(switch (job.status) {
        BatchJobStatus.queued => 'Queued',
        BatchJobStatus.converting => 'Converting',
        BatchJobStatus.completed => 'Completed',
        BatchJobStatus.failed => 'Failed',
        BatchJobStatus.cancelled => 'Cancelled',
      });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final done =
        _jobs.where((job) => job.status == BatchJobStatus.completed).length;
    final failed =
        _jobs.where((job) => job.status == BatchJobStatus.failed).length;
    final cancelled =
        _jobs.where((job) => job.status == BatchJobStatus.cancelled).length;
    final progress = _jobs.isEmpty
        ? 0.0
        : _jobs.fold<double>(
                0,
                (value, job) =>
                    value +
                    (job.status == BatchJobStatus.failed ? 1 : job.progress)) /
            _jobs.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Conversion'),
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(t('Convert multiple video or audio files in one batch.'),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 24),
                    _panel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton.tonalIcon(
                                    onPressed: _busy ? null : _pick,
                                    icon:
                                        const Icon(Icons.add_rounded, size: 19),
                                    label: Text(t(_jobs.isEmpty
                                        ? 'Choose files'
                                        : 'Add files'))),
                                if (_jobs.isNotEmpty)
                                  OutlinedButton(
                                      onPressed: _busy
                                          ? null
                                          : () => setState(() => _jobs = []),
                                      child: Text(t('Clear list'))),
                                Text(
                                    '${_jobs.length} ${t(_jobs.length == 1 ? 'file' : 'files')}',
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12)),
                              ]),
                          const SizedBox(height: 16),
                          if (_jobs.isEmpty)
                            SizedBox(
                                height: 116,
                                child: Center(
                                    child: Text(
                                        t(
                                            'Select files to build your conversion queue.'),
                                        style: const TextStyle(
                                            color: Colors.white60))))
                          else
                            SizedBox(
                                height: math.min(300, _jobs.length * 64.0),
                                child: ListView.builder(
                                  itemCount: _jobs.length,
                                  itemExtent: 64,
                                  itemBuilder: (_, index) {
                                    final job = _jobs[index];
                                    return Row(children: [
                                      SizedBox(
                                          width: 30,
                                          child: Text('${index + 1}',
                                              style: const TextStyle(
                                                  color: Colors.white38))),
                                      Icon(
                                          job.status == BatchJobStatus.completed
                                              ? Icons.check_circle_outline
                                              : job.status ==
                                                      BatchJobStatus.failed
                                                  ? Icons.error_outline
                                                  : Icons.audio_file_outlined,
                                          color: job.status ==
                                                  BatchJobStatus.failed
                                              ? Colors.redAccent
                                              : accent,
                                          size: 23),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: Tooltip(
                                              message: job.error ??
                                                  job.output ??
                                                  job.input,
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(p.basename(job.input),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 14)),
                                                    const SizedBox(height: 5),
                                                    if (job.status ==
                                                        BatchJobStatus
                                                            .converting)
                                                      LinearProgressIndicator(
                                                          value: job.progress >
                                                                  0
                                                              ? job.progress
                                                              : null,
                                                          minHeight: 2)
                                                    else
                                                      Text(
                                                          job
                                                                  .output ??
                                                              job.input,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white38,
                                                                  fontSize:
                                                                      10)),
                                                  ]))),
                                      const SizedBox(width: 14),
                                      SizedBox(
                                          width: 92,
                                          child: Text(_status(job),
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  color: job.status ==
                                                          BatchJobStatus.failed
                                                      ? Colors.redAccent
                                                      : Colors.white60,
                                                  fontSize: 11))),
                                      if (job.status ==
                                              BatchJobStatus.completed &&
                                          job.output != null)
                                        HarborOutputPlayButton(
                                            path: job.output!),
                                      IconButton(
                                          tooltip: t('Remove'),
                                          onPressed: _busy
                                              ? null
                                              : () => setState(() =>
                                                  _jobs = List.of(_jobs)
                                                    ..removeAt(index)),
                                          icon: const Icon(Icons.close_rounded,
                                              size: 17)),
                                    ]);
                                  },
                                )),
                        ])),
                    const SizedBox(height: 18),
                    _panel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(t('Output format'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final format in [
                              'mp3',
                              'm4a',
                              'wav',
                              'flac',
                              'ogg',
                              'opus'
                            ])
                              ChoiceChip(
                                  label: Text(format.toUpperCase()),
                                  selected: _format == format,
                                  onSelected: _busy
                                      ? null
                                      : (_) => setState(() => _format = format))
                          ]),
                          const SizedBox(height: 14),
                          Text(t('Each file is saved separately. Existing files are kept.'),
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ])),
                    const SizedBox(height: 20),
                    if (_busy) ...[
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 14)
                    ],
                    Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                              onPressed:
                                  _busy || _choosingOutput || _jobs.isEmpty
                                      ? null
                                      : _convert,
                              icon:
                                  const Icon(Icons.transform_rounded, size: 19),
                              label: Text(t('Convert all'))),
                          if (_busy)
                            OutlinedButton.icon(
                                onPressed: _stopping
                                    ? null
                                    : () {
                                        setState(() => _stopping = true);
                                        _converter.cancel();
                                      },
                                icon: const Icon(Icons.stop_rounded, size: 18),
                                label: Text(
                                    t(_stopping ? 'Stopping…' : 'Stop batch'))),
                          if (done + failed + cancelled > 0)
                            Text(
                                '$done ${t('Completed')} · $failed ${t('Failed')} · $cancelled ${t('Cancelled')}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                        ]),
                    if (_outputDirectory != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SelectableText(
                              '${t('Output folder')}: $_outputDirectory',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12))),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SelectableText(_error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 12))),
                  ]))),
    );
  }

  Widget _panel({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(12)),
      child: child);
}
