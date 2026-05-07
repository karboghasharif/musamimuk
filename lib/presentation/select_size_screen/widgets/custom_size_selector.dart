import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';

class CustomSizeSelector extends StatefulWidget {
  const CustomSizeSelector({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    required this.onCreate,
  });

  final double initialWidth;
  final double initialHeight;
  final void Function({
    required double width,
    required double height,
    required String unit,
  })
  onCreate;

  @override
  State<CustomSizeSelector> createState() => _CustomSizeSelectorState();
}

class _CustomSizeSelectorState extends State<CustomSizeSelector> {
  static const double _minDim = 1;

  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;

  double _w = 500;
  double _h = 500;
  String _unit = 'px';

  @override
  void initState() {
    super.initState();
    _w = widget.initialWidth;
    _h = widget.initialHeight;
    _wCtrl = TextEditingController(text: _w.toInt().toString());
    _hCtrl = TextEditingController(text: _h.toInt().toString());
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  double _maxW(BuildContext context) => MediaQuery.sizeOf(context).width * 8;
  double _maxH(BuildContext context) => MediaQuery.sizeOf(context).height * 8;

  void _syncFromText() {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    if (w == null || h == null) return;
    setState(() {
      _w = w.clamp(_minDim, _maxW(context));
      _h = h.clamp(_minDim, _maxH(context));
    });
  }

  void _syncTextFromSliders() {
    _wCtrl.text = _w.toInt().toString();
    _hCtrl.text = _h.toInt().toString();
  }

  InputDecoration _fieldDeco(ThemeData theme, {required String label}) =>
      InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.amber.withValues(alpha: 0.01),
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.adaptSize),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.adaptSize),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.adaptSize),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 14.v),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxW = _maxW(context);
    final maxH = _maxH(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.all(14.adaptSize),
      decoration: BoxDecoration(
        color: appTheme.blueGray90002,
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_custom_size'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.v),
          if (isNarrow) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _syncFromText(),
                    decoration: _fieldDeco(theme, label: 'lbl_width'.tr),
                  ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: TextField(
                    controller: _hCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _syncFromText(),
                    decoration: _fieldDeco(theme, label: 'lbl_height'.tr),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.v),
            SizedBox(
              width: 160.h,
              child: DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: _fieldDeco(theme, label: 'lbl_unit'.tr),
                items: [
                  DropdownMenuItem(value: 'px', child: Text('lbl_pixels'.tr)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _unit = v);
                },
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _syncFromText(),
                    decoration: _fieldDeco(theme, label: 'lbl_width'.tr),
                  ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: TextField(
                    controller: _hCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _syncFromText(),
                    decoration: _fieldDeco(theme, label: 'lbl_height'.tr),
                  ),
                ),
                SizedBox(width: 10.h),
                SizedBox(
                  width: 92.h,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _unit,
                    decoration: _fieldDeco(theme, label: 'lbl_unit'.tr),
                    items: [
                      DropdownMenuItem(
                        value: 'px',
                        child: Text(
                          'lbl_pixels'.tr,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _unit = v);
                    },
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 16.v),
          _sliderRow(
            context,
            label: 'lbl_width'.tr,
            value: _w,
            max: maxW,
            onChanged: (v) {
              setState(() => _w = v);
              _syncTextFromSliders();
            },
          ),
          SizedBox(height: 8.v),
          _sliderRow(
            context,
            label: 'lbl_height'.tr,
            value: _h,
            max: maxH,
            onChanged: (v) {
              setState(() => _h = v);
              _syncTextFromSliders();
            },
          ),
          SizedBox(height: 14.v),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(_wCtrl.text.trim());
              final h = double.tryParse(_hCtrl.text.trim());
              if (w == null || h == null || w <= 0 || h <= 0) {
                showAppToast(
                  'msg_invalid_custom_size'.tr,
                  type: ToastificationType.warning,
                );
                return;
              }
              widget.onCreate(
                width: w.clamp(_minDim, maxW),
                height: h.clamp(_minDim, maxH),
                unit: _unit,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.adaptSize),
              ),
              padding: EdgeInsets.symmetric(vertical: 14.v),
            ),
            child: Text(
              'lbl_create_custom_size'.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    BuildContext context, {
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value.toInt().toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 3),
          child: Slider(
            min: _minDim,
            max: max,
            divisions: 200,
            value: value.clamp(_minDim, max),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
