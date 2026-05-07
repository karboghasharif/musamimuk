import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Primary CTA — filled, minimum 48px height, clear focus for save / continue.
class AddNewPrimaryCta extends StatelessWidget {
  const AddNewPrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expandWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expandWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: cs.primary.withValues(alpha: 0.38),
        disabledForegroundColor: cs.onPrimary.withValues(alpha: 0.6),
        minimumSize: Size(expandWidth ? double.infinity : 0, AppDs.minTap.v),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.symmetric(
          horizontal: expandWidth ? AppDs.space4.h : AppDs.space4.h,
          vertical: AppDs.space2.v,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              width: 22.adaptSize,
              height: 22.adaptSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onPrimary,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: AppDs.bodyMin.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Secondary action — outline on dark sheets.
class AddNewSecondaryCta extends StatelessWidget {
  const AddNewSecondaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: cs.primary, width: 1.5),
        minimumSize: Size(double.infinity, AppDs.minTap.v),
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space4.h,
          vertical: AppDs.space3.v,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20.adaptSize, color: cs.primary),
                SizedBox(width: AppDs.space2.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppDs.bodyMin.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: AppDs.bodyMin.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Text-only cancel / tertiary on dark UI.
class AddNewTertiaryCta extends StatelessWidget {
  const AddNewTertiaryCta({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.72),
        minimumSize: Size(double.infinity, AppDs.minTap.v),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDs.bodyMin.fSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Single selectable row (radio semantics) — visibility, settings.
class AddNewSelectableOption extends StatelessWidget {
  const AddNewSelectableOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.semanticsHint,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final borderColor = selected
        ? cs.primary
        : Colors.white.withValues(alpha: 0.22);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      hint: semanticsHint,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppDs.space3.v),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            splashColor: cs.primary.withValues(alpha: 0.12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(minHeight: AppDs.minTap.v),
              padding: EdgeInsets.symmetric(
                horizontal: AppDs.space4.h,
                vertical: AppDs.space3.v,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                border: Border.all(color: borderColor, width: selected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(icon, color: cs.primary, size: 24.adaptSize),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: Text(
                      label,
                      style: AppDs.sheetBody(theme, color: Colors.white),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: cs.primary,
                      size: 22.adaptSize,
                      semanticLabel: 'Selected',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable row with chevron — share / settings lists on dark sheets.
class AddNewListActionRow extends StatelessWidget {
  const AddNewListActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.semanticsHint,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      button: true,
      label: label,
      hint: semanticsHint,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppDs.space3.v),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            splashColor: Colors.white.withValues(alpha: 0.08),
            child: Container(
              constraints: BoxConstraints(minHeight: AppDs.minTap.v),
              padding: EdgeInsets.symmetric(
                horizontal: AppDs.space4.h,
                vertical: AppDs.space3.v,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 24.adaptSize, color: cs.primary),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: Text(
                      label,
                      style: AppDs.sheetBody(theme, color: Colors.white),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 24.adaptSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header with icon — download / share groups.
class AddNewSectionHeader extends StatelessWidget {
  const AddNewSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDs.space3.v),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 26.adaptSize),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16).clamp(
                  16.0,
                  20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Format chip — export type.
class AddNewFormatChip extends StatelessWidget {
  const AddNewFormatChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDs.radiusSm.h),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Container(
            constraints: BoxConstraints(minHeight: AppDs.minTap.v * 0.85),
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space4.h,
              vertical: AppDs.space2.v,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDs.radiusSm.h),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                label,
                style: AppDs.sheetCaption(
                  theme,
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal editor tool: icon + label, meets min tap height.
class AddNewEditorToolButton extends StatelessWidget {
  const AddNewEditorToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ic = iconColor ?? cs.primary;
    final lc = labelColor ?? cs.surface;
    final bg = backgroundColor ?? AppDs.editorToolChipFill(cs);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: AppDs.minTap.h,
              minHeight: AppDs.minTap.v,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDs.space2.h,
                vertical: AppDs.space1.v,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: ic, size: 20.adaptSize),
                  SizedBox(height: AppDs.space1.v),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: lc,
                      height: 1.1,
                      fontSize:
                          (theme.textTheme.labelMedium?.fontSize ??
                                  AppDs.labelMin)
                              .clamp(AppDs.labelMin, 14.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shell for bottom toolbars (text / image context).
class AddNewEditorToolbarShell extends StatelessWidget {
  const AddNewEditorToolbarShell({
    super.key,
    required this.theme,
    required this.child,
  });

  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppDs.space3.h,
          AppDs.space3.v,
          AppDs.space3.h,
          AppDs.space3.v,
        ),
        decoration: BoxDecoration(
          color: AppDs.editorToolbarBg(cs),
          border: Border(top: BorderSide(color: AppDs.editorToolbarBorder(cs))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Loading placeholder for asset grids (no extra dependencies).
class AddNewLoadingBlock extends StatelessWidget {
  const AddNewLoadingBlock({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32.adaptSize,
            height: 32.adaptSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppDs.space4.v),
            Text(
              message!,
              style: AppDs.sheetCaption(
                theme,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
