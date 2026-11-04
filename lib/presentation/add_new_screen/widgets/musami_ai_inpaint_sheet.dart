import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Sheet: paint white edit regions over [imageBytes], enter prompt.
Future<({Uint8List maskPng, String prompt})?> showMusamiAiInpaintSheet({
  required BuildContext context,
  required Uint8List imageBytes,
}) {
  return showAppModalBottomSheet<({Uint8List maskPng, String prompt})>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return _MusamiAiInpaintSheet(imageBytes: imageBytes);
    },
  );
}

class _MusamiAiInpaintSheet extends StatefulWidget {
  const _MusamiAiInpaintSheet({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_MusamiAiInpaintSheet> createState() => _MusamiAiInpaintSheetState();
}

class _MusamiAiInpaintSheetState extends State<_MusamiAiInpaintSheet> {
  final _promptCtrl = TextEditingController();
  final _strokes = <List<Offset>>[];
  List<Offset>? _current;
  double _brush = 28;
  Size _paintSize = Size.zero;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('msg_ai_inpaint_prompt_required'.tr)),
      );
      return;
    }
    if (_strokes.isEmpty || _paintSize == Size.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('msg_ai_inpaint_mask_required'.tr)),
      );
      return;
    }
    final mask = await _encodeMaskPng(_paintSize, _strokes, _brush);
    if (!mounted || mask == null) return;
    Navigator.pop(context, (maskPng: mask, prompt: prompt));
  }

  static Future<Uint8List?> _encodeMaskPng(
    Size size,
    List<List<Offset>> strokes,
    double brush,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = size.width.ceil().clamp(1, 4096);
    final h = size.height.ceil().clamp(1, 4096);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = Colors.black,
    );
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = brush
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          brush / 2,
          Paint()..color = Colors.white,
        );
        continue;
      }
      for (var i = 1; i < stroke.length; i++) {
        canvas.drawLine(stroke[i - 1], stroke[i], paint);
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return AppDarkSheetTheme(
      child: SizedBox(
        height: height,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space3.v,
              AppDs.space4.h,
              AppDs.space3.v,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_ai_inpaint'.tr,
                  style: AppDs.sheetTitle(
                    Theme.of(context),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: AppDs.space1.v),
                Text(
                  'msg_ai_inpaint_mask_hint'.tr,
                  style: TextStyle(
                    color: AppDs.textOnDarkSecondary,
                    fontSize: 12.fSize,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDs.radiusMd),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _paintSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: Colors.black87,
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                            GestureDetector(
                              onPanStart: (d) {
                                setState(() {
                                  _current = [d.localPosition];
                                  _strokes.add(_current!);
                                });
                              },
                              onPanUpdate: (d) {
                                setState(() {
                                  _current?.add(d.localPosition);
                                });
                              },
                              onPanEnd: (_) => _current = null,
                              child: CustomPaint(
                                painter: _MaskPreviewPainter(
                                  strokes: _strokes,
                                  brush: _brush,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Row(
                  children: [
                    Text(
                      'lbl_ai_inpaint_brush'.tr,
                      style: TextStyle(color: Colors.white, fontSize: 12.fSize),
                    ),
                    Expanded(
                      child: Slider(
                        value: _brush,
                        min: 12,
                        max: 64,
                        onChanged: (v) => setState(() => _brush = v),
                      ),
                    ),
                    IconButton(
                      tooltip: 'lbl_ai_inpaint_clear_mask'.tr,
                      onPressed: () => setState(() => _strokes.clear()),
                      icon: const Icon(Icons.clear, color: Colors.white70),
                    ),
                  ],
                ),
                TextField(
                  controller: _promptCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'msg_ai_inpaint_prompt_hint'.tr,
                    hintStyle: TextStyle(color: AppDs.textOnDarkSecondary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space3.v),
                FilledButton(
                  onPressed: _apply,
                  child: Text('lbl_apply'.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('lbl_cancel'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaskPreviewPainter extends CustomPainter {
  _MaskPreviewPainter({required this.strokes, required this.brush});

  final List<List<Offset>> strokes;
  final double brush;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = brush
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          brush / 2,
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
        continue;
      }
      for (var i = 1; i < stroke.length; i++) {
        canvas.drawLine(stroke[i - 1], stroke[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPreviewPainter oldDelegate) => true;
}
