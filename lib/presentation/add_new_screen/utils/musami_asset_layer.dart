import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../data/models/media_item.dart';

const double kMusamiAssetLayerDefaultScale = 0.2;

/// Builds a [WidgetLayer] for an API asset, with precache and intrinsic size.
Future<WidgetLayer?> musamiBuildAssetWidgetLayer({
  required BuildContext context,
  required MediaItem item,
  required String layerKind,
  double scale = kMusamiAssetLayerDefaultScale,
}) async {
  final url = item.fileUrl.trim();
  if (url.isEmpty) return null;

  final provider = NetworkImage(url);
  try {
    await precacheImage(provider, context);
  } catch (_) {}

  final w = (item.width ?? 200).toDouble().clamp(1.0, 10000.0);
  final h = (item.height ?? 200).toDouble().clamp(1.0, 10000.0);

  return WidgetLayer(
    width: w,
    scale: scale,
    boxConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    exportConfigs: WidgetLayerExportConfigs(
      networkUrl: url,
      meta: <String, dynamic>{
        'musamiLayerKind': layerKind,
        'fileUrl': url,
      },
    ),
    meta: <String, dynamic>{
      'musamiLayerKind': layerKind,
      'fileUrl': url,
      if (w > 0) 'musamiAspect': h / w,
    },
    widget: Image(
      image: provider,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
    ),
  );
}
