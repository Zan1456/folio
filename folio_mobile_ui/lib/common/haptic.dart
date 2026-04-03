import 'package:flutter/services.dart';
import 'package:folio/models/settings.dart';

void performHapticFeedback(VibrationStrength strength) {
  switch (strength) {
    case VibrationStrength.off:
      break;
    case VibrationStrength.light:
      HapticFeedback.selectionClick();
    case VibrationStrength.medium:
      HapticFeedback.lightImpact();
    case VibrationStrength.strong:
      HapticFeedback.mediumImpact();
  }
}
