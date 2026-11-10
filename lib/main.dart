import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/theme_engine.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/app_prefs.dart';
import 'state/providers.dart';
import 'ui/adaptive_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(960, 680),
        minimumSize: Size(640, 480),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'Runami NCM',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      AppLogger.w('Main', 'Failed to configure window_manager: $e');
    }
  }

  runApp(const ProviderScope(child: RunamiNcmApp()));
}

class RunamiNcmApp extends ConsumerWidget {
  const RunamiNcmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateProvider);

    Locale? resolvedLocale;
    if (themeState.appLanguage == 'zh') {
      resolvedLocale = const Locale('zh', 'CN');
    } else if (themeState.appLanguage == 'zh_tw') {
      resolvedLocale = const Locale('zh', 'TW');
    } else if (themeState.appLanguage == 'en') {
      resolvedLocale = const Locale('en', 'US');
    } else if (themeState.appLanguage == 'ja') {
      resolvedLocale = const Locale('ja', 'JP');
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightTheme = ThemeEngine.buildTheme(
          brightness: Brightness.light,
          dynamicColorScheme: lightDynamic,
          fontFamily: themeState.fontFamily,
          baseWeight: themeState.fontWeight,
        );

        final darkTheme = ThemeEngine.buildTheme(
          brightness: Brightness.dark,
          dynamicColorScheme: darkDynamic,
          fontFamily: themeState.fontFamily,
          baseWeight: themeState.fontWeight,
        );

        return MaterialApp(
          title: 'Runami NCM',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeState.themeMode,
          locale: resolvedLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('zh', 'TW'),
            Locale('en', 'US'),
            Locale('ja', 'JP'),
          ],
          home: const AdaptiveScaffold(),
        );
      },
    );
  }
}
