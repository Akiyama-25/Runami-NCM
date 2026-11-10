import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/system_font_scanner.dart';
import 'convert_state_notifier.dart';
import 'theme_state_notifier.dart';

final convertQueueProvider =
    StateNotifierProvider<ConvertQueueNotifier, ConvertQueueState>((ref) {
  return ConvertQueueNotifier();
});

final themeStateProvider =
    StateNotifierProvider<ThemeStateNotifier, ThemeState>((ref) {
  return ThemeStateNotifier();
});

final installedFontsProvider = FutureProvider<List<SystemFontItem>>((ref) async {
  return await SystemFontScanner.scanInstalledFonts();
});
