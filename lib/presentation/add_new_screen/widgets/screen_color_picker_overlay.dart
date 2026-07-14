import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/app_export.dart';

/// Full-screen eyedropper that samples pixels from a [RepaintBoundary].
class ScreenColorPickerOverlay extends StatefulWidget {
  const ScreenColorPickerOverlay({
    super.key,
    required this.repaintBoundaryKey,
    required this.onColorPicked,
    required this.onCancel,
  });

  final GlobalKey repaintBoundaryKey;
  final ValueChanged<Color> onColorPicked;
  final VoidCallback onCancel;

  @override
  State<ScreenColorPickerOverlay> createState() =>
      _ScreenColorPickerOverlayState();
}

class _ScreenColorPickerOverlayState extends State<ScreenColorPickerOverlay> {
  static const double _magnifierSize = 88;
  static const int _magnifierZoom = 8;

  Uint8List? _pixels;
  int _imageWidth = 0;
  int _imageHeight = 0;
  double _pixelRatio = 1;
  Color _sampledColor = Colors.white;
  Offset? _pointerGlobal;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureSnapshot());
  }

  Future<void> _captureSnapshot() async {
    if (!mounted) return;
    setState(() => _isCapturing = true);

    final boundary = widget.repaintBoundaryKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) {
      if (mounted) setState(() => _isCapturing = false);
      return;
    }

    _pixelRatio = MediaQuery.devicePixelRatioOf(context);
    try {
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (!mounted || byteData == null) return;
      setState(() {
        _pixels = byteData.buffer.asUint8List();
        _imageWidth = width;
        _imageHeight = height;
        _isCapturing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Color? _colorAtGlobal(Offset global) {
    final pixels = _pixels;
    if (pixels == null) return null;

    final boundary = widget.repaintBoundaryKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (boundary == null || !boundary.hasSize) return null;

    final local = boundary.globalToLocal(global);
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > boundary.size.width ||
        local.dy > boundary.size.height) {
      return null;
    }

    final x = (local.dx * _pixelRatio).round().clamp(0, _imageWidth - 1);
    final y = (local.dy * _pixelRatio).round().clamp(0, _imageHeight - 1);
    final offset = (y * _imageWidth + x) * 4;
    if (offset + 3 >= pixels.length) return null;

    return Color.fromARGB(
      pixels[offset + 3],
      pixels[offset],
      pixels[offset + 1],
      pixels[offset + 2],
    );
  }

  void _handlePointer(Offset global) {
    final color = _colorAtGlobal(global);
    if (color == null) return;
    setState(() {
      _pointerGlobal = global;
      _sampledColor = color;
    });
  }

  void _confirmPick() {
    widget.onColorPicked(_sampledColor);
  }

  String _toHex(Color c) {
    return '#${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pointer = _pointerGlobal;
    final topInset = MediaQuery.paddingOf(context).top;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _handlePointer(e.position),
            onPointerMove: (e) => _handlePointer(e.position),
            onPointerUp: (_) => _confirmPick(),
          ),
          if (_isCapturing)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: topInset + 8,
            left: 12,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close, color: Colors.white),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        'msg_screen_color_picker_active'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _sampledColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _toHex(_sampledColor).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (pointer != null) _buildMagnifier(pointer),
          if (pointer == null && !_isCapturing)
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'msg_screen_color_picker_drag_hint'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMagnifier(Offset global) {
    final left = (global.dx - _magnifierSize / 2)
        .clamp(8.0, MediaQuery.sizeOf(context).width - _magnifierSize - 8);
    final top = (global.dy - _magnifierSize - 24)
        .clamp(8.0, MediaQuery.sizeOf(context).height - _magnifierSize - 8);

    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _magnifierSize,
            height: _magnifierSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(child: _buildMagnifierContent(global)),
          ),
          const SizedBox(height: 6),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _sampledColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnifierContent(Offset global) {
    final pixels = _pixels;
    if (pixels == null) {
      return ColoredBox(color: _sampledColor);
    }

    final boundary = widget.repaintBoundaryKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (boundary == null) return ColoredBox(color: _sampledColor);

    final local = boundary.globalToLocal(global);
    final centerX = (local.dx * _pixelRatio).round();
    final centerY = (local.dy * _pixelRatio).round();
    final half = (_magnifierSize / _magnifierZoom / 2).round();

    return CustomPaint(
      painter: _MagnifierPainter(
        pixels: pixels,
        imageWidth: _imageWidth,
        imageHeight: _imageHeight,
        centerX: centerX,
        centerY: centerY,
        sampleRadius: half,
      ),
      size: const Size(_magnifierSize, _magnifierSize),
    );
  }
}

class _MagnifierPainter extends CustomPainter {
  _MagnifierPainter({
    required this.pixels,
    required this.imageWidth,
    required this.imageHeight,
    required this.centerX,
    required this.centerY,
    required this.sampleRadius,
  });

  final Uint8List pixels;
  final int imageWidth;
  final int imageHeight;
  final int centerX;
  final int centerY;
  final int sampleRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / (sampleRadius * 2 + 1);
    final cellH = size.height / (sampleRadius * 2 + 1);

    for (var dy = -sampleRadius; dy <= sampleRadius; dy++) {
      for (var dx = -sampleRadius; dx <= sampleRadius; dx++) {
        final x = (centerX + dx).clamp(0, imageWidth - 1);
        final y = (centerY + dy).clamp(0, imageHeight - 1);
        final offset = (y * imageWidth + x) * 4;
        if (offset + 3 >= pixels.length) continue;

        final paint = Paint()
          ..color = Color.fromARGB(
            pixels[offset + 3],
            pixels[offset],
            pixels[offset + 1],
            pixels[offset + 2],
          );
        canvas.drawRect(
          Rect.fromLTWH(
            (dx + sampleRadius) * cellW,
            (dy + sampleRadius) * cellH,
            cellW + 0.5,
            cellH + 0.5,
          ),
          paint,
        );
      }
    }

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(
      Offset(cx - 6, cy),
      Offset(cx + 6, cy),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(cx, cy - 6),
      Offset(cx, cy + 6),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _MagnifierPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.centerY != centerY ||
        oldDelegate.pixels != pixels;
  }
}
