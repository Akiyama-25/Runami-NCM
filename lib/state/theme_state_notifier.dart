import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/system_font_scanner.dart';
import '../core/utils/app_prefs.dart';

class ThemeState {
  final ThemeMode themeMode;
  final String themeModeCode;
  final bool useMonetColors;
  final int customAccentColor;
  final int customLightBgColor;
  final int customDarkBgColor;
  final double customAccentH;
  final double customAccentS;
  final double customAccentL;
  final double customBgH;
  final double customBgS;
  final double customBgL;
  final String systemFontId;
  final String? fontFamily;
  final int fontWeight;
  final int gridColumns;
  final bool portraitGridEnabled;
  final String appLanguage;

  // Conversion, Lyrics, and Debug preferences (reactive)
  final String customPath;
  final bool autoSave;
  final bool enableCover;
  final bool enableLyric;
  final bool lyricEmbedOriginal;
  final bool lyricEmbedTranslated;
  final String logLevel;
  final String logFormat;

  const ThemeState({
    required this.themeMode,
    required this.themeModeCode,
    required this.useMonetColors,
    required this.customAccentColor,
    required this.customLightBgColor,
    required this.customDarkBgColor,
    required this.customAccentH,
    required this.customAccentS,
    required this.customAccentL,
    required this.customBgH,
    required this.customBgS,
    required this.customBgL,
    required this.systemFontId,
    this.fontFamily,
    required this.fontWeight,
    required this.gridColumns,
    required this.portraitGridEnabled,
    required this.appLanguage,
    required this.customPath,
    required this.autoSave,
    required this.enableCover,
    required this.enableLyric,
    required this.lyricEmbedOriginal,
    required this.lyricEmbedTranslated,
    required this.logLevel,
    required this.logFormat,
  });

  factory ThemeState.fromPrefs() {
    final modeCode = AppPrefs.themeMode;
    ThemeMode mode;
    switch (modeCode) {
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
    final family = SystemFontScanner.resolveFontFamily(fontId);

    return ThemeState(
      themeMode: mode,
      themeModeCode: modeCode,
      useMonetColors: AppPrefs.useMonetColors,
      customAccentColor: AppPrefs.customAccentColor,
      customLightBgColor: AppPrefs.customLightBgColor,
      customDarkBgColor: AppPrefs.customDarkBgColor,
      customAccentH: AppPrefs.customAccentH,
      customAccentS: AppPrefs.customAccentS,
      customAccentL: AppPrefs.customAccentL,
      customBgH: AppPrefs.customBgH,
      customBgS: AppPrefs.customBgS,
      customBgL: AppPrefs.customBgL,
      systemFontId: fontId,
      fontFamily: family,
      fontWeight: AppPrefs.fontWeight,
      gridColumns: AppPrefs.gridColumns,
      portraitGridEnabled: AppPrefs.portraitGridEnabled,
      appLanguage: AppPrefs.appLanguage,
      customPath: AppPrefs.customPath,
      autoSave: AppPrefs.autoSave,
      enableCover: AppPrefs.enableCover,
      enableLyric: AppPrefs.enableLyric,
      lyricEmbedOriginal: AppPrefs.lyricEmbedOriginal,
      lyricEmbedTranslated: AppPrefs.lyricEmbedTranslated,
      logLevel: AppPrefs.logLevel,
      logFormat: AppPrefs.logFormat,
    );
  }

  static const _sentinel = Object();

  ThemeState copyWith({
    ThemeMode? themeMode,
    String? themeModeCode,
    bool? useMonetColors,
    int? customAccentColor,
    int? customLightBgColor,
    int? customDarkBgColor,
    double? customAccentH,
    double? customAccentS,
    double? customAccentL,
    double? customBgH,
    double? customBgS,
    double? customBgL,
    String? systemFontId,
    Object? fontFamily = _sentinel,
    int? fontWeight,
    int? gridColumns,
    bool? portraitGridEnabled,
    String? appLanguage,
    String? customPath,
    bool? autoSave,
    bool? enableCover,
    bool? enableLyric,
    bool? lyricEmbedOriginal,
    bool? lyricEmbedTranslated,
    String? logLevel,
    String? logFormat,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeModeCode: themeModeCode ?? this.themeModeCode,
      useMonetColors: useMonetColors ?? this.useMonetColors,
      customAccentColor: customAccentColor ?? this.customAccentColor,
      customLightBgColor: customLightBgColor ?? this.customLightBgColor,
      customDarkBgColor: customDarkBgColor ?? this.customDarkBgColor,
      customAccentH: customAccentH ?? this.customAccentH,
      customAccentS: customAccentS ?? this.customAccentS,
      customAccentL: customAccentL ?? this.customAccentL,
      customBgH: customBgH ?? this.customBgH,
      customBgS: customBgS ?? this.customBgS,
      customBgL: customBgL ?? this.customBgL,
      systemFontId: systemFontId ?? this.systemFontId,
      fontFamily: identical(fontFamily, _sentinel)
          ? this.fontFamily
          : fontFamily as String?,
      fontWeight: fontWeight ?? this.fontWeight,
      gridColumns: gridColumns ?? this.gridColumns,
      portraitGridEnabled: portraitGridEnabled ?? this.portraitGridEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
      customPath: customPath ?? this.customPath,
      autoSave: autoSave ?? this.autoSave,
      enableCover: enableCover ?? this.enableCover,
      enableLyric: enableLyric ?? this.enableLyric,
      lyricEmbedOriginal: lyricEmbedOriginal ?? this.lyricEmbedOriginal,
      lyricEmbedTranslated: lyricEmbedTranslated ?? this.lyricEmbedTranslated,
      logLevel: logLevel ?? this.logLevel,
      logFormat: logFormat ?? this.logFormat,
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
    state = state.copyWith(themeMode: m, themeModeCode: mode);
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

  void setBgHsl(int argb, double h, double s, double l, bool isDark) {
    AppPrefs.updateBgColor(argb, h, s, l, isDark);
    state = state.copyWith(
      customLightBgColor: isDark ? state.customLightBgColor : argb,
      customDarkBgColor: isDark ? argb : state.customDarkBgColor,
      customBgH: h,
      customBgS: s,
      customBgL: l,
    );
  }

  void setSystemFont(String fontId) {
    AppPrefs.systemFontId = fontId;
    final family = SystemFontScanner.resolveFontFamily(fontId);
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

  void setCustomPath(String path) {
    AppPrefs.customPath = path;
    state = state.copyWith(customPath: path);
  }

  void setAutoSave(bool val) {
    AppPrefs.autoSave = val;
    state = state.copyWith(autoSave: val);
  }

  void setEnableCover(bool val) {
    AppPrefs.enableCover = val;
    state = state.copyWith(enableCover: val);
  }

  void setEnableLyric(bool val) {
    AppPrefs.enableLyric = val;
    state = state.copyWith(enableLyric: val);
  }

  void setLyricEmbedOriginal(bool val) {
    AppPrefs.lyricEmbedOriginal = val;
    state = state.copyWith(lyricEmbedOriginal: val);
  }

  void setLyricEmbedTranslated(bool val) {
    AppPrefs.lyricEmbedTranslated = val;
    state = state.copyWith(lyricEmbedTranslated: val);
  }

  void setLogLevel(String level) {
    AppPrefs.logLevel = level;
    state = state.copyWith(logLevel: level);
  }

  void setLogFormat(String format) {
    AppPrefs.logFormat = format;
    state = state.copyWith(logFormat: format);
  }
}
