import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class ThemeEngine {
  static FontWeight resolveWeight(int baseWeight, int offset) {
    final target = (baseWeight + offset).clamp(100, 900);
    final index = (target ~/ 100) - 1;
    return FontWeight.values[index.clamp(0, FontWeight.values.length - 1)];
  }

  static TextTheme _buildTextTheme(
    Brightness brightness,
    String? fontFamily,
    int baseWeight,
    ColorScheme scheme,
  ) {
    final base = (brightness == Brightness.dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(
      fontFamily: fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final bodyW = resolveWeight(baseWeight, 0);
    final mediumW = resolveWeight(baseWeight, 100);
    final strongW = resolveWeight(baseWeight, 200);

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: strongW, letterSpacing: -0.5),
      displayMedium: base.displayMedium?.copyWith(fontWeight: strongW, letterSpacing: -0.25),
      displaySmall: base.displaySmall?.copyWith(fontWeight: strongW),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: strongW, letterSpacing: -0.25),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: strongW),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: mediumW),
      titleLarge: base.titleLarge?.copyWith(fontWeight: strongW),
      titleMedium: base.titleMedium?.copyWith(fontWeight: mediumW, letterSpacing: 0.1),
      titleSmall: base.titleSmall?.copyWith(fontWeight: mediumW),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: bodyW),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: bodyW),
      bodySmall: base.bodySmall?.copyWith(fontWeight: bodyW),
      labelLarge: base.labelLarge?.copyWith(fontWeight: mediumW),
      labelMedium: base.labelMedium?.copyWith(fontWeight: mediumW),
      labelSmall: base.labelSmall?.copyWith(fontWeight: bodyW),
    );
  }

  static ThemeData buildTheme({
    required Brightness brightness,
    required bool useMonetColors,
    required Color accentColor,
    required Color bgColor,
    ColorScheme? dynamicColorScheme,
    required String? fontFamily,
    required int baseWeight,
  }) {
    final isDark = brightness == Brightness.dark;
    final monetActive = useMonetColors && dynamicColorScheme != null;

    // Step 1: Resolve base scheme (Material You dynamic or M3E default)
    final baseScheme = monetActive
        ? dynamicColorScheme
        : (isDark ? defaultDarkColorScheme : defaultLightColorScheme);

    // Step 2: Apply user custom accent, bg & M3E surface container hierarchy
    final scheme = applyUserColors(
      baseScheme,
      darkTheme: isDark,
      accent: accentColor,
      bg: bgColor,
      monetEnabled: monetActive,
    );

    // Step 3: Build M3E expressive typography
    final textTheme = _buildTextTheme(brightness, fontFamily, baseWeight, scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      textTheme: textTheme,
    );
  }
}
