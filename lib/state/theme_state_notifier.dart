import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/system_font_scanner.dart';
import '../core/utils/app_prefs.dart';

class ThemeState {
  final ThemeMode themeMode;
  final bool useMonetColors;
  final int customAccentColor;
  final double customAccentH;
  final double customAccentS;
  final double customAccentL;
  final String systemFontId;
  final String? fontFamily;
  final int fontWeight;
  final int gridColumns;
  final bool portraitGridEnabled;
  final String appLanguage;

  const ThemeState({
    required this.themeMode,
    required this.useMonetColors,
    required this.customAccentColor,
    required this.customAccentH,
    required this.customAccentS,
    required this.customAccentL,
    required this.systemFontId,
    this.fontFamily,
    required this.fontWeight,
    required this.gridColumns,
    required this.portraitGridEnabled,
    required this.appLanguage,
  });

  factory ThemeState.fromPrefs() {
    ThemeMode mode;
    switch (AppPrefs.themeMode) {
      case AppPrefs.THEME_LIGHT:
        mode = ThemeMode.light;
        break;
      case AppPrefs.THEME_DARK:
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
        break;
    }

    final fontId = AppPrefs.systemFontId;
    final family = (fontId == SystemFontScanner.idSystemDefault) ? null : fontId;

    return ThemeState(
      themeMode: mode,
      useMonetColors: AppPrefs.useMonetColors,
      customAccentColor: AppPrefs.customAccentColor,
      customAccentH: AppPrefs.customAccentH,
      customAccentS: AppPrefs.customAccentS,
      customAccentL: AppPrefs.customAccentL,
      systemFontId: fontId,
      fontFamily: family,
      fontWeight: AppPrefs.fontWeight,
      gridColumns: AppPrefs.gridColumns,
      portraitGridEnabled: AppPrefs.portraitGridEnabled,
      appLanguage: AppPrefs.appLanguage,
    );
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? useMonetColors,
    int? customAccentColor,
    double? customAccentH,
    double? customAccentS,
    double? customAccentL,
    String? systemFontId,
    String? fontFamily,
    int? fontWeight,
    int? gridColumns,
    bool? portraitGridEnabled,
    String? appLanguage,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      useMonetColors: useMonetColors ?? this.useMonetColors,
      customAccentColor: customAccentColor ?? this.customAccentColor,
      customAccentH: customAccentH ?? this.customAccentH,
      customAccentS: customAccentS ?? this.customAccentS,
      customAccentL: customAccentL ?? this.customAccentL,
      systemFontId: systemFontId ?? this.systemFontId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      gridColumns: gridColumns ?? this.gridColumns,
      portraitGridEnabled: portraitGridEnabled ?? this.portraitGridEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
    );
  }
}

class ThemeStateNotifier extends StateNotifier<ThemeState> {
  ThemeStateNotifier() : super(ThemeState.fromPrefs());

  void setThemeMode(String mode) {
    AppPrefs.themeMode = mode;
    ThemeMode m = ThemeMode.system;
    if (mode == AppPrefs.THEME_LIGHT) m = ThemeMode.light;
    if (mode == AppPrefs.THEME_DARK) m = ThemeMode.dark;
    state = state.copyWith(themeMode: m);
  }

  void setUseMonetColors(bool val) {
    AppPrefs.useMonetColors = val;
    state = state.copyWith(useMonetColors: val);
  }

  void setAccentHsl(int argb, double h, double s, double l) {
    AppPrefs.updateAccentColor(argb, h, s, l);
    state = state.copyWith(
      customAccentColor: argb,
      customAccentH: h,
      customAccentS: s,
      customAccentL: l,
    );
  }

  void setSystemFont(String fontId) {
    AppPrefs.systemFontId = fontId;
    final family = (fontId == SystemFontScanner.idSystemDefault) ? null : fontId;
    state = state.copyWith(systemFontId: fontId, fontFamily: family);
  }

  void setFontWeight(int weight) {
    AppPrefs.fontWeight = weight;
    state = state.copyWith(fontWeight: weight);
  }

  void setGridColumns(int cols) {
    AppPrefs.gridColumns = cols;
    state = state.copyWith(gridColumns: cols);
  }

  void setPortraitGridEnabled(bool enabled) {
    AppPrefs.portraitGridEnabled = enabled;
    state = state.copyWith(portraitGridEnabled: enabled);
  }

  void setAppLanguage(String lang) {
    AppPrefs.appLanguage = lang;
    state = state.copyWith(appLanguage: lang);
  }
}
