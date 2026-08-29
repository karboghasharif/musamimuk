import 'dart:async';
import 'dart:math' as math;
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
import '../../data/models/wallet_models.dart';
import '../../data/repositories/design_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/advertisement_banner.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_text_form_field.dart';
import '../wallet/bloc/wallet_bloc.dart';
import '../wallet/wallet_cost_guard.dart';
import '../wallet/widgets/coin_balance_chip.dart';
import 'bloc/add_new_bloc.dart';
import 'models/add_new_model.dart';
import 'models/gridgallery_pic_item_model.dart';
import 'widgets/add_new_bookmark_panel.dart';
import 'widgets/api_asset_bottom_sheet.dart';
import 'widgets/design_export_encode.dart';
import 'widgets/design_save_destination_sheet.dart';
import 'widgets/canvas_resize_size_panel.dart';
import 'widgets/design_save_form_dialog.dart';
import 'widgets/design_save_success_sheet.dart';
import 'widgets/musami_text_layer_transform_overlay.dart';
import 'widgets/musami_text_editor_widgets.dart';
import 'widgets/musami_text_layer_style_sheet.dart';
import 'widgets/editor_align_arrange_sheet.dart';
import 'widgets/screen_color_picker_overlay.dart';
import 'widgets/editor_contextual_toolbars.dart';
import 'widgets/editor_ai_command_bar.dart';
import 'widgets/draggable_editor_ai_fab.dart';
import 'utils/musami_clipping_mask.dart';
import 'utils/musami_layer_capture.dart';
import 'utils/musami_layer_clipboard.dart';
import 'utils/musami_page_background.dart';
import 'widgets/musami_layer_context_menu.dart';
import 'widgets/musami_layer_floating_quick_bar.dart';
import 'widgets/musami_layer_meta_sheets.dart';
import 'widgets/musami_page_palette_sheet.dart';
import '../../data/services/local_design_store.dart';
import '../../data/services/custom_font_library.dart';
import '../../data/services/user_font_library.dart';
import '../../data/models/custom_font_models.dart';
import 'widgets/musami_text_editor_arabic_fonts.dart';
import '../../core/config/editor_ai_config.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import '../../background_removal/background_removal_controller.dart';
import '../../background_removal/background_removal_loading_dialog.dart';
import '../../background_removal/background_removal_state.dart';
import '../../data/models/background_removal_api_models.dart';
import '../../data/services/editor_ai/editor_ai_asset_registry.dart';
import '../../core/utils/design_state_history.dart';
import 'utils/musami_layer_raster_utils.dart';
import 'package:pro_image_editor/features/crop_rotate_editor/utils/crop_aspect_ratios.dart';

/// Layer lock flag stored in [Layer.meta] (app-side; not provided by pub.dev
/// pro_image_editor).
const String kMusamiLayerLockedMetaKey = 'musamiLayerLocked';

/// Layer hide flag stored in [Layer.meta] (app-side; not provided by pub.dev
/// pro_image_editor).
const String kMusamiLayerHiddenMetaKey = 'musamiLayerHidden';

/// Raster/sticker tint on [WidgetLayer.meta], applied before tune/colour-matrix.
const String kMusamiImageTintArgbMetaKey = 'musamiImageTintArgb';

/// Ratio (height / width) of the layer FRAME — the selection box the user
/// drags. Free to become any ratio; resizing writes this key.
const String kMusamiFrameAspectMetaKey = 'musamiAspect';

/// Ratio (height / width) of the IMAGE inside the frame, taken from the source
/// pixels when the image is inserted, replaced or cropped.
///
/// Resizing the frame must never write this key: the content keeps its own
/// proportions and is cover-cropped to fill whatever frame the user drags.
const String kMusamiImageAspectMetaKey = 'musamiImageAspect';

/// Which part of the image stays visible when the frame crops it
/// (-1 = start, 0 = centre, 1 = end, on each axis).
const String kMusamiCropAlignXMetaKey = 'musamiCropAlignX';
const String kMusamiCropAlignYMetaKey = 'musamiCropAlignY';

/// Marks the frame box built by [musamiFrameWidgetLayerCore] so a later resize
/// re-frames the original content instead of nesting another shell.
const ValueKey<String> kMusamiLayerFrameBoxKey = ValueKey<String>(
  'musami.layerFrameBox',
);

/// Rounded corners for gallery chrome and user border/shadow (painted above pixels).
const double kMusamiImageLayerRoundedCorner = 16.0;

/// Editor app bar: accent strip + action row. Must match [preferredSize] exactly
/// (do not use `.v` here — it was overflowing the reserved height by ~0.2px).
const double kMusamiEditorAppBarAccentHeight = 3;
const double kMusamiEditorAppBarRowHeight = 56;

double musamiEditorAppBarHeight(double topInset) =>
    topInset + kMusamiEditorAppBarAccentHeight + kMusamiEditorAppBarRowHeight;

Future<Size> _musamiDecodeImageSize(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
}

/// Identifies composers so rebuild peels old shells correctly.
const ValueKey<String> kMusamiComposeBorderOverlayStackKey = ValueKey<String>(
  'musami.composeBorderOverlay',
);
const ValueKey<String> kMusamiComposeShadowDecoratorKey = ValueKey<String>(
  'musami.composeShadowDecor',
);
const ValueKey<String> kMusamiTuneFilterRepaintKey = ValueKey<String>(
  'musami.tuneFilterRepaint',
);
const ValueKey<String> kMusamiGalleryPickedChromeKey = ValueKey<String>(
  'musami.galleryPickedChrome',
);

/// Silhouette assets (shapes / icons) need [BlendMode.srcIn] recoloring;
/// photos and colorful stickers keep multiply ([BlendMode.modulate]).
bool musamiLayerUsesSilhouetteTint(Map<String, dynamic> meta) {
  final kind = meta['musamiLayerKind']?.toString();
  return kind == 'shape' || kind == 'ai-shape' || kind == 'ai-icon';
}

/// Whether a tint ARGB should drive a [ColorFiltered] on the layer.
///
/// For modulate/photo tints, opaque white is treated as a no-op (identity).
/// For silhouette [BlendMode.srcIn] tints, white is a valid recolor.
bool musamiLayerImageTintAppliesFilterArgb(
  int tintArgb, {
  bool allowWhite = false,
}) {
  if (((tintArgb >> 24) & 0xFF) == 0) return false;
  if (allowWhite) return true;
  return tintArgb != 0xFFFFFFFF;
}

/// Same tune definitions as the main editor (for layer [ColorFiltered] matrix).
List<TuneAdjustmentItem> musamiTuneItemsFromConfigs(ProImageEditorConfigs c) {
  final options = c.tuneEditor.tuneAdjustmentOptions;
  if (options != null && options.isNotEmpty) return options;
  return tunePresets(icons: c.tuneEditor.icons, i18n: c.i18n.tuneEditor);
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
    if (v == null || v.abs() < 1e-6) continue;
    final value = v.clamp(item.min, item.max);
    matrices.add(item.toMatrix(value));
  }
  if (matrices.isEmpty) {
    return List<double>.from(identityMatrix);
  }
  return mergeColorMatrices(filterList: const [], tuneAdjustmentList: matrices);
}

/// Opacity slider must always wrap the base child; stacking [Opacity] multiplies alphas.
///
/// The hit-area [Padding] added for tiny layers can sit either side of the
/// [Opacity], so both are peeled until neither is left on the outside.
Widget _unwrapOuterOpacityWidgets(Widget widget) {
  Widget w = widget;
  for (;;) {
    final before = w;
    w = _peelOuterOpacityAndPadding(w);
    if (identical(w, before)) return w;
  }
}

Widget _peelOuterOpacityAndPadding(Widget widget) {
  Widget w = widget;
  while (w is Opacity) {
    final next = (w as Opacity).child;
    if (next == null) break;
    w = next;
  }
  // Hit-area padding added for small layers — peel so compose can re-wrap.
  while (w is Padding) {
    final pad = w as Padding;
    final child = pad.child;
    if (child == null) break;
    // Only peel symmetric pads we add for min hit area (not decorative).
    final p = pad.padding.resolve(TextDirection.ltr);
    if (p.left == p.right && p.top == p.bottom && (p.left > 0 || p.top > 0)) {
      w = child;
      continue;
    }
    break;
  }
  return w;
}

/// Drops [musamiComposeImageLayerVisualCore] wrappers so rebuilds replace tint/tune
/// instead of nesting duplicate shells on stale subtrees.
///
/// Peels compose [DecoratedBox] / keyed [Stack] / [ColorFiltered], and legacy
/// gallery chrome ([kMusamiGalleryPickedChromeKey]).
Widget _unwrapMusamiWidgetLayerBareCore(Widget widget) {
  var w = _unwrapOuterOpacityWidgets(widget);

  bool legacyFlatComposeDecor(DecoratedBox box) {
    final deco = box.decoration;
    if (deco is! BoxDecoration) return false;
    final br = deco.borderRadius;
    if (br != null && br != BorderRadius.zero) return false;
    return deco.border != null ||
        (deco.boxShadow != null && deco.boxShadow!.isNotEmpty);
  }

  bool roundedComposeShadowOnly(DecoratedBox box) {
    if (box.key != kMusamiComposeShadowDecoratorKey) return false;
    final deco = box.decoration;
    return deco is BoxDecoration &&
        deco.border == null &&
        deco.boxShadow != null &&
        deco.boxShadow!.isNotEmpty &&
        deco.borderRadius ==
            BorderRadius.circular(kMusamiImageLayerRoundedCorner);
  }

  for (;;) {
    if (w is _MusamiImageDropShadow) {
      w = w.foreground;
      continue;
    }

    if (w is DecoratedBox) {
      final innerDec = w.child;
      if (innerDec != null) {
        // Strip legacy default gallery chrome from older layers.
        if (w.key == kMusamiGalleryPickedChromeKey) {
          w = innerDec;
          continue;
        }
        if (roundedComposeShadowOnly(w) || legacyFlatComposeDecor(w)) {
          w = innerDec;
          continue;
        }
      }
    }

    if (w is Stack && w.key == kMusamiComposeBorderOverlayStackKey) {
      final ch = w.children;
      if (ch.isEmpty) break;
      w = ch.first;
      continue;
    }

    final clippedCore = musamiTryUnwrapClipMaskedContent(w);
    if (clippedCore != null) {
      w = clippedCore;
      continue;
    }

    if (w is RepaintBoundary &&
        w.key == kMusamiTuneFilterRepaintKey &&
        w.child != null) {
      w = w.child!;
      continue;
    }

    if (w is ColorFiltered && w.child != null) {
      w = w.child!;
      continue;
    }

    break;
  }
  return w;
}

/// Alpha-aware drop shadow that follows non-transparent pixels (PNG cut-outs).
class _MusamiImageDropShadow extends StatelessWidget {
  const _MusamiImageDropShadow({
    super.key,
    required this.foreground,
    required this.shadowSource,
    required this.blur,
    required this.dx,
    required this.dy,
    required this.strength,
  });

  final Widget foreground;
  final Widget shadowSource;
  final double blur;
  final double dx;
  final double dy;
  final double strength;

  @override
  Widget build(BuildContext context) {
    final sigma = (blur / 2).clamp(0.0, 40.0);
    final shadowColor = Colors.black.withValues(
      alpha: strength.clamp(0.0, 1.0),
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Transform.translate(
          offset: Offset(dx, dy),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(shadowColor, BlendMode.srcIn),
              child: shadowSource,
            ),
          ),
        ),
        foreground,
      ],
    );
  }
}

Widget _musamiApplyImageLayerFilters(
  Widget coreUnwrapped,
  Map<String, dynamic> meta,
  List<TuneAdjustmentItem> items,
) {
  Widget w = coreUnwrapped;
  final tintArgb = meta[kMusamiImageTintArgbMetaKey] as int?;
  final silhouetteTint = musamiLayerUsesSilhouetteTint(meta);
  if (tintArgb != null &&
      musamiLayerImageTintAppliesFilterArgb(
        tintArgb,
        allowWhite: silhouetteTint,
      )) {
    w = ColorFiltered(
      colorFilter: ColorFilter.mode(
        musamiColorFromArgb32(tintArgb),
        // Black/dark shape PNGs ignore modulate; srcIn recolors silhouettes.
        silhouetteTint ? BlendMode.srcIn : BlendMode.modulate,
      ),
      child: w,
    );
  }
  final matrix = musamiLayerTuneColorMatrix(meta, items);
  if (!musamiColorMatrixIsIdentity(matrix)) {
    w = RepaintBoundary(
      key: kMusamiTuneFilterRepaintKey,
      child: ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: w),
    );
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

  final borderW = (meta['musamiBorderW'] as num?)?.toDouble() ?? 0;
  final shadowBlur = (meta['musamiShadowBlur'] as num?)?.toDouble() ?? 0;
  final shadowDx = (meta['musamiShadowDx'] as num?)?.toDouble() ?? 0;
  final shadowDy = (meta['musamiShadowDy'] as num?)?.toDouble() ?? 8;
  final shadowStrength =
      (meta['musamiShadowStrength'] as num?)?.toDouble() ?? 0.35;

  Border? border;
  if (borderW > 0) {
    final argb = (meta['musamiBorderArgb'] as int?) ?? 0xFF212121;
    border = Border.all(
      color: musamiColorFromArgb32(argb),
      width: borderW.clamp(0.5, 24.0),
    );
  }

  final hasShadow = shadowBlur > 0;
  final hasPaintedBorder = border != null;

  Widget filtered = _musamiApplyImageLayerFilters(coreUnwrapped, meta, items);

  // Apply shape clipping mask (alpha of silhouette) when meta is set.
  filtered = musamiApplyClippingMaskFromMeta(filtered, meta);

  Widget content = filtered;

  if (hasShadow) {
    content = _MusamiImageDropShadow(
      key: kMusamiComposeShadowDecoratorKey,
      foreground: filtered,
      shadowSource: filtered,
      blur: shadowBlur,
      dx: shadowDx,
      dy: shadowDy,
      strength: shadowStrength,
    );
  }

  if (!hasPaintedBorder) return content;

  final rCompose = BorderRadius.circular(kMusamiImageLayerRoundedCorner);
  return Stack(
    key: kMusamiComposeBorderOverlayStackKey,
    fit: StackFit.passthrough,
    clipBehavior: Clip.none,
    children: [
      content,
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: rCompose, border: border),
          ),
        ),
      ),
    ],
  );
}

WidgetLayer musamiRebuildWidgetLayerVisuals(
  WidgetLayer current,
  Map<String, dynamic> meta, {
  List<TuneAdjustmentItem>? tuneAdjustmentItems,
}) {
  final core = _unwrapMusamiWidgetLayerBareCore(current.widget);
  final opacity =
      (meta['musamiOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0;
  final hidden = meta[kMusamiLayerHiddenMetaKey] == true;
  final styled = musamiComposeImageLayerVisualCore(
    core,
    meta,
    tuneAdjustmentItems: tuneAdjustmentItems,
  );

  // Expand layout for tiny layers so hit-testing stays ~44×44 logical px
  // without changing the painted content size more than a transparent pad.
  final aspect = (meta['musamiAspect'] as num?)?.toDouble() ?? 1.0;
  final baseW = (current.width ?? 100).clamp(1.0, 100000.0);
  final baseH = (baseW * aspect).clamp(1.0, 100000.0);
  final visualW = baseW * current.scale;
  final visualH = baseH * current.scale;
  Widget painted = Opacity(
    opacity: hidden ? 0.0 : opacity,
    child: styled,
  );
  if (!hidden && (visualW < 44 || visualH < 44)) {
    final padX = visualW < 44 ? ((44 - visualW) / 2) / current.scale : 0.0;
    final padY = visualH < 44 ? ((44 - visualH) / 2) / current.scale : 0.0;
    painted = Padding(
      padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
      child: painted,
    );
  }

  final interaction = hidden
      ? current.interaction.copyWith(
          enableMove: false,
          enableScale: false,
          enableRotate: false,
          enableSelection: false,
          enableEdit: false,
        )
      : current.interaction;

  return WidgetLayer(
    id: current.id,
    key: current.key,
    widget: painted,
    width: current.width,
    offset: current.offset,
    rotation: current.rotation,
    scale: current.scale,
    flipX: current.flipX,
    flipY: current.flipY,
    interaction: interaction,
    exportConfigs: current.exportConfigs,
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

/// Updates a widget layer without clearing the current selection (live preview).
/// Pass [recordHistory: true] when the gesture ends so undo/redo stays correct.
void musamiReplaceWidgetLayerOnEditor(
  ProImageEditorState editor,
  WidgetLayer updated, {
  bool recordHistory = false,
}) {
  final idx = editor.activeLayers.indexWhere((l) => l.id == updated.id);
  if (idx < 0) return;

  if (recordHistory) {
    final layerId = updated.id;
    editor.replaceLayer(index: idx, layer: updated);
    editor.layerInteractionManager.selectedLayerId = layerId;
    return;
  }

  editor.activeLayers[idx] = updated;
  editor.setState(() {});
}

/// Peels the frame shell built by [musamiFrameWidgetLayerCore], returning the
/// intrinsic content widget (which carries the image's own proportions).
Widget musamiUnwrapLayerFrameBox(Widget bare) {
  if (bare is! SizedBox || bare.key != kMusamiLayerFrameBoxKey) return bare;
  final clip = bare.child;
  if (clip is! ClipRect) return bare;
  final fitted = clip.child;
  if (fitted is! FittedBox) return bare;
  return fitted.child ?? bare;
}

/// Wraps [content] in a frame box of `width` × `width * aspect`.
///
/// The frame is the box the user drags; [content] keeps its own intrinsic size
/// and proportions. `BoxFit.cover` + `ClipRect` scale the content up until it
/// covers the frame and crop whatever falls outside, so a frame of any ratio
/// never stretches a single pixel of the source image.
Widget musamiFrameWidgetLayerCore(
  Widget content, {
  required double width,
  required double aspect,
  Alignment cropAlignment = Alignment.center,
}) {
  final frameWidth = musamiSanitizedLayerWidth(width);
  final frameHeight = musamiSanitizedLayerWidth(
    frameWidth * musamiSanitizedLayerAspect(aspect),
  );
  return SizedBox(
    key: kMusamiLayerFrameBoxKey,
    width: frameWidth,
    height: frameHeight,
    child: ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: cropAlignment,
        clipBehavior: Clip.hardEdge,
        child: content,
      ),
    ),
  );
}

/// Re-frames a wrapped layer core to a new FRAME size.
///
/// [width] / [aspect] describe the frame only. The image content inside is
/// untouched, so repeated resizes never accumulate distortion.
Widget musamiResizeWidgetLayerCore(
  Widget wrappedWidget, {
  required double width,
  required double aspect,
  Alignment cropAlignment = Alignment.center,
}) {
  final bare = _unwrapMusamiWidgetLayerBareCore(wrappedWidget);
  return musamiFrameWidgetLayerCore(
    musamiUnwrapLayerFrameBox(bare),
    width: width,
    aspect: aspect,
    cropAlignment: cropAlignment,
  );
}

/// Guards layer geometry against zero, negative, NaN and infinite values.
double musamiSanitizedLayerWidth(double width) {
  if (!width.isFinite || width <= 0) return 1.0;
  return width.clamp(1.0, 100000.0);
}

/// Guards a ratio (height / width) against invalid values.
double musamiSanitizedLayerAspect(double aspect) {
  if (!aspect.isFinite || aspect <= 0) return 1.0;
  return aspect.clamp(0.001, 1000.0);
}

/// Ratio (height / width) of the layer FRAME.
double musamiWidgetLayerAspect(WidgetLayer layer) {
  return (layer.meta?[kMusamiFrameAspectMetaKey] as num?)?.toDouble() ?? 1.0;
}

/// Ratio (height / width) of the IMAGE inside the frame.
///
/// Falls back to the frame ratio for layers saved before frames existed, where
/// the two were still the same value.
double musamiWidgetLayerImageAspect(WidgetLayer layer) {
  final stored = (layer.meta?[kMusamiImageAspectMetaKey] as num?)?.toDouble();
  if (stored != null && stored.isFinite && stored > 0) return stored;
  return musamiSanitizedLayerAspect(musamiWidgetLayerAspect(layer));
}

/// Crop alignment of the image inside its frame.
Alignment musamiLayerCropAlignment(Map<String, dynamic>? meta) {
  double axis(String key) {
    final value = (meta?[key] as num?)?.toDouble();
    if (value == null || !value.isFinite) return 0;
    return value.clamp(-1.0, 1.0);
  }

  return Alignment(
    axis(kMusamiCropAlignXMetaKey),
    axis(kMusamiCropAlignYMetaKey),
  );
}

/// Applies FRAME width / aspect plus scale / offset to a widget layer in place.
///
/// Only frame geometry changes here — [kMusamiImageAspectMetaKey] is carried
/// through untouched so the image keeps its own proportions and is re-cropped
/// to the new frame instead of being stretched into it.
void musamiMutateWidgetLayerGeometry(
  ProImageEditorState editor,
  WidgetLayer layer, {
  required double width,
  required double aspect,
  required double scale,
  required Offset offset,
}) {
  final safeWidth = musamiSanitizedLayerWidth(width);
  final safeFrameAspect = musamiSanitizedLayerAspect(aspect);
  final safeScale = (scale.isFinite && scale > 0) ? scale : layer.scale;
  final safeOffset = (offset.dx.isFinite && offset.dy.isFinite)
      ? offset
      : layer.offset;

  // Layers created before frames existed only stored the frame ratio, which
  // back then still matched the image. Snapshot it once as the image ratio.
  final imageAspect = musamiWidgetLayerImageAspect(layer);

  final meta = layer.meta == null
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(layer.meta!);
  meta[kMusamiFrameAspectMetaKey] = safeFrameAspect;
  meta[kMusamiImageAspectMetaKey] = imageAspect;

  final core = musamiResizeWidgetLayerCore(
    layer.widget,
    width: safeWidth,
    aspect: safeFrameAspect,
    cropAlignment: musamiLayerCropAlignment(meta),
  );
  final preliminary = layer.copyWith(
    widget: core,
    width: safeWidth,
    scale: safeScale,
    offset: safeOffset,
    meta: meta,
  );
  final rebuilt = musamiRebuildWidgetLayerVisuals(
    preliminary,
    meta,
    tuneAdjustmentItems: musamiTuneItemsFromEditor(editor),
  );

  layer
    ..widget = rebuilt.widget
    ..width = rebuilt.width
    ..scale = rebuilt.scale
    ..offset = rebuilt.offset
    ..meta = rebuilt.meta;
}

/// Applies width / aspect / scale / offset to a widget layer and rebuilds visuals.
void musamiApplyWidgetLayerGeometry(
  ProImageEditorState editor,
  WidgetLayer layer, {
  required double width,
  required double aspect,
  required double scale,
  required Offset offset,
  bool recordHistory = false,
}) {
  musamiMutateWidgetLayerGeometry(
    editor,
    layer,
    width: width,
    aspect: aspect,
    scale: scale,
    offset: offset,
  );
  if (recordHistory) {
    final layerId = layer.id;
    final idx = editor.activeLayers.indexWhere((l) => l.id == layerId);
    if (idx >= 0) {
      editor.replaceLayer(index: idx, layer: layer);
      editor.layerInteractionManager.selectedLayerId = layerId;
    }
  }
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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

  void _apply({bool recordHistory = false}) {
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
    musamiReplaceWidgetLayerOnEditor(
      widget.editor,
      updated,
      recordHistory: recordHistory,
    );
  }

  void _reset() {
    for (final item in _items) {
      _values[item.id] = 0.0;
    }
    setState(() {});
    _apply(recordHistory: true);
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
                          _apply(recordHistory: false);
                        },
                        onChangeEnd: (_) => _apply(recordHistory: true),
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
  final int? designId;
  final String? designVisibility;
  final List<String> generatedAssetIds;
  final EditorAiGenerationMode? initialAiMode;
  final String? initialAiPrompt;
  final bool aiAutoSend;
  const AddNewScreen({
    super.key,
    required this.height,
    required this.width,
    this.unit = 'px',
    this.presetName = 'Custom Size',
    this.designId,
    this.designVisibility,
    this.generatedAssetIds = const [],
    this.initialAiMode,
    this.initialAiPrompt,
    this.aiAutoSend = false,
  });

  static Widget builder(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final height = arguments?['height'] as double? ?? 400.0;
    final width = arguments?['width'] as double? ?? 400.0;
    final unit = arguments?['unit'] as String? ?? 'px';
    final presetName = arguments?['presetName'] as String? ?? 'Custom Size';
    final backgroundImageBytes =
        arguments?['backgroundImageBytes'] as Uint8List?;
    final designHistoryJson = arguments?['designHistoryJson'] as String?;
    final designId = arguments?['designId'] as int?;
    final designVisibility = arguments?['designVisibility'] as String?;
    final generatedAssetIds =
        (arguments?['generatedAssetIds'] as List?)
            ?.map((id) => id.toString())
            .toList(growable: false) ??
        const <String>[];
    final aiModeName = arguments?['aiMode']?.toString();
    EditorAiGenerationMode? initialAiMode;
    if (aiModeName != null) {
      for (final mode in EditorAiGenerationMode.values) {
        if (mode.name == aiModeName) {
          initialAiMode = mode;
          break;
        }
      }
    }
    final initialAiPrompt = arguments?['aiPrompt']?.toString();
    final aiAutoSend = arguments?['aiAutoSend'] == true;

    return BlocProvider<AddNewBloc>(
      create: (context) =>
          AddNewBloc(AddNewState(screen3AddNewModelObj: AddNewModel()))..add(
            Screen3AddNewInitialEvent(
              height: height,
              width: width,
              unit: unit,
              backgroundImageBytes: backgroundImageBytes,
              designHistoryJson: designHistoryJson,
            ),
          ),
      child: AddNewScreen(
        height: height,
        width: width,
        unit: unit,
        presetName: presetName,
        designId: designId,
        designVisibility: designVisibility,
        generatedAssetIds: generatedAssetIds,
        initialAiMode: initialAiMode,
        initialAiPrompt: initialAiPrompt,
        aiAutoSend: aiAutoSend,
      ),
    );
  }

  @override
  State<AddNewScreen> createState() => _AddNewScreenState();
}

class _AddNewScreenState extends State<AddNewScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _editorRepaintKey = GlobalKey();
  final BackgroundRemovalController _backgroundRemovalController =
      BackgroundRemovalController();
  final GlobalKey<ExpandableFabState> _aiFabKey =
      GlobalKey<ExpandableFabState>();
  bool _aiBarVisible = false;
  bool _isSavingDesign = false;
  EditorAiGenerationMode _aiBarMode = EditorAiGenerationMode.text;
  String? _aiBarPrompt;
  bool _aiBarAutoSend = false;
  bool _didLaunchInitialAi = false;
  String? _localDraftId;
  Timer? _autoSaveDebounce;
  bool _autoSaveInFlight = false;
  /// Cached in [didChangeDependencies] so dispose / lifecycle saves never call
  /// `context.read` on a deactivated element.
  AddNewBloc? _addNewBloc;

  void _openAiBar(
    EditorAiGenerationMode mode, {
    String? prompt,
    bool autoSend = false,
  }) {
    setState(() {
      _aiBarVisible = true;
      _aiBarMode = mode;
      _aiBarPrompt = prompt;
      _aiBarAutoSend = autoSend;
    });
  }

  void _closeAiBar() {
    if (!_aiBarVisible) return;
    setState(() {
      _aiBarVisible = false;
      _aiBarPrompt = null;
      _aiBarAutoSend = false;
    });
  }

  void _maybeLaunchInitialAi(AddNewState state) {
    if (_didLaunchInitialAi) return;
    final mode = widget.initialAiMode;
    final prompt = widget.initialAiPrompt?.trim();
    if (mode == null || prompt == null || prompt.isEmpty) return;
    if (state.editorKey?.currentState == null) return;
    _didLaunchInitialAi = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openAiBar(
        mode,
        prompt: prompt,
        autoSend: widget.aiAutoSend,
      );
    });
  }

  void _editorZoomBy(ProImageEditorState editor, double factor) {
    final viewer = editor.interactiveViewer.currentState;
    if (viewer == null) return;
    final current = viewer.scaleFactor.clamp(0.25, 4.0);
    final next = (current * factor).clamp(0.25, 4.0);
    final offset = viewer.offset;
    viewer.zoomTo(offset: offset, scale: next);
  }

  /// Keeps the InteractiveViewer mounted (so zoom/pan matrix is preserved) and
  /// only toggles whether pinch / two-finger / pan gestures may change it.
  void _syncCanvasZoomInteraction(bool canvasLocked) {
    final editor = _addNewBloc?.state.editorKey?.currentState;
    editor?.interactiveViewer.currentState?.setEnableInteraction(
      !canvasLocked,
    );
  }

  Future<void> _autoSaveLocalDraft({bool force = false}) async {
    if (_autoSaveInFlight && !force) return;
    final bloc = _addNewBloc;
    if (bloc == null) return;
    final editor = bloc.state.editorKey?.currentState;
    if (editor == null) return;
    if (editor.activeLayers.isEmpty) return;
    _autoSaveInFlight = true;
    try {
      final history = await musamiExportDesignStateHistory(editor);
      if (history == null || history.trim().isEmpty) return;
      final blocState = bloc.state;
      final w = blocState.selectedwidth ?? widget.width;
      final h = blocState.selectedheight ?? widget.height;
      final name = widget.presetName.trim().isNotEmpty
          ? widget.presetName.trim()
          : 'Untitled draft';
      Uint8List? thumb;
      try {
        final bytes = await editor.captureEditorImage();
        thumb = await musamiEncodePngThumbnail(bytes);
      } catch (_) {}
      final draft = await LocalDesignStore.instance.saveDraft(
        existingId: _localDraftId,
        name: name,
        historyJson: history,
        width: w,
        height: h,
        thumbnailPng: thumb,
      );
      _localDraftId = draft.id;
    } catch (e) {
      debugPrint('Auto-save local draft failed: $e');
    } finally {
      _autoSaveInFlight = false;
    }
  }

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(seconds: 8), () {
      _autoSaveLocalDraft();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _autoSaveLocalDraft(force: true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final routeArgs =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final localId = routeArgs?['localDesignId']?.toString();
      if (localId != null && localId.isNotEmpty) {
        _localDraftId = localId;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _addNewBloc = context.read<AddNewBloc>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveDebounce?.cancel();
    // Best-effort save without context (widget tree is already tearing down).
    unawaited(_autoSaveLocalDraft(force: true));
    _backgroundRemovalController.dispose();
    super.dispose();
  }

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

  Future<Size> _decodeImageSize(Uint8List bytes) =>
      _musamiDecodeImageSize(bytes);

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
    return showApiAssetBottomSheet<WidgetLayer>(
      context: context,
      editorKey: editorKey,
      type: type,
      pickOnly: true,
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
    meta.removeWhere((k, _) => musamiIsCropMetaKey(k));
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
        'musamiShadowDx',
        'musamiShadowDy',
        'musamiShadowStrength',
        kMusamiImageTintArgbMetaKey,
      ]) {
        if (ex.containsKey(k)) meta[k] = ex[k];
      }
    }

    // Replacing swaps the image inside the existing frame: the frame keeps its
    // size and ratio, the new image keeps its own and is cropped to fit.
    final frameWidth =
        existing.width ??
        picked.width ??
        editor.configs.stickerEditor.initWidth;
    final frameAspect = musamiWidgetLayerAspect(existing);
    meta[kMusamiFrameAspectMetaKey] = frameAspect;
    meta[kMusamiImageAspectMetaKey] = musamiWidgetLayerImageAspect(picked);

    final core = musamiFrameWidgetLayerCore(
      musamiUnwrapLayerFrameBox(
        _unwrapMusamiWidgetLayerBareCore(picked.widget),
      ),
      width: frameWidth,
      aspect: frameAspect,
      cropAlignment: musamiLayerCropAlignment(meta),
    );
    final styled = musamiComposeImageLayerVisualCore(core, meta);
    final updated = WidgetLayer(
      id: existing.id,
      key: existing.key,
      widget: Opacity(opacity: opacity.clamp(0.0, 1.0), child: styled),
      width: frameWidth,
      offset: existing.offset,
      rotation: existing.rotation,
      scale: existing.scale,
      flipX: existing.flipX,
      flipY: existing.flipY,
      interaction: existing.interaction,
      exportConfigs: picked.exportConfigs.hasParameter
          ? picked.exportConfigs
          : existing.exportConfigs,
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
    final layerId = layer.id;
    final fontLibrary = CustomFontLibrary.instance;
    final userFontLibrary = UserFontLibrary.instance;
    unawaited(fontLibrary.ensureLoaded());
    unawaited(userFontLibrary.ensureLoaded());

    final allFonts = GoogleFonts.asMap().keys.toList()..sort();
    String query = '';
    String? loadingCustomKey;
    String? loadingUserKey;

    TextLayer? liveLayer() {
      return editor.activeLayers.cast<TextLayer?>().firstWhere(
        (l) => l?.id == layerId,
        orElse: () => null,
      );
    }

    TextStyle baseStyleFor(TextLayer live) {
      return musamiTextStyleWithoutPackage(
        live.textStyle ?? const TextStyle(),
      );
    }

    Future<void> applyFont(String fontName) async {
      final live = liveLayer() ?? layer;
      final nextStyle = GoogleFonts.getFont(
        fontName,
        textStyle: baseStyleFor(live),
      );
      final updated = copyTextLayer(live, textStyle: nextStyle);
      editor.applyTextLayerChanges(live, updated);
      editor.setState(() {});
    }

    Future<void> applyCustomFont(
      CustomFontItem font,
      void Function(VoidCallback fn) setSheetState,
    ) async {
      final key = font.uuid.isNotEmpty ? font.uuid : '${font.id}';
      setSheetState(() => loadingCustomKey = key);
      final style = await fontLibrary.loadStyle(font);
      if (!context.mounted) return;
      setSheetState(() => loadingCustomKey = null);
      if (style == null) {
        showAppToast(
          fontLibrary.error ?? 'msg_custom_font_load_failed'.tr,
          type: ToastificationType.error,
        );
        return;
      }
      final live = liveLayer() ?? layer;
      final nextStyle = musamiTextStyleWithFont(
        baseStyleFor(live),
        fontFamily: style.fontFamily,
        fontPackage: null,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
      );
      final updated = copyTextLayer(live, textStyle: nextStyle);
      editor.applyTextLayerChanges(live, updated);
      editor.setState(() {});
      if (context.mounted) Navigator.pop(context);
    }

    Future<void> applyUserFont(
      UserFontItem font,
      void Function(VoidCallback fn) setSheetState,
    ) async {
      setSheetState(() => loadingUserKey = font.id);
      final style = await userFontLibrary.loadStyle(font);
      if (!context.mounted) return;
      setSheetState(() => loadingUserKey = null);
      if (style == null) {
        showAppToast(
          userFontLibrary.error ?? 'msg_user_font_load_failed'.tr,
          type: ToastificationType.error,
        );
        return;
      }
      final live = liveLayer() ?? layer;
      final nextStyle = musamiTextStyleWithFont(
        baseStyleFor(live),
        fontFamily: style.fontFamily,
        fontPackage: null,
      );
      final updated = copyTextLayer(live, textStyle: nextStyle);
      editor.applyTextLayerChanges(live, updated);
      editor.setState(() {});
      if (context.mounted) Navigator.pop(context);
    }

    Future<void> importUserFont(
      void Function(VoidCallback fn) setSheetState,
    ) async {
      final result = await userFontLibrary.importFromDevice();
      if (!context.mounted) return;
      if (result is UserFontImportSuccess) {
        showAppToast(
          'msg_user_font_imported'.tr.replaceAll('{name}', result.font.name),
          type: ToastificationType.success,
        );
        await applyUserFont(result.font, setSheetState);
      } else if (result is UserFontImportFailure) {
        showAppToast(result.message, type: ToastificationType.error);
      }
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
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        fontLibrary,
                        userFontLibrary,
                      ]),
                      builder: (ctx, _) {
                        return StatefulBuilder(
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
                            final hasCustomFonts = fontLibrary.fonts
                                .where((f) => f.isFlutterLoadable)
                                .isNotEmpty;
                            final preferArabicFirst = RegExp(
                              r'[\u0600-\u06FF]',
                            ).hasMatch(layer.text);

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
                                          'lbl_text_editor_fonts_section'.tr,
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
                                      hintText: 'lbl_search_fonts'.tr,
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
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
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppDs.space4.h,
                                    0,
                                    AppDs.space4.h,
                                    AppDs.space2.v,
                                  ),
                                  child: MusamiUserFontSections(
                                    theme: theme,
                                    library: userFontLibrary,
                                    query: query,
                                    loadingFontKey: loadingUserKey,
                                    chipBackground: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                    labelColor: Colors.white.withValues(
                                      alpha: 0.7,
                                    ),
                                    sectionTitleColor: cs.primary,
                                    previewColor: Colors.white,
                                    onSelect: (font) =>
                                        applyUserFont(font, setSheetState),
                                    onImport: () =>
                                        importUserFont(setSheetState),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppDs.space4.h,
                                    0,
                                    AppDs.space4.h,
                                    AppDs.space2.v,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'lbl_text_editor_fonts_custom'.tr,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppDs.space4.h,
                                    0,
                                    AppDs.space4.h,
                                    AppDs.space2.v,
                                  ),
                                  child: MusamiCustomFontSections(
                                    theme: theme,
                                    library: fontLibrary,
                                    query: query,
                                    preferArabicFirst: preferArabicFirst,
                                    loadingFontKey: loadingCustomKey,
                                    chipBackground: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                    labelColor: Colors.white.withValues(
                                      alpha: 0.7,
                                    ),
                                    sectionTitleColor: Colors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    previewColor: Colors.white,
                                    onSelect: (font) => applyCustomFont(
                                      font,
                                      setSheetState,
                                    ),
                                  ),
                                ),
                                if (hasCustomFonts ||
                                    fontLibrary.isLoading ||
                                    fontLibrary.error != null)
                                  SizedBox(height: AppDs.space2.v),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppDs.space4.h,
                                    0,
                                    AppDs.space4.h,
                                    AppDs.space2.v,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'lbl_text_editor_fonts_google_pkg'.tr,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (ctx, constraints) {
                                      final maxW = constraints.maxWidth;
                                      final crossAxisCount =
                                          maxW >= 380 ? 2 : 1;
                                      final previewText =
                                          layer.text.trim().isEmpty
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
                                          final live = liveLayer() ?? layer;
                                          final previewStyle =
                                              GoogleFonts.getFont(
                                            fontName,
                                            textStyle: baseStyleFor(live)
                                                .copyWith(
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
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppDs.radiusMd.adaptSize,
                                              ),
                                              onTap: () async {
                                                await applyFont(fontName);
                                                if (ctx.mounted) {
                                                  Navigator.pop(ctx);
                                                }
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
                                                      overflow: TextOverflow
                                                          .ellipsis,
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
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          previewText,
                                                          maxLines:
                                                              crossAxisCount ==
                                                                      1
                                                                  ? 1
                                                                  : 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
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


  /// Intrinsic image content for a layer: a box at the source pixel ratio.
  ///
  /// The box always matches the decoded image, so the image is never stretched
  /// here. Frame cropping happens one level up in [musamiFrameWidgetLayerCore].
  Widget _buildGalleryStickerWidget(
    BuildContext context, {
    required ImageProvider image,
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Image(
        image: image,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appLocaleNotifier,
      builder: (context, _) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              unawaited(_autoSaveLocalDraft(force: true));
            }
          },
          child: SafeArea(
            child: BlocListener<AddNewBloc, AddNewState>(
              listenWhen: (prev, next) =>
                  prev.canvasLocked != next.canvasLocked,
              listener: (context, state) {
                _syncCanvasZoomInteraction(state.canvasLocked);
              },
              child: BlocBuilder<AddNewBloc, AddNewState>(
                builder: (context, state) {
              _maybeLaunchInitialAi(state);
              final width = widget.width;
              final height = widget.height;
              if (state.transparentBytes == null) {
                return Scaffold(
                  backgroundColor: appTheme.blueGray90007,
                  body: const AppLoadingBlock(),
                );
              }

              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: appTheme.blueGray90007,
                // Keep the canvas/tool panels fixed when the soft keyboard opens
                // (Select Size fields). Panels pad themselves via viewInsets.
                resizeToAvoidBottomInset: false,
                drawer: AppNavigationDrawer(
                  key: ValueKey<Object>(
                    Object.hash(
                      appLocaleNotifier.languageCode,
                      appLocaleNotifier.localeRevision,
                    ),
                  ),
                  homePopsToRootHome: true,
                ),
                // Selection frames use OverlayPortal (above the drawer). Clear
                // selection when the drawer opens so the frame is not on top.
                onDrawerChanged: (isOpened) {
                  if (!isOpened) return;
                  final editor = state.editorKey?.currentState;
                  if (editor != null) {
                    _editorClearAllSelection(editor);
                  }
                },
                floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
                floatingActionButton: null,
                body: Stack(
                  children: [
                    RepaintBoundary(
                      key: _editorRepaintKey,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildEditorWithTransparencyPreview(
                              context: context,
                              state: state,
                              width: width,
                              height: height,
                            ),
                          ),
                          if (!state.isScreenColorPicking &&
                              state.showbottomContainer == '1')
                            _buildColumnBookmark(context, state),
                          if (!state.isScreenColorPicking &&
                              state.showbottomContainer == '2')
                            _buildColumnSelectSize(context, state),
                          if (!state.isScreenColorPicking &&
                              state.showbottomContainer == '4')
                            _buildBgColorOverlay(context, state),
                          // Hide tooltip tails while the keyboard is open — they
                          // would otherwise float mid-screen above the inset panel.
                          if (!state.isScreenColorPicking &&
                              state.showbottomContainer == '2' &&
                              MediaQuery.viewInsetsOf(context).bottom == 0)
                            CustomImageView(
                              imagePath: ImageConstant.imgPolygon1,
                              height: 47.v,
                              width: 103.h,
                              alignment: Alignment.bottomLeft,
                              margin: EdgeInsets.only(left: 106.h),
                              fit: BoxFit.cover,
                            ),
                          if (!state.isScreenColorPicking &&
                              state.showbottomContainer == '1' &&
                              MediaQuery.viewInsetsOf(context).bottom == 0)
                            CustomImageView(
                              imagePath: ImageConstant.imgPolygon1,
                              height: 47.v,
                              width: 103.h,
                              alignment: Alignment.bottomLeft,
                              margin: EdgeInsets.only(left: 26.h),
                              fit: BoxFit.cover,
                            ),
                          if (!state.isScreenColorPicking &&
                              state.showbottomContainer == '4' &&
                              MediaQuery.viewInsetsOf(context).bottom == 0)
                            CustomImageView(
                              imagePath: ImageConstant.imgPolygon1,
                              height: 47.v,
                              width: 103.h,
                              alignment: Alignment.bottomLeft,
                              margin: EdgeInsets.only(left: 290.h),
                              fit: BoxFit.cover,
                            ),
                        ],
                      ),
                    ),
                    if (state.isScreenColorPicking)
                      ScreenColorPickerOverlay(
                        repaintBoundaryKey: _editorRepaintKey,
                        onColorPicked: (color) {
                          context.read<AddNewBloc>().add(
                            SetBgColorEvent(color: color),
                          );
                          context.read<AddNewBloc>().add(
                            EndScreenColorPickEvent(),
                          );
                        },
                        onCancel: () {
                          context.read<AddNewBloc>().add(
                            EndScreenColorPickEvent(),
                          );
                        },
                      ),
                    if (!state.isScreenColorPicking)
                      DraggableEditorAiFab(
                        fabKey: _aiFabKey,
                        onOpenMode: _openAiBar,
                      ),
                    if (!state.isScreenColorPicking && _aiBarVisible)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: MusamiEditorAiOverlay(
                          editorKey: state.editorKey,
                          visible: true,
                          mode: _aiBarMode,
                          initialPrompt: _aiBarPrompt,
                          autoSend: _aiBarAutoSend,
                          onClose: _closeAiBar,
                        ),
                      ),
                  ],
                ),
                bottomNavigationBar: state.activeToolbarMode == 'text'
                    ? _buildTextContextBottomBar(context, state)
                    : state.activeToolbarMode == 'image'
                    ? _buildImageContextBottomBar(context, state)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Visibility(
                            visible: state.showbottomContainer == '0',
                            maintainState: true,
                            maintainAnimation: true,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16.h, 4.v, 16.h, 0),
                              // Transparent BG status replaces the ad strip so
                              // users get clear feedback instead of a raw ad tile.
                              child: state.isBackgroundTransparent
                                  ? _TransparentBgStatusBar(
                                      onRestore: () {
                                        context.read<AddNewBloc>().add(
                                          MakeTransparentEvent(),
                                        );
                                        showAppToast(
                                          'msg_transparent_bg_off'.tr,
                                          type: ToastificationType.success,
                                        );
                                      },
                                    )
                                  : AdvertisementBanner(
                                      key: const ValueKey(
                                        'design_editor_ad_banner',
                                      ),
                                      placement: 'design_editor',
                                      limit: 3,
                                      height: 48.v,
                                      autoAdvanceSeconds: 8,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 49.h,
                              vertical: 10.v,
                            ),
                            child: SizedBox(
                              height: 52,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      BlocProvider.of<AddNewBloc>(context).add(
                                        ShowContainerEvent(
                                          ishow:
                                              state.showbottomContainer == '1'
                                              ? '0'
                                              : '1',
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomIconButton(
                                          height: 22.adaptSize,
                                          width: 22.adaptSize,
                                          child: CustomImageView(
                                            imagePath:
                                                state.showbottomContainer == '1'
                                                ? ImageConstant
                                                      .imgPlusSvgrepoCom
                                                : ImageConstant
                                                      .imgPlusSvgrepoComOnprimarycontainer,
                                          ),
                                        ),
                                        SizedBox(height: 4.v),
                                        Text(
                                          "lbl_add_new".tr,
                                          style:
                                              state.showbottomContainer == '1'
                                              ? CustomTextStyles
                                                    .bodySmallYellowA400
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
                                          ishow:
                                              state.showbottomContainer != '0'
                                              ? '0'
                                              : '2',
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          style:
                                              state.showbottomContainer == '2'
                                              ? CustomTextStyles
                                                    .bodySmallYellowA400
                                              : theme.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      final wasTransparent =
                                          state.isBackgroundTransparent;
                                      BlocProvider.of<AddNewBloc>(
                                        context,
                                      ).add(MakeTransparentEvent());
                                      // Close other tool panels so the status bar is visible.
                                      if (state.showbottomContainer != '0') {
                                        BlocProvider.of<AddNewBloc>(
                                          context,
                                        ).add(ShowContainerEvent(ishow: '0'));
                                      }
                                      showAppToast(
                                        wasTransparent
                                            ? 'msg_transparent_bg_off'.tr
                                            : 'msg_transparent_bg_on'.tr,
                                        type: ToastificationType.success,
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomIconButton(
                                          height: 22.adaptSize,
                                          width: 22.adaptSize,
                                          child: CustomImageView(
                                            imagePath:
                                                state.isBackgroundTransparent
                                                ? ImageConstant
                                                      .imgBlockchainSvgrepoComPrimary
                                                : ImageConstant
                                                      .imgBlockchainSvgrepoCom,
                                          ),
                                        ),
                                        SizedBox(height: 4.v),
                                        Text(
                                          "lbl_transparent_bg".tr,
                                          style: state.isBackgroundTransparent
                                              ? CustomTextStyles
                                                    .bodySmallYellowA400
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
                                          ishow:
                                              state.showbottomContainer == '4'
                                              ? '0'
                                              : '4',
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          style:
                                              state.showbottomContainer == '4'
                                              ? CustomTextStyles
                                                    .bodySmallYellowA400
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
                        ],
                      ),
              );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextContextBottomBar(BuildContext context, AddNewState state) {
    final editor = state.editorKey?.currentState;
    if (editor == null) return const SizedBox.shrink();

    final selectedId = state.selectedElementId;
    if (selectedId != null) {
      final layer = _editorFindLayer(editor, selectedId);
      if (layer != null && _editorLayerInteractionBlocked(layer)) {
        return const SizedBox.shrink();
      }
    }

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
      // Package renders text as initFontSize * scale * fontScale and ignores
      // TextStyle.fontSize — drive size through fontScale (see helpers).
      final initFontSize = editor.configs.textEditor.initFontSize;
      final currentSize = musamiTextLayerVisualFontSize(
        layer,
        initFontSize: initFontSize,
      );

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(context);
          double v = currentSize;
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
                          final live = selectedTextLayer();
                          if (live == null) return;
                          editor.applyTextLayerChanges(
                            live,
                            musamiTextLayerWithVisualFontSize(
                              live,
                              visualFontSize: nv,
                              initFontSize: initFontSize,
                            ),
                          );
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
      final layer = selectedTextLayer();
      if (layer == null) return;
      final initial = layer.textStyle?.color ?? layer.color;
      musamiShowLayerTextColorPicker(
        context,
        title: 'lbl_pick_text_color'.tr,
        initialColor: initial,
        onColorChanged: (c) {
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
      final layer = selectedTextLayer();
      if (layer == null) return;
      musamiShowLayerTextBackgroundPicker(
        context,
        title: 'lbl_pick_text_background'.tr,
        currentBackground: layer.textStyle?.backgroundColor,
        onBackgroundChanged: (bg) {
          final l = selectedTextLayer();
          if (l == null) return;
          // [TextStyle.copyWith(backgroundColor: null)] does not clear — use an
          // explicit alpha-zero colour. [RoundedBackgroundText] also reads
          // [TextLayer.background] for the box behind the text, so clear both.
          final fill = bg ?? Colors.transparent;
          final clear = fill.a < 0.01;
          final nextStyle = (l.textStyle ?? const TextStyle()).copyWith(
            backgroundColor: clear ? Colors.transparent : fill,
          );
          editor.applyTextLayerChanges(
            l,
            l.copyWith(
              textStyle: nextStyle,
              color: nextStyle.color ?? l.color,
              background: clear ? Colors.transparent : fill,
              colorMode: clear
                  ? LayerBackgroundMode.onlyColor
                  : LayerBackgroundMode.backgroundAndColor,
            ),
          );
          editor.setState(() {});
        },
      );
    }

    void pickOutlineColor() {
      final layer = selectedTextLayer();
      if (layer == null) return;
      if (state.textContextSecondaryPanel != 'stroke') {
        setTextSecondaryPanel('stroke');
      }
      musamiShowLayerTextColorPicker(
        context,
        title: 'Outline colour',
        initialColor: currentStrokeColor(layer) ?? const Color(0xFF000000),
        onColorChanged: (c) {
          applyStrokeColor(c);
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
      onColor: pickTextColor,
    );
  }

  /// Opens the bundled [CropRotateEditor] on the selected layer's raster bytes.
  /// Cancel/back closes the route without mutating the layer; Done replaces the
  /// in-memory bitmap (destructive) while preserving transform, z-order, and
  /// Musami meta-driven styling (opacity, border, shadow, tune matrix).
  Future<void> _openWidgetLayerCropRaster(
    BuildContext context,
    ProImageEditorState editor,
    WidgetLayer layer,
  ) async {
    final raw = musamiTryExtractMemoryImageBytes(layer.widget);
    if (raw == null || raw.isEmpty) {
      if (context.mounted) {
        showAppToast(
          'This layer cannot be cropped.',
          type: ToastificationType.warning,
        );
      }
      return;
    }

    final theme = Theme.of(context);
    final cropRotateOnly = ProImageEditorConfigs(
      i18n: I18n(
        doneLoadingMsg: 'msg_saving_your_design'.tr,
        cropRotateEditor: const I18nCropRotateEditor(
          bottomNavigationBarText: 'Crop and rotate',
          done: 'Done',
          cancel: 'Cancel',
          back: 'Back',
          reset: 'Reset',
          undo: 'Undo',
          redo: 'Redo',
          rotate: 'Rotate',
          flip: 'Flip',
          ratio: 'Ratio',
        ),
      ),
      cropRotateEditor: CropRotateEditorConfigs(
        enableProvideImageInfos: true,
        initAspectRatio: CropAspectRatios.custom,
        showLayers: false,
        enableTransformLayers: false,
        aspectRatios: const [
          AspectRatioItem(text: 'Free', value: -1),
          AspectRatioItem(text: 'Original', value: 0.0),
          AspectRatioItem(text: '1:1', value: 1.0),
          AspectRatioItem(text: '4:5', value: 4.0 / 5.0),
          AspectRatioItem(text: '16:9', value: 16.0 / 9.0),
        ],
        tools: const [
          CropRotateTool.rotate,
          CropRotateTool.flip,
          CropRotateTool.aspectRatio,
          CropRotateTool.reset,
        ],
      ),
    );

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => CropRotateEditor.memory(
          raw,
          initConfigs: CropRotateEditorInitConfigs(
            theme: theme,
            configs: cropRotateOnly,
            convertToUint8List: true,
            enableCloseButton: true,
            enablePopWhenDone: false,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List outBytes) async {
                if (outBytes.isEmpty) return;
                final stableContext = this.context;
                if (!stableContext.mounted) return;

                final tuneItems = musamiTuneItemsFromEditor(editor);
                final decodedSize = await _decodeImageSize(outBytes);
                if (!stableContext.mounted) return;

                final provider = MemoryImage(outBytes);
                await precacheImage(provider, stableContext);
                if (!stableContext.mounted) return;

                final meta = layer.meta == null
                    ? <String, dynamic>{}
                    : Map<String, dynamic>.from(layer.meta!);
                meta.removeWhere((k, _) => musamiIsCropMetaKey(k));
                // Cropping produces new pixels: frame and image both adopt the
                // ratio the user just cropped to.
                if (decodedSize.width > 0 && decodedSize.height > 0) {
                  final cropped = decodedSize.height / decodedSize.width;
                  meta[kMusamiFrameAspectMetaKey] = cropped;
                  meta[kMusamiImageAspectMetaKey] = cropped;
                }

                final newCore = _buildGalleryStickerWidget(
                  stableContext,
                  image: provider,
                  width: decodedSize.width,
                  height: decodedSize.height,
                );

                final preliminary = layer.copyWith(
                  widget: newCore,
                  width: decodedSize.width,
                  meta: meta,
                );
                final updated = musamiRebuildWidgetLayerVisuals(
                  preliminary,
                  meta,
                  tuneAdjustmentItems: tuneItems,
                );

                final idx = editor.activeLayers.indexWhere(
                  (l) => l.id == layer.id,
                );
                if (idx >= 0) {
                  editor.replaceLayer(index: idx, layer: updated);
                  editor.layerInteractionManager.selectedLayerId = updated.id;
                  editor.setState(() {});
                }
              },
              onCloseEditor: (_) {
                if (Navigator.of(routeContext).canPop()) {
                  Navigator.of(routeContext).pop();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyBackgroundRemovedToWidgetLayer({
    required BuildContext context,
    required ProImageEditorState editor,
    required WidgetLayer layer,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty || !context.mounted) return;

    final tuneItems = musamiTuneItemsFromEditor(editor);
    final provider = MemoryImage(bytes);
    await precacheImage(provider, context);
    if (!context.mounted) return;

    final meta = layer.meta == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(layer.meta!);
    meta.removeWhere((k, _) => musamiIsCropMetaKey(k));

    // Background removal keeps the source pixel ratio, so the image content is
    // rebuilt at its own ratio and re-cropped into the frame the user has.
    final displayWidth = layer.width ?? 200.0;
    final frameAspect = musamiWidgetLayerAspect(layer);
    final imageAspect = musamiWidgetLayerImageAspect(layer);
    meta[kMusamiImageAspectMetaKey] = imageAspect;

    final newCore = musamiFrameWidgetLayerCore(
      _buildGalleryStickerWidget(
        context,
        image: provider,
        width: displayWidth,
        height: displayWidth * imageAspect,
      ),
      width: displayWidth,
      aspect: frameAspect,
      cropAlignment: musamiLayerCropAlignment(meta),
    );

    final preliminary = layer.copyWith(
      widget: newCore,
      width: displayWidth,
      offset: layer.offset,
      rotation: layer.rotation,
      scale: layer.scale,
      flipX: layer.flipX,
      flipY: layer.flipY,
      meta: meta,
    );
    final updated = musamiRebuildWidgetLayerVisuals(
      preliminary,
      meta,
      tuneAdjustmentItems: tuneItems,
    );

    final idx = editor.activeLayers.indexWhere((l) => l.id == layer.id);
    if (idx >= 0) {
      editor.replaceLayer(index: idx, layer: updated);
      editor.layerInteractionManager.selectedLayerId = updated.id;
      editor.setState(() {});
    }
  }

  String _localizedBackgroundRemovalError(BackgroundRemovalState state) {
    switch (state.errorKind) {
      case BackgroundRemovalErrorKind.invalidFormat:
        return 'msg_bg_removal_invalid_format'.tr;
      case BackgroundRemovalErrorKind.fileTooLarge:
        return 'msg_bg_removal_file_too_large'.tr;
      case BackgroundRemovalErrorKind.timeout:
        return 'msg_bg_removal_timeout'.tr;
      case BackgroundRemovalErrorKind.network:
        return 'msg_bg_removal_network_error'.tr;
      case BackgroundRemovalErrorKind.insufficientCoins:
        return 'msg_insufficient_coins'.tr;
      case BackgroundRemovalErrorKind.apiFailure:
      case null:
        return 'msg_bg_removal_api_failure'.tr;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Layer context menu ("More")
  //
  // Every row delegates to the editor action that already exists (delete,
  // duplicate, lock, align, background) — the menu adds presentation, never a
  // second implementation. None of these actions touch frame/image geometry,
  // so the crop-based resize model is unaffected.
  // ─────────────────────────────────────────────────────────────────────────

  /// Blocks re-entry while a slow menu action (export, background) is running.
  bool _layerMenuBusy = false;

  /// Keyboard hints are meaningless without a keyboard, so they are shown on
  /// desktop only.
  String? _layerMenuShortcut(BuildContext context, String mac, String pc) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.macOS:
        return mac;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return pc;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  void _comingSoon() =>
      showAppToast('msg_coming_soon'.tr, type: ToastificationType.info);

  /// Opens the contextual menu for [layer], anchored to the More button.
  void _openLayerContextMenu({
    required BuildContext screenContext,
    required BuildContext anchorContext,
    required ProImageEditorState editor,
    required Layer layer,
  }) {
    final anchor = musamiAnchorRectFromContext(anchorContext);
    if (anchor == null) return;

    showMusamiLayerContextMenu(
      context: anchorContext,
      anchorRect: anchor,
      sections: _buildLayerMenuSections(
        menuContext: anchorContext,
        screenContext: screenContext,
        editor: editor,
        layer: layer,
      ),
    );
  }

  MusamiLayerQuickBarActions _buildLayerQuickBarActions({
    required BuildContext screenContext,
    required GlobalKey<ProImageEditorState> editorKey,
    required Layer layer,
  }) {
    return MusamiLayerQuickBarActions(
      isLocked: _editorLayerTransformLocked(layer),
      onComment: _comingSoon,
      onLockToggle: () {
        final editor = editorKey.currentState;
        if (editor == null) return;
        _editorToggleLayerTransformLock(editor, layer);
      },
      onDuplicate: () {
        final editor = editorKey.currentState;
        if (editor == null) return;
        _layerMenuDuplicate(screenContext, editor, layer.id);
      },
      onDelete: () {
        final editor = editorKey.currentState;
        if (editor == null) return;
        _layerMenuDelete(screenContext, editor, layer.id);
      },
      onMore: (anchorContext) {
        final editor = editorKey.currentState;
        if (editor == null) return;
        _openLayerContextMenu(
          screenContext: screenContext,
          anchorContext: anchorContext,
          editor: editor,
          layer: layer,
        );
      },
    );
  }

  Widget _wrapLayerSelectionChrome({
    required OverlayChildLayoutInfo info,
    required Layer layer,
    required Size canvasBodySize,
    required MusamiLayerQuickBarActions actions,
    required Widget selectionOverlay,
  }) {
    return MusamiLayerSelectionChrome(
      info: info,
      layer: layer,
      canvasBodySize: canvasBodySize,
      actions: actions,
      selectionOverlay: selectionOverlay,
    );
  }

  List<MusamiContextMenuSection> _buildLayerMenuSections({
    required BuildContext menuContext,
    required BuildContext screenContext,
    required ProImageEditorState editor,
    required Layer layer,
  }) {
    final layerId = layer.id;
    final isImage = layer is WidgetLayer;
    final isLocked = _editorLayerTransformLocked(layer);
    final hasClipboard = MusamiLayerClipboard.instance.hasContent;

    return <MusamiContextMenuSection>[
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.copy_rounded,
          label: 'lbl_layer_menu_copy'.tr,
          shortcut: _layerMenuShortcut(menuContext, '⌘C', 'Ctrl C'),
          onSelected: () => _layerMenuCopy(editor, layerId),
        ),
        MusamiContextMenuItem(
          icon: Icons.content_paste_rounded,
          label: 'lbl_layer_menu_paste'.tr,
          shortcut: _layerMenuShortcut(menuContext, '⌘V', 'Ctrl V'),
          enabled: hasClipboard,
          onSelected: () => _layerMenuPaste(screenContext, editor),
        ),
        MusamiContextMenuItem(
          icon: Icons.control_point_duplicate_rounded,
          label: 'lbl_layer_menu_duplicate'.tr,
          shortcut: _layerMenuShortcut(menuContext, '⌘D', 'Ctrl D'),
          onSelected: () => _layerMenuDuplicate(screenContext, editor, layerId),
        ),
        MusamiContextMenuItem(
          icon: Icons.delete_outline_rounded,
          label: 'lbl_layer_menu_delete'.tr,
          shortcut: _layerMenuShortcut(menuContext, 'DELETE', 'DELETE'),
          destructive: true,
          onSelected: () => _layerMenuDelete(screenContext, editor, layerId),
        ),
      ]),
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.align_horizontal_left_rounded,
          label: 'lbl_layer_menu_align_page'.tr,
          enabled: !isLocked,
          submenu: () => _buildAlignSubmenuSections(editor, layerId),
        ),
      ]),
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.hexagon_outlined,
          label: 'lbl_layer_menu_create_component'.tr,
          enabled: false,
          onSelected: _comingSoon,
        ),
        MusamiContextMenuItem(
          icon: Icons.mode_comment_outlined,
          label: 'lbl_layer_menu_comment'.tr,
          shortcut: _layerMenuShortcut(menuContext, '⌥⌘N', 'Ctrl Alt N'),
          enabled: false,
          onSelected: _comingSoon,
        ),
        MusamiContextMenuItem(
          icon: isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
          label: isLocked
              ? 'lbl_layer_menu_unlock'.tr
              : 'lbl_layer_menu_lock'.tr,
          shortcut: _layerMenuShortcut(menuContext, '⌥⇧L', 'Ctrl Shift L'),
          onSelected: () => _layerMenuToggleLock(editor, layerId),
        ),
        MusamiContextMenuItem(
          icon: Icons.link_rounded,
          label: 'lbl_layer_menu_link'.tr,
          shortcut: _layerMenuShortcut(menuContext, '⌘K', 'Ctrl K'),
          onSelected: () => _layerMenuEditLink(screenContext, editor, layerId),
        ),
        MusamiContextMenuItem(
          icon: Icons.schedule_rounded,
          label: 'lbl_layer_menu_timings'.tr,
          enabled: false,
          onSelected: _comingSoon,
        ),
        if (isImage)
          MusamiContextMenuItem(
            icon: Icons.accessibility_new_rounded,
            label: 'lbl_layer_menu_alt_text'.tr,
            onSelected: () =>
                _layerMenuEditAltText(screenContext, editor, layerId),
          ),
      ]),
      if (isImage)
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.wallpaper_rounded,
            label: 'lbl_layer_menu_set_background'.tr,
            onSelected: () =>
                _layerMenuSetAsBackground(screenContext, editor, layerId),
          ),
          MusamiContextMenuItem(
            icon: Icons.palette_outlined,
            label: 'lbl_layer_menu_apply_colors'.tr,
            onSelected: () =>
                _layerMenuApplyColors(screenContext, editor, layerId),
          ),
        ]),
      MusamiContextMenuSection([
        if (isImage)
          MusamiContextMenuItem(
            icon: Icons.download_rounded,
            label: 'lbl_layer_menu_download'.tr,
            onSelected: () =>
                _layerMenuDownload(screenContext, editor, layerId),
          ),
        MusamiContextMenuItem(
          icon: Icons.info_outline_rounded,
          label: 'lbl_layer_menu_info'.tr,
          onSelected: () => _layerMenuShowInfo(screenContext, editor, layerId),
        ),
      ]),
    ];
  }

  /// Align rows delegate to [musamiAlignLayerToPage] — the same canvas maths the
  /// align sheet uses, so the two can never disagree.
  List<MusamiContextMenuSection> _buildAlignSubmenuSections(
    ProImageEditorState editor,
    String layerId,
  ) {
    void align({int? xT, int? yT}) {
      if (!musamiAlignLayerToPage(
        editor: editor,
        layerId: layerId,
        xT: xT,
        yT: yT,
      )) {
        showAppToast(
          'msg_editor_align_no_canvas'.tr,
          type: ToastificationType.warning,
        );
        return;
      }
      editor.setState(() {});
    }

    return <MusamiContextMenuSection>[
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.align_horizontal_left_rounded,
          label: 'lbl_editor_align_left'.tr,
          onSelected: () => align(xT: -1),
        ),
        MusamiContextMenuItem(
          icon: Icons.align_horizontal_center_rounded,
          label: 'lbl_editor_align_center_h'.tr,
          onSelected: () => align(xT: 0),
        ),
        MusamiContextMenuItem(
          icon: Icons.align_horizontal_right_rounded,
          label: 'lbl_editor_align_right'.tr,
          onSelected: () => align(xT: 1),
        ),
      ]),
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.align_vertical_top_rounded,
          label: 'lbl_editor_align_top'.tr,
          onSelected: () => align(yT: -1),
        ),
        MusamiContextMenuItem(
          icon: Icons.align_vertical_center_rounded,
          label: 'lbl_editor_align_middle'.tr,
          onSelected: () => align(yT: 0),
        ),
        MusamiContextMenuItem(
          icon: Icons.align_vertical_bottom_rounded,
          label: 'lbl_editor_align_bottom'.tr,
          onSelected: () => align(yT: 1),
        ),
      ]),
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.filter_center_focus_rounded,
          label: 'lbl_layer_align_center_page'.tr,
          onSelected: () => align(xT: 0, yT: 0),
        ),
      ]),
    ];
  }

  void _layerMenuCopy(ProImageEditorState editor, String layerId) {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return;
    if (!MusamiLayerClipboard.instance.copy(layer)) return;
    showAppToast('msg_layer_copied'.tr, type: ToastificationType.success);
  }

  void _layerMenuPaste(BuildContext context, ProImageEditorState editor) {
    final pasted = MusamiLayerClipboard.instance.read();
    if (pasted == null) {
      showAppToast(
        'msg_layer_clipboard_empty'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    musamiAddAndSelectLayer(editor, pasted);
    _syncEditorSelection(context, pasted);
    showAppToast('msg_layer_pasted'.tr, type: ToastificationType.success);
  }

  void _layerMenuDuplicate(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return;
    final copy = musamiCloneLayer(layer, nudge: kMusamiLayerDuplicateNudge);
    if (copy == null) return;
    musamiAddAndSelectLayer(editor, copy);
    _syncEditorSelection(context, copy);
  }

  void _layerMenuDelete(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return;
    if (_editorLayerTransformLocked(layer)) {
      showAppToast(
        'msg_layer_locked_action'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    editor.removeLayer(layer);
    if (!context.mounted) return;
    context.read<AddNewBloc>().add(EditorClearSelectionEvent());
  }

  void _layerMenuToggleLock(ProImageEditorState editor, String layerId) {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return;
    _editorToggleLayerTransformLock(editor, layer);
  }

  /// Keeps the bloc's selection in sync after the menu adds a layer.
  void _syncEditorSelection(BuildContext context, Layer layer) {
    if (!context.mounted) return;
    context.read<AddNewBloc>().add(
      EditorSelectionChangedEvent(
        selectedElementId: layer.id,
        selectedElementType: layer is TextLayer ? 'text' : 'image',
      ),
    );
  }

  /// Writes [mutate] into the layer's meta as a single history entry.
  bool _layerMenuMutateMeta(
    ProImageEditorState editor,
    String layerId,
    void Function(Map<String, dynamic> meta) mutate,
  ) {
    final layers = List<Layer>.from(editor.activeLayers);
    final index = layers.indexWhere((l) => l.id == layerId);
    if (index < 0) return false;

    final target = layers[index];
    final meta = Map<String, dynamic>.from(target.meta ?? <String, dynamic>{});
    mutate(meta);
    target.meta = meta;

    editor.addHistory(layers: layers);
    editor.layerInteractionManager.selectedLayerId = layerId;
    editor.setState(() {});
    return true;
  }

  Future<void> _layerMenuEditLink(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) async {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return;

    final edit = await showMusamiLayerLinkSheet(
      context: context,
      initialValue: musamiLayerLink(layer),
    );
    if (edit.result == MusamiLayerMetaResult.cancelled) return;

    final removing = edit.result == MusamiLayerMetaResult.removed;
    final saved = _layerMenuMutateMeta(editor, layerId, (meta) {
      if (removing) {
        meta.remove(kMusamiLayerLinkMetaKey);
      } else {
        meta[kMusamiLayerLinkMetaKey] = musamiNormalizeLayerLink(edit.value);
      }
    });
    if (!saved) return;
    showAppToast(
      removing ? 'msg_layer_link_removed'.tr : 'msg_layer_link_saved'.tr,
      type: ToastificationType.success,
    );
  }

  Future<void> _layerMenuEditAltText(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) async {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return;

    final edit = await showMusamiLayerAltTextSheet(
      context: context,
      initialValue: musamiLayerAltText(layer),
    );
    if (edit.result == MusamiLayerMetaResult.cancelled) return;

    final removing = edit.result == MusamiLayerMetaResult.removed;
    final saved = _layerMenuMutateMeta(editor, layerId, (meta) {
      if (removing) {
        meta.remove(kMusamiLayerAltTextMetaKey);
      } else {
        meta[kMusamiLayerAltTextMetaKey] = edit.value;
      }
    });
    if (!saved) return;
    showAppToast(
      removing
          ? 'msg_layer_alt_text_removed'.tr
          : 'msg_layer_alt_text_saved'.tr,
      type: ToastificationType.success,
    );
  }

  /// Source pixels behind an image layer, used for background + palette.
  Future<Uint8List?> _layerMenuSourceBytes(WidgetLayer layer) {
    return musamiResolveRasterBytesForBackgroundRemoval(layer.widget);
  }

  Future<void> _layerMenuSetAsBackground(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) async {
    if (_layerMenuBusy) return;
    final layer = _editorFindLayer(editor, layerId);
    if (layer is! WidgetLayer) return;

    final bloc = context.read<AddNewBloc>();
    final canvas = Size(
      bloc.state.selectedwidth ?? widget.width ?? 1080,
      bloc.state.selectedheight ?? widget.height ?? 1080,
    );

    _layerMenuBusy = true;
    LoadingDialog.instance.show(context, configs: editor.configs);
    await WidgetsBinding.instance.endOfFrame;
    Uint8List? background;
    try {
      final source = await _layerMenuSourceBytes(layer);
      if (source != null && source.isNotEmpty) {
        background = await musamiRenderCoverBackgroundAsync(
          imageBytes: source,
          canvasSize: canvas,
        );
      }
    } finally {
      LoadingDialog.instance.hide();
      _layerMenuBusy = false;
    }

    if (!context.mounted) return;
    if (background == null || background.isEmpty) {
      showAppToast(
        'msg_layer_background_failed'.tr,
        type: ToastificationType.warning,
      );
      return;
    }

    // Remove the layer first so the picture is not shown twice, then swap the
    // page background.
    editor.removeLayer(layer);
    bloc
      ..add(EditorClearSelectionEvent())
      ..add(SetBackgroundImageEvent(imageBytes: background));
    showAppToast(
      'msg_layer_background_applied'.tr,
      type: ToastificationType.success,
    );
  }

  Future<void> _layerMenuApplyColors(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) async {
    if (_layerMenuBusy) return;
    final layer = _editorFindLayer(editor, layerId);
    if (layer is! WidgetLayer) return;

    _layerMenuBusy = true;
    LoadingDialog.instance.show(context, configs: editor.configs);
    await WidgetsBinding.instance.endOfFrame;
    List<Color> palette = const <Color>[];
    try {
      final source = await _layerMenuSourceBytes(layer);
      if (source != null && source.isNotEmpty) {
        palette = await musamiExtractDominantColorsAsync(source);
      }
    } finally {
      LoadingDialog.instance.hide();
      _layerMenuBusy = false;
    }

    if (!context.mounted) return;
    if (palette.isEmpty) {
      showAppToast('msg_layer_no_colors'.tr, type: ToastificationType.warning);
      return;
    }

    final picked = await showMusamiPagePaletteSheet(
      context: context,
      colors: palette,
    );
    if (picked == null || !context.mounted) return;
    context.read<AddNewBloc>().add(SetBgColorEvent(color: picked));
  }

  Future<void> _layerMenuDownload(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) async {
    if (_layerMenuBusy) return;
    final layer = _editorFindLayer(editor, layerId);
    if (layer is! WidgetLayer) return;

    // No loading overlay here: the capture mounts its own overlay entry, and an
    // opaque entry stacked above it would stop that entry from painting.
    _layerMenuBusy = true;
    Uint8List? bytes;
    try {
      // Capture the layer's own widget: the selection border and handles live
      // in the editor overlay, not in the layer, so they cannot leak in.
      bytes = await musamiCaptureWidgetPng(
        context: context,
        content: layer.widget,
        logicalSize: musamiEstimateLayerPaintSize(layer, editor),
      );
    } finally {
      _layerMenuBusy = false;
    }

    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        'msg_layer_download_failed'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    await saveExportedDesignToGallery(
      context,
      bytes: bytes,
      exportFileType: DesignExportFileType.png,
      preferredBaseName: 'musamimuk-selection',
    );
  }

  Future<void> _layerMenuShowInfo(
    BuildContext context,
    ProImageEditorState editor,
    String layerId,
  ) {
    final layer = _editorFindLayer(editor, layerId);
    if (layer == null) return Future<void>.value();
    return showMusamiLayerInfoSheet(
      context: context,
      entries: _buildLayerInfoEntries(editor, layer),
    );
  }

  /// Reports FRAME size and IMAGE size separately: with the crop-based resize
  /// model the two are independent, and conflating them would be misleading.
  List<MusamiLayerInfoEntry> _buildLayerInfoEntries(
    ProImageEditorState editor,
    Layer layer,
  ) {
    String number(double value) => value.toStringAsFixed(
      value.abs() >= 100 || value == value.roundToDouble() ? 0 : 1,
    );

    final entries = <MusamiLayerInfoEntry>[];

    if (layer is WidgetLayer) {
      final frame = musamiEstimateLayerPaintSize(layer, editor);
      final frameAspect = musamiSanitizedLayerAspect(
        musamiWidgetLayerAspect(layer),
      );
      final imageAspect = musamiWidgetLayerImageAspect(layer);
      final kind = layer.meta?['musamiLayerKind']?.toString();

      entries.add(
        MusamiLayerInfoEntry(
          'lbl_layer_info_type'.tr,
          kind == null || kind.isEmpty ? 'lbl_layer_type_other'.tr : kind,
        ),
      );
      entries.add(
        MusamiLayerInfoEntry(
          'lbl_layer_info_frame_size'.tr,
          '${number(frame.width)} × ${number(frame.height)} px',
        ),
      );
      entries.add(
        MusamiLayerInfoEntry(
          'lbl_layer_info_frame_ratio'.tr,
          (1 / frameAspect).toStringAsFixed(3),
        ),
      );
      entries.add(
        MusamiLayerInfoEntry(
          'lbl_layer_info_image_ratio'.tr,
          (1 / imageAspect).toStringAsFixed(3),
        ),
      );
      final url = musamiLayerFileUrl(layer);
      if (url != null && url.isNotEmpty) {
        entries.add(MusamiLayerInfoEntry('lbl_layer_info_source'.tr, url));
      }
    } else if (layer is TextLayer) {
      entries.add(
        MusamiLayerInfoEntry(
          'lbl_layer_info_type'.tr,
          'lbl_layer_type_text'.tr,
        ),
      );
      entries.add(
        MusamiLayerInfoEntry('lbl_layer_info_text'.tr, layer.text),
      );
    }

    entries.add(
      MusamiLayerInfoEntry(
        'lbl_layer_info_position'.tr,
        '${number(layer.offset.dx)}, ${number(layer.offset.dy)}',
      ),
    );
    entries.add(
      MusamiLayerInfoEntry(
        'lbl_layer_info_rotation'.tr,
        '${number(layer.rotation * 180 / math.pi)}°',
      ),
    );
    entries.add(
      MusamiLayerInfoEntry(
        'lbl_layer_info_scale'.tr,
        '${layer.scale.toStringAsFixed(2)}×',
      ),
    );
    entries.add(
      MusamiLayerInfoEntry(
        'lbl_layer_info_locked'.tr,
        _editorLayerTransformLocked(layer) ? 'lbl_yes'.tr : 'lbl_no'.tr,
      ),
    );

    final link = musamiLayerLink(layer);
    if (link != null) {
      entries.add(MusamiLayerInfoEntry('lbl_layer_info_link'.tr, link));
    }
    final altText = musamiLayerAltText(layer);
    if (altText != null) {
      entries.add(MusamiLayerInfoEntry('lbl_layer_info_alt_text'.tr, altText));
    }
    return entries;
  }

  Future<void> _runEditorBackgroundRemoval({
    required BuildContext context,
    required ProImageEditorState editor,
    required WidgetLayer layer,
  }) async {
    if (_backgroundRemovalController.isBusy) return;

    final allowed = await ensureCanSpendCoins(
      context: context,
      feature: WalletFeatureCost.removeBackground,
    );
    if (!allowed || !context.mounted) return;

    final bytes = await musamiResolveRasterBytesForBackgroundRemoval(
      layer.widget,
    );
    if (!context.mounted) return;

    if (bytes == null || bytes.isEmpty) {
      showAppToast(
        'msg_background_removal_unsupported_image'.tr,
        type: ToastificationType.warning,
      );
      return;
    }

    final networkUrl = musamiTryExtractNetworkImageUrl(layer.widget);
    final sourceFilename = networkUrl != null
        ? Uri.tryParse(networkUrl)?.pathSegments.lastOrNull
        : null;

    BackgroundRemovalLoadingDialog.show(
      context,
      previewBytes: bytes,
      controller: _backgroundRemovalController,
    );
    await WidgetsBinding.instance.endOfFrame;

    Uint8List? resultBytes;
    try {
      resultBytes = await _backgroundRemovalController.removeBackground(
        bytes,
        sourceFilename: sourceFilename,
      );
    } finally {
      if (context.mounted) {
        BackgroundRemovalLoadingDialog.hide(context);
      }
    }
    if (!context.mounted) return;

    if (resultBytes != null) {
      await _applyBackgroundRemovedToWidgetLayer(
        context: context,
        editor: editor,
        layer: layer,
        bytes: resultBytes,
      );
      if (!context.mounted) return;
      context.read<WalletBloc>().add(const WalletRefreshEvent());
      showAppToast(
        'msg_bg_removal_success'.tr,
        type: ToastificationType.success,
      );
      _backgroundRemovalController.reset();
      return;
    }

    final errorMessage = _localizedBackgroundRemovalError(
      _backgroundRemovalController.state,
    );
    showAppToast(errorMessage, type: ToastificationType.error);
    _backgroundRemovalController.reset();
  }

  Future<void> _applyRasterBytesToWidgetLayer({
    required BuildContext context,
    required ProImageEditorState editor,
    required WidgetLayer layer,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty || !context.mounted) return;

    final tuneItems = musamiTuneItemsFromEditor(editor);
    final decodedSize = await _decodeImageSize(bytes);
    if (!context.mounted) return;

    final provider = MemoryImage(bytes);
    await precacheImage(provider, context);
    if (!context.mounted) return;

    final meta = layer.meta == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(layer.meta!);
    meta.removeWhere((k, _) => musamiIsCropMetaKey(k));
    if (decodedSize.width > 0 && decodedSize.height > 0) {
      final decoded = decodedSize.height / decodedSize.width;
      meta[kMusamiFrameAspectMetaKey] = decoded;
      meta[kMusamiImageAspectMetaKey] = decoded;
    }

    final newCore = _buildGalleryStickerWidget(
      context,
      image: provider,
      width: decodedSize.width,
      height: decodedSize.height,
    );

    final preliminary = layer.copyWith(
      widget: newCore,
      width: decodedSize.width,
      meta: meta,
    );
    final updated = musamiRebuildWidgetLayerVisuals(
      preliminary,
      meta,
      tuneAdjustmentItems: tuneItems,
    );

    final idx = editor.activeLayers.indexWhere((l) => l.id == layer.id);
    if (idx >= 0) {
      editor.replaceLayer(index: idx, layer: updated);
      editor.layerInteractionManager.selectedLayerId = updated.id;
      editor.setState(() {});
    }
  }

  Widget _buildImageContextBottomBar(BuildContext context, AddNewState state) {
    final editor = state.editorKey?.currentState;
    if (editor == null) return const SizedBox.shrink();

    final selectedId = state.selectedElementId;
    if (selectedId != null) {
      final layer = _editorFindLayer(editor, selectedId);
      if (layer != null && _editorLayerInteractionBlocked(layer)) {
        return const SizedBox.shrink();
      }
    }

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
        exportConfigs: layer.exportConfigs,
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
              width: decodedSize.width,
              scale: layer.scale,
              widget: _buildGalleryStickerWidget(
                context,
                image: imageProvider,
                width: decodedSize.width,
                height: decodedSize.height,
              ),
              meta: <String, dynamic>{
                'musamiLayerKind': 'gallery',
                if (decodedSize.width > 0)
                  'musamiAspect': decodedSize.height / decodedSize.width,
              },
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

                  void pickCustomColor() {
                    musamiShowLayerTextColorPicker(
                      ctx2,
                      title: 'lbl_border_color'.tr,
                      initialColor: bc,
                      onColorChanged: (c) {
                        setState(() {
                          bc = c;
                          if (bw <= 0.05) bw = 2.0;
                        });
                        applyToEditor();
                      },
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'lbl_borders'.tr,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'lbl_border_color'.tr,
                          style: AppDs.sheetCaption(
                            sheetTheme,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDs.space2.v),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final c in presets)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  bc = c;
                                  if (bw <= 0.05) bw = 2.0;
                                });
                                applyToEditor();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: musamiColorToArgb32(bc) ==
                                            musamiColorToArgb32(c)
                                        ? sheetTheme.colorScheme.primary
                                        : Colors.white24,
                                    width: musamiColorToArgb32(bc) ==
                                            musamiColorToArgb32(c)
                                        ? 3
                                        : 1,
                                  ),
                                ),
                              ),
                            ),
                          InkWell(
                            onTap: pickCustomColor,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFFFF0000),
                                    Color(0xFFFFFF00),
                                    Color(0xFF00FF00),
                                    Color(0xFF00FFFF),
                                    Color(0xFF0000FF),
                                    Color(0xFFFF00FF),
                                    Color(0xFFFF0000),
                                  ],
                                ),
                                border: Border.all(
                                  color: sheetTheme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.colorize_rounded,
                                size: 16,
                                color: Colors.white,
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
      final dx0 = (m['musamiShadowDx'] as num?)?.toDouble() ?? 0;
      final dy0 = (m['musamiShadowDy'] as num?)?.toDouble() ?? 8;
      final st0 = (m['musamiShadowStrength'] as num?)?.toDouble() ?? 0.35;

      showAppModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final sheetTheme = Theme.of(ctx);
          double blur = blur0;
          double dx = dx0;
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
                      meta.remove('musamiShadowDx');
                      meta.remove('musamiShadowDy');
                      meta.remove('musamiShadowStrength');
                    } else {
                      meta['musamiShadowBlur'] = blur;
                      meta['musamiShadowDx'] = dx;
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
                        label: blur <= 0.05
                            ? 'Off'
                            : '${blur.toStringAsFixed(0)} px',
                        onChanged: (nv) {
                          setState(() => blur = nv);
                          applyToEditor();
                        },
                      ),
                      Text(
                        'lbl_shadow_offset_x'.tr,
                        style: sheetTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Slider(
                        value: dx.clamp(-32, 32),
                        min: -32,
                        max: 32,
                        divisions: 64,
                        label: '${dx.toStringAsFixed(0)} px',
                        onChanged: (nv) {
                          setState(() => dx = nv);
                          applyToEditor();
                        },
                      ),
                      Text(
                        'lbl_shadow_offset_y'.tr,
                        style: sheetTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Slider(
                        value: dy.clamp(-32, 32),
                        min: -32,
                        max: 32,
                        divisions: 64,
                        label: '${dy.toStringAsFixed(0)} px',
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

    void pickImageLayerTintColor() {
      final layer = selectedWidgetLayer();
      if (layer == null) return;
      final meta0 = layer.meta == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(layer.meta!);
      final existingArgb = meta0[kMusamiImageTintArgbMetaKey] as int?;
      final initial = existingArgb != null
          ? musamiColorFromArgb32(existingArgb)
          : Colors.white;

      musamiShowLayerTextColorPicker(
        context,
        title: 'lbl_pick_image_color'.tr,
        initialColor: initial,
        enableAlpha: true,
        onColorChanged: (c) {
          final current = selectedWidgetLayer();
          if (current == null) return;
          final meta = current.meta == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(current.meta!);
          final allowWhite = musamiLayerUsesSilhouetteTint(meta);
          final argb = musamiColorToArgb32(c);
          if (!musamiLayerImageTintAppliesFilterArgb(
            argb,
            allowWhite: allowWhite,
          )) {
            meta.remove(kMusamiImageTintArgbMetaKey);
          } else {
            meta[kMusamiImageTintArgbMetaKey] = argb;
          }
          final updated = musamiRebuildWidgetLayerVisuals(
            current,
            meta,
            tuneAdjustmentItems: musamiTuneItemsFromEditor(editor),
          );
          final idx = editor.activeLayers.indexWhere((l) => l.id == current.id);
          if (idx >= 0) {
            editor.replaceLayer(index: idx, layer: updated);
            editor.layerInteractionManager.selectedLayerId = updated.id;
            editor.setState(() {});
          }
        },
      );
    }

    final selectedForCrop = selectedWidgetLayer();
    final supportsClip =
        selectedForCrop != null &&
        musamiLayerSupportsClippingMaskAction(selectedForCrop);
    final clipActive =
        selectedForCrop != null &&
        musamiLayerHasActiveClippingMask(selectedForCrop.meta);

    return ImageContextToolbar(
      theme: Theme.of(context),
      secondaryPanel: state.imageContextSecondaryPanel,
      onDeselect: deselect,
      onDelete: delete,
      onResize: showResizeSheet,
      onCrop:
          selectedForCrop != null &&
              musamiWidgetLayerHasRasterCropSource(selectedForCrop.widget)
          ? () => _openWidgetLayerCropRaster(context, editor, selectedForCrop)
          : null,
      onBorder: showBorderSheet,
      onShadow: showShadowSheet,
      onDuplicate: duplicate,
      onOpacity: showOpacitySheet,
      onClippingMask: supportsClip
          ? () {
              final layer = selectedWidgetLayer();
              if (layer == null) return;
              final ok = musamiLayerHasActiveClippingMask(layer.meta)
                  ? musamiReleaseClippingMask(
                      editor: editor,
                      clipped: layer,
                      rebuildVisuals: (content, meta) =>
                          musamiRebuildWidgetLayerVisuals(
                        content,
                        meta,
                        tuneAdjustmentItems:
                            musamiTuneItemsFromEditor(editor),
                      ),
                    )
                  : musamiApplyShapeClippingMask(
                      editor: editor,
                      shape: layer,
                      rebuildVisuals: (content, meta) =>
                          musamiRebuildWidgetLayerVisuals(
                        content,
                        meta,
                        tuneAdjustmentItems:
                            musamiTuneItemsFromEditor(editor),
                      ),
                    );
              if (!ok) {
                showAppToast(
                  musamiLayerHasActiveClippingMask(layer.meta)
                      ? 'msg_clipping_mask_release_failed'.tr
                      : 'msg_clipping_mask_need_content'.tr,
                );
              }
            }
          : null,
      clippingMaskActive: clipActive,
      onReplace: () => replace(),
      onAiRemoveBg: () {
        final layer = selectedForCrop;
        if (layer == null) return;
        _runEditorBackgroundRemoval(
          context: context,
          editor: editor,
          layer: layer,
        );
      },
      onColor: pickImageLayerTintColor,
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

  Widget _buildEditorWithTransparencyPreview({
    required BuildContext context,
    required AddNewState state,
    required double width,
    required double height,
  }) {
    final editor = ProImageEditor.memory(
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
          final wi = w.toInt();
          final hi = h.toInt();
          final destination = await showDesignSaveDestinationSheet(context);
          if (!context.mounted) return;
          switch (destination) {
            case null:
              return;
            case DesignSaveDestination.workspace:
              await _runPostExportSavePipeline(
                context: context,
                imageBytes: bytes,
                width: wi,
                height: hi,
              );
            case DesignSaveDestination.gallery:
              await _runGalleryOnlyRasterExport(
                context: context,
                imageBytes: bytes,
                width: wi,
                height: hi,
              );
            case DesignSaveDestination.share:
              await _runShareExportedRaster(
                context: context,
                imageBytes: bytes,
                width: wi,
                height: hi,
              );
          }
        },
        mainEditorCallbacks: MainEditorCallbacks(
          onAfterViewInit: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _syncCanvasZoomInteraction(
                context.read<AddNewBloc>().state.canvasLocked,
              );
            });
          },
          onSelectedLayerChanged: (id) {
            final editor = state.editorKey?.currentState;
            if (editor == null) return;
            final selectedId = id.trim();
            if (selectedId.isEmpty) {
              // replaceLayer() briefly clears selection before it is restored;
              // keep the adjust panel open during that transient state.
              if (context.read<AddNewBloc>().state.imageContextSecondaryPanel ==
                  'adjust') {
                return;
              }
              context.read<AddNewBloc>().add(EditorClearSelectionEvent());
              return;
            }
            final Layer? layer = editor.activeLayers.cast<Layer?>().firstWhere(
              (l) => l?.id == selectedId,
              orElse: () => null,
            );
            if (layer != null && _editorLayerInteractionBlocked(layer)) {
              editor.layerInteractionManager.removeSelectedLayer(selectedId);
              context.read<AddNewBloc>().add(EditorClearSelectionEvent());
              return;
            }
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
            _scheduleAutoSave();
          },
          onLayerTapDown: (layer) {
            if (_editorLayerInteractionBlocked(layer)) return;
            _scheduleAutoSave();
          },
          onLayerTapUp: (layer) {
            if (_editorLayerInteractionBlocked(layer)) return;
            if (layer is! TextLayer) return;
            final editor = state.editorKey?.currentState;
            if (editor == null) return;

            final isDoubleTap = _isDoubleTapOnSameLayer(layer.id);

            if (!isDoubleTap) return;
            editor.editTextLayer(layer);
          },
          onImportHistoryEnd: (editor, _) {
            _restoreImportedWidgetLayerVisuals(editor);
            _ensureImportedLayersSelectable(editor);
            if (context.mounted) {
              context.read<AddNewBloc>().add(ClearPendingDesignHistoryEvent());
            }
          },
        ),
      ),
      configs: _musamiProImageEditorConfigs(context, state),
    );
    return editor;
  }

  /// Re-applies saved visual meta to [WidgetLayer]s after a state-history import.
  ///
  /// Import rebuilds [WidgetLayer.widget] as a bare image (network url /
  /// widget-record raster), which drops the [musamiComposeImageLayerVisualCore]
  /// wrappers — so reopened designs lost user tint (e.g. recoloured shapes),
  /// tune, border, shadow and opacity. [Layer.meta] survives export/import,
  /// so rebuild the compose shell from it, exactly like the live editor does.
  void _restoreImportedWidgetLayerVisuals(ProImageEditorState editor) {
    final tuneItems = musamiTuneItemsFromEditor(editor);
    for (final layer in editor.activeLayers) {
      if (layer is! WidgetLayer) continue;
      final meta = layer.meta;
      if (meta == null || meta.isEmpty) continue;

      // Import rebuilds the widget as a bare image, which would fall back to
      // the image's own ratio. Re-apply the saved frame so a cropped/reshaped
      // layer reopens exactly as it was saved.
      var core = _unwrapMusamiWidgetLayerBareCore(layer.widget);
      final frameAspect = (meta[kMusamiFrameAspectMetaKey] as num?)?.toDouble();
      if (frameAspect != null && frameAspect.isFinite && frameAspect > 0) {
        core = musamiFrameWidgetLayerCore(
          musamiUnwrapLayerFrameBox(core),
          width: layer.width ?? editor.configs.stickerEditor.initWidth,
          aspect: frameAspect,
          cropAlignment: musamiLayerCropAlignment(meta),
        );
      }

      final styled = musamiComposeImageLayerVisualCore(
        core,
        meta,
        tuneAdjustmentItems: tuneItems,
      );
      final opacity =
          (meta['musamiOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0;
      layer.widget = Opacity(opacity: opacity, child: styled);
    }
  }

  /// Restores selection/transform for layers that were not intentionally locked.
  void _ensureImportedLayersSelectable(ProImageEditorState editor) {
    for (final layer in editor.activeLayers) {
      if (_editorLayerTransformLocked(layer)) continue;
      layer.interaction = layer.interaction.copyWith(
        enableMove: true,
        enableScale: true,
        enableRotate: true,
        enableSelection: true,
        enableEdit: _editorDefaultEnableEditForLayer(layer),
      );
    }
    editor.setState(() {});
  }

  /// Workspace surround behind the paper.
  ///
  /// Solid dark by default. Soft transparency grid only when Transparent BG is on.
  Widget _musamiEditorWorkspaceBackground({
    required Widget child,
    required bool showTransparencyPreview,
  }) {
    if (!showTransparencyPreview) {
      return ColoredBox(
        color: AppDs.surfaceBase,
        child: SizedBox.expand(child: child),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(
          painter: _SoftTransparencyGridPainter(cellSize: 14),
          child: SizedBox.expand(),
        ),
        Positioned(
          left: 12.h,
          bottom: 12.v,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
                border: Border.all(
                  color: AppDs.accentYellow.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.v),
                child: Text(
                  'msg_transparent_bg_on'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox.expand(child: child),
      ],
    );
  }

  ProImageEditorConfigs _musamiProImageEditorConfigs(
    BuildContext context,
    AddNewState state,
  ) {
    final theme = Theme.of(context);
    final lang = appLocaleNotifier.languageCode;
    final initialRtl = lang == 'ar' || lang == 'ur';
    final redesignImport = musamiTryParseDesignImportHistory(
      state.pendingDesignHistoryJson,
    );

    return ProImageEditorConfigs(
      i18n: I18n(
        doneLoadingMsg: 'msg_saving_your_design'.tr,
        importStateHistoryMsg: redesignImport != null
            ? 'msg_importing_design_layers'.tr
            : '',
        textEditor: I18nTextEditor(
          inputHintText: 'lbl_text_editor_hint_ltr'.tr,
        ),
      ),
      stateHistory: StateHistoryConfigs(initStateHistory: redesignImport),
      imageGeneration: redesignImport != null
          ? const ImageGenerationConfigs(enableUseOriginalBytes: false)
          : const ImageGenerationConfigs(),
      mainEditor: MainEditorConfigs(
        enableCloseButton: false,
        // Required so [doneEditing] calls [onImageEditingComplete] with captured bytes.
        captureImageOnDone: true,
        // Hide ProImageEditor built-in bottom toolbar (paint/crop/tune/filter/blur/etc.)
        // because we render our own "Add New Design" tool grid.
        tools: const [],
        // Always keep zoom enabled so the InteractiveViewer stays mounted and
        // the current scale/offset survive lock toggles. Gestures are gated via
        // [ExtendedInteractiveViewerState.setEnableInteraction] instead.
        enableZoom: true,
        editorMinScale: 0.25,
        editorMaxScale: 4,
        enableDoubleTapZoom: !state.canvasLocked,
        boundaryMargin: const EdgeInsets.all(80),
        mobilePanInteraction: state.canvasLocked
            ? MobilePanInteraction.none
            : MobilePanInteraction.move,
        // Outer [SafeArea] + scaffold [bottomNavigationBar] already handle insets.
        safeArea: const EditorSafeArea(
          top: false,
          bottom: false,
          left: false,
          right: false,
        ),
        widgets: MainEditorWidgets(
          appBar: (editor, rebuildStream) {
            final topPad = MediaQuery.paddingOf(context).top;
            return ReactiveAppbar(
              stream: rebuildStream,
              appbarSize: Size.fromHeight(musamiEditorAppBarHeight(topPad)),
              builder: (ctx) => _buildSimplifiedEditorAppBar(ctx, editor),
            );
          },
          // Built-in bottom bar still reserves ~56px even when [tools] is empty.
          bottomBar: (editor, rebuildStream, key) {
            return ReactiveWidget(
              stream: rebuildStream,
              builder: (_) => SizedBox(key: key, height: 0),
            );
          },
          wrapBody: (editor, rebuildStream, content) {
            return ReactiveWidget(
              stream: rebuildStream,
              builder: (_) => BlocBuilder<AddNewBloc, AddNewState>(
                buildWhen: (prev, next) =>
                    prev.isBackgroundTransparent !=
                    next.isBackgroundTransparent,
                builder: (context, editorState) =>
                    _musamiEditorWorkspaceBackground(
                      showTransparencyPreview:
                          editorState.isBackgroundTransparent,
                      child: content,
                    ),
              ),
            );
          },
          // AI command bar is hosted in the Scaffold Stack (not bodyItems)
          // so ProImageEditor's translucent GestureDetector cannot steal taps.
        ),
        // Opaque mask over the outside-canvas region so layers cannot paint
        // onto the dark chrome (package layers use Clip.none).
        style: MainEditorStyle(
          background: AppDs.surfaceBase,
          outsideCaptureAreaLayerOpacity: 1.0,
        ),
      ),
      layerInteraction: LayerInteractionConfigs(
        // On mobile, default "auto" makes layers NOT selectable, which causes
        // single-tap to edit text layers. Force selectable so single-tap selects.
        selectable: LayerInteractionSelectable.enabled,
        // Route two-finger pinches to canvas zoom (gesture-centered) instead of
        // scaling/rotating the selected layer. Layer resize uses custom overlays.
        enableMobilePinchScale: false,
        enableMobilePinchRotate: false,
        style: LayerInteractionStyle(
          borderColor: theme.colorScheme.primary,
          strokeWidth: 1.5,
          // Slight padding improves grab / drag for small stickers & shapes.
          overlayPadding: const EdgeInsets.all(12),
        ),
        widgets: LayerInteractionWidgets(
          // Disable the built-in edit button so single-tap won't open edit.
          // Editing is triggered by double-tap on the layer.
          editButton: (rebuildStream, onTap, rotation) => ReactiveWidget(
            stream: rebuildStream,
            builder: (_) => const SizedBox.shrink(),
          ),
          rotateScaleButton:
              (rebuildStream, onScaleRotateDown, onScaleRotateUp, rotation) =>
                  ReactiveWidget(
                    stream: rebuildStream,
                    builder: (_) => const SizedBox.shrink(),
                  ),
          overlayChildBuilder: (rebuildStream, info, layer, interactions) {
            final strokeColor = theme.colorScheme.primary;
            final editorKey = state.editorKey!;
            final editor = editorKey.currentState;
            final canvasBodySize = editor?.sizesManager.bodySize ?? Size.zero;
            final quickBarActions = _buildLayerQuickBarActions(
              screenContext: context,
              editorKey: editorKey,
              layer: layer,
            );
            if (layer is TextLayer &&
                layer.interaction.enableScale &&
                layer.meta?[kMusamiLayerLockedMetaKey] != true) {
              return ReactiveWidget(
                stream: rebuildStream,
                builder: (_) => _wrapLayerSelectionChrome(
                  info: info,
                  layer: layer,
                  canvasBodySize: canvasBodySize,
                  actions: quickBarActions,
                  selectionOverlay: MusamiTextLayerTransformOverlay(
                    info: info,
                    layer: layer,
                    editorKey: editorKey,
                    strokeColor: strokeColor,
                  ),
                ),
              );
            }
            if (layer is WidgetLayer &&
                layer.interaction.enableScale &&
                layer.meta?[kMusamiLayerLockedMetaKey] != true) {
              return ReactiveWidget(
                stream: rebuildStream,
                builder: (_) => _wrapLayerSelectionChrome(
                  info: info,
                  layer: layer,
                  canvasBodySize: canvasBodySize,
                  actions: quickBarActions,
                  selectionOverlay: MusamiWidgetLayerTransformOverlay(
                    key: ValueKey(layer.id),
                    info: info,
                    layer: layer,
                    editorKey: editorKey,
                    strokeColor: strokeColor,
                    onApplyGeometry:
                        (
                          updatedLayer, {
                          required width,
                          required aspect,
                          required scale,
                          required offset,
                        }) {
                          final ed = editorKey.currentState;
                          if (ed == null) return;
                          musamiMutateWidgetLayerGeometry(
                            ed,
                            updatedLayer,
                            width: width,
                            aspect: aspect,
                            scale: scale,
                            offset: offset,
                          );
                        },
                  ),
                ),
              );
            }
            return ReactiveWidget(
              stream: rebuildStream,
              builder: (_) => _wrapLayerSelectionChrome(
                info: info,
                layer: layer,
                canvasBodySize: canvasBodySize,
                actions: quickBarActions,
                selectionOverlay: MusamiDefaultLayerTransformOverlay(
                  info: info,
                  layer: layer,
                  interactions: interactions,
                  strokeColor: strokeColor,
                ),
              ),
            );
          },
        ),
      ),
      stickerEditor: StickerEditorConfigs(builder: _buildStickerSelector),
      textEditor: TextEditorConfigs(
        initFontSize: 32,
        // RTL/LTR script mode is app-managed via align (pub.dev has no
        // initialInputTextDirection / setInputTextDirection).
        initialTextAlign: initialRtl ? TextAlign.right : TextAlign.left,
        // Near-black so new text is visible on the white page canvas.
        // Input field background is light (below) so typing stays readable.
        initialPrimaryColor: const Color(0xFF111111),
        initialSecondaryColor: const Color(0x00000000),
        // White input on dark editor chrome; no box fill by default.
        initialBackgroundColorMode: LayerBackgroundMode.onlyColor,
        enableTapOutsideToSave: false,
        showTextAlignButton: false,
        showFontScaleButton: false,
        showBackgroundModeButton: false,
        inputTextFieldAlign: Alignment.center,
        enableAutoOverflow: true,
        resizeToAvoidBottomInset: true,
        style: TextEditorStyle(
          background: appTheme.blueGray90004,
          appBarBackground: appTheme.blueGray90004,
          appBarColor: theme.colorScheme.onPrimary,
          inputHintColor: const Color(0xFF6B7280),
          inputTextFieldBackground: Colors.white,
          inputTextFieldBorderColor: theme.colorScheme.primary.withValues(
            alpha: 0.4,
          ),
          inputTextFieldBorderRadius: BorderRadius.circular(16.adaptSize),
          inputTextFieldPadding: EdgeInsets.symmetric(
            horizontal: 18.h,
            vertical: 22.v,
          ),
          textFieldPadding: EdgeInsets.symmetric(horizontal: 16.h),
          textFieldMargin: EdgeInsets.only(bottom: 200.v),
          inputCursorColor: theme.colorScheme.primary,
          textHeight: 1.35,
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
        style: PaintEditorStyle(
          background: state.isBackgroundTransparent
              ? Colors.transparent
              : const Color(0xFF161616),
        ),
        tools: const [
          PaintMode.freeStyle,
          PaintMode.arrow,
          PaintMode.line,
          PaintMode.rect,
          PaintMode.circle,
          PaintMode.dashLine,
          PaintMode.dashDotLine,
          PaintMode.hexagon,
          PaintMode.polygon,
          PaintMode.pixelate,
          PaintMode.blur,
          PaintMode.eraser,
        ],
        widgets: PaintEditorWidgets(
          bottomBar: (editor, stream) =>
              musamiPaintEditorBottomBar(editor, stream),
        ),
      ),
      tuneEditor: TuneEditorConfigs(
        tuneAdjustmentOptions: musamiDefaultTuneAdjustmentItems(),
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
    final canvasLocked = context.select(
      (AddNewBloc b) => b.state.canvasLocked,
    );

    Layer? selectedLayer() {
      final id = selectedId;
      if (id == null || id.trim().isEmpty) return null;
      for (final l in editor.activeLayers) {
        if (l.id == id) return l;
      }
      return null;
    }

    final sel = selectedLayer();
    final topInset = MediaQuery.paddingOf(context).top;

    return PreferredSize(
      preferredSize: Size.fromHeight(musamiEditorAppBarHeight(topInset)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset),
          ColoredBox(
            color: primary,
            child: const SizedBox(height: kMusamiEditorAppBarAccentHeight),
          ),
          SizedBox(
            height: kMusamiEditorAppBarRowHeight,
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
                    onPressed: () {
                      _editorClearAllSelection(editor);
                      _scaffoldKey.currentState?.openDrawer();
                    },
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
                            icon: Icons.filter_center_focus,
                            label: 'lbl_editor_align'.tr,
                            onPressed:
                                sel != null &&
                                    !_editorLayerInteractionBlocked(sel)
                                ? () => showEditorAlignArrangeSheet(
                                    context: context,
                                    editor: editor,
                                    layer: sel,
                                  )
                                : null,
                            enabled:
                                sel != null &&
                                !_editorLayerInteractionBlocked(sel),
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
                          _editorTopBarLabeledAction(
                            icon: Icons.zoom_out_rounded,
                            label: 'lbl_zoom_out'.tr,
                            onPressed: canvasLocked
                                ? null
                                : () => _editorZoomBy(editor, 1 / 1.25),
                            enabled: !canvasLocked,
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.zoom_in_rounded,
                            label: 'lbl_zoom_in'.tr,
                            onPressed: canvasLocked
                                ? null
                                : () => _editorZoomBy(editor, 1.25),
                            enabled: !canvasLocked,
                          ),
                          _editorTopBarLabeledAction(
                            icon: Icons.fit_screen_rounded,
                            label: 'lbl_zoom_reset'.tr,
                            onPressed: canvasLocked
                                ? null
                                : () => editor.resetZoom(),
                            enabled: !canvasLocked,
                          ),
                          _editorTopBarLabeledAction(
                            icon: canvasLocked
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            label: canvasLocked
                                ? 'lbl_canvas_unlock'.tr
                                : 'lbl_canvas_lock'.tr,
                            onPressed: () {
                              context.read<AddNewBloc>().add(
                                ToggleCanvasLockEvent(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.h),
                    child: const CoinBalanceChip(
                      compact: true,
                      lightBackground: true,
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
    return layer.meta?[kMusamiLayerLockedMetaKey] == true;
  }

  /// True when the user must not select or edit this layer on the canvas.
  bool _editorLayerInteractionBlocked(Layer layer) {
    return _editorLayerTransformLocked(layer) || _editorLayerHidden(layer);
  }

  Layer? _editorFindLayer(ProImageEditorState editor, String id) {
    for (final layer in editor.activeLayers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  bool _editorDefaultEnableEditForLayer(Layer layer) {
    if (layer is WidgetLayer) {
      final kind = layer.meta?['musamiLayerKind']?.toString();
      // Stickers / gallery / AI images are transformable, not text-editable.
      if (kind == 'gallery' || kind == 'sticker' || kind == 'png') {
        return false;
      }
    }
    return true;
  }

  void _editorApplyLayerLock(Layer target, bool locked) {
    final meta = Map<String, dynamic>.from(target.meta ?? {});
    if (locked) {
      meta[kMusamiLayerLockedMetaKey] = true;
      target.interaction = target.interaction.copyWith(
        enableMove: false,
        enableScale: false,
        enableRotate: false,
        enableSelection: false,
        enableEdit: false,
      );
    } else {
      meta.remove(kMusamiLayerLockedMetaKey);
      target.interaction = target.interaction.copyWith(
        enableMove: true,
        enableScale: true,
        enableRotate: true,
        enableSelection: true,
        enableEdit: _editorDefaultEnableEditForLayer(target),
      );
    }
    target.meta = meta;
  }

  void _editorPurgeLockedLayersFromSelection(ProImageEditorState editor) {
    final mgr = editor.layerInteractionManager;
    final lockedIds = editor.activeLayers
        .where(_editorLayerTransformLocked)
        .map((layer) => layer.id)
        .toSet();
    if (lockedIds.isEmpty) return;

    final staleIds = mgr.selectedLayerIds
        .where((id) => lockedIds.contains(id))
        .toList(growable: false);
    if (staleIds.isEmpty) return;

    for (final id in staleIds) {
      mgr.removeSelectedLayer(id);
    }
    if (mgr.selectedLayerIds.isEmpty && mounted) {
      context.read<AddNewBloc>().add(EditorClearSelectionEvent());
    }
    editor.setState(() {});
  }

  void _editorClearLayerFromSelection(
    ProImageEditorState editor,
    String layerId,
  ) {
    final mgr = editor.layerInteractionManager;
    if (!mgr.selectedLayerIds.contains(layerId)) return;
    mgr.removeSelectedLayer(layerId);
    if (mgr.selectedLayerIds.isEmpty && mounted) {
      context.read<AddNewBloc>().add(EditorClearSelectionEvent());
    }
    editor.setState(() {});
  }

  void _editorClearAllSelection(ProImageEditorState editor) {
    final mgr = editor.layerInteractionManager;
    if (mgr.selectedLayerIds.isEmpty) return;
    mgr.clearSelectedLayers();
    if (mounted) {
      context.read<AddNewBloc>().add(EditorClearSelectionEvent());
    }
    editor.setState(() {});
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
    _editorApplyLayerLock(target, locked);
    _editorPurgeLockedLayersFromSelection(editor);
    if (locked) {
      _editorClearLayerFromSelection(editor, layer.id);
    }
    editor.addHistory(layers: list);
    editor.setState(() {});
  }

  void _editorToggleLayerHidden(ProImageEditorState editor, Layer layer) {
    final hidden = !_editorLayerHidden(layer);
    final list = List<Layer>.from(editor.activeLayers);
    final ti = list.indexWhere((l) => l.id == layer.id);
    if (ti < 0) return;
    final target = list[ti];
    target.meta = {...?target.meta, kMusamiLayerHiddenMetaKey: hidden};
    if (hidden) {
      _editorClearLayerFromSelection(editor, layer.id);
      target.interaction = target.interaction.copyWith(
        enableMove: false,
        enableScale: false,
        enableRotate: false,
        enableSelection: false,
        enableEdit: false,
      );
    } else if (!_editorLayerTransformLocked(target)) {
      target.interaction = target.interaction.copyWith(
        enableMove: true,
        enableScale: true,
        enableRotate: true,
        enableSelection: true,
        enableEdit: _editorDefaultEnableEditForLayer(target),
      );
    }
    if (target is WidgetLayer) {
      list[ti] = musamiRebuildWidgetLayerVisuals(
        target,
        Map<String, dynamic>.from(target.meta ?? {}),
        tuneAdjustmentItems: musamiTuneItemsFromEditor(editor),
      );
    }
    editor.addHistory(layers: list);
    editor.setState(() {});
  }

  void _editorToggleLockAllTransforms(ProImageEditorState editor) {
    final allLocked =
        editor.activeLayers.isNotEmpty &&
        editor.activeLayers.every(_editorLayerTransformLocked);
    final lockNow = !allLocked;
    final list = List<Layer>.from(editor.activeLayers);
    for (final layer in list) {
      _editorApplyLayerLock(layer, lockNow);
    }
    _editorPurgeLockedLayersFromSelection(editor);
    if (lockNow) {
      _editorClearAllSelection(editor);
    }
    editor.addHistory(layers: list);
    editor.setState(() {});
  }

  void _editorToggleHideAllLayers(ProImageEditorState editor) {
    final anyVisible = editor.activeLayers.any((l) => !_editorLayerHidden(l));
    final hide = anyVisible;
    final list = List<Layer>.from(editor.activeLayers);
    for (var i = 0; i < list.length; i++) {
      final layer = list[i];
      layer.meta = {...?layer.meta, kMusamiLayerHiddenMetaKey: hide};
      if (hide) {
        layer.interaction = layer.interaction.copyWith(
          enableMove: false,
          enableScale: false,
          enableRotate: false,
          enableSelection: false,
          enableEdit: false,
        );
      } else if (!_editorLayerTransformLocked(layer)) {
        layer.interaction = layer.interaction.copyWith(
          enableMove: true,
          enableScale: true,
          enableRotate: true,
          enableSelection: true,
          enableEdit: _editorDefaultEnableEditForLayer(layer),
        );
      }
      if (layer is WidgetLayer) {
        list[i] = musamiRebuildWidgetLayerVisuals(
          layer,
          Map<String, dynamic>.from(layer.meta ?? {}),
          tuneAdjustmentItems: musamiTuneItemsFromEditor(editor),
        );
      }
    }
    if (hide) {
      _editorClearAllSelection(editor);
    }
    editor.addHistory(layers: list);
    editor.setState(() {});
  }

  void _editorToggleSelectAllLayers(ProImageEditorState editor) {
    final unlockedIds = editor.activeLayers
        .where((layer) => !_editorLayerInteractionBlocked(layer))
        .map((layer) => layer.id)
        .toSet();
    final mgr = editor.layerInteractionManager;
    if (mgr.selectedLayerIds.length == unlockedIds.length &&
        unlockedIds.isNotEmpty) {
      mgr.clearSelectedLayers();
    } else {
      mgr.setSelectedLayers(unlockedIds);
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
                                  if (_editorLayerInteractionBlocked(layer)) {
                                    showAppToast('msg_layer_locked'.tr);
                                    return;
                                  }
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
                                        value:
                                            selected &&
                                            !_editorLayerInteractionBlocked(
                                              layer,
                                            ),
                                        onChanged:
                                            _editorLayerInteractionBlocked(
                                              layer,
                                            )
                                            ? null
                                            : (_) {
                                                final mgr = editor
                                                    .layerInteractionManager;
                                                if (selected) {
                                                  mgr.removeSelectedLayer(
                                                    layer.id,
                                                  );
                                                } else {
                                                  mgr.addSelectedLayer(
                                                    layer.id,
                                                  );
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

  /// Export finished → save dialog (name + visibility + format) → upload → success.
  Future<void> _runPostExportSavePipeline({
    required BuildContext context,
    required Uint8List imageBytes,
    required int width,
    required int height,
  }) async {
    if (_isSavingDesign) return;
    _isSavingDesign = true;
    try {
      if (!context.mounted) return;
      if (imageBytes.isEmpty) {
        showAppToast('msg_export_failed'.tr, type: ToastificationType.error);
        return;
      }

      // Pro Image Editor exportStateHistory → design_data for redesign.
      String? designData;
      final editor = context.read<AddNewBloc>().state.editorKey?.currentState;
      if (editor != null) {
        designData = await musamiExportDesignStateHistory(editor);
      }
      if (!context.mounted) return;

      final suggestedName = widget.presetName.trim().isNotEmpty
          ? widget.presetName.trim()
          : null;
      final form = await showDesignSaveFormDialog(
        context,
        initialWidth: width,
        initialHeight: height,
        suggestedName: suggestedName,
        showVisibility: true,
        showFileType: true,
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
        final assetIds = <String>{
          ...widget.generatedAssetIds,
          if (editor != null) ...EditorAiAssetRegistry.collect(editor),
        }.toList(growable: false);
        final repository = DesignRepository();
        if (widget.designId == null) {
          result = await repository.saveDesign(
            imageBytes: encoded,
            width: form.width,
            height: form.height,
            title: form.title,
            visibility: form.visibility,
            filename: form.fileType.uploadFilename,
            designData: designData,
            assetIds: assetIds,
          );
        } else {
          final update = await repository.update(
            id: widget.designId!,
            name: form.title.trim() == widget.presetName.trim()
                ? null
                : form.title,
            visibility: form.visibility == widget.designVisibility
                ? null
                : form.visibility,
            imageBytes: encoded,
            filename: form.fileType.uploadFilename,
            width: form.width,
            height: form.height,
            designData: designData,
            assetIds: assetIds,
          );
          result = switch (update) {
            DesignActionSuccess() => SaveDesignSuccess(
              id: widget.designId.toString(),
              width: form.width,
              height: form.height,
              title: form.title,
            ),
            DesignActionFailure(:final message) => SaveDesignFailure(message),
          };
        }
      } catch (_) {
        result = SaveDesignFailure('Unable to save design. Please try again.');
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      if (!context.mounted) return;

      switch (result) {
        case SaveDesignSuccess():
          final draftId = _localDraftId;
          if (draftId != null && draftId.isNotEmpty) {
            await LocalDesignStore.instance.deleteDraft(draftId);
            _localDraftId = null;
          }
          if (form.fileType != DesignExportFileType.pdf) {
            await saveExportedDesignToGallery(
              context,
              bytes: encoded,
              exportFileType: form.fileType,
              preferredBaseName: form.title,
              quietSuccess: true,
            );
          }
          if (!context.mounted) return;
          await showDesignSaveSuccessDialog(context);
        case SaveDesignFailure(:final message):
          showAppToast(message, type: ToastificationType.error);
      }
    } finally {
      _isSavingDesign = false;
    }
  }

  /// Device gallery / files: name + PNG/JPG/PDF (no visibility).
  Future<void> _runGalleryOnlyRasterExport({
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
      showVisibility: false,
      showFileType: true,
      allowedFileTypes: const [
        DesignExportFileType.png,
        DesignExportFileType.jpg,
        DesignExportFileType.pdf,
      ],
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
    await saveExportedDesignToGallery(
      context,
      bytes: encoded,
      exportFileType: form.fileType,
      preferredBaseName: form.title,
    );
  }

  /// Encode at canvas size and open the platform share sheet.
  Future<void> _runShareExportedRaster({
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
      showVisibility: false,
      showFileType: true,
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
    await shareExportedDesignBytes(
      context,
      bytes: encoded,
      exportFileType: form.fileType,
      preferredBaseName: form.title,
    );
  }

  Widget _buildColumnSelectSize(BuildContext context, AddNewState state) {
    final screenSize = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Match new-design custom size limits (device × 8, hard-capped at 8192).
    final maxWidthPx = (screenSize.width * 8).clamp(1.0, 8192.0);
    final maxHeightPx = (screenSize.height * 8).clamp(1.0, 8192.0);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // Lift only this panel above the keyboard; scaffold itself does not resize.
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: CanvasResizeSizePanel(
          editorWidthPx: state.selectedwidth ?? widget.width,
          editorHeightPx: state.selectedheight ?? widget.height,
          maxWidthPx: maxWidthPx,
          maxHeightPx: maxHeightPx,
          initialUnit: state.canvasUnit ?? widget.unit,
          isApplying: state.isResizingCanvas,
          onApply: (width, height, unit) {
            FocusScope.of(context).unfocus();
            context.read<AddNewBloc>().add(
              ApplyCustomSizeEvent(width: width, height: height, unit: unit),
            );
          },
        ),
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
    final showsColorPreview =
        state.bgColorToolMode == 'wheel' || state.bgColorToolMode == 'picker';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showsColorPreview)
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
      case 'picker':
        return _ScreenColorPickerContent(state: state);
      case 'wheel':
        return _WheelColorPickerContent(state: state);
      case 'swatch':
        return _SwatchPaletteContent(state: state);
      case 'transparency':
        return _TransparencySliderContent(state: state);
      case 'recent':
        return _RecentColorsGridContent(state: state);
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
            final bloc = context.read<AddNewBloc>();
            bloc.add(SetBgColorToolModeEvent(mode: t.$1));
            if (t.$1 == 'picker') {
              bloc.add(StartScreenColorPickEvent());
            }
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
          final isSelected = c == null
              ? state.isBackgroundTransparent &&
                    (state.selectedBgColor?.a ?? 0) == 0
              : state.selectedBgColor == c;
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
        child: BlocSelector<AddNewBloc, AddNewState, AddNewModel?>(
          selector: (state) => state.screen3AddNewModelObj,
          builder: (context, screen3AddNewModelObj) {
            return AddNewBookmarkPanel(
              editorKey: state.editorKey,
              baseGridItems:
                  screen3AddNewModelObj?.gridgalleryPicItemList ?? const [],
              onAssetAdded: () {
                BlocProvider.of<AddNewBloc>(
                  context,
                ).add(ShowContainerEvent(ishow: '0'));
              },
              onToolTap: (model) => _handleAddNewToolTap(context, state, model),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAddNewToolTap(
    BuildContext context,
    AddNewState state,
    GridgalleryPicItemModel model,
  ) async {
    final editor = state.editorKey?.currentState;
    if (editor == null) return;

    BlocProvider.of<AddNewBloc>(context).add(ShowContainerEvent(ishow: '0'));

    if (model.gallerypic == 'Add Text') {
      editor.openTextEditor();
    }
    // else if (model.gallerypic == 'Paint') {
    //   editor.openPaintEditor();
    // } else if (model.gallerypic == 'Crop& Rotate') {
    //   editor.openCropRotateEditor();
    // } else if (model.gallerypic == 'Tune') {
    //   editor.openTuneEditor();
    // } else if (model.gallerypic == 'Filter') {
    //   editor.openFilterEditor();
    // } else if (model.gallerypic == 'Blur') {
    //   editor.openBlurEditor();
    // }
    else {
      final key = state.editorKey;
      if (key != null) {
        await _pickFromGalleryAndAddAsLayer(context, key);
      }
    }
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
        final canvasSize = musamiEditorCanvasSize(
          editor,
          fallback: MediaQuery.sizeOf(stableContext),
        );
        final layerW = decodedSize.width;
        final layerH = decodedSize.height;
        // Offset.zero is the canvas center (layer coords are body-centered).
        final s = musamiInsertedImageScale(
          intrinsic: Size(layerW, layerH),
          canvas: canvasSize,
        );
        editor.addLayer(
          WidgetLayer(
            width: layerW,
            scale: s,
            // Allow user to zoom/resize the sticker (don't lock max size).
            boxConstraints: kMusamiWidgetLayerBoxConstraints,
            offset: Offset.zero,
            interaction: LayerInteraction(enableEdit: false),
            widget: _buildGalleryStickerWidget(
              stableContext,
              image: imageProvider,
              width: layerW,
              height: layerH,
            ),
            meta: <String, dynamic>{
              'musamiLayerKind': 'gallery',
              // Frame and image start identical; only the frame changes later.
              if (layerW > 0) kMusamiFrameAspectMetaKey: layerH / layerW,
              if (layerW > 0) kMusamiImageAspectMetaKey: layerH / layerW,
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
      canvasSize: () {
        final editor = context.read<AddNewBloc>().state.editorKey?.currentState;
        return musamiEditorCanvasSize(editor);
      },
    );
  }
}

/// Full-screen sticker selector widget matching the design
class _FullScreenStickerSelector extends StatefulWidget {
  final void Function(WidgetLayer widget) setLayer;
  final ScrollController scrollController;
  final Size Function() canvasSize;

  const _FullScreenStickerSelector({
    required this.setLayer,
    required this.scrollController,
    required this.canvasSize,
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
                    final decodedSize = await _musamiDecodeImageSize(bytes);
                    if (!mounted) return;
                    final provider = MemoryImage(bytes);
                    await precacheImage(provider, context);
                    if (!mounted) return;

                    widget.setLayer(
                      WidgetLayer(
                        width: decodedSize.width,
                        scale: musamiInsertedImageScale(
                          intrinsic: decodedSize,
                          canvas: widget.canvasSize(),
                        ),
                        offset: Offset.zero,
                        boxConstraints: kMusamiWidgetLayerBoxConstraints,
                        interaction: LayerInteraction(enableEdit: false),
                        meta: <String, dynamic>{
                          'musamiLayerKind': 'gallery',
                          if (decodedSize.width > 0)
                            'musamiAspect':
                                decodedSize.height / decodedSize.width,
                        },
                        widget: SizedBox(
                          width: decodedSize.width,
                          height: decodedSize.height,
                          child: Image(
                            image: provider,
                            fit: BoxFit.fill,
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
                  final stickerType = item['type'] as String;
                  final stickerIndex = item['index'] as int;
                  setLayer(
                    WidgetLayer(
                      exportConfigs: WidgetLayerExportConfigs(
                        id: musamiStickerExportId(stickerType, stickerIndex),
                      ),
                      meta: const <String, dynamic>{
                        'musamiLayerKind': 'sticker',
                      },
                      widget: _buildStickerWidget(stickerType, stickerIndex),
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

// --- BG Color overlay content widgets (Picker, Wheel, Swatch, Transparency, Recent) ---

/// Eyedropper panel: sample colors from the live canvas via screen capture.
class _ScreenColorPickerContent extends StatelessWidget {
  const _ScreenColorPickerContent({required this.state});
  final AddNewState state;

  @override
  Widget build(BuildContext context) {
    final preview = state.selectedBgColor ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 16.v),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12.adaptSize),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                width: 44.adaptSize,
                height: 44.adaptSize,
                decoration: BoxDecoration(
                  color: preview,
                  borderRadius: BorderRadius.circular(10.adaptSize),
                  border: Border.all(color: Colors.black26),
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lbl_pick_color_from_screen'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      'msg_screen_color_picker_hint'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.v),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              context.read<AddNewBloc>().add(StartScreenColorPickEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: appTheme.blueGray90004,
              foregroundColor: appTheme.yellow500,
              padding: EdgeInsets.symmetric(vertical: 14.v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
            ),
            icon: Icon(Icons.colorize, size: 22.adaptSize),
            label: Text(
              'lbl_start_color_pick'.tr,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.fSize),
            ),
          ),
        ),
      ],
    );
  }
}

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
    _alpha = c.a.clamp(0.0, 1.0);
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

/// Transparency mode: opacity slider with live checkerboard-backed preview.
class _TransparencySliderContent extends StatefulWidget {
  const _TransparencySliderContent({required this.state});
  final AddNewState state;

  @override
  State<_TransparencySliderContent> createState() =>
      _TransparencySliderContentState();
}

class _TransparencySliderContentState
    extends State<_TransparencySliderContent> {
  late Color _baseRgb;
  late double _opacity;

  static Color _opaqueRgb(Color color) {
    return Color.fromARGB(255, color.red, color.green, color.blue);
  }

  void _syncFromSelectedColor(Color? color) {
    final resolved = color ?? Colors.red;
    _baseRgb = _opaqueRgb(resolved);
    _opacity = resolved.a.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _syncFromSelectedColor(widget.state.selectedBgColor);
  }

  @override
  void didUpdateWidget(covariant _TransparencySliderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedBgColor != widget.state.selectedBgColor) {
      _syncFromSelectedColor(widget.state.selectedBgColor);
    }
  }

  Color get _previewColor => _baseRgb.withValues(alpha: _opacity);

  void _applyOpacity(double value) {
    final opacity = value.clamp(0.0, 1.0);
    setState(() => _opacity = opacity);
    context.read<AddNewBloc>().add(
      SetBgColorEvent(color: _baseRgb.withValues(alpha: opacity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56.v,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.adaptSize),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _CheckerboardPainter(cellSize: 10)),
                ColoredBox(color: _previewColor),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.v),
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
                  onChanged: _applyOpacity,
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
                '${(_opacity * 100).round()}%',
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

/// Compact status strip shown above the editor toolbar while transparent BG is on.
class _TransparentBgStatusBar extends StatelessWidget {
  const _TransparentBgStatusBar({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 48.v,
        padding: EdgeInsets.symmetric(horizontal: AppDs.space3.h),
        decoration: BoxDecoration(
          color: AppDs.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
          border: Border.all(color: AppDs.accentYellow.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6.adaptSize),
              child: SizedBox(
                width: 28.adaptSize,
                height: 28.adaptSize,
                child: const CustomPaint(
                  painter: _CheckerboardPainter(cellSize: 5),
                ),
              ),
            ),
            SizedBox(width: AppDs.space2.h),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'msg_transparent_bg_on'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppDs.textOnDarkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'msg_transparent_bg_hint'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppDs.textOnDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestore,
              style: TextButton.styleFrom(
                foregroundColor: AppDs.accentYellow,
                padding: EdgeInsets.symmetric(horizontal: 10.h),
                minimumSize: Size(0, 36.v),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'lbl_restore_background'.tr,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppDs.accentYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Classic high-contrast checkerboard for small UI chips / swatches.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({this.cellSize = 6});

  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize;
  }
}

/// Soft dark grid for the editor surround when Transparent BG is enabled.
class _SoftTransparencyGridPainter extends CustomPainter {
  const _SoftTransparencyGridPainter({this.cellSize = 14});

  final double cellSize;

  static const Color _a = Color(0xFF2A3038);
  static const Color _b = Color(0xFF343B45);

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = _a;
    final paintB = Paint()..color = _b;
    canvas.drawRect(Offset.zero & size, paintA);
    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        final isAlt = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        if (!isAlt) continue;
        canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paintB);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SoftTransparencyGridPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize;
  }
}
