import 'package:isar_community/isar.dart';

part 'conversion_history_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Conversion History – stored in Isar
// ─────────────────────────────────────────────────────────────────────────────
@collection
class ConversionHistoryModel {
  Id id = Isar.autoIncrement;

  late String sourceVideoPath;
  late String sourceVideoName;
  late String outputAudioPath;
  late String outputAudioName;
  late DateTime timestamp;
  late int fileSizeBytes;

  ConversionHistoryModel();

  ConversionHistoryModel.create({
    required this.sourceVideoPath,
    required this.sourceVideoName,
    required this.outputAudioPath,
    required this.outputAudioName,
    required this.fileSizeBytes,
  }) {
    timestamp = DateTime.now();
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
