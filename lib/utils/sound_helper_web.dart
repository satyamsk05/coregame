// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

@JS('eval')
external void _eval(String code);

void playTickSound() {
  try {
    _eval('''
      (function() {
        try {
          var audioCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
          if (audioCtx.state === 'suspended') {
            audioCtx.resume();
          }
          var osc = audioCtx.createOscillator();
          var gain = audioCtx.createGain();
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(1400, audioCtx.currentTime);
          osc.frequency.exponentialRampToValueAtTime(120, audioCtx.currentTime + 0.03);
          
          gain.gain.setValueAtTime(0.05, audioCtx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + 0.03);
          
          osc.start(audioCtx.currentTime);
          osc.stop(audioCtx.currentTime + 0.03);
        } catch (e) {
          console.error(e);
        }
      })();
    ''');
  } catch (e) {
    // Fail silently on native platforms or errors
  }
}

void startWelcomeMusicSound() {
  try {
    _eval('''
      (function() {
        if (window._welcomeAudio) return;
        
        function startAudio() {
          var audioCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
          if (audioCtx.state === 'suspended') {
            audioCtx.resume();
          }
          if (window._welcomeAudio) return;
          
          var osc1 = audioCtx.createOscillator();
          var osc2 = audioCtx.createOscillator();
          var filter = audioCtx.createBiquadFilter();
          var gainNode = audioCtx.createGain();
          
          osc1.type = 'sawtooth';
          osc2.type = 'triangle';
          
          osc1.frequency.setValueAtTime(110, audioCtx.currentTime); // A2
          osc2.frequency.setValueAtTime(165, audioCtx.currentTime); // E3
          
          filter.type = 'lowpass';
          filter.frequency.setValueAtTime(400, audioCtx.currentTime);
          filter.Q.setValueAtTime(5, audioCtx.currentTime);
          
          var lfo = audioCtx.createOscillator();
          var lfoGain = audioCtx.createGain();
          lfo.frequency.value = 0.25;
          lfoGain.gain.value = 250;
          
          lfo.connect(lfoGain);
          lfoGain.connect(filter.frequency);
          
          osc1.connect(filter);
          osc2.connect(filter);
          filter.connect(gainNode);
          gainNode.connect(audioCtx.destination);
          
          gainNode.gain.setValueAtTime(0.0, audioCtx.currentTime);
          gainNode.gain.linearRampToValueAtTime(0.08, audioCtx.currentTime + 2.0);
          
          osc1.start();
          osc2.start();
          lfo.start();
          
          window._welcomeAudio = {
            osc1: osc1,
            osc2: osc2,
            lfo: lfo,
            gain: gainNode
          };
        }

        var tempCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
        if (tempCtx.state === 'suspended') {
          var startOnGesture = function() {
            startAudio();
            window.removeEventListener('click', startOnGesture);
            window.removeEventListener('touchstart', startOnGesture);
          };
          window.addEventListener('click', startOnGesture);
          window.addEventListener('touchstart', startOnGesture);
        } else {
          startAudio();
        }
      })();
    ''');
  } catch (e) {
    // Fail silently
  }
}

void stopWelcomeMusicSound() {
  try {
    _eval('''
      (function() {
        var welcome = window._welcomeAudio;
        if (welcome) {
          var audioCtx = window._audioCtx;
          var now = audioCtx ? audioCtx.currentTime : 0;
          if (welcome.gain && audioCtx) {
            welcome.gain.gain.cancelScheduledValues(now);
            welcome.gain.gain.setValueAtTime(welcome.gain.gain.value, now);
            welcome.gain.gain.linearRampToValueAtTime(0.0, now + 1.0);
            
            setTimeout(function() {
              try {
                welcome.osc1.stop();
                welcome.osc2.stop();
                welcome.lfo.stop();
              } catch (e) {}
              window._welcomeAudio = null;
            }, 1000);
          } else {
            try {
              welcome.osc1.stop();
              welcome.osc2.stop();
              welcome.lfo.stop();
            } catch (e) {}
            window._welcomeAudio = null;
          }
        }
      })();
    ''');
  } catch (e) {
    // Fail silently
  }
}

void playWinSound() {
  try {
    _eval('''
      (function() {
        try {
          var audioCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
          if (audioCtx.state === 'suspended') audioCtx.resume();
          var now = audioCtx.currentTime;
          
          var notes = [261.63, 329.63, 392.00, 523.25]; // C4, E4, G4, C5
          notes.forEach(function(freq, index) {
            var osc = audioCtx.createOscillator();
            var gain = audioCtx.createGain();
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, now + index * 0.1);
            
            gain.gain.setValueAtTime(0.0, now + index * 0.1);
            gain.gain.linearRampToValueAtTime(0.06, now + index * 0.1 + 0.05);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + index * 0.1 + 0.25);
            
            osc.start(now + index * 0.1);
            osc.stop(now + index * 0.1 + 0.3);
          });
        } catch (e) {
          console.error(e);
        }
      })();
    ''');
  } catch (e) {
    // Fail silently
  }
}

void playLoseSound() {
  try {
    _eval('''
      (function() {
        try {
          var audioCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
          if (audioCtx.state === 'suspended') audioCtx.resume();
          var now = audioCtx.currentTime;
          
          var osc = audioCtx.createOscillator();
          var gain = audioCtx.createGain();
          var filter = audioCtx.createBiquadFilter();
          
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(196.00, now); // G3
          osc.frequency.linearRampToValueAtTime(130.81, now + 0.4); // C3
          
          filter.type = 'lowpass';
          filter.frequency.setValueAtTime(300, now);
          
          osc.connect(filter);
          filter.connect(gain);
          gain.connect(audioCtx.destination);
          
          gain.gain.setValueAtTime(0.08, now);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.4);
          
          osc.start(now);
          osc.stop(now + 0.4);
        } catch (e) {
          console.error(e);
        }
      })();
    ''');
  } catch (e) {
    // Fail silently
  }
}

void playBeltHandleSound() {
  try {
    _eval('''
      (function() {
        try {
          var audioCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
          if (audioCtx.state === 'suspended') audioCtx.resume();
          var now = audioCtx.currentTime;
          
          // Mechanical ratchet click 1
          var osc1 = audioCtx.createOscillator();
          var gain1 = audioCtx.createGain();
          osc1.type = 'square';
          osc1.frequency.setValueAtTime(340, now);
          osc1.frequency.exponentialRampToValueAtTime(75, now + 0.045);
          gain1.gain.setValueAtTime(0.14, now);
          gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.045);
          osc1.connect(gain1);
          gain1.connect(audioCtx.destination);
          osc1.start(now);
          osc1.stop(now + 0.045);

          // Mechanical belt latch release 2 (delay 60ms)
          var osc2 = audioCtx.createOscillator();
          var gain2 = audioCtx.createGain();
          osc2.type = 'triangle';
          osc2.frequency.setValueAtTime(460, now + 0.06);
          osc2.frequency.exponentialRampToValueAtTime(110, now + 0.115);
          gain2.gain.setValueAtTime(0.16, now + 0.06);
          gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.115);
          osc2.connect(gain2);
          gain2.connect(audioCtx.destination);
          osc2.start(now + 0.06);
          osc2.stop(now + 0.115);
        } catch (e) {
          console.error(e);
        }
      })();
    ''');
  } catch (e) {
    // Fail silently
  }
}

void playCardPlaceSound() {
  try {
    _eval('''
      (function() {
        try {
          var audioCtx = window._audioCtx || (window._audioCtx = new (window.AudioContext || window.webkitAudioContext)());
          if (audioCtx.state === 'suspended') {
            audioCtx.resume();
          }
          var now = audioCtx.currentTime;

          // 1. Crisp felt card glide swish
          var osc1 = audioCtx.createOscillator();
          var gain1 = audioCtx.createGain();
          osc1.type = 'triangle';
          osc1.frequency.setValueAtTime(850, now);
          osc1.frequency.exponentialRampToValueAtTime(180, now + 0.055);
          gain1.gain.setValueAtTime(0.40, now);
          gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.055);
          osc1.connect(gain1);
          gain1.connect(audioCtx.destination);
          osc1.start(now);
          osc1.stop(now + 0.055);

          // 2. Felt table impact snap (12ms sub-pulse)
          var osc2 = audioCtx.createOscillator();
          var gain2 = audioCtx.createGain();
          osc2.type = 'sine';
          osc2.frequency.setValueAtTime(360, now + 0.012);
          osc2.frequency.exponentialRampToValueAtTime(95, now + 0.065);
          gain2.gain.setValueAtTime(0.50, now + 0.012);
          gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.065);
          osc2.connect(gain2);
          gain2.connect(audioCtx.destination);
          osc2.start(now + 0.012);
          osc2.stop(now + 0.065);
        } catch (e) {
          console.error(e);
        }
      })();
    ''');
  } catch (e) {
    // Fail silently
  }
}
