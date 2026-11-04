import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_live.dart';
import 'print_review_sheet.dart';
import 'print_ui.dart';

class PrintOrdersScreen extends StatefulWidget {
  const PrintOrdersScreen({super.key, this.shopMode = false});

  final bool shopMode;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final shopMode = args is Map && args['shopMode'] == true;
    return PrintOrdersScreen(shopMode: shopMode);
  }

  @override
  State<PrintOrdersScreen> createState() => _PrintOrdersScreenState();
}

class _PrintOrdersScreenState extends State<PrintOrdersScreen> {
  final _repo = PrintRepository();
  List<PrintOrder> _orders = const [];
  bool _loading = true;
  String? _error;
  Timer? _poll;
  VoidCallback? _stopLive;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _softReload());
    _stopLive = PrintLive.instance.listen(_softReload);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopLive?.call();
    super.dispose();
  }

  Future<void> _softReload() async {
    if (!mounted || _loading) return;
    final result =
        widget.shopMode ? await _repo.shopOrders() : await _repo.myOrders();
    if (!mounted || result is! PrintSuccess<List<PrintOrder>>) return;
    final next = result.data;
    final prev = {
      for (final order in _orders) order.id: order.status,
    };
    PrintOrder? changed;
    for (final order in next) {
      final before = prev[order.id];
      if (before != null && before != order.status) {
        changed = order;
        break;
      }
    }
    setState(() => _orders = next);
    if (changed != null) {
      showAppToast(
        '#${changed.number} · ${'lbl_print_status_${changed.status}'.tr}',
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = widget.shopMode ? await _repo.shopOrders() : await _repo.myOrders();
    if (!mounted) return;
    if (result is PrintFailure<List<PrintOrder>>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _orders = (result as PrintSuccess<List<PrintOrder>>).data;
      _loading = false;
    });
  }

  List<PrintOrder> get _active =>
      _orders.where((o) => o.status != 'completed' && o.status != 'cancelled').toList();

  List<PrintOrder> get _completed =>
      _orders.where((o) => o.status == 'completed').toList();

  String _reviewStatus(PrintOrder order) {
    if (order.status != 'completed' || order.pendingReviews.isEmpty) {
      return '';
    }
    if (order.pendingReviews.every((e) => e.submitted)) {
      return 'lbl_print_reviewed'.tr;
    }
    return 'lbl_print_please_review'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PrintScaffold(
        title: widget.shopMode ? 'lbl_print_shop_orders'.tr : 'lbl_print_my_orders'.tr,
        actions: [
          IconButton(
            tooltip: 'lbl_print_notices'.tr,
            onPressed: () =>
                NavigatorService.pushNamed(AppRoutes.printNoticesScreen),
            icon: const Icon(Icons.notifications_outlined, color: AppDs.printGold),
          ),
        ],
        body: Column(
          children: [
            TabBar(
              indicatorColor: AppDs.printGold,
              labelColor: AppDs.printGold,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'lbl_print_tab_active'.tr),
                Tab(text: 'lbl_print_tab_completed'.tr),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
                  : TabBarView(
                      children: [
                        _list(_active),
                        _list(_completed),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<PrintOrder> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'msg_print_no_orders'.tr,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(16.h),
        itemCount: orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.v),
        itemBuilder: (context, index) {
          final order = orders[index];
          final review = _reviewStatus(order);
          return ListTile(
            tileColor: AppDs.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              '#${order.number} · ${'lbl_print_status_${order.status}'.tr}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              [
                order.shop?.name ?? order.pickupCode,
                if (!widget.shopMode && order.offeredQuote != null)
                  'msg_print_quote_on_order'.tr,
                if (order.status == 'awaiting_payment') 'lbl_print_pay_now'.tr,
                if (review.isNotEmpty) review,
                if (order.dispute != null)
                  'lbl_print_dispute_${order.dispute!.status}'.tr,
              ].join(' · '),
              style: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
            onTap: () async {
              if (widget.shopMode) {
                NavigatorService.pushNamed(
                  AppRoutes.printShopDashboardScreen,
                  arguments: {'orderId': order.id},
                );
              } else {
                await NavigatorService.pushNamed(
                  AppRoutes.printTrackingScreen,
                  arguments: {'orderId': order.id},
                );
              }
              if (order.status == 'completed') {
                if (!context.mounted) return;
                await promptPendingPrintReviews(context: context, order: order);
                _load();
              }
            },
          );
        },
      ),
    );
  }
}
