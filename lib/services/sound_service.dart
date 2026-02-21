import 'package:flutter/services.dart';

class SoundService {
  static const MethodChannel _audioChannel = MethodChannel('retro_cam_audio');

  Future<void> initialize() async {
    // Handled natively
  }

  Future<void> playShutterSound() async {
    try {
      await _audioChannel.invokeMethod('playSystemSound', {'soundName': 'shutter'});
    } catch (e) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playWindSound() async {
    try {
      await _audioChannel.invokeMethod('playSystemSound', {'soundName': 'wind'});
    } catch (e) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void dispose() {
    // Nothing to dispose
  }
}
