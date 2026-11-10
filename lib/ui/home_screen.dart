import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/decrypt/models/decrypt_models.dart';
import '../l10n/app_strings.dart';
import '../state/providers.dart';
import 'file_item_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDragging = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      ref.read(convertQueueProvider.notifier).addFiles(paths);
    }
  }

  void _showClearDialog() {
    showDialog(
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
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
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

    final totalCount = queue.items.length;
    final doneCount = queue.items
        .where((i) =>
            i.state == DecryptState.COMPLETED ||
            i.state == DecryptState.COMPLETED_NO_LYRIC)
        .length;
    final pendingCount = totalCount - doneCount;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        ref.read(convertQueueProvider.notifier).addFiles(paths);
      },
      child: Stack(
        children: [
          Scaffold(
            body: CustomScrollView(
              slivers: [
                // Top App Bar
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  title: Text(
                    AppStrings.get(context, 'home_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    if (totalCount > 0) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        tooltip: AppStrings.get(context, 'home_clear_list'),
                        onPressed: _showClearDialog,
                      ),
                    ],
                  ],
                ),
                // Dashboard Banner Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppStrings.get(context, 'home_m3e_badge'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (queue.isProcessing) ...[
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.get(context, 'home_decrypting'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              AppStrings.get(context, 'home_stats_total'),
                              '$totalCount',
                            ),
                            _buildStatItem(
                              context,
                              AppStrings.get(context, 'home_stats_done'),
                              '$doneCount',
                            ),
                            _buildStatItem(
                              context,
                              AppStrings.get(context, 'home_stats_pending'),
                              '$pendingCount',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action buttons in banner
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.add),
                              label: Text(AppStrings.get(context, 'home_pick_files')),
                              onPressed: _pickFiles,
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.sync),
                              label: Text(AppStrings.get(context, 'home_convert_all')),
                              onPressed: totalCount > 0 ? () => ref.read(convertQueueProvider.notifier).convertAll() : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Content: Empty hint or Items
                if (queue.items.isEmpty) ...[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.queue_music,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppStrings.get(context, 'home_empty_hint'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.get(context, 'home_empty_desc'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Multi-column or List
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                      final useGrid = (!isPortrait || themeState.portraitGridEnabled) && screenWidth >= 600;
                      final cols = useGrid ? themeState.gridColumns : 1;

                      if (cols > 1) {
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisExtent: 170,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return FileItemCard(item: queue.items[index]);
                              },
                              childCount: queue.items.length,
                            ),
                          ),
                        );
                      } else {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return FileItemCard(item: queue.items[index]);
                            },
                            childCount: queue.items.length,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          // Drag & Drop overlay
          if (_isDragging) ...[
            Positioned.fill(
              child: Container(
                color: colorScheme.primary.withOpacity(0.12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download_outlined, size: 48, color: colorScheme.primary),
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
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}
