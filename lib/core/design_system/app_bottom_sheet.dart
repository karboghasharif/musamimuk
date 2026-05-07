import 'package:flutter/material.dart';

import '../utils/size_utils.dart';
import 'app_design_tokens.dart';

/// Standard modal bottom sheet: dark surface, top radius, drag handle.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor ?? AppDs.sheetBackground,
    shape: shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDs.radiusSheet.adaptSize),
          ),
        ),
    constraints: constraints,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: builder,
  );
}

/// Consistent insets for sheet content (8pt grid + home indicator).
class AppSheetPagePadding extends StatelessWidget {
  const AppSheetPagePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.top,
    this.bottomExtra,
  });

  final Widget child;
  final double? horizontal;
  final double? top;
  final double? bottomExtra;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + (bottomExtra ?? 0);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        (horizontal ?? AppDs.space4).h,
        (top ?? AppDs.space2).v,
        (horizontal ?? AppDs.space4).h,
        AppDs.space6.v + bottom,
      ),
      child: child,
    );
  }
}

/// Theme overrides for sliders, list tiles, and checkboxes on dark sheets.
class AppDarkSheetTheme extends StatelessWidget {
  const AppDarkSheetTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = Theme.of(context);
    final cs = parent.colorScheme;
    final primary = cs.primary;
    final onPrimary = cs.onPrimary;
    return Theme(
      data: parent.copyWith(
        textTheme: parent.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: IconThemeData(color: primary),
        sliderTheme: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: primary,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
          thumbColor: primary,
          overlayColor: WidgetStateColor.resolveWith(
            (states) => primary.withValues(alpha: 0.2),
          ),
          valueIndicatorColor: primary,
          showValueIndicator: ShowValueIndicator.onlyForContinuous,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: primary,
          textColor: Colors.white,
          titleTextStyle: parent.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: (parent.textTheme.titleMedium?.fontSize ?? AppDs.bodyMin)
                .clamp(AppDs.bodyMin, 20.0),
          ),
          subtitleTextStyle: AppDs.sheetCaption(
            parent,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.12),
          space: 1,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: primary, width: 1.5),
            minimumSize: Size(double.infinity, AppDs.minTap.v),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            minimumSize: Size(double.infinity, AppDs.minTap.v),
            disabledBackgroundColor: primary.withValues(alpha: 0.35),
            disabledForegroundColor: onPrimary.withValues(alpha: 0.5),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.5,
          ),
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return Colors.transparent;
          }),
          checkColor: WidgetStatePropertyAll(onPrimary),
        ),
      ),
      child: child,
    );
  }
}

/// Tappable row for simple pickers (camera / gallery, etc.).
class AppSheetOptionTile extends StatelessWidget {
  const AppSheetOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      button: true,
      label: title,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppDs.space2.v),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            splashColor: cs.primary.withValues(alpha: 0.12),
            child: Ink(
              decoration: BoxDecoration(
                color: AppDs.sheetListFill(0.1),
                borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                border: Border.all(color: AppDs.sheetBorderSubtle(0.18)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: AppDs.minTap.v),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDs.space4.h,
                    vertical: AppDs.space3.v,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: cs.primary, size: 24.adaptSize),
                      SizedBox(width: AppDs.space3.h),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: AppDs.sheetBody(theme, color: Colors.white),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: AppDs.space1.v),
                                child: Text(
                                  subtitle!,
                                  style: AppDs.sheetCaption(
                                    theme,
                                    color: Colors.white.withValues(
                                      alpha: 0.62,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
