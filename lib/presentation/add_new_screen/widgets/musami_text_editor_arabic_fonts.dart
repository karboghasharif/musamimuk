import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/custom_font_models.dart';
import '../../../data/services/custom_font_library.dart';
import '../../../data/services/user_font_library.dart';

/// Rebuilds [source] with a new font family, correctly clearing a sticky
/// `package` (Flutter's [TextStyle.copyWith] cannot set `package` to null).
TextStyle musamiTextStyleWithFont(
  TextStyle source, {
  required String? fontFamily,
  List<String>? fontFamilyFallback,
  String? fontPackage,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    color: source.color,
    backgroundColor: source.backgroundColor,
    fontSize: source.fontSize,
    fontWeight: fontWeight ?? source.fontWeight,
    fontStyle: fontStyle ?? source.fontStyle,
    letterSpacing: source.letterSpacing,
    wordSpacing: source.wordSpacing,
    textBaseline: source.textBaseline,
    height: source.height,
    leadingDistribution: source.leadingDistribution,
    locale: source.locale,
    foreground: source.foreground,
    background: source.background,
    shadows: source.shadows,
    fontFeatures: source.fontFeatures,
    fontVariations: source.fontVariations,
    decoration: source.decoration,
    decorationColor: source.decorationColor,
    decorationStyle: source.decorationStyle,
    decorationThickness: source.decorationThickness,
    debugLabel: source.debugLabel,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback ?? source.fontFamilyFallback,
    package: fontPackage,
    overflow: source.overflow,
  );
}

/// Strips a sticky font package so Google/custom fonts resolve from the app,
/// not a leftover `arabic_font` package. Always rebuilds — [TextStyle] has no
/// public `package` getter, and `copyWith(package: null)` cannot clear it.
TextStyle musamiTextStyleWithoutPackage(TextStyle source) {
  return musamiTextStyleWithFont(
    source,
    fontFamily: source.fontFamily,
    fontFamilyFallback: source.fontFamilyFallback,
    fontPackage: null,
    fontWeight: source.fontWeight,
    fontStyle: source.fontStyle,
  );
}

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
    musamiTextStyleWithFont(
      cur,
      fontFamily: prototype.fontFamily,
      fontFamilyFallback: prototype.fontFamilyFallback,
      fontPackage: fontPackage,
      fontWeight: prototype.fontWeight,
      fontStyle: prototype.fontStyle,
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

/// User-imported device fonts (TTF/OTF) with an Import action.
///
/// Used by the in-editor fonts sheet and the canvas text-layer fonts sheet.
class MusamiUserFontSections extends StatelessWidget {
  const MusamiUserFontSections({
    super.key,
    required this.theme,
    required this.library,
    required this.onSelect,
    required this.onImport,
    this.loadingFontKey,
    this.query = '',
    this.chipBackground,
    this.labelColor,
    this.sectionTitleColor,
    this.previewColor,
    this.showSectionTitle = true,
  });

  final ThemeData theme;
  final UserFontLibrary library;
  final Future<void> Function(UserFontItem font) onSelect;
  final Future<void> Function() onImport;
  final String? loadingFontKey;
  final String query;
  final Color? chipBackground;
  final Color? labelColor;
  final Color? sectionTitleColor;
  final Color? previewColor;
  final bool showSectionTitle;

  static const String _sample = 'Aa';

  List<UserFontItem> get _filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return library.fonts;
    return library.fonts
        .where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.family.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final fonts = _filtered;
    final titleColor = sectionTitleColor ?? theme.colorScheme.primary;
    final muted = labelColor ?? theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSectionTitle)
          Text(
            'lbl_text_editor_fonts_my'.tr,
            style: theme.textTheme.labelMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (showSectionTitle) SizedBox(height: 6.v),
        SizedBox(
          height: 56.v,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fonts.length + 1,
            separatorBuilder: (_, _) => SizedBox(width: 8.h),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _MusamiFontChip(
                  theme: theme,
                  background: chipBackground,
                  previewText: '+',
                  previewStyle: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.w600,
                    color: previewColor ?? theme.colorScheme.primary,
                  ),
                  previewDirection: TextDirection.ltr,
                  label: 'lbl_import_font'.tr,
                  labelColor: labelColor,
                  busy: library.isImporting,
                  onTap: () => onImport(),
                );
              }
              final font = fonts[i - 1];
              final ready = library.isFamilyLoaded(font.family);
              return _MusamiFontChip(
                theme: theme,
                background: chipBackground,
                previewText: _sample,
                previewStyle: TextStyle(
                  fontFamily: ready ? font.family : null,
                  fontSize: 16.fSize,
                  color: previewColor,
                ),
                previewDirection: TextDirection.ltr,
                label: font.name,
                labelColor: labelColor,
                busy: loadingFontKey == font.id,
                onTap: () => onSelect(font),
              );
            },
          ),
        ),
        if (fonts.isEmpty && !library.isImporting) ...[
          SizedBox(height: 4.v),
          Text(
            library.error ?? 'msg_user_fonts_empty'.tr,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}

/// Arabic + English sections from the admin Custom Font Library.
///
/// Used by the in-editor fonts sheet and the canvas text-layer fonts sheet.
class MusamiCustomFontSections extends StatelessWidget {
  const MusamiCustomFontSections({
    super.key,
    required this.theme,
    required this.library,
    required this.onSelect,
    this.loadingFontKey,
    this.query = '',
    this.preferArabicFirst = true,
    this.chipBackground,
    this.labelColor,
    this.sectionTitleColor,
    this.previewColor,
  });

  final ThemeData theme;
  final CustomFontLibrary library;
  final Future<void> Function(CustomFontItem font) onSelect;
  final String? loadingFontKey;
  final String query;

  /// When true, Arabic section is listed before English.
  final bool preferArabicFirst;
  final Color? chipBackground;
  final Color? labelColor;
  final Color? sectionTitleColor;
  final Color? previewColor;

  static const String _sampleArabic = 'نص';
  static const String _sampleEnglish = 'Aa';

  List<CustomFontItem> _filtered(bool arabic) {
    final q = query.trim().toLowerCase();
    return library.fontsForScript(arabic: arabic).where((f) {
      if (q.isEmpty) return true;
      return f.name.toLowerCase().contains(q) ||
          f.family.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final arabicFonts = _filtered(true);
    final englishFonts = _filtered(false);
    final titleColor = sectionTitleColor ?? theme.colorScheme.primary;
    final muted = labelColor ?? theme.colorScheme.onSurfaceVariant;

    if (library.isLoading && library.fonts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.v),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (arabicFonts.isEmpty && englishFonts.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8.v),
        child: Text(
          library.error ?? 'msg_custom_fonts_empty'.tr,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      );
    }

    final sections = <Widget>[
      if (preferArabicFirst) ...[
        if (arabicFonts.isNotEmpty)
          _section(
            title: 'lbl_text_editor_fonts_arabic'.tr,
            fonts: arabicFonts,
            sample: _sampleArabic,
            direction: TextDirection.rtl,
            titleColor: titleColor,
          ),
        if (englishFonts.isNotEmpty)
          _section(
            title: 'lbl_text_editor_fonts_english'.tr,
            fonts: englishFonts,
            sample: _sampleEnglish,
            direction: TextDirection.ltr,
            titleColor: titleColor,
          ),
      ] else ...[
        if (englishFonts.isNotEmpty)
          _section(
            title: 'lbl_text_editor_fonts_english'.tr,
            fonts: englishFonts,
            sample: _sampleEnglish,
            direction: TextDirection.ltr,
            titleColor: titleColor,
          ),
        if (arabicFonts.isNotEmpty)
          _section(
            title: 'lbl_text_editor_fonts_arabic'.tr,
            fonts: arabicFonts,
            sample: _sampleArabic,
            direction: TextDirection.rtl,
            titleColor: titleColor,
          ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) SizedBox(height: 10.v),
          sections[i],
        ],
      ],
    );
  }

  Widget _section({
    required String title,
    required List<CustomFontItem> fonts,
    required String sample,
    required TextDirection direction,
    required Color titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.v),
        SizedBox(
          height: 56.v,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fonts.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.h),
            itemBuilder: (context, i) {
              final font = fonts[i];
              final key = font.uuid.isNotEmpty ? font.uuid : '${font.id}';
              final ready = library.isReady(font);
              final previewStyle = TextStyle(
                fontFamily: ready ? font.family : null,
                fontSize: 16.fSize,
                fontWeight: font.fontWeight,
                fontStyle: font.fontStyle,
                color: previewColor,
              );
              return _MusamiFontChip(
                theme: theme,
                background: chipBackground,
                previewText: font.previewText.trim().isNotEmpty
                    ? font.previewText
                    : sample,
                previewStyle: previewStyle,
                previewDirection: direction,
                label: font.name,
                labelColor: labelColor,
                trailing: font.isPremium
                    ? Icons.workspace_premium_outlined
                    : null,
                busy: loadingFontKey == key,
                onTap: () => onSelect(font),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Font picker for the text editor: Custom Font Library + bundled fallbacks.
class MusamiArabicFontPickerStrip extends StatefulWidget {
  const MusamiArabicFontPickerStrip({
    super.key,
    required this.editor,
    required this.theme,
    this.preferArabic = true,
    this.showBundledFallbacks = true,
  });

  final TextEditorState editor;
  final ThemeData theme;

  /// When true, list Arabic custom fonts before English.
  final bool preferArabic;

  /// Show bundled arabic_font + Google Arabic fallbacks under custom fonts.
  final bool showBundledFallbacks;

  @override
  State<MusamiArabicFontPickerStrip> createState() =>
      _MusamiArabicFontPickerStripState();
}

class _MusamiArabicFontPickerStripState
    extends State<MusamiArabicFontPickerStrip> {
  static const String _sampleArabic = 'نص';

  final CustomFontLibrary _library = CustomFontLibrary.instance;
  final UserFontLibrary _userFonts = UserFontLibrary.instance;
  String? _loadingFontKey;
  String? _loadingUserFontKey;

  @override
  void initState() {
    super.initState();
    _library.addListener(_onLibraryChanged);
    _userFonts.addListener(_onLibraryChanged);
    // Full catalog so both Arabic and English sections are available.
    _library.ensureLoaded();
    _userFonts.ensureLoaded();
  }

  @override
  void dispose() {
    _library.removeListener(_onLibraryChanged);
    _userFonts.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _applyCustomFont(CustomFontItem font) async {
    setState(() => _loadingFontKey = font.uuid.isNotEmpty ? font.uuid : '${font.id}');
    final style = await _library.loadStyle(font);
    if (!mounted) return;
    setState(() => _loadingFontKey = null);
    if (style == null) {
      showAppToast(
        _library.error ?? 'msg_custom_font_load_failed'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    applyMusamiTextEditorFont(
      widget.editor,
      style,
      fontPackage: null,
    );
    widget.editor.focusNode.requestFocus();
  }

  Future<void> _applyUserFont(UserFontItem font) async {
    setState(() => _loadingUserFontKey = font.id);
    final style = await _userFonts.loadStyle(font);
    if (!mounted) return;
    setState(() => _loadingUserFontKey = null);
    if (style == null) {
      showAppToast(
        _userFonts.error ?? 'msg_user_font_load_failed'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    applyMusamiTextEditorFont(
      widget.editor,
      style,
      fontPackage: null,
    );
    widget.editor.focusNode.requestFocus();
  }

  Future<void> _importUserFont() async {
    final result = await _userFonts.importFromDevice();
    if (!mounted) return;
    if (result is UserFontImportSuccess) {
      showAppToast(
        'msg_user_font_imported'.tr.replaceAll('{name}', result.font.name),
        type: ToastificationType.success,
      );
      await _applyUserFont(result.font);
    } else if (result is UserFontImportFailure) {
      showAppToast(result.message, type: ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
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
        SizedBox(height: 8.v),
        MusamiUserFontSections(
          theme: theme,
          library: _userFonts,
          loadingFontKey: _loadingUserFontKey,
          onSelect: _applyUserFont,
          onImport: _importUserFont,
        ),
        SizedBox(height: 10.v),
        Text(
          'lbl_text_editor_fonts_custom'.tr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8.v),
        MusamiCustomFontSections(
          theme: theme,
          library: _library,
          preferArabicFirst: widget.preferArabic,
          loadingFontKey: _loadingFontKey,
          onSelect: _applyCustomFont,
        ),
        if (widget.showBundledFallbacks && widget.preferArabic) ...[
          SizedBox(height: 10.v),
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
                  previewDirection: TextDirection.rtl,
                  label: e.label,
                  onTap: () {
                    applyMusamiTextEditorFont(
                      widget.editor,
                      ArabicTextStyle(arabicFont: e.familyId),
                      fontPackage: ArabicThemeData.package,
                    );
                    widget.editor.focusNode.requestFocus();
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
                  previewDirection: TextDirection.rtl,
                  label: e.label,
                  onTap: () {
                    applyMusamiTextEditorFont(
                      widget.editor,
                      e.build(),
                      fontPackage: null,
                    );
                    widget.editor.focusNode.requestFocus();
                  },
                );
              },
            ),
          ),
        ],
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
    this.previewDirection = TextDirection.rtl,
    this.trailing,
    this.busy = false,
    this.background,
    this.labelColor,
  });

  final ThemeData theme;
  final String previewText;
  final TextStyle previewStyle;
  final String label;
  final VoidCallback onTap;
  final TextDirection previewDirection;
  final IconData? trailing;
  final bool busy;
  final Color? background;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10.adaptSize),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.adaptSize),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.v),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 16.adaptSize,
                  height: 16.adaptSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  previewText,
                  style: previewStyle,
                  textDirection: previewDirection,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 2.v),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.fSize,
                        color: labelColor ?? theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: 2.h),
                    Icon(
                      trailing,
                      size: 10.adaptSize,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
