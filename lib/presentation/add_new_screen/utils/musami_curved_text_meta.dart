import 'package:flutter/material.dart';

/// Layer kind for curved / arc text [WidgetLayer]s.
const String kMusamiCurvedTextLayerKind = 'curved_text';

/// Export / widgetLoader id prefix.
const String kMusamiCurvedTextIdPrefix = 'musami-curved-text:';

const String kMusamiCurvedTextFlagMetaKey = 'musamiCurvedText';
const String kMusamiCurvedSourceStringMetaKey = 'sourceString';
const String kMusamiCurvedArcAmountMetaKey = 'arcAmount';
const String kMusamiCurvedClockwiseMetaKey = 'clockwise';
const String kMusamiCurvedRtlMetaKey = 'rtl';
const String kMusamiCurvedTextAlignMetaKey = 'textAlign';
const String kMusamiCurvedFontFamilyMetaKey = 'fontFamily';
const String kMusamiCurvedFontSizeMetaKey = 'fontSize';
const String kMusamiCurvedFontWeightMetaKey = 'fontWeight';
const String kMusamiCurvedFontStyleMetaKey = 'fontStyle';
const String kMusamiCurvedColorMetaKey = 'color';
const String kMusamiCurvedLetterSpacingMetaKey = 'letterSpacing';

/// Arc strength in **[-1.0, 1.0]**.
///
/// - Magnitude maps to angular sweep (≈0.12π … ≈1.75π).
/// - Sign: **positive** = arch (text on the upper half of the circle);
///   **negative** = smile (text on the lower half).
/// - `0` keeps a gentle readable arc (not a perfectly straight line).
const double kMusamiCurvedArcAmountMin = -1.0;
const double kMusamiCurvedArcAmountMax = 1.0;
const double kMusamiCurvedArcAmountDefault = 0.45;

bool musamiIsCurvedTextLayerKind(String? kind) =>
    kind == kMusamiCurvedTextLayerKind;

bool musamiMetaIsCurvedText(Map<String, dynamic>? meta) {
  if (meta == null) return false;
  if (meta[kMusamiCurvedTextFlagMetaKey] == true) return true;
  return musamiIsCurvedTextLayerKind(meta['musamiLayerKind']?.toString());
}

/// True when [text] contains Arabic / Arabic-presentation code points.
bool musamiTextLooksArabic(String text) {
  for (final c in text.runes) {
    if (c >= 0x0600 && c <= 0x06FF) return true;
    if (c >= 0x0750 && c <= 0x077F) return true;
    if (c >= 0x08A0 && c <= 0x08FF) return true;
    if (c >= 0xFB50 && c <= 0xFDFF) return true;
    if (c >= 0xFE70 && c <= 0xFEFF) return true;
  }
  return false;
}

double musamiClampCurvedArcAmount(num? raw) {
  final v = (raw ?? kMusamiCurvedArcAmountDefault).toDouble();
  if (!v.isFinite) return kMusamiCurvedArcAmountDefault;
  return v.clamp(kMusamiCurvedArcAmountMin, kMusamiCurvedArcAmountMax);
}

/// Editable curved-text parameters (also JSON-friendly via [toMeta]/[fromMeta]).
@immutable
class MusamiCurvedTextParams {
  const MusamiCurvedTextParams({
    required this.sourceString,
    this.arcAmount = kMusamiCurvedArcAmountDefault,
    this.clockwise = false,
    this.rtl = false,
    this.textAlign = TextAlign.center,
    this.fontFamily,
    this.fontSize = 48,
    this.fontWeight = FontWeight.w600,
    this.fontStyle = FontStyle.normal,
    this.color = const Color(0xFF111111),
    this.letterSpacing = 0,
  });

  final String sourceString;
  final double arcAmount;
  final bool clockwise;
  final bool rtl;
  final TextAlign textAlign;
  final String? fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final Color color;
  final double letterSpacing;

  TextStyle get textStyle => TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.0,
      );

  TextDirection get textDirection =>
      rtl ? TextDirection.rtl : TextDirection.ltr;

  MusamiCurvedTextParams copyWith({
    String? sourceString,
    double? arcAmount,
    bool? clockwise,
    bool? rtl,
    TextAlign? textAlign,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
  }) {
    return MusamiCurvedTextParams(
      sourceString: sourceString ?? this.sourceString,
      arcAmount: arcAmount ?? this.arcAmount,
      clockwise: clockwise ?? this.clockwise,
      rtl: rtl ?? this.rtl,
      textAlign: textAlign ?? this.textAlign,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      color: color ?? this.color,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  Map<String, dynamic> toMeta() {
    return <String, dynamic>{
      'musamiLayerKind': kMusamiCurvedTextLayerKind,
      kMusamiCurvedTextFlagMetaKey: true,
      kMusamiCurvedSourceStringMetaKey: sourceString,
      kMusamiCurvedArcAmountMetaKey: musamiClampCurvedArcAmount(arcAmount),
      kMusamiCurvedClockwiseMetaKey: clockwise,
      kMusamiCurvedRtlMetaKey: rtl,
      kMusamiCurvedTextAlignMetaKey: _alignToName(textAlign),
      if (fontFamily != null && fontFamily!.isNotEmpty)
        kMusamiCurvedFontFamilyMetaKey: fontFamily,
      kMusamiCurvedFontSizeMetaKey: fontSize,
      kMusamiCurvedFontWeightMetaKey: fontWeight.value,
      kMusamiCurvedFontStyleMetaKey:
          fontStyle == FontStyle.italic ? 'italic' : 'normal',
      kMusamiCurvedColorMetaKey: color.toARGB32(),
      kMusamiCurvedLetterSpacingMetaKey: letterSpacing,
    };
  }

  static MusamiCurvedTextParams fromMeta(Map<String, dynamic>? meta) {
    final m = meta ?? const <String, dynamic>{};
    final rawAlign = m[kMusamiCurvedTextAlignMetaKey]?.toString();
    final weightRaw = (m[kMusamiCurvedFontWeightMetaKey] as num?)?.toInt();
    final styleRaw = m[kMusamiCurvedFontStyleMetaKey]?.toString();
    final colorRaw = m[kMusamiCurvedColorMetaKey];
    Color color = const Color(0xFF111111);
    if (colorRaw is int) {
      color = Color(colorRaw);
    } else if (colorRaw is num) {
      color = Color(colorRaw.toInt());
    }
    return MusamiCurvedTextParams(
      sourceString: m[kMusamiCurvedSourceStringMetaKey]?.toString() ?? '',
      arcAmount: musamiClampCurvedArcAmount(m[kMusamiCurvedArcAmountMetaKey]),
      clockwise: m[kMusamiCurvedClockwiseMetaKey] == true,
      rtl: m[kMusamiCurvedRtlMetaKey] == true,
      textAlign: _alignFromName(rawAlign),
      fontFamily: m[kMusamiCurvedFontFamilyMetaKey]?.toString(),
      fontSize: (m[kMusamiCurvedFontSizeMetaKey] as num?)?.toDouble() ?? 48,
      fontWeight: FontWeight.values.firstWhere(
        (w) => w.value == (weightRaw ?? 600),
        orElse: () => FontWeight.w600,
      ),
      fontStyle: styleRaw == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: color,
      letterSpacing:
          (m[kMusamiCurvedLetterSpacingMetaKey] as num?)?.toDouble() ?? 0,
    );
  }

  /// Builds params from a live [TextLayer]-like style snapshot.
  static MusamiCurvedTextParams fromPlainText({
    required String text,
    TextStyle? style,
    TextAlign align = TextAlign.center,
    Color? fallbackColor,
    bool? forceRtl,
  }) {
    final trimmed = text;
    final rtl = forceRtl ?? musamiTextLooksArabic(trimmed);
    final s = style ?? const TextStyle();
    return MusamiCurvedTextParams(
      sourceString: trimmed,
      arcAmount: kMusamiCurvedArcAmountDefault,
      clockwise: false,
      rtl: rtl,
      textAlign: align,
      fontFamily: s.fontFamily,
      fontSize: (s.fontSize ?? 48).toDouble(),
      fontWeight: s.fontWeight ?? FontWeight.w600,
      fontStyle: s.fontStyle ?? FontStyle.normal,
      color: s.color ?? fallbackColor ?? const Color(0xFF111111),
      letterSpacing: s.letterSpacing ?? 0,
    );
  }

  static String _alignToName(TextAlign a) => switch (a) {
        TextAlign.left || TextAlign.start => 'left',
        TextAlign.right || TextAlign.end => 'right',
        TextAlign.justify => 'justify',
        _ => 'center',
      };

  static TextAlign _alignFromName(String? raw) => switch (raw) {
        'left' || 'start' => TextAlign.left,
        'right' || 'end' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.center,
      };
}
