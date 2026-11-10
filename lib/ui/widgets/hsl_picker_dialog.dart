import 'package:flutter/material.dart';
import '../../core/theme/hsl_color.dart';
import '../../l10n/app_strings.dart';

class HslPickerDialog extends StatefulWidget {
  final double initialH;
  final double initialS;
  final double initialL;
  final String title;
  final void Function(int argb, double h, double s, double l) onColorSelected;

  const HslPickerDialog({
    super.key,
    required this.initialH,
    required this.initialS,
    required this.initialL,
    required this.title,
    required this.onColorSelected,
  });

  @override
  State<HslPickerDialog> createState() => _HslPickerDialogState();
}

class _HslPickerDialogState extends State<HslPickerDialog> {
  late double _h;
  late double _s;
  late double _l;

  @override
  void initState() {
    super.initState();
    _h = widget.initialH;
    _s = widget.initialS;
    _l = widget.initialL;
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = HslColorUtil.hslToColor(_h, _s, _l);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview Circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Hue Slider
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(AppStrings.get(context, 'pref_hsl_hue')),
                ),
                Expanded(
                  child: Slider(
                    value: _h,
                    min: 0,
                    max: 360,
                    onChanged: (val) => setState(() => _h = val),
                  ),
                ),
                Text('${_h.toInt()}°'),
              ],
            ),
            // Saturation Slider
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(AppStrings.get(context, 'pref_hsl_saturation')),
                ),
                Expanded(
                  child: Slider(
                    value: _s,
                    min: 0,
                    max: 100,
                    onChanged: (val) => setState(() => _s = val),
                  ),
                ),
                Text('${_s.toInt()}%'),
              ],
            ),
            // Lightness Slider
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(AppStrings.get(context, 'pref_hsl_lightness')),
                ),
                Expanded(
                  child: Slider(
                    value: _l,
                    min: 0,
                    max: 100,
                    onChanged: (val) => setState(() => _l = val),
                  ),
                ),
                Text('${_l.toInt()}%'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.get(context, 'home_cancel')),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(currentColor.value, _h, _s, _l);
            Navigator.of(context).pop();
          },
          child: Text(AppStrings.get(context, 'dialog_confirm')),
        ),
      ],
    );
  }
}
