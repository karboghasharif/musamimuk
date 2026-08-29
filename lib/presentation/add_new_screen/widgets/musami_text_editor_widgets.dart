import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import 'arabic_custom_keyboard.dart';
import 'musami_text_editor_ai_sheet.dart';
import 'musami_text_editor_arabic_fonts.dart';
import 'musami_text_editor_script.dart';

/// Swatches for **text** (foreground).
const List<Color> kMusamiTextColorPalette = [
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFB71C1C),
  Color(0xFFE65100),
  Color(0xFFF9A825),
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFF4E342E),
  Color(0xFF546E7A),
];

/// Swatches for **text box background** (when not transparent).
const List<Color> kMusamiTextBackgroundPalette = [
  Color(0xFFFFFFFF),
  Color(0xFFF5F5F5),
  Color(0xFFFFF9C4),
  Color(0xFFC8E6C9),
  Color(0xFFBBDEFB),
  Color(0xFFE1BEE7),
  Color(0xFFFFCCBC),
  Color(0xFFB0BEC5),
  Color(0xFF37474F),
  Color(0xFF000000),
];

/// Picks **text color** ([TextEditorState.primaryColor] with text+background mode).
void musamiShowTextColorPicker(BuildContext context, TextEditorState editor) {
  if (editor.backgroundColorMode != LayerBackgroundMode.onlyColor) {
    editor.backgroundColorMode = LayerBackgroundMode.backgroundAndColor;
  }
  _musamiShowHueColorPickerSheet(
    context,
    title: 'lbl_pick_text_color'.tr,
    initialColor: editor.primaryColor,
    onColorChanged: (c) => editor.primaryColor = c,
  );
}

/// Picks **background** behind the glyphs; use transparent to remove fill.
void musamiShowTextBackgroundPicker(
  BuildContext context,
  TextEditorState editor,
) {
  showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final sheetTheme = Theme.of(ctx);
      Color pickerColor = editor.secondaryColor;
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final pickerWidth = min(
                MediaQuery.sizeOf(context).width - 32,
                320.0,
              );
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'lbl_pick_text_background'.tr,
                      style: AppDs.sheetTitle(sheetTheme, color: Colors.white),
                    ),
                    SizedBox(height: AppDs.space3.v),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.format_color_reset,
                        color: sheetTheme.colorScheme.primary,
                      ),
                      title: Text('lbl_text_bg_transparent'.tr),
                      subtitle: Text('msg_text_bg_transparent_hint'.tr),
                      onTap: () {
                        editor.backgroundColorMode =
                            LayerBackgroundMode.onlyColor;
                        editor.secondaryColor = Colors.transparent;
                        Navigator.pop(ctx);
                      },
                    ),
                    SizedBox(height: AppDs.space2.v),
                    Text(
                      'lbl_solid_background'.tr,
                      style: AppDs.sheetCaption(
                        sheetTheme,
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppDs.space3.v),
                    Center(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) {
                          setModalState(() => pickerColor = c);
                          editor.backgroundColorMode =
                              LayerBackgroundMode.backgroundAndColor;
                          editor.secondaryColor = c;
                        },
                        enableAlpha: false,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsvWithHue,
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.65,
                        colorPickerWidth: pickerWidth,
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

void _musamiShowHueColorPickerSheet(
  BuildContext context, {
  required String title,
  required Color initialColor,
  required ValueChanged<Color> onColorChanged,
  bool enableAlpha = false,
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
              final pickerWidth = min(
                MediaQuery.sizeOf(context).width - 32,
                320.0,
              );
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
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) {
                          setModalState(() => pickerColor = c);
                          onColorChanged(c);
                        },
                        enableAlpha: enableAlpha,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsvWithHue,
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.65,
                        colorPickerWidth: pickerWidth,
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

/// Full HSV colour picker for a canvas [TextLayer] (matches inline text editor UX).
void musamiShowLayerTextColorPicker(
  BuildContext context, {
  required String title,
  required Color initialColor,
  required ValueChanged<Color> onColorChanged,
  bool enableAlpha = false,
}) {
  _musamiShowHueColorPickerSheet(
    context,
    title: title,
    initialColor: initialColor,
    onColorChanged: onColorChanged,
    enableAlpha: enableAlpha,
  );
}

/// Background / highlight behind glyphs on a canvas [TextLayer].
void musamiShowLayerTextBackgroundPicker(
  BuildContext context, {
  required String title,
  required Color? currentBackground,
  required ValueChanged<Color?> onBackgroundChanged,
}) {
  showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final sheetTheme = Theme.of(ctx);
      Color pickerColor =
          currentBackground != null && currentBackground.a > 0.01
          ? currentBackground
          : Colors.white;
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: StatefulBuilder(
            builder: (innerCtx, setModalState) {
              final pickerWidth = min(
                MediaQuery.sizeOf(innerCtx).width - 32,
                320.0,
              );
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: AppDs.sheetTitle(sheetTheme, color: Colors.white),
                    ),
                    SizedBox(height: AppDs.space3.v),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.format_color_reset,
                        color: sheetTheme.colorScheme.primary,
                      ),
                      title: Text('lbl_text_bg_transparent'.tr),
                      subtitle: Text('msg_text_bg_transparent_hint'.tr),
                      onTap: () {
                        onBackgroundChanged(Colors.transparent);
                        Navigator.pop(ctx);
                      },
                    ),
                    SizedBox(height: AppDs.space2.v),
                    Text(
                      'lbl_solid_background'.tr,
                      style: AppDs.sheetCaption(
                        sheetTheme,
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppDs.space3.v),
                    Center(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) {
                          setModalState(() => pickerColor = c);
                          onBackgroundChanged(c);
                        },
                        enableAlpha: true,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsvWithHue,
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.65,
                        colorPickerWidth: pickerWidth,
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

/// Shared color circle grid (text editor + canvas text layers).
void musamiShowColorPickerGrid(
  BuildContext context, {
  required String title,
  required List<Color> palette,
  required void Function(Color) onPick,
}) {
  _musamiShowColorGridSheet(
    context,
    title: title,
    palette: palette,
    onPick: onPick,
  );
}

void _musamiShowColorGridSheet(
  BuildContext context, {
  required String title,
  required List<Color> palette,
  required void Function(Color) onPick,
}) {
  showAppModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final sheetTheme = Theme.of(ctx);
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppDs.sheetTitle(sheetTheme, color: Colors.white),
              ),
              SizedBox(height: AppDs.space4.v),
              Wrap(
                spacing: AppDs.space3.h,
                runSpacing: AppDs.space3.v,
                children: palette.map((c) {
                  final isWhite = c == const Color(0xFFFFFFFF);
                  return InkWell(
                    onTap: () {
                      onPick(c);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(
                      AppDs.radiusLg.adaptSize,
                    ),
                    child: Container(
                      width: AppDs.minTap.adaptSize * 0.85,
                      height: AppDs.minTap.adaptSize * 0.85,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isWhite
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: isWhite ? 2 : 0,
                        ),
                        boxShadow: [
                          if (!isWhite)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// App bar: close, English / Arabic script toggle, book (reference).
ReactiveAppbar musamiTextEditorAppBar({
  required TextEditorState editor,
  required Stream<void> rebuildStream,
  required ThemeData theme,
}) {
  return ReactiveAppbar(
    stream: rebuildStream,
    appbarSize: Size.fromHeight(52.v),
    builder: (context) {
      final rtl = editor.isMusamiRtl;
      return PreferredSize(
        preferredSize: Size.fromHeight(52.v),
        child: Material(
          color: appTheme.blueGray90004,
          elevation: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: editor.close,
                  ),
                  Expanded(
                    child: _MusamiScriptToggle(editor: editor, rtl: rtl),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _MusamiScriptToggle extends StatelessWidget {
  const _MusamiScriptToggle({required this.editor, required this.rtl});

  final TextEditorState editor;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Row(
        children: [
          Expanded(
            child: _toggleSegment(
              context,
              label: 'lbl_text_editor_english'.tr,
              selected: !rtl,
              onTap: () => editor.setMusamiScriptDirection(TextDirection.ltr),
              selectedBg: cs.primary,
              unselectedBg: appTheme.blueGray90002,
              selectedFg: cs.onPrimary,
              unselectedFg: cs.onPrimary.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(width: 14.h),
          Expanded(
            child: _toggleSegment(
              context,
              label: 'lbl_text_editor_arabic_script'.tr,
              selected: rtl,
              onTap: () => editor.setMusamiScriptDirection(TextDirection.rtl),
              selectedBg: cs.primary,
              unselectedBg: appTheme.yellow500,
              selectedFg: cs.onPrimary,
              unselectedFg: cs.onPrimary.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleSegment(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color selectedBg,
    required Color unselectedBg,
    required Color selectedFg,
    required Color unselectedFg,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? selectedBg : unselectedBg,
      borderRadius: BorderRadius.circular(14.adaptSize),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.adaptSize),
        onTap: onTap,
        child: SizedBox(
          height: 48.v,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? selectedFg : unselectedFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary action — matches “Add to design”.
ReactiveWidget musamiTextEditorBottomBar({
  required TextEditorState editor,
  required Stream<void> rebuildStream,
  required ThemeData theme,
}) {
  return ReactiveWidget(
    stream: rebuildStream,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 12.v),
          child: SizedBox(
            width: double.infinity,
            height: 52.v,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.adaptSize),
                ),
              ),
              onPressed: editor.done,
              child: Text(
                'lbl_add_to_design'.tr,
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Reserve space above the keyboard for the floating toolbar (LTR / RTL).
const double kMusamiTextEditorChromeHeightLtr = 96;
const double kMusamiTextEditorChromeHeightRtl = 256;

/// Tashkeela strip + quick actions above the bottom bar.
List<ReactiveWidget> musamiTextEditorBodyOverlay({
  required TextEditorState editor,
  required Stream<void> rebuildStream,
  required ThemeData theme,
}) {
  return [
    ReactiveWidget(
      stream: rebuildStream,
      builder: (context) {
        return _MusamiTextEditorFloatingChrome(editor: editor, theme: theme);
      },
    ),
  ];
}

/// Sizes bottom inset and listens to the text field so the font strip appears
/// when the user selects text in Arabic (RTL) mode.
class _MusamiTextEditorFloatingChrome extends StatefulWidget {
  const _MusamiTextEditorFloatingChrome({
    required this.editor,
    required this.theme,
  });

  final TextEditorState editor;
  final ThemeData theme;

  @override
  State<_MusamiTextEditorFloatingChrome> createState() =>
      _MusamiTextEditorFloatingChromeState();
}

class _MusamiTextEditorFloatingChromeState
    extends State<_MusamiTextEditorFloatingChrome> {
  /// Body stack bottom — scaffold already insets above the keyboard.
  double _overlayBottom(BuildContext context) => 8.v;

  IconData _alignIcon(TextAlign align) {
    return switch (align) {
      TextAlign.left => Icons.format_align_left_rounded,
      TextAlign.right => Icons.format_align_right_rounded,
      TextAlign.center || _ => Icons.format_align_center_rounded,
    };
  }

  void _nudgeFontScale(TextEditorState editor, double delta) {
    final next = (editor.fontScale + delta).clamp(
      editor.textEditorConfigs.minFontScale,
      editor.textEditorConfigs.maxFontScale,
    );
    editor.fontScale = next;
    editor.focusNode.requestFocus();
  }

  void _openFontsSheet(BuildContext context, TextEditorState editor) {
    final preferArabic = editor.isMusamiRtl;
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            bottomExtra: AppDs.space4,
            child: SingleChildScrollView(
              child: MusamiArabicFontPickerStrip(
                editor: editor,
                theme: widget.theme,
                preferArabic: preferArabic,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openTashkeelaSheet(BuildContext context, TextEditorState editor) {
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            bottomExtra: AppDs.space4,
            child: ArabicTashkeelaStrip(
              controller: editor.textCtrl,
              focusNode: editor.focusNode,
            ),
          ),
        );
      },
    ).then((_) => editor.focusNode.requestFocus());
  }

  Widget _toolbarButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? iconColor,
    bool enabled = true,
  }) {
    final cs = theme.colorScheme;
    final color = enabled
        ? (iconColor ?? cs.primary)
        : (iconColor ?? cs.primary).withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.adaptSize),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 72.h,
          height: AppDs.minTap.v,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22.adaptSize, color: color),
              SizedBox(height: 2.v),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.35),
                  fontSize: 10.fSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _toolbarButtons({
    required BuildContext context,
    required TextEditorState editor,
    required ThemeData theme,
    required bool rtl,
    required bool keyboardOpen,
  }) {
    return [
      _toolbarButton(
        theme: theme,
        icon: Icons.auto_awesome,
        label: 'lbl_text_editor_ai'.tr,
        onTap: () => musamiShowTextEditorAiSheet(context, editor),
      ),
      _toolbarButton(
        theme: theme,
        icon: Icons.format_color_text_rounded,
        label: 'lbl_text_editor_color'.tr,
        iconColor: editor.primaryColor,
        onTap: () {
          musamiShowTextColorPicker(context, editor);
          editor.focusNode.requestFocus();
        },
      ),
      _toolbarButton(
        theme: theme,
        icon: _alignIcon(editor.align),
        label: 'lbl_text_editor_align'.tr,
        onTap: () {
          editor.toggleTextAlign();
          editor.focusNode.requestFocus();
        },
      ),
      _toolbarButton(
        theme: theme,
        icon: Icons.text_decrease_rounded,
        label: 'lbl_text_editor_smaller'.tr,
        onTap: () => _nudgeFontScale(editor, -0.1),
      ),
      _toolbarButton(
        theme: theme,
        icon: Icons.text_increase_rounded,
        label: 'lbl_text_editor_larger'.tr,
        onTap: () => _nudgeFontScale(editor, 0.1),
      ),
      _toolbarButton(
        theme: theme,
        icon: Icons.font_download_rounded,
        label: 'lbl_text_editor_fonts_toolbar'.tr,
        onTap: () => _openFontsSheet(context, editor),
      ),
      if (rtl && keyboardOpen)
        _toolbarButton(
          theme: theme,
          icon: Icons.spellcheck_rounded,
          label: 'lbl_keyboard_tashkeela'.tr,
          onTap: () => _openTashkeelaSheet(context, editor),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final editor = widget.editor;
    final theme = widget.theme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: editor.textCtrl,
      builder: (context, value, _) {
        final rtl = editor.isMusamiRtl;
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final bottomPad = _overlayBottom(context);
        final showInlineTashkeela = rtl && !keyboardOpen;

        return Positioned(
          left: 10.h,
          right: 10.h,
          bottom: bottomPad,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 8.v),
              decoration: BoxDecoration(
                color: appTheme.blueGray90002,
                borderRadius: BorderRadius.circular(16.adaptSize),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _toolbarButtons(
                        context: context,
                        editor: editor,
                        theme: theme,
                        rtl: rtl,
                        keyboardOpen: keyboardOpen,
                      ),
                    ),
                  ),
                  if (showInlineTashkeela) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.v),
                      child: Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    ArabicTashkeelaStrip(
                      controller: editor.textCtrl,
                      focusNode: editor.focusNode,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
