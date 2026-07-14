import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import 'text_field_insertion_helpers.dart';

/// Arabic diacritics (tashkeela) — inserted at the caret; letters use system keyboard.
const List<({String mark, String nameKey})> kArabicTashkeelaKeys = [
  (mark: '\u064E', nameKey: 'lbl_tashkeela_fatha'),
  (mark: '\u0650', nameKey: 'lbl_tashkeela_kasra'),
  (mark: '\u064F', nameKey: 'lbl_tashkeela_damma'),
  (mark: '\u0652', nameKey: 'lbl_tashkeela_sukun'),
  (mark: '\u0651', nameKey: 'lbl_tashkeela_shadda'),
  (mark: '\u064B', nameKey: 'lbl_tashkeela_tanwin_fath'),
  (mark: '\u064D', nameKey: 'lbl_tashkeela_tanwin_kasr'),
  (mark: '\u064C', nameKey: 'lbl_tashkeela_tanwin_damm'),
];

/// Arabic diacritics (tashkeela) — inserted at the caret; letters use system keyboard.
class ArabicTashkeelaStrip extends StatelessWidget {
  const ArabicTashkeelaStrip({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 8.0;
        final chipWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.spellcheck_rounded,
                  size: 18.adaptSize,
                  color: cs.primary,
                ),
                SizedBox(width: 6.h),
                Text(
                  'lbl_keyboard_tashkeela'.tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.fSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.v),
            Text(
              'msg_tashkeela_hint'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11.fSize,
              ),
            ),
            SizedBox(height: 10.v),
            Wrap(
              spacing: spacing.h,
              runSpacing: spacing.v,
              children: kArabicTashkeelaKeys.map((e) {
                return _TashkeelaChip(
                  width: chipWidth,
                  mark: e.mark,
                  label: e.nameKey.tr,
                  onTap: () => insertTextAtCursor(
                    controller,
                    e.mark,
                    focusNode: focusNode,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _TashkeelaChip extends StatelessWidget {
  const _TashkeelaChip({
    required this.width,
    required this.mark,
    required this.label,
    required this.onTap,
  });

  final double width;
  final String mark;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12.adaptSize),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: AppDs.minTap.v + 6.v,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mark,
                style: TextStyle(
                  fontSize: 22.fSize,
                  height: 1.1,
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 2.v),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 9.fSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
