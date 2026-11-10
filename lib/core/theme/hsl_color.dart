import 'dart:ui';
import 'package:flutter/painting.dart' as p;

class HslColorUtil {
  static Color hslToColor(double h, double s, double l, [double a = 1.0]) {
    final hsl = p.HSLColor.fromAHSL(
      a.clamp(0.0, 1.0),
      h.clamp(0.0, 360.0),
      (s / 100.0).clamp(0.0, 1.0),
      (l / 100.0).clamp(0.0, 1.0),
    );
    return hsl.toColor();
  }

  static List<double> colorToHsl(Color color) {
    final hsl = p.HSLColor.fromColor(color);
    return [
      hsl.hue,
      (hsl.saturation * 100.0).clamp(0.0, 100.0),
      (hsl.lightness * 100.0).clamp(0.0, 100.0),
    ];
  }
}
