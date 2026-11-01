import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_open_orders_sync.dart';

/// Opens the normal design app, the print shop, or the print rider.
///
/// Shop and rider are device modes. They do not change role_id.
///
/// Prefer [NavigatorService.navigatorKey] context (e.g. after closing the
/// drawer) so dialogs are not tied to a disposed route.
Future<void> showPrintModeSheet(BuildContext context) async {
  final host = NavigatorService.navigatorKey.currentContext ?? context;
  if (!host.mounted) return;

  final current = PrefUtils().getWorkMode();
  var available = cachedAvailableWorkModes();
  // If cache only knows Design, refresh once so Rider/Shop can appear.
  // Otherwise open instantly and refresh in the background.
  if (available.length <= 1 &&
      PrefUtils().isLoggedIn() &&
      !PrefUtils().isGuestAccount()) {
    await refreshPrintProfileModeCache();
    available = cachedAvailableWorkModes();
  } else {
    unawaited(refreshPrintProfileModeCache());
  }

  if (!host.mounted) return;
  final selected = await showWorkModePicker(
    host,
    available: available,
    current: current,
    title: 'lbl_switch_mode'.tr,
  );

  if (selected == null || selected == current) return;
  await applyWorkMode(selected);
}

/// Modes from local prefs only (no network). Always includes Design.
Set<String> cachedAvailableWorkModes() {
  final prefs = PrefUtils();
  final modes = <String>{PrefUtils.workModeNormal};
  if (prefs.isGuestAccount() || !prefs.isLoggedIn()) {
    return modes;
  }
  if (prefs.hasPrintShopProfile()) modes.add(PrefUtils.workModeShop);
  if (prefs.hasPrintRiderProfile()) modes.add(PrefUtils.workModeRider);
  final current = prefs.getWorkMode();
  if (current == PrefUtils.workModeShop) modes.add(PrefUtils.workModeShop);
  if (current == PrefUtils.workModeRider) modes.add(PrefUtils.workModeRider);
  return modes;
}

/// Best-effort refresh of shop/rider ownership flags (does not block UI).
Future<void> refreshPrintProfileModeCache({
  PrintRepository? repository,
}) async {
  final prefs = PrefUtils();
  if (prefs.isGuestAccount() || !prefs.isLoggedIn()) return;

  final repo = repository ?? PrintRepository();
  try {
    final results = await Future.wait<Object>([
      repo.myShop(),
      repo.myRider(),
    ]).timeout(const Duration(seconds: 8));

    final shop = results[0];
    if (shop is PrintSuccess<PrintShopSummary?>) {
      final hasShop = shop.data != null && shop.data!.id > 0;
      await prefs.setHasPrintShopProfile(hasShop);
    }

    final rider = results[1];
    if (rider is PrintSuccess<PrintRiderProfile?>) {
      final hasRider = rider.data != null && rider.data!.id > 0;
      await prefs.setHasPrintRiderProfile(hasRider);
    }
  } on TimeoutException {
    // Keep existing cache.
  } catch (_) {
    // Keep existing cache.
  }
}

/// Modes the signed-in user can open (cache + live `/me` refresh).
///
/// Used after login. The in-app switcher uses [cachedAvailableWorkModes]
/// so it never hangs on a slow network.
Future<Set<String>> resolveAvailableWorkModes({
  PrintRepository? repository,
}) async {
  await refreshPrintProfileModeCache(repository: repository);
  return cachedAvailableWorkModes();
}

/// Dialog / sheet to pick Design, Shop, or Rider (only listed [available] modes).
Future<String?> showWorkModePicker(
  BuildContext context, {
  required Set<String> available,
  String? current,
  String? title,
  String? subtitle,
}) {
  final ordered = <String>[
    PrefUtils.workModeNormal,
    PrefUtils.workModeShop,
    PrefUtils.workModeRider,
  ].where(available.contains).toList(growable: false);

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title ?? 'lbl_choose_work_mode'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subtitle ?? 'msg_choose_work_mode'.tr,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            SizedBox(height: 12.v),
            for (final mode in ordered)
              _ModeChoiceTile(
                mode: mode,
                selected: mode == current,
                onTap: () => Navigator.pop(dialogContext, mode),
              ),
          ],
        ),
      );
    },
  );
}

class _ModeChoiceTile extends StatelessWidget {
  const _ModeChoiceTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (mode) {
      PrefUtils.workModeShop => (
          'lbl_mode_shop'.tr,
          Icons.storefront_outlined,
        ),
      PrefUtils.workModeRider => (
          'lbl_mode_rider'.tr,
          Icons.two_wheeler_outlined,
        ),
      _ => ('lbl_mode_normal'.tr, Icons.design_services_outlined),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 8.v),
      child: Material(
        color: selected
            ? AppDs.printGold.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 14.v),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppDs.printGold : Colors.white70,
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppDs.printGold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> applyWorkMode(String mode) async {
  final prefs = PrefUtils();
  // Remember print profiles when leaving or entering them so the switcher
  // still lists Shop/Rider if `/me` is temporarily unreachable.
  final previous = prefs.getWorkMode();
  if (previous == PrefUtils.workModeShop || mode == PrefUtils.workModeShop) {
    await prefs.setHasPrintShopProfile(true);
  }
  if (previous == PrefUtils.workModeRider || mode == PrefUtils.workModeRider) {
    await prefs.setHasPrintRiderProfile(true);
  }
  await prefs.setWorkMode(mode);
  syncPrintOpenOrdersAfterWorkMode();
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
