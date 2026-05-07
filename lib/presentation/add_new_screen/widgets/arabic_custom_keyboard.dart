import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import 'text_field_insertion_helpers.dart';

/// Standalone harakat (diacritics) — insert at caret; letters use system keyboard.
const List<({String mark, String nameKey})> kArabicHarakatKeys = [
  (mark: '\u064E', nameKey: 'lbl_harakat_fatha'),
  (mark: '\u0650', nameKey: 'lbl_harakat_kasra'),
  (mark: '\u064F', nameKey: 'lbl_harakat_damma'),
  (mark: '\u0652', nameKey: 'lbl_harakat_sukun'),
  (mark: '\u0651', nameKey: 'lbl_harakat_shadda'),
  (mark: '\u064B', nameKey: 'lbl_harakat_tanwin_fath'),
  (mark: '\u064D', nameKey: 'lbl_harakat_tanwin_kasr'),
  (mark: '\u064C', nameKey: 'lbl_harakat_tanwin_damm'),
];

/// Compact harakat bar only — does **not** hide the mobile keyboard.
class ArabicHarakatStrip extends StatelessWidget {
  const ArabicHarakatStrip({
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
    final primarySoft = cs.primary.withValues(alpha: 0.12);
    final primaryBorder = cs.primary.withValues(alpha: 0.45);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 10.v),
      decoration: BoxDecoration(
        color: primarySoft,
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(color: cs.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'lbl_keyboard_harakat'.tr,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          SizedBox(height: 8.v),
          SizedBox(
            height: 48.v,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kArabicHarakatKeys.length,
              separatorBuilder: (_, _) => SizedBox(width: 8.h),
              itemBuilder: (context, i) {
                final e = kArabicHarakatKeys[i];
                return Tooltip(
                  message: e.nameKey.tr,
                  child: Material(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.adaptSize),
                      side: BorderSide(color: primaryBorder),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.adaptSize),
                      onTap: () => insertTextAtCursor(
                        controller,
                        e.mark,
                        focusNode: focusNode,
                      ),
                      splashColor: cs.primary.withValues(alpha: 0.12),
                      highlightColor: cs.primary.withValues(alpha: 0.08),
                      child: SizedBox(
                        width: 44.h,
                        child: Center(
                          child: Text(
                            e.mark,
                            style: TextStyle(
                              fontSize: 22.fSize,
                              height: 1.2,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
