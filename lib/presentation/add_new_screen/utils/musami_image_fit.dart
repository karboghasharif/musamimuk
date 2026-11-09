import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'musami_curved_text_meta.dart';
import 'musami_design_pack_border_frame.dart';

/// Meta: how a photo-like [WidgetLayer] fills its frame.
///
/// - [kMusamiImageFitCrop] — `BoxFit.cover` + clip (no pixel stretch)
/// - [kMusamiImageFitStretch] — `BoxFit.fill` (pixels warp to the frame)
///
/// New gallery/sticker/photo inserts write [kMusamiImageFitStretch] explicitly.
/// Legacy layers with no key keep **crop** (never rewritten by resize alone).
const String kMusamiImageFitModeMetaKey = 'musamiImageFitMode';

const String kMusamiImageFitCrop = 'crop';
const String kMusamiImageFitStretch = 'stretch';

/// Meta: when `true`, corner/edge resize preserves the current frame aspect.
///
/// Default `false` = free stretch (width/height independent), matching Canva.
/// Independent of [kMusamiImageFitModeMetaKey] — unlock does **not** force fill.
const String kMusamiMaintainAspectMetaKey = 'musamiMaintainAspectRatio';

/// Frame aspect (height / width) stored on photo-like layers.
const String kMusamiPhotoFrameAspectMetaKey = 'musamiAspect';

/// Intrinsic image aspect (height / width); resize must not overwrite casually.
const String kMusamiPhotoImageAspectMetaKey = 'musamiImageAspect';

/// Selection stroke / handle accent for photo layers (brand yellow).
const Color kMusamiImageSelectionColor = Color(0xFFF4DF08);

/// Legacy alias — prefer [kMusamiImageSelectionColor].
const Color kMusamiImageSelectionPurple = kMusamiImageSelectionColor;

/// Smallest / largest painted frame size a resize may produce (canvas logical px).
const double kMusamiMinFrameSizePx = 16;
const double kMusamiMaxFrameSizePx = 6000;

/// Resolves fit mode.
///
/// Missing key ⇒ [kMusamiImageFitCrop] for backward compatibility with older
/// designs. New inserts should write [kMusamiImageFitStretch] explicitly.
String musamiImageFitModeFromMeta(Map<String, dynamic>? meta) {
  final raw =
      meta?[kMusamiImageFitModeMetaKey]?.toString().trim().toLowerCase() ?? '';
  if (raw == kMusamiImageFitStretch) return kMusamiImageFitStretch;
  if (raw == kMusamiImageFitCrop) return kMusamiImageFitCrop;
  return kMusamiImageFitCrop;
}

bool musamiImageFitIsStretch(Map<String, dynamic>? meta) =>
    musamiImageFitModeFromMeta(meta) == kMusamiImageFitStretch;

/// Flutter [BoxFit] for the frame shell.
BoxFit musamiImageFitBoxFit(Map<String, dynamic>? meta) =>
    musamiImageFitIsStretch(meta) ? BoxFit.fill : BoxFit.cover;

/// Whether resize should preserve the current frame aspect ratio.
///
/// Missing key ⇒ free stretch (`false`).
bool musamiMaintainAspectFromMeta(Map<String, dynamic>? meta) {
  final raw = meta?[kMusamiMaintainAspectMetaKey];
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final s = raw?.toString().trim().toLowerCase();
  return s == 'true' || s == '1';
}

/// Photo-like layers can use Crop/Stretch + aspect lock.
bool musamiLayerSupportsImageFitMode(Map<String, dynamic>? meta) {
  if (meta == null) return true;
  if (musamiMetaIsCurvedText(meta)) return false;
  if (musamiMetaIsCanvasBorderFrame(meta)) return false;
  final kind = meta['musamiLayerKind']?.toString() ?? '';
  switch (kind) {
    case 'shape':
    case 'ai-shape':
    case 'ai-icon':
    case 'lottie':
    case 'online_asset_lottie':
    case 'online_asset_svg':
    case 'design_pack_shape':
    case 'design_pack_border':
      return false;
    default:
      return true;
  }
}

/// Layer.meta keys that describe photo transform / fill behaviour and must
/// survive save → import, duplicate, and (where applicable) replace.
const List<String> kMusamiImageTransformPersistenceKeys = <String>[
  kMusamiImageFitModeMetaKey,
  kMusamiMaintainAspectMetaKey,
  kMusamiPhotoFrameAspectMetaKey,
  kMusamiPhotoImageAspectMetaKey,
  'musamiCropAlignX',
  'musamiCropAlignY',
  'musamiLayerLocked',
  'musamiLayerHidden',
  'musamiOpacity',
  'musamiClippingMask',
  'musamiClipMaskUrl',
  'musamiClipContentKind',
  'musamiClipContentUrl',
  'musamiClipContentAspect',
];

/// Copies transform/presentation keys from [source] into [target] (in place).
void musamiCopyImageTransformPersistenceMeta(
  Map<String, dynamic> target,
  Map<String, dynamic>? source,
) {
  if (source == null || source.isEmpty) return;
  for (final key in kMusamiImageTransformPersistenceKeys) {
    if (source.containsKey(key)) target[key] = source[key];
  }
}

/// Meta for a Replace operation: start from [picked], keep frame policy from
/// [existing], then apply new image aspect under the existing frame aspect.
///
/// Pure helper for unit tests and [_applyReplacingWidgetLayer].
Map<String, dynamic> musamiBuildReplaceImageMeta({
  required Map<String, dynamic>? existing,
  required Map<String, dynamic>? picked,
  required double frameAspect,
  required double imageAspect,
  Iterable<String> extraPreserveKeys = const [
    'musamiBorderW',
    'musamiBorderArgb',
    'musamiShadowBlur',
    'musamiShadowDx',
    'musamiShadowDy',
    'musamiShadowStrength',
    'musamiImageTintArgb',
  ],
}) {
  final meta = Map<String, dynamic>.from(picked ?? const <String, dynamic>{});
  // Drop ephemeral crop-revision keys from the pick; keep Cover pan keys so
  // [musamiCopyImageTransformPersistenceMeta] can overwrite from [existing].
  meta.removeWhere((k, _) {
    if (k == 'musamiCropAlignX' || k == 'musamiCropAlignY') return false;
    return k == 'musamiCropRevision' || k.startsWith('musamiCrop');
  });
  final kind = picked?['musamiLayerKind']?.toString();
  meta['musamiLayerKind'] =
      (kind != null && kind.isNotEmpty) ? kind : 'gallery';
  musamiCopyImageTransformPersistenceMeta(meta, existing);
  if (existing != null) {
    for (final k in extraPreserveKeys) {
      if (existing.containsKey(k)) meta[k] = existing[k];
    }
  }
  final opacity = (existing?['musamiOpacity'] as num?)?.toDouble() ?? 1.0;
  meta['musamiOpacity'] = opacity;
  meta[kMusamiPhotoFrameAspectMetaKey] = frameAspect;
  meta[kMusamiPhotoImageAspectMetaKey] = imageAspect;
  return meta;
}

/// Default meta flags for a newly inserted photo-like layer (Canva free stretch).
Map<String, dynamic> musamiDefaultFreeStretchMeta() => <String, dynamic>{
      kMusamiImageFitModeMetaKey: kMusamiImageFitStretch,
      kMusamiMaintainAspectMetaKey: false,
    };

/// Consistent insert meta for photo-like [WidgetLayer]s.
///
/// Legacy imports omit fit keys and therefore stay in crop until the user
/// changes Fit mode explicitly.
Map<String, dynamic> musamiPhotoInsertMeta({
  required String layerKind,
  double? width,
  double? height,
}) {
  final meta = <String, dynamic>{
    'musamiLayerKind': layerKind,
    ...musamiDefaultFreeStretchMeta(),
  };
  if (width != null &&
      height != null &&
      width > 0 &&
      height > 0 &&
      width.isFinite &&
      height.isFinite) {
    final aspect = height / width;
    meta[kMusamiPhotoFrameAspectMetaKey] = aspect;
    meta[kMusamiPhotoImageAspectMetaKey] = aspect;
  }
  return meta;
}

/// Size after applying free or proportional resize from a gesture start rect.
///
/// Always derives from [start] + [grow] (not from the last frame) to avoid drift.
/// Result is clamped to [[kMusamiMinFrameSizePx], [kMusamiMaxFrameSizePx]].
Size musamiResizeFrameFromGesture({
  required Size start,
  required Offset grow,
  required bool maintainAspect,
  required bool isCorner,
  required bool isHorizontalEdge,
  double minSize = kMusamiMinFrameSizePx,
  double maxSize = kMusamiMaxFrameSizePx,
}) {
  var width = start.width + (isCorner || isHorizontalEdge ? grow.dx : 0);
  var height = start.height + (isCorner || !isHorizontalEdge ? grow.dy : 0);

  if (maintainAspect && start.width > 0 && start.height > 0) {
    final aspect = start.height / start.width;
    if (isCorner) {
      if (grow.dx.abs() >= grow.dy.abs()) {
        height = width * aspect;
      } else {
        width = height / aspect;
      }
    } else if (isHorizontalEdge) {
      height = width * aspect;
    } else {
      width = height / aspect;
    }
  }

  if (!width.isFinite) width = minSize;
  if (!height.isFinite) height = minSize;

  return Size(
    width.clamp(minSize, maxSize),
    height.clamp(minSize, maxSize),
  );
}

/// Converts a screen-space pointer delta into canvas space using viewer zoom.
Offset musamiScreenDeltaToCanvasDelta(
  Offset deltaGlobal,
  double viewerScale,
) {
  if (!deltaGlobal.dx.isFinite || !deltaGlobal.dy.isFinite) return Offset.zero;
  if (!viewerScale.isFinite || viewerScale <= 0) return deltaGlobal;
  return deltaGlobal / viewerScale;
}

/// Layer-centre shift that keeps the handle's opposite edge/corner fixed.
///
/// [anchorSign] is the direction from the layer centre toward the anchored
/// point (e.g. right-edge drag ⇒ left edge fixed ⇒ `Offset(-1, 0)`).
Offset musamiOffsetKeepingAnchor({
  required Offset startOffset,
  required Size startFrame,
  required Size newFrame,
  required Offset anchorSign,
  double rotation = 0,
  bool flipX = false,
  bool flipY = false,
}) {
  final startAnchorLocal = Offset(
    anchorSign.dx * startFrame.width / 2,
    anchorSign.dy * startFrame.height / 2,
  );
  final newAnchorLocal = Offset(
    anchorSign.dx * newFrame.width / 2,
    anchorSign.dy * newFrame.height / 2,
  );
  final localShift = startAnchorLocal - newAnchorLocal;
  final frameRotation = flipX == flipY ? rotation : -rotation;
  final cos = math.cos(frameRotation);
  final sin = math.sin(frameRotation);
  final canvasShift = Offset(
    localShift.dx * cos - localShift.dy * sin,
    localShift.dx * sin + localShift.dy * cos,
  );
  final next = startOffset + canvasShift;
  if (!next.dx.isFinite || !next.dy.isFinite) return startOffset;
  return next;
}
