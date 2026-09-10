import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
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
  final _otp = TextEditingController();
  PrintOrder? _order;
  PrintDeliveryQuote? _preview;
  String? _otpOnce;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _address.dispose();
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
    setState(() => _busy = true);
    final result = await _repo.previewDelivery(
      orderId: widget.orderId,
      address: address,
      lat: 21.57,
      lng: 39.17,
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
                  if (order.payment != null)
                    Padding(
                      padding: EdgeInsets.only(top: 12.v),
                      child: Text(
                        '${'msg_print_payment_protected'.tr}\n${printSar(order.payment!.amount)} · ${order.payment!.status}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
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
          if (shop?.lat != null)
            Text(
              '${'lbl_print_shop_mode'.tr}: ${shop!.lat}, ${shop.lng}',
              style: const TextStyle(color: Colors.white70),
            ),
          if (delivery?.customerLat != null)
            Text(
              '${'lbl_print_customer'.tr}: ${delivery!.customerLat}, ${delivery.customerLng}',
              style: const TextStyle(color: Colors.white70),
            ),
          if (delivery?.riderLat != null)
            Text(
              '${'lbl_print_rider'.tr}: ${delivery!.riderName ?? ''} · ${delivery.riderLat}, ${delivery.riderLng}',
              style: const TextStyle(color: Colors.white70),
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
