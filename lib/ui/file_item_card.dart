import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/decrypt/models/decrypt_models.dart';
import '../core/utils/file_utils.dart';
import '../l10n/app_strings.dart';
import '../state/providers.dart';

class FileItemCard extends ConsumerWidget {
  final FileItem item;

  const FileItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = item.state == DecryptState.COMPLETED ||
        item.state == DecryptState.COMPLETED_NO_LYRIC;
    final isFailed = item.state == DecryptState.FAILED;
    final isWorking = item.state == DecryptState.PARSING ||
        item.state == DecryptState.DECRYPTING ||
        item.state == DecryptState.SEARCHING_LYRIC ||
        item.state == DecryptState.WRITING_META;

    String stateLabel = AppStrings.get(context, 'file_wait');
    Color stateColor = colorScheme.outline;

    switch (item.state) {
      case DecryptState.PARSING:
        stateLabel = AppStrings.get(context, 'file_parsing');
        stateColor = colorScheme.primary;
        break;
      case DecryptState.DECRYPTING:
        final pct = (item.progress * 100).toInt();
        stateLabel = '${AppStrings.get(context, 'file_decrypting')} $pct%';
        stateColor = colorScheme.primary;
        break;
      case DecryptState.SEARCHING_LYRIC:
        stateLabel = AppStrings.get(context, 'file_searching_lyric');
        stateColor = colorScheme.secondary;
        break;
      case DecryptState.WRITING_META:
        stateLabel = AppStrings.get(context, 'file_writing_meta');
        stateColor = colorScheme.tertiary;
        break;
      case DecryptState.COMPLETED:
        stateLabel = AppStrings.get(context, 'file_completed');
        stateColor = Colors.green;
        break;
      case DecryptState.COMPLETED_NO_LYRIC:
        stateLabel = '${AppStrings.get(context, 'file_completed')} (${AppStrings.get(context, 'file_no_lyric')})';
        stateColor = Colors.teal;
        break;
      case DecryptState.FAILED:
        stateLabel = AppStrings.get(context, 'file_failed');
        stateColor = colorScheme.error;
        break;
      case DecryptState.IDLE:
        stateLabel = AppStrings.get(context, 'file_wait');
        stateColor = colorScheme.outline;
        break;
    }

    final displayName = (item.result?.metadata.musicName.isNotEmpty ?? false) &&
            item.result!.metadata.musicName != 'Unknown'
        ? item.result!.metadata.musicName
        : item.name;

    final artists = item.result?.metadata.artists.join('/') ?? '';
    final extBadge = item.result?.extension.toUpperCase();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isDone ? Icons.music_note : Icons.audiotrack,
                      color: isDone ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Song Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (extBadge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                extBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artists.isNotEmpty
                            ? '$artists · ${FileUtils.formatFileSize(item.size)}'
                            : FileUtils.formatFileSize(item.size),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // State badge
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: stateColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: stateColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Progress Bar if working
            if (isWorking) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress > 0.0 ? item.progress : null,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                ),
              ),
            ],
            // Action Buttons Footer
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.state == DecryptState.IDLE || isFailed) ...[
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(AppStrings.get(context, 'file_action_decrypt')),
                    onPressed: () {
                      ref.read(convertQueueProvider.notifier).convertSingle(item.id);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (isDone) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: Icon(
                      item.outputPath != null ? Icons.check : Icons.save_alt,
                      size: 18,
                    ),
                    label: Text(
                      item.outputPath != null
                          ? AppStrings.get(context, 'file_completed')
                          : AppStrings.get(context, 'file_action_save'),
                    ),
                    onPressed: item.outputPath != null
                        ? null
                        : () async {
                            try {
                              final path = await ref
                                  .read(convertQueueProvider.notifier)
                                  .saveSingle(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppStrings.get(context, 'main_saved_to', [path]),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppStrings.get(context, 'main_save_failed_msg', [e.toString()]),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: AppStrings.get(context, 'file_action_remove'),
                  onPressed: () {
                    ref.read(convertQueueProvider.notifier).removeFile(item.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
