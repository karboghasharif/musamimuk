import 'package:flutter/material.dart';

/// App-wide design tokens (8pt-based spacing, radii, type, elevation).
///
/// For responsive layouts, apply [SizeUtils] extensions `.h` / `.v` / `adaptSize`
/// at the widget call site where the codebase already does so.
abstract final class AppDs {
  // —— Spacing (4 / 8 / 12 / 16 / 24 / 32 / 48) ——
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;

  // —— Typography scale (before .fSize scaling) ——
  static const double fontDisplay = 32;
  static const double fontHeading = 24;
  static const double fontPageTitle = 28;
  static const double fontSectionTitle = 20;
  static const double fontTitle = 18;
  static const double fontCardTitle = 17;
  static const double fontBody = 16;
  static const double fontSecondary = 14;
  static const double fontCaption = 13;

  // —— Border radius ——
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusSheet = 20;
  static const double radiusFull = 999;

  // —— Buttons ——
  static const double buttonHeight = 52;
  static const double buttonHeightLg = 56;
  static const double iconSm = 20;
  static const double iconMd = 24;

  /// Minimum touch target (WCAG / Material).
  static const double minTap = 48;

  /// Minimum readable body / label sizes (before responsive scaling).
  static const double bodyMin = 14;
  static const double labelMin = 12;

  // —— Brand palette ——
  // Background #252A30 · Container/field #2F353D · Primary text #FFFFFF
  // Secondary text #9FA7B8 · Accent/button/icon #F4DF08 · On-accent text #000000

  // —— Text on dark surfaces (accessibility-first) ——
  static const Color textOnDarkPrimary = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFF9FA7B8);
  static const Color textOnDarkDisabled = Color(0x73FFFFFF);

  // —— Dark surface hierarchy ——
  static const Color surfaceBase = Color(0xFF252A30);
  static const Color surfaceRaised = Color(0xFF2F353D);
  static const Color surfaceElevated = Color(0xFF2F353D);
  static const Color accentYellow = Color(0xFFF4DF08);
  static const Color onAccent = Color(0xFF000000);

  // —— Motion ——
  static const Duration motionFast = Duration(milliseconds: 200);
  static const Duration motionNormal = Duration(milliseconds: 280);
  static const Duration tapFade = Duration(milliseconds: 120);
  static const Duration sheetTransition = Duration(milliseconds: 280);

  static const double textSecondaryOpacity = 0.75;
  static const double textDisabledOpacity = 0.45;

  static Color textPrimary(ColorScheme cs) => textOnDarkPrimary;

  static Color textSecondary(ColorScheme cs) => textOnDarkSecondary;

  static Color textDisabled(ColorScheme cs) => textOnDarkDisabled;

  /// Brand yellow — metrics, highlights, active accents on dark UI.
  static Color textAccent(ColorScheme cs) => cs.primary;

  static TextStyle screenTitle(ThemeData t, {Color? color}) {
    final base = t.textTheme.headlineSmall ?? t.textTheme.titleLarge!;
    return base.copyWith(
      fontWeight: FontWeight.w700,
      color: color ?? textPrimary(t.colorScheme),
      fontSize: fontPageTitle.clamp(24.0, 32.0),
      height: 1.2,
    );
  }

  static TextStyle sheetTitle(ThemeData t, {required Color color}) {
    final base = t.textTheme.titleLarge ?? t.textTheme.titleMedium!;
    return base.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontSize: fontSectionTitle.clamp(18.0, 24.0),
      height: 1.25,
    );
  }

  static TextStyle sheetBody(ThemeData t, {required Color color, double a = 1}) {
    return (t.textTheme.bodyLarge ?? t.textTheme.bodyMedium!).copyWith(
      color: color.withValues(alpha: a),
      fontSize: fontBody.clamp(bodyMin, 18.0),
      height: 1.4,
    );
  }

  static TextStyle sheetCaption(ThemeData t, {required Color color}) {
    return (t.textTheme.bodySmall ?? t.textTheme.labelLarge!).copyWith(
      color: color,
      fontSize: fontSecondary.clamp(labelMin, 15.0),
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
  }

  static List<BoxShadow> shadowSoft({double opacity = 0.12}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowCard() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> shadowSheetHandle() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ];

  /// Premium dark surface for modal bottom sheets.
  static const Color sheetBackground = Color(0xFF2F353D);

  static Color sheetBorderSubtle([double a = 0.14]) =>
      Colors.white.withValues(alpha: a);

  static Color sheetListFill([double a = 0.08]) =>
      Colors.white.withValues(alpha: a);

  static Color editorToolbarBg(ColorScheme cs) => cs.onPrimary;

  static Color editorToolbarBorder(ColorScheme cs) =>
      cs.onSecondary.withValues(alpha: 0.2);

  static Color editorToolChipFill(ColorScheme cs) =>
      cs.onPrimary.withValues(alpha: 0.14);

  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: color ?? (elevated ? surfaceElevated : surfaceRaised),
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLg),
      border: elevated
          ? null
          : Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: elevated ? shadowSoft(opacity: 0.22) : null,
    );
  }

  static EdgeInsets screenPaddingH = const EdgeInsets.symmetric(
    horizontal: space4,
  );

  static EdgeInsets cardPadding = const EdgeInsets.all(space4);
}
