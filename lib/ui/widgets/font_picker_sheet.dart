import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/system_font_scanner.dart';
import '../../l10n/app_strings.dart';
import '../../state/providers.dart';

class FontPickerSheet extends ConsumerStatefulWidget {
  const FontPickerSheet({super.key});

  @override
  ConsumerState<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends ConsumerState<FontPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

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

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.font_download_outlined, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.get(context, 'font_picker_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.get(context, 'font_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filter = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
                ),
              ),
              // Font weight quick slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${AppStrings.get(context, 'font_weight')}: ${themeState.fontWeight}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Expanded(
                      child: Slider(
                        value: themeState.fontWeight.toDouble(),
                        min: 100,
                        max: 900,
                        divisions: 8,
                        label: '${themeState.fontWeight}',
                        onChanged: (val) {
                          ref.read(themeStateProvider.notifier).setFontWeight(val.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Font list
              Expanded(
                child: fontsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (fonts) {
                    final filtered = fonts.where((f) {
                      if (_filter.isEmpty) return true;
                      return f.displayName.toLowerCase().contains(_filter) ||
                          f.id.toLowerCase().contains(_filter);
                    }).toList();

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final font = filtered[index];
                        final isSelected = font.id == themeState.systemFontId;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer.withOpacity(0.5)
                                : colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              font.displayName,
                              style: TextStyle(
                                fontFamily: font.fontFamily,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                AppStrings.get(context, 'font_preview_sample'),
                                style: TextStyle(
                                  fontFamily: font.fontFamily,
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: colorScheme.primary)
                                : null,
                            onTap: () {
                              ref.read(themeStateProvider.notifier).setSystemFont(font.id);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
