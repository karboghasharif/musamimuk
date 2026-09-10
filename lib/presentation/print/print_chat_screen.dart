import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

class PrintChatScreen extends StatefulWidget {
  const PrintChatScreen({super.key, required this.orderId});

  final int orderId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    return PrintChatScreen(orderId: apiParseInt(map['orderId']));
  }

  @override
  State<PrintChatScreen> createState() => _PrintChatScreenState();
}

class _PrintChatScreenState extends State<PrintChatScreen> {
  final _repo = PrintRepository();
  final _input = TextEditingController();
  PrintOrder? _order;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final result = await _repo.order(widget.orderId);
    if (!mounted) return;
    if (result is PrintSuccess<PrintOrder>) {
      setState(() {
        _order = result.data;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    final result = await _repo.sendMessage(orderId: widget.orderId, body: body);
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
    setState(() => _busy = false);
    if (paid is PrintFailure<PrintOrder>) {
      showAppToast(paid.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (paid as PrintSuccess<PrintOrder>).data);
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
      title: 'lbl_print_chat'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.h),
                    itemCount: order?.messages.length ?? 0,
                    itemBuilder: (context, index) {
                      final msg = order!.messages[index];
                      final mine = msg.from == 'customer';
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.v),
                          padding: EdgeInsets.all(12.h),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppDs.printGold
                                : AppDs.surfaceRaised,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg.body,
                            style: TextStyle(
                              color: mine ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (quote != null && quote.status == 'offered')
                  Container(
                    width: double.infinity,
                    color: AppDs.surfaceRaised,
                    padding: EdgeInsets.all(16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${printSar(quote.total)} · ${quote.etaHours}h',
                          style: const TextStyle(
                            color: AppDs.printGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${'lbl_print_subtotal'.tr}: ${printSar(quote.subtotal)} · ${'lbl_print_finishing'.tr}: ${printSar(quote.finishingTotal)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 8.v),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : _reload,
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
