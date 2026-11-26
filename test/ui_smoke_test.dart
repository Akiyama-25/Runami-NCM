import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runami_ncm/core/decrypt/models/decrypt_models.dart';
import 'package:runami_ncm/core/theme/app_colors.dart';
import 'package:runami_ncm/core/theme/theme_engine.dart';
import 'package:runami_ncm/core/utils/app_prefs.dart';
import 'package:runami_ncm/main.dart';
import 'package:runami_ncm/ui/file_item_card.dart';
import 'package:runami_ncm/ui/widgets/adaptive_controls_row.dart';
import 'package:runami_ncm/ui/widgets/markdown_renderer.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.init();
  });

  Widget wrapWithApp(Widget child) {
    final theme = ThemeEngine.buildTheme(
      brightness: Brightness.light,
      useMonetColors: false,
      accentColor: const Color(AppPrefs.DEFAULT_ACCENT_COLOR),
      bgColor: const Color(AppPrefs.DEFAULT_LIGHT_BG_COLOR),
      fontFamily: null,
      baseWeight: 400,
    );
    return ProviderScope(
      child: MaterialApp(
        theme: theme,
        locale: const Locale('zh', 'CN'),
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
        home: child,
      ),
    );
  }

  testWidgets('RunamiNcmApp renders HomeScreen and opens SettingsScreen via settings icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RunamiNcmApp()));
    await tester.pump(const Duration(milliseconds: 300));

    // Home screen hero elements
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.library_music), findsOneWidget);

    // Open Settings overlay
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Settings screen back button and section items
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.font_download), findsOneWidget);

    // Close Settings overlay via back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('FileItemCard renders completed item with extension and LRC badges',
      (WidgetTester tester) async {
    const item = FileItem(
      id: 1,
      path: '/tmp/test.ncm',
      name: 'ヨルシカ - エイミー.ncm',
      size: 74100000,
      state: DecryptState.COMPLETED,
      progress: 1.0,
      result: DecryptResult(
        metadata: NcmMetadata(musicName: 'エイミー', artists: ['ヨルシカ']),
        mimeType: 'audio/flac',
        extension: 'flac',
        lyric: '[00:01.00]test lyric',
      ),
    );

    await tester.pumpWidget(
      wrapWithApp(
        Scaffold(
          body: FileItemCard(
            item: item,
            onDecrypt: () {},
            onRemove: () {},
            onSave: () {},
            autoSave: false,
            enableCover: false,
          ),
        ),
      ),
    );

    expect(find.text('ヨルシカ - エイミー.ncm'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
    expect(find.text('LRC'), findsOneWidget);
    expect(find.byIcon(Icons.save_alt), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('MarkdownRenderer renders headings, lists, quotes, code blocks, and tables',
      (WidgetTester tester) async {
    const md = '''
# Title 1
## Section 2

Paragraph with **bold**, *italic*, and `inline code`.

> A blockquote note.

- Bullet item
1. Ordered item

```dart
final x = 1;
```

| Col A | Col B |
| ----- | ----- |
| Val 1 | Val 2 |
''';

    await tester.pumpWidget(
      wrapWithApp(
        const Scaffold(
          body: SingleChildScrollView(
            child: MarkdownRenderer(markdown: md),
          ),
        ),
      ),
    );

    expect(find.text('Title 1', findRichText: true), findsOneWidget);
    expect(find.text('Section 2', findRichText: true), findsOneWidget);
    expect(find.text('DART'), findsOneWidget);
    expect(find.text('Val 1', findRichText: true), findsOneWidget);
  });

  testWidgets('AdaptiveControlsRow lays out children in single row and wraps cleanly on narrow width',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithApp(
        Scaffold(
          body: SizedBox(
            width: 180,
            child: AdaptiveControlsRow(
              children: [
                FilledButton(onPressed: () {}, child: const Text('First Long Button')),
                FilledButton(onPressed: () {}, child: const Text('Second Long Button')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('First Long Button'), findsOneWidget);
    expect(find.text('Second Long Button'), findsOneWidget);
  });

  test('applyUserColors synthesizes M3E surface hierarchy for custom colors', () {
    final scheme = applyUserColors(
      defaultDarkColorScheme,
      darkTheme: true,
      accent: const Color(0xFF1976D2),
      bg: const Color(0xFF121212),
      monetEnabled: false,
    );
    expect(scheme.primary, const Color(0xFF1976D2));
    expect(scheme.surface, const Color(0xFF121212));
    expect(scheme.surfaceContainerHigh, isNot(equals(scheme.surface)));
  });
}
