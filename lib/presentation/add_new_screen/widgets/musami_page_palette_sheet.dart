import 'package:flutter/material.dart';

import '../../../core/design_system/app_bottom_sheet.dart';
import '../../../core/design_system/app_design_tokens.dart';
import '../../../localization/app_localization.dart';

const double _kSwatchSize = 56;

/// Shows the colours extracted from the selected image and returns the one the
/// user picked for the page background, or `null` if they dismissed the sheet.
Future<Color?> showMusamiPagePaletteSheet({
  required BuildContext context,
  required List<Color> colors,
}) {
  return showAppModalBottomSheet<Color>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'lbl_layer_menu_apply_colors'.tr,
                style: AppDs.sheetTitle(theme, color: AppDs.textOnDarkPrimary),
              ),
              const SizedBox(height: AppDs.space2),
              Text(
                'msg_apply_colors_hint'.tr,
                style: AppDs.sheetCaption(
                  theme,
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
              const SizedBox(height: AppDs.space4),
              Wrap(
                spacing: AppDs.space3,
                runSpacing: AppDs.space3,
                children: colors
                    .map(
                      (color) => _PaletteSwatch(
                        color: color,
                        onTap: () => Navigator.of(sheetContext).pop(color),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: Container(
          width: _kSwatchSize,
          height: _kSwatchSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: AppDs.textOnDarkPrimary.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
    );
  }
}
