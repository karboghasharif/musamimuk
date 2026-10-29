import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import '../../data/services/stripe/print_stripe_service.dart';
import 'print_ui.dart';

/// Shared designer order actions (accept / decline / pay / cancel).
/// Kept out of chat so messaging stays text-only.
class PrintOrderActions {
  PrintOrderActions._();

  static Future<PrintOrder?> acceptQuote({
    required BuildContext context,
    required PrintRepository repo,
    required PrintOrder order,
    required PrintQuote quote,
  }) async {
    final result = await repo.acceptQuote(
      orderId: order.id,
      quoteId: quote.id,
    );
    if (!context.mounted) return null;
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return null;
    }
    return (result as PrintSuccess<PrintOrder>).data;
  }

  static Future<PrintOrder?> declineQuote({
    required BuildContext context,
    required PrintRepository repo,
    required PrintOrder order,
    required PrintQuote quote,
  }) async {
    final result = await repo.declineQuote(
      orderId: order.id,
      quoteId: quote.id,
    );
    if (!context.mounted) return null;
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return null;
    }
    return (result as PrintSuccess<PrintOrder>).data;
  }

  static Future<PrintOrder?> cancelOrder({
    required BuildContext context,
    required PrintRepository repo,
    required PrintOrder order,
  }) async {
    if (!order.canCancel) return null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDs.surfaceRaised,
        title: Text(
          'lbl_print_cancel_order'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'msg_print_cancel_confirm'.tr,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('lbl_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'lbl_print_cancel_order'.tr,
              style: const TextStyle(color: AppDs.printGold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return null;
    final result = await repo.cancelOrder(order.id);
    if (!context.mounted) return null;
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return null;
    }
    final cancelled = (result as PrintSuccess<PrintOrder>).data;
    final paymentStatus = cancelled.payment?.status;
    showAppToast(
      paymentStatus == 'refund_pending' || paymentStatus == 'refunded'
          ? 'msg_print_refund_pending'.tr
          : 'msg_print_cancel_ok'.tr,
      type: ToastificationType.success,
    );
    return cancelled;
  }

  static Future<PrintOrder?> pay({
    required BuildContext context,
    required PrintRepository repo,
    required PrintOrder order,
  }) async {
    final method = await showAppModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AppDarkSheetTheme(
          child: AppSheetPagePadding(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_print_protected_pay'.tr,
                  style: AppDs.sheetTitle(theme, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.v),
                Text(
                  'msg_print_payment_protected'.tr,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.v),
                for (final payMethod in ['mada', 'visa', 'applepay'])
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.v),
                    child: PrintGoldButton(
                      label: 'lbl_print_pay_$payMethod'.tr,
                      onPressed: () => Navigator.pop(ctx, payMethod),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (method == null || !context.mounted) return null;

    final paid = await repo.pay(orderId: order.id, method: method);
    if (!context.mounted) return null;
    if (paid is PrintFailure<PrintPaySession>) {
      showAppToast(paid.message, type: ToastificationType.error);
      return null;
    }
    final session = (paid as PrintSuccess<PrintPaySession>).data;
    var orderPaid = session.order;
    final stripe = session.stripe;
    try {
      if (stripe != null && stripe.needsClientPayment) {
        final completed =
            await PrintStripeService.instance.presentPaymentSheet(stripe);
        if (!completed || !context.mounted) return null;
        final intentId = stripe.paymentIntentId;
        if (intentId == null || intentId.isEmpty) {
          showAppToast('msg_print_pay_failed'.tr, type: ToastificationType.error);
          return null;
        }
        final confirmed = await repo.confirmPay(
          orderId: order.id,
          paymentIntentId: intentId,
        );
        if (!context.mounted) return null;
        if (confirmed is PrintFailure<PrintOrder>) {
          showAppToast(confirmed.message, type: ToastificationType.error);
          return null;
        }
        orderPaid = (confirmed as PrintSuccess<PrintOrder>).data;
      }
    } catch (e) {
      if (context.mounted) {
        showAppToast(
          e.toString().replaceFirst('Exception: ', ''),
          type: ToastificationType.error,
        );
      }
      return null;
    }
    return orderPaid;
  }
}

/// Quote accept / decline + pay controls for the designer order screen.
class PrintQuoteDecisionCard extends StatelessWidget {
  const PrintQuoteDecisionCard({
    super.key,
    required this.order,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final PrintOrder order;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final quote = order.offeredQuote;
    if (quote == null || quote.status != 'offered') {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDs.printGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_print_send_quote'.tr,
            style: const TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.v),
          Text(
            '${'lbl_print_system_price'.tr}: ${printSar(quote.total)}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '${'lbl_print_shop_price'.tr}: ${printSar(quote.shopTotal ?? quote.total)} · ${quote.etaHours}h',
            style: const TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (quote.note != null && quote.note!.trim().isNotEmpty) ...[
            SizedBox(height: 6.v),
            Text(
              quote.note!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          SizedBox(height: 12.v),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  child: Text('lbl_print_decline'.tr),
                ),
              ),
              SizedBox(width: 8.h),
              Expanded(
                child: PrintGoldButton(
                  label: 'lbl_print_accept'.tr,
                  loading: busy,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
