import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../core/app_export.dart';

/// Shared HSV colour panel matching the Material picker reference
/// (saturation square + hue + alpha + HEX / RGBA labels).
class MusamiAppColorPickerPanel extends StatelessWidget {
  const MusamiAppColorPickerPanel({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.enableAlpha = true,
    this.colorPickerWidth,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool enableAlpha;
  final double? colorPickerWidth;

  @override
  Widget build(BuildContext context) {
    final width = colorPickerWidth ??
        min(MediaQuery.sizeOf(context).width - 48, 320.0);

    // flutter_colorpicker labels/controls expect a light Material surface.
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppDs.accentYellow,
          brightness: Brightness.light,
        ),
        textTheme: Typography.material2021(platform: TargetPlatform.android)
            .black
            .apply(bodyColor: const Color(0xFF1A1A1A)),
      ),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: onColorChanged,
            enableAlpha: enableAlpha,
            displayThumbColor: true,
            portraitOnly: true,
            hexInputBar: true,
            paletteType: PaletteType.hsvWithHue,
            labelTypes: const [
              ColorLabelType.hex,
              ColorLabelType.rgb,
            ],
            pickerAreaHeightPercent: 0.72,
            colorPickerWidth: width,
            pickerAreaBorderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// App-wide modal colour picker (image tint, text, border, etc.).
void musamiShowAppColorPicker(
  BuildContext context, {
  required String title,
  required Color initialColor,
  required ValueChanged<Color> onColorChanged,
  bool enableAlpha = true,
}) {
  showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final sheetTheme = Theme.of(ctx);
      Color pickerColor = initialColor;
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: AppDs.sheetTitle(sheetTheme, color: Colors.white),
                    ),
                    SizedBox(height: AppDs.space4.v),
                    Center(
                      child: MusamiAppColorPickerPanel(
                        pickerColor: pickerColor,
                        enableAlpha: enableAlpha,
                        onColorChanged: (Color c) {
                          setModalState(() => pickerColor = c);
                          onColorChanged(c);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
