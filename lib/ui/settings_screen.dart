import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/hsl_color.dart';
import '../core/theme/system_font_scanner.dart';
import '../core/utils/app_prefs.dart';
import '../l10n/app_strings.dart';
import '../state/providers.dart';
import 'widgets/adaptive_controls_row.dart';
import 'widgets/font_picker_sheet.dart';
import 'widgets/hsl_picker_sheet.dart';
import 'widgets/instructions_dialog.dart';
import 'widgets/log_dialog.dart';

/// SettingsScreen ported 1:1 from NCM-Converter-For-Android's SettingsScreen.kt.
class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final bool supportsDynamicColor;

  const SettingsScreen({
    super.key,
    required this.onBack,
    this.supportsDynamicColor = false,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double? _draggingColumns;

  Future<void> _pickOutputFolder() async {
    final selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null && selectedDir.isNotEmpty) {
      ref.read(themeStateProvider.notifier).setCustomPath(selectedDir);
    }
  }

  void _showColumnsToOneDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppStrings.get(context, 'pref_grid_columns')),
          content: Text(AppStrings.get(context, 'columns_dialog_msg')),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _draggingColumns = null);
                Navigator.of(ctx).pop();
              },
              child: Text(AppStrings.get(context, 'home_cancel')),
            ),
            TextButton(
              onPressed: () {
                ref.read(themeStateProvider.notifier).setGridColumns(1);
                setState(() => _draggingColumns = null);
                Navigator.of(ctx).pop();
              },
              child: Text(AppStrings.get(context, 'dialog_confirm')),
            ),
          ],
        );
      },
    );
  }

  void _openHslSheet({
    required bool isAccent,
    required bool isDark,
    required Color initialColor,
  }) {
    final hsl = HslColorUtil.colorToHsl(initialColor);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => HslPickerSheet(
        title: AppStrings.get(
          context,
          isAccent ? 'pref_custom_hsl_accent' : 'pref_custom_hsl_bg',
        ),
        initialH: hsl[0],
        initialS: hsl[1],
        initialL: hsl[2],
        onColorChanged: (argb, h, s, l) {
          final notifier = ref.read(themeStateProvider.notifier);
          if (isAccent) {
            notifier.setAccentHsl(argb, h, s, l);
          } else {
            notifier.setBgHsl(argb, h, s, l, isDark);
          }
        },
      ),
    );
  }

  void _openFontPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (_) => const FontPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeStateProvider);
    final fontsAsync = ref.watch(installedFontsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final twoCols = themeState.gridColumns > 1 && screenWidth >= 600;
    final scannedFonts = fontsAsync.valueOrNull ?? SystemFontScanner.getLogicalPresets();

    final showMonetToggle = widget.supportsDynamicColor || Platform.isAndroid;
    final showColorPickers = !showMonetToggle || !themeState.useMonetColors;

    final displayedColumns = (_draggingColumns ?? themeState.gridColumns.toDouble()).round();
    final isSimplifiedChinese = AppStrings.isSimplifiedChinese(context, themeState.appLanguage);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: IconButton.filledTonal(
              onPressed: widget.onBack,
              tooltip: AppStrings.get(context, 'settings_back'),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
              ),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        title: Text(
          AppStrings.get(context, 'settings_title'),
          style: textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // ── Display & M3E Theme ──
          _SectionHeader(AppStrings.get(context, 'section_display')),

          _pairOrStack(
            twoCols: twoCols,
            first: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(context, 'pref_theme_mode'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AdaptiveControlsRow(
                    horizontalSpacing: 6,
                    verticalSpacing: 6,
                    children: [
                      _ThemeChip(
                        label: AppStrings.get(context, 'pref_theme_system'),
                        selected: themeState.themeModeCode == AppPrefs.THEME_SYSTEM,
                        onTap: () => ref
                            .read(themeStateProvider.notifier)
                            .setThemeMode(AppPrefs.THEME_SYSTEM),
                      ),
                      _ThemeChip(
                        label: AppStrings.get(context, 'pref_theme_light'),
                        selected: themeState.themeModeCode == AppPrefs.THEME_LIGHT,
                        onTap: () => ref
                            .read(themeStateProvider.notifier)
                            .setThemeMode(AppPrefs.THEME_LIGHT),
                      ),
                      _ThemeChip(
                        label: AppStrings.get(context, 'pref_theme_dark'),
                        selected: themeState.themeModeCode == AppPrefs.THEME_DARK,
                        onTap: () => ref
                            .read(themeStateProvider.notifier)
                            .setThemeMode(AppPrefs.THEME_DARK),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            second: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(context, 'pref_language'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _StyledDropdown<String>(
                    currentValue: _normalizeLanguageCode(themeState.appLanguage),
                    options: [
                      ('system', AppStrings.get(context, 'lang_system')),
                      ('zh', AppStrings.get(context, 'lang_zh')),
                      ('zh_tw', AppStrings.get(context, 'lang_zh_tw')),
                      ('en', AppStrings.get(context, 'lang_en')),
                      ('ja', AppStrings.get(context, 'lang_ja')),
                    ],
                    onSelected: (code) {
                      ref.read(themeStateProvider.notifier).setAppLanguage(code);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Grid Columns Slider (full span)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get(context, 'pref_grid_columns'),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: displayedColumns.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (val) {
                          setState(() => _draggingColumns = val);
                        },
                        onChangeEnd: (val) {
                          final next = val.round();
                          if (next == 1 && themeState.gridColumns > 1) {
                            _showColumnsToOneDialog();
                          } else {
                            ref.read(themeStateProvider.notifier).setGridColumns(next);
                            setState(() => _draggingColumns = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.get(context, 'pref_grid_columns_value', [displayedColumns]),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Portrait Multi-column Switch (animated visibility when gridColumns > 1)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: themeState.gridColumns > 1
                ? _SettingSwitch(
                    title: AppStrings.get(context, 'pref_portrait_grid'),
                    subtitle: AppStrings.get(
                      context,
                      themeState.portraitGridEnabled
                          ? 'pref_portrait_grid_on'
                          : 'pref_portrait_grid_off',
                    ),
                    checked: themeState.portraitGridEnabled,
                    onChanged: (val) => ref
                        .read(themeStateProvider.notifier)
                        .setPortraitGridEnabled(val),
                  )
                : const SizedBox.shrink(),
          ),

          // FlClash-Style System Installed Font Selector & Weight Control Card
          _SystemFontSettingCard(
            selectedFontId: themeState.systemFontId,
            fontWeight: themeState.fontWeight,
            scannedCount: scannedFonts.length,
            onOpenPicker: _openFontPickerSheet,
            onWeightChanged: (w) =>
                ref.read(themeStateProvider.notifier).setFontWeight(w),
            onResetDefault: () {
              final notifier = ref.read(themeStateProvider.notifier);
              notifier.setSystemFont(SystemFontScanner.idSystemDefault);
              notifier.setFontWeight(400);
            },
          ),

          // Material You Dynamic Colors Switch
          if (showMonetToggle)
            _SettingSwitch(
              title: AppStrings.get(context, 'pref_monet'),
              subtitle: AppStrings.get(
                context,
                themeState.useMonetColors ? 'pref_monet_on' : 'pref_monet_off',
              ),
              checked: themeState.useMonetColors,
              onChanged: (newValue) {
                final notifier = ref.read(themeStateProvider.notifier);
                if (!newValue) {
                  // Snapshot current dynamic scheme primary & surface into custom colors
                  final accentHsl = HslColorUtil.colorToHsl(colorScheme.primary);
                  final bgHsl = HslColorUtil.colorToHsl(colorScheme.surface);
                  notifier.setAccentHsl(
                    colorScheme.primary.toARGB32(),
                    accentHsl[0],
                    accentHsl[1],
                    accentHsl[2],
                  );
                  notifier.setBgHsl(
                    colorScheme.surface.toARGB32(),
                    bgHsl[0],
                    bgHsl[1],
                    bgHsl[2],
                    isDark,
                  );
                }
                notifier.setUseMonetColors(newValue);
              },
            ),

          // Accent & Background Color Pickers (animated visibility when custom colors active)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: showColorPickers
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 12),
                        child: Text(
                          AppStrings.get(context, 'pref_accent_color'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      _ColorPickerRow(
                        colors: kAccentColorPresets,
                        selectedColor: Color(themeState.customAccentColor),
                        onColorSelected: (color) {
                          final hsl = HslColorUtil.colorToHsl(color);
                          ref.read(themeStateProvider.notifier).setAccentHsl(
                                color.toARGB32(),
                                hsl[0],
                                hsl[1],
                                hsl[2],
                              );
                        },
                        onCustomClick: () => _openHslSheet(
                          isAccent: true,
                          isDark: isDark,
                          initialColor: Color(themeState.customAccentColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 12),
                        child: Text(
                          AppStrings.get(context, 'pref_bg_color'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      _ColorPickerRow(
                        colors: isDark ? kDarkBgColorPresets : kLightBgColorPresets,
                        selectedColor: Color(
                          isDark
                              ? themeState.customDarkBgColor
                              : themeState.customLightBgColor,
                        ),
                        onColorSelected: (color) {
                          final hsl = HslColorUtil.colorToHsl(color);
                          ref.read(themeStateProvider.notifier).setBgHsl(
                                color.toARGB32(),
                                hsl[0],
                                hsl[1],
                                hsl[2],
                                isDark,
                              );
                        },
                        onCustomClick: () => _openHslSheet(
                          isAccent: false,
                          isDark: isDark,
                          initialColor: Color(
                            isDark
                                ? themeState.customDarkBgColor
                                : themeState.customLightBgColor,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Conversion ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _SectionHeader(AppStrings.get(context, 'section_convert')),

          InkWell(
            onTap: _pickOutputFolder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(context, 'pref_save_path'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          themeState.customPath,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _pairOrStack(
            twoCols: twoCols,
            first: _SettingSwitch(
              title: AppStrings.get(context, 'pref_auto_save'),
              subtitle: AppStrings.get(
                context,
                themeState.autoSave ? 'pref_auto_save_on' : 'pref_auto_save_off',
              ),
              checked: themeState.autoSave,
              onChanged: (val) =>
                  ref.read(themeStateProvider.notifier).setAutoSave(val),
            ),
            second: _SettingSwitch(
              title: AppStrings.get(context, 'pref_auto_cover'),
              subtitle: AppStrings.get(
                context,
                themeState.enableCover ? 'pref_auto_cover_on' : 'pref_auto_cover_off',
              ),
              checked: themeState.enableCover,
              onChanged: (val) =>
                  ref.read(themeStateProvider.notifier).setEnableCover(val),
            ),
          ),

          // ── Lyrics ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _SectionHeader(AppStrings.get(context, 'section_lyrics')),

          _SettingSwitch(
            title: AppStrings.get(context, 'pref_auto_lyric'),
            subtitle: AppStrings.get(
              context,
              themeState.enableLyric ? 'pref_auto_lyric_on' : 'pref_auto_lyric_off',
            ),
            checked: themeState.enableLyric,
            onChanged: (val) =>
                ref.read(themeStateProvider.notifier).setEnableLyric(val),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: themeState.enableLyric
                ? _pairOrStack(
                    twoCols: twoCols,
                    first: _SettingSwitch(
                      title: AppStrings.get(context, 'pref_lyric_original'),
                      subtitle: AppStrings.get(
                        context,
                        themeState.lyricEmbedOriginal
                            ? 'pref_lyric_original_on'
                            : 'pref_lyric_original_off',
                      ),
                      checked: themeState.lyricEmbedOriginal,
                      onChanged: (val) => ref
                          .read(themeStateProvider.notifier)
                          .setLyricEmbedOriginal(val),
                    ),
                    second: _SettingSwitch(
                      title: AppStrings.get(context, 'pref_lyric_translated'),
                      subtitle: themeState.lyricEmbedTranslated
                          ? (isSimplifiedChinese
                              ? AppStrings.get(context, 'pref_lyric_translated_on')
                              : '${AppStrings.get(context, 'pref_lyric_translated_on')} ${AppStrings.get(context, 'pref_lyric_translated_note')}')
                          : AppStrings.get(context, 'pref_lyric_translated_off'),
                      checked: themeState.lyricEmbedTranslated,
                      onChanged: (val) => ref
                          .read(themeStateProvider.notifier)
                          .setLyricEmbedTranslated(val),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Debug ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _SectionHeader(AppStrings.get(context, 'section_debug')),

          InkWell(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => LogDialog(
                  logLevel: themeState.logLevel,
                  logFormat: themeState.logFormat,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(context, 'pref_log'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          AppStrings.get(context, 'pref_log_desc'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _pairOrStack(
            twoCols: twoCols,
            first: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(context, 'pref_log_level'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _StyledDropdown<String>(
                    currentValue: themeState.logLevel,
                    options: const [
                      (AppPrefs.LOG_LEVEL_VERBOSE, 'VERBOSE'),
                      (AppPrefs.LOG_LEVEL_DEBUG, 'DEBUG'),
                      (AppPrefs.LOG_LEVEL_INFO, 'INFO'),
                      (AppPrefs.LOG_LEVEL_WARN, 'WARN'),
                      (AppPrefs.LOG_LEVEL_ERROR, 'ERROR'),
                    ],
                    onSelected: (level) =>
                        ref.read(themeStateProvider.notifier).setLogLevel(level),
                  ),
                ],
              ),
            ),
            second: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(context, 'pref_log_format'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _StyledDropdown<String>(
                    currentValue: themeState.logFormat.toLowerCase(),
                    options: [
                      ('log', AppStrings.get(context, 'log_format_default')),
                      ('txt', '.txt'),
                      ('md', '.md'),
                    ],
                    onSelected: (fmt) =>
                        ref.read(themeStateProvider.notifier).setLogFormat(fmt),
                  ),
                ],
              ),
            ),
          ),

          // ── About ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _SectionHeader(AppStrings.get(context, 'section_about')),

          InkWell(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => const InstructionsDialog(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(context, 'pref_instructions'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          AppStrings.get(context, 'pref_instructions_desc'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          InkWell(
            onTap: () {
              launchUrl(
                Uri.parse('https://github.com/Akiyama-25/Runami-NCM'),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.get(context, 'pref_github'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.get(context, 'pref_github_url'),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairOrStack({
    required bool twoCols,
    required Widget first,
    required Widget second,
  }) {
    if (!twoCols) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        Expanded(child: second),
      ],
    );
  }

  String _normalizeLanguageCode(String code) {
    if (code == 'zh-SC') return 'zh';
    if (code == 'zh-TC') return 'zh_tw';
    if (const {'system', 'zh', 'zh_tw', 'en', 'ja'}.contains(code)) return code;
    return 'system';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.transparent : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: checked, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T currentValue;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  const _StyledDropdown({
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String currentLabel = currentValue.toString();
    for (final (val, label) in options) {
      if (val == currentValue) {
        currentLabel = label;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        itemBuilder: (context) {
          return options.map((entry) {
            final (val, label) = entry;
            final isSelected = val == currentValue;
            return PopupMenuItem<T>(
              value: val,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label),
                  if (isSelected) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.check, size: 18, color: colorScheme.primary),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemFontSettingCard extends StatelessWidget {
  final String selectedFontId;
  final int fontWeight;
  final int scannedCount;
  final VoidCallback onOpenPicker;
  final ValueChanged<int> onWeightChanged;
  final VoidCallback onResetDefault;

  const _SystemFontSettingCard({
    required this.selectedFontId,
    required this.fontWeight,
    required this.scannedCount,
    required this.onOpenPicker,
    required this.onWeightChanged,
    required this.onResetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final defaultFontLabel = AppStrings.get(context, 'font_system');
    final activeFontName = SystemFontScanner.getDisplayName(
      selectedFontId,
      defaultLabel: defaultFontLabel,
    );

    final rawWeightIndex = kAppFontWeights.indexWhere((w) => w.weight == fontWeight);
    final weightIndex = rawWeightIndex >= 0 ? rawWeightIndex : 3;
    final weightLabel = kAppFontWeights[weightIndex].label;
    final isNonDefault = !SystemFontScanner.isDefaultFontId(selectedFontId) || fontWeight != 400;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onOpenPicker,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.font_download,
                                size: 22,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.get(context, 'pref_font'),
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  AppStrings.get(
                                    context,
                                    'font_scanned_count',
                                    [scannedCount],
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                activeFontName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.unfold_more,
                              size: 16,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Live Typography Preview Box
            Material(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onOpenPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    AppStrings.get(context, 'font_preview_sample'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Font Weight Step Slider (100..900)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.get(context, 'font_weight'),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weightLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (isNonDefault) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onResetDefault,
                        child: Text(
                          AppStrings.get(context, 'font_reset_default'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            Slider(
              value: weightIndex.toDouble(),
              min: 0,
              max: (kAppFontWeights.length - 1).toDouble(),
              divisions: kAppFontWeights.length - 1,
              onChanged: (idx) {
                final clamped = idx.round().clamp(0, kAppFontWeights.length - 1);
                onWeightChanged(kAppFontWeights[clamped].weight);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final List<ColorPresetOption> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onCustomClick;

  const _ColorPickerRow({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onCustomClick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < colors.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            _buildSwatch(colors[i], colorScheme),
          ],
          const SizedBox(width: 12),
          // Custom Rainbow HSL Button
          GestureDetector(
            onTap: onCustomClick,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.cyan,
                    Colors.blue,
                    Color(0xFFFF00FF),
                    Colors.red,
                  ],
                ),
                border: Border.all(color: colorScheme.outlineVariant, width: 1),
              ),
              child: const Center(
                child: Icon(Icons.edit, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatch(ColorPresetOption option, ColorScheme colorScheme) {
    final isSelected = selectedColor.toARGB32() == option.color.toARGB32();

    return GestureDetector(
      onTap: () => onColorSelected(option.color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: option.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.onSurface : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  size: 18,
                  color: option.color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
