import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import 'markdown_renderer.dart';

/// Instructions AlertDialog with Markdown rendering,
/// ported 1:1 from NCM-Converter-For-Android SettingsScreen.kt.
class InstructionsDialog extends StatelessWidget {
  const InstructionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final assetPath = AppStrings.instructionsAssetPath(context);

    return AlertDialog(
      title: Text(AppStrings.get(context, 'instructions_title')),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460, maxWidth: 560),
          child: FutureBuilder<String>(
            future: rootBundle.loadString(assetPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Text(AppStrings.get(context, 'instructions_load_failed'));
              }
              return SingleChildScrollView(
                child: MarkdownRenderer(markdown: snapshot.data!),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.get(context, 'instructions_close')),
        ),
      ],
    );
  }
}
