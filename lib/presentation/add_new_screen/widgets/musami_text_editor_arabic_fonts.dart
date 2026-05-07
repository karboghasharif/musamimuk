import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';

/// Merges [prototype]’s font family into the editor’s current style.
/// The text layer uses a single [TextStyle] for the whole field (Pro Image
/// Editor limitation).
void applyMusamiTextEditorFont(
  TextEditorState editor,
  TextStyle prototype, {
  required String? fontPackage,
}) {
  final cur = editor.selectedTextStyle;
  editor.setTextStyle(
    cur.copyWith(
      fontFamily: prototype.fontFamily,
      fontFamilyFallback: prototype.fontFamilyFallback,
      package: fontPackage,
    ),
  );
}

/// Fonts bundled by the `arabic_font` package (family id → UI label).
const List<({String familyId, String label})> kMusamiArabicFontPackageFonts = [
  (familyId: ArabicFont.amiri, label: 'Amiri'),
  (familyId: ArabicFont.arefRuqaa, label: 'Aref Ruqaa'),
  (familyId: ArabicFont.aalooBhaijaan, label: 'Baloo Bhaijaan'),
  (familyId: ArabicFont.cairo, label: 'Cairo'),
  (familyId: ArabicFont.changa, label: 'Changa'),
  (familyId: ArabicFont.elMessiri, label: 'El Messiri'),
  (familyId: ArabicFont.narmattan, label: 'Harmattan'),
  (familyId: ArabicFont.jomhuria, label: 'Jomhuria'),
  (familyId: ArabicFont.katibeh, label: 'Katibeh'),
  (familyId: ArabicFont.lalezar, label: 'Lalezar'),
  (familyId: ArabicFont.lateef, label: 'Lateef'),
  (familyId: ArabicFont.lemonada, label: 'Lemonada'),
  (familyId: ArabicFont.mada, label: 'Mada'),
  (familyId: ArabicFont.markaziText, label: 'Markazi Text'),
  (familyId: ArabicFont.mirza, label: 'Mirza'),
  (familyId: ArabicFont.rakkas, label: 'Rakkas'),
  (familyId: ArabicFont.reemKufi, label: 'Reem Kufi'),
  (familyId: ArabicFont.scheherazade, label: 'Scheherazade'),
  (familyId: ArabicFont.tajawal, label: 'Tajawal'),
  (familyId: ArabicFont.dubai, label: 'Dubai'),
  (familyId: ArabicFont.dinNextLTArabic, label: 'DIN Next LT Arabic'),
  (familyId: ArabicFont.iBMPlexSansArabic, label: 'IBM Plex Sans Arabic'),
  (familyId: ArabicFont.avenirArabic, label: 'Avenir Arabic'),
];

/// Curated Arabic-capable families from `google_fonts` (distinct from package list).
final List<({String label, TextStyle Function() build})> kMusamiGoogleArabicFonts =
    [
      (label: 'Cairo', build: () => GoogleFonts.cairo()),
      (label: 'Tajawal', build: () => GoogleFonts.tajawal()),
      (label: 'Amiri', build: () => GoogleFonts.amiri()),
      (label: 'Noto Sans Arabic', build: () => GoogleFonts.notoSansArabic()),
      (label: 'Noto Naskh Arabic', build: () => GoogleFonts.notoNaskhArabic()),
      (label: 'Changa', build: () => GoogleFonts.changa()),
      (label: 'El Messiri', build: () => GoogleFonts.elMessiri()),
      (label: 'Reem Kufi', build: () => GoogleFonts.reemKufi()),
      (label: 'Markazi Text', build: () => GoogleFonts.markaziText()),
      (label: 'Scheherazade New', build: () => GoogleFonts.scheherazadeNew()),
      (label: 'Beiruti', build: () => GoogleFonts.beiruti()),
      (label: 'IBM Plex Sans Arabic', build: () => GoogleFonts.ibmPlexSansArabic()),
      (label: 'Lateef', build: () => GoogleFonts.lateef()),
      (label: 'Lalezar', build: () => GoogleFonts.lalezar()),
    ];

/// Shown when Arabic (RTL) input is active and the user has a non‑collapsed
/// selection — pick a font to apply to the text layer style.
class MusamiArabicFontPickerStrip extends StatelessWidget {
  const MusamiArabicFontPickerStrip({
    super.key,
    required this.editor,
    required this.theme,
  });

  final TextEditorState editor;
  final ThemeData theme;

  static const String _sampleArabic = 'نص';

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'lbl_text_editor_fonts_section'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.v),
        Text(
          'lbl_text_editor_fonts_arabic_pkg'.tr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 6.v),
        SizedBox(
          height: 56.v,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kMusamiArabicFontPackageFonts.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.h),
            itemBuilder: (context, i) {
              final e = kMusamiArabicFontPackageFonts[i];
              final preview = ArabicTextStyle(
                arabicFont: e.familyId,
                fontSize: 16.fSize,
              );
              return _MusamiFontChip(
                theme: theme,
                previewText: _sampleArabic,
                previewStyle: preview,
                label: e.label,
                onTap: () {
                  applyMusamiTextEditorFont(
                    editor,
                    ArabicTextStyle(arabicFont: e.familyId),
                    fontPackage: ArabicThemeData.package,
                  );
                  editor.focusNode.requestFocus();
                },
              );
            },
          ),
        ),
        SizedBox(height: 10.v),
        Text(
          'lbl_text_editor_fonts_google_pkg'.tr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 6.v),
        SizedBox(
          height: 56.v,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kMusamiGoogleArabicFonts.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.h),
            itemBuilder: (context, i) {
              final e = kMusamiGoogleArabicFonts[i];
              final preview = e.build().copyWith(fontSize: 16.fSize);
              return _MusamiFontChip(
                theme: theme,
                previewText: _sampleArabic,
                previewStyle: preview,
                label: e.label,
                onTap: () {
                  applyMusamiTextEditorFont(
                    editor,
                    e.build(),
                    fontPackage: null,
                  );
                  editor.focusNode.requestFocus();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MusamiFontChip extends StatelessWidget {
  const _MusamiFontChip({
    required this.theme,
    required this.previewText,
    required this.previewStyle,
    required this.label,
    required this.onTap,
  });

  final ThemeData theme;
  final String previewText;
  final TextStyle previewStyle;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10.adaptSize),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.adaptSize),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.v),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                previewText,
                style: previewStyle,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 2.v),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9.fSize,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
