import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_review_sheet.dart';
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
      setState(() {
        _shop = null;
        _loading = false;
      });
      return;
    }
    final ordersResult = await _repo.shopOrders();
    if (!mounted) return;
    setState(() {
      _shop = shop;
      _orders = ordersResult is PrintSuccess<List<PrintOrder>>
          ? ordersResult.data
          : const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PrintScaffold(
        title: 'lbl_print_shop_mode'.tr,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_shop == null) {
      return PrintScaffold(
        title: 'lbl_print_shop_mode'.tr,
        body: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'msg_print_register_prompt'.tr,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.v),
              PrintGoldButton(
                label: 'lbl_print_register_shop'.tr,
                onPressed: () => NavigatorService.pushNamed(
                  AppRoutes.printShopRegisterScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_shop!.status == 'pending') {
      return PrintScaffold(
        title: 'lbl_print_shop_mode'.tr,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: Text(
              'msg_print_shop_pending'.tr,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return PrintScaffold(
      title: _shop!.name,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.all(16.h),
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            Text(
              _shop!.verified
                  ? 'lbl_print_verified'.tr
                  : 'lbl_print_status_${_shop!.status}'.tr,
              style: const TextStyle(color: AppDs.printGold),
            ),
            PrintLevelBadge(
              label: _shop!.levelLabel,
              labelAr: _shop!.levelLabelAr,
            ),
            if (_shop!.levelProgress?.hint != null)
              Padding(
                padding: EdgeInsets.only(top: 6.v, bottom: 12.v),
                child: Text(
                  _shop!.levelProgress!.hint!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ..._orders.map(
              (order) => Padding(
                padding: EdgeInsets.only(bottom: 10.v),
                child: _ShopOrderCard(order: order, onChanged: _load),
              ),
            ),
          ],
        ),
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
  bool _busy = false;

  @override
  void dispose() {
    _pickupCode.dispose();
    super.dispose();
  }

  Future<void> _quote() async {
    setState(() => _busy = true);
    final result = await _repo.createQuote(orderId: widget.order.id);
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
          if (order.status == 'quote')
            PrintGoldButton(
              label: 'lbl_print_send_quote'.tr,
              loading: _busy,
              onPressed: _quote,
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
        ],
      ),
    );
  }
}
