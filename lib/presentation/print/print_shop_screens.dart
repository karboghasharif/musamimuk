import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_earnings_card.dart';
import 'print_dispute_sheet.dart';
import 'print_review_sheet.dart';
import 'print_mode_switch.dart';
import 'print_live.dart';
import 'print_hours_services.dart';
import 'print_kyc_wizard.dart';
import 'print_location_picker.dart';
import 'print_ui.dart';

class PrintShopRegisterScreen extends StatefulWidget {
  const PrintShopRegisterScreen({super.key});

  static Widget builder(BuildContext context) => const PrintShopRegisterScreen();

  @override
  State<PrintShopRegisterScreen> createState() =>
      _PrintShopRegisterScreenState();
}

class _PrintShopRegisterScreenState extends State<PrintShopRegisterScreen> {
  static const _totalSteps = 5;

  final _repo = PrintRepository();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _about = TextEditingController();
  final _cr = TextEditingController();
  final _vat = TextEditingController();
  final _iban = TextEditingController();
  final _address = TextEditingController();
  final _district = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _starting = TextEditingController();
  final Map<String, PrintPickedDoc?> _docs = {
    for (final k in [
      ...PrintKyc.shopRequiredKinds,
      ...PrintKyc.shopOptionalKinds,
    ])
      k: null,
  };
  String _open = '09:00';
  String _close = '22:00';
  Set<int> _days = {0, 1, 2, 3, 4, 5, 6};
  Set<String> _services = {'digital'};
  int _step = 1;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _owner.dispose();
    _phone.dispose();
    _about.dispose();
    _cr.dispose();
    _vat.dispose();
    _iban.dispose();
    _address.dispose();
    _district.dispose();
    _lat.dispose();
    _lng.dispose();
    _starting.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 4) {
      for (final kind in PrintKyc.shopRequiredKinds) {
        if (_docs[kind] == null) {
          showAppToast('msg_print_docs_required'.tr, type: ToastificationType.error);
          return false;
        }
      }
      return true;
    }
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step == 2) {
      await fillDebugLocationIfEmpty(lat: _lat, lng: _lng);
      if (_lat.text.trim().isEmpty || _lng.text.trim().isEmpty) {
        showAppToast('msg_print_location_required'.tr, type: ToastificationType.error);
        return;
      }
    }
    if (_step < _totalSteps) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final docs = _docs.values.whereType<PrintPickedDoc>().toList();
    final result = await _repo.registerShop(
      name: _name.text.trim(),
      nameAr: _nameAr.text.trim().isEmpty ? null : _nameAr.text.trim(),
      ownerName: _owner.text.trim(),
      phone: _phone.text.trim(),
      about: _about.text.trim().isEmpty ? null : _about.text.trim(),
      crNumber: _cr.text.trim().isEmpty ? null : _cr.text.trim(),
      vatNumber: _vat.text.trim().isEmpty ? null : _vat.text.trim(),
      iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
      lat: double.tryParse(_lat.text.trim()),
      lng: double.tryParse(_lng.text.trim()),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
      startingPrice: double.tryParse(_starting.text.trim()),
      services: _services.toList(),
      hours: {
        'open': _open,
        'close': _close,
        'days': _days.toList()..sort(),
      },
      documents: docs,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is PrintFailure<PrintShopSummary>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    showAppToast('msg_print_kyc_submitted'.tr, type: ToastificationType.success);
    NavigatorService.pushReplacementNamed(AppRoutes.printShopHomeScreen);
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'lbl_print_step_business'.tr,
      'lbl_print_step_location'.tr,
      'lbl_print_step_commerce'.tr,
      'lbl_print_step_documents'.tr,
      'lbl_print_step_review'.tr,
    ];
    return PrintScaffold(
      title: 'lbl_print_register_shop'.tr,
      showBack: false,
      actions: const [PrintModeButton()],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.h),
          children: [
            PrintKycStepHeader(
              step: _step,
              total: _totalSteps,
              title: titles[_step - 1],
            ),
            if (_step == 1) ...[
              PrintKycTextField(
                controller: _name,
                label: 'lbl_print_shop_name'.tr,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _nameAr,
                label: 'lbl_print_shop_name_ar'.tr,
              ),
              PrintKycTextField(
                controller: _owner,
                label: 'lbl_print_owner_name'.tr,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _phone,
                label: 'lbl_print_phone'.tr,
                keyboardType: TextInputType.phone,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _about,
                label: 'lbl_print_about'.tr,
                maxLines: 3,
              ),
            ],
            if (_step == 2) ...[
              PrintKycTextField(
                controller: _address,
                label: 'lbl_print_address'.tr,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _district,
                label: 'lbl_print_district'.tr,
                validator: requiredText,
              ),
              PrintLocationPicker(
                latController: _lat,
                lngController: _lng,
                onChanged: () => setState(() {}),
              ),
            ],
            if (_step == 3) ...[
              PrintKycTextField(controller: _cr, label: 'lbl_print_cr'.tr),
              PrintKycTextField(controller: _vat, label: 'lbl_print_vat'.tr),
              PrintKycTextField(
                controller: _iban,
                label: 'lbl_print_iban'.tr,
                validator: saudiIbanText,
              ),
              PrintKycTextField(
                controller: _starting,
                label: 'lbl_print_starting_price'.tr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 8.v),
              PrintHoursEditor(
                open: _open,
                close: _close,
                days: _days,
                onOpenChanged: (v) => setState(() => _open = v),
                onCloseChanged: (v) => setState(() => _close = v),
                onDaysChanged: (v) => setState(() => _days = v),
              ),
              SizedBox(height: 12.v),
              PrintServicesChips(
                selected: _services,
                onChanged: (v) => setState(() => _services = v),
              ),
            ],
            if (_step == 4)
              ..._docs.keys.map(
                (kind) => PrintKycDocSlot(
                  kind: kind,
                  required: PrintKyc.shopRequiredKinds.contains(kind),
                  picked: _docs[kind],
                  onPick: () async {
                    final doc = await pickPrintKycFile(kind);
                    if (doc != null) setState(() => _docs[kind] = doc);
                  },
                  onClear: () => setState(() => _docs[kind] = null),
                ),
              ),
            if (_step == 5) ...[
              _ShopFact('lbl_print_shop_name'.tr, _name.text),
              _ShopFact('lbl_print_owner_name'.tr, _owner.text),
              _ShopFact('lbl_print_phone'.tr, _phone.text),
              _ShopFact('lbl_print_address'.tr, _address.text),
              _ShopFact('lbl_print_iban'.tr, _iban.text),
              _ShopFact(
                'lbl_print_documents'.tr,
                '${_docs.values.whereType<PrintPickedDoc>().length}',
              ),
            ],
            SizedBox(height: 16.v),
            Row(
              children: [
                if (_step > 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 48),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Text(
                        'lbl_print_back'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (_step > 1) SizedBox(width: 12.h),
                Expanded(
                  flex: 2,
                  child: PrintGoldButton(
                    label: _step == _totalSteps
                        ? 'lbl_print_submit'.tr
                        : 'lbl_print_next'.tr,
                    loading: _saving,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refreshOrders());
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
      return PrintScaffold(
        title: 'lbl_print_shop_mode'.tr,
        showBack: false,
        actions: const [PrintModeButton()],
        body: ListView(
          padding: EdgeInsets.all(24.h),
          children: [
            if (shop == null)
              Text(
                'msg_print_register_prompt'.tr,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              )
            else ...[
              PrintKycStatusBanner(
                status: shop.status,
                reviewNote: shop.reviewNote,
                onFixDocs: () => _uploadDocsSheet(shop),
                onEdit: () => _editProfileSheet(shop),
              ),
              Text(
                'lbl_print_documents'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.v),
              PrintDocumentList(documents: shop.documents),
            ],
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
              if (shop.needsKycAction)
                PrintKycStatusBanner(
                  status: shop.status,
                  reviewNote: shop.reviewNote,
                  onFixDocs: () => _uploadDocsSheet(shop),
                  onEdit: () => _editProfileSheet(shop),
                ),
              _ShopFact('lbl_print_shop_name'.tr, shop.name),
              if (shop.ownerName != null)
                _ShopFact('lbl_print_owner_name'.tr, shop.ownerName!),
              if (shop.phone != null) _ShopFact('lbl_print_phone'.tr, shop.phone!),
              if (shop.address != null)
                _ShopFact('lbl_print_address'.tr, shop.address!),
              if (shop.district != null)
                _ShopFact('lbl_print_district'.tr, shop.district!),
              if (shop.iban != null) _ShopFact('lbl_print_iban'.tr, shop.iban!),
              if (shop.crNumber != null) _ShopFact('lbl_print_cr'.tr, shop.crNumber!),
              SizedBox(height: 12.v),
              Text(
                'lbl_print_documents'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              PrintDocumentList(documents: shop.documents),
              SizedBox(height: 16.v),
              Text(
                'lbl_print_portfolio'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.v),
              if (shop.portfolio.isEmpty)
                Text(
                  'msg_print_notices_empty'.tr,
                  style: const TextStyle(color: Colors.white54),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shop.portfolio
                      .map(
                        (item) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrl == null
                                  ? Container(
                                      width: 88,
                                      height: 88,
                                      color: Colors.white12,
                                    )
                                  : Image.network(
                                      item.imageUrl!,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: () async {
                                  final result =
                                      await _repo.deleteShopPortfolio(item.id);
                                  if (result is PrintFailure<PrintShopSummary>) {
                                    showAppToast(
                                      result.message,
                                      type: ToastificationType.error,
                                    );
                                    return;
                                  }
                                  _load();
                                },
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              SizedBox(height: 10.v),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked == null) return;
                  final result = await _repo.addShopPortfolio(
                    imagePath: picked.path,
                  );
                  if (result is PrintFailure<PrintShopSummary>) {
                    showAppToast(result.message, type: ToastificationType.error);
                    return;
                  }
                  _load();
                },
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    color: AppDs.printGold),
                label: Text(
                  'lbl_print_add_portfolio'.tr,
                  style: const TextStyle(color: AppDs.printGold),
                ),
              ),
              SizedBox(height: 16.v),
              PrintGoldButton(
                label: 'lbl_print_edit_profile'.tr,
                onPressed: () => _editProfileSheet(shop),
              ),
              SizedBox(height: 10.v),
              OutlinedButton(
                onPressed: () => _uploadDocsSheet(shop),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppDs.printGold),
                ),
                child: Text(
                  'lbl_print_upload_docs'.tr,
                  style: const TextStyle(color: AppDs.printGold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editProfileSheet(PrintShopSummary shop) async {
    final name = TextEditingController(text: shop.name);
    final phone = TextEditingController(text: shop.phone ?? '');
    final address = TextEditingController(text: shop.address ?? '');
    final district = TextEditingController(text: shop.district ?? '');
    final about = TextEditingController(text: shop.about ?? '');
    final iban = TextEditingController(text: shop.iban ?? '');
    final lat = TextEditingController(text: shop.lat?.toString() ?? '');
    final lng = TextEditingController(text: shop.lng?.toString() ?? '');
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDs.surfaceRaised,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.h,
                right: 16.h,
                top: 16.v,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16.v,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'lbl_print_edit_profile'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 12.v),
                    PrintKycTextField(controller: name, label: 'lbl_print_shop_name'.tr),
                    PrintKycTextField(controller: phone, label: 'lbl_print_phone'.tr),
                    PrintKycTextField(controller: address, label: 'lbl_print_address'.tr),
                    PrintKycTextField(controller: district, label: 'lbl_print_district'.tr),
                    PrintKycTextField(controller: iban, label: 'lbl_print_iban'.tr),
                    PrintKycTextField(controller: about, label: 'lbl_print_about'.tr, maxLines: 3),
                    PrintKycTextField(controller: lat, label: 'lbl_print_lat'.tr),
                    PrintKycTextField(controller: lng, label: 'lbl_print_lng'.tr),
                    PrintGoldButton(
                      label: 'lbl_print_save'.tr,
                      loading: saving,
                      onPressed: () async {
                        if (saving) return;
                        setModal(() => saving = true);
                        final result = await _repo.updateShop({
                          'name': name.text.trim(),
                          'phone': phone.text.trim(),
                          'address': address.text.trim(),
                          'district': district.text.trim(),
                          'about': about.text.trim(),
                          'iban': iban.text.trim(),
                          if (double.tryParse(lat.text.trim()) != null)
                            'lat': double.parse(lat.text.trim()),
                          if (double.tryParse(lng.text.trim()) != null)
                            'lng': double.parse(lng.text.trim()),
                        });
                        if (!mounted) return;
                        setModal(() => saving = false);
                        if (result is PrintFailure<PrintShopSummary>) {
                          showAppToast(
                            result.message,
                            type: ToastificationType.error,
                          );
                          return;
                        }
                        showAppToast(
                          'msg_print_profile_saved'.tr,
                          type: ToastificationType.success,
                        );
                        Navigator.pop(ctx);
                        _load();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    name.dispose();
    phone.dispose();
    address.dispose();
    district.dispose();
    about.dispose();
    iban.dispose();
    lat.dispose();
    lng.dispose();
  }

  Future<void> _uploadDocsSheet(PrintShopSummary shop) async {
    final kinds = [
      ...PrintKyc.shopRequiredKinds,
      ...PrintKyc.shopOptionalKinds,
    ];
    final picked = <String, PrintPickedDoc?>{for (final k in kinds) k: null};
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDs.surfaceRaised,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.h,
                right: 16.h,
                top: 16.v,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16.v,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'lbl_print_upload_docs'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (shop.reviewNote != null && shop.reviewNote!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.v, bottom: 8.v),
                        child: Text(
                          shop.reviewNote!,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    ...kinds.map(
                      (kind) => PrintKycDocSlot(
                        kind: kind,
                        required: false,
                        picked: picked[kind],
                        onPick: () async {
                          final doc = await pickPrintKycFile(kind);
                          if (doc != null) setModal(() => picked[kind] = doc);
                        },
                        onClear: () => setModal(() => picked[kind] = null),
                      ),
                    ),
                    PrintGoldButton(
                      label: 'lbl_print_submit'.tr,
                      loading: saving,
                      onPressed: () async {
                        final docs =
                            picked.values.whereType<PrintPickedDoc>().toList();
                        if (docs.isEmpty) {
                          showAppToast(
                            'msg_print_docs_required'.tr,
                            type: ToastificationType.error,
                          );
                          return;
                        }
                        setModal(() => saving = true);
                        final result = await _repo.uploadShopDocuments(docs);
                        if (!mounted) return;
                        setModal(() => saving = false);
                        if (result is PrintFailure<PrintShopSummary>) {
                          showAppToast(
                            result.message,
                            type: ToastificationType.error,
                          );
                          return;
                        }
                        showAppToast(
                          'msg_print_docs_uploaded'.tr,
                          type: ToastificationType.success,
                        );
                        Navigator.pop(ctx);
                        _load();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          if ((order.printFileUrl ?? '').isNotEmpty) ...[
            SizedBox(height: 8.v),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(order.printFileUrl!);
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.download_outlined, color: AppDs.printGold),
              label: Text('lbl_print_download_file'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppDs.printGold),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
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
            if (order.dispute!.evidenceImages.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.v),
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.dispute!.evidenceImages.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.h),
                    itemBuilder: (context, index) {
                      final url = order.dispute!.evidenceImages[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: Colors.white12,
                            child: const Icon(Icons.broken_image, color: Colors.white54),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
