import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import 'musami_clipping_mask.dart';
import 'musami_layer_raster_utils.dart';
import 'musami_perspective_warp_meta.dart';
import '../widgets/musami_perspective_warp_page.dart';

export 'musami_perspective_warp.dart' show MusamiPerspectiveWarpResult;
export 'musami_perspective_warp_meta.dart';
export '../widgets/musami_perspective_warp_page.dart'
    show MusamiPerspectiveWarpPageResult;

/// In-session originals for gallery MemoryImage layers (not exported in meta).
final Map<String, Uint8List> _musamiWarpSessionOriginals = <String, Uint8List>{};

void musamiRememberWarpOriginalBytes(String layerId, Uint8List bytes) {
  if (layerId.isEmpty || bytes.isEmpty) return;
  // Keep the first (pre-warp) snapshot only.
  _musamiWarpSessionOriginals.putIfAbsent(layerId, () => bytes);
}

Uint8List? musamiPeekWarpOriginalBytes(String layerId) {
  return _musamiWarpSessionOriginals[layerId];
}

@visibleForTesting
void musamiDebugClearWarpSessionOriginals() {
  _musamiWarpSessionOriginals.clear();
}

/// Resolves current raster + best available original for Reset.
class MusamiWarpSourceBundle {
  const MusamiWarpSourceBundle({
    required this.bytes,
    this.originalBytes,
    this.networkUrl,
    this.assetPath,
  });

  /// Bytes shown / warped in the editor (current layer pixels).
  final Uint8List bytes;

  /// Pre-warp original when known (session cache or re-fetched URL/asset).
  final Uint8List? originalBytes;
  final String? networkUrl;
  final String? assetPath;

  Uint8List get bytesForReset => originalBytes ?? bytes;

  bool get canResetToOriginal =>
      originalBytes != null ||
      (networkUrl != null && networkUrl!.trim().isNotEmpty) ||
      (assetPath != null && assetPath!.trim().isNotEmpty);
}

Future<MusamiWarpSourceBundle?> musamiResolveWarpSource(
  WidgetLayer layer,
) async {
  final meta = layer.meta;
  final storedUrl =
      meta?[kMusamiWarpOriginalNetworkUrlMetaKey]?.toString().trim();
  final storedAsset =
      meta?[kMusamiWarpOriginalAssetPathMetaKey]?.toString().trim();
  final sessionOriginal = musamiPeekWarpOriginalBytes(layer.id);

  Uint8List? remoteOriginal;
  if (storedUrl != null && storedUrl.isNotEmpty) {
    remoteOriginal = await musamiResolveRasterBytesForBackgroundRemoval(
      Image.network(storedUrl),
    );
  }
  if ((remoteOriginal == null || remoteOriginal.isEmpty) &&
      storedAsset != null &&
      storedAsset.isNotEmpty) {
    try {
      final data = await rootBundle.load(storedAsset);
      remoteOriginal = data.buffer.asUint8List();
    } catch (_) {}
  }

  final current = await musamiResolveRasterBytesForBackgroundRemoval(
    layer.widget,
  );
  if (current == null || current.isEmpty) {
    // Fall back to session / remote if current widget has no MemoryImage yet.
    final fallback = remoteOriginal ?? sessionOriginal;
    if (fallback == null || fallback.isEmpty) return null;
    return MusamiWarpSourceBundle(
      bytes: fallback,
      originalBytes: fallback,
      networkUrl: storedUrl,
      assetPath: storedAsset,
    );
  }

  final networkUrl = storedUrl ??
      musamiTryExtractNetworkImageUrl(layer.widget) ??
      meta?['fileUrl']?.toString() ??
      meta?['networkUrl']?.toString();
  final assetPath = storedAsset ??
      musamiTryExtractAssetImagePath(layer.widget) ??
      meta?['assetPath']?.toString();

  final alreadyWarped = musamiMetaIsPerspectiveWarped(meta);
  // Prefer remote → session → current (only if not yet warped).
  final original = remoteOriginal ??
      sessionOriginal ??
      (alreadyWarped ? null : current);

  if (original != null && original.isNotEmpty) {
    musamiRememberWarpOriginalBytes(layer.id, original);
  }

  return MusamiWarpSourceBundle(
    bytes: current,
    originalBytes: original,
    networkUrl: networkUrl,
    assetPath: assetPath,
  );
}

bool musamiCanOpenPerspectiveWarp(WidgetLayer layer) {
  if (!musamiLayerMetaSupportsPerspectiveWarp(layer.meta)) return false;
  if (musamiLayerHasActiveClippingMask(layer.meta)) return false;
  return true;
}

/// Localization key for why warp is blocked, or null if allowed.
String? musamiPerspectiveWarpBlockReason(WidgetLayer layer) {
  if (musamiLayerHasActiveClippingMask(layer.meta)) {
    return 'msg_warp_release_mask_first';
  }
  if (!musamiLayerMetaSupportsPerspectiveWarp(layer.meta)) {
    return 'msg_warp_unsupported_layer';
  }
  return null;
}

/// Opens the warp editor. Returns null on cancel.
Future<MusamiPerspectiveWarpPageResult?> musamiPushPerspectiveWarpPage({
  required BuildContext context,
  required WidgetLayer layer,
  required MusamiWarpSourceBundle source,
}) {
  return Navigator.of(context, rootNavigator: true)
      .push<MusamiPerspectiveWarpPageResult>(
    MaterialPageRoute(
      builder: (_) => MusamiPerspectiveWarpPage(
        sourceBytes: source.bytes,
        initialQuad: musamiParseWarpQuad(layer.meta?[kMusamiWarpQuadMetaKey]),
        canReset: source.canResetToOriginal,
      ),
    ),
  );
}
