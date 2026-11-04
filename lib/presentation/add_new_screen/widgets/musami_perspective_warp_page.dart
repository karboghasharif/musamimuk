import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../utils/musami_perspective_warp.dart';
import '../utils/musami_perspective_warp_meta.dart';

class MusamiPerspectiveWarpPageResult {
  const MusamiPerspectiveWarpPageResult({
    this.warped,
    this.resetToOriginal = false,
  });

  final MusamiPerspectiveWarpResult? warped;
  final bool resetToOriginal;
}

/// Full-screen 4-handle perspective editor.
class MusamiPerspectiveWarpPage extends StatefulWidget {
  const MusamiPerspectiveWarpPage({
    super.key,
    required this.sourceBytes,
    this.initialQuad,
    this.canReset = false,
  });

  final Uint8List sourceBytes;
  final List<double>? initialQuad;
  final bool canReset;

  @override
  State<MusamiPerspectiveWarpPage> createState() =>
      _MusamiPerspectiveWarpPageState();
}

class _MusamiPerspectiveWarpPageState extends State<MusamiPerspectiveWarpPage> {
  ui.Image? _previewImage;
  late List<Offset> _corners; // normalized 0–1 tl,tr,br,bl
  bool _busy = false;
  bool _dragging = false;
  int? _activeCorner;
  Size _imageLayout = Size.zero;

  static const _handleSize = 28.0;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuad ?? musamiDefaultWarpQuad();
    _corners = [
      Offset(q[0], q[1]),
      Offset(q[2], q[3]),
      Offset(q[4], q[5]),
      Offset(q[6], q[7]),
    ];
    _loadPreview();
  }

  @override
  void dispose() {
    _previewImage?.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final decoded = musamiDecodeImageForWarp(
      widget.sourceBytes,
      maxEdge: kMusamiWarpPreviewMaxEdge,
    );
    if (decoded == null || !mounted) return;
    final png = musamiEncodePreviewPng(decoded);
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() {
      _previewImage?.dispose();
      _previewImage = frame.image;
    });
  }

  List<double> get _quadList => [
        _corners[0].dx,
        _corners[0].dy,
        _corners[1].dx,
        _corners[1].dy,
        _corners[2].dx,
        _corners[2].dy,
        _corners[3].dx,
        _corners[3].dy,
      ];

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = musamiPerspectiveWarpPng(
        bytes: widget.sourceBytes,
        quadNormalized: _quadList,
        maxEdge: kMusamiWarpFullMaxEdge,
      );
      if (!mounted) return;
      if (result == null) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pop(
        MusamiPerspectiveWarpPageResult(warped: result),
      );
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetHandles() {
    setState(() {
      _corners = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];
    });
  }

  Offset _toLocal(Offset normalized) {
    return Offset(
      normalized.dx * _imageLayout.width,
      normalized.dy * _imageLayout.height,
    );
  }

  Offset _toNormalized(Offset local) {
    if (_imageLayout.width <= 0 || _imageLayout.height <= 0) {
      return Offset.zero;
    }
    return Offset(
      (local.dx / _imageLayout.width).clamp(0.0, 1.0),
      (local.dy / _imageLayout.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: AppDs.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppDs.surfaceRaised,
        title: Text('lbl_perspective_warp'.tr),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.canReset)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).pop(
                        const MusamiPerspectiveWarpPageResult(
                          resetToOriginal: true,
                        ),
                      ),
              child: Text('lbl_warp_reset'.tr),
            ),
          TextButton(
            onPressed: _busy ? null : _resetHandles,
            child: Text('lbl_warp_reset_handles'.tr),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final img = _previewImage;
                if (img == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final maxW = constraints.maxWidth - 32;
                final maxH = constraints.maxHeight - 32;
                final scale = math.min(maxW / img.width, maxH / img.height);
                final layout = Size(img.width * scale, img.height * scale);
                _imageLayout = layout;

                return Center(
                  child: SizedBox(
                    width: layout.width,
                    height: layout.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: RawImage(
                            image: img,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _QuadWirePainter(
                              corners: [
                                for (final c in _corners) _toLocal(c),
                              ],
                              color: primary,
                            ),
                          ),
                        ),
                        for (var i = 0; i < 4; i++)
                          Positioned(
                            left: _toLocal(_corners[i]).dx - _handleSize / 2,
                            top: _toLocal(_corners[i]).dy - _handleSize / 2,
                            child: GestureDetector(
                              onPanStart: (_) {
                                setState(() {
                                  _dragging = true;
                                  _activeCorner = i;
                                });
                              },
                              onPanUpdate: (d) {
                                final local = _toLocal(_corners[i]) + d.delta;
                                setState(() {
                                  _corners[i] = _toNormalized(local);
                                });
                              },
                              onPanEnd: (_) {
                                setState(() {
                                  _dragging = false;
                                  _activeCorner = null;
                                });
                              },
                              child: Container(
                                width: _handleSize,
                                height: _handleSize,
                                decoration: BoxDecoration(
                                  color: _activeCorner == i
                                      ? primary
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primary,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 4,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_dragging)
            Padding(
              padding: EdgeInsets.only(bottom: 4.v),
              child: Text(
                'lbl_warp_preview_hint'.tr,
                style: const TextStyle(color: AppDs.textOnDarkSecondary),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 12.v),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'lbl_cancel'.tr,
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 10.h),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'lbl_apply'.tr,
                      isLoading: _busy,
                      onPressed: _busy ? null : _apply,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuadWirePainter extends CustomPainter {
  _QuadWirePainter({required this.corners, required this.color});

  final List<Offset> corners;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..moveTo(corners[0].dx, corners[0].dy);
    for (var i = 1; i < 4; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuadWirePainter oldDelegate) => true;
}
