import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import '../../data/services/stripe/print_stripe_service.dart';
import 'print_live.dart';
import 'print_ui.dart';

class PrintChatScreen extends StatefulWidget {
  const PrintChatScreen({
    super.key,
    required this.orderId,
    this.thread = 'customer_shop',
    this.viewer = 'customer',
  });

  final int orderId;
  final String thread;
  final String viewer;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    return PrintChatScreen(
      orderId: apiParseInt(map['orderId']),
      thread: map['thread']?.toString() ?? 'customer_shop',
      viewer: map['viewer']?.toString() ?? 'customer',
    );
  }

  @override
  State<PrintChatScreen> createState() => _PrintChatScreenState();
}

class _PrintChatScreenState extends State<PrintChatScreen> {
  final _repo = PrintRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  PrintOrder? _order;
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;
  VoidCallback? _stopLive;

  @override
  void initState() {
    super.initState();
    _reload();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _reload(scroll: false));
    _stopLive = PrintLive.instance.listen(() => _reload(scroll: false));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopLive?.call();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload({bool scroll = true}) async {
    final result = await _repo.order(widget.orderId);
    if (!mounted) return;
    if (result is PrintSuccess<PrintOrder>) {
      final next = result.data.messages.where((m) => m.thread == widget.thread).length;
      final prev = _order?.messages.where((m) => m.thread == widget.thread).length ?? 0;
      setState(() {
        _order = result.data;
        _loading = false;
      });
      if (scroll || next != prev) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    } else {
      setState(() => _loading = false);
    }
  }

  bool _isMine(PrintChatMessage message) {
    if (widget.viewer == 'shop') return message.from == 'printer';
    if (widget.viewer == 'rider') return message.from == 'rider';
    return message.from == 'customer';
  }

  String _sender(PrintChatMessage message, PrintOrder order) {
    if (_isMine(message)) return 'lbl_print_you'.tr;
    if (message.from == 'customer') return order.customerName ?? 'lbl_print_designer_chat'.tr;
    if (message.from == 'rider') return 'lbl_print_rider_chat'.tr;
    if (message.from == 'printer') return 'lbl_print_shop_mode'.tr;
    return 'lbl_print_update'.tr;
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    final result = await _repo.sendMessage(
      orderId: widget.orderId,
      body: body,
      thread: widget.thread,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    _input.clear();
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
  }

  Future<void> _accept(PrintQuote quote) async {
    setState(() => _busy = true);
    final result = await _repo.acceptQuote(
      orderId: widget.orderId,
      quoteId: quote.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
    await _showPaySheet();
  }

  Future<void> _decline(PrintQuote quote) async {
    setState(() => _busy = true);
    final result = await _repo.declineQuote(
      orderId: widget.orderId,
      quoteId: quote.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
  }

  Future<void> _showPaySheet() async {
    final order = _order;
    if (order == null) return;
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
                for (final method in ['mada', 'visa', 'applepay'])
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.v),
                    child: PrintGoldButton(
                      label: 'lbl_print_pay_$method'.tr,
                      onPressed: () => Navigator.pop(ctx, method),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (method == null || !mounted) return;
    setState(() => _busy = true);
    final paid = await _repo.pay(orderId: order.id, method: method);
    if (!mounted) return;
    if (paid is PrintFailure<PrintPaySession>) {
      setState(() => _busy = false);
      showAppToast(paid.message, type: ToastificationType.error);
      return;
    }
    final session = (paid as PrintSuccess<PrintPaySession>).data;
    var orderPaid = session.order;
    final stripe = session.stripe;
    try {
      if (stripe != null && stripe.needsClientPayment) {
        final completed =
            await PrintStripeService.instance.presentPaymentSheet(stripe);
        if (!completed) {
          if (mounted) setState(() => _busy = false);
          return;
        }
        final intentId = stripe.paymentIntentId;
        if (intentId == null || intentId.isEmpty) {
          if (mounted) setState(() => _busy = false);
          showAppToast('msg_print_pay_failed'.tr, type: ToastificationType.error);
          return;
        }
        final confirmed = await _repo.confirmPay(
          orderId: order.id,
          paymentIntentId: intentId,
        );
        if (!mounted) return;
        if (confirmed is PrintFailure<PrintOrder>) {
          setState(() => _busy = false);
          showAppToast(confirmed.message, type: ToastificationType.error);
          return;
        }
        orderPaid = (confirmed as PrintSuccess<PrintOrder>).data;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showAppToast(
          e.toString().replaceFirst('Exception: ', ''),
          type: ToastificationType.error,
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _order = orderPaid;
    });
    NavigatorService.pushNamed(
      AppRoutes.printTrackingScreen,
      arguments: {'orderId': order.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final quote = order?.offeredQuote;
    return PrintScaffold(
      title: order == null
          ? 'lbl_print_chat'.tr
          : '#${order.number} · ${widget.viewer == 'shop' ? (order.customerName ?? 'lbl_print_designer_chat'.tr) : 'lbl_print_chat'.tr}',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.all(16.h),
                    itemCount: order?.messages
                            .where((m) => m.thread == widget.thread)
                            .length ??
                        0,
                    itemBuilder: (context, index) {
                      final msg = order!.messages
                          .where((m) => m.thread == widget.thread)
                          .elementAt(index);
                      if (msg.from == 'system') {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.v),
                          child: Text(
                            msg.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        );
                      }
                      final mine = _isMine(msg);
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8.v),
                            padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.v),
                            decoration: BoxDecoration(
                              color: mine ? AppDs.printGold : AppDs.surfaceRaised,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(mine ? 16 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sender(msg, order),
                                  style: TextStyle(
                                    color: mine ? Colors.black54 : AppDs.printGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.v),
                                Text(
                                  msg.body,
                                  style: TextStyle(color: mine ? Colors.black : Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (quote != null &&
                    quote.status == 'offered' &&
                    widget.thread == 'customer_shop')
                  Container(
                    width: double.infinity,
                    color: AppDs.surfaceRaised,
                    padding: EdgeInsets.all(16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        if (widget.viewer == 'customer') ...[
                          SizedBox(height: 8.v),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy ? null : () => _decline(quote),
                                  child: Text('lbl_print_decline'.tr),
                                ),
                              ),
                              SizedBox(width: 8.h),
                              Expanded(
                                child: PrintGoldButton(
                                  label: 'lbl_print_accept'.tr,
                                  loading: _busy,
                                  onPressed: () => _accept(quote),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                if (order?.status == 'awaiting_payment')
                  Padding(
                    padding: EdgeInsets.all(16.h),
                    child: PrintGoldButton(
                      label: 'lbl_print_pay_now'.tr,
                      onPressed: _showPaySheet,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.h, 0, 16.h, 16.v),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          onSubmitted: (_) => _send(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'lbl_print_message_hint'.tr,
                            hintStyle: const TextStyle(
                              color: AppDs.textOnDarkSecondary,
                            ),
                            filled: true,
                            fillColor: AppDs.surfaceRaised,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send, color: AppDs.printGold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
