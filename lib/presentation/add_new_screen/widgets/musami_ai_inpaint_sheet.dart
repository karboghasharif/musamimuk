import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import 'musami_ai_chrome.dart';

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
          child: AppSheetPagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MusamiAiSheetHeader(
                  title: 'lbl_ai_inpaint'.tr,
                  subtitle: 'msg_ai_inpaint_mask_hint'.tr,
                  icon: Icons.format_paint_rounded,
                  trailing: IconButton(
                    tooltip: 'lbl_cancel'.tr,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space3.v),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: MusamiAiChrome.panelDeep,
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      border: Border.all(color: MusamiAiChrome.hairline),
                    ),
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
                                color: Colors.black,
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
                ),
                SizedBox(height: AppDs.space3.v),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  decoration: BoxDecoration(
                    color: MusamiAiChrome.panelDeep,
                    borderRadius: BorderRadius.circular(AppDs.radiusMd),
                    border: Border.all(color: MusamiAiChrome.hairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.brush_rounded,
                        size: 18,
                        color: MusamiAiChrome.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'lbl_ai_inpaint_brush'.tr,
                        style: const TextStyle(
                          color: AppDs.textOnDarkPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: MusamiAiChrome.accent,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.12),
                            thumbColor: MusamiAiChrome.accent,
                            overlayColor:
                                MusamiAiChrome.accent.withValues(alpha: 0.16),
                          ),
                          child: Slider(
                            value: _brush,
                            min: 12,
                            max: 64,
                            onChanged: (v) => setState(() => _brush = v),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'lbl_ai_inpaint_clear_mask'.tr,
                        onPressed: () => setState(() => _strokes.clear()),
                        icon: const Icon(
                          Icons.layers_clear_rounded,
                          color: AppDs.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDs.space3.v),
                TextField(
                  controller: _promptCtrl,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppDs.textOnDarkPrimary,
                    fontSize: 15,
                    height: 1.35,
                  ),
                  decoration: MusamiAiChrome.fieldDecoration(
                    hint: 'msg_ai_inpaint_prompt_hint'.tr,
                  ),
                ),
                SizedBox(height: AppDs.space4.v),
                MusamiAiPrimaryButton(
                  label: 'lbl_apply'.tr,
                  icon: Icons.auto_fix_high_rounded,
                  onPressed: _apply,
                ),
                MusamiAiGhostButton(
                  label: 'lbl_cancel'.tr,
                  onPressed: () => Navigator.pop(context),
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
      ..color = MusamiAiChrome.accent.withValues(alpha: 0.55)
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
          Paint()..color = MusamiAiChrome.accent.withValues(alpha: 0.55),
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
