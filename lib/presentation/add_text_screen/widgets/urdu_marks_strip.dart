import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../add_new_screen/widgets/text_field_insertion_helpers.dart';

/// Common Urdu / Arabic-script punctuation and letters for quick insertion.
const List<String> kUrduMarkCharacters = [
  '\u060C', // ،
  '\u06D4', // ۔
  '\u061F', // ؟
  '\u0621', // ء
  '\u06D2', // ے
  '\u06C1', // ہ
  '\u06BE', // ھ
  '\u0679', // ٹ
  '\u0688', // ڈ
  '\u0691', // ڑ
  '\u200C', // ZWNJ
  '\u0640', // ـ
  '\u064E', // َ
  '\u0650', // ِ
  '\u064F', // ُ
  '\u0652', // ْ
];

/// Compact horizontal strip of Urdu marks as light pills (no heavy container).
class UrduMarksStrip extends StatelessWidget {
  const UrduMarksStrip({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'lbl_urdu_marks'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 10.v),
        SizedBox(
          height: 44.v,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kUrduMarkCharacters.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.h),
            itemBuilder: (context, i) {
              final ch = kUrduMarkCharacters[i];
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.adaptSize),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                    onTap: () => insertTextAtCursor(
                      controller,
                      ch,
                      focusNode: focusNode,
                    ),
                    child: SizedBox(
                      width: 40.h,
                      child: Center(
                        child: Text(
                          ch,
                          style: TextStyle(
                            fontSize: 20.fSize,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
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
    );
  }
}
