import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/platform_utils.dart';

enum AudioOutputType {
  auto,
  speaker,
  headset,
}

final audioRoutingProvider =
    StateNotifierProvider<AudioRoutingNotifier, AudioOutputType>((ref) {
  return AudioRoutingNotifier();
});

class AudioRoutingNotifier extends StateNotifier<AudioOutputType> {
  AudioRoutingNotifier() : super(AudioOutputType.auto) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('audio_output_type') ?? 0;
    if (index < AudioOutputType.values.length) {
      state = AudioOutputType.values[index];
    }
    _applyRouting();
  }

  Future<void> setOutputType(AudioOutputType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('audio_output_type', type.index);
    _applyRouting();
  }

  static const _channel =
      MethodChannel('com.musiconvert.mp3noads/audio_routing');

  Future<void> _applyRouting() async {
    if (!isMobile) return;

    try {
      await _channel.invokeMethod('setAudioOutput', {
        'mode': state.name, // "auto", "speaker", or "headset"
      });
    } catch (e) {
      // Audio routing failed – silently ignore
    }
  }
}
