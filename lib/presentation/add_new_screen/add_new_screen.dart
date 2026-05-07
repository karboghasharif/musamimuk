import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/core/models/layers/layer_interaction.dart';
import 'package:pro_image_editor/features/filter_editor/constants/identity_matrix_constant.dart';
import 'package:pro_image_editor/features/filter_editor/utils/combine_color_matrix_utils.dart';
import 'package:pro_image_editor/features/tune_editor/utils/tune_presets.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/repositories/design_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/add_new_bloc.dart';
import 'models/add_new_model.dart';
import 'models/gridgallery_pic_item_model.dart';
import 'widgets/gridgallery_pic_item_widget.dart';
import 'widgets/api_asset_bottom_sheet.dart';
import 'widgets/design_export_encode.dart';
import 'widgets/design_save_form_dialog.dart';
import 'widgets/design_save_success_sheet.dart';
import 'widgets/musami_text_editor_widgets.dart';
import 'widgets/musami_text_layer_style_sheet.dart';
import 'widgets/shapes_bottom_sheet.dart';
import 'widgets/editor_align_arrange_sheet.dart';
import 'widgets/editor_contextual_toolbars.dart';

/// Same tune definitions as the main editor (for layer [ColorFiltered] matrix).
List<TuneAdjustmentItem> musamiTuneItemsFromConfigs(ProImageEditorConfigs c) {
  return c.tuneEditor.tuneAdjustmentOptions ??
      tunePresets(icons: c.tuneEditor.icons, i18n: c.i18n.tuneEditor);
}

List<TuneAdjustmentItem> musamiTuneItemsFromEditor(ProImageEditorState editor) {
  return musamiTuneItemsFromConfigs(editor.configs);
}

List<TuneAdjustmentItem> musamiDefaultTuneAdjustmentItems() {
  return tunePresets(
    icons: const TuneEditorIcons(),
    i18n: const I18nTuneEditor(),
  );
}

bool musamiColorMatrixIsIdentity(List<double> m) {
  for (var i = 0; i < identityMatrix.length; i++) {
    if ((m[i] - identityMatrix[i]).abs() > 1e-4) return false;
  }
  return true;
}

/// Builds a 4×5 color matrix from [meta] `musamiLayerTune` using [items] order.
List<double> musamiLayerTuneColorMatrix(
  Map<String, dynamic> meta,
  List<TuneAdjustmentItem> items,
) {
  final raw = meta['musamiLayerTune'];
  if (raw == null || raw is! Map) {
    return List<double>.from(identityMatrix);
  }
  final tuneMap = <String, double>{};
  for (final e in raw.entries) {
    tuneMap[e.key.toString()] = (e.value as num).toDouble();
  }
  final matrices = <List<double>>[];
  for (final item in items) {
    final v = tuneMap[item.id];
    final value = (v ?? 0.0).clamp(item.min, item.max);
    matrices.add(item.toMatrix(value));
  }
  return mergeColorMatrices(filterList: const [], tuneAdjustmentList: matrices);
}

/// Opacity slider must always wrap the base child; stacking [Opacity] multiplies alphas.
Widget _unwrapOuterOpacityWidgets(Widget widget) {
  Widget w = widget;
  while (w is Opacity) {
    final next = (w as Opacity).child;
    if (next == null) break;
    w = next;
  }
  return w;
}

/// Border + drop shadow from [meta], applied around the unwrapped layer core.
/// Optional [tuneAdjustmentItems] must match the editor config when set (layer tune in [meta]).
Widget musamiComposeImageLayerVisualCore(
  Widget coreUnwrapped,
  Map<String, dynamic> meta, {
  List<TuneAdjustmentItem>? tuneAdjustmentItems,
}) {
  final items = tuneAdjustmentItems ?? musamiDefaultTuneAdjustmentItems();
  Widget w = coreUnwrapped;
  final matrix = musamiLayerTuneColorMatrix(meta, items);
  if (!musamiColorMatrixIsIdentity(matrix)) {
    w = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: w);
  }

  final borderW = (meta['musamiBorderW'] as num?)?.toDouble() ?? 0;
  final shadowBlur = (meta['musamiShadowBlur'] as num?)?.toDouble() ?? 0;

  Border? border;
  if (borderW > 0) {
    final argb = (meta['musamiBorderArgb'] as int?) ?? 0xFF212121;
    border = Border.all(
      color: musamiColorFromArgb32(argb),
      width: borderW.clamp(0.5, 24.0),
    );
  }

  List<BoxShadow>? shadows;
  if (shadowBlur > 0) {
    final dy = (meta['musamiShadowDy'] as num?)?.toDouble() ?? 6;
    final op = (meta['musamiShadowStrength'] as num?)?.toDouble() ?? 0.35;
    shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: op.clamp(0.0, 1.0)),
        blurRadius: shadowBlur.clamp(0.0, 80.0),
        offset: Offset(0, dy),
      ),
    ];
  }

  if (border == null && (shadows == null || shadows.isEmpty)) {
    return w;
  }

  return DecoratedBox(
    decoration: BoxDecoration(border: border, boxShadow: shadows),
    child: w,
  );
}

WidgetLayer musamiRebuildWidgetLayerVisuals(
  WidgetLayer current,
  Map<String, dynamic> meta, {
  List<TuneAdjustmentItem>? tuneAdjustmentItems,
}) {
  final core = _unwrapOuterOpacityWidgets(current.widget);
  final opacity =
      (meta['musamiOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0;
  final styled = musamiComposeImageLayerVisualCore(
    core,
    meta,
    tuneAdjustmentItems: tuneAdjustmentItems,
  );
  return WidgetLayer(
    id: current.id,
    key: current.key,
    widget: Opacity(opacity: opacity, child: styled),
    width: current.width,
    offset: current.offset,
    rotation: current.rotation,
    scale: current.scale,
    flipX: current.flipX,
    flipY: current.flipY,
    interaction: current.interaction,
    meta: meta,
    boxConstraints: current.boxConstraints,
    groupId: current.groupId,
    startTime: current.startTime,
    endTime: current.endTime,
    enterDuration: current.enterDuration,
    exitDuration: current.exitDuration,
    enterCurve: current.enterCurve,
    exitCurve: current.exitCurve,
    transitionBuilder: current.transitionBuilder,
  );
}

/// Always-visible brush / line width control + default paint mode tools.
ReactiveWidget musamiPaintEditorBottomBar(
  PaintEditorState editor,
  Stream<void> rebuildStream,
) {
  return ReactiveWidget(
    stream: rebuildStream,
    builder: (context) {
      final cfg = editor.configs.paintEditor;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _musamiPaintBrushSizeRow(context, editor, cfg),
          if (editor.tools.length > 1)
            Material(
              color: cfg.style.bottomBarBackground,
              child: SizedBox(
                height: kToolbarHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: editor.tools.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 4),
                  itemBuilder: (ctx, i) {
                    final item = editor.tools[i];
                    final active = editor.paintMode == item.mode;
                    final color = active
                        ? cfg.style.bottomBarActiveItemColor
                        : cfg.style.bottomBarInactiveItemColor;
                    return FlatIconTextButton(
                      label: Text(
                        item.label,
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                      icon: Icon(item.icon, color: color),
                      onPressed: () => editor.setMode(item.mode),
                    );
                  },
                ),
              ),
            ),
        ],
      );
    },
  );
}

Widget _musamiPaintBrushSizeRow(
  BuildContext context,
  PaintEditorState editor,
  PaintEditorConfigs cfg,
) {
  return Material(
    color: cfg.style.bottomBarBackground,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Icon(
            Icons.brush_outlined,
            size: 22,
            color: cfg.style.bottomBarActiveItemColor,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Text(
              editor.i18n.paintEditor.lineWidth,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cfg.style.bottomBarActiveItemColor,
              ),
              maxLines: 2,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: Slider(
                value: editor.strokeWidth.clamp(
                  cfg.minStrokeWidth,
                  cfg.maxStrokeWidth,
                ),
                min: cfg.minStrokeWidth,
                max: cfg.maxStrokeWidth,
                divisions: cfg.divisionsStrokeWidth > 0
                    ? cfg.divisionsStrokeWidth
                    : null,
                label: editor.strokeWidth.toStringAsFixed(0),
                onChanged: editor.setStrokeWidth,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Inline tune controls for the image contextual toolbar (selected layer only).
class MusamiImageAdjustContextPanel extends StatefulWidget {
  const MusamiImageAdjustContextPanel({
    super.key,
    required this.editor,
    required this.layerId,
    required this.theme,
    required this.onClose,
  });

  final ProImageEditorState editor;
  final String layerId;
  final ThemeData theme;
  final VoidCallback onClose;

  @override
  State<MusamiImageAdjustContextPanel> createState() =>
      _MusamiImageAdjustContextPanelState();
}

class _MusamiImageAdjustContextPanelState
    extends State<MusamiImageAdjustContextPanel> {
  List<TuneAdjustmentItem> _items = const [];
  final Map<String, double> _values = {};

  WidgetLayer? _layer() {
    for (final l in widget.editor.activeLayers) {
      if (l.id == widget.layerId && l is WidgetLayer) return l;
    }
    return null;
  }

  void _loadItemsAndValues() {
    _items = musamiTuneItemsFromEditor(widget.editor);
    _values.clear();
    final layer = _layer();
    final tuneRaw = layer?.meta?['musamiLayerTune'];
    for (final item in _items) {
      final v = tuneRaw is Map && tuneRaw[item.id] != null
          ? (tuneRaw[item.id] as num).toDouble().clamp(item.min, item.max)
          : 0.0;
      _values[item.id] = v;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItemsAndValues();
  }

  @override
  void didUpdateWidget(covariant MusamiImageAdjustContextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layerId != widget.layerId ||
        oldWidget.editor != widget.editor) {
      _loadItemsAndValues();
    }
  }

  void _apply() {
    final current = _layer();
    if (current == null) return;
    final meta = current.meta == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(current.meta!);
    final out = <String, double>{};
    for (final item in _items) {
      final v = _values[item.id] ?? 0.0;
      if (v.abs() > 1e-6) out[item.id] = v;
    }
    if (out.isEmpty) {
      meta.remove('musamiLayerTune');
    } else {
      meta['musamiLayerTune'] = out;
    }
    final updated = musamiRebuildWidgetLayerVisuals(
      current,
      meta,
      tuneAdjustmentItems: _items,
    );
    final idx = widget.editor.activeLayers.indexWhere(
      (l) => l.id == current.id,
    );
    if (idx >= 0) {
      widget.editor.replaceLayer(index: idx, layer: updated);
      widget.editor.layerInteractionManager.selectedLayerId = updated.id;
      widget.editor.setState(() {});
    }
  }

  void _reset() {
    for (final item in _items) {
      _values[item.id] = 0.0;
    }
    setState(() {});
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final cs = t.colorScheme;
    if (_items.isEmpty) _loadItemsAndValues();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppDs.space1.h,
            right: AppDs.space1.h,
            bottom: AppDs.space1.v,
          ),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: widget.onClose,
                icon: Icon(Icons.arrow_back_rounded, color: cs.primary),
              ),
              Expanded(
                child: Text(
                  'Adjust image',
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: Text('Reset', style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: AppDs.space2.h),
              itemCount: _items.length,
              separatorBuilder: (_, _) => SizedBox(height: AppDs.space1.v),
              itemBuilder: (context, i) {
                final item = _items[i];
                final v = (_values[item.id] ?? 0.0).clamp(item.min, item.max);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: t.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF424242),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(v * item.labelMultiplier).round()}',
                          style: t.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: cs.primary,
                        inactiveTrackColor: cs.outline.withValues(alpha: 0.25),
                        thumbColor: cs.primary,
                        overlayColor: cs.primary.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: v,
                        min: item.min,
                        max: item.max,
                        divisions: item.divisions > 0 ? item.divisions : null,
                        onChanged: (nv) {
                          setState(() => _values[item.id] = nv);
                          _apply();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AddNewScreen extends StatefulWidget {
  final double width;
  final double height;
  final String unit;
  final String presetName;
  const AddNewScreen({
    super.key,
    required this.height,
    required this.width,
    this.unit = 'px',
    this.presetName = 'Custom Size',
  });

  static Widget builder(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final height = arguments?['height'] as double? ?? 400.0;
    final width = arguments?['width'] as double? ?? 400.0;
    final unit = arguments?['unit'] as String? ?? 'px';
    final presetName = arguments?['presetName'] as String? ?? 'Custom Size';

    return BlocProvider<AddNewBloc>(
      create: (context) =>
          AddNewBloc(AddNewState(screen3AddNewModelObj: AddNewModel()))
            ..add(Screen3AddNewInitialEvent(height: height, width: width)),
      child: AddNewScreen(
        height: height,
        width: width,
        unit: unit,
        presetName: presetName,
      ),
    );
  }

  @override
  State<AddNewScreen> createState() => _AddNewScreenState();
}

class _AddNewScreenState extends State<AddNewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const int _doubleTapThresholdMs = 320;
  String? _lastTapLayerId;
  int _lastTapEpochMs = 0;

  bool _isDoubleTapOnSameLayer(String layerId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ok =
        _lastTapLayerId == layerId &&
        (now - _lastTapEpochMs) <= _doubleTapThresholdMs;
    _lastTapLayerId = layerId;
    _lastTapEpochMs = now;
    return ok;
  }

  static const double _kStickerLayerSize = 180.0;
  static const double _kStickerCornerRadius = 16.0;

  Widget _wrapAsStickerChrome(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kStickerCornerRadius),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kStickerCornerRadius),
        child: child,
      ),
    );
  }

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  String _musamiImageLayerKind(WidgetLayer layer) {
    final raw = layer.meta?['musamiLayerKind'] as String?;
    switch (raw) {
      case 'sticker':
      case 'png':
      case 'logo':
      case 'gallery':
      case 'shape':
        return raw!;
      default:
        return 'gallery';
    }
  }

  Future<WidgetLayer?> _showStickerPickerForReplace(
    BuildContext context,
    ProImageEditorState editor,
  ) {
    final configs = editor.configs;
    final stickerEditorConfigs = configs.stickerEditor;
    final effectiveBoxConstraints = stickerEditorConfigs
        .style
        .editorBoxConstraintsBuilder
        ?.call(context, configs);
    final sheetTheme = stickerEditorConfigs.style.draggableSheetStyle;
    return showModalBottomSheet<WidgetLayer>(
      context: context,
      backgroundColor: stickerEditorConfigs.style.bottomSheetBackgroundColor,
      constraints: effectiveBoxConstraints,
      showDragHandle: stickerEditorConfigs.style.showDragHandle,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          expand: sheetTheme.expand,
          initialChildSize: sheetTheme.initialChildSize,
          maxChildSize: sheetTheme.maxChildSize,
          minChildSize: sheetTheme.minChildSize,
          shouldCloseOnMinExtent: sheetTheme.shouldCloseOnMinExtent,
          snap: sheetTheme.snap,
          snapAnimationDuration: sheetTheme.snapAnimationDuration,
          snapSizes: sheetTheme.snapSizes,
          builder: (_, controller) =>
              StickerEditor(configs: configs, scrollController: controller),
        ),
      ),
    );
  }

  Future<WidgetLayer?> _showApiAssetPickSheet(
    BuildContext context,
    GlobalKey<ProImageEditorState>? editorKey,
    MediaType type,
  ) {
    return showModalBottomSheet<WidgetLayer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.75,
        child: ApiAssetBottomSheet(
          editorKey: editorKey,
          type: type,
          pickOnly: true,
        ),
      ),
    );
  }

  void _applyReplacingWidgetLayer({
    required ProImageEditorState editor,
    required WidgetLayer existing,
    required WidgetLayer picked,
  }) {
    final opacity =
        (existing.meta?['musamiOpacity'] as num?)?.toDouble() ?? 1.0;
    final meta = Map<String, dynamic>.from(picked.meta ?? {});
    meta['musamiOpacity'] = opacity;
    final kind = picked.meta?['musamiLayerKind'] as String?;
    meta['musamiLayerKind'] = (kind != null && kind.isNotEmpty)
        ? kind
        : 'gallery';
    final ex = existing.meta;
    if (ex != null) {
      for (final k in const [
        'musamiBorderW',
        'musamiBorderArgb',
        'musamiShadowBlur',
        'musamiShadowDy',
        'musamiShadowStrength',
      ]) {
        if (ex.containsKey(k)) meta[k] = ex[k];
      }
    }

    final core = _unwrapOuterOpacityWidgets(picked.widget);
    final styled = musamiComposeImageLayerVisualCore(core, meta);
    final updated = WidgetLayer(
      id: existing.id,
      key: existing.key,
      widget: Opacity(opacity: opacity.clamp(0.0, 1.0), child: styled),
      width: existing.width,
      offset: existing.offset,
      rotation: existing.rotation,
      scale: existing.scale,
      flipX: existing.flipX,
      flipY: existing.flipY,
      interaction: existing.interaction,
      meta: meta,
      boxConstraints: existing.boxConstraints,
      groupId: existing.groupId,
      startTime: existing.startTime,
      endTime: existing.endTime,
      enterDuration: existing.enterDuration,
      exitDuration: existing.exitDuration,
      enterCurve: existing.enterCurve,
      exitCurve: existing.exitCurve,
      transitionBuilder: existing.transitionBuilder,
    );

    final idx = editor.activeLayers.indexWhere((l) => l.id == existing.id);
    if (idx >= 0) {
      editor.replaceLayer(index: idx, layer: updated);
      editor.layerInteractionManager.selectedLayerId = updated.id;
      editor.setState(() {});
    }
  }

  Future<void> _showGoogleFontsPicker({
    required BuildContext context,
    required ProImageEditorState editor,
    required TextLayer layer,
    required TextLayer Function(TextLayer layer, {TextStyle? textStyle})
    copyTextLayer,
  }) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseStyle = layer.textStyle ?? const TextStyle();

    final allFonts = GoogleFonts.asMap().keys.toList()..sort();
    String query = '';

    Future<void> applyFont(String fontName) async {
      final nextStyle = GoogleFonts.getFont(fontName, textStyle: baseStyle);
      final updated = copyTextLayer(layer, textStyle: nextStyle);
      editor.applyTextLayerChanges(layer, updated);
      editor.setState(() {});
    }

    await showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420.h,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
                ),
                child: AppDarkSheetTheme(
                  child: Material(
                    color: AppDs.sheetBackground,
                    borderRadius: BorderRadius.circular(
                      AppDs.radiusLg.adaptSize,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: StatefulBuilder(
                      builder: (ctx, setSheetState) {
                        final filtered = query.trim().isEmpty
                            ? allFonts
                            : allFonts
                                  .where(
                                    (f) => f.toLowerCase().contains(
                                      query.trim().toLowerCase(),
                                    ),
                                  )
                                  .toList();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppDs.space4.h,
                                AppDs.space3.v,
                                AppDs.space2.h,
                                AppDs.space2.v,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Google Fonts',
                                      style: AppDs.sheetTitle(
                                        theme,
                                        color: Colors.white,
                                      ).copyWith(fontSize: 18.fSize),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppDs.space4.h,
                                0,
                                AppDs.space4.h,
                                AppDs.space3.v,
                              ),
                              child: TextField(
                                onChanged: (v) =>
                                    setSheetState(() => query = v),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search fonts',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDs.radiusMd.adaptSize,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDs.radiusMd.adaptSize,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDs.radiusMd.adaptSize,
                                    ),
                                    borderSide: BorderSide(
                                      color: cs.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppDs.space3.h,
                                    vertical: AppDs.space3.v,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final maxW = constraints.maxWidth;
                                  final crossAxisCount = maxW >= 380 ? 2 : 1;
                                  final previewText = layer.text.trim().isEmpty
                                      ? 'The quick brown fox 123'
                                      : layer.text;

                                  return GridView.builder(
                                    padding: EdgeInsets.fromLTRB(
                                      5.h,
                                      0,
                                      5.h,
                                      5.v,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 10.v,
                                          crossAxisSpacing: 10.h,
                                          childAspectRatio: crossAxisCount == 1
                                              ? 4.8
                                              : 3.2,
                                        ),
                                    itemCount: filtered.length,
                                    itemBuilder: (ctx, i) {
                                      final fontName = filtered[i];
                                      final previewStyle = GoogleFonts.getFont(
                                        fontName,
                                        textStyle: baseStyle.copyWith(
                                          fontSize: 18.fSize,
                                          color: Colors.white,
                                        ),
                                      );

                                      return Material(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppDs.radiusMd.adaptSize,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            AppDs.radiusMd.adaptSize,
                                          ),
                                          onTap: () async {
                                            await applyFont(fontName);
                                            if (ctx.mounted) Navigator.pop(ctx);
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              12.h,
                                              10.v,
                                              12.h,
                                              10.v,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fontName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                                SizedBox(height: 6.v),
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      previewText,
                                                      maxLines:
                                                          crossAxisCount == 1
                                                          ? 1
                                                          : 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: previewStyle,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
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

  Widget _buildGalleryStickerWidget(
    BuildContext context, {
    required ImageProvider image,
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: _wrapAsStickerChrome(
        context,
        ColoredBox(
          color: Colors.transparent,
          child: Image(
            image: image,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appLocaleNotifier,
      builder: (context, _) {
        return SafeArea(
          child: BlocBuilder<AddNewBloc, AddNewState>(
            builder: (context, state) {
              final width = widget.width;
              final height = widget.height;
              if (state.transparentBytes == null) {
                // Show a loading indicator or handle the null state
                return const CircularProgressIndicator();
              }

              return Scaffold(
                key: _scaffoldKey,
                drawer: AppNavigationDrawer(
                  key: ValueKey<Object>(
                    Object.hash(
                      appLocaleNotifier.languageCode,
                      appLocaleNotifier.localeRevision,
                    ),
                  ),
                  homePopsToRootHome: true,
                ),
                body: Stack(
                  children: [
                    ProImageEditor.memory(
                      key: state.editorKey,
                      state.transparentBytes!,
                      callbacks: ProImageEditorCallbacks(
                        onImageEditingComplete: (Uint8List bytes) async {
                          // Dismiss ProImageEditor loading overlay before any await.
                          // Otherwise the modal barrier blocks the save dialog
                          // until the entire save pipeline finishes (or a debug tap).
                          LoadingDialog.instance.hide();
                          if (!context.mounted) return;
                          final w = state.selectedwidth ?? width;
                          final h = state.selectedheight ?? height;
                          await _runPostExportSavePipeline(
                            context: context,
                            imageBytes: bytes,
                            width: w.toInt(),
                            height: h.toInt(),
                          );
                        },
                        mainEditorCallbacks: MainEditorCallbacks(
                          onSelectedLayerChanged: (id) {
                            final editor = state.editorKey?.currentState;
                            if (editor == null) return;
                            final selectedId = id.trim();
                            if (selectedId.isEmpty) {
                              context.read<AddNewBloc>().add(
                                EditorClearSelectionEvent(),
                              );
                              return;
                            }
                            final Layer? layer = editor.activeLayers
                                .cast<Layer?>()
                                .firstWhere(
                                  (l) => l?.id == selectedId,
                                  orElse: () => null,
                                );
                            final type = switch (layer) {
                              TextLayer() => 'text',
                              WidgetLayer() => 'image',
                              PaintLayer() => 'shape',
                              _ => null,
                            };
                            context.read<AddNewBloc>().add(
                              EditorSelectionChangedEvent(
                                selectedElementId: selectedId,
                                selectedElementType: type,
                              ),
                            );
                          },
                          onLayerTapUp: (layer) {
                            if (layer is! TextLayer) return;
                            final editor = state.editorKey?.currentState;
                            if (editor == null) return;

                            final isDoubleTap = _isDoubleTapOnSameLayer(
                              layer.id,
                            );

                            if (!isDoubleTap) return;
                            editor.editTextLayer(layer);
                          },
                        ),
                      ),
                      configs: _musamiProImageEditorConfigs(context),
                    ),

                    state.showbottomContainer == '1'
                        ? _buildColumnBookmark(context, state)
                        : const SizedBox(),
                    state.showbottomContainer == '2'
                        ? _buildColumnSelectSize(context, state)
                        : const SizedBox(),
                    state.showbottomContainer == '4'
                        ? _buildBgColorOverlay(context, state)
                        : const SizedBox(),
                    state.showbottomContainer == '2'
                        ? CustomImageView(
                            imagePath: ImageConstant.imgPolygon1,
                            height: 47.v,
                            width: 103.h,
                            alignment: Alignment.bottomLeft,
                            margin: EdgeInsets.only(left: 106.h),
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                    state.showbottomContainer == '1'
                        ? CustomImageView(
                            imagePath: ImageConstant.imgPolygon1,
                            height: 47.v,
                            width: 103.h,
                            alignment: Alignment.bottomLeft,
                            margin: EdgeInsets.only(left: 26.h),
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                    state.showbottomContainer == '4'
                        ? CustomImageView(
                            imagePath: ImageConstant.imgPolygon1,
                            height: 47.v,
                            width: 103.h,
                            alignment: Alignment.bottomLeft,
                            margin: EdgeInsets.only(left: 290.h),
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                  ],
                ),
                bottomNavigationBar: state.activeToolbarMode == 'text'
                    ? _buildTextContextBottomBar(context, state)
                    : state.activeToolbarMode == 'image'
                    ? _buildImageContextBottomBar(context, state)
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 49.h,
                          vertical: 10.v,
                        ),
                        child: SizedBox(
                          height: 52,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  BlocProvider.of<AddNewBloc>(context).add(
                                    ShowContainerEvent(
                                      ishow: state.showbottomContainer == '1'
                                          ? '0'
                                          : '1',
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconButton(
                                      height: 22.adaptSize,
                                      width: 22.adaptSize,
                                      child: CustomImageView(
                                        imagePath:
                                            state.showbottomContainer == '1'
                                            ? ImageConstant.imgPlusSvgrepoCom
                                            : ImageConstant
                                                  .imgPlusSvgrepoComOnprimarycontainer,
                                      ),
                                    ),
                                    SizedBox(height: 4.v),
                                    Text(
                                      "lbl_add_new".tr,
                                      style: state.showbottomContainer == '1'
                                          ? CustomTextStyles.bodySmallYellowA400
                                          : theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  BlocProvider.of<AddNewBloc>(context).add(
                                    ShowContainerEvent(
                                      ishow: state.showbottomContainer != '0'
                                          ? '0'
                                          : '2',
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconButton(
                                      height: 22.adaptSize,
                                      width: 22.adaptSize,
                                      child: CustomImageView(
                                        imagePath:
                                            state.showbottomContainer == '2'
                                            ? ImageConstant
                                                  .imgSlideSizeSvgrepoComPrimary
                                            : ImageConstant
                                                  .imgSlideSizeSvgrepoCom,
                                      ),
                                    ),
                                    SizedBox(height: 4.v),
                                    Text(
                                      "lbl_resize_paper".tr,
                                      style: state.showbottomContainer == '2'
                                          ? CustomTextStyles.bodySmallYellowA400
                                          : theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  BlocProvider.of<AddNewBloc>(
                                    context,
                                  ).add(MakeTransparentEvent());
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconButton(
                                      height: 22.adaptSize,
                                      width: 22.adaptSize,
                                      child: CustomImageView(
                                        imagePath:
                                            state.showbottomContainer == '3'
                                            ? ImageConstant
                                                  .imgBlockchainSvgrepoComPrimary
                                            : ImageConstant
                                                  .imgBlockchainSvgrepoCom,
                                      ),
                                    ),
                                    SizedBox(height: 4.v),
                                    Text(
                                      "lbl_transparent_bg".tr,
                                      style: state.showbottomContainer == '3'
                                          ? CustomTextStyles.bodySmallYellowA400
                                          : theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  BlocProvider.of<AddNewBloc>(context).add(
                                    ShowContainerEvent(
                                      ishow: state.showbottomContainer == '4'
                                          ? '0'
                                          : '4',
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconButton(
                                      height: 22.adaptSize,
                                      width: 22.adaptSize,
                                      child: CustomImageView(
                                        imagePath:
                                            state.showbottomContainer == '4'
                                            ? ImageConstant
                                                  .imgColorFillSvgrepoComPrimary
                                            : ImageConstant
                                                  .imgColorFillSvgrepoCom,
                                      ),
                                    ),
                                    SizedBox(height: 4.v),
                                    Text(
                                      "lbl_bg_color".tr,
                                      style: state.showbottomContainer == '4'
                                          ? CustomTextStyles.bodySmallYellowA400
                                          : theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTextContextBottomBar(BuildContext context, AddNewState state) {
    final editor = state.editorKey?.currentState;
    if (editor == null) return const SizedBox.shrink();

    TextLayer? selectedTextLayer() {
      final id = state.selectedElementId;
      if (id == null) return null;
      return editor.activeLayers
          .whereType<TextLayer>()
          .cast<TextLayer?>()
          .firstWhere((l) => l?.id == id, orElse: () => null);
    }

    TextLayer _copyTextLayer(TextLayer layer, {TextStyle? textStyle}) {
      final effectiveStyle = textStyle ?? layer.textStyle;
      return layer.copyWith(
        textStyle: effectiveStyle,
        color: effectiveStyle?.color ?? layer.color,
      );
    }

    void applyTextStyle(TextLayer original, TextStyle style) {
      editor.applyTextLayerChanges(
        original,
        _copyTextLayer(original, textStyle: style),
      );
    }

    void openSizeSheet() {
      final layer = selectedTextLayer();
      if (layer == null) return;
      final style = layer.textStyle ?? const TextStyle();
      final currentSize = (style.fontSize ?? 24.0).toDouble();

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(context);
          double v = currentSize.clamp(8.0, 160.0);
          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Size',
                              style: AppDs.sheetTitle(t, color: Colors.white),
                            ),
                          ),
                          Text(
                            v.toStringAsFixed(0),
                            style: AppDs.sheetTitle(t, color: Colors.white),
                          ),
                        ],
                      ),
                      Slider(
                        value: v,
                        min: 8,
                        max: 160,
                        divisions: 152,
                        onChanged: (nv) {
                          setState(() => v = nv);
                          applyTextStyle(
                            layer,
                            (layer.textStyle ?? const TextStyle()).copyWith(
                              fontSize: nv,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppSecondaryButton(
                        label: 'lbl_apply'.tr,
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

    void openOpacitySheet() {
      final layer = selectedTextLayer();
      if (layer == null) return;
      final baseColor = (layer.textStyle?.color) ?? layer.color;
      final currentOpacity = baseColor.opacity.clamp(0.0, 1.0);

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(context);
          double v = currentOpacity;
          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Opacity',
                              style: AppDs.sheetTitle(t, color: Colors.white),
                            ),
                          ),
                          Text(
                            '${(v * 100).round()}%',
                            style: AppDs.sheetTitle(t, color: Colors.white),
                          ),
                        ],
                      ),
                      Slider(
                        value: v,
                        min: 0,
                        max: 1,
                        divisions: 100,
                        onChanged: (nv) {
                          setState(() => v = nv);
                          final live = selectedTextLayer();
                          if (live == null) return;
                          final nextColor = baseColor.withValues(alpha: nv);
                          applyTextStyle(
                            live,
                            (live.textStyle ?? const TextStyle()).copyWith(
                              color: nextColor,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppSecondaryButton(
                        label: 'lbl_apply'.tr,
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

    void setTextSecondaryPanel(String panel) {
      context.read<AddNewBloc>().add(
        SetTextContextSecondaryPanelEvent(panel: panel),
      );
    }

    Map<String, dynamic> mergeTextMeta(
      TextLayer layer, {
      Map<String, dynamic>? set,
      List<String>? removeKeys,
    }) {
      final m = layer.meta == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(layer.meta!);
      removeKeys?.forEach(m.remove);
      if (set != null) {
        for (final e in set.entries) {
          final k = e.key;
          final v = e.value;
          if (v == null) {
            m.remove(k);
          } else {
            m[k] = v;
          }
        }
      }
      return m;
    }

    double currentStrokeWidth(TextLayer layer) {
      final raw = layer.meta?[kMusamiTextOutlineWidthMetaKey];
      return raw is num ? raw.toDouble() : 0;
    }

    Color? currentStrokeColor(TextLayer layer) {
      final raw = layer.meta?[kMusamiTextOutlineColorMetaKey];
      return raw is int ? musamiColorFromArgb32(raw) : null;
    }

    void applyStrokeWidth(double width) {
      final l = selectedTextLayer();
      if (l == null) return;
      if (width <= 0) {
        final updated = l.copyWith(
          meta: mergeTextMeta(
            l,
            removeKeys: const [
              kMusamiTextOutlineWidthMetaKey,
              kMusamiTextOutlineColorMetaKey,
            ],
          ),
        );
        editor.applyTextLayerChanges(l, updated);
        editor.setState(() {});
        return;
      }
      final c = currentStrokeColor(l) ?? const Color(0xFF000000);
      final updated = l.copyWith(
        meta: mergeTextMeta(
          l,
          set: {
            kMusamiTextOutlineWidthMetaKey: width,
            kMusamiTextOutlineColorMetaKey: musamiColorToArgb32(c),
          },
        ),
      );
      editor.applyTextLayerChanges(l, updated);
      editor.setState(() {});
    }

    void applyStrokeColor(Color color) {
      final l = selectedTextLayer();
      if (l == null) return;
      final w = currentStrokeWidth(l);
      final nextW = w <= 0 ? 1.5 : w;
      final updated = l.copyWith(
        meta: mergeTextMeta(
          l,
          set: {
            kMusamiTextOutlineWidthMetaKey: nextW,
            kMusamiTextOutlineColorMetaKey: musamiColorToArgb32(color),
          },
        ),
      );
      editor.applyTextLayerChanges(l, updated);
      editor.setState(() {});
    }

    bool _isBold(TextStyle? s) {
      final w = s?.fontWeight;
      return w == FontWeight.w600 ||
          w == FontWeight.w700 ||
          w == FontWeight.bold;
    }

    bool _isItalic(TextStyle? s) => s?.fontStyle == FontStyle.italic;

    bool _isUnderline(TextStyle? s) {
      final d = s?.decoration;
      if (d == null || d == TextDecoration.none) return false;
      if (d == TextDecoration.underline) return true;
      // Handle combined decorations.
      if (d ==
          TextDecoration.combine(const [
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ])) {
        return true;
      }
      return false;
    }

    void setRegular() {
      final l = selectedTextLayer();
      if (l == null) return;
      final s = (l.textStyle ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
        decoration: TextDecoration.none,
      );
      applyTextStyle(l, s);
      editor.setState(() {});
    }

    void toggleBold() {
      final l = selectedTextLayer();
      if (l == null) return;
      final s0 = l.textStyle ?? const TextStyle();
      final next = _isBold(s0) ? FontWeight.w400 : FontWeight.w700;
      applyTextStyle(l, s0.copyWith(fontWeight: next));
      editor.setState(() {});
    }

    void toggleItalic() {
      final l = selectedTextLayer();
      if (l == null) return;
      final s0 = l.textStyle ?? const TextStyle();
      final next = _isItalic(s0) ? FontStyle.normal : FontStyle.italic;
      applyTextStyle(l, s0.copyWith(fontStyle: next));
      editor.setState(() {});
    }

    void toggleUnderline() {
      final l = selectedTextLayer();
      if (l == null) return;
      final s0 = l.textStyle ?? const TextStyle();
      final next = _isUnderline(s0)
          ? TextDecoration.none
          : TextDecoration.underline;
      applyTextStyle(l, s0.copyWith(decoration: next));
      editor.setState(() {});
    }

    void pickTextColor() {
      musamiShowColorPickerGrid(
        context,
        title: 'lbl_pick_text_color'.tr,
        palette: kMusamiTextColorPalette,
        onPick: (c) {
          final l = selectedTextLayer();
          if (l == null) return;
          applyTextStyle(
            l,
            (l.textStyle ?? const TextStyle()).copyWith(color: c),
          );
          editor.setState(() {});
        },
      );
    }

    void pickTextBackgroundColor() {
      final palette = <Color>[
        Colors.transparent,
        ...kMusamiTextBackgroundPalette,
      ];
      musamiShowColorPickerGrid(
        context,
        title: 'lbl_pick_text_background'.tr,
        palette: palette,
        onPick: (c) {
          final l = selectedTextLayer();
          if (l == null) return;
          final bg = c.a <= 0.01 ? null : c;
          applyTextStyle(
            l,
            (l.textStyle ?? const TextStyle()).copyWith(backgroundColor: bg),
          );
          editor.setState(() {});
        },
      );
    }

    void pickOutlineColor() {
      musamiShowColorPickerGrid(
        context,
        title: 'Outline color',
        palette: kMusamiTextColorPalette,
        onPick: (c) {
          applyStrokeColor(c);
          if (state.textContextSecondaryPanel != 'stroke') {
            setTextSecondaryPanel('stroke');
          }
        },
      );
    }

    return TextContextToolbar(
      theme: Theme.of(context),
      secondaryPanel: state.textContextSecondaryPanel,
      onCloseSecondaryPanel: () => setTextSecondaryPanel('default'),
      currentOutlineWidth: () {
        final l = selectedTextLayer();
        if (l == null) return 0.0;
        return currentStrokeWidth(l);
      }(),
      isBold: () {
        final l = selectedTextLayer();
        return _isBold(l?.textStyle);
      }(),
      isItalic: () {
        final l = selectedTextLayer();
        return _isItalic(l?.textStyle);
      }(),
      isUnderline: () {
        final l = selectedTextLayer();
        return _isUnderline(l?.textStyle);
      }(),
      onSetRegular: setRegular,
      onToggleBold: toggleBold,
      onToggleItalic: toggleItalic,
      onToggleUnderline: toggleUnderline,
      onPickTextColor: pickTextColor,
      onPickTextBackgroundColor: pickTextBackgroundColor,
      onSetOutlineWidth: (w) {
        applyStrokeWidth(w);
      },
      onPickOutlineColor: pickOutlineColor,
      onDeselect: () {
        editor.layerInteractionManager.clearSelectedLayers();
        context.read<AddNewBloc>().add(EditorClearSelectionEvent());
      },
      onDelete: () {
        final id = state.selectedElementId;
        if (id == null) return;
        final Layer? layer = editor.activeLayers.cast<Layer?>().firstWhere(
          (l) => l?.id == id,
          orElse: () => null,
        );
        if (layer == null) return;
        editor.removeLayer(layer);
        context.read<AddNewBloc>().add(EditorClearSelectionEvent());
      },
      onDuplicate: () {
        final layer = selectedTextLayer();
        if (layer == null) return;
        final copy = TextLayer(
          text: layer.text,
          customSecondaryColor: layer.customSecondaryColor,
          hit: layer.hit,
          textStyle: layer.textStyle,
          colorMode: layer.colorMode,
          color: layer.color,
          background: layer.background,
          align: layer.align,
          fontScale: layer.fontScale,
          maxTextWidth: layer.maxTextWidth,
          offset: layer.offset + const Offset(12, 12),
          rotation: layer.rotation,
          scale: layer.scale,
          flipX: layer.flipX,
          flipY: layer.flipY,
          interaction: layer.interaction,
          meta: layer.meta == null
              ? null
              : Map<String, dynamic>.from(layer.meta!),
          boxConstraints: layer.boxConstraints,
        );
        editor.addLayer(copy);
      },
      onEdit: () {
        final layer = selectedTextLayer();
        if (layer == null) return;
        editor.editTextLayer(layer);
      },
      onSize: openSizeSheet,
      onOpacity: openOpacitySheet,
      onStroke: () {
        setTextSecondaryPanel(
          state.textContextSecondaryPanel == 'stroke' ? 'default' : 'stroke',
        );
      },
      onFonts: () {
        final layer = selectedTextLayer();
        if (layer == null) return;
        _showGoogleFontsPicker(
          context: context,
          editor: editor,
          layer: layer,
          copyTextLayer: _copyTextLayer,
        );
      },
      onColor: () {
        final layer = selectedTextLayer();
        if (layer == null) return;
        musamiShowColorPickerGrid(
          context,
          title: 'lbl_pick_text_color'.tr,
          palette: kMusamiTextColorPalette,
          onPick: (c) {
            final live = selectedTextLayer();
            if (live == null) return;
            applyTextStyle(
              live,
              (live.textStyle ?? const TextStyle()).copyWith(color: c),
            );
          },
        );
      },
    );
  }

  Widget _buildImageContextBottomBar(BuildContext context, AddNewState state) {
    final editor = state.editorKey?.currentState;
    if (editor == null) return const SizedBox.shrink();

    WidgetLayer? selectedWidgetLayer() {
      final id = state.selectedElementId;
      if (id == null) return null;
      return editor.activeLayers
          .whereType<WidgetLayer>()
          .cast<WidgetLayer?>()
          .firstWhere((l) => l?.id == id, orElse: () => null);
    }

    void deselect() {
      editor.layerInteractionManager.clearSelectedLayers();
      context.read<AddNewBloc>().add(EditorClearSelectionEvent());
    }

    void delete() {
      final id = state.selectedElementId;
      if (id == null) return;
      final Layer? layer = editor.activeLayers.cast<Layer?>().firstWhere(
        (l) => l?.id == id,
        orElse: () => null,
      );
      if (layer == null) return;
      editor.removeLayer(layer);
      context.read<AddNewBloc>().add(EditorClearSelectionEvent());
    }

    void duplicate() {
      final layer = selectedWidgetLayer();
      if (layer == null) return;
      final copy = WidgetLayer(
        widget: layer.widget,
        width: layer.width,
        offset: layer.offset + const Offset(12, 12),
        rotation: layer.rotation,
        scale: layer.scale,
        flipX: layer.flipX,
        flipY: layer.flipY,
        interaction: layer.interaction,
        meta: layer.meta == null
            ? null
            : Map<String, dynamic>.from(layer.meta!),
        boxConstraints: layer.boxConstraints,
        groupId: layer.groupId,
        startTime: layer.startTime,
        endTime: layer.endTime,
        enterDuration: layer.enterDuration,
        exitDuration: layer.exitDuration,
        enterCurve: layer.enterCurve,
        exitCurve: layer.exitCurve,
        transitionBuilder: layer.transitionBuilder,
      );
      editor.addLayer(copy);
    }

    Future<void> replace() async {
      final layer = selectedWidgetLayer();
      if (layer == null) return;

      Future<void> applyPicked(WidgetLayer picked) async {
        if (!context.mounted) return;
        _applyReplacingWidgetLayer(
          editor: editor,
          existing: layer,
          picked: picked,
        );
      }

      final kind = _musamiImageLayerKind(layer);

      switch (kind) {
        case 'sticker':
          final picked = await _showStickerPickerForReplace(context, editor);
          if (picked != null) await applyPicked(picked);
          break;
        case 'png':
          final picked = await _showApiAssetPickSheet(
            context,
            state.editorKey,
            MediaType.png,
          );
          if (picked != null) await applyPicked(picked);
          break;
        case 'logo':
          final picked = await _showApiAssetPickSheet(
            context,
            state.editorKey,
            MediaType.logo,
          );
          if (picked != null) await applyPicked(picked);
          break;
        case 'shape':
          final picked = await _showApiAssetPickSheet(
            context,
            state.editorKey,
            MediaType.shape,
          );
          if (picked != null) await applyPicked(picked);
          break;
        case 'gallery':
        default:
          final picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
          );
          if (image == null || !context.mounted) return;
          final bytes = await image.readAsBytes();
          if (!context.mounted) return;
          final imageProvider = MemoryImage(bytes);
          await precacheImage(imageProvider, context);
          if (!context.mounted) return;
          final decodedSize = await _decodeImageSize(bytes);
          if (!context.mounted) return;
          await applyPicked(
            WidgetLayer(
              widget: _buildGalleryStickerWidget(
                context,
                image: imageProvider,
                width: decodedSize.width,
                height: decodedSize.height,
              ),
              meta: <String, dynamic>{'musamiLayerKind': 'gallery'},
            ),
          );
          break;
      }
    }

    void showOpacitySheet() {
      final layer = selectedWidgetLayer();
      if (layer == null) return;
      final initial =
          (layer.meta?['musamiOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ??
          1.0;

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(context);
          double v = initial;
          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Opacity',
                              style: AppDs.sheetTitle(t, color: Colors.white),
                            ),
                          ),
                          Text(
                            '${(v * 100).round()}%',
                            style: AppDs.sheetTitle(t, color: Colors.white),
                          ),
                        ],
                      ),
                      Slider(
                        value: v,
                        min: 0,
                        max: 1,
                        divisions: 100,
                        onChanged: (nv) {
                          setState(() => v = nv);
                          final current = selectedWidgetLayer();
                          if (current == null) return;

                          final meta = current.meta == null
                              ? <String, dynamic>{}
                              : Map<String, dynamic>.from(current.meta!);
                          meta['musamiOpacity'] = nv;

                          final updated = musamiRebuildWidgetLayerVisuals(
                            current,
                            meta,
                            tuneAdjustmentItems: musamiTuneItemsFromEditor(
                              editor,
                            ),
                          );
                          final idx = editor.activeLayers.indexWhere(
                            (l) => l.id == current.id,
                          );
                          if (idx >= 0) {
                            editor.replaceLayer(index: idx, layer: updated);
                            editor.layerInteractionManager.selectedLayerId =
                                updated.id;
                            editor.setState(() {});
                          }
                        },
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppSecondaryButton(
                        label: 'lbl_apply'.tr,
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

    void showBorderSheet() {
      final layer = selectedWidgetLayer();
      if (layer == null) return;
      final meta0 = layer.meta == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(layer.meta!);
      final initialW = (meta0['musamiBorderW'] as num?)?.toDouble() ?? 0;
      final initialArgb = (meta0['musamiBorderArgb'] as int?) ?? 0xFF212121;

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final sheetTheme = Theme.of(ctx);
          double bw = initialW;
          Color bc = musamiColorFromArgb32(initialArgb);
          const presets = <Color>[
            Color(0xFF212121),
            Color(0xFFFFFFFF),
            Color(0xFFE53935),
            Color(0xFF1E88E5),
            Color(0xFF43A047),
            Color(0xFFFFB300),
          ];
          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: StatefulBuilder(
                builder: (ctx2, setState) {
                  void applyToEditor() {
                    final current = selectedWidgetLayer();
                    if (current == null) return;
                    final meta = current.meta == null
                        ? <String, dynamic>{}
                        : Map<String, dynamic>.from(current.meta!);
                    if (bw <= 0.05) {
                      meta.remove('musamiBorderW');
                      meta.remove('musamiBorderArgb');
                    } else {
                      meta['musamiBorderW'] = bw;
                      meta['musamiBorderArgb'] = musamiColorToArgb32(bc);
                    }
                    final updated = musamiRebuildWidgetLayerVisuals(
                      current,
                      meta,
                      tuneAdjustmentItems: musamiTuneItemsFromEditor(editor),
                    );
                    final idx = editor.activeLayers.indexWhere(
                      (l) => l.id == current.id,
                    );
                    if (idx >= 0) {
                      editor.replaceLayer(index: idx, layer: updated);
                      editor.layerInteractionManager.selectedLayerId =
                          updated.id;
                      editor.setState(() {});
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Border',
                        style: AppDs.sheetTitle(
                          sheetTheme,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: bw.clamp(0, 12),
                        min: 0,
                        max: 12,
                        divisions: 48,
                        label: bw <= 0.05
                            ? 'Off'
                            : '${bw.toStringAsFixed(1)} px',
                        onChanged: (nv) {
                          setState(() => bw = nv);
                          applyToEditor();
                        },
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final c in presets)
                            InkWell(
                              onTap: () {
                                setState(() => bc = c);
                                applyToEditor();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: bc == c
                                        ? sheetTheme.colorScheme.primary
                                        : Colors.white24,
                                    width: bc == c ? 3 : 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppSecondaryButton(
                        label: 'lbl_apply'.tr,
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

    void showShadowSheet() {
      final layer = selectedWidgetLayer();
      if (layer == null) return;
      final m = layer.meta == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(layer.meta!);
      final blur0 = (m['musamiShadowBlur'] as num?)?.toDouble() ?? 0;
      final dy0 = (m['musamiShadowDy'] as num?)?.toDouble() ?? 8;
      final st0 = (m['musamiShadowStrength'] as num?)?.toDouble() ?? 0.35;

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final sheetTheme = Theme.of(ctx);
          double blur = blur0;
          double dy = dy0;
          double strength = st0.clamp(0.0, 1.0);
          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: StatefulBuilder(
                builder: (ctx2, setState) {
                  void applyToEditor() {
                    final current = selectedWidgetLayer();
                    if (current == null) return;
                    final meta = current.meta == null
                        ? <String, dynamic>{}
                        : Map<String, dynamic>.from(current.meta!);
                    if (blur <= 0.5) {
                      meta.remove('musamiShadowBlur');
                      meta.remove('musamiShadowDy');
                      meta.remove('musamiShadowStrength');
                    } else {
                      meta['musamiShadowBlur'] = blur;
                      meta['musamiShadowDy'] = dy;
                      meta['musamiShadowStrength'] = strength;
                    }
                    final updated = musamiRebuildWidgetLayerVisuals(
                      current,
                      meta,
                      tuneAdjustmentItems: musamiTuneItemsFromEditor(editor),
                    );
                    final idx = editor.activeLayers.indexWhere(
                      (l) => l.id == current.id,
                    );
                    if (idx >= 0) {
                      editor.replaceLayer(index: idx, layer: updated);
                      editor.layerInteractionManager.selectedLayerId =
                          updated.id;
                      editor.setState(() {});
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shadow',
                        style: AppDs.sheetTitle(
                          sheetTheme,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Blur',
                        style: sheetTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Slider(
                        value: blur.clamp(0, 48),
                        min: 0,
                        max: 48,
                        divisions: 48,
                        onChanged: (nv) {
                          setState(() => blur = nv);
                          applyToEditor();
                        },
                      ),
                      Text(
                        'Offset Y',
                        style: sheetTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Slider(
                        value: dy.clamp(0, 24),
                        min: 0,
                        max: 24,
                        divisions: 48,
                        onChanged: (nv) {
                          setState(() => dy = nv);
                          applyToEditor();
                        },
                      ),
                      Text(
                        'Strength',
                        style: sheetTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Slider(
                        value: strength,
                        min: 0.05,
                        max: 1,
                        divisions: 19,
                        onChanged: (nv) {
                          setState(() => strength = nv);
                          applyToEditor();
                        },
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppSecondaryButton(
                        label: 'lbl_apply'.tr,
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

    void showResizeSheet() {
      final layer = selectedWidgetLayer();
      if (layer == null) return;

      const minLayerScale = 0.05;
      const maxLayerScale = 8.0;
      final initial = layer.scale.clamp(minLayerScale, maxLayerScale);

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(context);
          double v = initial;
          return AppDarkSheetTheme(
            child: AppSheetPagePadding(
              child: StatefulBuilder(
                builder: (ctx2, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Resize image',
                              style: AppDs.sheetTitle(t, color: Colors.white),
                            ),
                          ),
                          Text(
                            '${(v * 100).round()}%',
                            style: AppDs.sheetTitle(t, color: Colors.white),
                          ),
                        ],
                      ),
                      Slider(
                        value: v.clamp(minLayerScale, maxLayerScale),
                        min: minLayerScale,
                        max: maxLayerScale,
                        divisions: 160,
                        label: '${(v * 100).round()}%',
                        onChanged: (nv) {
                          setState(() => v = nv);
                          final current = selectedWidgetLayer();
                          if (current == null) return;
                          final meta = current.meta == null
                              ? <String, dynamic>{}
                              : Map<String, dynamic>.from(current.meta!);
                          final updated = musamiRebuildWidgetLayerVisuals(
                            current.copyWith(scale: nv),
                            meta,
                            tuneAdjustmentItems: musamiTuneItemsFromEditor(
                              editor,
                            ),
                          );
                          final idx = editor.activeLayers.indexWhere(
                            (l) => l.id == current.id,
                          );
                          if (idx >= 0) {
                            editor.replaceLayer(index: idx, layer: updated);
                            editor.layerInteractionManager.selectedLayerId =
                                updated.id;
                            editor.setState(() {});
                          }
                        },
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppSecondaryButton(
                        label: 'lbl_apply'.tr,
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

    return ImageContextToolbar(
      theme: Theme.of(context),
      secondaryPanel: state.imageContextSecondaryPanel,
      onDeselect: deselect,
      onDelete: delete,
      onResize: showResizeSheet,
      onBorder: showBorderSheet,
      onShadow: showShadowSheet,
      onDuplicate: duplicate,
      onOpacity: showOpacitySheet,
      onReplace: () => replace(),
      onAiRemoveBg: () {
        NavigatorService.pushNamed(AppRoutes.enhancedRemoveBackgroundScreen);
      },
      onColor: editor.openFilterEditor,
      onAdjust: () {
        final next = state.imageContextSecondaryPanel == 'adjust'
            ? 'default'
            : 'adjust';
        context.read<AddNewBloc>().add(
          SetImageContextSecondaryPanelEvent(panel: next),
        );
      },
      adjustPanel: state.selectedElementId != null
          ? MusamiImageAdjustContextPanel(
              key: ValueKey<String>(state.selectedElementId!),
              editor: editor,
              layerId: state.selectedElementId!,
              theme: Theme.of(context),
              onClose: () {
                context.read<AddNewBloc>().add(
                  SetImageContextSecondaryPanelEvent(panel: 'default'),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }

  ProImageEditorConfigs _musamiProImageEditorConfigs(BuildContext context) {
    final theme = Theme.of(context);
    final lang = appLocaleNotifier.languageCode;
    final initialRtl = lang == 'ar' || lang == 'ur';

    return ProImageEditorConfigs(
      i18n: I18n(
        doneLoadingMsg: 'msg_saving_your_design'.tr,
        textEditor: I18nTextEditor(
          inputHintText: 'lbl_text_editor_hint_ltr'.tr,
        ),
      ),
      mainEditor: MainEditorConfigs(
        enableCloseButton: false,
        // Required so [doneEditing] calls [onImageEditingComplete] with captured bytes.
        captureImageOnDone: true,
        // Hide ProImageEditor built-in bottom toolbar (paint/crop/tune/filter/blur/etc.)
        // because we render our own "Add New Design" tool grid.
        tools: const [],
        widgets: MainEditorWidgets(
          appBar: (editor, rebuildStream) {
            final topPad = MediaQuery.paddingOf(context).top;
            return ReactiveAppbar(
              stream: rebuildStream,
              appbarSize: Size.fromHeight(topPad + 3 + 56),
              builder: (ctx) => _buildSimplifiedEditorAppBar(ctx, editor),
            );
          },
        ),
      ),
      layerInteraction: LayerInteractionConfigs(
        // On mobile, default "auto" makes layers NOT selectable, which causes
        // single-tap to edit text layers. Force selectable so single-tap selects.
        selectable: LayerInteractionSelectable.enabled,
        widgets: LayerInteractionWidgets(
          // Disable the built-in edit button so single-tap won't open edit.
          // Editing is triggered by double-tap on the layer.
          editButton: (rebuildStream, onTap, rotation) => ReactiveWidget(
            stream: rebuildStream,
            builder: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
      stickerEditor: StickerEditorConfigs(builder: _buildStickerSelector),
      textEditor: TextEditorConfigs(
        initialInputTextDirection: initialRtl
            ? TextDirection.rtl
            : TextDirection.ltr,
        initialTextAlign: initialRtl ? TextAlign.right : TextAlign.left,
        arabicScriptInputHint: 'lbl_text_editor_hint_rtl'.tr,
        // Default new text: no background (transparent).
        initialBackgroundColorMode: LayerBackgroundMode.onlyColor,
        enableTapOutsideToSave: false,
        showTextAlignButton: false,
        showFontScaleButton: false,
        showBackgroundModeButton: false,
        inputTextFieldAlign: Alignment.topCenter,
        style: TextEditorStyle(
          background: appTheme.blueGray90004,
          appBarBackground: appTheme.blueGray90004,
          appBarColor: theme.colorScheme.onPrimary,
          inputHintColor: theme.colorScheme.onPrimary.withValues(alpha: 0.55),
          inputTextFieldBackground: appTheme.gray90002,
          inputTextFieldBorderColor: theme.colorScheme.onPrimary.withValues(
            alpha: 0.12,
          ),
          // inputTextFieldBorderRadius: BorderRadius.all(
          //   Radius.circular(16.adaptSize),
          // ),
          // inputTextFieldPadding: EdgeInsets.symmetric(
          //   horizontal: 140.h,
          //   vertical: 150.v,
          // ),
          textFieldMargin: EdgeInsets.only(
            // left: 14.h,
            // right: 14.h,
            top: 12.v,
            // // Smaller bottom margin -> taller visible input area.
            // bottom: 200.v,
          ),
        ),
        widgets: TextEditorWidgets(
          appBar: (editor, stream) => musamiTextEditorAppBar(
            editor: editor,
            rebuildStream: stream,
            theme: theme,
          ),
          colorPicker: (editor, stream, color, onUpdate) => ReactiveWidget(
            stream: stream,
            builder: (_) => const SizedBox.shrink(),
          ),
          bottomBar: (editor, stream) => musamiTextEditorBottomBar(
            editor: editor,
            rebuildStream: stream,
            theme: theme,
          ),
          bodyItemsOverlay: (editor, stream) => musamiTextEditorBodyOverlay(
            editor: editor,
            rebuildStream: stream,
            theme: theme,
          ),
        ),
      ),
      paintEditor: PaintEditorConfigs(
        showLineWidthAdjustmentButton: true,
        widgets: PaintEditorWidgets(
          bottomBar: (editor, stream) =>
              musamiPaintEditorBottomBar(editor, stream),
        ),
      ),
    );
  }

  Widget _editorTopBarLabeledAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    final active = enabled && onPressed != null;
    final c = active ? const Color(0xFF424242) : const Color(0xFFBDBDBD);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onPressed : null,
        child: SizedBox(
          width: 52.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22.adaptSize, color: c),
              SizedBox(height: 2.v),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.fSize,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopBarBlendOpacity(
    BuildContext context,
    ProImageEditorState editor,
    String? selectedId,
  ) {
    if (selectedId == null || selectedId.trim().isEmpty) {
      showAppToast('msg_editor_select_for_blend'.tr);
      return;
    }
    Layer? hit;
    for (final l in editor.activeLayers) {
      if (l.id == selectedId) {
        hit = l;
        break;
      }
    }
    if (hit is TextLayer) {
      _showTopBarTextOpacitySheet(context, editor, hit);
    } else if (hit is WidgetLayer) {
      _showTopBarWidgetOpacitySheet(context, editor, hit);
    } else {
      showAppToast('msg_editor_blend_unsupported'.tr);
    }
  }

  void _showTopBarTextOpacitySheet(
    BuildContext context,
    ProImageEditorState editor,
    TextLayer layer,
  ) {
    final baseColor = (layer.textStyle?.color) ?? layer.color;
    var v = baseColor.a.clamp(0.0, 1.0);

    showAppModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(context);
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            child: StatefulBuilder(
              builder: (ctx, setSheet) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'lbl_editor_blend'.tr,
                            style: AppDs.sheetTitle(t, color: Colors.white),
                          ),
                        ),
                        Text(
                          '${(v * 100).round()}%',
                          style: AppDs.sheetTitle(t, color: Colors.white),
                        ),
                      ],
                    ),
                    Slider(
                      value: v,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      onChanged: (nv) {
                        setSheet(() => v = nv);
                        final idx = editor.activeLayers.indexWhere(
                          (l) => l.id == layer.id,
                        );
                        if (idx < 0) return;
                        final live = editor.activeLayers[idx] as TextLayer;
                        final rgb = baseColor.withValues(alpha: 1.0);
                        final nextColor = rgb.withValues(alpha: nv);
                        final next = live.copyWith(
                          textStyle: (live.textStyle ?? const TextStyle())
                              .copyWith(color: nextColor),
                          color: nextColor,
                        );
                        editor.applyTextLayerChanges(live, next);
                        editor.setState(() {});
                      },
                    ),
                    SizedBox(height: AppDs.space2.v),
                    AppSecondaryButton(
                      label: 'lbl_apply'.tr,
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

  void _showTopBarWidgetOpacitySheet(
    BuildContext context,
    ProImageEditorState editor,
    WidgetLayer layer,
  ) {
    final initial =
        (layer.meta?['musamiOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ??
        1.0;
    var v = initial;

    showAppModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(context);
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            child: StatefulBuilder(
              builder: (ctx, setSheet) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'lbl_editor_blend'.tr,
                            style: AppDs.sheetTitle(t, color: Colors.white),
                          ),
                        ),
                        Text(
                          '${(v * 100).round()}%',
                          style: AppDs.sheetTitle(t, color: Colors.white),
                        ),
                      ],
                    ),
                    Slider(
                      value: v,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      onChanged: (nv) {
                        setSheet(() => v = nv);
                        final idx = editor.activeLayers.indexWhere(
                          (l) => l.id == layer.id,
                        );
                        if (idx < 0) return;
                        final current = editor.activeLayers[idx] as WidgetLayer;
                        final meta = current.meta == null
                            ? <String, dynamic>{}
                            : Map<String, dynamic>.from(current.meta!);
                        meta['musamiOpacity'] = nv;
                        final updated = musamiRebuildWidgetLayerVisuals(
                          current,
                          meta,
                          tuneAdjustmentItems: musamiTuneItemsFromEditor(
                            editor,
                          ),
                        );
                        editor.replaceLayer(index: idx, layer: updated);
                        editor.layerInteractionManager.selectedLayerId =
                            updated.id;
                        editor.setState(() {});
                      },
                    ),
                    SizedBox(height: AppDs.space2.v),
                    AppSecondaryButton(
                      label: 'lbl_apply'.tr,
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

  /// Reference-style top bar: light strip, icon+label row, red Save block.
  PreferredSizeWidget _buildSimplifiedEditorAppBar(
    BuildContext context,
    ProImageEditorState editor,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final canUndo = editor.canUndo;
    final canRedo = editor.canRedo;
    final selectedId = context.select(
      (AddNewBloc b) => b.state.selectedElementId,
    );

    Layer? selectedLayer() {
      final id = selectedId;
      if (id == null || id.trim().isEmpty) return null;
      for (final l in editor.activeLayers) {
        if (l.id == id) return l;
      }
      return null;
    }

    void onMoveTap() {
      final layer = selectedLayer();
      if (layer == null) {
        showAppToast('msg_editor_select_to_move'.tr);
        return;
      }
      if (_editorLayerTransformLocked(layer)) {
        _editorToggleLayerTransformLock(editor, layer);
      }
      showAppToast('msg_editor_drag_to_move'.tr);
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final sel = selectedLayer();

    return PreferredSize(
      preferredSize: Size.fromHeight(topInset + 3 + 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset),
          ColoredBox(
            color: primary,
            child: SizedBox(height: 3.v),
          ),
          SizedBox(
            height: 56,
            child: ColoredBox(
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'msg_home_open_menu'.tr,
                    padding: EdgeInsets.symmetric(horizontal: AppDs.space1.h),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF424242),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: AppDs.space1.h),
                      child: Row(
                        children: [
                          _editorTopBarLabeledAction(
                            icon: Icons.layers_outlined,
                            label: 'lbl_layers'.tr,
                            onPressed: () =>
                                _showEditorLayersSheet(context, editor),
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.blur_on_rounded,
                            label: 'lbl_editor_blend'.tr,
                            onPressed: () => _showTopBarBlendOpacity(
                              context,
                              editor,
                              selectedId,
                            ),
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.filter_center_focus,
                            label: 'lbl_editor_align'.tr,
                            onPressed: sel != null
                                ? () => showEditorAlignArrangeSheet(
                                    context: context,
                                    editor: editor,
                                    layer: sel,
                                  )
                                : null,
                            enabled: sel != null,
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.open_with_rounded,
                            label: 'lbl_editor_move'.tr,
                            onPressed: onMoveTap,
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.undo_rounded,
                            label: 'lbl_undo'.tr,
                            onPressed: canUndo ? editor.undoAction : null,
                            enabled: canUndo,
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.redo_rounded,
                            label: 'lbl_redo'.tr,
                            onPressed: canRedo ? editor.redoAction : null,
                            enabled: canRedo,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    color: primary,
                    child: InkWell(
                      onTap: editor.doneEditing,
                      child: SizedBox(
                        width: 64.h,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 22.adaptSize,
                            ),
                            SizedBox(height: 2.v),
                            Text(
                              'lbl_save'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.fSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _editorLayerLabel(Layer layer) {
    if (layer is TextLayer) return 'lbl_layer_type_text'.tr;
    if (layer is EmojiLayer) return 'lbl_layer_type_emoji'.tr;
    if (layer is PaintLayer) return 'lbl_layer_type_paint'.tr;
    if (layer is WidgetLayer) return 'lbl_layer_type_sticker'.tr;
    return 'lbl_layer_type_other'.tr;
  }

  bool _editorLayerHidden(Layer layer) {
    return layer.meta?[kMusamiLayerHiddenMetaKey] == true;
  }

  bool _editorLayerTransformLocked(Layer layer) {
    return !layer.interaction.enableMove &&
        !layer.interaction.enableScale &&
        !layer.interaction.enableRotate;
  }

  /// [activeLayers] order is back → front; the sheet lists front → back.
  void _editorReorderLayersFromDisplay(
    ProImageEditorState editor,
    int oldDisplayIndex,
    int newDisplayIndex,
  ) {
    final display = List<Layer>.from(editor.activeLayers.reversed);
    if (newDisplayIndex > oldDisplayIndex) {
      newDisplayIndex -= 1;
    }
    final item = display.removeAt(oldDisplayIndex);
    display.insert(newDisplayIndex, item);
    editor.addHistory(layers: display.reversed.toList());
  }

  void _editorToggleLayerTransformLock(
    ProImageEditorState editor,
    Layer layer,
  ) {
    final locked = !_editorLayerTransformLocked(layer);
    final list = List<Layer>.from(editor.activeLayers);
    final ti = list.indexWhere((l) => l.id == layer.id);
    if (ti < 0) return;
    final target = list[ti];
    target.interaction = target.interaction.copyWith(
      enableMove: !locked,
      enableScale: !locked,
      enableRotate: !locked,
    );
    editor.addHistory(layers: list);
  }

  void _editorToggleLayerHidden(ProImageEditorState editor, Layer layer) {
    final hidden = !_editorLayerHidden(layer);
    final list = List<Layer>.from(editor.activeLayers);
    final ti = list.indexWhere((l) => l.id == layer.id);
    if (ti < 0) return;
    final target = list[ti];
    target.meta = {...?target.meta, kMusamiLayerHiddenMetaKey: hidden};
    editor.addHistory(layers: list);
  }

  void _editorToggleLockAllTransforms(ProImageEditorState editor) {
    final allLocked =
        editor.activeLayers.isNotEmpty &&
        editor.activeLayers.every(_editorLayerTransformLocked);
    final enable = allLocked;
    final list = List<Layer>.from(editor.activeLayers);
    for (final layer in list) {
      layer.interaction = layer.interaction.copyWith(
        enableMove: enable,
        enableScale: enable,
        enableRotate: enable,
      );
    }
    editor.addHistory(layers: list);
  }

  void _editorToggleHideAllLayers(ProImageEditorState editor) {
    final anyVisible = editor.activeLayers.any((l) => !_editorLayerHidden(l));
    final hide = anyVisible;
    final list = List<Layer>.from(editor.activeLayers);
    for (final layer in list) {
      layer.meta = {...?layer.meta, kMusamiLayerHiddenMetaKey: hide};
    }
    editor.addHistory(layers: list);
  }

  void _editorToggleSelectAllLayers(ProImageEditorState editor) {
    final ids = editor.activeLayers.map((l) => l.id).toSet();
    final mgr = editor.layerInteractionManager;
    if (mgr.selectedLayerIds.length == ids.length && ids.isNotEmpty) {
      mgr.clearSelectedLayers();
    } else {
      mgr.setSelectedLayers(ids);
    }
    editor.setState(() {});
  }

  Widget _editorLayerThumbnail(Layer layer) {
    const size = 48.0;
    final box = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.dividerColor),
    );
    if (layer is TextLayer) {
      final t = layer.text.toString();
      final short = t.length > 48 ? '${t.substring(0, 48)}…' : t;
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: box,
        alignment: Alignment.center,
        child: Text(
          short.isEmpty ? '—' : short,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall,
        ),
      );
    }
    if (layer is EmojiLayer) {
      return Container(
        width: size,
        height: size,
        decoration: box,
        alignment: Alignment.center,
        child: Text(layer.emoji, style: const TextStyle(fontSize: 26)),
      );
    }
    if (layer is PaintLayer) {
      return Container(
        width: size,
        height: size,
        decoration: box,
        alignment: Alignment.center,
        child: Icon(Icons.brush_outlined, color: theme.colorScheme.primary),
      );
    }
    if (layer is WidgetLayer) {
      return Container(
        width: size,
        height: size,
        decoration: box,
        alignment: Alignment.center,
        child: Icon(Icons.widgets_outlined, color: theme.colorScheme.primary),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: box,
      alignment: Alignment.center,
      child: Icon(Icons.layers_outlined, color: theme.colorScheme.primary),
    );
  }

  void _showEditorLayersSheet(
    BuildContext context,
    ProImageEditorState editor,
  ) {
    final primary = theme.colorScheme.primary;

    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AppDarkSheetTheme(
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final ordered = editor.activeLayers;
                final layers = List<Layer>.from(ordered.reversed);
                final maxH = MediaQuery.sizeOf(context).height * 0.58;
                final allTransformsLocked =
                    ordered.isNotEmpty &&
                    ordered.every(_editorLayerTransformLocked);
                final anyLayerVisible = ordered.any(
                  (l) => !_editorLayerHidden(l),
                );
                final allSelected =
                    ordered.isNotEmpty &&
                    editor.layerInteractionManager.selectedLayerIds.length ==
                        ordered.length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppDs.space4.h,
                        AppDs.space3.v,
                        AppDs.space2.h,
                        AppDs.space3.v,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            color: primary,
                            size: 26.adaptSize,
                          ),
                          SizedBox(width: AppDs.space3.h),
                          Expanded(
                            child: Text(
                              'lbl_layers'.tr,
                              style: AppDs.sheetTitle(
                                theme,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonLabel,
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    if (layers.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppDs.space3.h,
                          AppDs.space3.v,
                          AppDs.space3.h,
                          AppDs.space2.v,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              tooltip: 'lbl_layer_filters'.tr,
                              icon: Icon(Icons.filter_list, color: primary),
                              onPressed: () {
                                Navigator.pop(ctx);
                                editor.openFilterEditor();
                              },
                            ),
                            IconButton(
                              tooltip: allTransformsLocked
                                  ? 'lbl_layer_unlock_all'.tr
                                  : 'lbl_layer_lock_all'.tr,
                              icon: Icon(
                                allTransformsLocked
                                    ? Icons.lock
                                    : Icons.lock_open,
                                color: primary,
                              ),
                              onPressed: () {
                                _editorToggleLockAllTransforms(editor);
                                setModalState(() {});
                              },
                            ),
                            IconButton(
                              tooltip: anyLayerVisible
                                  ? 'lbl_layer_hide_all'.tr
                                  : 'lbl_layer_show_all'.tr,
                              icon: Icon(
                                anyLayerVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: primary,
                              ),
                              onPressed: () {
                                _editorToggleHideAllLayers(editor);
                                setModalState(() {});
                              },
                            ),
                            IconButton(
                              tooltip: allSelected
                                  ? 'lbl_layer_deselect_all'.tr
                                  : 'lbl_layer_select_all'.tr,
                              icon: Icon(
                                allSelected
                                    ? Icons.check_box_outlined
                                    : Icons.check_box_outline_blank_outlined,
                                color: primary,
                              ),
                              onPressed: () {
                                _editorToggleSelectAllLayers(editor);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    if (layers.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppDs.space4.h,
                          0,
                          AppDs.space4.h,
                          AppDs.space2.v,
                        ),
                        child: Text(
                          'msg_layer_order_hint'.tr,
                          style: AppDs.sheetCaption(
                            theme,
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                        ),
                      ),
                    if (layers.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDs.space5.h,
                          vertical: AppDs.space4.v,
                        ),
                        child: Text(
                          'msg_editor_no_layers'.tr,
                          textAlign: TextAlign.center,
                          style: AppDs.sheetBody(
                            theme,
                            color: Colors.white,
                            a: 0.72,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: maxH,
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: layers.length,
                          onReorder: (oldIndex, newIndex) {
                            _editorReorderLayersFromDisplay(
                              editor,
                              oldIndex,
                              newIndex,
                            );
                            setModalState(() {});
                          },
                          itemBuilder: (context, i) {
                            final layer = layers[i];
                            final n = layers.length - i;
                            final transformLocked = _editorLayerTransformLocked(
                              layer,
                            );
                            final hidden = _editorLayerHidden(layer);
                            final selected = editor
                                .layerInteractionManager
                                .selectedLayerIds
                                .contains(layer.id);

                            return Material(
                              key: ValueKey<String>(layer.id),
                              color: AppDs.sheetListFill(0.06),
                              borderRadius: BorderRadius.circular(
                                AppDs.radiusMd.h,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  editor
                                          .layerInteractionManager
                                          .selectedLayerId =
                                      layer.id;
                                  editor.setState(() {});
                                  Navigator.pop(ctx);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppDs.space2.h,
                                    vertical: AppDs.space2.v,
                                  ),
                                  child: Row(
                                    children: [
                                      ReorderableDragStartListener(
                                        index: i,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: AppDs.space2.h,
                                          ),
                                          child: Icon(
                                            Icons.swap_vert,
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _editorLayerThumbnail(layer),
                                      SizedBox(width: 10.h),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '#$n ${_editorLayerLabel(layer)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            if (layers.length == 1)
                                              Text(
                                                'lbl_layer_frontmost'.tr,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.62,
                                                          ),
                                                    ),
                                              )
                                            else if (i == 0)
                                              Text(
                                                'lbl_layer_frontmost'.tr,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.62,
                                                          ),
                                                    ),
                                              )
                                            else if (i == layers.length - 1)
                                              Text(
                                                'lbl_layer_backmost'.tr,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.62,
                                                          ),
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: transformLocked
                                            ? 'lbl_layer_unlock'.tr
                                            : 'lbl_layer_lock'.tr,
                                        icon: Icon(
                                          transformLocked
                                              ? Icons.lock_outline
                                              : Icons.lock_open_outlined,
                                          color: primary,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          _editorToggleLayerTransformLock(
                                            editor,
                                            layer,
                                          );
                                          setModalState(() {});
                                        },
                                      ),
                                      IconButton(
                                        tooltip: hidden
                                            ? 'lbl_layer_show'.tr
                                            : 'lbl_layer_hide'.tr,
                                        icon: Icon(
                                          hidden
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: primary,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          _editorToggleLayerHidden(
                                            editor,
                                            layer,
                                          );
                                          setModalState(() {});
                                        },
                                      ),
                                      Checkbox(
                                        value: selected,
                                        onChanged: (_) {
                                          final mgr =
                                              editor.layerInteractionManager;
                                          if (selected) {
                                            mgr.removeSelectedLayer(layer.id);
                                          } else {
                                            mgr.addSelectedLayer(layer.id);
                                          }
                                          editor.setState(() {});
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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

  /// Export finished → save dialog (name, format, size, quality, visibility) → upload → success.
  Future<void> _runPostExportSavePipeline({
    required BuildContext context,
    required Uint8List imageBytes,
    required int width,
    required int height,
  }) async {
    if (!context.mounted) return;
    if (imageBytes.isEmpty) {
      showAppToast('msg_export_failed'.tr, type: ToastificationType.error);
      return;
    }
    final suggestedName = widget.presetName.trim().isNotEmpty
        ? widget.presetName.trim()
        : null;
    final form = await showDesignSaveFormDialog(
      context,
      initialWidth: width,
      initialHeight: height,
      suggestedName: suggestedName,
      showVisibility: true,
    );
    if (!context.mounted || form == null) return;

    final encoded = await encodeDesignForUpload(
      imageBytes,
      width: form.width,
      height: form.height,
      type: form.fileType,
      jpgQuality: form.quality,
    );
    if (!context.mounted) return;
    if (encoded == null) {
      showAppToast('msg_export_failed'.tr, type: ToastificationType.error);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 28.adaptSize,
                height: 28.adaptSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 20.h),
              Expanded(
                child: Text(
                  'msg_uploading_design'.tr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    SaveDesignResult result;
    try {
      result = await DesignRepository().saveDesign(
        imageBytes: encoded,
        width: form.width,
        height: form.height,
        title: form.title,
        visibility: form.visibility,
        filename: form.fileType.uploadFilename,
      );
    } catch (e, _) {
      result = SaveDesignFailure(e.toString());
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    if (!context.mounted) return;

    switch (result) {
      case SaveDesignSuccess():
        if (form.fileType != DesignExportFileType.pdf) {
          await saveExportedDesignToGallery(
            context,
            bytes: encoded,
            exportFileType: form.fileType,
            quietSuccess: true,
          );
        }
        if (!context.mounted) return;
        await showDesignSaveSuccessDialog(context);
      case SaveDesignFailure(:final message):
        showAppToast(message, type: ToastificationType.error);
    }
  }

  Widget _buildColumnSelectSize(BuildContext context, AddNewState state) {
    final screenSize = MediaQuery.sizeOf(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: _ResizeOverlayContent(
        state: state,
        maxWidth: screenSize.width,
        maxHeight: screenSize.height,
        editorWidth: state.selectedwidth ?? widget.width,
        editorHeight: state.selectedheight ?? widget.height,
      ),
    );
  }

  static final _swatchColors = <Color?>[
    null,
    Colors.black,
    Colors.white,
    Colors.grey.shade300,
    Colors.grey.shade600,
    const Color(0xFF6B2D2D),
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  Widget _buildBgColorOverlay(BuildContext context, AddNewState state) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: 45.v, left: 16.h, right: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.v),
        decoration: AppDecoration.fillYellow.copyWith(
          borderRadius: BorderRadius.circular(20.adaptSize),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBgColorOverlayHeader(context, state),
            SizedBox(height: 12.v),
            _buildBgColorOverlayContent(context, state),
            SizedBox(height: 12.v),
            _buildBgColorToolRow(context, state),
            SizedBox(height: 12.v),
            _buildBgColorSwatchesRow(context, state),
            SizedBox(height: 8.v),
          ],
        ),
      ),
    );
  }

  Widget _buildBgColorOverlayHeader(BuildContext context, AddNewState state) {
    final isWheel = state.bgColorToolMode == 'wheel';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isWheel)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28.adaptSize,
                height: 28.adaptSize,
                decoration: BoxDecoration(
                  color: state.selectedBgColor ?? Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                'Hex',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.black87,
                  fontSize: 14.0,
                ),
              ),
              Icon(
                Icons.unfold_more,
                size: 16.adaptSize,
                color: Colors.black87,
              ),
            ],
          )
        else
          const SizedBox(width: 24),
        Expanded(child: const SizedBox()),
        GestureDetector(
          onTap: () {
            BlocProvider.of<AddNewBloc>(
              context,
            ).add(ShowContainerEvent(ishow: '0'));
          },
          child: Icon(Icons.close, size: 24.adaptSize, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBgColorOverlayContent(BuildContext context, AddNewState state) {
    switch (state.bgColorToolMode) {
      case 'wheel':
        return _WheelColorPickerContent(state: state);
      case 'swatch':
        return _SwatchPaletteContent(state: state);
      case 'transparency':
        return _TransparencySliderContent(state: state);
      case 'recent':
        return _RecentColorsGridContent(state: state);
      case 'picker':
      default:
        return _WheelColorPickerContent(state: state);
    }
  }

  Widget _buildBgColorToolRow(BuildContext context, AddNewState state) {
    const tools = [
      ('picker', Icons.colorize, 'Picker'),
      ('wheel', Icons.palette_outlined, 'Wheel'),
      ('swatch', Icons.square_rounded, 'Swatch'),
      ('transparency', Icons.water_drop_outlined, 'Transparency'),
      ('recent', Icons.history, 'Recent'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tools.map((t) {
        final isActive = state.bgColorToolMode == t.$1;
        return GestureDetector(
          onTap: () {
            BlocProvider.of<AddNewBloc>(
              context,
            ).add(SetBgColorToolModeEvent(mode: t.$1));
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.v),
            decoration: BoxDecoration(
              color: isActive ? Colors.black87 : Colors.transparent,
              borderRadius: BorderRadius.circular(10.adaptSize),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t.$2,
                  size: 22.adaptSize,
                  color: isActive ? appTheme.yellow500 : Colors.black87,
                ),
                SizedBox(height: 4.v),
                Text(
                  t.$3,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? appTheme.yellow500 : Colors.black87,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBgColorSwatchesRow(BuildContext context, AddNewState state) {
    return SizedBox(
      height: 40.v,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _swatchColors.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.h),
        itemBuilder: (context, index) {
          final c = _swatchColors[index];
          final isSelected = state.selectedBgColor == c;
          return GestureDetector(
            onTap: () {
              if (c == null) {
                BlocProvider.of<AddNewBloc>(
                  context,
                ).add(MakeTransparentEvent());
                BlocProvider.of<AddNewBloc>(
                  context,
                ).add(ShowContainerEvent(ishow: '0'));
                return;
              }
              BlocProvider.of<AddNewBloc>(
                context,
              ).add(SetBgColorEvent(color: c));
            },
            child: Container(
              width: 36.adaptSize,
              height: 36.adaptSize,
              decoration: BoxDecoration(
                color: c == null ? Colors.transparent : c,
                borderRadius: BorderRadius.circular(8.adaptSize),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.black26,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: c == null
                  ? CustomPaint(
                      painter: _CheckerboardPainter(),
                      size: Size.infinite,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildColumnBookmark(BuildContext context, AddNewState state) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: 46.v),
        padding: EdgeInsets.symmetric(horizontal: 26.h, vertical: 20.v),
        decoration: AppDecoration.fillYellow.copyWith(
          borderRadius: BorderRadiusStyle.roundedBorder33,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 25.v),
            Padding(
              padding: EdgeInsets.only(right: 1.h),
              child: BlocSelector<AddNewBloc, AddNewState, AddNewModel?>(
                selector: (state) => state.screen3AddNewModelObj,
                builder: (context, screen3AddNewModelObj) {
                  return GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisExtent: 93.v,
                      crossAxisCount: 3,
                      mainAxisSpacing: 15.h,
                      crossAxisSpacing: 15.h,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        screen3AddNewModelObj?.gridgalleryPicItemList.length ??
                        0,
                    itemBuilder: (context, index) {
                      GridgalleryPicItemModel model =
                          screen3AddNewModelObj
                              ?.gridgalleryPicItemList[index] ??
                          GridgalleryPicItemModel();
                      return GridgalleryPicItemWidget(
                        model,
                        onTapColumngallery: () async {
                          final editor = state.editorKey?.currentState;
                          if (editor == null) return;

                          // Close the popup for all actions.
                          BlocProvider.of<AddNewBloc>(
                            context,
                          ).add(ShowContainerEvent(ishow: '0'));

                          if (model.gallerypic == 'Add Text') {
                            // Text editor
                            editor.openTextEditor();
                          } else if (model.gallerypic == 'Shapes') {
                            // Shapes: show bottom sheet with shapes from API
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.75,
                                child: ShapesBottomSheet(
                                  editorKey: state.editorKey,
                                ),
                              ),
                            );
                          } else if (model.gallerypic == 'PNG Images') {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.75,
                                child: ApiAssetBottomSheet(
                                  editorKey: state.editorKey,
                                  type: MediaType.png,
                                ),
                              ),
                            );
                          } else if (model.gallerypic == 'Logos') {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.75,
                                child: ApiAssetBottomSheet(
                                  editorKey: state.editorKey,
                                  type: MediaType.logo,
                                ),
                              ),
                            );
                          } else if (model.gallerypic == 'Paint') {
                            editor.openPaintEditor();
                          } else if (model.gallerypic == 'Crop& Rotate') {
                            editor.openCropRotateEditor();
                          } else if (model.gallerypic == 'Tune') {
                            editor.openTuneEditor();
                          } else if (model.gallerypic == 'Filter') {
                            editor.openFilterEditor();
                          } else if (model.gallerypic == 'Blur') {
                            editor.openBlurEditor();
                          } else {
                            // Gallery: pick from device and add as editor layer
                            final key = state.editorKey;
                            if (key != null) {
                              await _pickFromGalleryAndAddAsLayer(context, key);
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGalleryAndAddAsLayer(
    BuildContext context,
    GlobalKey<ProImageEditorState> editorKey,
  ) async {
    // The incoming `context` can be from a bottom sheet / grid item and may be
    // disposed after returning from the native picker. Use the State's context
    // as the stable one as long as `mounted` is true.
    final stableContext = this.context;
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image == null || !mounted) return;

      late final Uint8List bytes;
      try {
        bytes = await image.readAsBytes();
      } catch (e) {
        rethrow;
      }
      if (!mounted) return;
      final decodedSize = await _decodeImageSize(bytes);

      // ProImageEditor captures layers via screenshots; undecoded images can
      // layout with zero size. Precache matches the package sticker examples.
      final imageProvider = MemoryImage(bytes);
      await precacheImage(imageProvider, stableContext);
      if (!mounted) return;

      Future<void> addDecodedLayer() async {
        final editor = editorKey.currentState;
        if (editor == null) return;
        final body = editor.sizesManager.bodySize;
        final canvasSize = body.isEmpty || body == Size.infinite
            ? MediaQuery.sizeOf(stableContext)
            : body;
        final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
        final layerW = decodedSize.width;
        final layerH = decodedSize.height;
        editor.addLayer(
          WidgetLayer(
            width: layerW,
            // Allow user to zoom/resize the sticker (don't lock max size).
            boxConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            offset: center - Offset(layerW / 2, layerH / 2),
            interaction: LayerInteraction(enableEdit: false),
            widget: _buildGalleryStickerWidget(
              stableContext,
              image: imageProvider,
              width: layerW,
              height: layerH,
            ),
            meta: <String, dynamic>{
              'musamiLayerKind': 'gallery',
              if (layerW > 0) 'musamiAspect': layerH / layerW,
            },
          ),
        );
        editor.layerInteractionManager.selectedLayerId =
            editor.activeLayers.last.id;
        editor.setState(() {});
      }

      // Ensure the editor tree has applied the precached image before addLayer.
      // We use endOfFrame because the incoming widget context may be disposed
      // and post-frame callbacks tied to that phase can be skipped in some flows.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        await addDecodedLayer();
      }
    } catch (e) {
      if (mounted) {
        showAppToast(
          'Could not open gallery: $e',
          type: ToastificationType.error,
        );
      }
    }
  }

  /// Builds the sticker selector widget for the sticker editor
  Widget _buildStickerSelector(
    void Function(WidgetLayer widget) setLayer,
    ScrollController scrollController,
  ) {
    return _FullScreenStickerSelector(
      setLayer: setLayer,
      scrollController: scrollController,
    );
  }
}

/// Full-screen sticker selector widget matching the design
class _FullScreenStickerSelector extends StatefulWidget {
  final void Function(WidgetLayer widget) setLayer;
  final ScrollController scrollController;

  const _FullScreenStickerSelector({
    required this.setLayer,
    required this.scrollController,
  });

  @override
  State<_FullScreenStickerSelector> createState() =>
      _FullScreenStickerSelectorState();
}

class _FullScreenStickerSelectorState
    extends State<_FullScreenStickerSelector> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Basic', 'Blob', 'Badges', 'Borders', 'I'];
  final List<Map<String, dynamic>> _stickerSections = [
    {
      'title': 'Basic',
      'items': List.generate(4, (i) => {'type': 'basic', 'index': i}),
    },
    {
      'title': 'Blob',
      'items': List.generate(5, (i) => {'type': 'blob', 'index': i}),
    },
    {
      'title': 'Badges',
      'items': List.generate(4, (i) => {'type': 'badge', 'index': i}),
    },
    {
      'title': 'Animals Stickers',
      'items': List.generate(4, (i) => {'type': 'animal', 'index': i}),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Top header with back button and search
            _buildHeader(),
            // Category tabs
            _buildCategoryTabs(),
            // Content sections
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._stickerSections.map(
                      (section) => _buildStickerSection(
                        title: section['title'] as String,
                        items: section['items'] as List<Map<String, dynamic>>,
                        setLayer: widget.setLayer,
                      ),
                    ),
                    SizedBox(height: 20.v),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
      child: Column(
        children: [
          // Back + Gallery button
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Gallery',
                onPressed: () async {
                  try {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                      maxHeight: 1920,
                    );
                    if (image == null || !mounted) return;
                    final bytes = await image.readAsBytes();
                    if (!mounted) return;
                    final provider = MemoryImage(bytes);
                    await precacheImage(provider, context);
                    if (!mounted) return;

                    widget.setLayer(
                      WidgetLayer(
                        // Allow zoom/resize like a sticker.
                        width: _AddNewScreenState._kStickerLayerSize,
                        boxConstraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        interaction: LayerInteraction(enableEdit: false),
                        meta: const <String, dynamic>{
                          'musamiLayerKind': 'gallery',
                        },
                        widget: SizedBox(
                          width: _AddNewScreenState._kStickerLayerSize,
                          height: _AddNewScreenState._kStickerLayerSize,
                          child: Image(
                            image: provider,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    );
                  } catch (_) {
                    // ignore
                  }
                },
                icon: Icon(
                  Icons.photo_library_outlined,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 12.v),
          // Search bar
          Container(
            height: 48.v,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.h,
                  vertical: 12.v,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50.v,
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == 0 && isSelected)
                    Icon(Icons.home, color: Colors.white, size: 20)
                  else if (index == 0)
                    Icon(Icons.home_outlined, color: Colors.white, size: 20),
                  if (index == 0) SizedBox(width: 6.h),
                  Text(
                    _categories[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required void Function(WidgetLayer widget) setLayer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.v),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'See all',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120.v,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  setLayer(
                    WidgetLayer(
                      meta: const <String, dynamic>{
                        'musamiLayerKind': 'sticker',
                      },
                      widget: _buildStickerWidget(
                        item['type'] as String,
                        item['index'] as int,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 100.h,
                  height: 100.v,
                  margin: EdgeInsets.only(right: 12.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  child: _buildStickerPreview(
                    item['type'] as String,
                    item['index'] as int,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16.v),
      ],
    );
  }

  Widget _buildStickerPreview(String type, int index) {
    switch (type) {
      case 'basic':
        return _buildBasicShape(index);
      case 'blob':
        return _buildBlobShape(index);
      case 'badge':
        return _buildBadge(index);
      case 'animal':
        return _buildAnimalSticker(index);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStickerWidget(String type, int index) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: _buildStickerPreview(type, index),
    );
  }

  Widget _buildBasicShape(int index) {
    switch (index % 3) {
      case 0:
        return Container(
          margin: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8.h),
          ),
        );
      case 1:
        return Container(
          margin: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      case 2:
        return Container(
          margin: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(50.h),
          ),
        );
      default:
        return Container(
          margin: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
        );
    }
  }

  Widget _buildBlobShape(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: EdgeInsets.all(15.h),
          child: CustomPaint(
            size: Size(
              constraints.maxWidth - 30.h,
              constraints.maxHeight - 30.v,
            ),
            painter: _BlobPainter(),
          ),
        );
      },
    );
  }

  Widget _buildBadge(int index) {
    final colors = [
      [Colors.red, Colors.white, Colors.yellow],
      [Colors.yellow, Colors.white, Colors.red],
      [Colors.lime, Colors.white],
      [Colors.red, Colors.white],
    ];
    final badgeColors = colors[index % colors.length];

    return Container(
      margin: EdgeInsets.all(10.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60.h,
            height: 60.v,
            decoration: BoxDecoration(
              color: badgeColors[0],
              shape: BoxShape.circle,
              border: Border.all(color: badgeColors[1], width: 2),
            ),
            child: Icon(
              Icons.star,
              color: badgeColors.length > 2 ? badgeColors[2] : badgeColors[1],
              size: 24,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 40.h,
              height: 8.v,
              decoration: BoxDecoration(
                color: badgeColors[0],
                borderRadius: BorderRadius.circular(4.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalSticker(int index) {
    final animals = [
      {'icon': Icons.favorite, 'color': Colors.pink},
      {'icon': Icons.pets, 'color': Colors.orange},
      {'icon': Icons.eco, 'color': Colors.brown},
      {'icon': Icons.forest, 'color': Colors.grey},
    ];
    final animal = animals[index % animals.length];

    return Container(
      margin: EdgeInsets.all(15.h),
      decoration: BoxDecoration(
        color: (animal['color'] as Color).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Icon(
        animal['icon'] as IconData,
        color: animal['color'] as Color,
        size: 40,
      ),
    );
  }
}

// --- BG Color overlay content widgets (Wheel, Swatch, Transparency, Recent) ---

/// Wheel mode: saturation/value gradient, hue slider, transparency slider, hex + opacity (ref 1).
class _WheelColorPickerContent extends StatefulWidget {
  const _WheelColorPickerContent({required this.state});
  final AddNewState state;

  @override
  State<_WheelColorPickerContent> createState() =>
      _WheelColorPickerContentState();
}

class _WheelColorPickerContentState extends State<_WheelColorPickerContent> {
  late double _hue;
  late double _saturation;
  late double _value;
  late double _alpha;

  @override
  void initState() {
    super.initState();
    _initFromColor(widget.state.selectedBgColor ?? Colors.red);
  }

  @override
  void didUpdateWidget(covariant _WheelColorPickerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedBgColor != widget.state.selectedBgColor) {
      _initFromColor(widget.state.selectedBgColor ?? Colors.red);
    }
  }

  void _initFromColor(Color c) {
    final hsv = HSVColor.fromColor(c);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _alpha = c.opacity;
  }

  void _applyColor() {
    final c = HSVColor.fromAHSV(_alpha, _hue, _saturation, _value).toColor();
    BlocProvider.of<AddNewBloc>(context).add(SetBgColorEvent(color: c));
  }

  static String _toHex(Color c) {
    return '#${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = HSVColor.fromAHSV(
      _alpha,
      _hue,
      _saturation,
      _value,
    ).toColor();
    final hex = _toHex(color);
    final opacityPercent = (_alpha * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 140.v,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (d) {
                  final x = d.localPosition.dx.clamp(0.0, constraints.maxWidth);
                  final y = d.localPosition.dy.clamp(
                    0.0,
                    constraints.maxHeight,
                  );
                  setState(() {
                    _saturation = (x / constraints.maxWidth).clamp(0.0, 1.0);
                    _value = 1.0 - (y / constraints.maxHeight).clamp(0.0, 1.0);
                  });
                  _applyColor();
                },
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            HSVColor.fromAHSV(1, _hue, 1, 1).toColor(),
                          ],
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (_saturation * constraints.maxWidth - 12).clamp(
                        0.0,
                        constraints.maxWidth - 24,
                      ),
                      top: ((1 - _value) * constraints.maxHeight - 12).clamp(
                        0.0,
                        constraints.maxHeight - 24,
                      ),
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.v),
        SliderTheme(
          data: SliderThemeData(
            trackShape: const RoundedRectSliderTrackShape(),
            overlayShape: const RoundSliderOverlayShape(),
            activeTrackColor: appTheme.blueGray90004,
            inactiveTrackColor: Colors.black26,
            thumbColor: appTheme.blueGray90004,
          ),
          child: Slider(
            value: _hue.clamp(0.0, 360.0),
            min: 0,
            max: 360,
            onChanged: (v) {
              setState(() => _hue = v);
              _applyColor();
            },
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackShape: const RoundedRectSliderTrackShape(),
            overlayShape: const RoundSliderOverlayShape(),
            activeTrackColor: appTheme.blueGray90004,
            inactiveTrackColor: Colors.black26,
            thumbColor: appTheme.blueGray90004,
          ),
          child: Slider(
            value: _alpha,
            min: 0,
            max: 1,
            onChanged: (v) {
              setState(() => _alpha = v);
              _applyColor();
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8.adaptSize),
              ),
              child: Text(
                hex,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8.adaptSize),
              ),
              child: Text(
                '$opacityPercent',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Swatch mode: 8 vertical palette strips (2x4), each 5 shades (ref 2).
class _SwatchPaletteContent extends StatelessWidget {
  const _SwatchPaletteContent({required this.state});
  final AddNewState state;

  static const List<List<Color>> _palettes = [
    [
      Color(0xFF8B4513),
      Color(0xFFCD853F),
      Color(0xFFDEB887),
      Color(0xFFF5DEB3),
      Color(0xFFFFF8DC),
    ],
    [
      Color(0xFF8B008B),
      Color(0xFFDA70D6),
      Color(0xFFEE82EE),
      Color(0xFFF0B0F0),
      Color(0xFFFFE4F0),
    ],
    [
      Color(0xFF4B0082),
      Color(0xFF6A5ACD),
      Color(0xFF9370DB),
      Color(0xFFDDA0DD),
      Color(0xFFE6E6FA),
    ],
    [
      Color(0xFF00008B),
      Color(0xFF4169E1),
      Color(0xFF6495ED),
      Color(0xFF87CEEB),
      Color(0xFFB0E0E6),
    ],
    [
      Color(0xFF008080),
      Color(0xFF20B2AA),
      Color(0xFF40E0D0),
      Color(0xFF7FFFD4),
      Color(0xFFE0FFFF),
    ],
    [
      Color(0xFF006400),
      Color(0xFF228B22),
      Color(0xFF32CD32),
      Color(0xFF90EE90),
      Color(0xFFF0FFF0),
    ],
    [
      Color(0xFF800080),
      Color(0xFFBA55D3),
      Color(0xFFDDA0DD),
      Color(0xFFFFB6C1),
      Color(0xFFFFC0CB),
    ],
    [
      Color(0xFF2F4F4F),
      Color(0xFF708090),
      Color(0xFFA9A9A9),
      Color(0xFFD3D3D3),
      Color(0xFFF5F5F5),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.h,
      runSpacing: 10.v,
      children: List.generate(8, (i) {
        final palette = _palettes[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: palette.map((c) {
            return GestureDetector(
              onTap: () {
                BlocProvider.of<AddNewBloc>(
                  context,
                ).add(SetBgColorEvent(color: c));
              },
              child: Container(
                width: 36.h,
                height: 28.v,
                margin: EdgeInsets.only(bottom: 2.v),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(4.adaptSize),
                  border: Border.all(color: Colors.black26),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}

/// Transparency mode: opacity slider at top + value display (ref 3).
class _TransparencySliderContent extends StatefulWidget {
  const _TransparencySliderContent({required this.state});
  final AddNewState state;

  @override
  State<_TransparencySliderContent> createState() =>
      _TransparencySliderContentState();
}

class _TransparencySliderContentState
    extends State<_TransparencySliderContent> {
  late double _opacity;

  @override
  void initState() {
    super.initState();
    _opacity = widget.state.selectedBgColor?.opacity ?? 1.0;
  }

  @override
  void didUpdateWidget(covariant _TransparencySliderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedBgColor != widget.state.selectedBgColor) {
      _opacity = widget.state.selectedBgColor?.opacity ?? 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackShape: const RoundedRectSliderTrackShape(),
                  overlayShape: const RoundSliderOverlayShape(),
                  activeTrackColor: appTheme.blueGray90004,
                  inactiveTrackColor: Colors.black26,
                  thumbColor: appTheme.blueGray90004,
                ),
                child: Slider(
                  value: _opacity,
                  min: 0,
                  max: 1,
                  onChanged: (v) {
                    setState(() => _opacity = v);
                    BlocProvider.of<AddNewBloc>(context).add(
                      SetBgColorEvent(
                        color: (widget.state.selectedBgColor ?? Colors.grey)
                            .withOpacity(v),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: 48.h,
              padding: EdgeInsets.symmetric(vertical: 6.v),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8.adaptSize),
              ),
              alignment: Alignment.center,
              child: Text(
                '${(_opacity * 100).round()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Recent mode: grid of color swatches (ref 4).
class _RecentColorsGridContent extends StatelessWidget {
  const _RecentColorsGridContent({required this.state});
  final AddNewState state;

  static const List<Color> _gridColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.brown,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.h,
      runSpacing: 8.v,
      children: _gridColors.map((c) {
        return GestureDetector(
          onTap: () {
            BlocProvider.of<AddNewBloc>(context).add(SetBgColorEvent(color: c));
          },
          child: Container(
            width: 32.adaptSize,
            height: 32.adaptSize,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(6.adaptSize),
              border: Border.all(color: Colors.black26),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Resize overlay with custom size fields (limited to screen) and sliders that update on drag end.
class _ResizeOverlayContent extends StatefulWidget {
  const _ResizeOverlayContent({
    required this.state,
    required this.maxWidth,
    required this.maxHeight,
    required this.editorWidth,
    required this.editorHeight,
  });

  final AddNewState state;
  final double maxWidth;
  final double maxHeight;
  final double editorWidth;
  final double editorHeight;

  @override
  State<_ResizeOverlayContent> createState() => _ResizeOverlayContentState();
}

class _ResizeOverlayContentState extends State<_ResizeOverlayContent> {
  late double _localHeight;
  late double _localWidth;

  @override
  void initState() {
    super.initState();
    _localHeight = widget.editorHeight;
    _localWidth = widget.editorWidth;
  }

  @override
  void didUpdateWidget(covariant _ResizeOverlayContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedheight != widget.state.selectedheight ||
        oldWidget.state.selectedwidth != widget.state.selectedwidth) {
      _localHeight = widget.state.selectedheight ?? widget.editorHeight;
      _localWidth = widget.state.selectedwidth ?? widget.editorWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final maxW = widget.maxWidth;
    final maxH = widget.maxHeight;
    const minDim = 50.0;

    return Container(
      margin: EdgeInsets.only(bottom: 45.v),
      padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 20.v),
      decoration: AppDecoration.fillPrimary.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder33,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "lbl_select_size2".tr,
            style: CustomTextStyles.titleMediumPoppinsBluegray90004,
          ),
          SizedBox(height: 12.v),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Text(
                "lbl_custom_size".tr,
                style: CustomTextStyles.bodySmallBluegray90004,
              ),
            ),
          ),
          SizedBox(height: 10.v),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.valueoneController != null)
                CustomTextFormField(
                  width: 115.h,
                  controller: state.valueoneController!,
                  hintText: "lbl_200".tr,
                  textStyle: CustomTextStyles.bodySmallBluegray90004,
                  textInputAction: TextInputAction.done,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 30.h,
                    vertical: 14.v,
                  ),
                  borderDecoration: TextFormFieldStyleHelper.fillYellow,
                  fillColor: appTheme.yellow500,
                )
              else
                SizedBox(width: 115.h, height: 49.v),
              Padding(
                padding: EdgeInsets.only(top: 17.v, bottom: 14.v),
                child: Text(
                  "lbl_x".tr,
                  style: CustomTextStyles.bodySmallBluegray90004,
                ),
              ),
              if (state.valueTwoController != null)
                CustomTextFormField(
                  width: 115.h,
                  controller: state.valueTwoController!,
                  textStyle: CustomTextStyles.bodySmallBluegray90004,
                  hintText: "lbl_200".tr,
                  textInputAction: TextInputAction.done,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 30.h,
                    vertical: 14.v,
                  ),
                  borderDecoration: TextFormFieldStyleHelper.fillYellow,
                  fillColor: appTheme.yellow500,
                )
              else
                SizedBox(width: 115.h, height: 49.v),
              SizedBox(width: 8.h),
              CustomElevatedButton(
                height: 49.v,
                width: 80.h,
                text: "Apply",
                buttonStyle: CustomButtonStyles.fillYellow,
                buttonTextStyle: CustomTextStyles.bodySmallBluegray90004,
                onPressed: () {
                  final wText = state.valueoneController?.text ?? '';
                  final hText = state.valueTwoController?.text ?? '';
                  final parsedW = double.tryParse(wText);
                  final parsedH = double.tryParse(hText);
                  if (parsedW == null || parsedH == null) return;
                  final clampedW = parsedW.clamp(1.0, maxW);
                  final clampedH = parsedH.clamp(1.0, maxH);
                  final wasOver = parsedW > maxW || parsedH > maxH;
                  if (wasOver) {
                    showAppToast(
                      'Limit to screen size',
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                  BlocProvider.of<AddNewBloc>(context).add(
                    ApplyCustomSizeEvent(width: clampedW, height: clampedH),
                  );
                  setState(() {
                    _localWidth = clampedW;
                    _localHeight = clampedH;
                  });
                },
              ),
            ],
          ),
          if (state.valueTwoController != null)
            Padding(
              padding: EdgeInsets.only(top: 8.v),
              child: Text(
                'Max: ${maxW.toInt()} x ${maxH.toInt()}',
                style: CustomTextStyles.bodySmallBluegray90004.copyWith(
                  fontSize: 11.0,
                ),
              ),
            ),
          SizedBox(height: 14.v),
          Container(
            padding: EdgeInsets.all(15.h),
            decoration: AppDecoration.fillYellow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder10,
            ),
            child: Column(
              children: [
                const Text('Height', style: TextStyle(color: Colors.black)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgArrowDownGray900,
                      height: 18.adaptSize,
                      width: 18.adaptSize,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 12.h,
                          top: 3.v,
                          bottom: 3.v,
                        ),
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackShape: const RoundedRectSliderTrackShape(),
                            overlayShape: const RoundSliderOverlayShape(),
                            activeTrackColor: appTheme.blueGray90004,
                            inactiveTrackColor: appTheme.black900.withOpacity(
                              0.08,
                            ),
                            thumbColor: appTheme.blueGray90004,
                            thumbShape: const RoundSliderThumbShape(),
                          ),
                          child: Slider(
                            value: _localHeight.clamp(minDim, maxH),
                            min: minDim,
                            max: maxH,
                            onChanged: (value) {
                              setState(() => _localHeight = value);
                            },
                            onChangeEnd: (value) {
                              BlocProvider.of<AddNewBloc>(context).add(
                                SliderHeightValueChangedEvent(
                                  width: _localWidth,
                                  height: value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    CustomImageView(
                      imagePath: ImageConstant.imgArrowLeft,
                      height: 17.adaptSize,
                      width: 17.adaptSize,
                      margin: EdgeInsets.only(left: 11.h),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.v),
          Container(
            padding: EdgeInsets.all(15.h),
            decoration: AppDecoration.fillYellow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder10,
            ),
            child: Column(
              children: [
                const Text('Width', style: TextStyle(color: Colors.black)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgArrowDownGray900,
                      height: 18.adaptSize,
                      width: 18.adaptSize,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 12.h,
                          top: 3.v,
                          bottom: 3.v,
                        ),
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackShape: const RoundedRectSliderTrackShape(),
                            overlayShape: const RoundSliderOverlayShape(),
                            activeTrackColor: appTheme.blueGray90004,
                            inactiveTrackColor: appTheme.black900.withOpacity(
                              0.08,
                            ),
                            thumbColor: appTheme.blueGray90004,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: _localWidth.clamp(minDim, maxW),
                            min: minDim,
                            max: maxW,
                            onChanged: (value) {
                              setState(() => _localWidth = value);
                            },
                            onChangeEnd: (value) {
                              BlocProvider.of<AddNewBloc>(context).add(
                                SliderwidthtValueChangedEvent(
                                  width: value,
                                  height: _localHeight,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    CustomImageView(
                      imagePath: ImageConstant.imgArrowLeft,
                      height: 17.adaptSize,
                      width: 17.adaptSize,
                      margin: EdgeInsets.only(left: 11.h),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 68.v),
        ],
      ),
    );
  }
}

/// Custom painter for blob shapes
class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width * 0.7,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.5,
      size.width * 0.8,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.9,
      size.width * 0.2,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.5,
      size.width * 0.3,
      size.height * 0.2,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Checkerboard pattern for transparency swatch
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 6.0;
    final white = Paint()..color = Colors.white;
    final gray = Paint()..color = Colors.grey.shade400;
    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        final isLight = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isLight ? white : gray,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
