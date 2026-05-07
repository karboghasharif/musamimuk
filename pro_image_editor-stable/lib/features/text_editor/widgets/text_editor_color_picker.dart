import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '../text_editor.dart';

/// A widget for selecting and customizing text colors in the text editor,
/// allowing updates to primary and background colors.
class TextEditorColorPicker extends StatelessWidget {
  /// Creates a `TextEditorColorPicker` with the necessary configurations,
  /// state, and callbacks for handling color updates and position changes.
  ///
  /// - [state]: Represents the current state of the text editor.
  /// - [configs]: Configuration settings for the editor, including available
  ///   colors.
  /// - [rebuildController]: A stream controller for triggering UI updates.
  /// - [primaryColor]: The current primary color selected for the text.
  /// - [selectedTextStyle]: The text style currently applied to the text.
  /// - [onUpdateColor]: Callback triggered when the color is updated.
  const TextEditorColorPicker({
    super.key,
    required this.state,
    required this.configs,
    required this.rebuildController,
    required this.primaryColor,
    required this.selectedTextStyle,
    required this.onUpdateColor,
  });

  /// Represents the current state of the text editor.
  final TextEditorState state;

  /// Configuration settings for the editor, including available colors.
  final ProImageEditorConfigs configs;

  /// A stream controller for triggering UI updates.
  final StreamController<void> rebuildController;

  /// The current primary color selected for the text.
  final Color primaryColor;

  /// The text style currently applied to the text.
  final TextStyle selectedTextStyle;

  /// Callback triggered when the color is updated.
  final Function(Color color) onUpdateColor;

  @override
  Widget build(BuildContext context) {
    if (configs.textEditor.widgets.colorPicker != null) {
      return configs.textEditor.widgets.colorPicker!.call(
            state,
            rebuildController.stream,
            selectedTextStyle.color ?? primaryColor,
            onUpdateColor,
          ) ??
          const SizedBox.shrink();
    }

    final maxPickerWidth = min(
      280.0,
      MediaQuery.sizeOf(context).width * 0.42,
    );

    final maxTotalHeight = min(
      380.0,
      MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom -
          kToolbarHeight -
          kBottomNavigationBarHeight -
          10 * 2 -
          MediaQuery.paddingOf(context).top,
    );

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: null,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        constraints: BoxConstraints(maxHeight: maxTotalHeight),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                colorToHex(
                  primaryColor,
                  includeHashSign: true,
                  enableAlpha: false,
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: maxPickerWidth,
                child: ColorPicker(
                  pickerColor: primaryColor,
                  onColorChanged: onUpdateColor,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.72,
                  colorPickerWidth: maxPickerWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
