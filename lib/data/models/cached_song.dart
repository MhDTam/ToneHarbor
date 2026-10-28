import 'package:isar_community/isar.dart';

part 'cached_song.g.dart';

@collection
class CachedSong {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String path;

  late String title;
  late String artist;
  late String album;
  late int durationMs;
  late int dateAddedSeconds;
  late int lastModifiedMs;
}
