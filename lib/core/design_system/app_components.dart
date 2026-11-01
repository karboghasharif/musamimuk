import 'package:flutter/material.dart';

import '../utils/size_utils.dart';
import '../../widgets/custom_image_view.dart';
import 'app_design_tokens.dart';
import 'app_motion.dart';
import 'app_typography.dart';

/// Semantic text widget — enforces typography tokens.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.variant = AppTextVariant.body,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
  });

  final String data;
  final AppTextVariant variant;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final style = switch (variant) {
      AppTextVariant.display => AppTypography.display(t),
      AppTextVariant.heading => AppTypography.heading(t),
      AppTextVariant.title => AppTypography.title(t),
      AppTextVariant.body => AppTypography.body(t),
      AppTextVariant.secondary => AppTypography.secondary(t),
      AppTextVariant.caption => AppTypography.caption(t),
      AppTextVariant.accent => AppTypography.accent(t),
    }.copyWith(color: color);

    return Semantics(
      label: semanticsLabel,
      child: Text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}

enum AppTextVariant {
  display,
  heading,
  title,
  body,
  secondary,
  caption,
  accent,
}

/// Filter / nav chip with active state styling.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return FilterChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: AppDs.iconSm.adaptSize,
              color: selected ? cs.primary : AppDs.textOnDarkSecondary,
            )
          : null,
      label: Text(
        label,
        style: selected
            ? AppTypography.navActive(t)
            : AppTypography.navInactive(t),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: cs.primary.withValues(alpha: 0.2),
      checkmarkColor: AppDs.textOnDarkPrimary,
      side: BorderSide(
        color: selected
            ? cs.primary.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}

/// Full-width primary CTA — 52px height, loading + press scale.
class AppPrimaryButton extends StatefulWidget {
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
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = !widget.isLoading && widget.onPressed != null;
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDs.motionFast,
        curve: Curves.easeOutCubic,
        child: FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
            disabledForegroundColor: cs.onPrimary.withValues(alpha: 0.5),
            minimumSize: Size(
              widget.expandWidth ? double.infinity : 0,
              AppDs.buttonHeight.v,
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
            animationDuration: AppDs.motionFast,
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 22.adaptSize,
                  height: 22.adaptSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTypography.buttonLabel(Theme.of(context)),
                ),
        ),
      ),
    );
  }
}

/// Themed text field — label, hint, validation, prefix/suffix, focus ring.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.textInputType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.autofocus = false,
    this.enabled = true,
    this.semanticsLabel,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType textInputType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;
  final bool enabled;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget? prefixWidget = prefix;
    if (prefixWidget == null && prefixIcon != null) {
      prefixWidget = Icon(
        prefixIcon,
        size: AppDs.iconSm.adaptSize,
        color: AppDs.textOnDarkSecondary,
      );
    }

    return Semantics(
      label: semanticsLabel ?? label ?? hintText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && label!.trim().isNotEmpty) ...[
            AppText(label!.trim(), variant: AppTextVariant.caption),
            SizedBox(height: AppDs.space2.v),
          ],
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: textInputType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            validator: validator,
            style: AppTypography.body(theme),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixWidget != null
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: AppDs.space3.h,
                        end: AppDs.space2.h,
                      ),
                      child: prefixWidget,
                    )
                  : null,
              prefixIconConstraints: BoxConstraints(
                minWidth: AppDs.minTap,
                minHeight: AppDs.minTap,
              ),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: AppDs.space2.h,
                      ),
                      child: suffix,
                    )
                  : null,
              suffixIconConstraints: BoxConstraints(
                minWidth: AppDs.minTap,
                minHeight: AppDs.minTap,
              ),
              errorStyle: AppTypography.caption(theme).copyWith(
                color: cs.error,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: prefixWidget == null ? AppDs.space4.h : 0,
                vertical: AppDs.space3.v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outline button for dark panels / high-contrast secondary actions.
class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.foregroundOnDark = true,
    this.isLoading = false,
    this.expandWidth = true,
    this.outlineColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool foregroundOnDark;
  final bool isLoading;
  final bool expandWidth;
  final Color? outlineColor;

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = widget.foregroundOnDark
        ? AppDs.textOnDarkPrimary
        : cs.onSurface;
    final enabled = !widget.isLoading && widget.onPressed != null;
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDs.motionFast,
        curve: Curves.easeOutCubic,
        child: OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(
              color: widget.outlineColor ??
                  Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            minimumSize: Size(
              widget.expandWidth ? double.infinity : 0,
              AppDs.buttonHeight.v,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space4.h,
              vertical: AppDs.space3.v,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            ),
            animationDuration: AppDs.motionFast,
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 22.adaptSize,
                  height: 22.adaptSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : widget.icon != null || widget.leading != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.leading != null)
                          widget.leading!
                        else
                          Icon(
                            widget.icon,
                            size: AppDs.iconSm.adaptSize,
                            color: cs.primary,
                          ),
                        SizedBox(width: AppDs.space2.h),
                        Text(
                          widget.label,
                          style: AppTypography.buttonLabel(Theme.of(context))
                              .copyWith(color: fg),
                        ),
                      ],
                    )
                  : Text(
                      widget.label,
                      style: AppTypography.buttonLabel(Theme.of(context))
                          .copyWith(color: fg),
                    ),
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
    final muted = AppDs.textOnDarkSecondary;
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

/// Consistent elevated card for lists and detail sections.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = false,
    this.animateIn = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Container(
      width: double.infinity,
      margin: margin,
      decoration: AppDs.cardDecoration(elevated: elevated),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Inside Expanded / tight height, Column must flex the body so
          // scrollables get a bounded viewport instead of overflowing.
          final boundedHeight = constraints.hasBoundedHeight;
          final hasTitle = title != null && title!.trim().isNotEmpty;
          final hasFooter = actionLabel != null && onAction != null;

          final body = boundedHeight ? Expanded(child: child) : child;

          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                boundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (hasTitle) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!.trim(),
                            style: AppTypography.cardTitle(theme),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            SizedBox(height: AppDs.space1.v),
                            Text(
                              subtitle!.trim(),
                              style: AppTypography.secondary(theme),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
                SizedBox(height: AppDs.space3.v),
              ],
              body,
              if (hasFooter) ...[
                SizedBox(height: AppDs.space4.v),
                AppSecondaryButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          );

          final content = Padding(
            padding: padding ?? EdgeInsets.all(AppDs.space4.h),
            child: column,
          );

          if (onTap == null) return content;
          return Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap, child: content),
          );
        },
      ),
    );

    if (animateIn) {
      card = AppFadeIn(child: card);
    }
    return card;
  }
}

/// Standard search field matching the design system.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.body(Theme.of(context)),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: AppDs.iconSm.adaptSize,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Page header with title and optional subtitle.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.align = TextAlign.start,
  });

  final String title;
  final String? subtitle;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: AppTypography.pageTitle(theme),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          SizedBox(height: AppDs.space2.v),
          Text(
            subtitle!.trim(),
            textAlign: align,
            style: AppTypography.secondary(theme),
          ),
        ],
      ],
    );
  }
}

/// Horizontal filter chips row with consistent spacing.
class AppFilterChipRow extends StatelessWidget {
  const AppFilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDs.buttonHeight.v * 0.72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => SizedBox(width: AppDs.space2.h),
        itemBuilder: (context, index) {
          return AppChip(
            label: labels[index],
            selected: selectedIndex == index,
            onSelected: (_) => onSelected(index),
          );
        },
      ),
    );
  }
}

/// Section heading within a screen (secondary to page title).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDs.space3.v),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, variant: AppTextVariant.heading),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: AppDs.space1.v),
                  AppText(subtitle!.trim(), variant: AppTextVariant.secondary),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Standard scrollable screen shell: gutter padding + optional header.
class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.title,
    this.subtitle,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
    this.headerSpacing,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final String? title;
  final String? subtitle;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final double? headerSpacing;

  @override
  Widget build(BuildContext context) {
    final gutter = padding ??
        EdgeInsets.fromLTRB(
          AppDs.space4.h,
          AppDs.space3.v,
          AppDs.space4.h,
          AppDs.space6.v,
        );

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: gutter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && title!.trim().isNotEmpty) ...[
              AppPageHeader(title: title!.trim(), subtitle: subtitle),
              SizedBox(height: headerSpacing?.v ?? AppDs.space6.v),
            ],
            body,
          ],
        ),
      ),
    );
  }
}

/// Handles loading / error / empty / content states consistently.
class AppAsyncBody extends StatelessWidget {
  const AppAsyncBody({
    super.key,
    required this.isLoading,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.emptyTitle,
    this.emptyMessage,
    this.loading,
  });

  final bool isLoading;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String? emptyTitle;
  final String? emptyMessage;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loading ?? const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDs.space8),
        child: AppLoadingBlock(),
      );
    }
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return AppErrorState(message: errorMessage!.trim(), onRetry: onRetry);
    }
    if (isEmpty) {
      return AppEmptyState(
        title: emptyTitle ?? 'No results',
        message: emptyMessage,
      );
    }
    return child;
  }
}

/// Horizontal divider with centered label — auth / onboarding screens.
class AppLabeledDivider extends StatelessWidget {
  const AppLabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDs.space3.h),
          child: AppText(label, variant: AppTextVariant.caption),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
      ],
    );
  }
}

/// Compact social / OAuth icon button — logo or icon in a 48×48 row tile.
class AppSocialIconButton extends StatelessWidget {
  const AppSocialIconButton({
    super.key,
    required this.semanticsLabel,
    required this.onPressed,
    this.icon,
    this.child,
    this.isLoading = false,
    this.size = AppDs.minTap,
  });

  final String semanticsLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final bool isLoading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = !isLoading && onPressed != null;
    final logoSize = AppDs.iconMd.adaptSize;

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: enabled,
      child: AppScaleTap(
        enabled: enabled,
        onTap: onPressed,
        child: Container(
          width: size.h,
          height: size.v,
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                )
              : Center(
                  child: child ??
                      Icon(
                        icon,
                        size: logoSize,
                        color: cs.primary,
                      ),
                ),
        ),
      ),
    );
  }
}

/// Hub tile: icon/image + label (home, search nav).
class AppQuickActionTile extends StatelessWidget {
  const AppQuickActionTile({
    super.key,
    this.icon,
    this.imagePath,
    required this.label,
    this.onTap,
    this.highlighted = false,
  });

  final IconData? icon;
  final String? imagePath;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        child: SizedBox(
          width: 80.h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppDs.space3.adaptSize),
                decoration: BoxDecoration(
                  color: highlighted
                      ? cs.primary.withValues(alpha: 0.18)
                      : AppDs.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
                  border: highlighted
                      ? Border.all(color: cs.primary.withValues(alpha: 0.5))
                      : null,
                ),
                child: icon != null
                    ? Icon(
                        icon,
                        size: AppDs.iconMd.adaptSize,
                        color: highlighted ? cs.primary : AppDs.textOnDarkPrimary,
                      )
                    : CustomImageView(
                        imagePath: imagePath,
                        height: AppDs.iconMd.adaptSize,
                        width: AppDs.iconMd.adaptSize,
                      ),
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                label,
                variant: highlighted
                    ? AppTextVariant.body
                    : AppTextVariant.secondary,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft studio-lamp wash from top-start (RTL/LTR via [AlignmentDirectional]).
class AppAtelierAtmosphere extends StatelessWidget {
  const AppAtelierAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppDs.atelierInk,
          gradient: RadialGradient(
            center: AlignmentDirectional.topStart.resolve(
              Directionality.of(context),
            ),
            radius: 1.15,
            colors: const [
              AppDs.atelierLamp,
              Color(0x00252A30),
            ],
            stops: const [0.0, 0.72],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
