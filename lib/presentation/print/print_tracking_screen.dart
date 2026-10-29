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
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load());
    _stopLive = PrintLive.instance.listen(_load);
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

  Future<void> _load() async {
    final result = await _repo.order(widget.orderId);
    if (!mounted) return;
    if (result is PrintSuccess<PrintOrder>) {
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

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return PrintScaffold(
      title: 'lbl_print_tracking'.tr,
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(16.h),
                children: [
                  Text(
                    '#${order.number}',
                    style: TextStyle(
                      color: AppDs.printGold,
                      fontSize: 20.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'lbl_print_status_${order.status}'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (order.shop?.name != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.v),
                      child: Text(
                        order.shop!.name,
                        style: const TextStyle(color: AppDs.textOnDarkSecondary),
                      ),
                    ),
                  if (order.dispute != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8.v),
                      child: Text(
                        '${'lbl_print_dispute_status'.tr}: ${'lbl_print_dispute_${order.dispute!.status}'.tr}',
                        style: const TextStyle(color: AppDs.printGold),
                      ),
                    ),
                  SizedBox(height: 12.v),
                  PrintQuoteDecisionCard(
                    order: order,
                    busy: _busy,
                    onAccept: () {
                      final quote = order.offeredQuote;
                      if (quote != null) _acceptQuote(quote);
                    },
                    onDecline: () {
                      final quote = order.offeredQuote;
                      if (quote != null) _declineQuote(quote);
                    },
                  ),
                  if (order.status == 'awaiting_payment') ...[
                    SizedBox(height: 12.v),
                    PrintGoldButton(
                      label: 'lbl_print_pay_now'.tr,
                      loading: _busy,
                      onPressed: _payNow,
                    ),
                  ],
                  SizedBox(height: 12.v),
                  OutlinedButton.icon(
                    onPressed: () {
                      NavigatorService.pushNamed(
                        AppRoutes.printChatScreen,
                        arguments: {
                          'orderId': order.id,
                          'viewer': 'customer',
                          'thread': 'customer_shop',
                        },
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, color: AppDs.printGold),
                    label: Text('lbl_print_message_shop'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDs.printGold,
                      side: const BorderSide(color: AppDs.printGold),
                      minimumSize: Size(double.infinity, 48.v),
                    ),
                  ),
                  if (order.canCancel) ...[
                    SizedBox(height: 8.v),
                    SizedBox(
                      height: 44.v,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _cancelOrder,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: Size(double.infinity, 44.v),
                        ),
                        child: Text('lbl_print_cancel_order'.tr),
                      ),
                    ),
                  ],
                  if (order.status == 'ready' && order.fulfillment == null) ...[
                    SizedBox(height: 16.v),
                    PrintGoldButton(
                      label: 'lbl_print_pick_up'.tr,
                      loading: _busy,
                      onPressed: _confirmPickup,
                    ),
                    SizedBox(height: 10.v),
                    TextField(
                      controller: _address,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'lbl_print_delivery_address'.tr,
                        labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
                        filled: true,
                        fillColor: AppDs.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.v),
                    PrintLocationPicker(
                      latController: _dropLat,
                      lngController: _dropLng,
                      onChanged: () => setState(() {}),
                    ),
                    SizedBox(height: 10.v),
                    PrintGoldButton(
                      label: 'lbl_print_deliver_to_me'.tr,
                      loading: _busy,
                      onPressed: _previewDelivery,
                    ),
                    if (_preview != null) ...[
                      SizedBox(height: 12.v),
                      _TotalsCard(quote: _preview!),
                      SizedBox(height: 10.v),
                      PrintGoldButton(
                        label: 'lbl_print_confirm_delivery'.tr,
                        loading: _busy,
                        onPressed: _confirmDelivery,
                      ),
                    ],
                  ],
                  if (order.fulfillment == 'pickup' ||
                      (order.readyForPickup && order.fulfillment == 'pickup')) ...[
                    SizedBox(height: 12.v),
                    _PickupCodeCard(code: order.pickupCode),
                  ],
                  if (order.fulfillment == 'delivery') ...[
                    SizedBox(height: 12.v),
                    _TotalsCard(
                      quote: PrintDeliveryQuote(
                        printSubtotal: order.printSubtotal ?? 0,
                        deliveryFee: order.deliveryFee ?? 0,
                        total: order.total ?? 0,
                      ),
                    ),
                    if (_otpOnce != null) ...[
                      SizedBox(height: 12.v),
                      Container(
                        padding: EdgeInsets.all(16.h),
                        decoration: BoxDecoration(
                          color: AppDs.printGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'lbl_print_otp_once'.tr,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _otpOnce!,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28.fSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (order.delivery != null) ...[
                      SizedBox(height: 12.v),
                      _MapCard(order: order),
                    ],
                    if (order.status != 'completed') ...[
                      SizedBox(height: 12.v),
                      TextField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'lbl_print_enter_otp'.tr,
                          counterText: '',
                          labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
                          filled: true,
                          fillColor: AppDs.surfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.v),
                      PrintGoldButton(
                        label: 'lbl_print_confirm_otp'.tr,
                        loading: _busy,
                        onPressed: _submitOtp,
                      ),
                    ],
                  ],
                  if (order.status == 'completed') ...[
                    SizedBox(height: 16.v),
                    Text(
                      'lbl_print_please_review'.tr,
                      style: const TextStyle(
                        color: AppDs.printGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ...order.pendingReviews.where((e) => !e.submitted).map(
                      (pending) => Padding(
                        padding: EdgeInsets.only(top: 8.v),
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
                  ],
                  if (order.payment != null)
                    Padding(
                      padding: EdgeInsets.only(top: 12.v),
                      child: Text(
                        '${'msg_print_payment_protected'.tr}\n${printSar(order.payment!.amount)} · ${order.payment!.status}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  if (order.dispute == null &&
                      order.status != 'quote' &&
                      order.status != 'awaiting_payment' &&
                      order.status != 'cancelled') ...[
                    SizedBox(height: 12.v),
                    PrintGoldButton(
                      label: 'lbl_print_report_problem'.tr,
                      onPressed: () async {
                        await showPrintDisputeSheet(
                          context: context,
                          orderId: order.id,
                        );
                        _load();
                      },
                    ),
                  ],
                  SizedBox(height: 20.v),
                  ...order.timeline.map(
                    (event) => Padding(
                      padding: EdgeInsets.only(bottom: 16.v),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: AppDs.printGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 36,
                                color: AppDs.printGold.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                          SizedBox(width: 12.h),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (event.detail != null)
                                  Text(
                                    event.detail!,
                                    style: const TextStyle(
                                      color: AppDs.textOnDarkSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.printGold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'lbl_print_ready_pickup'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.v),
          ColoredBox(
            color: Colors.white,
            child: QrImageView(
              data: code,
              size: 160,
              backgroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 8.v),
          Text(
            code,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24.fSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.quote});

  final PrintDeliveryQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${'lbl_print_subtotal'.tr}: ${printSar(quote.printSubtotal)}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '${'lbl_print_delivery_fee'.tr}: ${printSar(quote.deliveryFee)}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '${'lbl_print_grand_total'.tr}: ${printSar(quote.total)}',
            style: const TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.order});

  final PrintOrder order;

  Widget _pointRow({
    required String label,
    required double? lat,
    required double? lng,
    String? detail,
  }) {
    if (lat == null || lng == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 8.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            detail == null || detail.isEmpty
                ? '$label: $lat, $lng'
                : '$label: $detail · $lat, $lng',
            style: const TextStyle(color: Colors.white70),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => printOpenInMaps(lat, lng),
              icon: const Icon(Icons.map_outlined, color: AppDs.printGold, size: 18),
              label: Text(
                'lbl_print_open_in_maps'.tr,
                style: const TextStyle(color: AppDs.printGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivery = order.delivery;
    final shop = order.shop;
    return Container(
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lbl_print_live_map'.tr,
            style: const TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          _pointRow(
            label: 'lbl_print_shop_mode'.tr,
            lat: shop?.lat,
            lng: shop?.lng,
          ),
          _pointRow(
            label: 'lbl_print_customer'.tr,
            lat: delivery?.customerLat,
            lng: delivery?.customerLng,
          ),
          _pointRow(
            label: 'lbl_print_rider'.tr,
            lat: delivery?.riderLat,
            lng: delivery?.riderLng,
            detail: delivery?.riderName,
          ),
          Text(
            'lbl_print_status_${delivery?.status ?? order.status}'.tr,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
