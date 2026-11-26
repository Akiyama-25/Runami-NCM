import 'package:flutter/material.dart';

/// Semantic status colors directly matching NCM-Converter-For-Android Color.kt.
const Color kErrorColor = Color(0xFFCF6679);
const Color kErrorLightColor = Color(0xFFB3261E);
const Color kSuccessColor = Color(0xFF2EBD59);

class ColorPresetOption {
  final String labelKey;
  final Color color;

  const ColorPresetOption(this.labelKey, this.color);
}

const List<ColorPresetOption> kAccentColorPresets = [
  ColorPresetOption('color_green', Color(0xFF1DB954)),
  ColorPresetOption('color_blue', Color(0xFF1976D2)),
  ColorPresetOption('color_purple', Color(0xFF7B1FA2)),
  ColorPresetOption('color_red', Color(0xFFD32F2F)),
  ColorPresetOption('color_orange', Color(0xFFF57C00)),
  ColorPresetOption('color_cyan', Color(0xFF00838F)),
  ColorPresetOption('color_pink', Color(0xFFC2185B)),
  ColorPresetOption('color_indigo', Color(0xFF303F9F)),
];

const List<ColorPresetOption> kLightBgColorPresets = [
  ColorPresetOption('color_white', Color(0xFFFAFAFA)),
  ColorPresetOption('color_light_gray', Color(0xFFF5F5F5)),
  ColorPresetOption('color_cream', Color(0xFFFFF8E1)),
  ColorPresetOption('color_light_blue', Color(0xFFE3F2FD)),
];

const List<ColorPresetOption> kDarkBgColorPresets = [
  ColorPresetOption('color_black', Color(0xFF121212)),
  ColorPresetOption('color_dark_gray', Color(0xFF1E1E1E)),
  ColorPresetOption('color_dark_blue', Color(0xFF0D1B2A)),
  ColorPresetOption('color_dark_purple', Color(0xFF1A1A2E)),
];

class FontWeightPreset {
  final int weight;
  final String label;

  const FontWeightPreset(this.weight, this.label);
}

const List<FontWeightPreset> kAppFontWeights = [
  FontWeightPreset(100, 'Thin (100)'),
  FontWeightPreset(200, 'ExtraLight (200)'),
  FontWeightPreset(300, 'Light (300)'),
  FontWeightPreset(400, 'Regular (400)'),
  FontWeightPreset(500, 'Medium (500)'),
  FontWeightPreset(600, 'SemiBold (600)'),
  FontWeightPreset(700, 'Bold (700)'),
  FontWeightPreset(800, 'ExtraBold (800)'),
  FontWeightPreset(900, 'Black (900)'),
];

const ColorScheme defaultDarkColorScheme = ColorScheme.dark(
  primary: Color(0xFF1DB954),
  onPrimary: Color(0xFF0A1F11),
  primaryContainer: Color(0xFF144225),
  onPrimaryContainer: Color(0xFFA7F3C1),
  secondary: Color(0xFF66D491),
  onSecondary: Color(0xFF0A1F11),
  secondaryContainer: Color(0xFF1B3525),
  onSecondaryContainer: Color(0xFFC7F7D8),
  surface: Color(0xFF111315),
  onSurface: Color(0xFFE6E8EA),
  surfaceContainerLowest: Color(0xFF0B0D0E),
  surfaceContainerLow: Color(0xFF16181B),
  surfaceContainer: Color(0xFF1B1E22),
  surfaceContainerHigh: Color(0xFF23272C),
  surfaceContainerHighest: Color(0xFF2D3138),
  onSurfaceVariant: Color(0xFF9EA4AE),
  outline: Color(0xFF42474E),
  outlineVariant: Color(0xFF2B2F35),
  error: kErrorColor,
  onError: Color(0xFF121416),
);

const ColorScheme defaultLightColorScheme = ColorScheme.light(
  primary: Color(0xFF169C46),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFD6F7E1),
  onPrimaryContainer: Color(0xFF073818),
  secondary: Color(0xFF2B6B43),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFE4F5EA),
  onSecondaryContainer: Color(0xFF12361F),
  surface: Color(0xFFF8F9FA),
  onSurface: Color(0xFF181C1E),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF2F4F6),
  surfaceContainer: Color(0xFFECEEF0),
  surfaceContainerHigh: Color(0xFFE5E8EB),
  surfaceContainerHighest: Color(0xFFDEE2E6),
  onSurfaceVariant: Color(0xFF5A6065),
  outline: Color(0xFFC4C7CE),
  outlineVariant: Color(0xFFE1E3E8),
  error: kErrorLightColor,
  onError: Colors.white,
);

Color _contrastOn(Color color) {
  return color.computeLuminance() > 0.5 ? const Color(0xFF121416) : Colors.white;
}

Color _blend(Color fg, Color bg, double fraction) {
  final r = (fg.red + (bg.red - fg.red) * fraction).round().clamp(0, 255);
  final g = (fg.green + (bg.green - fg.green) * fraction).round().clamp(0, 255);
  final b = (fg.blue + (bg.blue - fg.blue) * fraction).round().clamp(0, 255);
  final a = (fg.alpha + (bg.alpha - fg.alpha) * fraction).round().clamp(0, 255);
  return Color.fromARGB(a, r, g, b);
}

Color _lighten(Color color, double fraction) => _blend(color, Colors.white, fraction);
Color _darken(Color color, double fraction) => _blend(color, Colors.black, fraction);

/// M3E (Material 3 Expressive) & FlClash-inspired surface container and accent color synthesizer,
/// ported 1:1 from NCM-Converter-For-Android's Color.kt.
ColorScheme applyUserColors(
  ColorScheme base, {
  required bool darkTheme,
  required Color accent,
  required Color bg,
  required bool monetEnabled,
}) {
  final onSurfaceVariant = darkTheme ? const Color(0xFFA2A8B2) : const Color(0xFF5A6169);
  final onSurface = darkTheme ? const Color(0xFFE8EAED) : const Color(0xFF1A1C1E);
  final outline = darkTheme ? const Color(0xFF42474E) : const Color(0xFFC4C7CE);
  final outlineVariant = darkTheme ? const Color(0xFF2B2F35) : const Color(0xFFE1E3E8);

  if (monetEnabled) {
    return base.copyWith(
      onSurfaceVariant: onSurfaceVariant,
      onSurface: onSurface,
      outline: outline,
      outlineVariant: outlineVariant,
    );
  }

  final onPrimary = _contrastOn(accent);
  final primaryContainer = darkTheme ? _blend(accent, bg, 0.72) : _lighten(accent, 0.82);
  final onPrimaryContainer = darkTheme ? _lighten(accent, 0.65) : _darken(accent, 0.45);
  final secondaryContainer = darkTheme ? _blend(accent, bg, 0.82) : _lighten(accent, 0.88);
  final onSecondaryContainer = darkTheme ? _lighten(accent, 0.72) : _darken(accent, 0.40);

  final surfaceContainerLowest = darkTheme ? _darken(bg, 0.20) : Colors.white;
  final surfaceContainerLow = darkTheme ? _lighten(bg, 0.03) : _darken(bg, 0.02);
  final surfaceContainer = darkTheme ? _lighten(bg, 0.06) : _darken(bg, 0.045);
  final surfaceContainerHigh = darkTheme ? _lighten(bg, 0.10) : _darken(bg, 0.07);
  final surfaceContainerHighest = darkTheme ? _lighten(bg, 0.14) : _darken(bg, 0.10);

  return base.copyWith(
    primary: accent,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: accent,
    onSecondary: onPrimary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    surface: bg,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    outline: outline,
    outlineVariant: outlineVariant,
  );
}
