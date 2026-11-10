import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/system_font_scanner.dart';
import '../core/utils/app_prefs.dart';
import '../l10n/app_strings.dart';
import '../state/providers.dart';
import 'widgets/font_picker_sheet.dart';
import 'widgets/hsl_picker_dialog.dart';
import 'widgets/instructions_dialog.dart';
import 'widgets/log_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get(context, 'settings_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Appearance Section
          _buildSectionHeader(context, AppStrings.get(context, 'section_display'), Icons.palette_outlined),
          Card(
            child: Column(
              children: [
                // Theme Mode
                ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: Text(AppStrings.get(context, 'pref_theme_mode')),
                  trailing: DropdownButton<String>(
                    value: AppPrefs.themeMode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: AppPrefs.THEME_SYSTEM,
                        child: Text(AppStrings.get(context, 'pref_theme_system')),
                      ),
                      DropdownMenuItem(
                        value: AppPrefs.THEME_LIGHT,
                        child: Text(AppStrings.get(context, 'pref_theme_light')),
                      ),
                      DropdownMenuItem(
                        value: AppPrefs.THEME_DARK,
                        child: Text(AppStrings.get(context, 'pref_theme_dark')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(themeStateProvider.notifier).setThemeMode(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                // Language
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(AppStrings.get(context, 'pref_language')),
                  trailing: DropdownButton<String>(
                    value: AppPrefs.appLanguage,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(AppStrings.get(context, 'lang_system')),
                      ),
                      DropdownMenuItem(
                        value: 'zh',
                        child: Text(AppStrings.get(context, 'lang_zh')),
                      ),
                      DropdownMenuItem(
                        value: 'zh_tw',
                        child: Text(AppStrings.get(context, 'lang_zh_tw')),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(AppStrings.get(context, 'lang_en')),
                      ),
                      DropdownMenuItem(
                        value: 'ja',
                        child: Text(AppStrings.get(context, 'lang_ja')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(themeStateProvider.notifier).setAppLanguage(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                // Grid Columns
                ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: Text(AppStrings.get(context, 'pref_grid_columns')),
                  subtitle: Text(AppStrings.get(context, 'pref_grid_columns_value', [themeState.gridColumns])),
                  trailing: SizedBox(
                    width: 140,
                    child: Slider(
                      value: themeState.gridColumns.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${themeState.gridColumns}',
                      onChanged: (val) {
                        ref.read(themeStateProvider.notifier).setGridColumns(val.toInt());
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Portrait Multi-Column
                SwitchListTile(
                  secondary: const Icon(Icons.stay_current_portrait),
                  title: Text(AppStrings.get(context, 'pref_portrait_grid')),
                  subtitle: Text(
                    themeState.portraitGridEnabled
                        ? AppStrings.get(context, 'pref_portrait_grid_on')
                        : AppStrings.get(context, 'pref_portrait_grid_off'),
                  ),
                  value: themeState.portraitGridEnabled,
                  onChanged: (val) {
                    ref.read(themeStateProvider.notifier).setPortraitGridEnabled(val);
                  },
                ),
                const Divider(height: 1),
                // Monet dynamic colors
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome),
                  title: Text(AppStrings.get(context, 'pref_monet')),
                  subtitle: Text(
                    themeState.useMonetColors
                        ? AppStrings.get(context, 'pref_monet_on')
                        : AppStrings.get(context, 'pref_monet_off'),
                  ),
                  value: themeState.useMonetColors,
                  onChanged: (val) {
                    ref.read(themeStateProvider.notifier).setUseMonetColors(val);
                  },
                ),
                if (!themeState.useMonetColors) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.color_lens),
                    title: Text(AppStrings.get(context, 'pref_custom_hsl_accent')),
                    trailing: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(themeState.customAccentColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => HslPickerDialog(
                          title: AppStrings.get(context, 'pref_custom_hsl_accent'),
                          initialH: themeState.customAccentH,
                          initialS: themeState.customAccentS,
                          initialL: themeState.customAccentL,
                          onColorSelected: (argb, h, s, l) {
                            ref.read(themeStateProvider.notifier).setAccentHsl(argb, h, s, l);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. System Fonts (FlClash style)
          _buildSectionHeader(context, AppStrings.get(context, 'pref_font'), Icons.font_download_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: Text(AppStrings.get(context, 'pref_font')),
                  subtitle: Text(
                    themeState.systemFontId == SystemFontScanner.idSystemDefault
                        ? AppStrings.get(context, 'font_system')
                        : themeState.systemFontId,
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const FontPickerSheet(),
                      );
                    },
                    child: Text(AppStrings.get(context, 'font_picker_title').split(' ')[0]),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.format_bold),
                  title: Text('${AppStrings.get(context, 'font_weight')}: ${themeState.fontWeight}'),
                  subtitle: Slider(
                    value: themeState.fontWeight.toDouble(),
                    min: 100,
                    max: 900,
                    divisions: 8,
                    label: '${themeState.fontWeight}',
                    onChanged: (val) {
                      ref.read(themeStateProvider.notifier).setFontWeight(val.toInt());
                    },
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(themeStateProvider.notifier).setSystemFont(SystemFontScanner.idSystemDefault);
                      ref.read(themeStateProvider.notifier).setFontWeight(400);
                    },
                    child: Text(AppStrings.get(context, 'font_reset_default')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Conversion Section
          _buildSectionHeader(context, AppStrings.get(context, 'section_convert'), Icons.swap_horiz),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(AppStrings.get(context, 'pref_save_path')),
                  subtitle: Text(AppPrefs.customPath),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final selectedDir = await FilePicker.platform.getDirectoryPath();
                      if (selectedDir != null && selectedDir.isNotEmpty) {
                        AppPrefs.customPath = selectedDir;
                        ref.read(themeStateProvider.notifier); // Trigger rebuild
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.save),
                  title: Text(AppStrings.get(context, 'pref_auto_save')),
                  subtitle: Text(
                    AppPrefs.autoSave
                        ? AppStrings.get(context, 'pref_auto_save_on')
                        : AppStrings.get(context, 'pref_auto_save_off'),
                  ),
                  value: AppPrefs.autoSave,
                  onChanged: (val) {
                    AppPrefs.autoSave = val;
                    (context as Element).markNeedsBuild();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.image_outlined),
                  title: Text(AppStrings.get(context, 'pref_auto_cover')),
                  subtitle: Text(
                    AppPrefs.enableCover
                        ? AppStrings.get(context, 'pref_auto_cover_on')
                        : AppStrings.get(context, 'pref_auto_cover_off'),
                  ),
                  value: AppPrefs.enableCover,
                  onChanged: (val) {
                    AppPrefs.enableCover = val;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Lyrics Section
          _buildSectionHeader(context, AppStrings.get(context, 'section_lyrics'), Icons.subtitles_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lyrics_outlined),
                  title: Text(AppStrings.get(context, 'pref_auto_lyric')),
                  subtitle: Text(
                    AppPrefs.enableLyric
                        ? AppStrings.get(context, 'pref_auto_lyric_on')
                        : AppStrings.get(context, 'pref_auto_lyric_off'),
                  ),
                  value: AppPrefs.enableLyric,
                  onChanged: (val) {
                    AppPrefs.enableLyric = val;
                    (context as Element).markNeedsBuild();
                  },
                ),
                if (AppPrefs.enableLyric) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.text_snippet_outlined),
                    title: Text(AppStrings.get(context, 'pref_lyric_original')),
                    value: AppPrefs.lyricEmbedOriginal,
                    onChanged: (val) {
                      AppPrefs.lyricEmbedOriginal = val;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.translate_outlined),
                    title: Text(AppStrings.get(context, 'pref_lyric_translated')),
                    subtitle: Text(AppStrings.get(context, 'pref_lyric_translated_note')),
                    value: AppPrefs.lyricEmbedTranslated,
                    onChanged: (val) {
                      AppPrefs.lyricEmbedTranslated = val;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Diagnostics & Logging
          _buildSectionHeader(context, AppStrings.get(context, 'section_debug'), Icons.bug_report_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.terminal),
                  title: Text(AppStrings.get(context, 'pref_log')),
                  subtitle: Text(AppStrings.get(context, 'pref_log_desc')),
                  trailing: FilledButton.tonal(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const LogDialog(),
                      );
                    },
                    child: Text(AppStrings.get(context, 'log_action_export')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. About Section
          _buildSectionHeader(context, AppStrings.get(context, 'section_about'), Icons.info_outline),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.album_outlined),
                  title: Text(AppStrings.get(context, 'pref_github')),
                  subtitle: const Text('Version 1.0.0 (Flutter M3E Multiplatform)'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    launchUrl(Uri.parse('https://${AppStrings.get(context, 'pref_github_url')}'));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(AppStrings.get(context, 'pref_instructions')),
                  subtitle: Text(AppStrings.get(context, 'pref_instructions_desc')),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const InstructionsDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
