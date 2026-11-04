import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

/// Profile-wise conversation inbox (one thread per peer, not per order).
class PrintChatsScreen extends StatefulWidget {
  const PrintChatsScreen({super.key, this.viewer = 'customer'});

  final String viewer;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final viewer = args is Map ? args['viewer']?.toString() : null;
    return PrintChatsScreen(
      viewer: (viewer == 'shop' || viewer == 'rider') ? viewer! : 'customer',
    );
  }

  @override
  State<PrintChatsScreen> createState() => _PrintChatsScreenState();
}

class _PrintChatsScreenState extends State<PrintChatsScreen> {
  final _repo = PrintRepository();
  List<PrintConversation> _rows = const [];
  bool _loading = true;
  String? _error;

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
    final result = await _repo.conversations();
    if (!mounted) return;
    if (result is PrintFailure<List<PrintConversation>>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    var rows = (result as PrintSuccess<List<PrintConversation>>).data;
    if (widget.viewer == 'customer') {
      rows = rows.where((c) => c.kind == 'customer_shop').toList();
    } else if (widget.viewer == 'rider') {
      rows = rows.where((c) => c.kind == 'shop_rider').toList();
    }
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  void _openChat(PrintConversation conversation) {
    NavigatorService.pushNamed(
      AppRoutes.printChatScreen,
      arguments: {
        'conversationId': conversation.id,
        'viewer': widget.viewer,
        'thread': conversation.kind,
        if (conversation.lastOrderId != null) 'orderId': conversation.lastOrderId,
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
                  : _rows.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 120.v),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.h),
                                child: Text(
                                  widget.viewer == 'shop'
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
                          itemCount: _rows.length,
                          separatorBuilder: (_, _) => SizedBox(height: 8.v),
                          itemBuilder: (context, index) {
                            final conversation = _rows[index];
                            return PrintConversationSlip(
                              title: conversation.peerName ??
                                  conversation.shopName ??
                                  'lbl_print_chat'.tr,
                              preview: conversation.lastBody,
                              subtitle: conversation.kind == 'shop_rider'
                                  ? 'lbl_print_rider_chat'.tr
                                  : 'lbl_print_designer_chat'.tr,
                              badge: conversation.lastOrderNumber != null
                                  ? '#${conversation.lastOrderNumber}'
                                  : null,
                              onTap: () => _openChat(conversation),
                            );
                          },
                        ),
            ),
    );
  }
}
