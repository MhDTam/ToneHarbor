// ─────────────────────────────────────────────────────────────────────────────
// Song Model – lightweight, no Isar annotations (sourced from on_audio_query)
// ─────────────────────────────────────────────────────────────────────────────
class SongModel {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String data; // file path
  final int duration; // ms
  final int dateAdded; // timestamp seconds
  final int albumId; // MediaStore album id (0 when unknown)
  final String? artworkPath;
  bool isFavorite;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.data,
    required this.duration,
    required this.dateAdded,
    this.albumId = 0,
    this.artworkPath,
    this.isFavorite = false,
  });

  String get durationFormatted {
    final d = Duration(milliseconds: duration);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  SongModel copyWith({bool? isFavorite}) {
    return SongModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      data: data,
      duration: duration,
      dateAdded: dateAdded,
      albumId: albumId,
      artworkPath: artworkPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
