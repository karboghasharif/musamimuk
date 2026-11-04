import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_live.dart';
import 'print_ui.dart';

/// Profile-scoped print chat (designer↔shop or shop↔rider) with optional files.
class PrintChatScreen extends StatefulWidget {
  const PrintChatScreen({
    super.key,
    this.conversationId,
    this.orderId,
    this.shopId,
    this.customerUserId,
    this.riderUserId,
    this.thread = 'customer_shop',
    this.viewer = 'customer',
  });

  final int? conversationId;
  final int? orderId;
  final int? shopId;
  final int? customerUserId;
  final int? riderUserId;
  final String thread;
  final String viewer;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    return PrintChatScreen(
      conversationId: _optionalInt(map['conversationId']),
      orderId: _optionalInt(map['orderId']),
      shopId: _optionalInt(map['shopId']),
      customerUserId: _optionalInt(map['customerUserId']),
      riderUserId: _optionalInt(map['riderUserId']),
      thread: map['thread']?.toString() ?? 'customer_shop',
      viewer: map['viewer']?.toString() ?? 'customer',
    );
  }

  static int? _optionalInt(dynamic value) {
    final parsed = apiParseInt(value);
    return parsed > 0 ? parsed : null;
  }

  @override
  State<PrintChatScreen> createState() => _PrintChatScreenState();
}

class _PrintChatScreenState extends State<PrintChatScreen> {
  final _repo = PrintRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  PrintConversation? _conversation;
  PrintOrder? _order;
  bool _loading = true;
  bool _busy = false;
  String? _pendingPath;
  String? _pendingName;
  Timer? _poll;
  VoidCallback? _stopLive;

  @override
  void initState() {
    super.initState();
    _bootstrap();
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

  Future<void> _bootstrap() async {
    if (widget.conversationId != null) {
      await _reload();
      return;
    }
    final opened = await _repo.openConversation(
      shopId: widget.shopId,
      customerUserId: widget.customerUserId,
      riderUserId: widget.riderUserId,
      orderId: widget.orderId,
      thread: widget.thread,
    );
    if (!mounted) return;
    if (opened is PrintFailure<PrintConversation>) {
      // Legacy fallback: open via order messages if conversation API is unavailable.
      if (widget.orderId != null) {
        final order = await _repo.order(widget.orderId!);
        if (!mounted) return;
        if (order is PrintSuccess<PrintOrder>) {
          setState(() {
            _order = order.data;
            _loading = false;
          });
          return;
        }
      }
      setState(() => _loading = false);
      showAppToast(opened.message, type: ToastificationType.error);
      return;
    }
    setState(() {
      _conversation = (opened as PrintSuccess<PrintConversation>).data;
      _loading = false;
    });
    _scrollToEnd();
    if (_conversation?.lastOrderId != null) {
      final order = await _repo.order(_conversation!.lastOrderId!);
      if (mounted && order is PrintSuccess<PrintOrder>) {
        setState(() => _order = order.data);
      }
    }
  }

  Future<void> _reload({bool scroll = true}) async {
    final id = _conversation?.id ?? widget.conversationId;
    if (id == null) {
      if (widget.orderId != null) {
        final order = await _repo.order(widget.orderId!);
        if (!mounted) return;
        if (order is PrintSuccess<PrintOrder>) {
          setState(() {
            _order = order.data;
            _loading = false;
          });
        }
      }
      return;
    }
    final result = await _repo.conversation(id);
    if (!mounted) return;
    if (result is PrintSuccess<PrintConversation>) {
      final prev = _conversation?.messages.length ?? 0;
      setState(() {
        _conversation = result.data;
        _loading = false;
      });
      if (scroll || result.data.messages.length != prev) {
        _scrollToEnd();
      }
    } else {
      setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  bool _isMine(PrintChatMessage message) {
    if (widget.viewer == 'shop') return message.from == 'printer';
    if (widget.viewer == 'rider') return message.from == 'rider';
    return message.from == 'customer';
  }

  String _sender(PrintChatMessage message) {
    if (_isMine(message)) return 'lbl_print_you'.tr;
    if (message.from == 'customer') {
      return _conversation?.peerName ??
          _order?.customerName ??
          'lbl_print_designer_chat'.tr;
    }
    if (message.from == 'rider') {
      return _conversation?.peerName ?? 'lbl_print_rider_chat'.tr;
    }
    if (message.from == 'printer') {
      return _conversation?.shopName ??
          _order?.shop?.name ??
          'lbl_print_shop_mode'.tr;
    }
    return 'lbl_print_update'.tr;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'webp',
        'gif',
        'doc',
        'docx',
      ],
      withData: false,
    );
    final file = result?.files.single;
    if (file == null || file.path == null) return;
    if ((file.size) > 5 * 1024 * 1024) {
      showAppToast('msg_print_chat_file_too_large'.tr, type: ToastificationType.error);
      return;
    }
    setState(() {
      _pendingPath = file.path;
      _pendingName = file.name;
    });
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if ((body.isEmpty && _pendingPath == null) || _busy) return;
    setState(() => _busy = true);

    final conversationId = _conversation?.id ?? widget.conversationId;
    if (conversationId != null) {
      final result = await _repo.sendConversationMessage(
        conversationId: conversationId,
        body: body.isEmpty ? null : body,
        orderId: widget.orderId ?? _conversation?.lastOrderId,
        attachmentPath: _pendingPath,
        attachmentName: _pendingName,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (result is PrintFailure<PrintConversation>) {
        showAppToast(result.message, type: ToastificationType.error);
        return;
      }
      _input.clear();
      setState(() {
        _conversation = (result as PrintSuccess<PrintConversation>).data;
        _pendingPath = null;
        _pendingName = null;
      });
      _scrollToEnd();
      return;
    }

    if (widget.orderId == null) {
      setState(() => _busy = false);
      showAppToast('msg_print_chat_unavailable'.tr, type: ToastificationType.error);
      return;
    }
    final legacy = await _repo.sendMessage(
      orderId: widget.orderId!,
      body: body.isEmpty ? null : body,
      thread: widget.thread,
      attachmentPath: _pendingPath,
      attachmentName: _pendingName,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (legacy is PrintFailure<PrintOrder>) {
      showAppToast(legacy.message, type: ToastificationType.error);
      return;
    }
    _input.clear();
    setState(() {
      _order = (legacy as PrintSuccess<PrintOrder>).data;
      _pendingPath = null;
      _pendingName = null;
    });
    _scrollToEnd();
  }

  Future<void> _openAttachment(PrintChatAttachment attachment) async {
    final url = attachment.url;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<PrintChatMessage> get _messages {
    if (_conversation != null) return _conversation!.messages;
    if (_order != null) {
      return _order!.messages
          .where((m) => m.thread == widget.thread && m.from != 'system')
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final title = _conversation?.peerName ??
        (_conversation?.shopName) ??
        (_order == null
            ? 'lbl_print_chat'.tr
            : (_conversation?.peerName ??
                (widget.viewer == 'shop'
                    ? (_order?.customerName ?? 'lbl_print_designer_chat'.tr)
                    : (_order?.shop?.name ?? 'lbl_print_chat'.tr))));
    final quoteReady = widget.viewer == 'customer' &&
        widget.thread == 'customer_shop' &&
        (_order?.offeredQuote != null ||
            (_conversation?.lastOrderId != null && _order?.offeredQuote != null));
    final orderId = widget.orderId ?? _conversation?.lastOrderId ?? _order?.id;

    return PrintScaffold(
      title: title,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (quoteReady && orderId != null)
                  Material(
                    color: AppDs.surfaceRaised,
                    child: InkWell(
                      onTap: () {
                        NavigatorService.pushNamed(
                          AppRoutes.printTrackingScreen,
                          arguments: {'orderId': orderId},
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
                if (_conversation?.lastOrderNumber != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${'lbl_print_latest_order'.tr} #${_conversation!.lastOrderNumber}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.all(16.h),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
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
                                  _sender(msg),
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.black54
                                        : AppDs.printGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (msg.body.trim().isNotEmpty) ...[
                                  SizedBox(height: 2.v),
                                  Text(
                                    msg.body,
                                    style: TextStyle(
                                      color: mine ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ],
                                if (msg.attachment != null) ...[
                                  SizedBox(height: 8.v),
                                  InkWell(
                                    onTap: () => _openAttachment(msg.attachment!),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.h,
                                        vertical: 8.v,
                                      ),
                                      decoration: BoxDecoration(
                                        color: mine
                                            ? Colors.black.withValues(alpha: 0.08)
                                            : Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            msg.attachment!.isImage
                                                ? Icons.image_outlined
                                                : Icons.attach_file,
                                            size: 18,
                                            color: mine
                                                ? Colors.black87
                                                : AppDs.printGold,
                                          ),
                                          SizedBox(width: 6.h),
                                          Flexible(
                                            child: Text(
                                              msg.attachment!.name ??
                                                  'lbl_print_attachment'.tr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: mine
                                                    ? Colors.black87
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_pendingName != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.h, 0, 16.h, 8.v),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: AppDs.printGold, size: 18),
                        SizedBox(width: 6.h),
                        Expanded(
                          child: Text(
                            _pendingName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _pendingPath = null;
                            _pendingName = null;
                          }),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.h, 0, 8.h, 16.v),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _busy ? null : _pickFile,
                        icon: const Icon(Icons.attach_file, color: AppDs.printGold),
                        tooltip: 'lbl_print_attach_file'.tr,
                      ),
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
                        onPressed: _busy ? null : _send,
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
