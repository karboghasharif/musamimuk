import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/network/authenticated_image.dart';
import '../../../core/utils/design_state_history.dart';
import '../../../data/models/media_item.dart';

/// Builds a [WidgetLayer] for an API asset, with precache and intrinsic size.
///
/// Layer offset stays [Offset.zero] (canvas center). Scale fits the asset
/// inside 1/3 of the canvas unless [scale] is passed explicitly.
Future<WidgetLayer?> musamiBuildAssetWidgetLayer({
  required BuildContext context,
  required MediaItem item,
  required String layerKind,
  double? scale,
  ProImageEditorState? editor,
  Size? canvasSize,
}) async {
  final url = item.fileUrl.trim();
  if (url.isEmpty) return null;

  final provider = musamiAuthenticatedNetworkImage(url);
  try {
    await precacheImage(provider, context);
  } catch (_) {}

  final w = (item.width ?? 200).toDouble().clamp(1.0, 10000.0);
  final h = (item.height ?? 200).toDouble().clamp(1.0, 10000.0);
  final canvas = canvasSize ?? musamiEditorCanvasSize(editor);
  final resolvedScale =
      scale ??
      musamiInsertedImageScale(intrinsic: Size(w, h), canvas: canvas);

  return WidgetLayer(
    width: w,
    scale: resolvedScale,
    offset: Offset.zero,
    boxConstraints: kMusamiWidgetLayerBoxConstraints,
    exportConfigs: WidgetLayerExportConfigs(
      networkUrl: url,
      meta: <String, dynamic>{'musamiLayerKind': layerKind, 'fileUrl': url},
    ),
    meta: <String, dynamic>{
      'musamiLayerKind': layerKind,
      'fileUrl': url,
      // Frame and image ratios start identical; resizing only moves the frame.
      if (w > 0) 'musamiAspect': h / w,
      if (w > 0) 'musamiImageAspect': h / w,
    },
    widget: SizedBox(
      width: w,
      height: h,
      child: Image(
        image: provider,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      ),
    ),
  );
}
