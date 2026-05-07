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

  double _minHeight() {
    final ar = preset.aspectRatio;
    if (ar < 0.85) return 240.v; // portrait
    if (ar > 1.35) return 140.v; // landscape
    return 170.v; // square-ish
  }

  bool get _isBasic => preset.category.toLowerCase() == 'basic';

  ({Color bg, Color fg, IconData? icon}) _categoryColors(ThemeData theme) {
    final cs = theme.colorScheme;
    final cat = preset.category.toLowerCase();
    if (_isBasic) {
      return (bg: Colors.white, fg: Colors.black87, icon: null);
    }
    if (cat.contains('facebook')) {
      return (bg: appTheme.indigo700, fg: Colors.white, icon: Icons.facebook);
    }
    if (cat.contains('instagram')) {
      return (bg: appTheme.pink500, fg: Colors.white, icon: Icons.camera_alt_outlined);
    }
    if (cat.contains('youtube')) {
      return (bg: appTheme.redA70001, fg: Colors.white, icon: Icons.play_arrow_rounded);
    }
    if (cat.contains('web')) {
      return (bg: cs.primary.withValues(alpha: 0.18), fg: cs.onPrimary, icon: Icons.public_outlined);
    }
    if (cat.contains('print')) {
      return (bg: cs.secondary.withValues(alpha: 0.22), fg: cs.onSecondaryContainer, icon: Icons.print_outlined);
    }
    return (bg: cs.surface, fg: cs.onSurface, icon: null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cat = _categoryColors(theme);
    final minH = _minHeight();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.adaptSize),
        child: Ink(
          padding: EdgeInsets.all(12.adaptSize),
          decoration: BoxDecoration(
            color: _isBasic ? Colors.white : cat.bg,
            borderRadius: BorderRadius.circular(14.adaptSize),
            border: Border.all(
              color: denseOnDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : cs.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: SizedBox(
              height: minH,
              child: Stack(
                children: [
                  if (_isBasic)
                    Center(
                      child: Opacity(
                        opacity: 0.55,
                        child: Text(
                          preset.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cat.icon != null) ...[
                            Icon(cat.icon, color: cat.fg, size: 22.adaptSize),
                            SizedBox(width: 10.h),
                          ],
                          Expanded(
                            child: Opacity(
                              opacity: 0.9,
                              child: Text(
                                preset.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: cat.fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      preset.ratio,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _isBasic ? Colors.black87 : cat.fg,
                        fontWeight: _isBasic ? FontWeight.w700 : FontWeight.w800,
                      ),
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

