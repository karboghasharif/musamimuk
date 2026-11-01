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
import 'print_shop_drawer.dart';
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
  List<PrintHourShift> _shifts = const [
    PrintHourShift(open: '09:00', close: '22:00'),
  ];
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
      hours: printHoursPayload(shifts: _shifts, days: _days),
      documents: docs,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is PrintFailure<PrintShopSummary>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    showAppToast('msg_print_kyc_submitted'.tr, type: ToastificationType.success);
    await applyWorkMode(PrefUtils.workModeShop);
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
    final shortLabels = [
      '1',
      '2',
      '3',
      '4',
      '5',
    ];
    return PrintScaffold(
      title: 'lbl_print_register_shop'.tr,
      showBack: false,
      actions: const [PrintModeButton()],
      bottom: PrintKycNavBar(
        canGoBack: _step > 1,
        primaryLabel: _step == _totalSteps
            ? 'lbl_print_submit'.tr
            : 'lbl_print_next'.tr,
        loading: _saving,
        onBack: () => setState(() => _step--),
        onPrimary: _next,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppDs.space5.h,
            AppDs.space4.v,
            AppDs.space5.h,
            AppDs.space4.v,
          ),
          children: [
            PrintKycStepHeader(
              step: _step,
              total: _totalSteps,
              title: titles[_step - 1],
              subtitle: _step == _totalSteps
                  ? 'msg_print_review_header'.tr
                  : 'msg_print_kyc_step_hint'.tr,
              stepLabels: shortLabels,
            ),
            if (_step == 1) ...[
              PrintKycTextField(
                controller: _name,
                label: 'lbl_print_shop_name'.tr,
                prefixIcon: Icons.storefront_outlined,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _nameAr,
                label: 'lbl_print_shop_name_ar'.tr,
                prefixIcon: Icons.translate_rounded,
              ),
              PrintKycTextField(
                controller: _owner,
                label: 'lbl_print_owner_name'.tr,
                prefixIcon: Icons.person_outline_rounded,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _phone,
                label: 'lbl_print_phone'.tr,
                prefixIcon: Icons.phone_outlined,
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
              PrintLocationPicker(
                latController: _lat,
                lngController: _lng,
                addressController: _address,
                districtController: _district,
                onChanged: () => setState(() {}),
              ),
              SizedBox(height: AppDs.space3.v),
              PrintKycTextField(
                controller: _address,
                label: 'lbl_print_address'.tr,
                prefixIcon: Icons.place_outlined,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _district,
                label: 'lbl_print_district'.tr,
                prefixIcon: Icons.map_outlined,
                validator: requiredText,
              ),
            ],
            if (_step == 3) ...[
              PrintKycTextField(
                controller: _cr,
                label: 'lbl_print_cr'.tr,
                prefixIcon: Icons.badge_outlined,
              ),
              PrintKycTextField(
                controller: _vat,
                label: 'lbl_print_vat'.tr,
                prefixIcon: Icons.receipt_long_outlined,
              ),
              PrintKycTextField(
                controller: _iban,
                label: 'lbl_print_iban'.tr,
                prefixIcon: Icons.account_balance_outlined,
                validator: saudiIbanText,
              ),
              PrintKycTextField(
                controller: _starting,
                label: 'lbl_print_starting_price'.tr,
                prefixIcon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: AppDs.space2.v),
              PrintHoursEditor(
                shifts: _shifts,
                days: _days,
                onShiftsChanged: (v) => setState(() => _shifts = v),
                onDaysChanged: (v) => setState(() => _days = v),
              ),
              SizedBox(height: AppDs.space3.v),
              PrintServicesChips(
                selected: _services,
                onChanged: (v) => setState(() => _services = v),
              ),
            ],
            if (_step == 4)
              PrintKycDocSection(
                requiredKinds: PrintKyc.shopRequiredKinds,
                optionalKinds: PrintKyc.shopOptionalKinds,
                docs: _docs,
                onPick: (kind) async {
                  final doc = await pickPrintKycFile(kind);
                  if (doc != null) setState(() => _docs[kind] = doc);
                },
                onClear: (kind) => setState(() => _docs[kind] = null),
              ),
            if (_step == 5) _buildReview(),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final attachedDocs =
        _docs.values.whereType<PrintPickedDoc>().toList(growable: false);
    final missingRequired = PrintKyc.shopRequiredKinds
        .where((k) => _docs[k] == null)
        .map((k) => PrintKyc.labelKey(k).tr)
        .toList();
    final dayLabels = (_days.toList()..sort())
        .map((d) => printDayLabels[d.clamp(0, 6)])
        .toList();
    final shiftLabels = _shifts
        .map((s) => '${s.open} – ${s.close}')
        .toList();
    final serviceLabels =
        _services.map((s) => s.replaceAll('_', ' ')).toList()..sort();
    final coords = [
      if (_lat.text.trim().isNotEmpty) _lat.text.trim(),
      if (_lng.text.trim().isNotEmpty) _lng.text.trim(),
    ].join(', ');

    return PrintKycReviewCard(
      children: [
        PrintKycReviewSection(
          title: 'lbl_print_step_business'.tr,
          icon: Icons.storefront_outlined,
          onEdit: () => setState(() => _step = 1),
          children: [
            PrintKycFactRow('lbl_print_shop_name'.tr, _name.text),
            if (_nameAr.text.trim().isNotEmpty)
              PrintKycFactRow('lbl_print_shop_name_ar'.tr, _nameAr.text),
            PrintKycFactRow('lbl_print_owner_name'.tr, _owner.text),
            PrintKycFactRow('lbl_print_phone'.tr, _phone.text),
            if (_about.text.trim().isNotEmpty)
              PrintKycFactRow(
                'lbl_print_about'.tr,
                _about.text,
                stacked: true,
              ),
          ],
        ),
        PrintKycReviewSection(
          title: 'lbl_print_step_location'.tr,
          icon: Icons.place_outlined,
          onEdit: () => setState(() => _step = 2),
          children: [
            PrintKycFactRow(
              'lbl_print_address'.tr,
              _address.text,
              stacked: true,
            ),
            PrintKycFactRow('lbl_print_district'.tr, _district.text),
            PrintKycFactRow('lbl_print_map_pin'.tr, coords, stacked: true),
          ],
        ),
        PrintKycReviewSection(
          title: 'lbl_print_step_commerce'.tr,
          icon: Icons.payments_outlined,
          onEdit: () => setState(() => _step = 3),
          children: [
            if (_cr.text.trim().isNotEmpty)
              PrintKycFactRow('lbl_print_cr'.tr, _cr.text),
            if (_vat.text.trim().isNotEmpty)
              PrintKycFactRow('lbl_print_vat'.tr, _vat.text),
            PrintKycFactRow('lbl_print_iban'.tr, _iban.text, stacked: true),
            if (_starting.text.trim().isNotEmpty)
              PrintKycFactRow(
                'lbl_print_starting_price'.tr,
                '${_starting.text.trim()} SAR',
              ),
            AppText('lbl_print_hours'.tr, variant: AppTextVariant.caption),
            SizedBox(height: AppDs.space1.v),
            PrintKycReviewChips(items: shiftLabels),
            AppText('lbl_print_open_days'.tr, variant: AppTextVariant.caption),
            SizedBox(height: AppDs.space1.v),
            PrintKycReviewChips(items: dayLabels),
            AppText('lbl_print_services'.tr, variant: AppTextVariant.caption),
            SizedBox(height: AppDs.space1.v),
            PrintKycReviewChips(
              items: serviceLabels,
              emptyLabel: 'msg_print_no_services_selected'.tr,
            ),
          ],
        ),
        PrintKycReviewSection(
          title: 'lbl_print_step_documents'.tr,
          icon: Icons.folder_outlined,
          onEdit: () => setState(() => _step = 4),
          children: [
            PrintKycFactRow(
              'lbl_print_documents'.tr,
              '${attachedDocs.length}',
            ),
            AppText(
              'lbl_print_docs_attached_list'.tr,
              variant: AppTextVariant.caption,
            ),
            SizedBox(height: AppDs.space2.v),
            PrintKycDocPreviewGrid(
              docs: attachedDocs,
              emptyLabel: 'msg_print_no_documents'.tr,
            ),
            if (missingRequired.isNotEmpty) ...[
              SizedBox(height: AppDs.space2.v),
              AppText(
                'msg_print_docs_missing_review'.tr,
                variant: AppTextVariant.caption,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: AppDs.space1.v),
              PrintKycReviewChips(items: missingRequired),
            ],
          ],
        ),
      ],
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
      await PrefUtils().setHasPrintShopProfile(false);
      if (!mounted) return;
      NavigatorService.pushReplacementNamed(AppRoutes.printShopRegisterScreen);
      return;
    }
    await PrefUtils().setHasPrintShopProfile(true);
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

  int get _quoteCount =>
      _orders.where((order) => order.status == 'quote').length;

  Future<void> _openOrderDetail(PrintOrder order) async {
    await NavigatorService.pushNamed(
      AppRoutes.printShopOrderDetailScreen,
      arguments: {'orderId': order.id},
    );
    if (mounted) await _refreshOrders();
  }

  void _openConversation(PrintOrder order) {
    NavigatorService.pushNamed(
      AppRoutes.printChatScreen,
      arguments: {
        'orderId': order.id,
        'thread': 'customer_shop',
        'viewer': 'shop',
      },
    );
  }

  String? _lastChatPreview(PrintOrder order) {
    final chats = order.messages
        .where(
          (m) => m.thread == 'customer_shop' && m.from != 'system',
        )
        .toList();
    if (chats.isEmpty) return null;
    return chats.last.body;
  }

  List<PrintOrder> get _conversationOrders {
    final active = _orders
        .where((o) => o.status != 'cancelled')
        .toList(growable: false);
    active.sort((a, b) {
      final aMs = a.messages.isEmpty ? 0 : a.messages.last.id;
      final bMs = b.messages.isEmpty ? 0 : b.messages.last.id;
      return bMs.compareTo(aMs);
    });
    return active;
  }

  String get _sectionTitle {
    switch (_section) {
      case 1:
        return 'lbl_print_shop_orders'.tr;
      case 2:
        return 'lbl_print_conversations'.tr;
      case 3:
        return 'lbl_print_earnings'.tr;
      case 4:
        return 'lbl_print_profile'.tr;
      default:
        return _shop?.name ?? 'lbl_print_shop_mode'.tr;
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppAtelierAtmosphere(),
            ListView(
              padding: EdgeInsets.fromLTRB(
                AppDs.space5.h,
                AppDs.space4.v,
                AppDs.space5.h,
                AppDs.space8.v,
              ),
              children: [
                if (shop == null)
                  Padding(
                    padding: EdgeInsets.only(top: AppDs.space8.v),
                    child: AppText(
                      'msg_print_register_prompt'.tr,
                      variant: AppTextVariant.secondary,
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  PrintKycStatusBanner(
                    status: shop.status,
                    reviewNote: shop.reviewNote,
                    onFixDocs: () => _uploadDocsSheet(shop),
                    onEdit: () => _editProfileSheet(shop),
                  ),
                  PrintDocumentList(documents: shop.documents),
                ],
                if (_orders.isNotEmpty) ...[
                  SizedBox(height: AppDs.space5.v),
                  ..._orders.map(
                    (order) => Padding(
                      padding: EdgeInsets.only(bottom: AppDs.space2.v),
                      child: Text(
                        '#${order.number} · ${order.customerName ?? ''} · ${'lbl_print_status_${order.status}'.tr}',
                        style: AppTypography.caption(Theme.of(context))
                            .copyWith(color: AppDs.textOnDarkSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
    return PrintScaffold(
      title: _sectionTitle,
      showBack: false,
      drawer: PrintShopDrawer(
        shopName: shop.name,
        section: _section,
        quoteCount: _quoteCount,
        onSelectSection: (index) => setState(() => _section = index),
      ),
      actions: [
        IconButton(
          tooltip: 'lbl_print_conversations'.tr,
          onPressed: () => setState(() => _section = 2),
          icon: Icon(
            Icons.forum_outlined,
            color: AppDs.atelierBrass,
            size: 22.adaptSize,
          ),
        ),
        const PrintModeButton(),
      ],
      bottom: NavigationBar(
        backgroundColor: AppDs.surfaceRaised,
        indicatorColor: AppDs.printGold.withValues(alpha: 0.25),
        selectedIndex: _section.clamp(0, 4),
        onDestinationSelected: (index) => setState(() => _section = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            label: 'lbl_home'.tr,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _quoteCount > 0,
              label: Text('$_quoteCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            label: 'lbl_print_nav_orders'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            label: 'lbl_print_nav_chat'.tr,
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
                padding: EdgeInsets.only(bottom: AppDs.space4.v),
                child: PrintNewJobBanner(
                  jobNumber: _banner!.number,
                  customerName: _banner!.customerName ??
                      _banner!.designName ??
                      'msg_print_new_request'.tr,
                  onOpen: () {
                    final order = _banner!;
                    setState(() => _banner = null);
                    _openOrderDetail(order);
                  },
                  onDismiss: () => setState(() => _banner = null),
                ),
              ),
            if (_section == 0) ...[
              _ShopDesk(shop: shop, orders: _orders),
              SizedBox(height: AppDs.space5.v),
              PrintSectionTitle('lbl_print_incoming'.tr),
              SizedBox(height: AppDs.space3.v),
              if (_orders.where((order) => order.status == 'quote').isEmpty)
                PrintEmptyWork(
                  icon: Icons.inbox_outlined,
                  title: 'msg_print_no_orders'.tr,
                  body: 'msg_print_shop_queue_empty'.tr,
                )
              else
                ..._orders.where((order) => order.status == 'quote').map(
                  (order) => Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: PrintOrderSlip(
                      order: order,
                      preview: _lastChatPreview(order),
                      onTap: () => _openOrderDetail(order),
                    ),
                  ),
                ),
            ],
            if (_section == 1) ...[
              PrintSectionTitle('lbl_print_shop_orders'.tr),
              SizedBox(height: AppDs.space1.v),
              Text(
                'msg_print_tap_order_detail'.tr,
                style: AppTypography.caption(Theme.of(context)).copyWith(
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              if (_orders.isEmpty)
                PrintEmptyWork(
                  icon: Icons.receipt_long_outlined,
                  title: 'msg_print_no_orders'.tr,
                  body: 'msg_print_shop_queue_empty'.tr,
                )
              else
                ..._orders.map(
                  (order) => Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: PrintOrderSlip(
                      order: order,
                      preview: _lastChatPreview(order),
                      onTap: () => _openOrderDetail(order),
                    ),
                  ),
                ),
            ],
            if (_section == 2) ...[
              PrintSectionTitle('lbl_print_conversations'.tr),
              SizedBox(height: AppDs.space1.v),
              Text(
                'msg_print_tap_conversation'.tr,
                style: AppTypography.caption(Theme.of(context)).copyWith(
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
              SizedBox(height: AppDs.space3.v),
              if (_conversationOrders.isEmpty)
                PrintEmptyWork(
                  icon: Icons.forum_outlined,
                  title: 'msg_print_no_chats'.tr,
                  body: 'msg_print_shop_chats_empty'.tr,
                )
              else
                ..._conversationOrders.map(
                  (order) => Padding(
                    padding: EdgeInsets.only(bottom: AppDs.space2.v),
                    child: PrintConversationSlip(
                      order: order,
                      peerName: order.customerName,
                      threadLabel: 'lbl_print_designer_chat'.tr,
                      onTap: () => _openConversation(order),
                    ),
                  ),
                ),
            ],
            if (_section == 3) const PrintEarningsCard(kind: 'shop'),
            if (_section == 4) ...[
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
              SizedBox(height: AppDs.space4.v),
              PrintDocumentList(documents: shop.documents),
              SizedBox(height: AppDs.space5.v),
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
    final picked = <String, PrintPickedDoc?>{
      for (final k in [
        ...PrintKyc.shopRequiredKinds,
        ...PrintKyc.shopOptionalKinds,
      ])
        k: null,
    };
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDs.atelierInk,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppDs.space4.h,
                right: AppDs.space4.h,
                top: AppDs.space4.v,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppDs.space4.v,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      'lbl_print_upload_docs'.tr,
                      variant: AppTextVariant.heading,
                    ),
                    if (shop.reviewNote != null && shop.reviewNote!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: AppDs.space2.v,
                          bottom: AppDs.space2.v,
                        ),
                        child: AppText(
                          shop.reviewNote!,
                          variant: AppTextVariant.secondary,
                          color: const Color(0xFFE8A54B),
                        ),
                      ),
                    SizedBox(height: AppDs.space3.v),
                    PrintKycDocSection(
                      requiredKinds: PrintKyc.shopRequiredKinds,
                      optionalKinds: PrintKyc.shopOptionalKinds,
                      docs: picked,
                      onPick: (kind) async {
                        final doc = await pickPrintKycFile(kind);
                        if (doc != null) setModal(() => picked[kind] = doc);
                      },
                      onClear: (kind) => setModal(() => picked[kind] = null),
                    ),
                    SizedBox(height: AppDs.space3.v),
                    AppPrimaryButton(
                      label: 'lbl_print_submit'.tr,
                      isLoading: saving,
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
    final place = [
      if (shop.address != null && shop.address!.trim().isNotEmpty) shop.address!,
      if (shop.district != null && shop.district!.trim().isNotEmpty)
        shop.district!,
    ].join(' · ');
    return PrintDeskHero(
      name: shop.name,
      statusLabel: shop.verified
          ? 'lbl_print_verified'.tr
          : 'lbl_print_status_${shop.status}'.tr,
      statusActive: shop.verified || shop.openNow,
      subtitle: place.isEmpty ? null : place,
      levelLabel: shop.levelLabel,
      levelLabelAr: shop.levelLabelAr,
      levelProgress: shop.levelProgress,
      leadingIcon: Icons.print_outlined,
      metrics: [
        ('$waiting', 'lbl_print_desk_waiting'.tr),
        (shop.rating.toStringAsFixed(1), 'lbl_print_desk_rating'.tr),
        ('${shop.completedOrders}', 'lbl_print_desk_done'.tr),
      ],
    );
  }
}

typedef _ShopFact = PrintKycFactRow;

class PrintShopDashboardScreen extends StatelessWidget {
  const PrintShopDashboardScreen({super.key});

  static Widget builder(BuildContext context) => const PrintShopHomeScreen();

  @override
  Widget build(BuildContext context) => const PrintShopHomeScreen();
}

class PrintShopOrderPanel extends StatefulWidget {
  const PrintShopOrderPanel({
    super.key,
    required this.order,
    required this.onChanged,
  });

  final PrintOrder order;
  final VoidCallback onChanged;

  @override
  State<PrintShopOrderPanel> createState() => _PrintShopOrderPanelState();
}

class _PrintShopOrderPanelState extends State<PrintShopOrderPanel> {
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

  Future<void> _decline() async {
    setState(() => _busy = true);
    final result = await _repo.declineRequest(widget.order.id);
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

  String get _subtitle {
    final order = widget.order;
    final parts = <String>[
      if (order.shopId == null && order.status == 'quote')
        'lbl_print_open_booking'.tr,
      if ((order.customerName ?? '').trim().isNotEmpty) order.customerName!.trim(),
      if ((order.fulfillment ?? '').isNotEmpty)
        order.fulfillment == 'delivery'
            ? 'lbl_print_deliver_to_me'.tr
            : 'lbl_print_pick_up'.tr,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final isQuote = order.status == 'quote';
    final lastChat = order.messages
        .where(
          (message) =>
              message.thread == 'customer_shop' && message.from != 'system',
        )
        .toList();

    return PrintJobTicket(
      jobNumber: order.number,
      statusLabel: 'lbl_print_status_${order.status}'.tr,
      title: order.designName,
      subtitle: _subtitle.isEmpty ? null : _subtitle,
      urgent: isQuote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.spec != null) ...[
            PrintSpecPills(spec: order.spec!),
            SizedBox(height: AppDs.space3.v),
          ],
          if ((order.spec?.notes ?? '').trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppDs.space3.h),
              decoration: BoxDecoration(
                color: AppDs.atelierBrass.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDs.radiusMd),
                border: Border.all(
                  color: AppDs.atelierBrass.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lbl_print_designer_notes'.tr,
                    style: AppTypography.caption(theme).copyWith(
                      color: AppDs.atelierBrass,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppDs.space1.v),
                  Text(
                    order.spec!.notes!.trim(),
                    style: AppTypography.secondary(theme).copyWith(
                      color: AppDs.textOnDarkPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDs.space3.v),
          ],
          if (order.systemTotal != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'lbl_print_system_guide_price'.tr,
                    style: AppTypography.caption(theme).copyWith(
                      color: AppDs.textOnDarkSecondary,
                    ),
                  ),
                ),
                Text(
                  printSar(order.systemTotal!),
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.atelierBrass,
                    fontWeight: FontWeight.w800,
                    fontSize: 18.fSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDs.space3.v),
          ],
          if (isQuote) ...[
            Container(
              padding: EdgeInsets.all(AppDs.space3.h),
              decoration: BoxDecoration(
                color: AppDs.atelierInk.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppDs.radiusMd),
                border: Border.all(color: AppDs.atelierHairline(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'lbl_print_quote_workbench'.tr,
                    style: AppTypography.body(theme).copyWith(
                      color: AppDs.textOnDarkPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppDs.space1.v),
                  Text(
                    'msg_print_quote_hint'.tr,
                    style: AppTypography.caption(theme).copyWith(
                      color: AppDs.textOnDarkSecondary,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: AppDs.space3.v),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _shopPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: AppDs.textOnDarkPrimary),
                          decoration: printTicketField('lbl_print_shop_price'.tr),
                        ),
                      ),
                      SizedBox(width: AppDs.space2.h),
                      Expanded(
                        child: TextField(
                          controller: _eta,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppDs.textOnDarkPrimary),
                          decoration: printTicketField('lbl_print_eta_hours'.tr),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDs.space2.v),
                  TextField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 3,
                    style: const TextStyle(color: AppDs.textOnDarkPrimary),
                    decoration: printTicketField('lbl_print_note'.tr),
                  ),
                  SizedBox(height: AppDs.space3.v),
                  PrintGoldButton(
                    label: 'lbl_print_send_quote'.tr,
                    loading: _busy,
                    onPressed: _quote,
                  ),
                  SizedBox(height: AppDs.space2.v),
                  PrintGhostButton(
                    label: 'lbl_print_decline'.tr,
                    onPressed: _busy ? null : _decline,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDs.space3.v),
          ],
          if (lastChat.isNotEmpty) ...[
            Text(
              lastChat.last.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(theme).copyWith(
                color: AppDs.textOnDarkSecondary,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
            SizedBox(height: AppDs.space3.v),
          ],
          if ((order.printFileUrl ?? '').isNotEmpty) ...[
            PrintGhostButton(
              label: 'lbl_print_download_file'.tr,
              icon: Icons.download_outlined,
              onPressed: () async {
                final uri = Uri.tryParse(order.printFileUrl!);
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            SizedBox(height: AppDs.space2.v),
          ],
          PrintGhostButton(
            label: 'lbl_print_designer_chat'.tr,
            icon: Icons.chat_bubble_outline,
            onPressed: () => NavigatorService.pushNamed(
              AppRoutes.printChatScreen,
              arguments: {
                'orderId': order.id,
                'thread': 'customer_shop',
                'viewer': 'shop',
              },
            ),
          ),
          if (order.delivery?.riderId != null) ...[
            SizedBox(height: AppDs.space2.v),
            PrintGhostButton(
              label: 'lbl_print_rider_chat'.tr,
              icon: Icons.two_wheeler_outlined,
              onPressed: () => NavigatorService.pushNamed(
                AppRoutes.printChatScreen,
                arguments: {
                  'orderId': order.id,
                  'thread': 'shop_rider',
                  'viewer': 'shop',
                },
              ),
            ),
          ],
          if (order.status == 'ready' &&
              order.fulfillment == 'delivery' &&
              order.delivery?.riderId == null) ...[
            SizedBox(height: AppDs.space3.v),
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
          ],
          if (order.nextAction != null && !isQuote) ...[
            SizedBox(height: AppDs.space3.v),
            PrintGoldButton(
              label: 'lbl_print_action_${order.nextAction}'.tr,
              loading: _busy,
              onPressed: () => _advance(order.nextAction!),
            ),
          ],
          if (order.status == 'ready') ...[
            SizedBox(height: AppDs.space3.v),
            TextField(
              controller: _pickupCode,
              style: const TextStyle(color: AppDs.textOnDarkPrimary),
              decoration: printTicketField('lbl_print_pickup_code'.tr),
            ),
            SizedBox(height: AppDs.space2.v),
            PrintGoldButton(
              label: 'lbl_print_verify_pickup'.tr,
              loading: _busy,
              onPressed: _verifyPickup,
            ),
          ],
          if (order.status == 'completed') ...[
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
                    widget.onChanged();
                  },
                ),
              ),
            ),
          ],
          if (order.dispute != null) ...[
            SizedBox(height: AppDs.space3.v),
            Text(
              '${'lbl_print_dispute_status'.tr}: ${'lbl_print_dispute_${order.dispute!.status}'.tr}',
              style: AppTypography.caption(theme).copyWith(
                color: AppDs.atelierBrass,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (order.dispute!.evidenceImages.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: AppDs.space2.v),
                child: SizedBox(
                  height: 64.adaptSize,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.dispute!.evidenceImages.length,
                    separatorBuilder: (_, _) => SizedBox(width: AppDs.space2.h),
                    itemBuilder: (context, index) {
                      final url = order.dispute!.evidenceImages[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppDs.radiusSm),
                        child: Image.network(
                          url,
                          width: 64.adaptSize,
                          height: 64.adaptSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 64.adaptSize,
                            height: 64.adaptSize,
                            color: AppDs.atelierHairline(0.08),
                            child: const Icon(
                              Icons.broken_image,
                              color: AppDs.textOnDarkSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (order.dispute!.isOpen)
              Padding(
                padding: EdgeInsets.only(top: AppDs.space2.v),
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

class PrintShopOrderDetailScreen extends StatefulWidget {
  const PrintShopOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final raw = args is Map ? args['orderId'] : null;
    final orderId = raw is int
        ? raw
        : raw is num
            ? raw.toInt()
            : int.tryParse('$raw') ?? 0;
    return PrintShopOrderDetailScreen(orderId: orderId);
  }

  @override
  State<PrintShopOrderDetailScreen> createState() =>
      _PrintShopOrderDetailScreenState();
}

class _PrintShopOrderDetailScreenState
    extends State<PrintShopOrderDetailScreen> {
  final _repo = PrintRepository();
  PrintOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.orderId <= 0) {
      setState(() {
        _loading = false;
        _error = 'msg_print_order_missing'.tr;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.order(widget.orderId);
    if (!mounted) return;
    if (result is PrintFailure<PrintOrder>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _order = (result as PrintSuccess<PrintOrder>).data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return PrintScaffold(
      title: order == null
          ? 'lbl_print_order_detail'.tr
          : '#${order.number}',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(16.h),
                children: [
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(top: AppDs.space8.v),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else if (order != null)
                    PrintShopOrderPanel(order: order, onChanged: _load),
                ],
              ),
            ),
    );
  }
}
