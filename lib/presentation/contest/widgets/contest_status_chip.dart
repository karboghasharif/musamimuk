import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ContestStatusChip extends StatelessWidget {
  const ContestStatusChip({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final s = status?.trim();
    if (s == null || s.isEmpty) return const SizedBox.shrink();
    final color = switch (s.toLowerCase()) {
      'active' => appTheme.green500,
      'upcoming' => appTheme.yellow500,
      'ended' || 'completed' => appTheme.redA400,
      _ => theme.colorScheme.primary,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space3.h,
        vertical: AppDs.space1.v,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        s[0].toUpperCase() + s.substring(1),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: AppDs.fontSecondary.fSize,
        ),
      ),
    );
  }
}
