import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/decrypt/models/decrypt_models.dart';
import '../l10n/app_strings.dart';
import '../state/convert_state_notifier.dart';
import '../state/providers.dart';
import 'file_item_card.dart';
import 'widgets/adaptive_controls_row.dart';

/// HomeScreen ported 1:1 from NCM-Converter-For-Android's HomeScreen.kt,
/// preserving desktop drag-and-drop import support for Runami-NCM.
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.onOpenSettings,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late final AnimationController _breatheController;
  late final Animation<double> _breatheScale;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breatheScale = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  void _handleAddReport(AddFilesReport report) {
    if (!mounted) return;
    if (report.addedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(context, 'home_no_ncm_selected'))),
      );
      return;
    }
    if (report.filteredOutCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(context, 'home_non_ncm_filtered'))),
      );
    }
    if (report.truncatedToMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(context, 'home_max_files'))),
      );
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      final report = ref.read(convertQueueProvider.notifier).addFiles(paths);
      _handleAddReport(report);
    }
  }

  Future<void> _saveItem(FileItem item) async {
    try {
      final path = await ref.read(convertQueueProvider.notifier).saveSingle(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(context, 'main_saved_to', [path]))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get(context, 'main_save_failed_msg', [e.toString()]),
            ),
          ),
        );
      }
    }
  }

  void _showClearDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppStrings.get(context, 'home_clear_dialog_title')),
          content: Text(AppStrings.get(context, 'home_clear_dialog_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get(context, 'home_cancel')),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                ref.read(convertQueueProvider.notifier).clearAll();
                Navigator.of(ctx).pop();
              },
              child: Text(AppStrings.get(context, 'home_clear_confirm')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(convertQueueProvider);
    final themeState = ref.watch(themeStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final files = queue.items;
    final isProcessing = queue.isProcessing;

    final totalCount = files.length;
    final doneCount = files
        .where((i) =>
            i.state == DecryptState.COMPLETED ||
            i.state == DecryptState.COMPLETED_NO_LYRIC)
        .length;
    final pendingCount = files
        .where((i) => i.state == DecryptState.IDLE || i.state == DecryptState.FAILED)
        .length;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final effectiveColumns = themeState.gridColumns <= 1
        ? 1
        : (isCompact
            ? (themeState.portraitGridEnabled ? themeState.gridColumns : 1)
            : themeState.gridColumns);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        final report = ref.read(convertQueueProvider.notifier).addFiles(paths);
        _handleAddReport(report);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              backgroundColor: colorScheme.surface,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.get(context, 'home_title'),
                    style: textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isProcessing)
                    Text(
                      AppStrings.get(context, 'home_decrypting'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              actions: [
                IconButton.filledTonal(
                  onPressed: widget.onOpenSettings,
                  tooltip: AppStrings.get(context, 'settings_title'),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    foregroundColor: colorScheme.onSurface,
                  ),
                  icon: const Icon(Icons.settings),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                // M3E Expressive Hero Dashboard Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdaptiveControlsRow(
                          horizontalSpacing: 8,
                          verticalSpacing: 8,
                          children: [
                            _M3EStatPill(
                              label: AppStrings.get(context, 'home_stats_total'),
                              value: totalCount.toString(),
                              containerColor: colorScheme.surfaceContainerHigh,
                              contentColor: colorScheme.onSurface,
                            ),
                            _M3EStatPill(
                              label: AppStrings.get(context, 'home_stats_done'),
                              value: doneCount.toString(),
                              containerColor:
                                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                              contentColor: colorScheme.onPrimaryContainer,
                            ),
                            _M3EStatPill(
                              label: AppStrings.get(context, 'home_stats_pending'),
                              value: pendingCount.toString(),
                              containerColor:
                                  colorScheme.secondaryContainer.withValues(alpha: 0.7),
                              contentColor: colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: isProcessing ? null : _pickFiles,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppStrings.get(context, 'home_pick_files'),
                                  style: textTheme.labelLarge?.copyWith(
                                    color: isProcessing
                                        ? colorScheme.onSurface.withValues(alpha: 0.38)
                                        : colorScheme.onPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty State or Responsive File Grid
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: files.isEmpty
                        ? _buildEmptyState(context, colorScheme, textTheme)
                        : _buildFileGrid(
                            files: files,
                            columns: effectiveColumns,
                            autoSave: themeState.autoSave,
                            enableCover: themeState.enableCover,
                          ),
                  ),
                ),
              ],
            ),
            // Animated Floating Bottom Action Bar
            bottomNavigationBar: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: files.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('empty_bottom'))
                    : SafeArea(
                        key: const ValueKey('active_bottom'),
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Material(
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.22),
                            color: colorScheme.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: AdaptiveControlsRow(
                                horizontalSpacing: 10,
                                verticalSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: files.isNotEmpty ? _showClearDialog : null,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.delete_sweep, size: 18),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            AppStrings.get(context, 'home_clear_list'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: (!isProcessing && pendingCount > 0)
                                        ? () => ref
                                            .read(convertQueueProvider.notifier)
                                            .convertAll()
                                        : null,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.bolt, size: 18),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            AppStrings.get(context, 'home_convert_all'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Desktop Drag & Drop Overlay
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.primary, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_download_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.get(context, 'drop_zone_active'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      key: const ValueKey('empty_state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _breatheScale,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.library_music,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.get(context, 'home_empty_hint'),
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get(context, 'home_empty_desc'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileGrid({
    required List<FileItem> files,
    required int columns,
    required bool autoSave,
    required bool enableCover,
  }) {
    final rowCount = (files.length + columns - 1) ~/ columns;

    return ListView.builder(
      key: const ValueKey('file_grid'),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final startIdx = rowIndex * columns;
        if (columns == 1) {
          final item = files[startIdx];
          return _AnimatedFileEntry(
            key: ValueKey(item.id),
            child: FileItemCard(
              item: item,
              onDecrypt: () =>
                  ref.read(convertQueueProvider.notifier).convertSingle(item.id),
              onRemove: () =>
                  ref.read(convertQueueProvider.notifier).removeFile(item.id),
              onSave: () => _saveItem(item),
              autoSave: autoSave,
              enableCover: enableCover,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int col = 0; col < columns; col++) ...[
                if (col > 0) const SizedBox(width: 4),
                Expanded(
                  child: (startIdx + col < files.length)
                      ? _AnimatedFileEntry(
                          key: ValueKey(files[startIdx + col].id),
                          child: FileItemCard(
                            item: files[startIdx + col],
                            onDecrypt: () => ref
                                .read(convertQueueProvider.notifier)
                                .convertSingle(files[startIdx + col].id),
                            onRemove: () => ref
                                .read(convertQueueProvider.notifier)
                                .removeFile(files[startIdx + col].id),
                            onSave: () => _saveItem(files[startIdx + col]),
                            autoSave: autoSave,
                            enableCover: enableCover,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedFileEntry extends StatefulWidget {
  final Widget child;

  const _AnimatedFileEntry({super.key, required this.child});

  @override
  State<_AnimatedFileEntry> createState() => _AnimatedFileEntryState();
}

class _AnimatedFileEntryState extends State<_AnimatedFileEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _M3EStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color containerColor;
  final Color contentColor;

  const _M3EStatPill({
    required this.label,
    required this.value,
    required this.containerColor,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
              color: contentColor,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              color: contentColor.withValues(alpha: 0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
