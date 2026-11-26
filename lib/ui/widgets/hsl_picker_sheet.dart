import 'package:flutter/material.dart';
import '../../core/theme/hsl_color.dart';
import '../../l10n/app_strings.dart';

/// Live-updating HSL Color Picker ModalBottomSheet with gradient tracks,
/// ported 1:1 from NCM-Converter-For-Android SettingsScreen.kt.
class HslPickerSheet extends StatefulWidget {
  final String title;
  final double initialH;
  final double initialS;
  final double initialL;
  final void Function(int argb, double h, double s, double l) onColorChanged;

  const HslPickerSheet({
    super.key,
    required this.title,
    required this.initialH,
    required this.initialS,
    required this.initialL,
    required this.onColorChanged,
  });

  @override
  State<HslPickerSheet> createState() => _HslPickerSheetState();
}

class _HslPickerSheetState extends State<HslPickerSheet> {
  late double _h;
  late double _s;
  late double _l;

  @override
  void initState() {
    super.initState();
    _h = widget.initialH.clamp(0.0, 360.0);
    _s = widget.initialS.clamp(0.0, 100.0);
    _l = widget.initialL.clamp(0.0, 100.0);
  }

  void _emit() {
    final color = HslColorUtil.hslToColor(_h, _s, _l);
    widget.onColorChanged(color.toARGB32(), _h, _s, _l);
  }

  List<Color> _hueGradientColors() {
    const steps = 7;
    return List.generate(
      steps + 1,
      (i) => HslColorUtil.hslToColor(i * 360.0 / steps, 100.0, 50.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewColor = HslColorUtil.hslToColor(_h, _s, _l);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // 64x64 Preview Circle with 2dp outline border
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 2),
              ),
            ),

            const SizedBox(height: 24),

            // Hue slider (0..360)
            _HslGradientSlider(
              label: AppStrings.get(context, 'pref_hsl_hue'),
              value: _h,
              min: 0,
              max: 360,
              gradientColors: _hueGradientColors(),
              valueText: '${_h.toInt()}°',
              onChanged: (val) {
                setState(() => _h = val);
                _emit();
              },
            ),

            const SizedBox(height: 12),

            // Lightness slider (0..100)
            _HslGradientSlider(
              label: AppStrings.get(context, 'pref_hsl_lightness'),
              value: _l,
              min: 0,
              max: 100,
              gradientColors: [
                Colors.black,
                HslColorUtil.hslToColor(_h, _s, 50.0),
                Colors.white,
              ],
              valueText: '${_l.toInt()}%',
              onChanged: (val) {
                setState(() => _l = val);
                _emit();
              },
            ),

            const SizedBox(height: 12),

            // Saturation slider (0..100)
            _HslGradientSlider(
              label: AppStrings.get(context, 'pref_hsl_saturation'),
              value: _s,
              min: 0,
              max: 100,
              gradientColors: [
                const Color(0xFF808080),
                HslColorUtil.hslToColor(_h, 100.0, _l),
              ],
              valueText: '${_s.toInt()}%',
              onChanged: (val) {
                setState(() => _s = val);
                _emit();
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HslGradientSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final List<Color> gradientColors;
  final String valueText;
  final ValueChanged<double> onChanged;

  const _HslGradientSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.gradientColors,
    required this.valueText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
            Text(
              valueText,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 12dp gradient rounded track
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(colors: gradientColors),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 3,
                  ),
                  thumbColor: colorScheme.primary,
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
