import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/system_font_scanner.dart';
import '../../core/theme/theme_engine.dart';
import '../../l10n/app_strings.dart';
import '../../state/providers.dart';

/// FlClash-Style System Installed Font Picker ModalBottomSheet,
/// ported 1:1 from NCM-Converter-For-Android SettingsScreen.kt.
class FontPickerSheet extends ConsumerStatefulWidget {
  const FontPickerSheet({super.key});

  @override
  ConsumerState<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends ConsumerState<FontPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontsAsync = ref.watch(installedFontsProvider);
    final themeState = ref.watch(themeStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final weight = ThemeEngine.resolveWeight(themeState.fontWeight, 0);

    final systemFonts = fontsAsync.valueOrNull ?? SystemFontScanner.getLogicalPresets();
    final filteredFonts = _searchQuery.trim().isEmpty
        ? systemFonts
        : systemFonts.where((f) {
            final q = _searchQuery.trim().toLowerCase();
            return f.displayName.toLowerCase().contains(q) ||
                f.subtitle.toLowerCase().contains(q);
          }).toList();

    final maxSheetHeight = MediaQuery.of(context).size.height * 0.82;

    return SizedBox(
      height: maxSheetHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(context, 'font_picker_title'),
                        style: textTheme.titleMedium?.copyWith(fontSize: 17),
                      ),
                      Text(
                        AppStrings.get(context, 'font_scanned_count', [systemFonts.length]),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final notifier = ref.read(themeStateProvider.notifier);
                    notifier.setSystemFont(SystemFontScanner.idSystemDefault);
                    notifier.setFontWeight(400);
                  },
                  child: Text(AppStrings.get(context, 'font_reset_default')),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: AppStrings.get(context, 'font_search_hint'),
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Font List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 28),
                itemCount: filteredFonts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = filteredFonts[index];
                  final isSelected = entry.id == themeState.systemFontId ||
                      (SystemFontScanner.isDefaultFontId(entry.id) &&
                          SystemFontScanner.isDefaultFontId(themeState.systemFontId));

                  return Material(
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.75)
                        : colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isSelected
                          ? BorderSide(color: colorScheme.primary, width: 1.5)
                          : BorderSide.none,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ref.read(themeStateProvider.notifier).setSystemFont(entry.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          entry.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: entry.fontFamily,
                                            fontWeight: weight,
                                            fontSize: 15,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (entry.isBuiltInLogical) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'OS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppStrings.get(context, 'font_preview_sample'),
                                    style: TextStyle(
                                      fontFamily: entry.fontFamily,
                                      fontWeight: weight,
                                      fontSize: 13,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    entry.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
