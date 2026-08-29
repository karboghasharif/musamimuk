import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';

/// Practical slider ceiling so common sizes (e.g. 500–1080) sit mid-track.
/// Absolute device max still applied on create.
const double _kPracticalSliderMaxPx = 4000;

class CustomSizeSelector extends StatefulWidget {
  const CustomSizeSelector({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    required this.onCreate,
    this.initiallyExpanded = false,
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

  /// When false, starts collapsed so presets stay visible above the fold.
  final bool initiallyExpanded;

  @override
  State<CustomSizeSelector> createState() => _CustomSizeSelectorState();
}

class _CustomSizeSelectorState extends State<CustomSizeSelector> {
  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;

  late double _w;
  late double _h;
  String _unit = 'px';
  late bool _expanded;
  bool _lockAspect = false;
  double _aspect = 1;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _w = CanvasUnitUtils.fromPixels(widget.initialWidth, _unit);
    _h = CanvasUnitUtils.fromPixels(widget.initialHeight, _unit);
    _aspect = _w <= 0 || _h <= 0 ? 1 : _w / _h;
    _wCtrl = TextEditingController(
      text: CanvasUnitUtils.formatValue(_w, _unit),
    );
    _hCtrl = TextEditingController(
      text: CanvasUnitUtils.formatValue(_h, _unit),
    );
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  double _maxPxW(BuildContext context) => MediaQuery.sizeOf(context).width * 8;
  double _maxPxH(BuildContext context) => MediaQuery.sizeOf(context).height * 8;

  double _sliderMaxW(BuildContext context) {
    final device = CanvasUnitUtils.fromPixels(_maxPxW(context), _unit);
    final practical = CanvasUnitUtils.fromPixels(_kPracticalSliderMaxPx, _unit);
    return device < practical ? device : practical;
  }

  double _sliderMaxH(BuildContext context) {
    final device = CanvasUnitUtils.fromPixels(_maxPxH(context), _unit);
    final practical = CanvasUnitUtils.fromPixels(_kPracticalSliderMaxPx, _unit);
    return device < practical ? device : practical;
  }

  double _minDim() => CanvasUnitUtils.minValue(_unit);

  List<TextInputFormatter> _inputFormatters() {
    if (_unit == 'px') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];
  }

  void _clampLocalDimensions(BuildContext context) {
    final min = _minDim();
    final maxW = CanvasUnitUtils.fromPixels(_maxPxW(context), _unit);
    final maxH = CanvasUnitUtils.fromPixels(_maxPxH(context), _unit);
    _w = _w.clamp(min, maxW);
    _h = _h.clamp(min, maxH);
  }

  void _syncFromText(BuildContext context, {required bool fromWidth}) {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    if (w == null && h == null) return;
    setState(() {
      if (_lockAspect && _aspect > 0) {
        if (fromWidth && w != null) {
          _w = w;
          _h = w / _aspect;
        } else if (!fromWidth && h != null) {
          _h = h;
          _w = h * _aspect;
        }
      } else {
        if (w != null) _w = w;
        if (h != null) _h = h;
        if (_w > 0 && _h > 0) _aspect = _w / _h;
      }
      _clampLocalDimensions(context);
      _syncTextFromSliders();
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
      if (_w > 0 && _h > 0) _aspect = _w / _h;
      _syncTextFromSliders();
    });
  }

  void _setWidth(BuildContext context, double v) {
    setState(() {
      _w = v;
      if (_lockAspect && _aspect > 0) {
        _h = v / _aspect;
      } else if (_w > 0 && _h > 0) {
        _aspect = _w / _h;
      }
      _clampLocalDimensions(context);
      _syncTextFromSliders();
    });
  }

  void _setHeight(BuildContext context, double v) {
    setState(() {
      _h = v;
      if (_lockAspect && _aspect > 0) {
        _w = v * _aspect;
      } else if (_w > 0 && _h > 0) {
        _aspect = _w / _h;
      }
      _clampLocalDimensions(context);
      _syncTextFromSliders();
    });
  }

  String _pixelPreview(BuildContext context) {
    final wPx = CanvasUnitUtils.toPixels(_w, _unit).round();
    final hPx = CanvasUnitUtils.toPixels(_h, _unit).round();
    return 'msg_canvas_size_pixels'.tr
        .replaceAll('@width', '$wPx')
        .replaceAll('@height', '$hPx');
  }

  InputDecoration _fieldDeco(ThemeData theme, {required String label}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: AppDs.textOnDarkSecondary,
      ),
      floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: AppDs.accentYellow,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        borderSide: const BorderSide(color: AppDs.accentYellow, width: 1.4),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 14.v),
    );
  }

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
    final wPx = rawWPx.clamp(1, maxWPx.round());
    final hPx = rawHPx.clamp(1, maxHPx.round());

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

    return AnimatedContainer(
      duration: AppDs.motionNormal,
      curve: Curves.easeOutCubic,
      decoration: AppDs.cardDecoration(elevated: true),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space3.v,
                AppDs.space3.h,
                AppDs.space3.v,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.adaptSize,
                    height: 40.adaptSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppDs.accentYellow.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        AppDs.radiusSm.adaptSize,
                      ),
                    ),
                    child: Icon(
                      Icons.aspect_ratio_rounded,
                      color: AppDs.accentYellow,
                      size: 22.adaptSize,
                    ),
                  ),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'lbl_custom_size'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppDs.textOnDarkPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.v),
                        Text(
                          _expanded
                              ? 'msg_custom_size_hint'.tr
                              : _pixelPreview(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppDs.textOnDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppDs.textOnDarkSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                0,
                AppDs.space4.h,
                AppDs.space4.v,
              ),
              child: _expandedBody(theme, cs),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDs.motionNormal,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _expandedBody(ThemeData theme, ColorScheme cs) {
    final maxW = _sliderMaxW(context);
    final maxH = _sliderMaxH(context);
    final wPx = CanvasUnitUtils.toPixels(_w, _unit);
    final hPx = CanvasUnitUtils.toPixels(_h, _unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        SizedBox(height: AppDs.space3.v),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AspectPreview(widthPx: wPx, heightPx: hPx),
            SizedBox(width: AppDs.space3.h),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _wCtrl,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppDs.textOnDarkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: _inputFormatters(),
                          onChanged: (_) =>
                              _syncFromText(context, fromWidth: true),
                          decoration: _fieldDeco(theme, label: 'lbl_width'.tr),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.h),
                        child: Text(
                          '×',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppDs.textOnDarkSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _hCtrl,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppDs.textOnDarkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: _inputFormatters(),
                          onChanged: (_) =>
                              _syncFromText(context, fromWidth: false),
                          decoration: _fieldDeco(theme, label: 'lbl_height'.tr),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDs.space2.v),
                  Row(
                    children: [
                      Expanded(child: _unitDropdown(theme)),
                      SizedBox(width: AppDs.space2.h),
                      Tooltip(
                        message: 'lbl_lock_aspect'.tr,
                        child: FilterChip(
                          selected: _lockAspect,
                          showCheckmark: false,
                          avatar: Icon(
                            _lockAspect
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            size: 16.adaptSize,
                            color: _lockAspect
                                ? AppDs.onAccent
                                : AppDs.textOnDarkSecondary,
                          ),
                          label: Text(
                            'lbl_ratio'.tr,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _lockAspect
                                  ? AppDs.onAccent
                                  : AppDs.textOnDarkPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selectedColor: AppDs.accentYellow,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          onSelected: (v) {
                            setState(() {
                              _lockAspect = v;
                              if (_w > 0 && _h > 0) _aspect = _w / _h;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppDs.space2.v),
        Text(
          _pixelPreview(context),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppDs.textOnDarkSecondary,
          ),
        ),
        SizedBox(height: AppDs.space3.v),
        _sliderRow(
          context,
          label: 'lbl_width'.tr,
          value: _w,
          max: maxW,
          onChanged: (v) => _setWidth(context, v),
        ),
        _sliderRow(
          context,
          label: 'lbl_height'.tr,
          value: _h,
          max: maxH,
          onChanged: (v) => _setHeight(context, v),
        ),
        SizedBox(height: AppDs.space3.v),
        SizedBox(
          height: AppDs.buttonHeight.v,
          child: FilledButton(
            onPressed: () => _submit(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppDs.accentYellow,
              foregroundColor: AppDs.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
              ),
            ),
            child: Text(
              'lbl_create_custom_size'.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppDs.onAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unitDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      key: ValueKey(_unit),
      isExpanded: true,
      initialValue: _unit,
      dropdownColor: AppDs.surfaceElevated,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppDs.textOnDarkPrimary,
      ),
      decoration: _fieldDeco(theme, label: 'lbl_unit'.tr),
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
    final safeMax = max <= min ? min + 1 : max;
    final clamped = value.clamp(min, safeMax);
    final divisions = _unit == 'px'
        ? (safeMax - min).round().clamp(1, 200)
        : 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppDs.textOnDarkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${CanvasUnitUtils.formatValue(clamped, _unit)} $_unit',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppDs.textOnDarkPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppDs.accentYellow,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: AppDs.accentYellow,
            overlayColor: AppDs.accentYellow.withValues(alpha: 0.18),
          ),
          child: Slider(
            min: min,
            max: safeMax,
            divisions: divisions,
            value: clamped,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _AspectPreview extends StatelessWidget {
  const _AspectPreview({required this.widthPx, required this.heightPx});

  final double widthPx;
  final double heightPx;

  @override
  Widget build(BuildContext context) {
    final ar = (widthPx <= 0 || heightPx <= 0) ? 1.0 : widthPx / heightPx;
    const box = 56.0;
    double w;
    double h;
    if (ar >= 1) {
      w = box;
      h = box / ar;
    } else {
      h = box;
      w = box * ar;
    }
    h = h.clamp(18.0, box);
    w = w.clamp(18.0, box);

    return Container(
      width: 64.adaptSize,
      height: 64.adaptSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: AnimatedContainer(
        duration: AppDs.motionFast,
        width: w.adaptSize,
        height: h.adaptSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.adaptSize),
          border: Border.all(color: AppDs.accentYellow, width: 1.5),
        ),
      ),
    );
  }
}
