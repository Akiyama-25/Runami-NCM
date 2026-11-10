import 'package:flutter/material.dart';
import '../utils/app_prefs.dart';
import 'hsl_color.dart';

class ThemeEngine {
  static FontWeight resolveWeight(int baseWeight, int offset) {
    final target = (baseWeight + offset).clamp(100, 900);
    final index = (target ~/ 100) - 1;
    return FontWeight.values[index.clamp(0, FontWeight.values.length - 1)];
  }

  static TextTheme _buildTextTheme(String? fontFamily, int baseWeight) {
    final base = Typography.material2021().black.apply(fontFamily: fontFamily);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: resolveWeight(baseWeight, 300)),
      displayMedium: base.displayMedium?.copyWith(fontWeight: resolveWeight(baseWeight, 300)),
      displaySmall: base.displaySmall?.copyWith(fontWeight: resolveWeight(baseWeight, 200)),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: resolveWeight(baseWeight, 200)),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: resolveWeight(baseWeight, 200)),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: resolveWeight(baseWeight, 100)),
      titleLarge: base.titleLarge?.copyWith(fontWeight: resolveWeight(baseWeight, 200)),
      titleMedium: base.titleMedium?.copyWith(fontWeight: resolveWeight(baseWeight, 100)),
      titleSmall: base.titleSmall?.copyWith(fontWeight: resolveWeight(baseWeight, 100)),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: resolveWeight(baseWeight, 0)),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: resolveWeight(baseWeight, 0)),
      bodySmall: base.bodySmall?.copyWith(fontWeight: resolveWeight(baseWeight, 0)),
      labelLarge: base.labelLarge?.copyWith(fontWeight: resolveWeight(baseWeight, 100)),
      labelMedium: base.labelMedium?.copyWith(fontWeight: resolveWeight(baseWeight, 100)),
      labelSmall: base.labelSmall?.copyWith(fontWeight: resolveWeight(baseWeight, 0)),
    );
  }

  static ThemeData buildTheme({
    required Brightness brightness,
    ColorScheme? dynamicColorScheme,
    required String? fontFamily,
    required int baseWeight,
  }) {
    final isDark = brightness == Brightness.dark;

    // 1. Resolve ColorScheme
    ColorScheme scheme;
    if (AppPrefs.useMonetColors && dynamicColorScheme != null) {
      scheme = dynamicColorScheme;
    } else {
      final accent = HslColorUtil.hslToColor(
        AppPrefs.customAccentH,
        AppPrefs.customAccentS,
        AppPrefs.customAccentL,
      );
      scheme = ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      );
    }

    final textTheme = _buildTextTheme(fontFamily, baseWeight);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: isDark ? scheme.surfaceContainerLowest : scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 3,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
      ),
      textTheme: textTheme,
    );
  }
}
