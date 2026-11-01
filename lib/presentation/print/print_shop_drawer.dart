import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import 'print_mode_switch.dart';

/// Atelier side rail for print-shop mode (not the designer drawer chrome).
class PrintShopDrawer extends StatelessWidget {
  const PrintShopDrawer({
    super.key,
    required this.shopName,
    required this.section,
    required this.onSelectSection,
    this.quoteCount = 0,
  });

  final String shopName;
  final int section;
  final ValueChanged<int> onSelectSection;
  final int quoteCount;

  void _go(BuildContext context, int index) {
    Navigator.pop(context);
    onSelectSection(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: AppDs.atelierInk,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space5.h,
                AppDs.space5.v,
                AppDs.space5.h,
                AppDs.space4.v,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.adaptSize,
                    height: 48.adaptSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppDs.atelierBrass.withValues(alpha: 0.14),
                      border: Border.all(
                        color: AppDs.atelierBrass.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Icon(
                      Icons.print_outlined,
                      color: AppDs.atelierBrass,
                      size: 22.adaptSize,
                    ),
                  ),
                  SizedBox(height: AppDs.space3.v),
                  Text(
                    shopName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(theme).copyWith(
                      color: AppDs.textOnDarkPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20.fSize,
                    ),
                  ),
                  SizedBox(height: AppDs.space1.v),
                  Text(
                    'lbl_print_shop_mode'.tr,
                    style: AppTypography.caption(theme).copyWith(
                      color: AppDs.atelierBrass,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: AppDs.space5.h),
              color: AppDs.atelierHairline(0.14),
            ),
            SizedBox(height: AppDs.space2.v),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: AppDs.space2.v),
                children: [
                  _item(
                    context,
                    index: 0,
                    icon: Icons.storefront_outlined,
                    label: 'lbl_home'.tr,
                  ),
                  _item(
                    context,
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    label: 'lbl_print_shop_orders'.tr,
                    badge: quoteCount > 0 ? '$quoteCount' : null,
                  ),
                  _item(
                    context,
                    index: 2,
                    icon: Icons.forum_outlined,
                    label: 'lbl_print_conversations'.tr,
                  ),
                  _item(
                    context,
                    index: 3,
                    icon: Icons.payments_outlined,
                    label: 'lbl_print_earnings'.tr,
                  ),
                  _item(
                    context,
                    index: 4,
                    icon: Icons.badge_outlined,
                    label: 'lbl_print_profile'.tr,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDs.space5.h,
                      vertical: AppDs.space2.v,
                    ),
                    child: Container(height: 1, color: AppDs.atelierHairline(0.1)),
                  ),
                  _tile(
                    context,
                    icon: Icons.campaign_outlined,
                    label: 'lbl_print_notices'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      NavigatorService.pushNamed(AppRoutes.printNoticesScreen);
                    },
                  ),
                  _tile(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    label: 'lbl_switch_mode'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      showPrintModeSheet(context);
                    },
                  ),
                  _tile(
                    context,
                    icon: Icons.design_services_outlined,
                    label: 'lbl_print_exit_to_designer'.tr,
                    onTap: () async {
                      Navigator.pop(context);
                      await applyWorkMode(PrefUtils.workModeNormal);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    return _tile(
      context,
      icon: icon,
      label: label,
      selected: section == index,
      badge: badge,
      onTap: () => _go(context, index),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final color = selected ? AppDs.atelierBrass : AppDs.textOnDarkPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppDs.space3.h,
            vertical: 2.v,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space3.h,
            vertical: AppDs.space3.v,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppDs.atelierBrass.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: selected
                  ? AppDs.atelierBrass.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22.adaptSize),
              SizedBox(width: AppDs.space3.h),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(theme).copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.h,
                    vertical: 2.v,
                  ),
                  decoration: BoxDecoration(
                    color: AppDs.atelierBrass,
                    borderRadius: BorderRadius.circular(AppDs.radiusFull),
                  ),
                  child: Text(
                    badge,
                    style: AppTypography.caption(theme).copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
