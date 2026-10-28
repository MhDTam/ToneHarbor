import 'package:flutter/material.dart';
import 'harbor_audio_editor.dart';
import 'harbor_batch_studio.dart';

enum StudioMode { converter, editor }

class HarborStudio extends StatelessWidget {
  final StudioMode mode;
  final String? initialFile;
  final List<String>? initialFiles;
  const HarborStudio(
      {super.key, required this.mode, this.initialFile, this.initialFiles});
  @override
  Widget build(BuildContext context) => mode == StudioMode.converter
      ? HarborBatchStudio(initialFile: initialFile, initialFiles: initialFiles)
      : HarborAudioEditor(initialFile: initialFile);
}
