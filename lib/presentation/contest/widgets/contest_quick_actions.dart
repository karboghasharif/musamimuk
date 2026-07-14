import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ContestQuickAction {
  const ContestQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
}

class ContestQuickActions extends StatelessWidget {
  const ContestQuickActions({super.key, required this.actions});

  final List<ContestQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: AppDs.space2.h),
            _QuickActionChip(action: actions[i]),
          ],
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.action});

  final ContestQuickAction action;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final bg = action.primary
        ? cs.primary.withValues(alpha: 0.15)
        : AppDs.surfaceElevated;
    final borderColor = action.primary
        ? cs.primary.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.1);
    final iconColor = action.primary ? cs.primary : AppDs.textOnDarkSecondary;
    final textStyle = action.primary
        ? AppTypography.navActive(theme)
        : AppTypography.navInactive(theme);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
        child: Container(
          constraints: BoxConstraints(minHeight: AppDs.minTap.v),
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4.h,
            vertical: AppDs.space2.v,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 18.adaptSize, color: iconColor),
              SizedBox(width: AppDs.space2.h),
              Text(action.label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
