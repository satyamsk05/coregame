import 'package:flutter/services.dart';

void playTickSound() {
  try {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  } catch (_) {}
}

void startWelcomeMusicSound() {}

void stopWelcomeMusicSound() {}

void playWinSound() {
  try {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
  } catch (_) {}
}

void playLoseSound() {
  try {
    HapticFeedback.vibrate();
  } catch (_) {}
}

void playBeltHandleSound() {
  try {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  } catch (_) {}
}

void playCardPlaceSound() {
  try {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  } catch (_) {}
}
