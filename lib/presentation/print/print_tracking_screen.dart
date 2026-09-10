import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
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
  PrintOrder? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.order(widget.orderId);
    if (!mounted) return;
    if (result is PrintSuccess<PrintOrder>) {
      setState(() => _order = result.data);
    }
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
                  if (order.readyForPickup) ...[
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
                            'lbl_print_ready_pickup'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            order.pickupCode,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24.fSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
