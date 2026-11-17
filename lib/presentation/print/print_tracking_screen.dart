import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_dispute_sheet.dart';
import 'print_live.dart';
import 'print_location_picker.dart';
import 'print_order_actions.dart';
import 'print_review_sheet.dart';
import 'print_ui.dart';

class PrintTrackingScreen extends StatefulWidget {
  const PrintTrackingScreen({super.key, required this.orderId});

  final int orderId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    return PrintTrackingScreen(orderId: apiParseInt(map['orderId']));
  }

  @override
  State<PrintTrackingScreen> createState() => _PrintTrackingScreenState();
}

class _PrintTrackingScreenState extends State<PrintTrackingScreen> {
  final _repo = PrintRepository();
  final _address = TextEditingController();
  final _dropLat = TextEditingController();
  final _dropLng = TextEditingController();
  final _otp = TextEditingController();
  PrintOrder? _order;
  PrintDeliveryQuote? _preview;
  String? _otpOnce;
  bool _busy = false;
  bool _reviewPrompted = false;
  Timer? _poll;
  VoidCallback? _stopLive;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _softReload());
    _stopLive = PrintLive.instance.listen(_softReload);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopLive?.call();
    _address.dispose();
    _dropLat.dispose();
    _dropLng.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _softReload() async {
    if (!mounted || widget.orderId <= 0) return;
    final result = await _repo.order(widget.orderId);
    if (!mounted || result is! PrintSuccess<PrintOrder>) return;
    final next = result.data;
    final prevStatus = _order?.status;
    final otp = next.delivery?.otp?.trim();
    if (otp != null && otp.isNotEmpty && _otp.text.trim().isEmpty) {
      _otp.text = otp;
    }
    setState(() => _order = next);
    if (prevStatus != null && prevStatus != next.status) {
      showAppToast(
        '#${next.number} · ${'lbl_print_status_${next.status}'.tr}',
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
    if (next.status == 'completed') {
      _poll?.cancel();
      if (!_reviewPrompted &&
          next.pendingReviews.any((e) => !e.submitted)) {
        _reviewPrompted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          promptPendingPrintReviews(context: context, order: next);
        });
      }
    }
  }

  Future<void> _load() async {
    final result = await _repo.order(widget.orderId);
    if (!mounted) return;
    if (result is PrintSuccess<PrintOrder>) {
      final otp = result.data.delivery?.otp?.trim();
      if (otp != null && otp.isNotEmpty && _otp.text.trim().isEmpty) {
        _otp.text = otp;
      }
      setState(() => _order = result.data);
      if (result.data.status == 'completed') {
        _poll?.cancel();
        if (!_reviewPrompted &&
            result.data.pendingReviews.any((e) => !e.submitted)) {
          _reviewPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            promptPendingPrintReviews(context: context, order: result.data);
          });
        }
      }
    }
  }

  Future<void> _confirmPickup() async {
    setState(() => _busy = true);
    final result = await _repo.confirmPickup(widget.orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
  }

  Future<void> _previewDelivery() async {
    final address = _address.text.trim();
    if (address.isEmpty) {
      showAppToast('lbl_print_address'.tr, type: ToastificationType.error);
      return;
    }
    var lat = double.tryParse(_dropLat.text.trim());
    var lng = double.tryParse(_dropLng.text.trim());
    if (lat == null || lng == null) {
      final fix = await printAcquireGps();
      if (fix == null) return;
      lat = fix.lat;
      lng = fix.lng;
      _dropLat.text = lat.toStringAsFixed(6);
      _dropLng.text = lng.toStringAsFixed(6);
    }
    setState(() => _busy = true);
    final result = await _repo.previewDelivery(
      orderId: widget.orderId,
      address: address,
      lat: lat,
      lng: lng,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintDeliveryQuote>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _preview = (result as PrintSuccess<PrintDeliveryQuote>).data);
  }

  Future<void> _confirmDelivery() async {
    setState(() => _busy = true);
    final result = await _repo.confirmDelivery(widget.orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintDeliveryQuote>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    final quote = (result as PrintSuccess<PrintDeliveryQuote>).data;
    setState(() {
      _otpOnce = quote.otp;
      if (quote.order != null) _order = quote.order;
    });
    if (!quote.assigned) {
      showAppToast('msg_print_no_riders'.tr);
    }
    await _load();
  }

  Future<void> _acceptQuote(PrintQuote quote) async {
    if (_busy) return;
    setState(() => _busy = true);
    final next = await PrintOrderActions.acceptQuote(
      context: context,
      repo: _repo,
      order: _order!,
      quote: quote,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (next == null) return;
    setState(() => _order = next);
    final paid = await PrintOrderActions.pay(
      context: context,
      repo: _repo,
      order: next,
    );
    if (!mounted) return;
    if (paid != null) setState(() => _order = paid);
  }

  Future<void> _requestChange(PrintOrder order) async {
    if (_busy) return;
    final qtyCtrl = TextEditingController(
      text: '${order.spec?.quantity ?? 100}',
    );
    final noteCtrl = TextEditingController(text: order.spec?.notes ?? '');
    final designerNoteCtrl = TextEditingController();
    final papers = const [
      '80gsm',
      '120gsm',
      '250gsm',
      '300gsm',
      'glossy',
      'matte',
    ];
    var paper = order.spec?.paper ?? '80gsm';
    if (!papers.contains(paper)) paper = '80gsm';
    final finishes = List<String>.from(order.spec?.finishing ?? const []);
    final availableFinishes = const [
      'lamination',
      'cutting',
      'folding',
      'binding',
    ];

    final submitted = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDs.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.h,
            right: 20.h,
            top: 16.v,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20.v,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'lbl_print_request_change'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6.v),
                    Text(
                      'msg_print_change_qty_hint'.tr,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    SizedBox(height: 12.v),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: printTicketField('lbl_print_quantity'.tr),
                    ),
                    SizedBox(height: 10.v),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use — controlled value needed inside StatefulBuilder
                      value: paper,
                      dropdownColor: AppDs.surfaceRaised,
                      decoration: printTicketField('lbl_print_paper'.tr),
                      items: papers
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModal(() => paper = v ?? paper),
                    ),
                    SizedBox(height: 10.v),
                    Wrap(
                      spacing: 8,
                      children: availableFinishes.map((f) {
                        final selected = finishes.contains(f);
                        return FilterChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (on) => setModal(() {
                            if (on) {
                              finishes.add(f);
                            } else {
                              finishes.remove(f);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10.v),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: printTicketField('lbl_print_optional_note'.tr),
                    ),
                    SizedBox(height: 10.v),
                    TextField(
                      controller: designerNoteCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: printTicketField('lbl_print_change_note'.tr),
                    ),
                    SizedBox(height: 14.v),
                    PrintGoldButton(
                      label: 'lbl_print_request_change'.tr,
                      onPressed: () {
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                        if (qty < 1) return;
                        Navigator.pop(ctx, {
                          'spec': {
                            'quantity': qty,
                            'paper': paper,
                            'finishing': finishes,
                            if (noteCtrl.text.trim().isNotEmpty)
                              'notes': noteCtrl.text.trim(),
                          },
                          'note': designerNoteCtrl.text.trim(),
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    qtyCtrl.dispose();
    noteCtrl.dispose();
    designerNoteCtrl.dispose();
    if (submitted == null || !mounted) return;

    setState(() => _busy = true);
    final result = await _repo.createChangeRequest(
      orderId: order.id,
      spec: (submitted['spec'] as Map).cast<String, dynamic>(),
      note: submitted['note']?.toString(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
    showAppToast('msg_print_change_submitted'.tr);
  }

  Future<void> _cancelChange(PrintOrder order) async {
    final cr = order.activeChangeRequest;
    if (cr == null || _busy) return;
    setState(() => _busy = true);
    final result = await _repo.cancelChangeRequest(
      orderId: order.id,
      changeRequestId: cr.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
    showAppToast('msg_print_change_cancelled'.tr);
  }

  Future<void> _payChange(PrintOrder order) async {
    final cr = order.activeChangeRequest;
    if (cr == null || _busy) return;
    setState(() => _busy = true);
    final next = await PrintOrderActions.payChangeRequest(
      context: context,
      repo: _repo,
      order: order,
      changeRequest: cr,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (next != null) _order = next;
    });
  }

  Future<void> _declineQuote(PrintQuote quote) async {
    if (_busy) return;
    setState(() => _busy = true);
    final next = await PrintOrderActions.declineQuote(
      context: context,
      repo: _repo,
      order: _order!,
      quote: quote,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (next != null) _order = next;
    });
  }

  Future<void> _payNow() async {
    final order = _order;
    if (order == null || _busy) return;
    setState(() => _busy = true);
    final paid = await PrintOrderActions.pay(
      context: context,
      repo: _repo,
      order: order,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (paid != null) _order = paid;
    });
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null || _busy) return;
    setState(() => _busy = true);
    final cancelled = await PrintOrderActions.cancelOrder(
      context: context,
      repo: _repo,
      order: order,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (cancelled != null) _order = cancelled;
    });
  }

  Future<void> _submitOtp() async {
    setState(() => _busy = true);
    final result = await _repo.verifyDeliveryOtp(
      orderId: widget.orderId,
      otp: _otp.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _order = (result as PrintSuccess<PrintOrder>).data);
  }

  String? _stageHint(PrintOrder order) {
    switch (order.status) {
      case 'quote':
        return 'msg_print_waiting_for_quotes_body'.tr;
      case 'awaiting_payment':
        return 'lbl_print_pay_now'.tr;
      case 'accepted':
      case 'printing':
      case 'print_complete':
      case 'quality_check':
      case 'protected':
        return 'msg_print_shop_preparing'.tr;
      case 'ready':
        if (order.fulfillment == 'delivery' && order.delivery?.riderId == null) {
          return 'msg_print_waiting_rider'.tr;
        }
        return null;
      case 'out_for_delivery':
        final arrived = (order.delivery?.arrivedCustomerAt ?? '').isNotEmpty;
        return arrived
            ? null
            : 'msg_print_need_otp_when_arrived'.tr;
      default:
        return null;
    }
  }

  String? _deliveryOtp(PrintOrder order) {
    final fromApi = order.delivery?.otp?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final once = _otpOnce?.trim();
    if (once != null && once.isNotEmpty) return once;
    return null;
  }

  bool _showDeliveryOtpConfirm(PrintOrder order) {
    if (order.fulfillment != 'delivery' || order.status == 'completed') {
      return false;
    }
    // Confirm only after the rider marks arrived at customer.
    return order.status == 'out_for_delivery' &&
        (order.delivery?.arrivedCustomerAt ?? '').isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final theme = Theme.of(context);
    return PrintScaffold(
      title: 'lbl_print_tracking'.tr,
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDs.space4.h,
                  AppDs.space4.v,
                  AppDs.space4.h,
                  AppDs.space8.v,
                ),
                children: [
                  PrintStatusHero(
                    number: order.number,
                    statusLabel: 'lbl_print_status_${order.status}'.tr,
                    shopName: order.shop?.name,
                    totalLabel: order.total != null
                        ? '${'lbl_print_total_due'.tr} · ${printSar(order.total!)}'
                        : null,
                    hint: _stageHint(order),
                  ),
                  if (order.dispute != null) ...[
                    SizedBox(height: AppDs.space3.v),
                    Text(
                      '${'lbl_print_dispute_status'.tr}: ${'lbl_print_dispute_${order.dispute!.status}'.tr}',
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.atelierBrass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (order.activeChangeRequest != null) ...[
                    SizedBox(height: AppDs.space3.v),
                    _ChangeRequestBanner(
                      change: order.activeChangeRequest!,
                      onPay: order.activeChangeRequest!.needsCustomerPayment
                          ? () => _payChange(order)
                          : null,
                      onCancel: order.activeChangeRequest!.status == 'pending'
                          ? () => _cancelChange(order)
                          : null,
                    ),
                  ],
                  if (order.canRequestChange) ...[
                    SizedBox(height: AppDs.space3.v),
                    PrintGhostButton(
                      label: 'lbl_print_request_change'.tr,
                      icon: Icons.edit_note_outlined,
                      onPressed: _busy ? null : () => _requestChange(order),
                    ),
                  ],
                  SizedBox(height: AppDs.space4.v),
                  PrintQuoteOffersBoard(
                    order: order,
                    busy: _busy,
                    onAccept: _acceptQuote,
                    onDecline: _declineQuote,
                  ),
                  if (order.status == 'awaiting_payment') ...[
                    PrintGoldButton(
                      label: 'lbl_print_pay_now'.tr,
                      loading: _busy,
                      onPressed: _payNow,
                    ),
                    SizedBox(height: AppDs.space3.v),
                  ],
                  if (order.status == 'ready' && order.fulfillment == null) ...[
                    PrintGoldButton(
                      label: 'lbl_print_pick_up'.tr,
                      loading: _busy,
                      onPressed: _confirmPickup,
                    ),
                    SizedBox(height: AppDs.space3.v),
                    Text(
                      'lbl_print_deliver_to_me'.tr,
                      style: AppTypography.body(theme).copyWith(
                        color: AppDs.textOnDarkPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppDs.space2.v),
                    TextField(
                      controller: _address,
                      style: const TextStyle(color: Colors.white),
                      decoration: printTicketField('lbl_print_delivery_address'.tr),
                    ),
                    SizedBox(height: AppDs.space2.v),
                    PrintLocationPicker(
                      latController: _dropLat,
                      lngController: _dropLng,
                      addressController: _address,
                      onChanged: () => setState(() {}),
                    ),
                    SizedBox(height: AppDs.space2.v),
                    PrintGoldButton(
                      label: 'lbl_print_deliver_to_me'.tr,
                      loading: _busy,
                      onPressed: _previewDelivery,
                    ),
                    if (_preview != null) ...[
                      SizedBox(height: AppDs.space3.v),
                      _SimpleTotals(quote: _preview!),
                      SizedBox(height: AppDs.space2.v),
                      PrintGoldButton(
                        label: 'lbl_print_confirm_delivery'.tr,
                        loading: _busy,
                        onPressed: _confirmDelivery,
                      ),
                    ],
                    SizedBox(height: AppDs.space3.v),
                  ],
                  if (order.fulfillment == 'pickup' &&
                      (order.readyForPickup ||
                          order.status == 'ready' ||
                          order.status == 'completed')) ...[
                    _PickupCodeCard(code: order.pickupCode),
                    SizedBox(height: AppDs.space3.v),
                  ],
                  if (_deliveryOtp(order) != null &&
                      order.fulfillment == 'delivery' &&
                      order.status != 'completed') ...[
                    _OtpReveal(code: _deliveryOtp(order)!),
                    SizedBox(height: AppDs.space1.v),
                    Text(
                      'msg_print_otp_not_order_number'.tr,
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: AppDs.space3.v),
                  ],
                  if (_showDeliveryOtpConfirm(order)) ...[
                    TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: printTicketField('lbl_print_enter_otp'.tr)
                          .copyWith(counterText: ''),
                    ),
                    SizedBox(height: AppDs.space2.v),
                    PrintGoldButton(
                      label: 'lbl_print_confirm_otp'.tr,
                      loading: _busy,
                      onPressed: _submitOtp,
                    ),
                    SizedBox(height: AppDs.space3.v),
                  ],
                  if (order.status == 'completed') ...[
                    Text(
                      'lbl_print_please_review'.tr,
                      style: AppTypography.body(theme).copyWith(
                        color: AppDs.atelierBrass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ...order.pendingReviews.where((e) => !e.submitted).map(
                      (pending) => Padding(
                        padding: EdgeInsets.only(top: AppDs.space2.v),
                        child: PrintGoldButton(
                          label: 'lbl_print_review_${pending.target}'.tr,
                          onPressed: () async {
                            await showPrintReviewSheet(
                              context: context,
                              orderId: order.id,
                              target: pending.target,
                            );
                            _load();
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: AppDs.space3.v),
                  ],
                  PrintTextActionRow(
                    actions: [
                      (
                        'lbl_print_message_shop'.tr,
                        () => NavigatorService.pushNamed(
                              AppRoutes.printChatScreen,
                              arguments: {
                                if (order.conversationId != null)
                                  'conversationId': order.conversationId,
                                'orderId': order.id,
                                'shopId': order.shopId,
                                'viewer': 'customer',
                                'thread': 'customer_shop',
                              },
                            ),
                      ),
                      if (order.canCancel)
                        ('lbl_print_cancel_order'.tr, _busy ? null : _cancelOrder),
                      if (order.dispute == null &&
                          order.status != 'quote' &&
                          order.status != 'awaiting_payment' &&
                          order.status != 'cancelled')
                        (
                          'lbl_print_report_problem'.tr,
                          () async {
                            await showPrintDisputeSheet(
                              context: context,
                              orderId: order.id,
                            );
                            _load();
                          },
                        ),
                    ],
                  ),
                  if (order.payment != null) ...[
                    SizedBox(height: AppDs.space2.v),
                    Text(
                      '${'msg_print_payment_protected'.tr} · ${printSar(order.payment!.amount)}',
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (order.fulfillment == 'delivery' &&
                      order.delivery != null) ...[
                    SizedBox(height: AppDs.space4.v),
                    _CompactMaps(order: order),
                  ],
                  if (order.timeline.isNotEmpty) ...[
                    SizedBox(height: AppDs.space4.v),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.only(top: AppDs.space2.v),
                        iconColor: AppDs.atelierBrass,
                        collapsedIconColor: AppDs.textOnDarkSecondary,
                        title: Text(
                          'lbl_print_activity'.tr,
                          style: AppTypography.body(theme).copyWith(
                            color: AppDs.textOnDarkPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          for (final event in order.timeline.reversed.take(8))
                            Padding(
                              padding: EdgeInsets.only(bottom: AppDs.space3.v),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8.adaptSize,
                                    height: 8.adaptSize,
                                    margin: EdgeInsets.only(top: 6.v),
                                    decoration: const BoxDecoration(
                                      color: AppDs.atelierBrass,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: AppDs.space3.h),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: AppTypography.secondary(theme)
                                              .copyWith(
                                            color: AppDs.textOnDarkPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (event.detail != null)
                                          Text(
                                            event.detail!,
                                            style: AppTypography.caption(theme)
                                                .copyWith(
                                              color: AppDs.textOnDarkSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PickupCodeCard extends StatelessWidget {
  const _PickupCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AppDs.space4.h),
      decoration: BoxDecoration(
        color: AppDs.atelierBrass,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            'lbl_print_ready_pickup'.tr,
            style: AppTypography.caption(theme).copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppDs.space2.v),
          ColoredBox(
            color: Colors.white,
            child: QrImageView(
              data: code,
              size: 140,
              backgroundColor: Colors.white,
            ),
          ),
          SizedBox(height: AppDs.space2.v),
          Text(
            code,
            style: TextStyle(
              color: Colors.black,
              fontSize: 26.fSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpReveal extends StatelessWidget {
  const _OtpReveal({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space4.h,
        vertical: AppDs.space4.v,
      ),
      decoration: BoxDecoration(
        color: AppDs.atelierBrass,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            'lbl_print_delivery_otp'.tr,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppDs.space1.v),
          Text(
            'OTP: $code',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32.fSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTotals extends StatelessWidget {
  const _SimpleTotals({required this.quote});

  final PrintDeliveryQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${'lbl_print_delivery_fee'.tr} ${printSar(quote.deliveryFee)}',
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
            ),
          ),
        ),
        Text(
          printSar(quote.total),
          style: AppTypography.body(theme).copyWith(
            color: AppDs.atelierBrass,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompactMaps extends StatelessWidget {
  const _CompactMaps({required this.order});

  final PrintOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delivery = order.delivery;
    final shop = order.shop;
    final links = <(String, double, double)>[
      if (shop?.lat != null && shop?.lng != null)
        ('lbl_print_shop_mode'.tr, shop!.lat!, shop.lng!),
      if (delivery?.customerLat != null && delivery?.customerLng != null)
        (
          'lbl_print_customer'.tr,
          delivery!.customerLat!,
          delivery.customerLng!,
        ),
      if (delivery?.riderLat != null && delivery?.riderLng != null)
        (
          (delivery?.riderName?.isNotEmpty ?? false)
              ? delivery!.riderName!
              : 'lbl_print_rider'.tr,
          delivery!.riderLat!,
          delivery.riderLng!,
        ),
    ];
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'lbl_print_locations'.tr,
          style: AppTypography.body(theme).copyWith(
            color: AppDs.textOnDarkPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppDs.space1.v),
        Wrap(
          spacing: AppDs.space2.h,
          children: [
            for (final link in links)
              TextButton.icon(
                onPressed: () => printOpenInMaps(link.$2, link.$3),
                icon: Icon(
                  Icons.map_outlined,
                  size: 16.adaptSize,
                  color: AppDs.atelierBrass,
                ),
                label: Text(link.$1),
                style: TextButton.styleFrom(
                  foregroundColor: AppDs.atelierBrass,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChangeRequestBanner extends StatelessWidget {
  const _ChangeRequestBanner({
    required this.change,
    this.onPay,
    this.onCancel,
  });

  final PrintChangeRequest change;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final awaitingPay = change.needsCustomerPayment;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDs.space3.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: AppDs.atelierBrass.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            awaitingPay
                ? 'msg_print_change_awaiting_payment'.tr
                : 'msg_print_change_pending'.tr,
            style: AppTypography.body(theme).copyWith(
              color: AppDs.atelierBrass,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (change.deltaAmount != null && change.deltaAmount != 0) ...[
            SizedBox(height: 4.v),
            Text(
              printSar(change.deltaAmount!),
              style: AppTypography.caption(theme).copyWith(
                color: AppDs.textOnDarkSecondary,
              ),
            ),
          ],
          if (onPay != null || onCancel != null) ...[
            SizedBox(height: 10.v),
            if (onPay != null)
              PrintGoldButton(
                label: 'lbl_print_pay_change'.tr,
                onPressed: onPay,
              ),
            if (onCancel != null) ...[
              if (onPay != null) SizedBox(height: 8.v),
              PrintGhostButton(
                label: 'lbl_print_cancel_change_request'.tr,
                onPressed: onCancel,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
