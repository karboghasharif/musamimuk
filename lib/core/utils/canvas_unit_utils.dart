/// Canvas dimension units and conversion to editor pixels (96 DPI).
class CanvasUnitUtils {
  CanvasUnitUtils._();

  static const double dpi = 96;

  static const List<String> units = ['px', 'in', 'ft', 'cm', 'mm'];

  static bool isSupported(String unit) => units.contains(unit);

  /// Converts a value in [unit] to pixels (rounded to nearest integer pixel).
  static double toPixels(double value, String unit) {
    final px = switch (unit) {
      'px' => value,
      'in' => value * dpi,
      'ft' => value * dpi * 12,
      'cm' => value * dpi / 2.54,
      'mm' => value * dpi / 25.4,
      _ => value,
    };
    return px < 1 ? 1 : px;
  }

  /// Converts pixels to a value in [unit].
  static double fromPixels(double pixels, String unit) {
    return switch (unit) {
      'px' => pixels,
      'in' => pixels / dpi,
      'ft' => pixels / (dpi * 12),
      'cm' => pixels * 2.54 / dpi,
      'mm' => pixels * 25.4 / dpi,
      _ => pixels,
    };
  }

  static double minValue(String unit) {
    return switch (unit) {
      'px' => 1,
      'in' => 0.1,
      'ft' => 0.01,
      'cm' => 0.1,
      'mm' => 1,
      _ => 1,
    };
  }

  static int decimalPlaces(String unit) {
    return switch (unit) {
      'px' => 0,
      'in' || 'ft' => 2,
      'cm' || 'mm' => 1,
      _ => 0,
    };
  }

  static String formatValue(double value, String unit) {
    final places = decimalPlaces(unit);
    if (places == 0) return value.round().toString();
    return value.toStringAsFixed(places);
  }

  static String unitLabelKey(String unit) {
    return switch (unit) {
      'px' => 'lbl_canvas_unit_px',
      'in' => 'lbl_canvas_unit_in',
      'ft' => 'lbl_canvas_unit_ft',
      'cm' => 'lbl_canvas_unit_cm',
      'mm' => 'lbl_canvas_unit_mm',
      _ => 'lbl_pixels',
    };
  }
}

/// Width/height in pixels with a user-facing display unit.
class CanvasUnitDimensions {
  CanvasUnitDimensions({
    required double widthPx,
    required double heightPx,
    String unit = 'px',
  })  : _widthPx = widthPx,
        _heightPx = heightPx,
        unit = CanvasUnitUtils.isSupported(unit) ? unit : 'px';

  String unit;
  double _widthPx;
  double _heightPx;

  double get widthPx => _widthPx;
  double get heightPx => _heightPx;
  double get widthDisplay => CanvasUnitUtils.fromPixels(_widthPx, unit);
  double get heightDisplay => CanvasUnitUtils.fromPixels(_heightPx, unit);

  void setPixelSize(double widthPx, double heightPx) {
    _widthPx = widthPx;
    _heightPx = heightPx;
  }

  void setDisplaySize(double width, double height) {
    _widthPx = CanvasUnitUtils.toPixels(width, unit);
    _heightPx = CanvasUnitUtils.toPixels(height, unit);
  }

  void changeUnit(String newUnit) {
    if (!CanvasUnitUtils.isSupported(newUnit)) return;
    unit = newUnit;
  }

  void clampPixels({
    required double minPx,
    required double maxPxW,
    required double maxPxH,
  }) {
    _widthPx = _widthPx.clamp(minPx, maxPxW);
    _heightPx = _heightPx.clamp(minPx, maxPxH);
  }

  String formatWidth() => CanvasUnitUtils.formatValue(widthDisplay, unit);
  String formatHeight() => CanvasUnitUtils.formatValue(heightDisplay, unit);
}
