import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Confirm 2× / 4× AI upscale for the selected image layer.
Future<int?> showMusamiAiUpscaleSheet(BuildContext context) {
  return showAppModalBottomSheet<int>(
    context: context,
    builder: (ctx) {
      var scale = 2;
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'lbl_ai_upscale'.tr,
                    style: AppDs.sheetTitle(
                      Theme.of(context),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppDs.space2.v),
                  Text(
                    'msg_ai_upscale_hint'.tr,
                    style: TextStyle(
                      color: AppDs.textOnDarkSecondary,
                      fontSize: 13.fSize,
                    ),
                  ),
                  SizedBox(height: AppDs.space3.v),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 2, label: Text('lbl_ai_upscale_2x'.tr)),
                      ButtonSegment(value: 4, label: Text('lbl_ai_upscale_4x'.tr)),
                    ],
                    selected: {scale},
                    onSelectionChanged: (next) {
                      setState(() => scale = next.first);
                    },
                  ),
                  SizedBox(height: AppDs.space4.v),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, scale),
                    child: Text('lbl_apply'.tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('lbl_cancel'.tr),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
