import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/app_prefs.dart';
import '../../l10n/app_strings.dart';

class LogDialog extends StatefulWidget {
  const LogDialog({super.key});

  @override
  State<LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<LogDialog> {
  String _selectedLevel = AppPrefs.logLevel;
  String _selectedFormat = AppPrefs.logFormat;

  @override
  Widget build(BuildContext context) {
    final entries = AppLogger.getEntries(_selectedLevel);
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and options
              Row(
                children: [
                  Icon(Icons.terminal, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.get(context, 'log_dialog_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Level dropdown
                  DropdownButton<String>(
                    value: _selectedLevel,
                    underline: const SizedBox(),
                    items: [
                      AppPrefs.LOG_LEVEL_VERBOSE,
                      AppPrefs.LOG_LEVEL_DEBUG,
                      AppPrefs.LOG_LEVEL_INFO,
                      AppPrefs.LOG_LEVEL_WARN,
                      AppPrefs.LOG_LEVEL_ERROR,
                    ].map((lvl) {
                      return DropdownMenuItem(value: lvl, child: Text(lvl));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLevel = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Logs view box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.get(context, 'log_empty'),
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, idx) {
                            final e = entries[idx];
                            Color levelColor = colorScheme.onSurface;
                            if (e.level == AppPrefs.LOG_LEVEL_ERROR) {
                              levelColor = colorScheme.error;
                            } else if (e.level == AppPrefs.LOG_LEVEL_WARN) {
                              levelColor = Colors.orange;
                            } else if (e.level == AppPrefs.LOG_LEVEL_INFO) {
                              levelColor = colorScheme.primary;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: SelectableText(
                                e.format(_selectedFormat),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: levelColor,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(AppStrings.get(context, 'log_action_clear')),
                    onPressed: () {
                      AppLogger.clear();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.get(context, 'log_clear_confirm'))),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(AppStrings.get(context, 'log_action_copy')),
                    onPressed: () {
                      final logs = AppLogger.exportLogs(
                        format: _selectedFormat,
                        minLevel: _selectedLevel,
                      );
                      Clipboard.setData(ClipboardData(text: logs));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.get(context, 'log_copied'))),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.get(context, 'instructions_close')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
