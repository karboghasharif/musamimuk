import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'musami_clipping_mask.dart';

/// Longest edge of a captured layer, in device pixels. Keeps a huge layer on a
/// high-DPI screen from allocating a several-hundred-megabyte bitmap.
const double _kMaxCaptureEdgePx = 4096;

/// Renders [content] at [logicalSize] into transparent PNG bytes.
///
/// The widget is mounted in the app [Overlay] at ~0 opacity for the couple of
/// frames it takes to paint, then removed. A [RepaintBoundary] owns its own
/// compositing layer, so the capture contains only [content] — never the
/// selection handles, the transform overlay or the rest of the canvas — and is
/// unaffected by the near-zero opacity of its ancestor.
///
/// Returns `null` when the capture could not be produced.
Future<Uint8List?> musamiCaptureWidgetPng({
  required BuildContext context,
  required Widget content,
  required Size logicalSize,
  double pixelRatio = 3,
}) async {
  if (!logicalSize.width.isFinite ||
      !logicalSize.height.isFinite ||
      logicalSize.width <= 0 ||
      logicalSize.height <= 0) {
    return null;
  }

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  await _precacheProviders(context, content);
  if (!context.mounted) return null;

  final longestEdge = math.max(logicalSize.width, logicalSize.height);
  final ratio = math
      .min(pixelRatio, _kMaxCaptureEdgePx / longestEdge)
      .clamp(1.0, pixelRatio);

  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: Opacity(
          // Exactly 0 would skip painting entirely and leave nothing to grab.
          opacity: 0.001,
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: logicalSize.width,
              height: logicalSize.height,
              child: FittedBox(fit: BoxFit.contain, child: content),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // One frame to mount and lay out, a second so any image that resolved
    // during the first frame has actually been painted.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final image = await renderObject.toImage(pixelRatio: ratio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  } finally {
    entry.remove();
    entry.dispose();
  }
}

/// Decodes every image in [root] up front so the offscreen frames paint pixels
/// instead of empty placeholders.
Future<void> _precacheProviders(BuildContext context, Widget root) async {
  final providers = _collectImageProviders(root);
  for (final provider in providers) {
    if (!context.mounted) return;
    try {
      await precacheImage(provider, context);
    } catch (_) {
      // A broken asset must not abort the export; it just renders empty.
    }
  }
}

List<ImageProvider> _collectImageProviders(Widget root) {
  final found = <ImageProvider>[];
  final queue = <Widget>[root];
  while (queue.isNotEmpty) {
    final widget = queue.removeAt(0);

    if (widget is Image) found.add(widget.image);

    final clipped = musamiTryUnwrapClipMaskedContent(widget);
    if (clipped != null) {
      queue.add(clipped);
      continue;
    }

    if (widget is SingleChildRenderObjectWidget) {
      final child = widget.child;
      if (child != null) queue.add(child);
    } else if (widget is MultiChildRenderObjectWidget) {
      queue.addAll(widget.children);
    } else if (widget is ProxyWidget) {
      queue.add(widget.child);
    }
  }
  return found;
}
