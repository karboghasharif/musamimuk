import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import 'print_open_orders_controller.dart';
import 'print_ui.dart';

/// Global bottom dock for open designer print orders.
///
/// Mounted from [MaterialApp.builder] (above the navigator Overlay), so this
/// widget must not rely on Overlay (no IconButton tooltips / menus).
class PrintOpenOrderHost extends StatelessWidget {
  const PrintOpenOrderHost({super.key, required this.child});

  final Widget child;

  static const _hideRoutes = <String>{
    AppRoutes.initialRoute,
    AppRoutes.screenTwentythreeScreen,
    AppRoutes.screen0LoginScreen,
    AppRoutes.screen0RegisterScreen,
    AppRoutes.forgotPasswordScreen,
    AppRoutes.printTrackingScreen,
    AppRoutes.printOrdersScreen,
    AppRoutes.printChatsScreen,
    AppRoutes.printChatScreen,
    AppRoutes.printShopHomeScreen,
    AppRoutes.printShopOrderDetailScreen,
    AppRoutes.printShopDashboardScreen,
    AppRoutes.printShopRegisterScreen,
    AppRoutes.printRiderHomeScreen,
    AppRoutes.printRiderRegisterScreen,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PrintOpenOrdersController.instance,
        AppRouteObserver.instance,
      ]),
      builder: (context, _) {
        final controller = PrintOpenOrdersController.instance;
        final route = AppRouteObserver.instance.currentRouteName;
        final hideForRoute = route != null && _hideRoutes.contains(route);
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final order = controller.primary;
        final show = controller.shouldShowDock &&
            !hideForRoute &&
            !keyboardOpen &&
            order != null;

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (show)
              Positioned(
                left: AppDs.space4.h,
                right: AppDs.space4.h,
                bottom: MediaQuery.paddingOf(context).bottom + AppDs.space3.v,
                child: controller.minimized
                    ? _MinimizedChip(
                        order: order,
                        extraCount: controller.extraCount,
                        onExpand: controller.expand,
                      )
                    : _OpenOrderDialog(
                        order: order,
                        extraCount: controller.extraCount,
                        onMinimize: controller.minimize,
                        onDismiss: controller.dismissPrimary,
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _MinimizedChip extends StatelessWidget {
  const _MinimizedChip({
    required this.order,
    required this.extraCount,
    required this.onExpand,
  });

  final PrintOrder order;
  final int extraCount;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppDs.atelierInk,
        elevation: 8,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        child: InkWell(
          onTap: onExpand,
          borderRadius: BorderRadius.circular(AppDs.radiusFull),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space4.h,
              vertical: AppDs.space2.v,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDs.radiusFull),
              border: Border.all(
                color: AppDs.atelierBrass.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.print_outlined,
                  color: AppDs.atelierBrass,
                  size: 18.adaptSize,
                ),
                SizedBox(width: AppDs.space2.h),
                Text(
                  '#${order.number}',
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.atelierBrass,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (extraCount > 0) ...[
                  SizedBox(width: AppDs.space2.h),
                  Text(
                    '+$extraCount',
                    style: AppTypography.caption(theme).copyWith(
                      color: AppDs.textOnDarkSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenOrderDialog extends StatelessWidget {
  const _OpenOrderDialog({
    required this.order,
    required this.extraCount,
    required this.onMinimize,
    required this.onDismiss,
  });

  final PrintOrder order;
  final int extraCount;
  final VoidCallback onMinimize;
  final VoidCallback onDismiss;

  String get _actionHint {
    if (order.status == 'awaiting_payment') return 'lbl_print_pay_now'.tr;
    if (order.status == 'quote') {
      final n = order.offeredQuotes.length;
      if (n > 0) {
        return 'msg_print_offers_count'.tr.replaceAll('{count}', '$n');
      }
      return 'msg_print_waiting_for_quotes'.tr;
    }
    if (order.status == 'ready') return 'lbl_print_status_ready'.tr;
    return 'lbl_print_view_order'.tr;
  }

  Future<void> _open() async {
    if (extraCount > 0) {
      await NavigatorService.pushNamed(AppRoutes.printOrdersScreen);
    } else {
      await NavigatorService.pushNamed(
        AppRoutes.printTrackingScreen,
        arguments: {'orderId': order.id},
      );
    }
    await PrintOpenOrdersController.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopName = order.shop?.name.trim() ?? '';
    final detail = [
      if (shopName.isNotEmpty) shopName,
      _actionHint,
      if (extraCount > 0)
        'msg_print_open_orders_more'.tr.replaceAll('{count}', '$extraCount'),
    ].join(' · ');
    final urgent = order.status == 'awaiting_payment' ||
        (order.status == 'quote' && order.offeredQuote != null);

    return Material(
      color: AppDs.surfaceRaised,
      elevation: 12,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(AppDs.radiusMd),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: AppDs.atelierBrass.withValues(alpha: 0.45),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            child: SizedBox(
              height: 64.v,
              child: Row(
                children: [
                  Container(width: 3.h, color: AppDs.atelierBrass),
                  SizedBox(width: AppDs.space3.h),
                  Text(
                    '#${order.number}',
                    style: AppTypography.body(theme).copyWith(
                      color: AppDs.atelierBrass,
                      fontWeight: FontWeight.w800,
                      fontSize: 18.fSize,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: AppDs.space2.h),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PrintStatusStamp(
                          label: 'lbl_print_status_${order.status}'.tr,
                          urgent: urgent,
                        ),
                        SizedBox(height: 2.v),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(theme).copyWith(
                            color: AppDs.textOnDarkSecondary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DockIcon(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: onMinimize,
                  ),
                  _DockIcon(
                    icon: Icons.close_rounded,
                    onTap: onDismiss,
                  ),
                  SizedBox(width: AppDs.space1.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDs.radiusFull),
      child: Padding(
        padding: EdgeInsets.all(6.adaptSize),
        child: Icon(
          icon,
          color: AppDs.textOnDarkSecondary,
          size: 20.adaptSize,
        ),
      ),
    );
  }
}
