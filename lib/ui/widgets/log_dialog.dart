import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/app_logger.dart';
import '../../core/utils/file_utils.dart';
import '../../l10n/app_strings.dart';
import 'adaptive_controls_row.dart';
import 'markdown_renderer.dart';

/// Runtime Logs AlertDialog ported 1:1 from NCM-Converter-For-Android SettingsScreen.kt.
class LogDialog extends StatefulWidget {
  final String logLevel;
  final String logFormat;

  const LogDialog({
    super.key,
    required this.logLevel,
    required this.logFormat,
  });

  @override
  State<LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<LogDialog> {
  late String _logText;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    final entries = AppLogger.getEntries(widget.logLevel);
    if (entries.isEmpty) {
      _logText = '';
      return;
    }
    _logText = AppLogger.exportLogs(
      format: widget.logFormat,
      minLevel: widget.logLevel,
    );
  }

  Future<void> _exportLogs() async {
    final content = _logText.isEmpty
        ? AppStrings.get(context, 'log_empty')
        : _logText;
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'runami_ncm_log_$stamp.${widget.logFormat}';

    try {
      String? targetPath;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        targetPath = await FilePicker.platform.saveFile(
          dialogTitle: AppStrings.get(context, 'log_share_title'),
          fileName: fileName,
        );
        if (targetPath == null) return;
      } else {
        final outDir = await FileUtils.getDefaultOutputDirectory();
        targetPath = p.join(outDir.path, fileName);
      }

      final file = File(targetPath);
      await file.writeAsString(content, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(context, 'log_exported_to', [targetPath])),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(context, 'log_export_failed', [e.toString()])),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayLog = _logText.isEmpty
        ? AppStrings.get(context, 'log_empty')
        : _logText;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              AppStrings.get(context, 'log_dialog_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${widget.logLevel} · .${widget.logFormat})',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 450,
            maxWidth: 560,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: widget.logFormat.toLowerCase() == 'md'
                        ? MarkdownRenderer(markdown: displayLog)
                        : SelectableText(
                            displayLog,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AdaptiveControlsRow(
                horizontalSpacing: 8,
                verticalSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      AppLogger.clear();
                      setState(_refreshLogs);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.get(context, 'log_clear_confirm')),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.get(context, 'log_action_clear'),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: displayLog));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.get(context, 'log_copied')),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.content_copy, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.get(context, 'log_action_copy'),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _exportLogs,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.get(context, 'log_action_export'),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.get(context, 'instructions_close')),
        ),
      ],
    );
  }
}
