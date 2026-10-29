import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_earnings_card.dart';
import 'print_review_sheet.dart';
import 'print_mode_switch.dart';
import 'print_live.dart';
import 'print_kyc_wizard.dart';
import 'print_location_picker.dart';
import 'print_ui.dart';

class PrintRiderHomeScreen extends StatefulWidget {
  const PrintRiderHomeScreen({super.key});

  static Widget builder(BuildContext context) => const PrintRiderHomeScreen();

  @override
  State<PrintRiderHomeScreen> createState() => _PrintRiderHomeScreenState();
}

class _PrintRiderHomeScreenState extends State<PrintRiderHomeScreen> {
  final _repo = PrintRepository();
  PrintRiderProfile? _rider;
  List<PrintDeliveryInfo> _jobs = const [];
  List<PrintReview> _reviews = const [];
  bool _loading = true;
  bool _togglingOnline = false;
  int _section = 0;
  Timer? _poll;
  Timer? _locationPing;
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
    _locationPing?.cancel();
    _stopLive?.call();
    super.dispose();
  }

  void _syncLocationPing(bool online) {
    _locationPing?.cancel();
    _locationPing = null;
    if (!online) return;
    _locationPing = Timer.periodic(const Duration(seconds: 60), (_) async {
      final fix = await printAcquireGps();
      if (fix == null || !mounted) return;
      await _repo.setRiderOnline(online: true, lat: fix.lat, lng: fix.lng);
    });
  }

  Future<void> _load() async {
    final riderResult = await _repo.myRider();
    if (!mounted) return;
    if (riderResult is PrintFailure<PrintRiderProfile?>) {
      setState(() => _loading = false);
      return;
    }
    final rider = (riderResult as PrintSuccess<PrintRiderProfile?>).data;
    if (rider == null) {
      if (!mounted) return;
      NavigatorService.pushReplacementNamed(AppRoutes.printRiderRegisterScreen);
      return;
    }
    var jobs = const <PrintDeliveryInfo>[];
    if (rider.isApproved) {
      final jobsResult = await _repo.riderJobs();
      if (jobsResult is PrintSuccess<List<PrintDeliveryInfo>>) {
        jobs = jobsResult.data;
      }
    }
    List<PrintReview> reviews = const [];
    final reviewResult = await _repo.riderReviews(rider.id);
    if (reviewResult is PrintSuccess<List<PrintReview>>) {
      reviews = reviewResult.data;
    }
    if (!mounted) return;
    setState(() {
      _rider = rider;
      _jobs = jobs;
      _reviews = reviews;
      _loading = false;
    });
    _syncLocationPing(rider.online);
  }

  Future<void> _toggleOnline(bool online) async {
    if (_togglingOnline) return;
    setState(() => _togglingOnline = true);
    double? lat;
    double? lng;
    if (online) {
      final fix = await printAcquireGps();
      if (fix == null) {
        if (mounted) setState(() => _togglingOnline = false);
        return;
      }
      lat = fix.lat;
      lng = fix.lng;
    }
    final result = await _repo.setRiderOnline(
      online: online,
      lat: lat,
      lng: lng,
    );
    if (!mounted) return;
    setState(() => _togglingOnline = false);
    if (result is PrintFailure<PrintRiderProfile>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    final rider = (result as PrintSuccess<PrintRiderProfile>).data;
    setState(() => _rider = rider);
    _syncLocationPing(rider.online);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PrintScaffold(
        title: 'lbl_print_rider_mode'.tr,
        showBack: false,
        actions: const [PrintModeButton()],
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final rider = _rider;
    if (rider == null || !rider.isApproved) {
      return PrintScaffold(
        title: 'lbl_print_rider_mode'.tr,
        showBack: false,
        actions: const [PrintModeButton()],
        body: ListView(
          padding: EdgeInsets.all(24.h),
          children: [
            if (rider == null)
              Text(
                'msg_print_register_rider'.tr,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              )
            else ...[
              PrintKycStatusBanner(
                status: rider.status,
                reviewNote: rider.reviewNote,
                onFixDocs: () => _uploadDocsSheet(rider),
                onEdit: () => _editProfileSheet(rider),
              ),
              PrintDocumentList(documents: rider.documents),
            ],
          ],
        ),
      );
    }
    return PrintScaffold(
      title: rider.name,
      showBack: false,
      actions: const [PrintModeButton()],
      bottom: NavigationBar(
        backgroundColor: AppDs.surfaceRaised,
        indicatorColor: AppDs.printGold.withValues(alpha: 0.25),
        selectedIndex: _section,
        onDestinationSelected: (index) => setState(() => _section = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: 'lbl_home'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            label: 'lbl_print_jobs'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.wifi_tethering),
            label: 'lbl_print_online'.tr,
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
            if (_section == 0) ...[
              PrintLevelBadge(label: rider.levelLabel, labelAr: rider.levelLabelAr),
              if (rider.levelProgress?.hint != null)
                Padding(
                  padding: EdgeInsets.only(top: 6.v, bottom: 12.v),
                  child: Text(
                    rider.levelProgress!.hint!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              Text(
                'lbl_print_verified_reviews'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.v),
              PrintVerifiedReviewList(reviews: _reviews),
            ],
            if (_section == 1)
              ..._jobs.map(
                (job) => Padding(
                  padding: EdgeInsets.only(bottom: 10.v),
                  child: _RiderJobCard(job: job, onChanged: _load),
                ),
              ),
            if (_section == 2)
              SwitchListTile(
                value: rider.online,
                activeThumbColor: AppDs.printGold,
                title: Text(
                  'lbl_print_online'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
                onChanged: _toggleOnline,
              ),
            if (_section == 3) const PrintEarningsCard(kind: 'rider'),
            if (_section == 4) ...[
              if (rider.needsKycAction)
                PrintKycStatusBanner(
                  status: rider.status,
                  reviewNote: rider.reviewNote,
                  onFixDocs: () => _uploadDocsSheet(rider),
                  onEdit: () => _editProfileSheet(rider),
                ),
              _RiderFact('lbl_print_owner_name'.tr, rider.name),
              _RiderFact('lbl_print_phone'.tr, rider.phone),
              if (rider.nationalId != null)
                _RiderFact('lbl_print_national_id'.tr, rider.nationalId!),
              if (rider.vehicle != null)
                _RiderFact('lbl_print_vehicle'.tr, rider.vehicle!),
              if (rider.plate != null)
                _RiderFact('lbl_print_plate'.tr, rider.plate!),
              if (rider.iban != null)
                _RiderFact('lbl_print_iban'.tr, rider.iban!),
              if (rider.district != null)
                _RiderFact('lbl_print_district'.tr, rider.district!),
              SizedBox(height: 12.v),
              PrintDocumentList(documents: rider.documents),
              SizedBox(height: 16.v),
              PrintGoldButton(
                label: 'lbl_print_edit_profile'.tr,
                onPressed: () => _editProfileSheet(rider),
              ),
              SizedBox(height: 10.v),
              OutlinedButton(
                onPressed: () => _uploadDocsSheet(rider),
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

  Future<void> _editProfileSheet(PrintRiderProfile rider) async {
    final name = TextEditingController(text: rider.name);
    final phone = TextEditingController(text: rider.phone);
    final vehicle = TextEditingController(text: rider.vehicle ?? '');
    final plate = TextEditingController(text: rider.plate ?? '');
    final iban = TextEditingController(text: rider.iban ?? '');
    final district = TextEditingController(text: rider.district ?? '');
    final lat = TextEditingController(text: rider.lat?.toString() ?? '');
    final lng = TextEditingController(text: rider.lng?.toString() ?? '');
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
                    PrintKycTextField(controller: name, label: 'lbl_print_owner_name'.tr),
                    PrintKycTextField(controller: phone, label: 'lbl_print_phone'.tr),
                    PrintKycTextField(controller: vehicle, label: 'lbl_print_vehicle'.tr),
                    PrintKycTextField(controller: plate, label: 'lbl_print_plate'.tr),
                    PrintKycTextField(controller: iban, label: 'lbl_print_iban'.tr),
                    PrintKycTextField(controller: district, label: 'lbl_print_district'.tr),
                    PrintKycTextField(controller: lat, label: 'lbl_print_lat'.tr),
                    PrintKycTextField(controller: lng, label: 'lbl_print_lng'.tr),
                    PrintGoldButton(
                      label: 'lbl_print_save'.tr,
                      loading: saving,
                      onPressed: () async {
                        setModal(() => saving = true);
                        final result = await _repo.updateRider({
                          'name': name.text.trim(),
                          'phone': phone.text.trim(),
                          'vehicle': vehicle.text.trim(),
                          'plate': plate.text.trim(),
                          'iban': iban.text.trim(),
                          'district': district.text.trim(),
                          if (double.tryParse(lat.text.trim()) != null)
                            'lat': double.parse(lat.text.trim()),
                          if (double.tryParse(lng.text.trim()) != null)
                            'lng': double.parse(lng.text.trim()),
                        });
                        if (!mounted) return;
                        setModal(() => saving = false);
                        if (result is PrintFailure<PrintRiderProfile>) {
                          showAppToast(result.message, type: ToastificationType.error);
                          return;
                        }
                        showAppToast('msg_print_profile_saved'.tr, type: ToastificationType.success);
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
    vehicle.dispose();
    plate.dispose();
    iban.dispose();
    district.dispose();
    lat.dispose();
    lng.dispose();
  }

  Future<void> _uploadDocsSheet(PrintRiderProfile rider) async {
    final kinds = [
      ...PrintKyc.riderRequiredKinds,
      ...PrintKyc.riderOptionalKinds,
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
                        final result = await _repo.uploadRiderDocuments(docs);
                        if (!mounted) return;
                        setModal(() => saving = false);
                        if (result is PrintFailure<PrintRiderProfile>) {
                          showAppToast(result.message, type: ToastificationType.error);
                          return;
                        }
                        showAppToast('msg_print_docs_uploaded'.tr, type: ToastificationType.success);
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

class _RiderFact extends StatelessWidget {
  const _RiderFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.v),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.h,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class PrintRiderRegisterScreen extends StatefulWidget {
  const PrintRiderRegisterScreen({super.key});

  static Widget builder(BuildContext context) =>
      const PrintRiderRegisterScreen();

  @override
  State<PrintRiderRegisterScreen> createState() =>
      _PrintRiderRegisterScreenState();
}

class _PrintRiderRegisterScreenState extends State<PrintRiderRegisterScreen> {
  static const _totalSteps = 5;

  final _repo = PrintRepository();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _vehicle = TextEditingController();
  final _plate = TextEditingController();
  final _iban = TextEditingController();
  final _district = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final Set<String> _areas = {};
  List<PrintDeliveryArea> _areaChoices = const [];
  final Map<String, PrintPickedDoc?> _docs = {
    for (final k in [
      ...PrintKyc.riderRequiredKinds,
      ...PrintKyc.riderOptionalKinds,
    ])
      k: null,
  };
  int _step = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    final result = await _repo.deliveryAreas();
    if (!mounted) return;
    if (result is PrintSuccess<List<PrintDeliveryArea>>) {
      setState(() => _areaChoices = result.data);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _vehicle.dispose();
    _plate.dispose();
    _iban.dispose();
    _district.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 2) {
      if (!(_formKey.currentState?.validate() ?? false)) return false;
      if (_areas.isEmpty) {
        showAppToast('msg_print_areas_required'.tr, type: ToastificationType.error);
        return false;
      }
      return true;
    }
    if (_step == 4) {
      for (final kind in PrintKyc.riderRequiredKinds) {
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
    if (_step == 3) {
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
    if (_areas.isEmpty) {
      showAppToast('msg_print_areas_required'.tr, type: ToastificationType.error);
      return;
    }
    setState(() => _saving = true);
    final result = await _repo.registerRider(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      nationalId:
          _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
      vehicle: _vehicle.text.trim().isEmpty ? null : _vehicle.text.trim(),
      plate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
      iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
      lat: double.tryParse(_lat.text.trim()),
      lng: double.tryParse(_lng.text.trim()),
      areas: _areas.toList(),
      documents: _docs.values.whereType<PrintPickedDoc>().toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is PrintFailure<PrintRiderProfile>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    showAppToast('msg_print_kyc_submitted'.tr, type: ToastificationType.success);
    NavigatorService.pushReplacementNamed(AppRoutes.printRiderHomeScreen);
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'lbl_print_step_identity'.tr,
      'lbl_print_step_vehicle'.tr,
      'lbl_print_step_payout'.tr,
      'lbl_print_step_documents'.tr,
      'lbl_print_step_review'.tr,
    ];
    return PrintScaffold(
      title: 'lbl_print_register_rider'.tr,
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
                controller: _nationalId,
                label: 'lbl_print_national_id'.tr,
                validator: requiredText,
              ),
            ],
            if (_step == 2) ...[
              PrintKycTextField(
                controller: _vehicle,
                label: 'lbl_print_vehicle'.tr,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _plate,
                label: 'lbl_print_plate'.tr,
                validator: requiredText,
              ),
              PrintKycTextField(
                controller: _district,
                label: 'lbl_print_district'.tr,
                validator: requiredText,
              ),
              Text(
                'lbl_print_service_areas'.tr,
                style: const TextStyle(color: Colors.white70),
              ),
              if (_areaChoices.isEmpty)
                Text(
                  'msg_print_areas_loading'.tr,
                  style: const TextStyle(color: Colors.white54),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _areaChoices
                      .map(
                        (area) => FilterChip(
                          label: Text(area.label),
                          selected: _areas.contains(area.code),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _areas.add(area.code);
                              } else {
                                _areas.remove(area.code);
                              }
                            });
                          },
                          selectedColor: AppDs.printGold,
                          labelStyle: TextStyle(
                            color: _areas.contains(area.code)
                                ? Colors.black
                                : Colors.white,
                          ),
                          backgroundColor: AppDs.surfaceRaised,
                        ),
                      )
                      .toList(),
                ),
            ],
            if (_step == 3) ...[
              PrintKycTextField(
                controller: _iban,
                label: 'lbl_print_iban'.tr,
                validator: saudiIbanText,
              ),
              PrintLocationPicker(
                latController: _lat,
                lngController: _lng,
                onChanged: () => setState(() {}),
              ),
            ],
            if (_step == 4)
              ..._docs.keys.map(
                (kind) => PrintKycDocSlot(
                  kind: kind,
                  required: PrintKyc.riderRequiredKinds.contains(kind),
                  picked: _docs[kind],
                  onPick: () async {
                    final doc = await pickPrintKycFile(kind);
                    if (doc != null) setState(() => _docs[kind] = doc);
                  },
                  onClear: () => setState(() => _docs[kind] = null),
                ),
              ),
            if (_step == 5) ...[
              _RiderFact('lbl_print_owner_name'.tr, _name.text),
              _RiderFact('lbl_print_phone'.tr, _phone.text),
              _RiderFact('lbl_print_vehicle'.tr, _vehicle.text),
              _RiderFact('lbl_print_iban'.tr, _iban.text),
              _RiderFact(
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
                      onPressed: _saving ? null : () => setState(() => _step--),
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

class _RiderJobCard extends StatefulWidget {
  const _RiderJobCard({required this.job, required this.onChanged});

  final PrintDeliveryInfo job;
  final VoidCallback onChanged;

  @override
  State<_RiderJobCard> createState() => _RiderJobCardState();
}

class _RiderJobCardState extends State<_RiderJobCard> {
  final _repo = PrintRepository();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String? get _nextAction {
    switch (widget.job.status) {
      case 'requested':
        return 'accept';
      case 'assigned':
        return 'going_to_shop';
      case 'going_to_shop':
        return widget.job.arrivedShopAt == null ? 'arrive_shop' : 'pickup';
      case 'picked_up':
        return 'on_route';
      case 'on_route':
        return widget.job.arrivedCustomerAt == null ? 'arrive_customer' : null;
      default:
        return null;
    }
  }

  Future<void> _run() async {
    final action = _nextAction;
    if (action == null) return;
    setState(() => _busy = true);
    final PrintResult<PrintDeliveryInfo> result;
    if (action == 'accept') {
      result = await _repo.acceptDelivery(widget.job.id);
    } else {
      result = await _repo.advanceDelivery(
        deliveryId: widget.job.id,
        action: action,
        code: action == 'pickup' ? _code.text.trim() : null,
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintDeliveryInfo>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final action = _nextAction;
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
            '#${job.orderId ?? job.id} · ${'lbl_print_status_${job.status}'.tr}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (job.shopName != null)
            Text(job.shopName!, style: const TextStyle(color: Colors.white70)),
          if (job.pickupCode != null)
            Text('${'lbl_print_pickup_code'.tr}: ${job.pickupCode}'),
          if (job.areaCode != null)
            Text('${'lbl_print_area'.tr}: ${job.areaCode}'),
          if (job.address != null)
            Text(job.address!, style: const TextStyle(color: Colors.white70)),
          Text(
            '${'lbl_print_delivery_fee'.tr}: ${printSar(job.fee)} · ${job.distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '${'lbl_print_expected_earning'.tr}: ${printSar(job.expectedEarning)}',
            style: const TextStyle(color: AppDs.printGold),
          ),
          Text(
            'msg_print_earning_not_paid'.tr,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (action == 'pickup') ...[
            SizedBox(height: 8.v),
            TextField(
              controller: _code,
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
          ],
          if (job.status != 'requested' && job.orderId != null)
            TextButton(
              onPressed: () => NavigatorService.pushNamed(
                AppRoutes.printChatScreen,
                arguments: {
                  'orderId': job.orderId,
                  'thread': 'shop_rider',
                  'viewer': 'rider',
                },
              ),
              child: Text('lbl_print_rider_chat'.tr),
            ),
          if (action != null)
            Padding(
              padding: EdgeInsets.only(top: 8.v),
              child: PrintGoldButton(
                label: 'lbl_print_rider_action_$action'.tr,
                loading: _busy,
                onPressed: _run,
              ),
            ),
          if (job.status == 'delivered' && job.orderId != null)
            Padding(
              padding: EdgeInsets.only(top: 8.v),
              child: PrintGoldButton(
                label: 'lbl_print_review_customer'.tr,
                onPressed: () async {
                  await showPrintReviewSheet(
                    context: context,
                    orderId: job.orderId!,
                    target: 'customer',
                  );
                  widget.onChanged();
                },
              ),
            ),
        ],
      ),
    );
  }
}
