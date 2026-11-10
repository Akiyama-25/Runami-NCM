class LyricLine {
  final int timestamp; // Milliseconds
  final String text;

  const LyricLine(this.timestamp, this.text);
}

class LrcParser {
  static final RegExp _timestampPattern =
      RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

  static List<LyricLine> parse(String? lrcText) {
    if (lrcText == null || lrcText.trim().isEmpty) return const [];

    final lines = lrcText.split('\n');
    final result = <LyricLine>[];

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed != null) {
        result.add(parsed);
      }
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  static String merge(List<LyricLine> original, List<LyricLine> translated) {
    if (original.isEmpty) return '';
    if (translated.isEmpty) return toLrcString(original);

    final transMap = {for (final t in translated) t.timestamp: t.text};
    final merged = <LyricLine>[];

    for (final line in original) {
      final transText = transMap[line.timestamp];
      if (transText != null && transText.trim().isNotEmpty) {
        final formattedTrans =
            '${line.text}\n${_formatTimestamp(line.timestamp)}${transText.trim()}';
        merged.add(LyricLine(line.timestamp, formattedTrans));
      } else {
        merged.add(line);
      }
    }

    return toLrcString(merged);
  }

  static String toLrcString(List<LyricLine> lines) {
    return lines.map((l) => '${_formatTimestamp(l.timestamp)}${l.text}').join('\n');
  }

  static LyricLine? _parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final match = _timestampPattern.firstMatch(trimmed);
    if (match == null) return null;

    final min = int.tryParse(match.group(1) ?? '');
    final sec = int.tryParse(match.group(2) ?? '');
    final msStr = (match.group(3) ?? '').padRight(3, '0');
    final ms = int.tryParse(msStr);
    final text = match.group(4) ?? '';

    if (min == null || sec == null || ms == null) return null;

    final totalMs = min * 60000 + sec * 1000 + ms;
    return LyricLine(totalMs, text.trim());
  }

  static String _formatTimestamp(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = ms % 1000;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    final msStr = millis.toString().padLeft(3, '0');
    return '[$minStr:$secStr.$msStr]';
  }
}
