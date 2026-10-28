import 'package:isar_community/isar.dart';

part 'action_history_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Action History – unified model for Video Conversion & Audio Editing
// ─────────────────────────────────────────────────────────────────────────────
@collection
class ActionHistoryModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String type; // 'conversion' or 'editing'

  late String sourcePath;
  late String outputPath;
  late String title;

  @Index(type: IndexType.value)
  late DateTime timestamp;

  late bool isSuccess;
  String? error;

  // Storage size in bytes
  late int fileSizeBytes;

  ActionHistoryModel();

  ActionHistoryModel.create({
    required this.type,
    required this.sourcePath,
    required this.outputPath,
    required this.title,
    required this.fileSizeBytes,
    this.isSuccess = true,
    this.error,
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
