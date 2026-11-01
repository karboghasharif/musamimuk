import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

/// Conversation inbox for designer (customer) or shop viewer.
class PrintChatsScreen extends StatefulWidget {
  const PrintChatsScreen({super.key, this.viewer = 'customer'});

  /// `customer` loads myOrders; `shop` loads shopOrders.
  final String viewer;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final viewer = args is Map ? args['viewer']?.toString() : null;
    return PrintChatsScreen(
      viewer: (viewer == 'shop') ? 'shop' : 'customer',
    );
  }

  @override
  State<PrintChatsScreen> createState() => _PrintChatsScreenState();
}

class _PrintChatsScreenState extends State<PrintChatsScreen> {
  final _repo = PrintRepository();
  List<PrintOrder> _orders = const [];
  bool _loading = true;
  String? _error;

  bool get _isShop => widget.viewer == 'shop';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = _isShop ? await _repo.shopOrders() : await _repo.myOrders();
    if (!mounted) return;
    if (result is PrintFailure<List<PrintOrder>>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    final orders = (result as PrintSuccess<List<PrintOrder>>).data;
    final active = orders
        .where((o) => o.status != 'cancelled')
        .toList(growable: true);
    active.sort((a, b) {
      final aMs = a.messages.isEmpty ? 0 : a.messages.last.id;
      final bMs = b.messages.isEmpty ? 0 : b.messages.last.id;
      return bMs.compareTo(aMs);
    });
    setState(() {
      _orders = active;
      _loading = false;
    });
  }

  void _openChat(PrintOrder order) {
    NavigatorService.pushNamed(
      AppRoutes.printChatScreen,
      arguments: {
        'orderId': order.id,
        'viewer': _isShop ? 'shop' : 'customer',
        'thread': 'customer_shop',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: 'lbl_print_conversations'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      children: [
                        SizedBox(height: 120.v),
                        Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : _orders.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 120.v),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.h),
                                child: Text(
                                  _isShop
                                      ? 'msg_print_shop_chats_empty'.tr
                                      : 'msg_print_no_chats'.tr,
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(16.h),
                          itemCount: _orders.length,
                          separatorBuilder: (_, _) => SizedBox(height: 8.v),
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return PrintConversationSlip(
                              order: order,
                              peerName: _isShop
                                  ? order.customerName
                                  : order.shop?.name,
                              threadLabel: _isShop
                                  ? 'lbl_print_designer_chat'.tr
                                  : 'lbl_print_message_shop'.tr,
                              onTap: () => _openChat(order),
                            );
                          },
                        ),
            ),
    );
  }
}
