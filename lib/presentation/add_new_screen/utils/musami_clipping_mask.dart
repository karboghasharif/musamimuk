import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/network/authenticated_image.dart';

/// Meta: shape (or compatible layer) is acting as / was applied as a clip mask.
const String kMusamiClippingMaskMetaKey = 'musamiClippingMask';

/// Meta: network URL of the silhouette used as the alpha mask.
const String kMusamiClipMaskUrlMetaKey = 'musamiClipMaskUrl';

/// Meta: original content layer kind before clip merge (`gallery`, `sticker`, …).
const String kMusamiClipContentKindMetaKey = 'musamiClipContentKind';

/// Meta: original content network URL (when available) for release-mask.
const String kMusamiClipContentUrlMetaKey = 'musamiClipContentUrl';

/// Meta: aspect (height / width) the content had before it was clipped.
///
/// The clipped layer paints at the silhouette aspect, so the content aspect is
/// kept to cover-fit the artwork inside the frame and to restore it on release.
const String kMusamiClipContentAspectMetaKey = 'musamiClipContentAspect';

/// Meta key holding the painted aspect (height / width) of a widget layer.
const String _kMusamiAspectMetaKey = 'musamiAspect';

/// Base width of the internal clip frame.
///
/// Pro Image Editor wraps layer widgets in a `FittedBox` sized to the layer
/// width, so only the frame ratios matter here.
const double _kMusamiClipFrameBaseWidth = 1000;

typedef MusamiRebuildWidgetLayerVisuals = WidgetLayer Function(
  WidgetLayer content,
  Map<String, dynamic> meta,
);

bool musamiLayerIsShapeKind(Map<String, dynamic>? meta) {
  final kind = meta?['musamiLayerKind']?.toString();
  return kind == 'shape' || kind == 'ai-shape' || kind == 'ai-icon';
}

bool musamiLayerHasActiveClippingMask(Map<String, dynamic>? meta) {
  return meta?[kMusamiClippingMaskMetaKey] == true;
}

bool musamiLayerSupportsClippingMaskAction(WidgetLayer layer) {
  final meta = layer.meta;
  if (musamiLayerHasActiveClippingMask(meta)) return true;
  return musamiLayerIsShapeKind(meta);
}

String? musamiLayerFileUrl(Layer layer) {
  final meta = layer.meta;
  if (meta == null) return null;
  final url =
      meta['fileUrl']?.toString() ??
      meta['file_url']?.toString() ??
      meta['networkUrl']?.toString() ??
      meta['url']?.toString();
  if (url == null || url.trim().isEmpty) return null;
  return url.trim();
}

double _musamiSafeAspect(double? aspect, [double fallback = 1.0]) {
  if (aspect == null || !aspect.isFinite || aspect <= 0) return fallback;
  return aspect;
}

double _musamiAspectFromMeta(
  Map<String, dynamic> meta,
  String key,
  double fallback,
) {
  return _musamiSafeAspect((meta[key] as num?)?.toDouble(), fallback);
}

/// Wraps [content] with the clipping mask described by [meta], when active.
Widget musamiApplyClippingMaskFromMeta(
  Widget content,
  Map<String, dynamic> meta,
) {
  final maskUrl = meta[kMusamiClipMaskUrlMetaKey]?.toString().trim();
  if (!musamiLayerHasActiveClippingMask(meta) ||
      maskUrl == null ||
      maskUrl.isEmpty) {
    return content;
  }

  final frameAspect = _musamiAspectFromMeta(meta, _kMusamiAspectMetaKey, 1.0);
  return MusamiClipMaskedContent(
    maskUrl: maskUrl,
    maskAspect: frameAspect,
    contentAspect: _musamiAspectFromMeta(
      meta,
      kMusamiClipContentAspectMetaKey,
      frameAspect,
    ),
    child: content,
  );
}

/// Peels a clip-mask wrapper so rebuilds can re-apply compose wrappers.
Widget? musamiTryUnwrapClipMaskedContent(Widget widget) {
  if (widget is MusamiClipMaskedContent) return widget.child;
  return null;
}

/// Finds the [WidgetLayer] immediately below [shape] in the editor stack.
///
/// In Pro Image Editor, lower indices are behind higher indices (drawn first).
WidgetLayer? musamiFindContentLayerBelowShape(
  ProImageEditorState editor,
  WidgetLayer shape,
) {
  final layers = editor.activeLayers;
  final shapeIndex = layers.indexWhere((l) => l.id == shape.id);
  if (shapeIndex <= 0) return null;
  for (var i = shapeIndex - 1; i >= 0; i--) {
    final candidate = layers[i];
    if (candidate is! WidgetLayer) continue;
    if (musamiLayerIsShapeKind(candidate.meta)) continue;
    if (musamiLayerHasActiveClippingMask(candidate.meta)) continue;
    return candidate;
  }
  return null;
}

/// Applies the selected shape as a clipping mask over the content layer below.
///
/// The merged layer adopts the shape geometry (frame), so the silhouette keeps
/// its own ratio and stays where the user placed it, while the content below is
/// cover-fitted into that frame.
bool musamiApplyShapeClippingMask({
  required ProImageEditorState editor,
  required WidgetLayer shape,
  required MusamiRebuildWidgetLayerVisuals rebuildVisuals,
}) {
  final content = musamiFindContentLayerBelowShape(editor, shape);
  if (content == null) return false;

  final maskUrl = musamiLayerFileUrl(shape);
  if (maskUrl == null || maskUrl.isEmpty) return false;

  final contentMeta = Map<String, dynamic>.from(content.meta ?? {});
  final contentUrl = musamiLayerFileUrl(content);
  final contentKind =
      contentMeta['musamiLayerKind']?.toString() ?? 'gallery';
  final contentAspect = _musamiAspectFromMeta(
    contentMeta,
    _kMusamiAspectMetaKey,
    1.0,
  );
  final maskAspect = _musamiAspectFromMeta(
    Map<String, dynamic>.from(shape.meta ?? {}),
    _kMusamiAspectMetaKey,
    1.0,
  );

  contentMeta[kMusamiClippingMaskMetaKey] = true;
  contentMeta[kMusamiClipMaskUrlMetaKey] = maskUrl;
  contentMeta[kMusamiClipContentKindMetaKey] = contentKind;
  contentMeta[kMusamiClipContentAspectMetaKey] = contentAspect;
  if (contentUrl != null && contentUrl.isNotEmpty) {
    contentMeta[kMusamiClipContentUrlMetaKey] = contentUrl;
  }
  contentMeta['musamiLayerKind'] = contentKind;
  contentMeta[_kMusamiAspectMetaKey] = maskAspect;

  final framedContent = content.copyWith(
    width: shape.width,
    scale: shape.scale,
    offset: shape.offset,
    rotation: shape.rotation,
    flipX: shape.flipX,
    flipY: shape.flipY,
    meta: contentMeta,
  );

  final rebuilt = rebuildVisuals(framedContent, contentMeta);
  final contentIndex = editor.activeLayers.indexWhere((l) => l.id == content.id);
  if (contentIndex < 0) return false;

  editor.replaceLayer(index: contentIndex, layer: rebuilt);
  final shapeAfter = editor.activeLayers
      .whereType<WidgetLayer>()
      .cast<WidgetLayer?>()
      .firstWhere((l) => l?.id == shape.id, orElse: () => null);
  if (shapeAfter != null) {
    editor.removeLayer(shapeAfter);
  }
  editor.layerInteractionManager.selectedLayerId = rebuilt.id;
  editor.setState(() {});
  return true;
}

/// Releases a previously applied clipping mask into separate layers when possible.
bool musamiReleaseClippingMask({
  required ProImageEditorState editor,
  required WidgetLayer clipped,
  required MusamiRebuildWidgetLayerVisuals rebuildVisuals,
}) {
  final meta = Map<String, dynamic>.from(clipped.meta ?? {});
  if (meta[kMusamiClippingMaskMetaKey] != true) return false;

  final maskUrl = meta[kMusamiClipMaskUrlMetaKey]?.toString();
  final contentKind =
      meta[kMusamiClipContentKindMetaKey]?.toString() ?? 'gallery';
  final frameAspect = _musamiAspectFromMeta(meta, _kMusamiAspectMetaKey, 1.0);
  final contentAspect = _musamiAspectFromMeta(
    meta,
    kMusamiClipContentAspectMetaKey,
    frameAspect,
  );

  meta.remove(kMusamiClippingMaskMetaKey);
  meta.remove(kMusamiClipMaskUrlMetaKey);
  meta.remove(kMusamiClipContentKindMetaKey);
  meta.remove(kMusamiClipContentUrlMetaKey);
  meta.remove(kMusamiClipContentAspectMetaKey);
  meta['musamiLayerKind'] = contentKind;
  meta[_kMusamiAspectMetaKey] = contentAspect;

  final restoredContent = rebuildVisuals(clipped, meta);
  final idx = editor.activeLayers.indexWhere((l) => l.id == clipped.id);
  if (idx < 0) return false;
  editor.replaceLayer(index: idx, layer: restoredContent);

  if (maskUrl != null && maskUrl.isNotEmpty) {
    final shapeMeta = <String, dynamic>{
      'musamiLayerKind': 'shape',
      'fileUrl': maskUrl,
      _kMusamiAspectMetaKey: frameAspect,
    };
    final shape = WidgetLayer(
      offset: restoredContent.offset + const Offset(12, 12),
      scale: restoredContent.scale,
      rotation: restoredContent.rotation,
      width: restoredContent.width,
      flipX: restoredContent.flipX,
      flipY: restoredContent.flipY,
      boxConstraints: restoredContent.boxConstraints,
      exportConfigs: WidgetLayerExportConfigs(
        networkUrl: maskUrl,
        meta: Map<String, dynamic>.from(shapeMeta),
      ),
      meta: shapeMeta,
      widget: Image(
        image: musamiAuthenticatedNetworkImage(maskUrl),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      ),
    );
    editor.addLayer(shape);
  }

  editor.layerInteractionManager.selectedLayerId = restoredContent.id;
  editor.setState(() {});
  return true;
}

/// Clips [child] to the alpha channel of the silhouette loaded from [maskUrl].
///
/// The frame keeps the silhouette ratio ([maskAspect]) and [child] is
/// cover-fitted inside it, so the artwork fills the shape without stretching
/// either of them. Masking uses a `ShaderMask` (a compositing layer) instead of
/// a raw `saveLayer` blend so it only affects this subtree — a canvas-level
/// `BlendMode.dstIn` also erases the background and sibling layers, and breaks
/// when the content itself paints into its own layer (tint / tune filters).
class MusamiClipMaskedContent extends StatefulWidget {
  const MusamiClipMaskedContent({
    super.key,
    required this.maskUrl,
    required this.maskAspect,
    required this.contentAspect,
    required this.child,
  });

  /// Network URL of the silhouette whose alpha clips [child].
  final String maskUrl;

  /// Silhouette aspect (height / width) — defines the painted frame.
  final double maskAspect;

  /// Clipped content aspect (height / width) — used for the cover fit.
  final double contentAspect;

  final Widget child;

  @override
  State<MusamiClipMaskedContent> createState() =>
      _MusamiClipMaskedContentState();
}

class _MusamiClipMaskedContentState extends State<MusamiClipMaskedContent> {
  ImageStream? _maskStream;
  ImageStreamListener? _maskListener;
  ImageInfo? _maskInfo;
  bool _maskFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveMask();
  }

  @override
  void didUpdateWidget(MusamiClipMaskedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskUrl != widget.maskUrl) _resolveMask();
  }

  @override
  void dispose() {
    _detachMaskListener();
    _maskInfo?.dispose();
    _maskInfo = null;
    super.dispose();
  }

  void _resolveMask() {
    final stream = musamiAuthenticatedNetworkImage(
      widget.maskUrl,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _maskStream?.key) return;

    _detachMaskListener();
    final listener = ImageStreamListener(
      _handleMaskFrame,
      onError: (_, _) => _handleMaskFailure(),
    );
    _maskStream = stream;
    _maskListener = listener;
    stream.addListener(listener);
  }

  void _detachMaskListener() {
    final listener = _maskListener;
    if (listener != null) _maskStream?.removeListener(listener);
    _maskListener = null;
    _maskStream = null;
  }

  void _handleMaskFrame(ImageInfo info, bool synchronousCall) {
    if (!mounted) {
      info.dispose();
      return;
    }
    setState(() {
      _maskInfo?.dispose();
      _maskInfo = info;
      _maskFailed = false;
    });
  }

  void _handleMaskFailure() {
    if (!mounted) return;
    setState(() {
      _maskInfo?.dispose();
      _maskInfo = null;
      _maskFailed = true;
    });
  }

  /// Maps the silhouette pixels onto the painted frame [bounds].
  Float64List _maskShaderTransform(Rect bounds, ui.Image mask) {
    final scaleX = mask.width > 0 ? bounds.width / mask.width : 1.0;
    final scaleY = mask.height > 0 ? bounds.height / mask.height : 1.0;
    return (Matrix4.identity()
          ..setEntry(0, 0, scaleX)
          ..setEntry(1, 1, scaleY)
          ..setEntry(0, 3, bounds.left)
          ..setEntry(1, 3, bounds.top))
        .storage;
  }

  Widget _buildFramedContent() {
    const frameWidth = _kMusamiClipFrameBaseWidth;
    return SizedBox(
      width: frameWidth,
      height: frameWidth * _musamiSafeAspect(widget.maskAspect),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: frameWidth,
            height: frameWidth * _musamiSafeAspect(widget.contentAspect),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final framed = _buildFramedContent();
    final mask = _maskInfo?.image;
    if (mask == null) {
      // Keep the artwork visible when the silhouette cannot be loaded, and
      // hide it while loading so an unclipped frame never flashes.
      return _maskFailed ? framed : Opacity(opacity: 0, child: framed);
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => ui.ImageShader(
        mask,
        TileMode.clamp,
        TileMode.clamp,
        _maskShaderTransform(bounds, mask),
        filterQuality: FilterQuality.medium,
      ),
      child: framed,
    );
  }
}
