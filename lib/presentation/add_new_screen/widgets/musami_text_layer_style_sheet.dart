import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import 'musami_text_editor_widgets.dart';

bool _textDecorationHas(TextDecoration? decoration, TextDecoration part) {
  if (decoration == null || decoration == TextDecoration.none) {
    return false;
  }
  if (decoration == part) return true;
  if (part == TextDecoration.underline &&
      decoration ==
          TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ])) {
    return true;
  }
  if (part == TextDecoration.lineThrough &&
      decoration ==
          TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ])) {
    return true;
  }
  return false;
}

/// Pastel / highlighter-style swatches for [TextStyle.backgroundColor].
const List<Color> kMusamiHighlightPalette = [
  Color(0x66FFEB3B),
  Color(0x66FF9800),
  Color(0x66E91E63),
  Color(0x664CAF50),
  Color(0x662196F3),
  Color(0x669C27B0),
  Color(0x66B0BEC5),
  Color(0x66FFFFFF),
];

/// Keys stored on [TextLayer.meta] for outline; must match
/// `layer_widget_text_item.dart` in `pro_image_editor`.
const String kMusamiTextOutlineWidthMetaKey = 'musami_text_outline_w';
const String kMusamiTextOutlineColorMetaKey = 'musami_text_outline_c';

int musamiColorToArgb32(Color c) {
  int ch(double x) => (x * 255.0).round() & 0xff;
  return (ch(c.a) << 24) | (ch(c.r) << 16) | (ch(c.g) << 8) | ch(c.b);
}

Color musamiColorFromArgb32(int v) => Color(v);

/// Ring of non-blurred shadows to approximate a text outline (canvas text).
List<Shadow> musamiOutlineShadows(Color color, double strokeWidth) {
  if (strokeWidth <= 0) return [];
  final w = strokeWidth;
  final q = w * 0.70710678;
  final offsets = <Offset>[
    Offset(-w, 0),
    Offset(w, 0),
    Offset(0, -w),
    Offset(0, w),
    Offset(-q, -q),
    Offset(q, -q),
    Offset(-q, q),
    Offset(q, q),
  ];
  return offsets
      .map((o) => Shadow(color: color, offset: o, blurRadius: 0))
      .toList();
}

Map<String, dynamic> _mergeMeta(
  TextLayer layer, {
  Map<String, dynamic>? set,
  List<String>? removeKeys,
}) {
  final m = layer.meta == null
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(layer.meta!);
  removeKeys?.forEach(m.remove);
  if (set != null) {
    set.forEach((k, v) {
      if (v == null) {
        m.remove(k);
      } else {
        m[k] = v;
      }
    });
  }
  return m;
}

/// Full typography / styling for a selected [TextLayer] (not the inline
/// [TextEditorState] keyboard flow).
Future<void> showMusamiTextLayerStyleSheet({
  required BuildContext context,
  required ProImageEditorState editor,
  required TextLayer? Function() getLayer,
  required Future<void> Function() onOpenGoogleFontsPicker,
  required Future<void> Function() onOpenGradientEditor,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440.h,
                maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.92,
              ),
              child: AppDarkSheetTheme(
                child: Material(
                  color: AppDs.sheetBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppDs.radiusLg.adaptSize),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: StatefulBuilder(
                    builder: (ctx, setModal) {
                      TextLayer? layerOrNull() => getLayer();

                      void apply(TextLayer next) {
                        final cur = layerOrNull();
                        if (cur == null) return;
                        editor.applyTextLayerChanges(cur, next);
                        editor.setState(() {});
                        setModal(() {});
                      }

                      TextStyle baseStyle(TextLayer l) =>
                          l.textStyle ?? TextStyle(color: l.color);

                      final layer = layerOrNull();
                      if (layer == null) {
                        return Padding(
                          padding: EdgeInsets.all(AppDs.space4.h),
                          child: Text(
                            'No text layer selected',
                            style: AppDs.sheetBody(theme, color: Colors.white),
                          ),
                        );
                      }

                      final st = baseStyle(layer);
                      final hasUnderline = _textDecorationHas(
                        st.decoration,
                        TextDecoration.underline,
                      );
                      final hasStrike = _textDecorationHas(
                        st.decoration,
                        TextDecoration.lineThrough,
                      );
                      final outlineW =
                          (layer.meta?[kMusamiTextOutlineWidthMetaKey] as num?)
                              ?.toDouble() ??
                          0.0;
                      final outlineCi =
                          layer.meta?[kMusamiTextOutlineColorMetaKey] as int?;
                      final outlineColor = outlineCi != null
                          ? musamiColorFromArgb32(outlineCi)
                          : Colors.black;
                      final hasDropShadow =
                          st.shadows != null && st.shadows!.isNotEmpty;

                      TextDecoration? buildDecoration({
                        required bool u,
                        required bool s,
                      }) {
                        if (!u && !s) return TextDecoration.none;
                        if (u && s) {
                          return TextDecoration.combine([
                            TextDecoration.underline,
                            TextDecoration.lineThrough,
                          ]);
                        }
                        if (u) return TextDecoration.underline;
                        return TextDecoration.lineThrough;
                      }

                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppDs.space4.h,
                          AppDs.space2.v,
                          AppDs.space4.h,
                          AppDs.space6.v,
                        ),
                        shrinkWrap: true,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Text style',
                                  style: AppDs.sheetTitle(
                                    theme,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(sheetCtx),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppDs.space3.v),
                          Text(
                            'Case',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    final l = layerOrNull();
                                    if (l == null) return;
                                    apply(
                                      l.copyWith(text: l.text.toUpperCase()),
                                    );
                                  },
                                  child: const Text('UPPERCASE'),
                                ),
                              ),
                              SizedBox(width: AppDs.space2.h),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    final l = layerOrNull();
                                    if (l == null) return;
                                    apply(
                                      l.copyWith(text: l.text.toLowerCase()),
                                    );
                                  },
                                  child: const Text('lowercase'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppDs.space4.v),
                          Text(
                            'Font size',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          StatefulBuilder(
                            builder: (c, setS) {
                              final l = layerOrNull();
                              if (l == null) {
                                return const SizedBox.shrink();
                              }
                              final sz = (baseStyle(l).fontSize ?? 24.0).clamp(
                                8.0,
                                160.0,
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          value: sz,
                                          min: 8,
                                          max: 160,
                                          divisions: 152,
                                          label: sz.round().toString(),
                                          onChanged: (v) {
                                            final cur = layerOrNull();
                                            if (cur == null) return;
                                            final nextSt = baseStyle(
                                              cur,
                                            ).copyWith(fontSize: v);
                                            apply(
                                              cur.copyWith(
                                                textStyle: nextSt,
                                                color:
                                                    nextSt.color ?? cur.color,
                                              ),
                                            );
                                            setS(() {});
                                            setModal(() {});
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40.h,
                                        child: Text(
                                          sz.round().toString(),
                                          textAlign: TextAlign.end,
                                          style: AppDs.sheetBody(
                                            theme,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: AppDs.space2.v),
                          Text(
                            'Font weight',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 400, label: Text('Regular')),
                              ButtonSegment(value: 500, label: Text('Medium')),
                              ButtonSegment(value: 700, label: Text('Bold')),
                            ],
                            selected: {
                              switch (st.fontWeight?.value ?? 400) {
                                500 => 500,
                                700 => 700,
                                _ => 400,
                              },
                            },
                            onSelectionChanged: (s) {
                              final v = s.first;
                              final w = switch (v) {
                                500 => FontWeight.w500,
                                700 => FontWeight.w700,
                                _ => FontWeight.w400,
                              };
                              final l = layerOrNull();
                              if (l == null) return;
                              final nextSt = baseStyle(
                                l,
                              ).copyWith(fontWeight: w);
                              apply(
                                l.copyWith(
                                  textStyle: nextSt,
                                  color: nextSt.color ?? l.color,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: AppDs.space3.v),
                          Text(
                            'Style',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          Row(
                            children: [
                              FilterChip(
                                label: const Text('Italic'),
                                selected: st.fontStyle == FontStyle.italic,
                                onSelected: (sel) {
                                  final l = layerOrNull();
                                  if (l == null) return;
                                  final nextSt = baseStyle(l).copyWith(
                                    fontStyle: sel
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  );
                                  apply(
                                    l.copyWith(
                                      textStyle: nextSt,
                                      color: nextSt.color ?? l.color,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: AppDs.space2.h),
                              FilterChip(
                                label: const Text('Underline'),
                                selected: hasUnderline,
                                onSelected: (sel) {
                                  final l = layerOrNull();
                                  if (l == null) return;
                                  final nextSt = baseStyle(l).copyWith(
                                    decoration: buildDecoration(
                                      u: sel,
                                      s: hasStrike,
                                    ),
                                  );
                                  apply(
                                    l.copyWith(
                                      textStyle: nextSt,
                                      color: nextSt.color ?? l.color,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: AppDs.space2.h),
                              FilterChip(
                                label: const Text('Strike'),
                                selected: hasStrike,
                                onSelected: (sel) {
                                  final l = layerOrNull();
                                  if (l == null) return;
                                  final nextSt = baseStyle(l).copyWith(
                                    decoration: buildDecoration(
                                      u: hasUnderline,
                                      s: sel,
                                    ),
                                  );
                                  apply(
                                    l.copyWith(
                                      textStyle: nextSt,
                                      color: nextSt.color ?? l.color,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: AppDs.space4.v),
                          Text(
                            'Text color',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          Wrap(
                            spacing: AppDs.space2.h,
                            runSpacing: AppDs.space2.v,
                            children: kMusamiTextColorPalette.map((c) {
                              return InkWell(
                                onTap: () {
                                  final l = layerOrNull();
                                  if (l == null) return;
                                  final nextSt = baseStyle(
                                    l,
                                  ).copyWith(color: c);
                                  apply(
                                    l.copyWith(textStyle: nextSt, color: c),
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  AppDs.radiusLg.adaptSize,
                                ),
                                child: Container(
                                  width: AppDs.minTap.adaptSize * 0.65,
                                  height: AppDs.minTap.adaptSize * 0.65,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: AppDs.space4.v),
                          Text(
                            'Highlight',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          Wrap(
                            spacing: AppDs.space2.h,
                            runSpacing: AppDs.space2.v,
                            children: [
                              ActionChip(
                                label: const Text('None'),
                                onPressed: () {
                                  final l = layerOrNull();
                                  if (l == null) return;
                                  final nextSt = baseStyle(
                                    l,
                                  ).copyWith(
                                    backgroundColor: Colors.transparent,
                                  );
                                  apply(
                                    l.copyWith(
                                      textStyle: nextSt,
                                      color: nextSt.color ?? l.color,
                                    ),
                                  );
                                },
                              ),
                              ...kMusamiHighlightPalette.map((c) {
                                return InkWell(
                                  onTap: () {
                                    final l = layerOrNull();
                                    if (l == null) return;
                                    final nextSt = baseStyle(
                                      l,
                                    ).copyWith(backgroundColor: c);
                                    apply(
                                      l.copyWith(
                                        textStyle: nextSt,
                                        color: nextSt.color ?? l.color,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppDs.radiusLg.adaptSize,
                                  ),
                                  child: Container(
                                    width: AppDs.minTap.adaptSize * 0.65,
                                    height: AppDs.minTap.adaptSize * 0.65,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          SizedBox(height: AppDs.space4.v),
                          Text(
                            'Background (box)',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.format_color_reset,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              'Transparent',
                              style: AppDs.sheetBody(
                                theme,
                                color: Colors.white,
                              ),
                            ),
                            onTap: () {
                              final l = layerOrNull();
                              if (l == null) return;
                              apply(
                                l.copyWith(
                                  colorMode: LayerBackgroundMode.onlyColor,
                                  background: Colors.transparent,
                                ),
                              );
                            },
                          ),
                          Wrap(
                            spacing: AppDs.space2.h,
                            runSpacing: AppDs.space2.v,
                            children: kMusamiTextBackgroundPalette.map((c) {
                              return InkWell(
                                onTap: () {
                                  final l = layerOrNull();
                                  if (l == null) return;
                                  apply(
                                    l.copyWith(
                                      colorMode: LayerBackgroundMode
                                          .backgroundAndColor,
                                      background: c,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  AppDs.radiusLg.adaptSize,
                                ),
                                child: Container(
                                  width: AppDs.minTap.adaptSize * 0.65,
                                  height: AppDs.minTap.adaptSize * 0.65,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: AppDs.space4.v),
                          Text(
                            'Outline',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: outlineW.clamp(0, 8),
                                  min: 0,
                                  max: 8,
                                  divisions: 16,
                                  label: outlineW.toStringAsFixed(1),
                                  onChanged: (v) {
                                    final l = layerOrNull();
                                    if (l == null) return;
                                    if (v <= 0) {
                                      apply(
                                        l.copyWith(
                                          meta: _mergeMeta(
                                            l,
                                            removeKeys: const [
                                              kMusamiTextOutlineWidthMetaKey,
                                              kMusamiTextOutlineColorMetaKey,
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      apply(
                                        l.copyWith(
                                          meta: _mergeMeta(
                                            l,
                                            set: {
                                              kMusamiTextOutlineWidthMetaKey: v,
                                              kMusamiTextOutlineColorMetaKey:
                                                  musamiColorToArgb32(
                                                    outlineColor,
                                                  ),
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: AppDs.space2.h,
                            runSpacing: AppDs.space2.v,
                            children:
                                [
                                  const Color(0xFF000000),
                                  const Color(0xFFFFFFFF),
                                  ...kMusamiTextColorPalette.skip(2),
                                ].map((c) {
                                  return InkWell(
                                    onTap: () {
                                      final l = layerOrNull();
                                      if (l == null) return;
                                      final raw = l
                                          .meta?[kMusamiTextOutlineWidthMetaKey];
                                      final w =
                                          (raw is num
                                              ? raw.toDouble()
                                              : null) ??
                                          1.5;
                                      apply(
                                        l.copyWith(
                                          meta: _mergeMeta(
                                            l,
                                            set: {
                                              kMusamiTextOutlineWidthMetaKey:
                                                  w <= 0 ? 1.5 : w,
                                              kMusamiTextOutlineColorMetaKey:
                                                  musamiColorToArgb32(c),
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(
                                      AppDs.radiusLg.adaptSize,
                                    ),
                                    child: Container(
                                      width: AppDs.minTap.adaptSize * 0.55,
                                      height: AppDs.minTap.adaptSize * 0.55,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: AppDs.space4.v),
                          Text(
                            'Drop shadow',
                            style: AppDs.sheetCaption(
                              theme,
                              color: theme.colorScheme.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Soft shadow',
                              style: AppDs.sheetBody(
                                theme,
                                color: Colors.white,
                              ),
                            ),
                            value: hasDropShadow,
                            onChanged: (on) {
                              final l = layerOrNull();
                              if (l == null) return;
                              final nextSt = baseStyle(l).copyWith(
                                shadows: on
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          offset: const Offset(1.5, 2),
                                          blurRadius: 3.5,
                                        ),
                                      ]
                                    : null,
                              );
                              apply(
                                l.copyWith(
                                  textStyle: nextSt,
                                  color: nextSt.color ?? l.color,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: AppDs.space4.v),
                          FilledButton.icon(
                            onPressed: () => onOpenGoogleFontsPicker(),
                            icon: const Icon(Icons.font_download_outlined),
                            label: const Text('Font family (Google Fonts)'),
                          ),
                          SizedBox(height: AppDs.space2.v),
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetCtx);
                              await onOpenGradientEditor();
                            },
                            icon: const Icon(Icons.gradient_rounded),
                            label: const Text('Gradient (full editor)'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
