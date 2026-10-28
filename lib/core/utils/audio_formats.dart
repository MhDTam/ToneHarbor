/// Audio-only library inputs. Video containers belong to the converter.
const libraryAudioExtensions = <String>{
  'mp3',
  'm4a',
  'wav',
  'flac',
  'ogg',
  'aac',
  'wma',
  'opus',
};

bool isLibraryAudioFile(String file) {
  final name = file.replaceAll('\\', '/').split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 &&
      libraryAudioExtensions.contains(name.substring(dot + 1).toLowerCase());
}
