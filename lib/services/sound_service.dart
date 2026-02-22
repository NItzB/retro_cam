import 'package:flutter/services.dart';
import '../services/filter_service.dart';

class SoundService {
  static const MethodChannel _audioChannel = MethodChannel('retro_cam_audio');

  Future<void> initialize() async {
    // Handled natively
  }

  Future<void> playShutterSound(VintageFilterType type) async {
    try {
      String soundName = 'shutter';
      switch (type) {
        case VintageFilterType.wetzlarMono: soundName = 'wetzlar_shutter'; break;
        case VintageFilterType.portraGlow: soundName = 'portra_shutter'; break;
        case VintageFilterType.kChrome64: soundName = 'kchrome_shutter'; break;
        case VintageFilterType.superiaTeal: soundName = 'superia_shutter'; break;
        case VintageFilterType.nightCine: soundName = 'nightcine_shutter'; break;
        case VintageFilterType.magicSquare: soundName = 'magic_shutter'; break;
        case VintageFilterType.original: soundName = 'shutter'; break;
      }
      
      await _audioChannel.invokeMethod('playSystemSound', {'soundName': soundName});
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

  Future<void> playClickSound() async {
    try {
      await _audioChannel.invokeMethod('playSystemSound', {'soundName': 'click'});
    } catch (e) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void dispose() {
    // Nothing to dispose
  }
}
