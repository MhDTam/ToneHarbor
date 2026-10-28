import 'package:isar_community/isar.dart';

part 'playlist_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Playlist Model – stored in Isar
// ─────────────────────────────────────────────────────────────────────────────
@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;

  late String name;
  List<int> songIds = []; // on_audio_query song IDs
  late DateTime createdAt;

  PlaylistModel();

  PlaylistModel.create({required this.name}) {
    createdAt = DateTime.now();
  }
}
