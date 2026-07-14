import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import 'contest_section_card.dart';

class ContestStatItem {
  const ContestStatItem({
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;
}

class ContestStatsGrid extends StatelessWidget {
  const ContestStatsGrid({
    super.key,
    required this.items,
    this.title,
  });

  final List<ContestStatItem> items;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ContestSectionCard(
      title: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossCount = 2;
          final spacing = AppDs.space3.h;
          final tileWidth =
              (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
          const minTileHeight = 76.0;

          return Wrap(
            spacing: spacing,
            runSpacing: AppDs.space3.v,
            children: items.map((item) {
              return SizedBox(
                width: tileWidth,
                child: _StatTile(
                  item: item,
                  minHeight: minTileHeight.v,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.item,
    required this.minHeight,
  });

  final ContestStatItem item;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space2.h,
          vertical: AppDs.space2.v,
        ),
        decoration: BoxDecoration(
          color: AppDs.surfaceElevated.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: AppDs.iconSm.adaptSize,
                    color: AppDs.textAccent(theme.colorScheme),
                  ),
                  SizedBox(width: AppDs.space1.h),
                ],
                Flexible(
                  child: Text(
                    item.value,
                    style: AppTypography.statValue(theme),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDs.space1.v),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.statLabel(theme),
            ),
          ],
        ),
      ),
    );
  }
}
