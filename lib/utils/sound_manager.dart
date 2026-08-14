import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'sound_helper.dart' as helper;

class SoundManager {
  static bool soundOn = true;

  static void playClick() {
    if (soundOn) {
      if (kIsWeb) {
        helper.playTick();
      } else {
        helper.playTick();
        SystemSound.play(SystemSoundType.click);
      }
    }
  }
}
