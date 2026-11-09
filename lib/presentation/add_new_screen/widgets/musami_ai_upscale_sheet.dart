import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import 'musami_ai_chrome.dart';

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
                  MusamiAiSheetHeader(
                    title: 'lbl_ai_upscale'.tr,
                    subtitle: 'msg_ai_upscale_hint'.tr,
                    icon: Icons.high_quality_rounded,
                  ),
                  SizedBox(height: AppDs.space4.v),
                  Row(
                    children: [
                      Expanded(
                        child: _UpscaleOptionCard(
                          scale: 2,
                          label: 'lbl_ai_upscale_2x'.tr,
                          detail: 'Sharper detail',
                          selected: scale == 2,
                          onTap: () => setState(() => scale = 2),
                        ),
                      ),
                      SizedBox(width: AppDs.space2.h),
                      Expanded(
                        child: _UpscaleOptionCard(
                          scale: 4,
                          label: 'lbl_ai_upscale_4x'.tr,
                          detail: 'Maximum clarity',
                          selected: scale == 4,
                          onTap: () => setState(() => scale = 4),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDs.space5.v),
                  MusamiAiPrimaryButton(
                    label: 'lbl_apply'.tr,
                    icon: Icons.auto_fix_high_rounded,
                    onPressed: () => Navigator.pop(ctx, scale),
                  ),
                  MusamiAiGhostButton(
                    label: 'lbl_cancel'.tr,
                    onPressed: () => Navigator.pop(ctx),
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

class _UpscaleOptionCard extends StatelessWidget {
  const _UpscaleOptionCard({
    required this.scale,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final int scale;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: selected
                ? MusamiAiChrome.accent.withValues(alpha: 0.14)
                : MusamiAiChrome.panelDeep,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: selected ? MusamiAiChrome.accent : MusamiAiChrome.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$scale×',
                style: TextStyle(
                  color: selected
                      ? MusamiAiChrome.accent
                      : AppDs.textOnDarkPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppDs.textOnDarkPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  color: AppDs.textOnDarkSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
