import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';

class EditorBottomToolbar extends StatelessWidget {
  const EditorBottomToolbar({
    super.key,
    required this.mode,
    required this.editor,
    required this.onDeselect,
    required this.onDelete,
    required this.onDuplicate,
    required this.onEdit,
    required this.onSize,
    required this.onOpacity,
    required this.onStroke,
    required this.onShadow,
    required this.onStyle,
    required this.onFonts,
    required this.onColor,
    required this.onGradient,
    required this.defaultTools,
    required this.settingsRow,
  });

  final String mode;
  final ProImageEditorState editor;

  final VoidCallback onDeselect;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onSize;
  final VoidCallback onOpacity;
  final VoidCallback onStroke;
  final VoidCallback onShadow;
  final VoidCallback onStyle;
  final VoidCallback onFonts;
  final VoidCallback onColor;
  final VoidCallback onGradient;

  final Widget defaultTools;
  final Widget settingsRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mode == 'text')
            TextContextToolbar(
              theme: theme,
              onDelete: onDelete,
              onSize: onSize,
              onStroke: onStroke,
              onDuplicate: onDuplicate,
              onOpacity: onOpacity,
              onDeselect: onDeselect,
              onEdit: onEdit,
              onFonts: onFonts,
              onColor: onColor,
            )
          else ...[
            defaultTools,
            settingsRow,
          ],
        ],
      ),
    );
  }
}

/// Two-tier bar when text is selected: primary (app red + white glyphs) like the
/// reference editor; secondary (white + dark icons) with Deselect in a red strip.
class TextContextToolbar extends StatelessWidget {
  const TextContextToolbar({
    super.key,
    required this.theme,
    required this.onDelete,
    required this.onSize,
    required this.onStroke,
    required this.onDuplicate,
    required this.onOpacity,
    required this.onDeselect,
    required this.onEdit,
    required this.onFonts,
    required this.onColor,
    this.secondaryPanel = 'default',
    this.onCloseSecondaryPanel,
    this.onSetOutlineWidth,
    this.onPickOutlineColor,
    this.currentOutlineWidth,
    this.isBold,
    this.isItalic,
    this.isUnderline,
    this.onSetRegular,
    this.onToggleBold,
    this.onToggleItalic,
    this.onToggleUnderline,
    this.onPickTextColor,
    this.onPickTextBackgroundColor,
  });

  final ThemeData theme;
  final VoidCallback onDelete;
  final VoidCallback onSize;
  final VoidCallback onStroke;
  final VoidCallback onDuplicate;
  final VoidCallback onOpacity;
  final VoidCallback onDeselect;
  final VoidCallback onEdit;
  final VoidCallback onFonts;
  final VoidCallback onColor;
  final String secondaryPanel;
  final VoidCallback? onCloseSecondaryPanel;
  final void Function(double width)? onSetOutlineWidth;
  final VoidCallback? onPickOutlineColor;
  final double? currentOutlineWidth;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderline;
  final VoidCallback? onSetRegular;
  final VoidCallback? onToggleBold;
  final VoidCallback? onToggleItalic;
  final VoidCallback? onToggleUnderline;
  final VoidCallback? onPickTextColor;
  final VoidCallback? onPickTextBackgroundColor;

  static const Color _onLightBar = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final primary = cs.primary;

    // bottomNavigationBar allows unbounded height; pin bar heights so Row
    // + crossAxisAlignment.stretch never sees infinite vertical constraints.
    // Match [ImageContextToolbar]: scroll + tool vertical padding eats 4× space2.
    final primaryBarH = AppDs.minTap.v + AppDs.space4.v + AppDs.space2.v;
    final secondaryBarH = AppDs.minTap.v + AppDs.space4.v + 18.v;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: primaryBarH,
          width: double.infinity,
          child: Material(
            color: primary,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                vertical: AppDs.space2.v,
                horizontal: AppDs.space2.h,
              ),
              child: Row(
                children: [
                  _PrimaryBarTool(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    onTap: onDelete,
                  ),
                  _PrimaryBarTool(
                    icon: Icons.text_fields_rounded,
                    label: 'Size',
                    onTap: onSize,
                  ),
                  _PrimaryBarTool(
                    icon: Icons.border_color_outlined,
                    label: 'Stroke',
                    onTap: onStroke,
                  ),
                  _PrimaryBarTool(
                    icon: Icons.copy_all_outlined,
                    label: 'Duplicate',
                    onTap: onDuplicate,
                  ),
                  _PrimaryBarTool(
                    icon: Icons.opacity_rounded,
                    label: 'Opacity',
                    onTap: onOpacity,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: secondaryBarH,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: primary,
                  child: InkWell(
                    onTap: onDeselect,
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDs.space3.h,
                        vertical: AppDs.space2.v,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 26.adaptSize,
                            height: 26.adaptSize,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove_rounded,
                              color: primary,
                              size: 22.adaptSize,
                            ),
                          ),
                          SizedBox(height: AppDs.space1.v),
                          Text(
                            'Deselect',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.fSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDs.space2.v,
                      horizontal: AppDs.space1.h,
                    ),
                    child: secondaryPanel == 'stroke'
                        ? _TextStyleInlinePanel(
                            theme: theme,
                            onBack: onCloseSecondaryPanel ?? onDeselect,
                            isBold: isBold ?? false,
                            isItalic: isItalic ?? false,
                            isUnderline: isUnderline ?? false,
                            onSetRegular: onSetRegular,
                            onToggleBold: onToggleBold,
                            onToggleItalic: onToggleItalic,
                            onToggleUnderline: onToggleUnderline,
                            onPickTextColor: onPickTextColor,
                            onPickTextBackgroundColor:
                                onPickTextBackgroundColor,
                            onSetOutlineWidth: onSetOutlineWidth,
                            onPickOutlineColor: onPickOutlineColor,
                            outlineWidth: currentOutlineWidth ?? 0,
                          )
                        : Row(
                            children: [
                              _SecondaryBarTool(
                                theme: theme,
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: onEdit,
                              ),
                              _SecondaryBarTool(
                                theme: theme,
                                icon: Icons.title_rounded,
                                label: 'Fonts',
                                onTap: onFonts,
                              ),
                              _SecondaryBarTool(
                                theme: theme,
                                icon: Icons.format_color_text_rounded,
                                label: 'Colour',
                                onTap: onColor,
                              ),
                              if (onPickTextBackgroundColor != null)
                                _SecondaryBarTool(
                                  theme: theme,
                                  icon: Icons.format_color_fill_rounded,
                                  label: 'Background',
                                  onTap: onPickTextBackgroundColor!,
                                ),
                              _SecondaryBarTool(
                                theme: theme,
                                icon: Icons.text_fields_rounded,
                                label: 'Size',
                                onTap: onSize,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextStyleInlinePanel extends StatelessWidget {
  const _TextStyleInlinePanel({
    required this.theme,
    required this.onBack,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.onSetRegular,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleUnderline,
    required this.onPickTextColor,
    required this.onPickTextBackgroundColor,
    required this.onSetOutlineWidth,
    required this.onPickOutlineColor,
    required this.outlineWidth,
  });

  final ThemeData theme;
  final VoidCallback onBack;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final VoidCallback? onSetRegular;
  final VoidCallback? onToggleBold;
  final VoidCallback? onToggleItalic;
  final VoidCallback? onToggleUnderline;
  final VoidCallback? onPickTextColor;
  final VoidCallback? onPickTextBackgroundColor;
  final void Function(double width)? onSetOutlineWidth;
  final VoidCallback? onPickOutlineColor;
  final double outlineWidth;

  static double get _toolW => 76.h;
  static const List<double> _outlineWidths = <double>[0, 1, 2, 3, 4, 6, 8];

  String _wLabel(double w) {
    if (w <= 0) return 'Off';
    if ((w - w.roundToDouble()).abs() < 0.01) return '${w.toInt()}px';
    return '${w.toStringAsFixed(1)}px';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _toolW,
          child: _InlineToolButton(
            theme: theme,
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            onTap: onBack,
          ),
        ),
        SizedBox(width: AppDs.space1.h),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.text_fields_rounded,
                    label: 'Regular',
                    onTap: onSetRegular ?? () {},
                    active: !isBold && !isItalic,
                  ),
                ),
                SizedBox(width: AppDs.space1.h),
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.format_bold_rounded,
                    label: 'Bold',
                    onTap: onToggleBold ?? () {},
                    active: isBold,
                  ),
                ),
                SizedBox(width: AppDs.space1.h),
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.format_italic_rounded,
                    label: 'Italic',
                    onTap: onToggleItalic ?? () {},
                    active: isItalic,
                  ),
                ),
                SizedBox(width: AppDs.space1.h),
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.format_underline_rounded,
                    label: 'Underline',
                    onTap: onToggleUnderline ?? () {},
                    active: isUnderline,
                  ),
                ),
                SizedBox(width: AppDs.space2.h),
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.format_color_text_rounded,
                    label: 'Text',
                    onTap: onPickTextColor ?? () {},
                  ),
                ),
                SizedBox(width: AppDs.space1.h),
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.format_color_fill_rounded,
                    label: 'BG',
                    onTap: onPickTextBackgroundColor ?? () {},
                  ),
                ),
                SizedBox(width: AppDs.space2.h),
                for (final w in _outlineWidths) ...[
                  SizedBox(
                    width: _toolW,
                    child: _InlineToolButton(
                      theme: theme,
                      icon: Icons.border_outer_rounded,
                      label: 'Out ${_wLabel(w)}',
                      onTap: () => onSetOutlineWidth?.call(w),
                      active: (outlineWidth - w).abs() < 0.01,
                    ),
                  ),
                  SizedBox(width: AppDs.space1.h),
                ],
                SizedBox(width: AppDs.space2.h),
                SizedBox(
                  width: _toolW,
                  child: _InlineToolButton(
                    theme: theme,
                    icon: Icons.palette_outlined,
                    label: 'Out color',
                    onTap: onPickOutlineColor ?? () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineToolButton extends StatelessWidget {
  const _InlineToolButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Material(
      color: active ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
        splashColor: cs.primary.withValues(alpha: 0.12),
        highlightColor: cs.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppDs.space1.v,
            horizontal: 2.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: TextContextToolbar._onLightBar,
                size: 22.adaptSize,
              ),
              SizedBox(height: AppDs.space1.v),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: TextContextToolbar._onLightBar,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 10.fSize,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBarTool extends StatelessWidget {
  const _PrimaryBarTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static double get _minW => 56.h;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _minW,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppDs.space2.v,
              horizontal: 2.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: 22.adaptSize),
                SizedBox(height: AppDs.space1.v),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.fSize,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBarTool extends StatelessWidget {
  const _SecondaryBarTool({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? theme.colorScheme.primary
        : TextContextToolbar._onLightBar;
    final textColor = selected
        ? theme.colorScheme.primary
        : TextContextToolbar._onLightBar;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppDs.space1.v,
              horizontal: 2.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 22.adaptSize),
                SizedBox(height: AppDs.space1.v),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.fSize,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-tier bar when an image/widget layer is selected (matches reference layout).
class ImageContextToolbar extends StatelessWidget {
  const ImageContextToolbar({
    super.key,
    required this.theme,
    required this.onDelete,
    required this.onResize,
    this.onCrop,
    required this.onBorder,
    required this.onShadow,
    required this.onDuplicate,
    required this.onOpacity,
    required this.onDeselect,
    required this.onReplace,
    required this.onAiRemoveBg,
    required this.onColor,
    required this.onAdjust,
    this.secondaryPanel = 'default',
    this.adjustPanel = const SizedBox.shrink(),
  });

  final ThemeData theme;
  final VoidCallback onDelete;
  final VoidCallback onResize;
  /// When null, the Crop tool is hidden (e.g. vector stickers or network-only assets).
  final VoidCallback? onCrop;
  final VoidCallback onBorder;
  final VoidCallback onShadow;
  final VoidCallback onDuplicate;
  final VoidCallback onOpacity;
  final VoidCallback onDeselect;
  final VoidCallback onReplace;
  final VoidCallback onAiRemoveBg;
  final VoidCallback onColor;
  final VoidCallback onAdjust;

  /// `default` | `adjust`
  final String secondaryPanel;
  final Widget adjustPanel;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final primaryBarH = AppDs.minTap.v + AppDs.space4.v + AppDs.space2.v;
    final secondaryBarH = AppDs.minTap.v + AppDs.space4.v + 18.v;
    final isAdjust = secondaryPanel == 'adjust';
    final screenH = MediaQuery.sizeOf(context).height;
    final adjustBarH = math.min(screenH * 0.36, 288.0);
    final secondaryH = isAdjust ? adjustBarH : secondaryBarH;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: primaryBarH,
            width: double.infinity,
            child: Material(
              color: primary,
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  vertical: AppDs.space2.v,
                  horizontal: AppDs.space2.h,
                ),
                child: Row(
                  children: [
                    _PrimaryBarTool(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      onTap: onDelete,
                    ),
                    _PrimaryBarTool(
                      icon: Icons.open_in_full_rounded,
                      label: 'Resize',
                      onTap: onResize,
                    ),
                    if (onCrop != null)
                      _PrimaryBarTool(
                        icon: Icons.crop_rounded,
                        label: 'Crop',
                        onTap: onCrop!,
                      ),
                    _PrimaryBarTool(
                      icon: Icons.border_outer_rounded,
                      label: 'Border',
                      onTap: onBorder,
                    ),
                    _PrimaryBarTool(
                      icon: Icons.layers_outlined,
                      label: 'Shadow',
                      onTap: onShadow,
                    ),
                    _PrimaryBarTool(
                      icon: Icons.copy_all_outlined,
                      label: 'Duplicate',
                      onTap: onDuplicate,
                    ),
                    _PrimaryBarTool(
                      icon: Icons.opacity_rounded,
                      label: 'Opacity',
                      onTap: onOpacity,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: secondaryH,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: primary,
                    child: InkWell(
                      onTap: onDeselect,
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDs.space3.h,
                          vertical: AppDs.space2.v,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 26.adaptSize,
                              height: 26.adaptSize,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.remove_rounded,
                                color: primary,
                                size: 22.adaptSize,
                              ),
                            ),
                            SizedBox(height: AppDs.space1.v),
                            Text(
                              'Deselect',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.fSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: isAdjust
                        ? Padding(
                            padding: EdgeInsets.only(
                              top: AppDs.space1.v,
                              bottom: AppDs.space1.v,
                            ),
                            child: adjustPanel,
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppDs.space2.v,
                              horizontal: AppDs.space1.h,
                            ),
                            child: Row(
                              children: [
                                _SecondaryBarTool(
                                  theme: theme,
                                  icon: Icons.add_photo_alternate_outlined,
                                  label: 'Replace',
                                  onTap: onReplace,
                                ),
                                _SecondaryBarTool(
                                  theme: theme,
                                  icon: Icons.auto_fix_high_rounded,
                                  label: 'msg_remove_background'.tr,
                                  onTap: onAiRemoveBg,
                                ),
                                _SecondaryBarTool(
                                  theme: theme,
                                  icon: Icons.palette_outlined,
                                  label: 'Color',
                                  onTap: onColor,
                                ),
                                _SecondaryBarTool(
                                  theme: theme,
                                  icon: Icons.tune_rounded,
                                  label: 'Adjust',
                                  selected: isAdjust,
                                  onTap: onAdjust,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
