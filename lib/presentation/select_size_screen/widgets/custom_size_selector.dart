import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/canvas_unit_utils.dart';

class CustomSizeSelector extends StatefulWidget {
  const CustomSizeSelector({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    required this.onCreate,
  });

  /// Initial canvas width in pixels.
  final double initialWidth;
  /// Initial canvas height in pixels.
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
  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;

  late double _w;
  late double _h;
  String _unit = 'px';

  @override
  void initState() {
    super.initState();
    _w = CanvasUnitUtils.fromPixels(widget.initialWidth, _unit);
    _h = CanvasUnitUtils.fromPixels(widget.initialHeight, _unit);
    _wCtrl = TextEditingController(text: CanvasUnitUtils.formatValue(_w, _unit));
    _hCtrl = TextEditingController(text: CanvasUnitUtils.formatValue(_h, _unit));
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  double _maxPxW(BuildContext context) => MediaQuery.sizeOf(context).width * 8;
  double _maxPxH(BuildContext context) => MediaQuery.sizeOf(context).height * 8;

  double _maxW(BuildContext context) =>
      CanvasUnitUtils.fromPixels(_maxPxW(context), _unit);

  double _maxH(BuildContext context) =>
      CanvasUnitUtils.fromPixels(_maxPxH(context), _unit);

  double _minDim() => CanvasUnitUtils.minValue(_unit);

  List<TextInputFormatter> _inputFormatters() {
    if (_unit == 'px') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    ];
  }

  void _clampLocalDimensions(BuildContext context) {
    final min = _minDim();
    final maxW = _maxW(context);
    final maxH = _maxH(context);
    _w = _w.clamp(min, maxW);
    _h = _h.clamp(min, maxH);
  }

  void _syncFromText(BuildContext context) {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    if (w == null || h == null) return;
    setState(() {
      _w = w;
      _h = h;
      _clampLocalDimensions(context);
    });
  }

  void _syncTextFromSliders() {
    _wCtrl.text = CanvasUnitUtils.formatValue(_w, _unit);
    _hCtrl.text = CanvasUnitUtils.formatValue(_h, _unit);
  }

  void _onUnitChanged(String? newUnit) {
    if (newUnit == null || newUnit == _unit) return;
    final wPx = CanvasUnitUtils.toPixels(_w, _unit);
    final hPx = CanvasUnitUtils.toPixels(_h, _unit);
    setState(() {
      _unit = newUnit;
      _w = CanvasUnitUtils.fromPixels(wPx, _unit);
      _h = CanvasUnitUtils.fromPixels(hPx, _unit);
      _clampLocalDimensions(context);
      _syncTextFromSliders();
    });
  }

  List<DropdownMenuItem<String>> _unitItems() {
    return CanvasUnitUtils.units
        .map(
          (unit) => DropdownMenuItem<String>(
            value: unit,
            child: Text(
              CanvasUnitUtils.unitLabelKey(unit).tr,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        )
        .toList();
  }

  Widget _unitDropdown(ThemeData theme, {bool expanded = false}) {
    return DropdownButtonFormField<String>(
      key: ValueKey(_unit),
      isExpanded: expanded,
      initialValue: _unit,
      decoration: _fieldDeco(theme, label: 'lbl_unit'.tr),
      items: _unitItems(),
      onChanged: _onUnitChanged,
    );
  }

  String _pixelPreview(BuildContext context) {
    final wPx = CanvasUnitUtils.toPixels(_w, _unit).round();
    final hPx = CanvasUnitUtils.toPixels(_h, _unit).round();
    return 'msg_canvas_size_pixels'.tr
        .replaceAll('@width', '$wPx')
        .replaceAll('@height', '$hPx');
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

  void _submit(BuildContext context) {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    final min = _minDim();
    if (w == null || h == null || w < min || h < min) {
      showAppToast(
        'msg_invalid_custom_size'.tr,
        type: ToastificationType.warning,
      );
      return;
    }

    final maxWPx = _maxPxW(context);
    final maxHPx = _maxPxH(context);
    final rawWPx = CanvasUnitUtils.toPixels(w, _unit).round();
    final rawHPx = CanvasUnitUtils.toPixels(h, _unit).round();
    final wPx = rawWPx.clamp(1, maxWPx);
    final hPx = rawHPx.clamp(1, maxHPx);

    if (rawWPx > maxWPx || rawHPx > maxHPx) {
      showAppToast(
        'msg_canvas_size_clamped'.tr,
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }

    widget.onCreate(width: wPx.toDouble(), height: hPx.toDouble(), unit: _unit);
  }

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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _inputFormatters(),
                    onChanged: (_) => _syncFromText(context),
                    decoration: _fieldDeco(theme, label: 'lbl_width'.tr),
                  ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: TextField(
                    controller: _hCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _inputFormatters(),
                    onChanged: (_) => _syncFromText(context),
                    decoration: _fieldDeco(theme, label: 'lbl_height'.tr),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.v),
            SizedBox(width: double.infinity, child: _unitDropdown(theme)),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _inputFormatters(),
                    onChanged: (_) => _syncFromText(context),
                    decoration: _fieldDeco(theme, label: 'lbl_width'.tr),
                  ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: TextField(
                    controller: _hCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _inputFormatters(),
                    onChanged: (_) => _syncFromText(context),
                    decoration: _fieldDeco(theme, label: 'lbl_height'.tr),
                  ),
                ),
                SizedBox(width: 10.h),
                SizedBox(
                  width: 148.h,
                  child: _unitDropdown(theme, expanded: true),
                ),
              ],
            ),
          ],
          SizedBox(height: 8.v),
          Text(
            _pixelPreview(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
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
            onPressed: () => _submit(context),
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
    final min = _minDim();
    final clamped = value.clamp(min, max);
    final divisions = _unit == 'px'
        ? (max - min).round().clamp(1, 200)
        : 200;

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
              '${CanvasUnitUtils.formatValue(clamped, _unit)} $_unit',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 3),
          child: Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: clamped,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
