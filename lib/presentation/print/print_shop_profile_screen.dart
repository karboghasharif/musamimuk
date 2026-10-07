import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

class PrintShopProfileScreen extends StatefulWidget {
  const PrintShopProfileScreen({
    super.key,
    required this.shopId,
    required this.orderId,
    this.request,
  });

  final int shopId;
  final int orderId;
  final Map<String, dynamic>? request;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    final request = map['request'];
    return PrintShopProfileScreen(
      shopId: apiParseInt(map['shopId']),
      orderId: apiParseInt(map['orderId']),
      request: request is Map ? request.cast<String, dynamic>() : null,
    );
  }

  @override
  State<PrintShopProfileScreen> createState() => _PrintShopProfileScreenState();
}

class _PrintShopProfileScreenState extends State<PrintShopProfileScreen> {
  final _repo = PrintRepository();
  PrintShopSummary? _shop;
  List<PrintReview> _reviews = const [];
  bool _loading = true;
  bool _chatting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.shopProfile(widget.shopId);
    if (!mounted) return;
    if (result is PrintFailure<PrintShopSummary>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _shop = (result as PrintSuccess<PrintShopSummary>).data;
      _loading = false;
    });
    final reviews = await _repo.shopReviews(widget.shopId);
    if (!mounted) return;
    if (reviews is PrintSuccess<List<PrintReview>>) {
      setState(() => _reviews = reviews.data);
    }
  }

  Future<void> _chat() async {
    if (_chatting) return;
    setState(() => _chatting = true);
    final request = widget.request;
    final PrintResult<PrintOrder> result;
    if (request != null && apiParseInt(request['designId']) > 0) {
      final specMap = request['spec'];
      result = await _repo.createJob(
        designId: apiParseInt(request['designId']),
        spec: specMap is Map
            ? PrintSpec.fromJson(specMap.cast<String, dynamic>())
            : const PrintSpec(sizeId: 'a4', quantity: 100, sides: 1, color: 'color', paper: '80gsm'),
        shopId: widget.shopId,
        fulfillment: request['fulfillment']?.toString(),
        dropoffAddress: request['dropoffAddress']?.toString(),
        dropoffLat: request['dropoffLat'] is num ? (request['dropoffLat'] as num).toDouble() : null,
        dropoffLng: request['dropoffLng'] is num ? (request['dropoffLng'] as num).toDouble() : null,
      );
    } else {
      result = await _repo.startChat(
        shopId: widget.shopId,
        orderId: widget.orderId,
        body: 'lbl_print_hello_shop'.tr,
      );
    }
    if (!mounted) return;
    setState(() => _chatting = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    final order = (result as PrintSuccess<PrintOrder>).data;
    NavigatorService.pushNamed(
      AppRoutes.printChatScreen,
      arguments: {'orderId': order.id, 'shopId': widget.shopId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    return PrintScaffold(
      title: shop?.name ?? 'lbl_print_shop_profile'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16.h),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop!.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.fSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (shop.verified)
                      Chip(
                        label: Text('lbl_print_verified'.tr),
                        backgroundColor: AppDs.printGold,
                      ),
                  ],
                ),
                PrintLevelBadge(
                  label: shop.levelLabel,
                  labelAr: shop.levelLabelAr,
                ),
                if (shop.nameAr != null)
                  Text(
                    shop.nameAr!,
                    style: const TextStyle(color: AppDs.textOnDarkSecondary),
                  ),
                SizedBox(height: 8.v),
                Text(
                  '${shop.rating.toStringAsFixed(1)} ★ · ${shop.completedOrders} ${'lbl_print_orders'.tr}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (shop.address != null)
                  Text(
                    shop.address!,
                    style: const TextStyle(color: AppDs.textOnDarkSecondary),
                  ),
                SizedBox(height: 16.v),
                Text(
                  shop.about ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 12.v),
                Wrap(
                  spacing: 8,
                  children: shop.services
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          backgroundColor: AppDs.surfaceRaised,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 16.v),
                Text(
                  'lbl_print_verified_reviews'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.v),
                PrintVerifiedReviewList(reviews: _reviews),
                SizedBox(height: 24.v),
                PrintGoldButton(
                  label: 'lbl_print_chat'.tr,
                  loading: _chatting,
                  onPressed: _chat,
                ),
              ],
            ),
    );
  }
}
