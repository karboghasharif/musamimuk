import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: widget.shopMode ? 'lbl_print_shop_orders'.tr : 'lbl_print_my_orders'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
          : _orders.isEmpty
          ? Center(
              child: Text(
                'msg_print_no_orders'.tr,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: EdgeInsets.all(16.h),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.v),
                itemBuilder: (context, index) {
                  final order = _orders[index];
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
                      order.shop?.name ?? order.pickupCode,
                      style: const TextStyle(color: AppDs.textOnDarkSecondary),
                    ),
                    onTap: () {
                      if (widget.shopMode) {
                        NavigatorService.pushNamed(
                          AppRoutes.printShopDashboardScreen,
                          arguments: {'orderId': order.id},
                        );
                      } else {
                        NavigatorService.pushNamed(
                          AppRoutes.printTrackingScreen,
                          arguments: {'orderId': order.id},
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
