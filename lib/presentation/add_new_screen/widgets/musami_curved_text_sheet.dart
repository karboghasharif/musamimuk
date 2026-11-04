import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../utils/musami_curved_text_apply.dart';
import 'musami_curved_text_layer.dart';

/// Opens the curve editor for a curved [WidgetLayer], or converts a [TextLayer].
Future<void> showMusamiCurvedTextSheet({
  required BuildContext context,
  required ProImageEditorState editor,
  TextLayer? textLayer,
  WidgetLayer? curvedLayer,
  void Function(Layer layer)? onCommitted,
}) async {
  assert(textLayer != null || curvedLayer != null);

  final initial = curvedLayer != null
      ? MusamiCurvedTextParams.fromMeta(curvedLayer.meta)
      : MusamiCurvedTextParams.fromPlainText(
          text: textLayer!.text,
          style: textLayer.textStyle,
          align: textLayer.align,
          fallbackColor: textLayer.color,
        );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.72,
      child: _CurvedTextSheet(
        editor: editor,
        textLayer: textLayer,
        curvedLayer: curvedLayer,
        initial: initial,
        onCommitted: onCommitted,
      ),
    ),
  );
}

class _CurvedTextSheet extends StatefulWidget {
  const _CurvedTextSheet({
    required this.editor,
    required this.initial,
    this.textLayer,
    this.curvedLayer,
    this.onCommitted,
  });

  final ProImageEditorState editor;
  final TextLayer? textLayer;
  final WidgetLayer? curvedLayer;
  final MusamiCurvedTextParams initial;
  final void Function(Layer layer)? onCommitted;

  @override
  State<_CurvedTextSheet> createState() => _CurvedTextSheetState();
}

class _CurvedTextSheetState extends State<_CurvedTextSheet> {
  late MusamiCurvedTextParams _params;
  late final TextEditingController _textController;
  bool _dragging = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _params = widget.initial;
    _textController = TextEditingController(text: _params.sourceString);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _apply({bool removeCurve = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final editor = widget.editor;
      if (removeCurve && widget.curvedLayer != null) {
        final text = musamiRemoveCurveToTextLayer(
          editor: editor,
          layer: widget.curvedLayer!,
        );
        if (text != null) widget.onCommitted?.call(text);
        if (mounted) Navigator.of(context).maybePop();
        return;
      }

      final next = _params.copyWith(
        sourceString: _textController.text,
      );
      if (next.sourceString.trim().isEmpty) {
        showAppToast(
          'msg_curved_text_empty'.tr,
          type: ToastificationType.warning,
        );
        return;
      }

      if (widget.curvedLayer != null) {
        final live = editor.activeLayers.cast<Layer?>().firstWhere(
              (l) => l?.id == widget.curvedLayer!.id,
              orElse: () => widget.curvedLayer,
            );
        if (live is! WidgetLayer) return;
        final updated = musamiUpdateCurvedTextLayer(
          editor: editor,
          layer: live,
          params: next,
          commitHistory: true,
        );
        if (updated != null) widget.onCommitted?.call(updated);
      } else if (widget.textLayer != null) {
        final converted = musamiConvertTextLayerToCurved(
          editor: editor,
          textLayer: widget.textLayer!,
          paramsOverride: next,
        );
        if (converted != null) widget.onCommitted?.call(converted);
      }
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final previewStep = _dragging ? 2.5 : 1.0;
    return Material(
      color: AppDs.surfaceBase,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDs.radiusSheet.adaptSize),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 10.v),
            Container(
              width: 40.h,
              height: 4.v,
              decoration: BoxDecoration(
                color: AppDs.sheetBorderSubtle(),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 12.v, 8.h, 8.v),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.curvedLayer != null
                          ? 'lbl_edit_curve'.tr
                          : 'lbl_curve_text'.tr,
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.w700,
                        color: AppDs.textOnDarkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, color: AppDs.textOnDarkSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppDs.surfaceRaised,
                          borderRadius: BorderRadius.circular(12.h),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: MusamiCurvedTextLayer(
                            params: _params.copyWith(
                              sourceString: _textController.text.isEmpty
                                  ? 'مرحبا بكم'
                                  : _textController.text,
                            ),
                            stripStep: previewStep,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.v),
                    TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppDs.textOnDarkPrimary),
                      decoration: InputDecoration(
                        labelText: 'lbl_curved_text_content'.tr,
                        labelStyle: const TextStyle(
                          color: AppDs.textOnDarkSecondary,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      textDirection: _params.rtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                    SizedBox(height: 8.v),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'lbl_curved_text_arc'.tr,
                        style: TextStyle(
                          color: AppDs.textOnDarkSecondary,
                          fontSize: 13.fSize,
                        ),
                      ),
                    ),
                    Slider(
                      value: _params.arcAmount,
                      min: kMusamiCurvedArcAmountMin,
                      max: kMusamiCurvedArcAmountMax,
                      activeColor: primary,
                      onChangeStart: (_) => setState(() => _dragging = true),
                      onChanged: (v) {
                        setState(() {
                          _params = _params.copyWith(arcAmount: v);
                        });
                      },
                      onChangeEnd: (_) => setState(() => _dragging = false),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'lbl_curved_text_direction'.tr,
                        style: const TextStyle(color: AppDs.textOnDarkPrimary),
                      ),
                      subtitle: Text(
                        _params.clockwise
                            ? 'lbl_curved_text_clockwise'.tr
                            : 'lbl_curved_text_counterclockwise'.tr,
                        style: const TextStyle(
                          color: AppDs.textOnDarkSecondary,
                        ),
                      ),
                      value: _params.clockwise,
                      activeThumbColor: primary,
                      onChanged: (v) {
                        setState(() {
                          _params = _params.copyWith(clockwise: v);
                        });
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'lbl_curved_text_rtl'.tr,
                        style: const TextStyle(color: AppDs.textOnDarkPrimary),
                      ),
                      value: _params.rtl,
                      activeThumbColor: primary,
                      onChanged: (v) {
                        setState(() {
                          _params = _params.copyWith(rtl: v);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 12.v),
              child: Row(
                children: [
                  if (widget.curvedLayer != null)
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'lbl_remove_curve'.tr,
                        onPressed: _busy ? null : () => _apply(removeCurve: true),
                      ),
                    ),
                  if (widget.curvedLayer != null) SizedBox(width: 10.h),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'lbl_apply'.tr,
                      onPressed: _busy ? null : () => _apply(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
