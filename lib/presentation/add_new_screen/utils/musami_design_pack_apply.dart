import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/utils/design_state_history.dart';
import '../../../data/models/design_pack_models.dart';
import 'musami_design_pack_border_frame.dart';
import 'musami_design_pack_widgets.dart';

export 'musami_design_pack_border_frame.dart';
export 'musami_design_pack_widgets.dart';

/// Inserts a pack item onto the editor canvas (undo via editor history).
///
/// **Borders** are applied as a full-canvas frame (all four corners + edge
/// tiles), not as a single centered sticker.
Future<WidgetLayer?> musamiApplyDesignPackItem({
  required BuildContext context,
  required DesignPackItem item,
  required GlobalKey<ProImageEditorState>? editorKey,
  VoidCallback? onAssetAdded,
  Color? svgTint,
}) async {
  final editor = editorKey?.currentState;
  if (editor == null) return null;
  final path = item.assetPath.trim();
  if (path.isEmpty) return null;

  // Fail fast when the asset was never bundled (spaces / missing pubspec dir).
  try {
    await rootBundle.load(path);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Design pack asset missing: $path ($e)');
    }
    return null;
  }

  if (item.category == DesignPackCategory.borders) {
    return _applyBorderFrame(
      editor: editor,
      item: item,
      path: path,
      onAssetAdded: onAssetAdded,
      svgTint: svgTint,
    );
  }

  final size = item.category == DesignPackCategory.patterns
      ? const Size(240, 240)
      : const Size(180, 180);
  // Shapes are single-color silhouettes (srcIn recolor).
  // Emoji + specialtext keep authored fills — srcIn would crush them to one color.
  final usesSilhouetteTint =
      item.isSvg && item.category == DesignPackCategory.shapes;
  final tint = usesSilhouetteTint
      ? (svgTint ?? const Color(0xFF111111))
      : svgTint;

  final meta = <String, dynamic>{
    'musamiLayerKind': item.layerKind,
    'designPackId': item.id,
    'assetPath': path,
    'category': item.category.name,
    if (item.subcategory != null) 'subcategory': item.subcategory,
    'musamiAspect': size.height / size.width,
    'musamiImageAspect': size.height / size.width,
    if (tint != null) 'musamiImageTintArgb': tint.toARGB32(),
  };

  Widget packWidget = musamiDesignPackWidget(
    assetPath: path,
    isSvg: item.isSvg,
    width: size.width,
    height: size.height,
    // Do not bake SvgPicture.colorFilter — compose tint lives in meta.
    tint: null,
  );
  if (tint != null) {
    packWidget = ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: packWidget,
    );
  }

  final layer = WidgetLayer(
    width: size.width,
    scale: musamiInsertedImageScale(
      intrinsic: size,
      canvas: musamiEditorCanvasSize(editor),
    ),
    offset: Offset.zero,
    boxConstraints: kMusamiWidgetLayerBoxConstraints,
    // Use `id` (not assetPath) so SVG is not restored as Image.asset by PIE.
    exportConfigs: WidgetLayerExportConfigs(
      id: '$kMusamiDesignPackIdPrefix${item.id}',
      meta: meta,
    ),
    meta: meta,
    widget: packWidget,
  );

  editor.addLayer(layer);
  onAssetAdded?.call();
  return layer;
}

Future<WidgetLayer?> _applyBorderFrame({
  required ProImageEditorState editor,
  required DesignPackItem item,
  required String path,
  VoidCallback? onAssetAdded,
  Color? svgTint,
}) async {
  final canvas = musamiEditorCanvasSize(editor);
  final cw = canvas.width <= 0 ? 1080.0 : canvas.width;
  final ch = canvas.height <= 0 ? 1080.0 : canvas.height;
  final frameSize = Size(cw, ch);

  final paths = await musamiResolveBorderFramePaths(path);
  final tint = svgTint ?? const Color(0xFF111111);

  final meta = <String, dynamic>{
    'musamiLayerKind': item.layerKind,
    'designPackId': item.id,
    'assetPath': path,
    'category': item.category.name,
    kMusamiBorderModeMetaKey: kMusamiBorderModeCanvasFrame,
    kMusamiBorderCornerPathMetaKey: paths.cornerPath,
    kMusamiBorderEdgePathMetaKey: paths.edgePath,
    'musamiFrameWidth': cw,
    'musamiFrameHeight': ch,
    'musamiAspect': ch / cw,
    'musamiImageAspect': ch / cw,
    'musamiImageTintArgb': tint.toARGB32(),
  };

  final frame = MusamiDesignPackBorderFrame(
    size: frameSize,
    cornerAssetPath: paths.cornerPath,
    edgeAssetPath: paths.edgePath,
    tint: tint,
    isSvg: item.isSvg,
  );

  final layer = WidgetLayer(
    width: cw,
    scale: 1,
    offset: Offset.zero,
    boxConstraints: kMusamiWidgetLayerBoxConstraints,
    exportConfigs: WidgetLayerExportConfigs(
      id: '$kMusamiDesignPackIdPrefix${item.id}',
      meta: meta,
    ),
    meta: meta,
    widget: frame,
  );

  editor.addLayer(layer);
  onAssetAdded?.call();
  return layer;
}
