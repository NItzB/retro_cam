import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _shutterPlayer = AudioPlayer();
  final AudioPlayer _windPlayer = AudioPlayer();

  // Preload sounds for lower latency
  Future<void> initialize() async {
    // Note: AudioPlayers usually loads on demand, but we can set the source early
    await _shutterPlayer.setSource(AssetSource('sounds/shutter.wav'));
    await _windPlayer.setSource(AssetSource('sounds/wind.wav'));
  }

  Future<void> playShutterSound() async {
    if (_shutterPlayer.state == PlayerState.playing) {
      await _shutterPlayer.stop();
    }
    await _shutterPlayer.play(AssetSource('sounds/shutter.wav'));
  }

  Future<void> playWindSound() async {
    if (_windPlayer.state == PlayerState.playing) {
       await _windPlayer.stop();
    }
    await _windPlayer.play(AssetSource('sounds/wind.wav'));
  }
  
  void dispose() {
    _shutterPlayer.dispose();
    _windPlayer.dispose();
  }
}
