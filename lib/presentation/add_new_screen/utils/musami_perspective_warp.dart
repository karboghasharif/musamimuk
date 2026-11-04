import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'musami_perspective_warp_meta.dart';

/// One corner in image / output pixel space.
class MusamiWarpPoint {
  const MusamiWarpPoint(this.x, this.y);
  final double x;
  final double y;
}

/// Result of [musamiPerspectiveWarpPng].
class MusamiPerspectiveWarpResult {
  const MusamiPerspectiveWarpResult({
    required this.pngBytes,
    required this.width,
    required this.height,
    required this.quadNormalized,
  });

  final Uint8List pngBytes;
  final int width;
  final int height;

  /// Destination quad in 0–1 of the **source** image (tl,tr,br,bl).
  final List<double> quadNormalized;
}

/// Scales [src] so its longest edge ≤ [maxEdge]. Returns [src] if already small.
img.Image musamiDownscaleImage(img.Image src, int maxEdge) {
  final longest = math.max(src.width, src.height);
  if (longest <= maxEdge || maxEdge <= 0) return src;
  final scale = maxEdge / longest;
  final w = math.max(1, (src.width * scale).round());
  final h = math.max(1, (src.height * scale).round());
  return img.copyResize(
    src,
    width: w,
    height: h,
    interpolation: img.Interpolation.linear,
  );
}

/// Decodes [bytes] and optionally downscales to [maxEdge].
img.Image? musamiDecodeImageForWarp(Uint8List bytes, {int? maxEdge}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  if (maxEdge == null) return decoded;
  return musamiDownscaleImage(decoded, maxEdge);
}

/// PNG encode for preview / ui.Image codec.
Uint8List musamiEncodePreviewPng(img.Image image) {
  return Uint8List.fromList(img.encodePng(image));
}

/// Builds a 3×3 homography mapping destination → source (row-major 9).
///
/// Correspondences: [srcCorners][i] ↔ [dstCorners][i], length 4 (tl,tr,br,bl).
Float64List? musamiComputeHomography({
  required List<MusamiWarpPoint> srcCorners,
  required List<MusamiWarpPoint> dstCorners,
}) {
  if (srcCorners.length != 4 || dstCorners.length != 4) return null;

  // Solve Ah = b for h00..h21 with h22 = 1 (8 unknowns).
  final a = List.generate(8, (_) => List<double>.filled(8, 0));
  final b = List<double>.filled(8, 0);

  for (var i = 0; i < 4; i++) {
    final x = dstCorners[i].x;
    final y = dstCorners[i].y;
    final u = srcCorners[i].x;
    final v = srcCorners[i].y;
    final r1 = i * 2;
    final r2 = r1 + 1;
    a[r1][0] = x;
    a[r1][1] = y;
    a[r1][2] = 1;
    a[r1][3] = 0;
    a[r1][4] = 0;
    a[r1][5] = 0;
    a[r1][6] = -u * x;
    a[r1][7] = -u * y;
    b[r1] = u;

    a[r2][0] = 0;
    a[r2][1] = 0;
    a[r2][2] = 0;
    a[r2][3] = x;
    a[r2][4] = y;
    a[r2][5] = 1;
    a[r2][6] = -v * x;
    a[r2][7] = -v * y;
    b[r2] = v;
  }

  final h8 = _solveLinearSystem(a, b);
  if (h8 == null) return null;
  return Float64List.fromList([
    h8[0],
    h8[1],
    h8[2],
    h8[3],
    h8[4],
    h8[5],
    h8[6],
    h8[7],
    1.0,
  ]);
}

MusamiWarpPoint? musamiApplyHomography(Float64List h, double x, double y) {
  final w = h[6] * x + h[7] * y + h[8];
  if (w.abs() < 1e-12) return null;
  return MusamiWarpPoint(
    (h[0] * x + h[1] * y + h[2]) / w,
    (h[3] * x + h[4] * y + h[5]) / w,
  );
}

/// Warps [src] so its rectangle maps onto [quadNormalized] (tl,tr,br,bl in 0–1).
///
/// Output is a tight RGBA PNG cropped to the warped silhouette.
MusamiPerspectiveWarpResult? musamiPerspectiveWarpImage({
  required img.Image src,
  required List<double> quadNormalized,
  int maxEdge = kMusamiWarpFullMaxEdge,
}) {
  final quad = musamiParseWarpQuad(quadNormalized) ?? musamiDefaultWarpQuad();
  final working = musamiDownscaleImage(src, maxEdge);
  final sw = working.width.toDouble();
  final sh = working.height.toDouble();

  final dst = <MusamiWarpPoint>[
    MusamiWarpPoint(quad[0] * sw, quad[1] * sh),
    MusamiWarpPoint(quad[2] * sw, quad[3] * sh),
    MusamiWarpPoint(quad[4] * sw, quad[5] * sh),
    MusamiWarpPoint(quad[6] * sw, quad[7] * sh),
  ];

  // Bounding box of destination quad in source-pixel space.
  var minX = dst[0].x;
  var maxX = dst[0].x;
  var minY = dst[0].y;
  var maxY = dst[0].y;
  for (final p in dst) {
    minX = math.min(minX, p.x);
    maxX = math.max(maxX, p.x);
    minY = math.min(minY, p.y);
    maxY = math.max(maxY, p.y);
  }
  // Pad 1px so edges don't clip.
  minX = minX.floorToDouble() - 1;
  minY = minY.floorToDouble() - 1;
  maxX = maxX.ceilToDouble() + 1;
  maxY = maxY.ceilToDouble() + 1;
  final outW = math.max(1, (maxX - minX).round());
  final outH = math.max(1, (maxY - minY).round());
  if (outW > maxEdge * 2 || outH > maxEdge * 2) {
    // Pathological quad — refuse.
    return null;
  }

  // Map output pixel → source: dest corners are shifted into output space.
  final dstOut = [
    for (final p in dst) MusamiWarpPoint(p.x - minX, p.y - minY),
  ];
  final srcCorners = [
    const MusamiWarpPoint(0, 0),
    MusamiWarpPoint(sw - 1, 0),
    MusamiWarpPoint(sw - 1, sh - 1),
    MusamiWarpPoint(0, sh - 1),
  ];
  final h = musamiComputeHomography(srcCorners: srcCorners, dstCorners: dstOut);
  if (h == null) return null;

  final out = img.Image(width: outW, height: outH, numChannels: 4);
  for (var y = 0; y < outH; y++) {
    for (var x = 0; x < outW; x++) {
      final mapped = musamiApplyHomography(h, x + 0.5, y + 0.5);
      if (mapped == null) continue;
      final sx = mapped.x;
      final sy = mapped.y;
      if (sx < -0.5 || sy < -0.5 || sx >= sw || sy >= sh) continue;
      // Soft edge: only fill if inside the destination quad.
      if (!_pointInConvexQuad(x + 0.5, y + 0.5, dstOut)) continue;
      final c = _sampleBilinear(working, sx, sy);
      out.setPixelRgba(x, y, c.r, c.g, c.b, c.a);
    }
  }

  final encoded = img.encodePng(out);
  return MusamiPerspectiveWarpResult(
    pngBytes: Uint8List.fromList(encoded),
    width: outW,
    height: outH,
    quadNormalized: List<double>.from(quad),
  );
}

/// Convenience: decode [bytes], warp, return PNG result.
MusamiPerspectiveWarpResult? musamiPerspectiveWarpPng({
  required Uint8List bytes,
  required List<double> quadNormalized,
  int maxEdge = kMusamiWarpFullMaxEdge,
}) {
  final decoded = musamiDecodeImageForWarp(bytes, maxEdge: maxEdge);
  if (decoded == null) return null;
  return musamiPerspectiveWarpImage(
    src: decoded,
    quadNormalized: quadNormalized,
    maxEdge: maxEdge,
  );
}

class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);
  final int r, g, b, a;
}

_Rgba _sampleBilinear(img.Image src, double x, double y) {
  final x0 = x.floor().clamp(0, src.width - 1);
  final y0 = y.floor().clamp(0, src.height - 1);
  final x1 = (x0 + 1).clamp(0, src.width - 1);
  final y1 = (y0 + 1).clamp(0, src.height - 1);
  final fx = x - x.floorToDouble();
  final fy = y - y.floorToDouble();

  final p00 = src.getPixel(x0, y0);
  final p10 = src.getPixel(x1, y0);
  final p01 = src.getPixel(x0, y1);
  final p11 = src.getPixel(x1, y1);

  int lerpChannel(num a, num b, num c, num d) {
    final top = a + (b - a) * fx;
    final bot = c + (d - c) * fx;
    return (top + (bot - top) * fy).round().clamp(0, 255);
  }

  return _Rgba(
    lerpChannel(p00.r, p10.r, p01.r, p11.r),
    lerpChannel(p00.g, p10.g, p01.g, p11.g),
    lerpChannel(p00.b, p10.b, p01.b, p11.b),
    lerpChannel(p00.a, p10.a, p01.a, p11.a),
  );
}

bool _pointInConvexQuad(double x, double y, List<MusamiWarpPoint> q) {
  // Same winding cross-product test for all edges.
  var sign = 0.0;
  for (var i = 0; i < 4; i++) {
    final a = q[i];
    final b = q[(i + 1) % 4];
    final cross = (b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x);
    if (cross.abs() < 1e-9) continue;
    if (sign == 0) {
      sign = cross;
    } else if (cross.sign != sign.sign) {
      return false;
    }
  }
  return true;
}

/// Gaussian elimination with partial pivoting. Returns null if singular.
List<double>? _solveLinearSystem(List<List<double>> a, List<double> b) {
  final n = b.length;
  final m = List.generate(n, (i) => List<double>.from(a[i])..add(b[i]));

  for (var col = 0; col < n; col++) {
    var pivot = col;
    var best = m[col][col].abs();
    for (var row = col + 1; row < n; row++) {
      final v = m[row][col].abs();
      if (v > best) {
        best = v;
        pivot = row;
      }
    }
    if (best < 1e-12) return null;
    if (pivot != col) {
      final tmp = m[col];
      m[col] = m[pivot];
      m[pivot] = tmp;
    }
    final div = m[col][col];
    for (var j = col; j <= n; j++) {
      m[col][j] /= div;
    }
    for (var row = 0; row < n; row++) {
      if (row == col) continue;
      final factor = m[row][col];
      for (var j = col; j <= n; j++) {
        m[row][j] -= factor * m[col][j];
      }
    }
  }
  return [for (var i = 0; i < n; i++) m[i][n]];
}
