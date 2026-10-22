import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AlertFeedbackService {
  static final AlertFeedbackService _instance = AlertFeedbackService._internal();
  factory AlertFeedbackService() => _instance;
  AlertFeedbackService._internal();

  Timer? _vibrateTimer;
  bool _isActive = false;
  bool _hasVibrator = true;

  Future<void> init() async {
    try {
      final canVibrate = await Vibration.hasVibrator();
      _hasVibrator = canVibrate;
    } catch (_) {
      _hasVibrator = false;
    }
  }

  void startAlert({bool playSound = true, bool vibrate = true}) {
    if (_isActive && _vibrateTimer != null) return;
    _isActive = true;

    _vibrateTimer?.cancel();

    // Trigger immediate alert pulse
    _triggerPulse(playSound, vibrate);

    // Repeat pulses every 1.2s while emergency is in the same lane
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _triggerPulse(playSound, vibrate);
    });
  }

  void stopAlert() {
    _isActive = false;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  void _triggerPulse(bool playSound, bool vibrate) {
    if (playSound) {
      SystemSound.play(SystemSoundType.alert);
    }

    if (!vibrate) return;

    if (!_hasVibrator) {
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      Vibration.vibrate(
        pattern: [0, 450, 150, 450],
      );
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  void triggerTapFeedback() {
    HapticFeedback.selectionClick();
  }

  void triggerLaneSwitchFeedback() {
    HapticFeedback.selectionClick();
  }

  void dispose() {
    stopAlert();
  }
}

