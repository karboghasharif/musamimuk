import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'musami_curved_text_meta.dart';

/// Maps |arcAmount| ∈ [0,1] → sweep radians (gentle … near-circle).
double musamiCurvedTextSweepRadians(double arcAmount) {
  final t = musamiClampCurvedArcAmount(arcAmount).abs();
  const minSweep = 0.18 * math.pi;
  const maxSweep = 1.72 * math.pi;
  return minSweep + (maxSweep - minSweep) * t;
}

/// Lays out [params] as a straight line (Arabic shaping intact).
TextPainter musamiCurvedTextStraightPainter(MusamiCurvedTextParams params) {
  final text = params.sourceString.isEmpty ? ' ' : params.sourceString;
  final painter = TextPainter(
    text: TextSpan(text: text, style: params.textStyle),
    textAlign: params.textAlign,
    textDirection: params.textDirection,
    maxLines: 1,
    ellipsis: null,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  return painter;
}

/// Geometry for placing the straight text strip along an arc.
class MusamiCurvedTextGeometry {
  const MusamiCurvedTextGeometry({
    required this.radius,
    required this.sweep,
    required this.startAngle,
    required this.center,
    required this.bounds,
    required this.textWidth,
    required this.textHeight,
    required this.archUp,
  });

  final double radius;
  final double sweep;
  final double startAngle;
  final Offset center;
  final Size bounds;
  final double textWidth;
  final double textHeight;
  final bool archUp;
}

MusamiCurvedTextGeometry musamiCurvedTextGeometry(
  MusamiCurvedTextParams params, {
  TextPainter? painter,
}) {
  final tp = painter ?? musamiCurvedTextStraightPainter(params);
  final textW = math.max(tp.width, 1.0);
  final textH = math.max(tp.height, params.fontSize);
  final sweep = musamiCurvedTextSweepRadians(params.arcAmount);
  final radius = textW / sweep;
  final archUp = params.arcAmount >= 0;

  // Angles measured from +x, clockwise-positive in Flutter's y-down space is
  // actually standard math with y flipped visually — use Canvas coords.
  // Arch (text on top): center below baseline, mid angle = -π/2.
  // Smile (text on bottom): center above baseline, mid angle = +π/2.
  final mid = archUp ? -math.pi / 2 : math.pi / 2;
  final start = mid - sweep / 2;

  // Bounding box of the arc ribbon (radius ± half text height).
  final pad = textH * 0.55;
  final rOuter = radius + pad;
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = -double.infinity;
  double maxY = -double.infinity;
  const steps = 48;
  for (var i = 0; i <= steps; i++) {
    final a = start + sweep * (i / steps);
    final x = math.cos(a) * rOuter;
    final y = math.sin(a) * rOuter;
    minX = math.min(minX, x);
    minY = math.min(minY, y);
    maxX = math.max(maxX, x);
    maxY = math.max(maxY, y);
    final xi = math.cos(a) * (radius - pad);
    final yi = math.sin(a) * (radius - pad);
    minX = math.min(minX, xi);
    minY = math.min(minY, yi);
    maxX = math.max(maxX, xi);
    maxY = math.max(maxY, yi);
  }
  // Origin of local coords = circle center; shift so bounds top-left is 0,0.
  final bounds = Size(
    (maxX - minX).clamp(8.0, 4000.0),
    (maxY - minY).clamp(8.0, 4000.0),
  );
  final center = Offset(-minX, -minY);
  return MusamiCurvedTextGeometry(
    radius: radius,
    sweep: sweep,
    startAngle: start,
    center: center,
    bounds: bounds,
    textWidth: textW,
    textHeight: textH,
    archUp: archUp,
  );
}

Size musamiCurvedTextLayoutSize(MusamiCurvedTextParams params) {
  return musamiCurvedTextGeometry(params).bounds;
}

/// Paints shaped text along an arc by strip-warping the straight [TextPainter].
///
/// Shaping runs on the full string first (RTL / Arabic joining preserved), then
/// vertical 1px strips are placed along the circle tangent.
class MusamiCurvedTextPainter extends CustomPainter {
  MusamiCurvedTextPainter({
    required this.params,
    this.stripStep = 1.0,
  });

  final MusamiCurvedTextParams params;

  /// Horizontal sampling step in source pixels (2–3 = lighter live preview).
  final double stripStep;

  @override
  void paint(Canvas canvas, Size size) {
    if (params.sourceString.trim().isEmpty) return;

    final tp = musamiCurvedTextStraightPainter(params);
    final geo = musamiCurvedTextGeometry(params, painter: tp);

    final recorder = ui.PictureRecorder();
    final textCanvas = Canvas(recorder);
    tp.paint(textCanvas, Offset.zero);
    final picture = recorder.endRecording();

    final scaleX = size.width / geo.bounds.width;
    final scaleY = size.height / geo.bounds.height;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final step = stripStep.clamp(0.75, 4.0);
    final srcW = geo.textWidth;
    final srcH = geo.textHeight;
    final clockwise = params.clockwise;

    for (double x = 0; x < srcW; x += step) {
      final tRaw = (x + step * 0.5) / srcW;
      final t = clockwise ? (1.0 - tRaw) : tRaw;
      final angle = geo.startAngle + geo.sweep * t;
      // Tangent orientation: glyph baseline follows the circle.
      final rotation = angle + (geo.archUp ? math.pi / 2 : -math.pi / 2);

      final pos = Offset(
        geo.center.dx + math.cos(angle) * geo.radius,
        geo.center.dy + math.sin(angle) * geo.radius,
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);
      // Draw a thin vertical slice of the shaped text, centered on baseline.
      final sliceW = math.min(step + 0.75, srcW - x);
      canvas.clipRect(Rect.fromLTWH(-sliceW / 2, -srcH / 2, sliceW, srcH));
      canvas.translate(-x - sliceW / 2, -srcH / 2);
      canvas.drawPicture(picture);
      canvas.restore();
    }

    picture.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MusamiCurvedTextPainter oldDelegate) {
    return oldDelegate.params.sourceString != params.sourceString ||
        oldDelegate.params.arcAmount != params.arcAmount ||
        oldDelegate.params.clockwise != params.clockwise ||
        oldDelegate.params.rtl != params.rtl ||
        oldDelegate.params.fontSize != params.fontSize ||
        oldDelegate.params.fontFamily != params.fontFamily ||
        oldDelegate.params.fontWeight != params.fontWeight ||
        oldDelegate.params.fontStyle != params.fontStyle ||
        oldDelegate.params.color != params.color ||
        oldDelegate.params.letterSpacing != params.letterSpacing ||
        oldDelegate.stripStep != stripStep;
  }
}
