/// Base class for the audio handler.
/// On mobile, the actual handler extends BaseAudioHandler from audio_service.
/// On desktop, it's just a plain Dart class.
/// Both are unified through ToneHarborAudioHandler in audio_handler.dart.
abstract class PlatformAudioHandler {}
