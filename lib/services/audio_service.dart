import 'package:audioplayers/audioplayers.dart';

/// Singleton audio service. Tick for countdown taps, chime for celebration,
/// voice for per-step parent recordings.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final _tick = AudioPlayer();
  final _chime = AudioPlayer();
  final _voice = AudioPlayer();

  Future<void> playTick() async {
    try {
      await _tick.play(AssetSource('sounds/tick.wav'));
    } catch (_) {}
  }

  Future<void> playCelebration() async {
    try {
      await _chime.play(AssetSource('sounds/chime.wav'));
    } catch (_) {}
  }

  Future<void> playVoice(String path) async {
    try {
      await _voice.stop();
      await _voice.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> stopVoice() async {
    try {
      await _voice.stop();
    } catch (_) {}
  }
}
