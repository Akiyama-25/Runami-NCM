import 'dart:io';
import 'package:flutter/services.dart';

class SystemFontItem {
  final String id;
  final String displayName;
  final String subtitle;
  final String? fontFamily;
  final bool isBuiltInLogical;

  const SystemFontItem({
    required this.id,
    required this.displayName,
    required this.subtitle,
    this.fontFamily,
    this.isBuiltInLogical = false,
  });
}

class SystemFontScanner {
  static const String idSystemDefault = 'system_default';
  static const String idLegacyDefault = 'system';
  static const String idSansSerif = 'sans-serif';
  static const String idSerif = 'serif';
  static const String idMonospace = 'monospace';
  static const String idCursive = 'cursive';

  static const MethodChannel _iosFontChannel =
      MethodChannel('ncm.converter/system_fonts');

  static List<SystemFontItem>? _cachedFonts;

  static bool isDefaultFontId(String fontId) {
    return fontId.isEmpty || fontId == idSystemDefault || fontId == idLegacyDefault;
  }

  static List<SystemFontItem> getLogicalPresets() => const [
        SystemFontItem(
          id: idSystemDefault,
          displayName: 'System Default',
          subtitle: 'OS UI Default Font',
          fontFamily: null,
          isBuiltInLogical: true,
        ),
        SystemFontItem(
          id: idSansSerif,
          displayName: 'Sans-Serif',
          subtitle: 'System Sans-Serif',
          fontFamily: 'sans-serif',
          isBuiltInLogical: true,
        ),
        SystemFontItem(
          id: idSerif,
          displayName: 'Serif',
          subtitle: 'System Serif',
          fontFamily: 'serif',
          isBuiltInLogical: true,
        ),
        SystemFontItem(
          id: idMonospace,
          displayName: 'Monospace',
          subtitle: 'System Monospace',
          fontFamily: 'monospace',
          isBuiltInLogical: true,
        ),
        SystemFontItem(
          id: idCursive,
          displayName: 'Cursive',
          subtitle: 'System Script / Cursive',
          fontFamily: 'cursive',
          isBuiltInLogical: true,
        ),
      ];

  static String? resolveFontFamily(String fontId) {
    if (isDefaultFontId(fontId)) return null;
    if (fontId == idSansSerif) return 'sans-serif';
    if (fontId == idSerif) return 'serif';
    if (fontId == idMonospace) return 'monospace';
    if (fontId == idCursive) return 'cursive';
    final cached = _cachedFonts;
    if (cached != null) {
      for (final f in cached) {
        if (f.id == fontId) return f.fontFamily;
      }
    }
    return fontId;
  }

  static String getDisplayName(String fontId, {String? defaultLabel}) {
    if (isDefaultFontId(fontId)) {
      return defaultLabel ?? 'System Default';
    }
    final list = _cachedFonts ?? getLogicalPresets();
    for (final item in list) {
      if (item.id == fontId) return item.displayName;
    }
    switch (fontId) {
      case idSansSerif:
        return 'Sans-Serif';
      case idSerif:
        return 'Serif';
      case idMonospace:
        return 'Monospace';
      case idCursive:
        return 'Cursive';
      default:
        return fontId;
    }
  }

  static Future<List<SystemFontItem>> scanInstalledFonts({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedFonts != null) {
      return _cachedFonts!;
    }

    final presets = getLogicalPresets();
    final Map<String, SystemFontItem> discovered = {};
    final excludedKeywords = [
      'emoji',
      'symbol',
      'dingbats',
      'glyphs',
      'clock',
      'weather',
      'barcode',
      'braille',
    ];

    try {
      if (Platform.isWindows) {
        final winFontsDir = Directory(r'C:\Windows\Fonts');
        final localAppData = Platform.environment['LOCALAPPDATA'];
        final userFontsDir = localAppData != null
            ? Directory('$localAppData\\Microsoft\\Windows\\Fonts')
            : null;

        for (final dir in [winFontsDir, if (userFontsDir != null) userFontsDir]) {
          if (await dir.exists()) {
            await for (final entity in dir.list(followLinks: false)) {
              if (entity is File &&
                  RegExp(r'\.(ttf|otf|ttc)$', caseSensitive: false).hasMatch(entity.path)) {
                final fileName = entity.uri.pathSegments.last;
                final lower = fileName.toLowerCase();
                if (excludedKeywords.any(lower.contains)) continue;
                final family = _cleanFontName(fileName);
                if (family.isNotEmpty && !discovered.containsKey(family)) {
                  discovered[family] = SystemFontItem(
                    id: family,
                    displayName: family,
                    subtitle: fileName,
                    fontFamily: family,
                  );
                }
              }
            }
          }
        }
      } else if (Platform.isAndroid) {
        for (final path in [
          '/system/fonts',
          '/product/fonts',
          '/system/product/fonts',
          '/vendor/fonts',
        ]) {
          final dir = Directory(path);
          if (await dir.exists()) {
            try {
              for (final entity in dir.listSync(followLinks: false)) {
                if (entity is File &&
                    RegExp(r'\.(ttf|otf|ttc)$', caseSensitive: false).hasMatch(entity.path)) {
                  final fileName = entity.uri.pathSegments.last;
                  final lower = fileName.toLowerCase();
                  if (excludedKeywords.any(lower.contains)) continue;
                  final family = _cleanFontName(fileName);
                  if (family.isNotEmpty && !discovered.containsKey(family)) {
                    discovered[family] = SystemFontItem(
                      id: family,
                      displayName: family,
                      subtitle: fileName,
                      fontFamily: family,
                    );
                  }
                }
              }
            } catch (_) {}
          }
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        try {
          final iosFonts = await _iosFontChannel.invokeListMethod<String>('getFamilyNames');
          if (iosFonts != null) {
            for (final f in iosFonts) {
              if (f.isNotEmpty && !discovered.containsKey(f)) {
                discovered[f] = SystemFontItem(
                  id: f,
                  displayName: f,
                  subtitle: 'Apple System Font',
                  fontFamily: f,
                );
              }
            }
          }
        } catch (_) {}
      } else if (Platform.isLinux) {
        for (final path in ['/usr/share/fonts', '/usr/local/share/fonts']) {
          final dir = Directory(path);
          if (await dir.exists()) {
            try {
              await for (final entity in dir.list(recursive: true, followLinks: false)) {
                if (entity is File &&
                    RegExp(r'\.(ttf|otf|ttc)$', caseSensitive: false).hasMatch(entity.path)) {
                  final fileName = entity.uri.pathSegments.last;
                  final lower = fileName.toLowerCase();
                  if (excludedKeywords.any(lower.contains)) continue;
                  final family = _cleanFontName(fileName);
                  if (family.isNotEmpty && !discovered.containsKey(family)) {
                    discovered[family] = SystemFontItem(
                      id: family,
                      displayName: family,
                      subtitle: fileName,
                      fontFamily: family,
                    );
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    final sortedDiscovered = discovered.values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    final result = [...presets, ...sortedDiscovered];
    _cachedFonts = result;
    return result;
  }

  static String _cleanFontName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'\.(ttf|otf|ttc)$', caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'[-_](ExtraLight|UltraLight|Thin|DemiLight|Light|Regular|Normal|Book|Medium|SemiBold|DemiBold|ExtraBold|UltraBold|Bold|Black|Heavy|Italic|Oblique|VF|Variable|Display|Text|UI).*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\d+$'), '')
        .replaceAll('_', ' ')
        .trim();
  }
}
