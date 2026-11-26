import 'package:flutter/material.dart';
import '../core/decrypt/models/decrypt_models.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_strings.dart';

/// File item card ported 1:1 from NCM-Converter-For-Android's FileItemView.kt.
class FileItemCard extends StatelessWidget {
  final FileItem item;
  final VoidCallback onDecrypt;
  final VoidCallback onRemove;
  final VoidCallback onSave;
  final bool autoSave;
  final bool enableCover;

  const FileItemCard({
    super.key,
    required this.item,
    required this.onDecrypt,
    required this.onRemove,
    required this.onSave,
    required this.autoSave,
    required this.enableCover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    final isDone = item.state == DecryptState.COMPLETED ||
        item.state == DecryptState.COMPLETED_NO_LYRIC;
    final isFailed = item.state == DecryptState.FAILED;

    final borderColor = isDone
        ? kSuccessColor.withValues(alpha: 0.35)
        : isFailed
            ? kErrorColor.withValues(alpha: 0.4)
            : colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Album Cover or M3E Expressive Tonal Icon Container (48x48, radius 14)
                _buildLeadingArtwork(
                  colorScheme: colorScheme,
                  isDone: isDone,
                  isFailed: isFailed,
                ),
                const SizedBox(width: 12),

                // File Name & Metadata Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                          fontSize: 14,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // File size pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatFileSize(item.size),
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ),

                          // Extension badge (MP3 / FLAC)
                          if (item.result?.extension.isNotEmpty ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.result!.extension.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),

                          // LRC badge
                          if (item.result?.lyric != null && item.result!.lyric!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kSuccessColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lyrics,
                                    size: 12,
                                    color: kSuccessColor,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'LRC',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: kSuccessColor,
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

                const SizedBox(width: 4),

                // M3E Inline Action Pill Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.state == DecryptState.IDLE || item.state == DecryptState.FAILED)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton.filledTonal(
                          onPressed: onDecrypt,
                          padding: EdgeInsets.zero,
                          tooltip: AppStrings.get(context, 'file_action_decrypt'),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                          icon: const Icon(Icons.play_arrow, size: 20),
                        ),
                      )
                    else if (isDone && !autoSave)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton.filledTonal(
                          onPressed: onSave,
                          padding: EdgeInsets.zero,
                          tooltip: AppStrings.get(context, 'file_action_save'),
                          style: IconButton.styleFrom(
                            backgroundColor: kSuccessColor.withValues(alpha: 0.18),
                            foregroundColor: kSuccessColor,
                          ),
                          icon: const Icon(Icons.save_alt, size: 20),
                        ),
                      ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        tooltip: AppStrings.get(context, 'file_action_remove'),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Expressive Status Row & Progress Indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                    alignment: Alignment.centerLeft,
                    child: child,
                  ),
                );
              },
              child: Align(
                key: ValueKey(item.state),
                alignment: Alignment.centerLeft,
                child: _buildStatusRow(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingArtwork({
    required ColorScheme colorScheme,
    required bool isDone,
    required bool isFailed,
  }) {
    final coverBytes = item.result?.coverBytes;
    final rawAlbumPic = item.result?.metadata.albumPic.trim() ?? '';
    final albumPic = rawAlbumPic.replaceFirst(
      RegExp(r'^http://', caseSensitive: false),
      'https://',
    );

    Widget fallbackIcon() {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDone
              ? kSuccessColor.withValues(alpha: 0.14)
              : isFailed
                  ? kErrorColor.withValues(alpha: 0.14)
                  : colorScheme.primaryContainer.withValues(alpha: 0.65),
        ),
        child: Center(
          child: Icon(
            Icons.audio_file,
            size: 26,
            color: isDone
                ? kSuccessColor
                : isFailed
                    ? kErrorColor
                    : colorScheme.primary,
          ),
        ),
      );
    }

    if (enableCover && coverBytes != null && coverBytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          coverBytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackIcon(),
        ),
      );
    }

    if (enableCover && albumPic.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          albumPic,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackIcon(),
        ),
      );
    }

    return fallbackIcon();
  }

  Widget _buildStatusRow(BuildContext context, ColorScheme colorScheme) {
    final primaryColor = colorScheme.primary;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final extUpper = item.result?.extension.toUpperCase() ?? '';

    switch (item.state) {
      case DecryptState.IDLE:
        return Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              AppStrings.get(context, 'file_wait'),
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
          ],
        );

      case DecryptState.PARSING:
      case DecryptState.DECRYPTING:
      case DecryptState.WRITING_META:
        final label = switch (item.state) {
          DecryptState.PARSING => AppStrings.get(context, 'file_parsing'),
          DecryptState.DECRYPTING =>
            AppStrings.get(context, 'file_decrypting', [(item.progress * 100).toInt()]),
          DecryptState.WRITING_META => AppStrings.get(context, 'file_writing_meta'),
          _ => '',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: primaryColor),
                ),
              ],
            ),
            if (item.state == DecryptState.DECRYPTING) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: item.progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 220),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      color: primaryColor,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    );
                  },
                ),
              ),
            ],
          ],
        );

      case DecryptState.SEARCHING_LYRIC:
        return Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.get(context, 'file_searching_lyric'),
              style: TextStyle(fontSize: 12, color: primaryColor),
            ),
          ],
        );

      case DecryptState.COMPLETED:
        return Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: kSuccessColor),
            const SizedBox(width: 6),
            Text(
              AppStrings.get(context, 'file_completed', [extUpper]),
              style: const TextStyle(fontSize: 12, color: kSuccessColor),
            ),
          ],
        );

      case DecryptState.COMPLETED_NO_LYRIC:
        return Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16, color: kSuccessColor),
                const SizedBox(width: 6),
                Text(
                  AppStrings.get(context, 'file_completed', [extUpper]),
                  style: const TextStyle(fontSize: 12, color: kSuccessColor),
                ),
              ],
            ),
            Text(
              '· ${AppStrings.get(context, 'file_no_lyric')}',
              style: TextStyle(fontSize: 11, color: onSurfaceVariant),
            ),
          ],
        );

      case DecryptState.FAILED:
        return Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: kErrorColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.error ?? AppStrings.get(context, 'file_failed'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: kErrorColor),
              ),
            ),
          ],
        );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${bytes ~/ 1024} KB';
    return '${(bytes / (1024.0 * 1024.0)).toStringAsFixed(1)} MB';
  }
}
