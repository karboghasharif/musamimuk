import 'package:flutter/material.dart';

import '../utils/size_utils.dart';
import 'app_design_tokens.dart';

/// Semantic typography helpers — use instead of ad-hoc [TextStyle]s.
abstract final class AppTypography {
  /// 32 Bold — hero / display text.
  static TextStyle display(ThemeData t) {
    return (t.textTheme.headlineLarge ?? t.textTheme.headlineMedium!).copyWith(
      fontSize: AppDs.fontDisplay.fSize,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.5,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  /// 24 SemiBold — screen headings.
  static TextStyle heading(ThemeData t) {
    return (t.textTheme.headlineSmall ?? t.textTheme.titleLarge!).copyWith(
      fontSize: AppDs.fontHeading.fSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  static TextStyle pageTitle(ThemeData t) {
    return (t.textTheme.headlineMedium ?? t.textTheme.titleLarge!).copyWith(
      fontSize: AppDs.fontPageTitle.fSize,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.3,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  static TextStyle sectionTitle(ThemeData t) {
    return (t.textTheme.titleLarge ?? t.textTheme.titleMedium!).copyWith(
      fontSize: AppDs.fontSectionTitle.fSize,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  /// 18 Medium — card / list titles.
  static TextStyle title(ThemeData t) {
    return (t.textTheme.titleMedium ?? t.textTheme.bodyLarge!).copyWith(
      fontSize: AppDs.fontTitle.fSize,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  static TextStyle cardTitle(ThemeData t) {
    return (t.textTheme.titleMedium ?? t.textTheme.bodyLarge!).copyWith(
      fontSize: AppDs.fontCardTitle.fSize,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  static TextStyle body(ThemeData t) {
    return (t.textTheme.bodyLarge ?? t.textTheme.bodyMedium!).copyWith(
      fontSize: AppDs.fontBody.fSize,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  static TextStyle bodyMedium(ThemeData t) {
    return (t.textTheme.bodyMedium ?? t.textTheme.bodyLarge!).copyWith(
      fontSize: AppDs.fontBody.fSize,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppDs.textPrimary(t.colorScheme),
    );
  }

  static TextStyle secondary(ThemeData t) {
    return (t.textTheme.bodySmall ?? t.textTheme.bodyMedium!).copyWith(
      fontSize: AppDs.fontSecondary.fSize,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: AppDs.textSecondary(t.colorScheme),
    );
  }

  static TextStyle label(ThemeData t, {bool bold = false}) {
    return (t.textTheme.labelLarge ?? t.textTheme.bodySmall!).copyWith(
      fontSize: AppDs.fontSecondary.fSize,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
      height: 1.25,
      color: AppDs.textOnDarkPrimary,
    );
  }

  /// Supporting copy on dark cards (descriptions, categories).
  static TextStyle caption(ThemeData t) {
    return secondary(t);
  }

  /// Numeric highlights, counts, stat values.
  static TextStyle accent(ThemeData t) {
    return (t.textTheme.titleMedium ?? t.textTheme.bodyLarge!).copyWith(
      fontSize: AppDs.fontCardTitle.fSize,
      fontWeight: FontWeight.w700,
      color: AppDs.textAccent(t.colorScheme),
    );
  }

  /// Stat / metric labels on dark surfaces.
  static TextStyle statLabel(ThemeData t) {
    return (t.textTheme.bodySmall ?? t.textTheme.labelLarge!).copyWith(
      fontSize: AppDs.fontSecondary.fSize,
      fontWeight: FontWeight.w500,
      color: AppDs.textOnDarkPrimary,
    );
  }

  /// Stat / metric values — brand yellow.
  static TextStyle statValue(ThemeData t, {bool highlight = true}) {
    return (t.textTheme.titleSmall ?? t.textTheme.bodyLarge!).copyWith(
      fontSize: AppDs.fontCardTitle.fSize,
      fontWeight: FontWeight.w800,
      color: highlight
          ? AppDs.textAccent(t.colorScheme)
          : AppDs.textOnDarkPrimary,
    );
  }

  /// Countdown digits — hero emphasis.
  static TextStyle countdown(ThemeData t) {
    return (t.textTheme.headlineSmall ?? t.textTheme.titleLarge!).copyWith(
      fontSize: AppDs.fontHeading.fSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppDs.textOnDarkPrimary,
    );
  }

  static TextStyle countdownLabel(ThemeData t) {
    return (t.textTheme.bodySmall ?? t.textTheme.labelMedium!).copyWith(
      fontSize: AppDs.fontCaption.fSize,
      fontWeight: FontWeight.w500,
      color: AppDs.textSecondary(t.colorScheme),
    );
  }

  /// Navigation / filter chip — active.
  static TextStyle navActive(ThemeData t) {
    return label(t, bold: true).copyWith(color: AppDs.textOnDarkPrimary);
  }

  /// Navigation / filter chip — inactive.
  static TextStyle navInactive(ThemeData t) {
    return label(t).copyWith(color: AppDs.textOnDarkSecondary);
  }

  static TextStyle buttonLabel(ThemeData t) {
    return TextStyle(
      fontSize: AppDs.fontBody.fSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.1,
      color: AppDs.onAccent,
    );
  }
}