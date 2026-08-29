import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../models/size_preset.dart';

class SizePresetCard extends StatelessWidget {
  const SizePresetCard({
    super.key,
    required this.preset,
    this.denseOnDark = false,
    required this.onTap,
  });

  final SizePreset preset;
  final bool denseOnDark;
  final VoidCallback onTap;

  bool get _isBasic => preset.category.toLowerCase() == 'basic';

  ({Color bg, Color fg, Color accent, IconData? icon}) _categoryColors(
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;
    final cat = preset.category.toLowerCase();
    if (_isBasic) {
      return (
        bg: AppDs.surfaceRaised,
        fg: AppDs.textOnDarkPrimary,
        accent: AppDs.accentYellow,
        icon: null,
      );
    }
    if (cat.contains('facebook')) {
      return (
        bg: appTheme.indigo700,
        fg: Colors.white,
        accent: Colors.white,
        icon: Icons.facebook,
      );
    }
    if (cat.contains('instagram')) {
      return (
        bg: appTheme.pink500,
        fg: Colors.white,
        accent: Colors.white,
        icon: Icons.camera_alt_outlined,
      );
    }
    if (cat.contains('youtube')) {
      return (
        bg: appTheme.redA70001,
        fg: Colors.white,
        accent: Colors.white,
        icon: Icons.play_arrow_rounded,
      );
    }
    if (cat.contains('web')) {
      return (
        bg: cs.primary.withValues(alpha: 0.22),
        fg: AppDs.textOnDarkPrimary,
        accent: AppDs.accentYellow,
        icon: Icons.public_outlined,
      );
    }
    if (cat.contains('print')) {
      return (
        bg: Colors.white.withValues(alpha: 0.1),
        fg: AppDs.textOnDarkPrimary,
        accent: AppDs.accentYellow,
        icon: Icons.print_outlined,
      );
    }
    return (
      bg: AppDs.surfaceRaised,
      fg: AppDs.textOnDarkPrimary,
      accent: AppDs.accentYellow,
      icon: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = _categoryColors(theme);
    final dims = '${preset.width.round()} × ${preset.height.round()}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        child: Ink(
          padding: EdgeInsets.all(AppDs.space3.adaptSize),
          decoration: BoxDecoration(
            color: cat.bg,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
            border: Border.all(
              color: denseOnDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: AppDs.shadowSoft(opacity: 0.16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(
                      AppDs.radiusSm.adaptSize,
                    ),
                  ),
                  child: _RatioShape(
                    aspectRatio: preset.aspectRatio,
                    color: cat.accent,
                  ),
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              Row(
                children: [
                  if (cat.icon != null) ...[
                    Icon(cat.icon, color: cat.fg, size: 16.adaptSize),
                    SizedBox(width: 6.h),
                  ],
                  Expanded(
                    child: Text(
                      preset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cat.fg,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.v),
              Text(
                dims,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cat.fg.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.v),
              Text(
                preset.ratio,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cat.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatioShape extends StatelessWidget {
  const _RatioShape({required this.aspectRatio, required this.color});

  final double aspectRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ar = aspectRatio <= 0 ? 1.0 : aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * 0.62;
        final maxH = constraints.maxHeight * 0.62;
        double w;
        double h;
        if (ar >= 1) {
          w = maxW;
          h = maxW / ar;
          if (h > maxH) {
            h = maxH;
            w = maxH * ar;
          }
        } else {
          h = maxH;
          w = maxH * ar;
          if (w > maxW) {
            w = maxW;
            h = maxW / ar;
          }
        }
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.adaptSize),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      },
    );
  }
}
