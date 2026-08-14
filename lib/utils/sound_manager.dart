import 'package:flutter/services.dart';

class SoundManager {
  static bool soundOn = true;

  static void playClick() {
    if (soundOn) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
