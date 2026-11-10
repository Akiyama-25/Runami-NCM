import 'package:flutter_test/flutter_test.dart';
import 'package:runami_ncm/core/lyric/lrc_parser.dart';
import 'package:runami_ncm/core/lyric/similarity_calculator.dart';
import 'package:runami_ncm/core/theme/hsl_color.dart';

void main() {
  group('LrcParser Tests', () {
    test('parses timestamped lines correctly', () {
      const lrc = '[00:01.500]Hello world\n[00:03.200]Flutter multiplatform';
      final parsed = LrcParser.parse(lrc);

      expect(parsed.length, 2);
      expect(parsed[0].timestamp, 1500);
      expect(parsed[0].text, 'Hello world');
      expect(parsed[1].timestamp, 3200);
      expect(parsed[1].text, 'Flutter multiplatform');
    });

    test('merges original and translated lines by timestamp', () {
      final orig = [
        const LyricLine(1000, 'Hello'),
        const LyricLine(2000, 'World'),
      ];
      final trans = [
        const LyricLine(1000, '你好'),
        const LyricLine(2000, '世界'),
      ];

      final merged = LrcParser.merge(orig, trans);
      expect(merged.contains('Hello'), true);
      expect(merged.contains('你好'), true);
      expect(merged.contains('World'), true);
      expect(merged.contains('世界'), true);
    });
  });

  group('SimilarityCalculator Tests', () {
    test('exact match returns 1.0', () {
      expect(SimilarityCalculator.calculateSimilarity('Song Name', 'Song Name'), 1.0);
    });

    test('case insensitive match returns 1.0', () {
      expect(SimilarityCalculator.calculateSimilarity('Song Name', 'song name'), 1.0);
    });

    test('different strings return similarity ratio', () {
      final sim = SimilarityCalculator.calculateSimilarity('Komorebi', 'Komorebi (Instrumental)');
      expect(sim, greaterThan(0.3));
    });
  });

  group('HslColorUtil Tests', () {
    test('converts HSL to Color correctly', () {
      final color = HslColorUtil.hslToColor(141, 73, 41);
      expect(color.alpha, 255);
      expect(color.green, greaterThan(color.red));
    });
  });
}
