import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

typedef AudioTags = ({
  String? title,
  String? artist,
  Duration? duration,
  Uint8List? artwork
});

/// Some parser failure paths do not close their own reader. Own every opened
/// handle so malformed/unsupported tags never leave a Windows file locked.
AudioTags readAudioTags(String path, {bool includeArtwork = false}) {
  final file = _TrackedAudioFile(File(path));
  try {
    final metadata = readMetadata(file, getImage: includeArtwork);
    return (
      title: metadata.title,
      artist: metadata.artist,
      duration: metadata.duration,
      artwork: metadata.pictures.isEmpty
          ? null
          : Uint8List.fromList(metadata.pictures.first.bytes)
    );
  } finally {
    file.closeReaders();
  }
}

class _TrackedAudioFile implements File {
  final File source;
  final _readers = <RandomAccessFile>[];
  _TrackedAudioFile(this.source);
  @override
  String get path => source.path;
  @override
  Uri get uri => source.uri;
  @override
  File get absolute => source.absolute;
  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    final reader = source.openSync(mode: mode);
    _readers.add(reader);
    return reader;
  }

  void closeReaders() {
    for (final reader in _readers) {
      try {
        reader.closeSync();
      } on FileSystemException {/* Already closed by parser. */}
    }
    _readers.clear();
  }

  @override
  String toString() => source.toString();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
