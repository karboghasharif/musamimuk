import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_live.dart';
import 'print_ui.dart';

/// Individual print chat thread (customer↔shop or shop↔rider).
/// Quote accept / decline / pay live on the order (tracking) screen — not here.
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
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _reload(scroll: false));
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
      final next =
          result.data.messages.where((m) => m.thread == widget.thread).length;
      final prev =
          _order?.messages.where((m) => m.thread == widget.thread).length ?? 0;
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
    if (message.from == 'customer') {
      return order.customerName ?? 'lbl_print_designer_chat'.tr;
    }
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

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final quoteReady = widget.viewer == 'customer' &&
        widget.thread == 'customer_shop' &&
        order?.offeredQuote != null;
    return PrintScaffold(
      title: order == null
          ? 'lbl_print_chat'.tr
          : '#${order.number} · ${widget.viewer == 'shop' ? (order.customerName ?? 'lbl_print_designer_chat'.tr) : 'lbl_print_chat'.tr}',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (quoteReady)
                  Material(
                    color: AppDs.surfaceRaised,
                    child: InkWell(
                      onTap: () {
                        NavigatorService.pushNamed(
                          AppRoutes.printTrackingScreen,
                          arguments: {'orderId': widget.orderId},
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.h,
                          vertical: 12.v,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.request_quote_outlined,
                              color: AppDs.printGold,
                            ),
                            SizedBox(width: 10.h),
                            Expanded(
                              child: Text(
                                'msg_print_quote_on_order'.tr,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            Text(
                              'lbl_print_view_order'.tr,
                              style: const TextStyle(
                                color: AppDs.printGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      final mine = _isMine(msg);
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8.v),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.h,
                              vertical: 10.v,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  mine ? AppDs.printGold : AppDs.surfaceRaised,
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
                                    color: mine
                                        ? Colors.black54
                                        : AppDs.printGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.v),
                                Text(
                                  msg.body,
                                  style: TextStyle(
                                    color: mine ? Colors.black : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
