import 'package:flutter/material.dart';

import '../../core/app_export.dart';

/// Opens the normal design app, the print shop, or the print rider.
///
/// Shop and rider are device modes. They do not change role_id.
Future<void> showPrintModeSheet(BuildContext context) async {
  final current = PrefUtils().getWorkMode();
  final canSwitchWork = !PrefUtils().isGuestAccount() && PrefUtils().isLoggedIn();

  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1E2128),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      Widget tile(String mode, String label, IconData icon) {
        final active = current == mode;
        return ListTile(
          leading: Icon(icon, color: active ? AppDs.printGold : Colors.white70),
          title: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: active
              ? const Icon(Icons.check, color: AppDs.printGold)
              : null,
          onTap: () => Navigator.pop(sheetContext, mode),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.v),
            Text(
              'lbl_switch_mode'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            tile(PrefUtils.workModeNormal, 'lbl_mode_normal'.tr, Icons.home_outlined),
            if (canSwitchWork)
              tile(PrefUtils.workModeShop, 'lbl_mode_shop'.tr, Icons.storefront_outlined),
            if (canSwitchWork)
              tile(PrefUtils.workModeRider, 'lbl_mode_rider'.tr, Icons.two_wheeler_outlined),
            SizedBox(height: 8.v),
          ],
        ),
      );
    },
  );

  if (selected == null || selected == current) return;
  await applyWorkMode(selected);
}

Future<void> applyWorkMode(String mode) async {
  await PrefUtils().setWorkMode(mode);
  final route = switch (mode) {
    PrefUtils.workModeShop => AppRoutes.printShopHomeScreen,
    PrefUtils.workModeRider => AppRoutes.printRiderHomeScreen,
    _ => AppRoutes.screen1HomeScreen,
  };
  await NavigatorService.pushNamedAndRemoveUntil(route);
}

class PrintModeButton extends StatelessWidget {
  const PrintModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'lbl_switch_mode'.tr,
      onPressed: () => showPrintModeSheet(context),
      icon: const Icon(Icons.swap_horiz, color: AppDs.printGold),
    );
  }
}
