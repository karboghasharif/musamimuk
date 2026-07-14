import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_form_field.dart';

/// Yellow-themed resize canvas popup (editor overlay) with unit-aware dimensions.
class CanvasResizeSizePanel extends StatefulWidget {
  const CanvasResizeSizePanel({
    super.key,
    required this.editorWidthPx,
    required this.editorHeightPx,
    required this.maxWidthPx,
    required this.maxHeightPx,
    required this.initialUnit,
    required this.onApply,
    required this.onHeightSliderEnd,
    required this.onWidthSliderEnd,
    this.minWidthPx = 50,
  });

  final double editorWidthPx;
  final double editorHeightPx;
  final double maxWidthPx;
  final double maxHeightPx;
  final String initialUnit;
  final double minWidthPx;
  final void Function(double widthPx, double heightPx, String unit) onApply;
  final void Function(double widthPx, double heightPx) onHeightSliderEnd;
  final void Function(double widthPx, double heightPx) onWidthSliderEnd;

  @override
  State<CanvasResizeSizePanel> createState() => _CanvasResizeSizePanelState();
}

class _CanvasResizeSizePanelState extends State<CanvasResizeSizePanel> {
  static const double _minHeightPx = 50;

  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;
  late CanvasUnitDimensions _dims;

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
    if (oldWidget.editorWidthPx != widget.editorWidthPx ||
        oldWidget.editorHeightPx != widget.editorHeightPx) {
      _dims.setPixelSize(widget.editorWidthPx, widget.editorHeightPx);
      _clampPixels();
      _syncTextFromDimensions();
    }
    if (oldWidget.initialUnit != widget.initialUnit &&
        _dims.unit != widget.initialUnit) {
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

  double get _minPx => widget.minWidthPx < _minHeightPx
      ? widget.minWidthPx
      : _minHeightPx;

  double _maxDisplayW() => CanvasUnitUtils.fromPixels(widget.maxWidthPx, _dims.unit);
  double _maxDisplayH() => CanvasUnitUtils.fromPixels(widget.maxHeightPx, _dims.unit);
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
    });
  }

  void _onUnitChanged(String? newUnit) {
    if (newUnit == null || newUnit == _dims.unit) return;
    setState(() {
      _dims.changeUnit(newUnit);
      _clampPixels();
      _syncTextFromDimensions();
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
    final parsed = _parseAndClampFromFields();
    if (parsed == null) return;
    setState(() {
      _dims.setPixelSize(parsed.widthPx, parsed.heightPx);
    });
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

  Widget _unitDropdown() {
    return SizedBox(
      width: 122.h,
      child: DropdownButtonFormField<String>(
        key: ValueKey(_dims.unit),
        isExpanded: true,
        initialValue: _dims.unit,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: appTheme.yellow500,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.v),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.h),
            borderSide: BorderSide.none,
          ),
        ),
        icon: CustomImageView(
          imagePath: ImageConstant.imgArrowdownGray9001,
          height: 16.adaptSize,
          width: 16.adaptSize,
        ),
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
        onChanged: _onUnitChanged,
      ),
    );
  }

  Widget _sliderBox({
    required String label,
    required double displayValue,
    required double maxDisplay,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    final min = _minDisplay();
    final clamped = displayValue.clamp(min, maxDisplay);
    return Container(
      padding: EdgeInsets.all(15.h),
      decoration: AppDecoration.fillYellow.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder10,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: CustomTextStyles.bodySmallBluegray90004.copyWith(
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            '${CanvasUnitUtils.formatValue(clamped, _dims.unit)} ${_dims.unit}',
            style: CustomTextStyles.bodySmallBluegray90004.copyWith(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgArrowDownGray900,
                height: 18.adaptSize,
                width: 18.adaptSize,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12.h,
                    top: 3.v,
                    bottom: 3.v,
                  ),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackShape: const RoundedRectSliderTrackShape(),
                      overlayShape: const RoundSliderOverlayShape(),
                      activeTrackColor: appTheme.blueGray90004,
                      inactiveTrackColor:
                          appTheme.black900.withValues(alpha: 0.08),
                      thumbColor: appTheme.blueGray90004,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: clamped,
                      min: min,
                      max: maxDisplay,
                      onChanged: onChanged,
                      onChangeEnd: onChangeEnd,
                    ),
                  ),
                ),
              ),
              CustomImageView(
                imagePath: ImageConstant.imgArrowLeft,
                height: 17.adaptSize,
                width: 17.adaptSize,
                margin: EdgeInsets.only(left: 11.h),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxDisplayW = _maxDisplayW();
    final maxDisplayH = _maxDisplayH();

    return Container(
      margin: EdgeInsets.only(bottom: 45.v),
      padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 20.v),
      decoration: AppDecoration.fillPrimary.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder33,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'lbl_select_size2'.tr,
            style: CustomTextStyles.titleMediumPoppinsBluegray90004,
          ),
          SizedBox(height: 12.v),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Text(
                'lbl_custom_size'.tr,
                style: CustomTextStyles.bodySmallBluegray90004,
              ),
            ),
          ),
          SizedBox(height: 10.v),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _wCtrl,
                  hintText: 'lbl_width'.tr,
                  textStyle: CustomTextStyles.bodySmallBluegray90004,
                  textInputAction: TextInputAction.next,
                  textInputType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _inputFormatters(),
                  onChanged: (_) => _syncFromText(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 14.v,
                  ),
                  borderDecoration: TextFormFieldStyleHelper.fillYellow,
                  fillColor: appTheme.yellow500,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 17.v,
                  left: 6.h,
                  right: 6.h,
                  bottom: 14.v,
                ),
                child: Text(
                  'lbl_x'.tr,
                  style: CustomTextStyles.bodySmallBluegray90004,
                ),
              ),
              Expanded(
                child: CustomTextFormField(
                  controller: _hCtrl,
                  hintText: 'lbl_height'.tr,
                  textStyle: CustomTextStyles.bodySmallBluegray90004,
                  textInputAction: TextInputAction.done,
                  textInputType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _inputFormatters(),
                  onChanged: (_) => _syncFromText(),
                  onFieldSubmitted: (_) => _apply(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 14.v,
                  ),
                  borderDecoration: TextFormFieldStyleHelper.fillYellow,
                  fillColor: appTheme.yellow500,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.v),
          Row(
            children: [
              Expanded(child: _unitDropdown()),
              SizedBox(width: 8.h),
              CustomElevatedButton(
                height: 49.v,
                width: 80.h,
                text: 'lbl_apply'.tr,
                buttonStyle: CustomButtonStyles.fillYellow,
                buttonTextStyle: CustomTextStyles.bodySmallBluegray90004,
                onPressed: _apply,
              ),
            ],
          ),
          SizedBox(height: 8.v),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4.h),
              child: Text(
                _pixelPreview(),
                style: CustomTextStyles.bodySmallBluegray90004.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4.v),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _maxLabel(),
                style: CustomTextStyles.bodySmallBluegray90004.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          ),
          SizedBox(height: 14.v),
          _sliderBox(
            label: 'lbl_height'.tr,
            displayValue: _dims.heightDisplay,
            maxDisplay: maxDisplayH,
            onChanged: (value) {
              setState(() {
                _dims.setDisplaySize(_dims.widthDisplay, value);
                _clampPixels();
                _syncTextFromDimensions();
              });
            },
            onChangeEnd: (value) {
              setState(() {
                _dims.setDisplaySize(_dims.widthDisplay, value);
                _clampPixels();
                _syncTextFromDimensions();
              });
              widget.onHeightSliderEnd(_dims.widthPx, _dims.heightPx);
            },
          ),
          SizedBox(height: 10.v),
          _sliderBox(
            label: 'lbl_width'.tr,
            displayValue: _dims.widthDisplay,
            maxDisplay: maxDisplayW,
            onChanged: (value) {
              setState(() {
                _dims.setDisplaySize(value, _dims.heightDisplay);
                _clampPixels();
                _syncTextFromDimensions();
              });
            },
            onChangeEnd: (value) {
              setState(() {
                _dims.setDisplaySize(value, _dims.heightDisplay);
                _clampPixels();
                _syncTextFromDimensions();
              });
              widget.onWidthSliderEnd(_dims.widthPx, _dims.heightPx);
            },
          ),
          SizedBox(height: 68.v),
        ],
      ),
    );
  }
}
