import 'package:intl/intl.dart';
import 'app_prefs.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String format(String formatType) {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    if (formatType == AppPrefs.LOG_FORMAT_MD) {
      return '- **`$timeStr`** `[$level]` `[$tag]` $message';
    } else if (formatType == AppPrefs.LOG_FORMAT_TXT) {
      return '$timeStr [$level/$tag]: $message';
    } else {
      return '$timeStr $level/$tag: $message';
    }
  }
}

class AppLogger {
  static const int maxEntries = 1000;
  static final List<LogEntry> _logs = [];

  static void v(String tag, String message) => _log(AppPrefs.LOG_LEVEL_VERBOSE, tag, message);
  static void d(String tag, String message) => _log(AppPrefs.LOG_LEVEL_DEBUG, tag, message);
  static void i(String tag, String message) => _log(AppPrefs.LOG_LEVEL_INFO, tag, message);
  static void w(String tag, String message) => _log(AppPrefs.LOG_LEVEL_WARN, tag, message);
  static void e(String tag, String message) => _log(AppPrefs.LOG_LEVEL_ERROR, tag, message);

  static void _log(String level, String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _logs.add(entry);
    if (_logs.length > maxEntries) {
      _logs.removeAt(0);
    }
    // Print to developer console
    print('${entry.level}/${entry.tag}: ${entry.message}');
  }

  static List<LogEntry> getEntries([String? minLevel]) {
    final currentMin = minLevel ?? AppPrefs.logLevel;
    final priorityOrder = [
      AppPrefs.LOG_LEVEL_VERBOSE,
      AppPrefs.LOG_LEVEL_DEBUG,
      AppPrefs.LOG_LEVEL_INFO,
      AppPrefs.LOG_LEVEL_WARN,
      AppPrefs.LOG_LEVEL_ERROR,
    ];

    final minIndex = priorityOrder.indexOf(currentMin);
    return _logs.where((entry) {
      final entryIndex = priorityOrder.indexOf(entry.level);
      return entryIndex >= minIndex;
    }).toList();
  }

  static String exportLogs({String? format, String? minLevel}) {
    final targetFormat = format ?? AppPrefs.logFormat;
    final entries = getEntries(minLevel);
    if (entries.isEmpty) return 'No logs available.';

    final buffer = StringBuffer();
    if (targetFormat == AppPrefs.LOG_FORMAT_MD) {
      buffer.writeln('# NCM Converter Runtime Logs');
      buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}\n');
    }

    for (final entry in entries) {
      buffer.writeln(entry.format(targetFormat));
    }
    return buffer.toString();
  }

  static void clear() {
    _logs.clear();
  }
}
