import 'package:flutter/material.dart';

import '../utils/size_utils.dart';
import 'app_design_tokens.dart';

/// Full-width primary CTA — 48px min height, loading state.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
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
        minimumSize: Size(
          expandWidth ? double.infinity : 0,
          AppDs.minTap.v,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space4.h,
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

/// Outline button for dark panels / high-contrast secondary actions.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foregroundOnDark = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool foregroundOnDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foregroundOnDark ? Colors.white : cs.onSurface;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
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

/// Centered loading block for sheets and list bodies (no extra packages).
class AppLoadingBlock extends StatelessWidget {
  const AppLoadingBlock({super.key, this.message, this.progress});

  final String? message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    return Center(
      child: Semantics(
        label: message ?? 'Loading',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null)
              SizedBox(
                width: 40.adaptSize,
                height: 40.adaptSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: progress,
                  color: theme.colorScheme.primary,
                ),
              )
            else
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
                style: AppDs.sheetCaption(theme, color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty list / screen placeholder with optional primary action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.all(AppDs.space6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.adaptSize, color: cs.primary.withValues(alpha: 0.85)),
          SizedBox(height: AppDs.space4.v),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppDs.sheetTitle(theme, color: cs.onSurface),
          ),
          if (message != null) ...[
            SizedBox(height: AppDs.space2.v),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppDs.sheetCaption(
                theme,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: AppDs.space6.v),
            AppPrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state with icon + message + retry (not color-only: uses icon + text).
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.all(AppDs.space6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 44.adaptSize,
            semanticLabel: 'Error',
            color: cs.error,
          ),
          SizedBox(height: AppDs.space4.v),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppDs.sheetBody(theme, color: cs.onSurface),
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppDs.space5.v),
            AppPrimaryButton(
              label: retryLabel,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Standard content padding for scrollable screens.
class AppScreenGutter extends StatelessWidget {
  const AppScreenGutter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      child: child,
    );
  }
}
