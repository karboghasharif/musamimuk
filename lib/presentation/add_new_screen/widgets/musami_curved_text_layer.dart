import 'package:flutter/material.dart';

import '../utils/musami_curved_text_meta.dart';
import '../utils/musami_curved_text_painter.dart';

/// Canvas widget for a curved-text [WidgetLayer].
class MusamiCurvedTextLayer extends StatelessWidget {
  const MusamiCurvedTextLayer({
    super.key,
    required this.params,
    this.stripStep = 1.0,
    this.width,
    this.height,
  });

  final MusamiCurvedTextParams params;

  /// >1 for lighter live preview while dragging the arc slider.
  final double stripStep;

  final double? width;
  final double? height;

  factory MusamiCurvedTextLayer.fromMeta(
    Map<String, dynamic>? meta, {
    Key? key,
    double stripStep = 1.0,
    double? width,
    double? height,
  }) {
    return MusamiCurvedTextLayer(
      key: key,
      params: MusamiCurvedTextParams.fromMeta(meta),
      stripStep: stripStep,
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = musamiCurvedTextLayoutSize(params);
    final w = width ?? size.width;
    final h = height ?? size.height;
    if (params.sourceString.trim().isEmpty) {
      return SizedBox(
        width: w.clamp(48.0, 4000.0),
        height: h.clamp(48.0, 4000.0),
        child: const Center(
          child: Icon(Icons.text_fields_outlined, size: 28),
        ),
      );
    }
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: MusamiCurvedTextPainter(
          params: params,
          stripStep: stripStep,
        ),
        size: Size(w, h),
      ),
    );
  }
}
