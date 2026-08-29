import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';

/// Yellow resize canvas panel (editor overlay), matching other tool tabs.
///
/// Sliders and fields only update the draft values shown in the panel.
/// The editor canvas size changes only when the user taps Apply.
class CanvasResizeSizePanel extends StatefulWidget {
  const CanvasResizeSizePanel({
    super.key,
    required this.editorWidthPx,
    required this.editorHeightPx,
    required this.maxWidthPx,
    required this.maxHeightPx,
    required this.initialUnit,
    required this.onApply,
    this.isApplying = false,
    this.minWidthPx = 50,
  });

  final double editorWidthPx;
  final double editorHeightPx;
  final double maxWidthPx;
  final double maxHeightPx;
  final String initialUnit;
  final double minWidthPx;
  final bool isApplying;
  final void Function(double widthPx, double heightPx, String unit) onApply;

  @override
  State<CanvasResizeSizePanel> createState() => _CanvasResizeSizePanelState();
}

class _CanvasResizeSizePanelState extends State<CanvasResizeSizePanel> {
  static const double _minHeightPx = 50;
  static const Color _ink = Color(0xFF1A1D21);
  static const Color _inkMuted = Color(0xFF4A5560);

  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;
  late CanvasUnitDimensions _dims;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _dims = CanvasUnitDimensions(
      widthPx: widget.editorWidthPx,
      heightPx: widget.editorHeightPx,
      unit: widget.initialUnit,
    );
    _clampPixels();
    _wCtrl = TextEditingController(text: _dims.formatWidth());
    _hCtrl = TextEditingController(text: _dims.formatHeight());
  }

  @override
  void didUpdateWidget(covariant CanvasResizeSizePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync from the live editor only after Apply finishes (or external resize).
    // While the user is drafting, ignore parent size so sliders stay local.
    if (!_dirty &&
        (oldWidget.editorWidthPx != widget.editorWidthPx ||
            oldWidget.editorHeightPx != widget.editorHeightPx)) {
      _dims.setPixelSize(widget.editorWidthPx, widget.editorHeightPx);
      _clampPixels();
      _syncTextFromDimensions();
    }
    if (oldWidget.isApplying && !widget.isApplying) {
      _dims.setPixelSize(widget.editorWidthPx, widget.editorHeightPx);
      _clampPixels();
      _syncTextFromDimensions();
      _dirty = false;
    }
    if (oldWidget.initialUnit != widget.initialUnit &&
        _dims.unit != widget.initialUnit &&
        !_dirty) {
      _dims.changeUnit(widget.initialUnit);
      _syncTextFromDimensions();
    }
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  double get _minPx =>
      widget.minWidthPx < _minHeightPx ? widget.minWidthPx : _minHeightPx;

  double _maxDisplayW() =>
      CanvasUnitUtils.fromPixels(widget.maxWidthPx, _dims.unit);
  double _maxDisplayH() =>
      CanvasUnitUtils.fromPixels(widget.maxHeightPx, _dims.unit);
  double _minDisplay() => CanvasUnitUtils.minValue(_dims.unit);

  void _clampPixels() {
    _dims.clampPixels(
      minPx: _minPx,
      maxPxW: widget.maxWidthPx,
      maxPxH: widget.maxHeightPx,
    );
  }

  void _syncTextFromDimensions() {
    _wCtrl.text = _dims.formatWidth();
    _hCtrl.text = _dims.formatHeight();
  }

  List<TextInputFormatter> _inputFormatters() {
    if (_dims.unit == 'px') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    ];
  }

  void _syncFromText() {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    if (w == null || h == null) return;
    setState(() {
      _dims.setDisplaySize(w, h);
      _clampPixels();
      _syncTextFromDimensions();
      _dirty = true;
    });
  }

  void _onUnitChanged(String? newUnit) {
    if (newUnit == null || newUnit == _dims.unit) return;
    setState(() {
      _dims.changeUnit(newUnit);
      _clampPixels();
      _syncTextFromDimensions();
      _dirty = true;
    });
  }

  ({double widthPx, double heightPx})? _parseAndClampFromFields() {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    final min = _minDisplay();
    if (w == null || h == null || w < min || h < min) {
      showAppToast(
        'msg_invalid_custom_size'.tr,
        type: ToastificationType.warning,
      );
      return null;
    }
    _dims.setDisplaySize(w, h);
    final rawWPx = _dims.widthPx.round();
    final rawHPx = _dims.heightPx.round();
    _dims.clampPixels(
      minPx: _minPx,
      maxPxW: widget.maxWidthPx,
      maxPxH: widget.maxHeightPx,
    );
    final wPx = _dims.widthPx.round().toDouble();
    final hPx = _dims.heightPx.round().toDouble();
    if (rawWPx > widget.maxWidthPx.round() ||
        rawHPx > widget.maxHeightPx.round()) {
      showAppToast(
        'msg_canvas_size_clamped'.tr,
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
    _syncTextFromDimensions();
    return (widthPx: wPx, heightPx: hPx);
  }

  void _apply() {
    if (widget.isApplying) return;
    FocusScope.of(context).unfocus();
    final parsed = _parseAndClampFromFields();
    if (parsed == null) return;
    widget.onApply(parsed.widthPx, parsed.heightPx, _dims.unit);
  }

  String _pixelPreview() {
    return 'msg_canvas_size_pixels'.tr
        .replaceAll('@width', '${_dims.widthPx.round()}')
        .replaceAll('@height', '${_dims.heightPx.round()}');
  }

  String _maxLabel() {
    return 'msg_canvas_max_pixels'.tr
        .replaceAll('@width', '${widget.maxWidthPx.round()}')
        .replaceAll('@height', '${widget.maxHeightPx.round()}');
  }

  InputDecoration _fieldDeco({required String label}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      labelStyle: const TextStyle(
        color: _inkMuted,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: _ink,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        borderSide: BorderSide(color: appTheme.blueGray90004, width: 1.6),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 12.v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDisplayW = _maxDisplayW();
    final maxDisplayH = _maxDisplayH();
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final maxPanelHeight = MediaQuery.sizeOf(context).height *
        (keyboardOpen ? 0.42 : 0.55);
    final applying = widget.isApplying;
    final canApply = _dirty && !applying;

    return Container(
      margin: EdgeInsets.only(bottom: 46.v, left: 12.h, right: 12.h),
      padding: EdgeInsets.fromLTRB(
        AppDs.space5.h,
        AppDs.space4.v,
        AppDs.space5.h,
        AppDs.space5.v,
      ),
      decoration: AppDecoration.fillYellow.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder33,
      ),
      constraints: BoxConstraints(maxHeight: maxPanelHeight),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'lbl_select_size2'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _maxLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDs.space3.v),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wCtrl,
                    enabled: !applying,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _inputFormatters(),
                    onChanged: (_) => _syncFromText(),
                    decoration: _fieldDeco(label: 'lbl_width'.tr),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.h),
                  child: Text(
                    '×',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _hCtrl,
                    enabled: !applying,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _inputFormatters(),
                    onChanged: (_) => _syncFromText(),
                    onSubmitted: (_) => _apply(),
                    decoration: _fieldDeco(label: 'lbl_height'.tr),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDs.space3.v),
            Row(
              children: [
                Expanded(child: _unitDropdown(theme, enabled: !applying)),
                SizedBox(width: AppDs.space2.h),
                SizedBox(
                  height: 48.v,
                  child: FilledButton(
                    onPressed: canApply ? _apply : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: canApply
                          ? appTheme.blueGray90004
                          : appTheme.blueGray90004.withValues(alpha: 0.72),
                      disabledBackgroundColor:
                          appTheme.blueGray90004.withValues(alpha: 0.72),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDs.radiusMd.adaptSize,
                        ),
                      ),
                    ),
                    child: applying
                        ? SizedBox(
                            width: 20.adaptSize,
                            height: 20.adaptSize,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'lbl_apply'.tr,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDs.space2.v),
            Text(
              _pixelPreview(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppDs.space3.v),
            _sliderRow(
              theme: theme,
              label: 'lbl_width'.tr,
              displayValue: _dims.widthDisplay,
              maxDisplay: maxDisplayW,
              enabled: !applying,
              onChanged: (value) {
                setState(() {
                  _dims.setDisplaySize(value, _dims.heightDisplay);
                  _clampPixels();
                  _syncTextFromDimensions();
                  _dirty = true;
                });
              },
            ),
            SizedBox(height: AppDs.space1.v),
            _sliderRow(
              theme: theme,
              label: 'lbl_height'.tr,
              displayValue: _dims.heightDisplay,
              maxDisplay: maxDisplayH,
              enabled: !applying,
              onChanged: (value) {
                setState(() {
                  _dims.setDisplaySize(_dims.widthDisplay, value);
                  _clampPixels();
                  _syncTextFromDimensions();
                  _dirty = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitDropdown(ThemeData theme, {required bool enabled}) {
    return DropdownButtonFormField<String>(
      key: ValueKey(_dims.unit),
      isExpanded: true,
      initialValue: _dims.unit,
      dropdownColor: Colors.white,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: _ink,
        fontWeight: FontWeight.w600,
      ),
      decoration: _fieldDeco(label: 'lbl_unit'.tr),
      items: CanvasUnitUtils.units
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
          .toList(),
      onChanged: enabled ? _onUnitChanged : null,
    );
  }

  Widget _sliderRow({
    required ThemeData theme,
    required String label,
    required double displayValue,
    required double maxDisplay,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    final min = _minDisplay();
    final safeMax = maxDisplay <= min ? min + 1 : maxDisplay;
    final clamped = displayValue.clamp(min, safeMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${CanvasUnitUtils.formatValue(clamped, _dims.unit)} ${_dims.unit}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: appTheme.blueGray90004,
            inactiveTrackColor: Colors.black.withValues(alpha: 0.12),
            thumbColor: appTheme.blueGray90004,
            overlayColor: appTheme.blueGray90004.withValues(alpha: 0.16),
            disabledActiveTrackColor:
                appTheme.blueGray90004.withValues(alpha: 0.4),
            disabledInactiveTrackColor: Colors.black.withValues(alpha: 0.08),
            disabledThumbColor: appTheme.blueGray90004.withValues(alpha: 0.5),
          ),
          child: Slider(
            value: clamped,
            min: min,
            max: safeMax,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
