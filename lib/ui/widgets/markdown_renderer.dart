import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

sealed class _MarkdownBlock {
  const _MarkdownBlock();
}

class _HeadingBlock extends _MarkdownBlock {
  final int level;
  final String text;
  const _HeadingBlock(this.level, this.text);
}

class _ParagraphBlock extends _MarkdownBlock {
  final String text;
  const _ParagraphBlock(this.text);
}

class _BulletItemBlock extends _MarkdownBlock {
  final int indent;
  final String text;
  const _BulletItemBlock(this.indent, this.text);
}

class _OrderedItemBlock extends _MarkdownBlock {
  final int indent;
  final String number;
  final String text;
  const _OrderedItemBlock(this.indent, this.number, this.text);
}

class _BlockQuoteBlock extends _MarkdownBlock {
  final String text;
  const _BlockQuoteBlock(this.text);
}

class _CodeBlock extends _MarkdownBlock {
  final String language;
  final String code;
  const _CodeBlock(this.language, this.code);
}

class _TableBlock extends _MarkdownBlock {
  final List<String> headers;
  final List<List<String>> rows;
  const _TableBlock(this.headers, this.rows);
}

class _DividerBlock extends _MarkdownBlock {
  const _DividerBlock();
}

class _MarkdownParser {
  static final RegExp _headingRegex = RegExp(r'^(#{1,6})\s+(.*)$');
  static final RegExp _hrRegex = RegExp(r'^(\*{3,}|-{3,}|_{3,})\s*$');
  static final RegExp _bulletRegex = RegExp(r'^(\s*)([-*•·])\s+(.*)$');
  static final RegExp _orderedRegex = RegExp(r'^(\s*)(\d+)\.\s+(.*)$');

  static bool _isTableSeparator(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
    if (!trimmed.contains('-')) return false;
    final cells = trimmed.split('|');
    if (cells.length < 2) return false;
    return cells.every((cell) {
      var core = cell.trim();
      if (core.startsWith(':')) core = core.substring(1);
      if (core.endsWith(':')) core = core.substring(0, core.length - 1);
      return core.length >= 2 && RegExp(r'^-+$').hasMatch(core);
    });
  }

  static List<String> _parseTableRow(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed.split('|').map((e) => e.trim()).toList();
  }

  static List<_MarkdownBlock> parse(String markdown) {
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_MarkdownBlock>[];
    int i = 0;

    while (i < lines.length) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // 1. Fenced Code Block
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++;
        blocks.add(_CodeBlock(lang, codeLines.join('\n')));
        continue;
      }

      // 2. Horizontal Rule
      if (_hrRegex.hasMatch(trimmed)) {
        blocks.add(const _DividerBlock());
        i++;
        continue;
      }

      // 3. Heading
      final headingMatch = _headingRegex.firstMatch(trimmed);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final text = headingMatch.group(2)!.trim();
        blocks.add(_HeadingBlock(level, text));
        i++;
        continue;
      }

      // 4. Blockquote
      if (trimmed.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quoteLines.add(lines[i].trim().substring(1).trimLeft());
          i++;
        }
        blocks.add(_BlockQuoteBlock(quoteLines.join('\n')));
        continue;
      }

      // 5. Markdown Table
      if (trimmed.contains('|') && i + 1 < lines.length && _isTableSeparator(lines[i + 1])) {
        final headers = _parseTableRow(trimmed);
        i += 2;
        final rows = <List<String>>[];
        while (i < lines.length && lines[i].trim().isNotEmpty && lines[i].trim().contains('|')) {
          rows.add(_parseTableRow(lines[i].trim()));
          i++;
        }
        blocks.add(_TableBlock(headers, rows));
        continue;
      }

      // 6. Bullet List Item
      final bulletMatch = _bulletRegex.firstMatch(rawLine);
      if (bulletMatch != null) {
        final indent = bulletMatch.group(1)!.length ~/ 2;
        final text = bulletMatch.group(3)!.trim();
        blocks.add(_BulletItemBlock(indent, text));
        i++;
        continue;
      }

      // 7. Ordered List Item
      final orderedMatch = _orderedRegex.firstMatch(rawLine);
      if (orderedMatch != null) {
        final indent = orderedMatch.group(1)!.length ~/ 2;
        final number = orderedMatch.group(2)!;
        final text = orderedMatch.group(3)!.trim();
        blocks.add(_OrderedItemBlock(indent, number, text));
        i++;
        continue;
      }

      // 8. Paragraph
      final paraLines = <String>[];
      while (i < lines.length) {
        final curRaw = lines[i];
        final curTrim = curRaw.trim();
        if (curTrim.isEmpty ||
            curTrim.startsWith('```') ||
            _hrRegex.hasMatch(curTrim) ||
            _headingRegex.hasMatch(curTrim) ||
            curTrim.startsWith('>') ||
            _bulletRegex.hasMatch(curRaw) ||
            _orderedRegex.hasMatch(curRaw) ||
            (curTrim.contains('|') && i + 1 < lines.length && _isTableSeparator(lines[i + 1]))) {
          break;
        }
        paraLines.add(curTrim);
        i++;
      }
      if (paraLines.isNotEmpty) {
        blocks.add(_ParagraphBlock(paraLines.join('\n')));
      } else {
        i++;
      }
    }

    return blocks;
  }
}

/// Custom M3E Markdown renderer ported 1:1 from NCM-Converter-For-Android's MarkdownRenderer.kt.
class MarkdownRenderer extends StatelessWidget {
  final String markdown;

  const MarkdownRenderer({super.key, required this.markdown});

  static final RegExp _inlineTokenRegex = RegExp(
    r'(`[^`]+`)|(\*\*\*[^*]+\*\*\*)|(\*\*[^*]+\*\*)|(__[^_]+__)|(\*[^*\n]+\*)|(_[^_\n]+_)|(~~[^~]+~~)|(\[([^\]]+)\]\(([^)]+)\))|(https?://[^\s)]+)',
  );

  @override
  Widget build(BuildContext context) {
    final blocks = _MarkdownParser.parse(markdown);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildBlock(blocks[i], colorScheme, textTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildBlock(
    _MarkdownBlock block,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    switch (block) {
      case _HeadingBlock():
        return _buildHeading(block.level, block.text, colorScheme, textTheme);
      case _ParagraphBlock():
        return Text.rich(
          _parseInline(block.text, colorScheme),
          style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontSize: 14,
            height: 21 / 14,
            color: colorScheme.onSurface,
          ),
        );
      case _BulletItemBlock():
        return Padding(
          padding: EdgeInsets.only(left: block.indent * 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                width: block.indent == 0 ? 6 : 5,
                height: block.indent == 0 ? 6 : 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: block.indent == 0 ? colorScheme.primary : colorScheme.secondary,
                ),
              ),
              Expanded(
                child: Text.rich(
                  _parseInline(block.text, colorScheme),
                  style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      case _OrderedItemBlock():
        return Padding(
          padding: EdgeInsets.only(left: block.indent * 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  block.number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  _parseInline(block.text, colorScheme),
                  style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockQuoteBlock():
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: colorScheme.primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text.rich(
                      _parseInline(block.text, colorScheme),
                      style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                        fontSize: 13,
                        height: 19 / 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case _CodeBlock():
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.language.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    block.language.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  block.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 18 / 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      case _TableBlock():
        return _buildTable(block.headers, block.rows, colorScheme);
      case _DividerBlock():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        );
    }
  }

  Widget _buildHeading(
    int level,
    String text,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final double fontSize;
    final FontWeight fontWeight;
    final Color color;
    final double topPad;

    switch (level) {
      case 1:
        fontSize = 19;
        fontWeight = FontWeight.bold;
        color = colorScheme.primary;
        topPad = 4;
        break;
      case 2:
        fontSize = 16;
        fontWeight = FontWeight.w600;
        color = colorScheme.primary;
        topPad = 6;
        break;
      case 3:
        fontSize = 14;
        fontWeight = FontWeight.w600;
        color = colorScheme.secondary;
        topPad = 4;
        break;
      default:
        fontSize = 13;
        fontWeight = FontWeight.w500;
        color = colorScheme.onSurface;
        topPad = 2;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            _parseInline(text, colorScheme),
            style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: (fontSize + 5) / fontSize,
            ),
          ),
          if (level == 1) ...[
            const SizedBox(height: 4),
            Divider(
              height: 1.5,
              thickness: 1.5,
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable(
    List<String> headers,
    List<List<String>> rows,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: colorScheme.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                for (int i = 0; i < headers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      _parseInline(headers[i], colorScheme),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final row in rows) ...[
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  for (int col = 0; col < headers.length; col++) ...[
                    if (col > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        _parseInline(col < row.length ? row[col] : '', colorScheme),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InlineSpan _parseInline(String text, ColorScheme colorScheme) {
    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in _inlineTokenRegex.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final token = match.group(0)!;

      if (match.group(1) != null) {
        // Inline code `code`
        final content = token.substring(1, token.length - 1);
        spans.add(
          TextSpan(
            text: ' $content ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.45),
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // Bold + Italic ***text***
        spans.add(
          TextSpan(
            text: token.substring(3, token.length - 3),
            style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(3) != null || match.group(4) != null) {
        // Bold **text** or __text__
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        );
      } else if (match.group(5) != null || match.group(6) != null) {
        // Italic *text* or _text_
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(7) != null) {
        // Strikethrough ~~text~~
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
        );
      } else if (match.group(8) != null) {
        // Link [label](url)
        final label = match.group(9) ?? token;
        final url = match.group(10) ?? '';
        spans.add(
          TextSpan(
            text: label,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
      } else if (match.group(11) != null) {
        // Bare URL
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final uri = Uri.tryParse(token);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(children: spans);
  }
}
