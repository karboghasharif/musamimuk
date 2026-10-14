import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_earnings_card.dart';
import 'print_dispute_sheet.dart';
import 'print_review_sheet.dart';
import 'print_mode_switch.dart';
import 'print_live.dart';
import 'print_ui.dart';

class PrintShopRegisterScreen extends StatefulWidget {
  const PrintShopRegisterScreen({super.key});

  static Widget builder(BuildContext context) => const PrintShopRegisterScreen();

  @override
  State<PrintShopRegisterScreen> createState() =>
      _PrintShopRegisterScreenState();
}

class _PrintShopRegisterScreenState extends State<PrintShopRegisterScreen> {
  final _repo = PrintRepository();
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _cr = TextEditingController();
  final _vat = TextEditingController();
  final _iban = TextEditingController();
  final _address = TextEditingController();
  final _district = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _owner.dispose();
    _phone.dispose();
    _cr.dispose();
    _vat.dispose();
    _iban.dispose();
    _address.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await _repo.registerShop(
      name: _name.text.trim(),
      nameAr: _nameAr.text.trim().isEmpty ? null : _nameAr.text.trim(),
      ownerName: _owner.text.trim(),
      phone: _phone.text.trim(),
      crNumber: _cr.text.trim().isEmpty ? null : _cr.text.trim(),
      vatNumber: _vat.text.trim().isEmpty ? null : _vat.text.trim(),
      iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
      lat: 21.54,
      lng: 39.17,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is PrintFailure<PrintShopSummary>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    NavigatorService.pushReplacementNamed(AppRoutes.printShopHomeScreen);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
      filled: true,
      fillColor: AppDs.surfaceRaised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    Widget field(TextEditingController c, String label) => Padding(
      padding: EdgeInsets.only(bottom: 10.v),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: deco(label),
      ),
    );

    return PrintScaffold(
      title: 'lbl_print_register_shop'.tr,
      showBack: false,
      actions: const [PrintModeButton()],
      body: ListView(
        padding: EdgeInsets.all(16.h),
        children: [
          field(_name, 'lbl_print_shop_name'.tr),
          field(_nameAr, 'lbl_print_shop_name_ar'.tr),
          field(_owner, 'lbl_print_owner_name'.tr),
          field(_phone, 'lbl_print_phone'.tr),
          field(_cr, 'lbl_print_cr'.tr),
          field(_vat, 'lbl_print_vat'.tr),
          field(_iban, 'lbl_print_iban'.tr),
          field(_address, 'lbl_print_address'.tr),
          field(_district, 'lbl_print_district'.tr),
          PrintGoldButton(
            label: 'lbl_print_submit'.tr,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class PrintShopHomeScreen extends StatefulWidget {
  const PrintShopHomeScreen({super.key});

  static Widget builder(BuildContext context) => const PrintShopHomeScreen();

  @override
  State<PrintShopHomeScreen> createState() => _PrintShopHomeScreenState();
}

class _PrintShopHomeScreenState extends State<PrintShopHomeScreen> {
  final _repo = PrintRepository();
  PrintShopSummary? _shop;
  List<PrintOrder> _orders = const [];
  bool _loading = true;
  String? _error;
  int _section = 0;
  Timer? _poll;
  VoidCallback? _stopLive;
  Set<int>? _knownOrderIds;
  PrintOrder? _banner;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refreshOrders());
    _stopLive = PrintLive.instance.listen(_refreshOrders);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopLive?.call();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final shopResult = await _repo.myShop();
    if (!mounted) return;
    if (shopResult is PrintFailure<PrintShopSummary?>) {
      setState(() {
        _loading = false;
        _error = shopResult.message;
      });
      return;
    }
    final shop = (shopResult as PrintSuccess<PrintShopSummary?>).data;
    if (shop == null) {
      if (!mounted) return;
      NavigatorService.pushReplacementNamed(AppRoutes.printShopRegisterScreen);
      return;
    }
    final ordersResult = await _repo.shopOrders();
    if (!mounted) return;
    final rows = ordersResult is PrintSuccess<List<PrintOrder>>
        ? ordersResult.data
        : const <PrintOrder>[];
    setState(() {
      _shop = shop;
      _orders = rows;
      _knownOrderIds = rows.map((order) => order.id).toSet();
      _loading = false;
    });
  }

  Future<void> _refreshOrders() async {
    final ordersResult = await _repo.shopOrders();
    if (!mounted || ordersResult is! PrintSuccess<List<PrintOrder>>) return;
    final rows = ordersResult.data;
    final known = _knownOrderIds;
    PrintOrder? fresh;
    if (known != null) {
      for (final order in rows) {
        if (!known.contains(order.id)) {
          fresh = order;
          break;
        }
      }
    }
    setState(() {
      _orders = rows;
      _knownOrderIds = rows.map((order) => order.id).toSet();
      if (fresh != null) _banner = fresh;
    });
    if (fresh != null) {
      showAppToast(
        '${'lbl_print_new_request'.tr} #${fresh.number}',
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PrintScaffold(
        title: 'lbl_print_shop_mode'.tr,
        showBack: false,
        actions: const [PrintModeButton()],
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final shop = _shop;
    if (shop == null || !shop.canOperate) {
      final message = shop == null
          ? 'msg_print_register_prompt'.tr
          : shop.status == 'pending'
              ? 'msg_print_shop_pending'.tr
              : 'lbl_print_status_${shop.status}'.tr;
      return PrintScaffold(
        title: 'lbl_print_shop_mode'.tr,
        showBack: false,
        actions: const [PrintModeButton()],
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                if (_orders.isNotEmpty) ...[
                  SizedBox(height: 16.v),
                  ..._orders.map(
                    (order) => Padding(
                      padding: EdgeInsets.only(bottom: 8.v),
                      child: Text(
                        '#${order.number} · ${order.customerName ?? ''} · ${'lbl_print_status_${order.status}'.tr}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return PrintScaffold(
      title: shop.name,
      showBack: false,
      actions: const [PrintModeButton()],
      bottom: NavigationBar(
        backgroundColor: AppDs.surfaceRaised,
        indicatorColor: AppDs.printGold.withValues(alpha: 0.25),
        selectedIndex: _section,
        onDestinationSelected: (index) => setState(() => _section = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            label: 'lbl_home'.tr,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _orders.where((order) => order.status == 'quote').isNotEmpty,
              label: Text('${_orders.where((order) => order.status == 'quote').length}'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            label: 'lbl_print_shop_orders'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            label: 'lbl_print_earnings'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            label: 'lbl_print_profile'.tr,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.all(16.h),
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            if (_banner != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12.v),
                child: Material(
                  color: AppDs.printGold,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      _section = 1;
                      _banner = null;
                    }),
                    child: Padding(
                      padding: EdgeInsets.all(14.h),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.black),
                          SizedBox(width: 12.h),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'lbl_print_new_request'.tr} #${_banner!.number}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  _banner!.customerName ?? 'msg_print_new_request'.tr,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _banner = null),
                            icon: const Icon(Icons.close, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_section == 0) ...[
              _ShopDesk(shop: shop, orders: _orders),
              SizedBox(height: 16.v),
              Text(
                'lbl_print_incoming'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.fSize,
                ),
              ),
              SizedBox(height: 8.v),
              if (_orders.where((order) => order.status == 'quote').isEmpty)
                Text(
                  'msg_print_no_orders'.tr,
                  style: const TextStyle(color: Colors.white70),
                ),
              ..._orders.where((order) => order.status == 'quote').map(
                (order) => Padding(
                  padding: EdgeInsets.only(bottom: 10.v),
                  child: _ShopOrderCard(order: order, onChanged: _load),
                ),
              ),
            ],
            if (_section == 1)
              ..._orders.map(
                (order) => Padding(
                  padding: EdgeInsets.only(bottom: 10.v),
                  child: _ShopOrderCard(order: order, onChanged: _load),
                ),
              ),
            if (_section == 1 && _orders.isEmpty)
              Text(
                'msg_print_no_orders'.tr,
                style: const TextStyle(color: Colors.white70),
              ),
            if (_section == 2) const PrintEarningsCard(kind: 'shop'),
            if (_section == 3) ...[
              _ShopFact('lbl_print_shop_name'.tr, shop.name),
              if (shop.phone != null) _ShopFact('lbl_print_phone'.tr, shop.phone!),
              if (shop.address != null) _ShopFact('lbl_print_address'.tr, shop.address!),
              if (shop.district != null) _ShopFact('lbl_print_district'.tr, shop.district!),
              _ShopFact(
                'lbl_print_status_${shop.status}'.tr,
                shop.reviewNote ?? '',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopDesk extends StatelessWidget {
  const _ShopDesk({required this.shop, required this.orders});

  final PrintShopSummary shop;
  final List<PrintOrder> orders;

  @override
  Widget build(BuildContext context) {
    final waiting = orders.where((order) => order.status == 'quote').length;
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppDs.printGold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppDs.printGold,
                child: Text(
                  shop.name.isEmpty ? 'S' : shop.name.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      shop.verified
                          ? 'lbl_print_verified'.tr
                          : 'lbl_print_status_${shop.status}'.tr,
                      style: const TextStyle(color: AppDs.printGold),
                    ),
                  ],
                ),
              ),
              PrintLevelBadge(label: shop.levelLabel, labelAr: shop.levelLabelAr),
            ],
          ),
          if (shop.address != null) ...[
            SizedBox(height: 10.v),
            Text(shop.address!, style: const TextStyle(color: Colors.white70)),
          ],
          SizedBox(height: 14.v),
          Row(
            children: [
              _DeskStat('$waiting', 'lbl_print_incoming'.tr),
              _DeskStat(shop.rating.toStringAsFixed(1), 'lbl_print_verified_reviews'.tr),
              _DeskStat('${shop.completedOrders}', 'lbl_print_shop_orders'.tr),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeskStat extends StatelessWidget {
  const _DeskStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ShopFact extends StatelessWidget {
  const _ShopFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppDs.printGold)),
          if (value.isNotEmpty)
            Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class PrintShopDashboardScreen extends StatelessWidget {
  const PrintShopDashboardScreen({super.key});

  static Widget builder(BuildContext context) => const PrintShopHomeScreen();

  @override
  Widget build(BuildContext context) => const PrintShopHomeScreen();
}

class _ShopOrderCard extends StatefulWidget {
  const _ShopOrderCard({required this.order, required this.onChanged});

  final PrintOrder order;
  final VoidCallback onChanged;

  @override
  State<_ShopOrderCard> createState() => _ShopOrderCardState();
}

class _ShopOrderCardState extends State<_ShopOrderCard> {
  final _repo = PrintRepository();
  final _pickupCode = TextEditingController();
  final _shopPrice = TextEditingController();
  final _eta = TextEditingController(text: '24');
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _pickupCode.dispose();
    _shopPrice.dispose();
    _eta.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _quote() async {
    final price = double.tryParse(_shopPrice.text.trim());
    if (price == null || price <= 0) {
      showAppToast('lbl_print_shop_price'.tr, type: ToastificationType.error);
      return;
    }
    setState(() => _busy = true);
    final result = await _repo.createQuote(
      orderId: widget.order.id,
      shopTotal: price,
      etaHours: int.tryParse(_eta.text.trim()),
      note: _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    widget.onChanged();
  }

  Future<void> _advance(String action) async {
    setState(() => _busy = true);
    final result = await _repo.advance(orderId: widget.order.id, action: action);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    widget.onChanged();
  }

  Future<void> _verifyPickup() async {
    setState(() => _busy = true);
    final result = await _repo.verifyPickup(
      orderId: widget.order.id,
      code: _pickupCode.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintOrder>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Container(
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '#${order.number} · ${'lbl_print_status_${order.status}'.tr}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (order.designName != null)
            Text(order.designName!, style: const TextStyle(color: Colors.white70)),
          if (order.customerName != null)
            Text(order.customerName!, style: const TextStyle(color: Colors.white70)),
          if (order.systemTotal != null)
            Text(
              '${'lbl_print_system_price'.tr}: SAR ${order.systemTotal!.toStringAsFixed(2)}',
              style: const TextStyle(color: AppDs.printGold),
            ),
          if (order.status == 'quote') ...[
            TextField(
              controller: _shopPrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'lbl_print_shop_price'.tr),
            ),
            TextField(
              controller: _eta,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'lbl_print_eta_hours'.tr),
            ),
            TextField(
              controller: _note,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'lbl_print_note'.tr),
            ),
            PrintGoldButton(
              label: 'lbl_print_send_quote'.tr,
              loading: _busy,
              onPressed: _quote,
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final result = await _repo.declineRequest(order.id);
                      if (!mounted) return;
                      setState(() => _busy = false);
                      if (result is PrintFailure<PrintOrder>) {
                        showAppToast(result.message, type: ToastificationType.error);
                        return;
                      }
                      widget.onChanged();
                    },
              child: Text('lbl_print_decline'.tr),
            ),
          ],
          if (order.messages.any((message) => message.thread == 'customer_shop' && message.from != 'system'))
            Padding(
              padding: EdgeInsets.only(top: 8.v),
              child: Text(
                order.messages.lastWhere((message) => message.thread == 'customer_shop' && message.from != 'system').body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ),
          SizedBox(height: 8.v),
          OutlinedButton.icon(
            onPressed: () => NavigatorService.pushNamed(
              AppRoutes.printChatScreen,
              arguments: {
                'orderId': order.id,
                'thread': 'customer_shop',
                'viewer': 'shop',
              },
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: AppDs.printGold),
            label: Text('lbl_print_designer_chat'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppDs.printGold),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (order.delivery?.riderId != null)
            TextButton(
              onPressed: () => NavigatorService.pushNamed(
                AppRoutes.printChatScreen,
                arguments: {
                  'orderId': order.id,
                  'thread': 'shop_rider',
                  'viewer': 'shop',
                },
              ),
              child: Text('lbl_print_rider_chat'.tr),
            ),
          if (order.status == 'ready' && order.fulfillment == 'delivery' && order.delivery?.riderId == null)
            PrintGoldButton(
              label: 'lbl_print_request_rider'.tr,
              loading: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                final result = await _repo.requestRider(order.id);
                if (!mounted) return;
                setState(() => _busy = false);
                if (result is PrintFailure<PrintOrder>) {
                  showAppToast(result.message, type: ToastificationType.error);
                  return;
                }
                widget.onChanged();
              },
            ),
          if (order.nextAction != null && order.status != 'quote')
            Padding(
              padding: EdgeInsets.only(top: 8.v),
              child: PrintGoldButton(
                label: 'lbl_print_action_${order.nextAction}'.tr,
                loading: _busy,
                onPressed: () => _advance(order.nextAction!),
              ),
            ),
          if (order.status == 'ready') ...[
            SizedBox(height: 10.v),
            TextField(
              controller: _pickupCode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'lbl_print_pickup_code'.tr,
                labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
                filled: true,
                fillColor: AppDs.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 8.v),
            PrintGoldButton(
              label: 'lbl_print_verify_pickup'.tr,
              loading: _busy,
              onPressed: _verifyPickup,
            ),
          ],
          if (order.status == 'completed') ...[
            SizedBox(height: 8.v),
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
                    widget.onChanged();
                  },
                ),
              ),
            ),
          ],
          if (order.dispute != null) ...[
            SizedBox(height: 8.v),
            Text(
              '${'lbl_print_dispute_status'.tr}: ${'lbl_print_dispute_${order.dispute!.status}'.tr}',
              style: const TextStyle(color: AppDs.printGold),
            ),
            if (order.dispute!.isOpen)
              Padding(
                padding: EdgeInsets.only(top: 8.v),
                child: PrintGoldButton(
                  label: 'lbl_print_dispute_reply'.tr,
                  onPressed: () async {
                    await showPrintDisputeReplySheet(
                      context: context,
                      orderId: order.id,
                    );
                    widget.onChanged();
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
