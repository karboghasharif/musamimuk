import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/category_item.dart';

class ContestCategoryChips extends StatelessWidget {
  const ContestCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<CategoryItem> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40.v,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'lbl_all'.tr,
            selected: selectedCategoryId == null,
            onTap: () => onSelected(null),
          ),
          ...categories.map(
            (c) => _chip(
              label: c.name,
              selected: selectedCategoryId == c.id,
              onTap: () => onSelected(c.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: AppDs.space2.h),
      child: FilterChip(
        label: Text(
          label,
          style: selected
              ? AppTypography.navActive(theme)
              : AppTypography.navInactive(theme),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        checkmarkColor: AppDs.textOnDarkPrimary,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
