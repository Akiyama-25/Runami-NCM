import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/theme_engine.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/app_prefs.dart';
import 'l10n/app_strings.dart';
import 'state/providers.dart';
import 'ui/home_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/widgets/predictive_back_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(960, 680),
        minimumSize: Size(420, 480),
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
    if (themeState.appLanguage == 'zh' || themeState.appLanguage == 'zh-SC') {
      resolvedLocale = const Locale('zh', 'CN');
    } else if (themeState.appLanguage == 'zh_tw' || themeState.appLanguage == 'zh-TC') {
      resolvedLocale = const Locale('zh', 'TW');
    } else if (themeState.appLanguage == 'en') {
      resolvedLocale = const Locale('en', 'US');
    } else if (themeState.appLanguage == 'ja') {
      resolvedLocale = const Locale('ja', 'JP');
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final supportsDynamic = lightDynamic != null || darkDynamic != null;

        final lightTheme = ThemeEngine.buildTheme(
          brightness: Brightness.light,
          useMonetColors: themeState.useMonetColors,
          accentColor: Color(themeState.customAccentColor),
          bgColor: Color(themeState.customLightBgColor),
          dynamicColorScheme: lightDynamic,
          fontFamily: themeState.fontFamily,
          baseWeight: themeState.fontWeight,
        );

        final darkTheme = ThemeEngine.buildTheme(
          brightness: Brightness.dark,
          useMonetColors: themeState.useMonetColors,
          accentColor: Color(themeState.customAccentColor),
          bgColor: Color(themeState.customDarkBgColor),
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
          home: _RootHost(supportsDynamicColor: supportsDynamic),
        );
      },
    );
  }
}

/// Single-host screen matching NCM-Converter-For-Android's MainActivity:
/// wraps HomeScreen and SettingsScreen inside PredictiveBackContainer with
/// double-tap-back-to-exit support.
class _RootHost extends StatefulWidget {
  final bool supportsDynamicColor;

  const _RootHost({required this.supportsDynamicColor});

  @override
  State<_RootHost> createState() => _RootHostState();
}

class _RootHostState extends State<_RootHost> {
  bool _showSettings = false;
  DateTime? _lastBackPress;

  void _handleHomeBackPress() {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!).inMilliseconds < 2000) {
      SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get(context, 'press_back_again')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_showSettings) {
          _handleHomeBackPress();
        }
      },
      child: PredictiveBackContainer(
        isOverlayOpen: _showSettings,
        onCloseOverlay: () {
          if (mounted) {
            setState(() => _showSettings = false);
          }
        },
        backgroundContent: HomeScreen(
          onOpenSettings: () => setState(() => _showSettings = true),
        ),
        overlayContent: (requestClose) => SettingsScreen(
          onBack: requestClose,
          supportsDynamicColor: widget.supportsDynamicColor,
        ),
      ),
    );
  }
}
