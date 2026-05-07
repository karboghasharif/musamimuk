import 'package:flutter/material.dart';

/// App-wide design tokens (8pt-based spacing, radii, type, elevation).
///
/// For responsive layouts, apply [SizeUtils] extensions `.h` / `.v` / `adaptSize`
/// at the widget call site where the codebase already does so.
abstract final class AppDs {
  // —— 8pt-based spacing ——
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  // —— Border radius ——
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusSheet = 20;
  static const double radiusFull = 999;

  /// Minimum touch target (WCAG / Material).
  static const double minTap = 48;

  /// Minimum readable body / label sizes (before responsive scaling).
  static const double bodyMin = 14;
  static const double labelMin = 12;

  // —— Motion ——
  static const Duration tapFade = Duration(milliseconds: 120);
  static const Duration sheetTransition = Duration(milliseconds: 280);

  static TextStyle screenTitle(ThemeData t, {required Color color}) {
    final base = t.textTheme.headlineSmall ?? t.textTheme.titleLarge!;
    return base.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontSize: (base.fontSize ?? 22).clamp(20.0, 28.0),
      height: 1.2,
    );
  }

  static TextStyle sheetTitle(ThemeData t, {required Color color}) {
    final base = t.textTheme.titleLarge ?? t.textTheme.titleMedium!;
    return base.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontSize: (base.fontSize ?? 22).clamp(18.0, 26.0),
      height: 1.25,
    );
  }

  static TextStyle sheetBody(ThemeData t, {required Color color, double a = 1}) {
    return (t.textTheme.bodyLarge ?? t.textTheme.bodyMedium!).copyWith(
      color: color.withValues(alpha: a),
      fontSize: (t.textTheme.bodyLarge?.fontSize ?? bodyMin).clamp(bodyMin, 20.0),
      height: 1.35,
    );
  }

  static TextStyle sheetCaption(ThemeData t, {required Color color}) {
    return (t.textTheme.bodySmall ?? t.textTheme.labelLarge!).copyWith(
      color: color,
      fontSize: (t.textTheme.bodySmall?.fontSize ?? labelMin).clamp(labelMin, 16.0),
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
  }

  static List<BoxShadow> shadowSoft({double opacity = 0.14}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
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

  /// Premium dark surface for modal bottom sheets (matches app scaffold tone).
  static const Color sheetBackground = Color(0xFF24292F);

  /// Subtle border for sheet sections / list rows on [sheetBackground].
  static Color sheetBorderSubtle([double a = 0.2]) =>
      Colors.white.withValues(alpha: a);

  /// Muted list / chip fill on dark sheets.
  static Color sheetListFill([double a = 0.08]) =>
      Colors.white.withValues(alpha: a);

  /// Editor toolbar / dark sheet surfaces (pairs with app scaffold).
  static Color editorToolbarBg(ColorScheme cs) => cs.onPrimary;

  static Color editorToolbarBorder(ColorScheme cs) =>
      cs.onSecondary.withValues(alpha: 0.2);

  static Color editorToolChipFill(ColorScheme cs) =>
      cs.onPrimary.withValues(alpha: 0.14);
}
