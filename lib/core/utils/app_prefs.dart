import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String KEY_THEME_MODE = "theme_mode";
  static const String KEY_CUSTOM_PATH = "custom_path";
  static const String KEY_AUTO_SAVE = "auto_save";
  static const String KEY_ENABLE_LYRIC = "enable_lyric";
  static const String KEY_LYRIC_MODE = "lyric_mode";
  static const String KEY_LYRIC_EMBED_ORIGINAL = "lyric_embed_original";
  static const String KEY_LYRIC_EMBED_TRANSLATED = "lyric_embed_translated";
  static const String KEY_ENABLE_COVER = "enable_cover";
  static const String KEY_USE_MONET_COLORS = "use_monet_colors";
  static const String KEY_CUSTOM_ACCENT_COLOR = "custom_accent_color";
  static const String KEY_CUSTOM_LIGHT_BG_COLOR = "custom_light_bg_color";
  static const String KEY_CUSTOM_DARK_BG_COLOR = "custom_dark_bg_color";
  static const String KEY_CUSTOM_ACCENT_H = "custom_accent_h";
  static const String KEY_CUSTOM_ACCENT_S = "custom_accent_s";
  static const String KEY_CUSTOM_ACCENT_L = "custom_accent_l";
  static const String KEY_CUSTOM_BG_H = "custom_bg_h";
  static const String KEY_CUSTOM_BG_S = "custom_bg_s";
  static const String KEY_CUSTOM_BG_L = "custom_bg_l";
  static const String KEY_GRID_COLUMNS = "grid_columns";
  static const String KEY_PORTRAIT_GRID_ENABLED = "portrait_grid_enabled";
  static const String KEY_APP_LANGUAGE = "app_language";
  static const String KEY_USE_EMBEDDED_FONT = "use_embedded_font";
  static const String KEY_SYSTEM_FONT_ID = "system_font_id";
  static const String KEY_FONT_WEIGHT = "font_weight";
  static const String KEY_CUSTOM_OUTPUT_URI = "custom_output_uri";
  static const String KEY_LOG_LEVEL = "log_level";
  static const String KEY_LOG_FORMAT = "log_format";

  static const String THEME_SYSTEM = "system";
  static const String THEME_LIGHT = "light";
  static const String THEME_DARK = "dark";

  static const String LOG_LEVEL_VERBOSE = "VERBOSE";
  static const String LOG_LEVEL_DEBUG = "DEBUG";
  static const String LOG_LEVEL_INFO = "INFO";
  static const String LOG_LEVEL_WARN = "WARN";
  static const String LOG_LEVEL_ERROR = "ERROR";

  static const String LOG_FORMAT_LOG = "log";
  static const String LOG_FORMAT_TXT = "txt";
  static const String LOG_FORMAT_MD = "md";

  static const String LYRIC_MODE_MERGED = "merged";
  static const String LYRIC_MODE_RAW = "raw";
  static const String LYRIC_MODE_TRANSLATED = "translated";

  static const int DEFAULT_ACCENT_COLOR = 0xFF1DB954;
  static const int DEFAULT_LIGHT_BG_COLOR = 0xFFFAFAFA;
  static const int DEFAULT_DARK_BG_COLOR = 0xFF121212;

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _migrateLyricMode();
  }

  static void _migrateLyricMode() {
    if (_prefs.containsKey(KEY_LYRIC_MODE) && !_prefs.containsKey(KEY_LYRIC_EMBED_ORIGINAL)) {
      final mode = _prefs.getString(KEY_LYRIC_MODE) ?? LYRIC_MODE_MERGED;
      if (mode == LYRIC_MODE_RAW) {
        _prefs.setBool(KEY_LYRIC_EMBED_ORIGINAL, true);
        _prefs.setBool(KEY_LYRIC_EMBED_TRANSLATED, false);
      } else if (mode == LYRIC_MODE_TRANSLATED) {
        _prefs.setBool(KEY_LYRIC_EMBED_ORIGINAL, false);
        _prefs.setBool(KEY_LYRIC_EMBED_TRANSLATED, true);
      } else {
        _prefs.setBool(KEY_LYRIC_EMBED_ORIGINAL, true);
        _prefs.setBool(KEY_LYRIC_EMBED_TRANSLATED, true);
      }
      _prefs.remove(KEY_LYRIC_MODE);
    }
  }

  static String get themeMode => _prefs.getString(KEY_THEME_MODE) ?? THEME_SYSTEM;
  static set themeMode(String value) => _prefs.setString(KEY_THEME_MODE, value);

  static String get customPath =>
      _prefs.getString(KEY_CUSTOM_PATH) ?? (Platform.isWindows ? r'Music\NCMConverter' : 'Music/NCMConverter');
  static set customPath(String value) => _prefs.setString(KEY_CUSTOM_PATH, value);

  static String get customOutputUri => _prefs.getString(KEY_CUSTOM_OUTPUT_URI) ?? '';
  static set customOutputUri(String value) => _prefs.setString(KEY_CUSTOM_OUTPUT_URI, value);

  static bool get autoSave => _prefs.getBool(KEY_AUTO_SAVE) ?? false;
  static set autoSave(bool value) => _prefs.setBool(KEY_AUTO_SAVE, value);

  static bool get enableLyric => _prefs.getBool(KEY_ENABLE_LYRIC) ?? true;
  static set enableLyric(bool value) => _prefs.setBool(KEY_ENABLE_LYRIC, value);

  static bool get lyricEmbedOriginal => _prefs.getBool(KEY_LYRIC_EMBED_ORIGINAL) ?? true;
  static set lyricEmbedOriginal(bool value) => _prefs.setBool(KEY_LYRIC_EMBED_ORIGINAL, value);

  static bool get lyricEmbedTranslated => _prefs.getBool(KEY_LYRIC_EMBED_TRANSLATED) ?? true;
  static set lyricEmbedTranslated(bool value) => _prefs.setBool(KEY_LYRIC_EMBED_TRANSLATED, value);

  static bool get enableCover => _prefs.getBool(KEY_ENABLE_COVER) ?? true;
  static set enableCover(bool value) => _prefs.setBool(KEY_ENABLE_COVER, value);

  static bool get useMonetColors => _prefs.getBool(KEY_USE_MONET_COLORS) ?? true;
  static set useMonetColors(bool value) => _prefs.setBool(KEY_USE_MONET_COLORS, value);

  static int get customAccentColor => _prefs.getInt(KEY_CUSTOM_ACCENT_COLOR) ?? DEFAULT_ACCENT_COLOR;
  static set customAccentColor(int value) => _prefs.setInt(KEY_CUSTOM_ACCENT_COLOR, value);

  static int get customLightBgColor => _prefs.getInt(KEY_CUSTOM_LIGHT_BG_COLOR) ?? DEFAULT_LIGHT_BG_COLOR;
  static set customLightBgColor(int value) => _prefs.setInt(KEY_CUSTOM_LIGHT_BG_COLOR, value);

  static int get customDarkBgColor => _prefs.getInt(KEY_CUSTOM_DARK_BG_COLOR) ?? DEFAULT_DARK_BG_COLOR;
  static set customDarkBgColor(int value) => _prefs.setInt(KEY_CUSTOM_DARK_BG_COLOR, value);

  static double get customAccentH => _prefs.getDouble(KEY_CUSTOM_ACCENT_H) ?? 141.0;
  static set customAccentH(double value) => _prefs.setDouble(KEY_CUSTOM_ACCENT_H, value);

  static double get customAccentS => _prefs.getDouble(KEY_CUSTOM_ACCENT_S) ?? 73.0;
  static set customAccentS(double value) => _prefs.setDouble(KEY_CUSTOM_ACCENT_S, value);

  static double get customAccentL => _prefs.getDouble(KEY_CUSTOM_ACCENT_L) ?? 41.0;
  static set customAccentL(double value) => _prefs.setDouble(KEY_CUSTOM_ACCENT_L, value);

  static double get customBgH => _prefs.getDouble(KEY_CUSTOM_BG_H) ?? 0.0;
  static set customBgH(double value) => _prefs.setDouble(KEY_CUSTOM_BG_H, value);

  static double get customBgS => _prefs.getDouble(KEY_CUSTOM_BG_S) ?? 0.0;
  static set customBgS(double value) => _prefs.setDouble(KEY_CUSTOM_BG_S, value);

  static double get customBgL => _prefs.getDouble(KEY_CUSTOM_BG_L) ?? 98.0;
  static set customBgL(double value) => _prefs.setDouble(KEY_CUSTOM_BG_L, value);

  static int get gridColumns => (_prefs.getInt(KEY_GRID_COLUMNS) ?? 2).clamp(1, 5);
  static set gridColumns(int value) => _prefs.setInt(KEY_GRID_COLUMNS, value.clamp(1, 5));

  static bool get portraitGridEnabled => _prefs.getBool(KEY_PORTRAIT_GRID_ENABLED) ?? false;
  static set portraitGridEnabled(bool value) => _prefs.setBool(KEY_PORTRAIT_GRID_ENABLED, value);

  static bool get useEmbeddedFont => _prefs.getBool(KEY_USE_EMBEDDED_FONT) ?? false;
  static set useEmbeddedFont(bool value) => _prefs.setBool(KEY_USE_EMBEDDED_FONT, value);

  static String get systemFontId => _prefs.getString(KEY_SYSTEM_FONT_ID) ?? 'system_default';
  static set systemFontId(String value) => _prefs.setString(KEY_SYSTEM_FONT_ID, value);

  static int get fontWeight => (_prefs.getInt(KEY_FONT_WEIGHT) ?? 400).clamp(100, 900);
  static set fontWeight(int value) => _prefs.setInt(KEY_FONT_WEIGHT, value.clamp(100, 900));

  static String get appLanguage => _prefs.getString(KEY_APP_LANGUAGE) ?? 'system';
  static set appLanguage(String value) => _prefs.setString(KEY_APP_LANGUAGE, value);

  static String get logLevel => _prefs.getString(KEY_LOG_LEVEL) ?? LOG_LEVEL_DEBUG;
  static set logLevel(String value) => _prefs.setString(KEY_LOG_LEVEL, value);

  static String get logFormat => _prefs.getString(KEY_LOG_FORMAT) ?? LOG_FORMAT_LOG;
  static set logFormat(String value) => _prefs.setString(KEY_LOG_FORMAT, value);

  static void updateAccentColor(int argb, double h, double s, double l) {
    customAccentColor = argb;
    customAccentH = h;
    customAccentS = s;
    customAccentL = l;
  }

  static void updateBgColor(int argb, double h, double s, double l, bool isDark) {
    customBgH = h;
    customBgS = s;
    customBgL = l;
    if (isDark) {
      customDarkBgColor = argb;
    } else {
      customLightBgColor = argb;
    }
  }
}
