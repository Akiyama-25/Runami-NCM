import 'dart:io';
import 'package:flutter/services.dart';

class SystemFontItem {
  final String id;
  final String displayName;
  final String? fontFamily;

  const SystemFontItem({
    required this.id,
    required this.displayName,
    this.fontFamily,
  });
}

class SystemFontScanner {
  static const String idSystemDefault = 'system_default';
  static const MethodChannel _iosFontChannel =
      MethodChannel('ncm.converter/system_fonts');

  static final List<SystemFontItem> _standardFallbackFonts = [
    const SystemFontItem(id: 'system_default', displayName: '系统默认字体', fontFamily: null),
    const SystemFontItem(id: 'sans-serif', displayName: 'Sans-Serif (无衬线)', fontFamily: 'sans-serif'),
    const SystemFontItem(id: 'serif', displayName: 'Serif (衬线)', fontFamily: 'serif'),
    const SystemFontItem(id: 'monospace', displayName: 'Monospace (等宽)', fontFamily: 'monospace'),
    const SystemFontItem(id: 'Microsoft YaHei UI', displayName: '微软雅黑 UI', fontFamily: 'Microsoft YaHei UI'),
    const SystemFontItem(id: 'PingFang SC', displayName: '苹方 (PingFang SC)', fontFamily: 'PingFang SC'),
    const SystemFontItem(id: 'Noto Sans CJK SC', displayName: '思源黑体 (Noto Sans SC)', fontFamily: 'Noto Sans CJK SC'),
    const SystemFontItem(id: 'MiSans', displayName: '小米字体 (MiSans)', fontFamily: 'MiSans'),
    const SystemFontItem(id: 'HarmonyOS Sans SC', displayName: '鸿蒙字体 (HarmonyOS Sans)', fontFamily: 'HarmonyOS Sans SC'),
  ];

  static Future<List<SystemFontItem>> scanInstalledFonts() async {
    final Map<String, SystemFontItem> fontMap = {};

    for (final item in _standardFallbackFonts) {
      fontMap[item.displayName] = item;
    }

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
                final family = _cleanFontName(entity.uri.pathSegments.last);
                if (family.isNotEmpty && !fontMap.containsKey(family)) {
                  fontMap[family] = SystemFontItem(
                    id: family,
                    displayName: family,
                    fontFamily: family,
                  );
                }
              }
            }
          }
        }
      } else if (Platform.isAndroid) {
        for (final path in ['/system/fonts', '/product/fonts']) {
          final dir = Directory(path);
          if (await dir.exists()) {
            for (final entity in dir.listSync(followLinks: false)) {
              if (entity is File &&
                  RegExp(r'\.(ttf|otf)$', caseSensitive: false).hasMatch(entity.path)) {
                final family = _cleanFontName(entity.uri.pathSegments.last);
                if (family.isNotEmpty && !fontMap.containsKey(family)) {
                  fontMap[family] = SystemFontItem(
                    id: family,
                    displayName: family,
                    fontFamily: family,
                  );
                }
              }
            }
          }
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        try {
          final iosFonts = await _iosFontChannel.invokeListMethod<String>('getFamilyNames');
          if (iosFonts != null) {
            for (final f in iosFonts) {
              if (!fontMap.containsKey(f)) {
                fontMap[f] = SystemFontItem(id: f, displayName: f, fontFamily: f);
              }
            }
          }
        } catch (_) {
          // Fallback handled
        }
      }
    } catch (_) {
      // Ignore scan errors and use standard fallbacks
    }

    final list = fontMap.values.toList();
    list.sort((a, b) {
      if (a.id == idSystemDefault) return -1;
      if (b.id == idSystemDefault) return 1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return list;
  }

  static String _cleanFontName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'\.(ttf|otf|ttc)$', caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'[-_](Regular|Bold|Medium|Light|Thin|Heavy|Black|SemiBold|ExtraLight|Italic|Display|Text|UI).*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\d+$'), '')
        .trim();
  }
}
