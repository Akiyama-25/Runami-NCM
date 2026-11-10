import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_prefs.dart';

class FileUtils {
  static Future<Directory> getDefaultOutputDirectory() async {
    final customPath = AppPrefs.customPath.trim();

    if (Platform.isAndroid) {
      final extDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
      if (extDirs != null && extDirs.isNotEmpty) {
        final base = extDirs.first;
        final dir = Directory(p.join(base.path, customPath.isNotEmpty ? customPath : 'NCMConverter'));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userProfile != null) {
        final musicPath = p.join(userProfile, customPath.isNotEmpty ? customPath : r'Music\NCMConverter');
        final dir = Directory(musicPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, customPath.isNotEmpty ? customPath : 'ConvertedMusic'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    // Fallback for Linux or unexpected platform
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'NCMConverter'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}
