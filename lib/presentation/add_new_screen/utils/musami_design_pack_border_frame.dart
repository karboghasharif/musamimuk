import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Meta: border is a full-canvas frame (corners + edge tiles), not a sticker.
const String kMusamiBorderModeMetaKey = 'musamiBorderMode';
const String kMusamiBorderModeCanvasFrame = 'canvas_frame';
const String kMusamiBorderCornerPathMetaKey = 'musamiBorderCornerPath';
const String kMusamiBorderEdgePathMetaKey = 'musamiBorderEdgePath';

/// Optional absolute motif size (px) — driven by Border thickness slider.
const String kMusamiBorderMotifSizeMetaKey = 'musamiBorderMotifSize';

/// Motif size as a fraction of the shorter canvas side.
const double kMusamiBorderMotifCanvasFraction = 0.15;
const double kMusamiBorderMotifMin = 24;
const double kMusamiBorderMotifMax = 280;

/// Border sheet slider range mapped onto motif size for canvas frames.
const double kMusamiBorderThicknessSliderMax = 12;

bool musamiMetaIsCanvasBorderFrame(Map<String, dynamic>? meta) {
  if (meta == null) return false;
  if (meta[kMusamiBorderModeMetaKey]?.toString() ==
      kMusamiBorderModeCanvasFrame) {
    return true;
  }
  // Borders category without mode still treated as frame when kind matches.
  return meta['musamiLayerKind']?.toString() == 'design_pack_border' &&
      meta[kMusamiBorderModeMetaKey] == null &&
      (meta[kMusamiBorderCornerPathMetaKey] != null ||
          meta[kMusamiBorderEdgePathMetaKey] != null);
}

/// Maps `files/border-*.svg` ↔ `files/corner-*.svg` (and named families).
String musamiPairedBorderAssetPath(String assetPath) {
  final i = assetPath.lastIndexOf('/');
  final dir = i >= 0 ? assetPath.substring(0, i + 1) : '';
  final file = i >= 0 ? assetPath.substring(i + 1) : assetPath;
  if (file.startsWith('corner-')) {
    return '$dir${file.replaceFirst('corner-', 'border-')}';
  }
  if (file.startsWith('border-')) {
    return '$dir${file.replaceFirst('border-', 'corner-')}';
  }
  return assetPath;
}

bool musamiAssetPathLooksLikeCorner(String assetPath) {
  final file = assetPath.split('/').last.toLowerCase();
  return file.startsWith('corner-');
}

Future<bool> musamiAssetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}

/// Resolves corner + edge asset paths for a selected borders-pack item.
Future<({String cornerPath, String edgePath})> musamiResolveBorderFramePaths(
  String selectedPath,
) async {
  final pair = musamiPairedBorderAssetPath(selectedPath);
  final pairOk =
      pair != selectedPath && await musamiAssetExists(pair);

  if (musamiAssetPathLooksLikeCorner(selectedPath)) {
    return (
      cornerPath: selectedPath,
      edgePath: pairOk ? pair : selectedPath,
    );
  }
  return (
    cornerPath: pairOk ? pair : selectedPath,
    edgePath: selectedPath,
  );
}

double musamiBorderMotifSize(Size canvas, {double? overridePx}) {
  if (overridePx != null && overridePx.isFinite && overridePx > 0) {
    return overridePx.clamp(kMusamiBorderMotifMin, kMusamiBorderMotifMax);
  }
  final m = math.min(canvas.width, canvas.height) *
      kMusamiBorderMotifCanvasFraction;
  return m.clamp(kMusamiBorderMotifMin, kMusamiBorderMotifMax);
}

/// Maps Border sheet thickness (0…12) → motif px for the given frame size.
double musamiBorderMotifSizeFromThickness(Size canvas, double thickness) {
  if (thickness <= 0.05) {
    return musamiBorderMotifSize(canvas);
  }
  final t = thickness.clamp(0.0, kMusamiBorderThicknessSliderMax);
  final minSide = math.min(canvas.width, canvas.height);
  final minM = (minSide * 0.06).clamp(kMusamiBorderMotifMin, kMusamiBorderMotifMax);
  final maxM = (minSide * 0.28).clamp(kMusamiBorderMotifMin, kMusamiBorderMotifMax);
  final tNorm = t / kMusamiBorderThicknessSliderMax;
  return (minM + (maxM - minM) * tNorm)
      .clamp(kMusamiBorderMotifMin, kMusamiBorderMotifMax);
}

/// Sync frame width/height meta from the live layer geometry.
void musamiSyncCanvasBorderFrameMetaSize(
  Map<String, dynamic> meta, {
  required double width,
  required double aspect,
}) {
  final w = width <= 0 || !width.isFinite ? 1.0 : width;
  final a = aspect <= 0 || !aspect.isFinite ? 1.0 : aspect;
  meta['musamiFrameWidth'] = w;
  meta['musamiFrameHeight'] = w * a;
  meta['musamiAspect'] = a;
  meta['musamiImageAspect'] = a;
}

/// Full-bleed decorative frame: corners on all four corners + tiles on all sides.
class MusamiDesignPackBorderFrame extends StatelessWidget {
  const MusamiDesignPackBorderFrame({
    super.key,
    required this.size,
    required this.cornerAssetPath,
    required this.edgeAssetPath,
    this.tint,
    this.motifSize,
    this.isSvg = true,
  });

  final Size size;
  final String cornerAssetPath;
  final String edgeAssetPath;
  final Color? tint;
  final double? motifSize;
  final bool isSvg;

  factory MusamiDesignPackBorderFrame.fromMeta(Map<String, dynamic>? meta) {
    final w = (meta?['musamiFrameWidth'] as num?)?.toDouble() ?? 1080;
    final h = (meta?['musamiFrameHeight'] as num?)?.toDouble() ?? 1080;
    final asset = meta?['assetPath']?.toString() ?? '';
    final corner = meta?[kMusamiBorderCornerPathMetaKey]?.toString() ?? asset;
    final edge = meta?[kMusamiBorderEdgePathMetaKey]?.toString() ?? asset;
    final tintArgb = (meta?['musamiImageTintArgb'] as num?)?.toInt();
    final motifOverride =
        (meta?[kMusamiBorderMotifSizeMetaKey] as num?)?.toDouble();
    // Fall back: map legacy Border stroke width into motif thickness.
    final borderW = (meta?['musamiBorderW'] as num?)?.toDouble();
    final motif = motifOverride ??
        (borderW != null && borderW > 0.05
            ? musamiBorderMotifSizeFromThickness(Size(w, h), borderW)
            : null);
    return MusamiDesignPackBorderFrame(
      size: Size(w, h),
      cornerAssetPath: corner,
      edgeAssetPath: edge,
      tint: tintArgb == null ? null : Color(tintArgb),
      motifSize: motif,
      isSvg: (corner.isNotEmpty ? corner : edge).toLowerCase().endsWith('.svg'),
    );
  }

  ColorFilter? get _tintFilter {
    if (tint == null) return null;
    return ColorFilter.mode(tint!, BlendMode.srcIn);
  }

  Widget _motif({
    required String path,
    required double side,
    double rotation = 0,
    bool flipX = false,
    bool flipY = false,
  }) {
    Widget child;
    if (isSvg || path.toLowerCase().endsWith('.svg')) {
      child = SvgPicture.asset(
        path,
        width: side,
        height: side,
        fit: BoxFit.contain,
        colorFilter: _tintFilter,
        placeholderBuilder: (_) => SizedBox(width: side, height: side),
        errorBuilder: (_, _, _) => SizedBox(width: side, height: side),
      );
    } else {
      child = Image.asset(
        path,
        width: side,
        height: side,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => SizedBox(width: side, height: side),
      );
      if (_tintFilter != null) {
        child = ColorFiltered(colorFilter: _tintFilter!, child: child);
      }
    }

    if (flipX || flipY) {
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          flipX ? -1.0 : 1.0,
          flipY ? -1.0 : 1.0,
          1.0,
        ),
        child: child,
      );
    }
    if (rotation != 0) {
      child = Transform.rotate(angle: rotation, child: child);
    }
    return SizedBox(width: side, height: side, child: child);
  }

  Widget _edgeStrip({
    required Axis axis,
    required double length,
    required double motif,
    required double rotation,
  }) {
    final usable = math.max(0.0, length - motif);
    final count = math.max(1, (usable / motif).floor());
    final tiles = List<Widget>.generate(
      count,
      (_) => _motif(path: edgeAssetPath, side: motif, rotation: rotation),
      growable: false,
    );
    if (axis == Axis.horizontal) {
      return SizedBox(
        height: motif,
        width: length,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: tiles,
        ),
      );
    }
    return SizedBox(
      width: motif,
      height: length,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = size.width <= 0 ? 1.0 : size.width;
    final h = size.height <= 0 ? 1.0 : size.height;
    final motif = musamiBorderMotifSize(Size(w, h), overridePx: motifSize);
    final edgeLenH = math.max(0.0, w - motif);
    final edgeLenV = math.max(0.0, h - motif);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Top edge
          Positioned(
            left: motif * 0.5,
            top: 0,
            child: _edgeStrip(
              axis: Axis.horizontal,
              length: edgeLenH,
              motif: motif,
              rotation: 0,
            ),
          ),
          // Bottom edge
          Positioned(
            left: motif * 0.5,
            bottom: 0,
            child: _edgeStrip(
              axis: Axis.horizontal,
              length: edgeLenH,
              motif: motif,
              rotation: math.pi,
            ),
          ),
          // Left edge
          Positioned(
            left: 0,
            top: motif * 0.5,
            child: _edgeStrip(
              axis: Axis.vertical,
              length: edgeLenV,
              motif: motif,
              rotation: -math.pi / 2,
            ),
          ),
          // Right edge
          Positioned(
            right: 0,
            top: motif * 0.5,
            child: _edgeStrip(
              axis: Axis.vertical,
              length: edgeLenV,
              motif: motif,
              rotation: math.pi / 2,
            ),
          ),
          // Corners (on top of edges)
          Positioned(
            left: 0,
            top: 0,
            child: _motif(path: cornerAssetPath, side: motif),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _motif(path: cornerAssetPath, side: motif, flipX: true),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _motif(
              path: cornerAssetPath,
              side: motif,
              flipX: true,
              flipY: true,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _motif(path: cornerAssetPath, side: motif, flipY: true),
          ),
        ],
      ),
    );
  }
}
