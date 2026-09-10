import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_review_sheet.dart';
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
    super.dispose();
  }

  Future<void> _load() async {
    final riderResult = await _repo.myRider();
    if (!mounted) return;
    if (riderResult is PrintFailure<PrintRiderProfile?>) {
      setState(() => _loading = false);
      return;
    }
    final rider = (riderResult as PrintSuccess<PrintRiderProfile?>).data;
    var jobs = const <PrintDeliveryInfo>[];
    if (rider != null && rider.status == 'approved') {
      final jobsResult = await _repo.riderJobs();
      if (jobsResult is PrintSuccess<List<PrintDeliveryInfo>>) {
        jobs = jobsResult.data;
      }
    }
    List<PrintReview> reviews = const [];
    if (rider != null) {
      final reviewResult = await _repo.riderReviews(rider.id);
      if (reviewResult is PrintSuccess<List<PrintReview>>) {
        reviews = reviewResult.data;
      }
    }
    if (!mounted) return;
    setState(() {
      _rider = rider;
      _jobs = jobs;
      _reviews = reviews;
      _loading = false;
    });
  }

  Future<void> _toggleOnline(bool online) async {
    final result = await _repo.setRiderOnline(
      online: online,
      lat: 21.544,
      lng: 39.173,
    );
    if (!mounted) return;
    if (result is PrintFailure<PrintRiderProfile>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    setState(() => _rider = (result as PrintSuccess<PrintRiderProfile>).data);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PrintScaffold(
        title: 'lbl_print_rider_mode'.tr,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_rider == null) {
      return PrintScaffold(
        title: 'lbl_print_rider_mode'.tr,
        body: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'msg_print_register_rider'.tr,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.v),
              PrintGoldButton(
                label: 'lbl_print_register_rider'.tr,
                onPressed: () => NavigatorService.pushNamed(
                  AppRoutes.printRiderRegisterScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_rider!.status != 'approved') {
      return PrintScaffold(
        title: 'lbl_print_rider_mode'.tr,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: Text(
              'msg_print_rider_pending'.tr,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return PrintScaffold(
      title: _rider!.name,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.all(16.h),
          children: [
            SwitchListTile(
              value: _rider!.online,
              activeThumbColor: AppDs.printGold,
              title: Text(
                'lbl_print_online'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              onChanged: _toggleOnline,
            ),
            PrintLevelBadge(
              label: _rider!.levelLabel,
              labelAr: _rider!.levelLabelAr,
            ),
            if (_rider!.levelProgress?.hint != null)
              Padding(
                padding: EdgeInsets.only(top: 6.v, bottom: 12.v),
                child: Text(
                  _rider!.levelProgress!.hint!,
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
            SizedBox(height: 12.v),
            ..._jobs.map(
              (job) => Padding(
                padding: EdgeInsets.only(bottom: 10.v),
                child: _RiderJobCard(job: job, onChanged: _load),
              ),
            ),
          ],
        ),
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
  final _repo = PrintRepository();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _vehicle = TextEditingController();
  final _plate = TextEditingController();
  final _iban = TextEditingController();
  final _district = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _vehicle.dispose();
    _plate.dispose();
    _iban.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await _repo.registerRider(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      nationalId: _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
      vehicle: _vehicle.text.trim().isEmpty ? null : _vehicle.text.trim(),
      plate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
      iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
      lat: 21.544,
      lng: 39.173,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is PrintFailure<PrintRiderProfile>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    NavigatorService.pushReplacementNamed(AppRoutes.printRiderHomeScreen);
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
      title: 'lbl_print_register_rider'.tr,
      body: ListView(
        padding: EdgeInsets.all(16.h),
        children: [
          field(_name, 'lbl_print_owner_name'.tr),
          field(_phone, 'lbl_print_phone'.tr),
          field(_nationalId, 'lbl_print_national_id'.tr),
          field(_vehicle, 'lbl_print_vehicle'.tr),
          field(_plate, 'lbl_print_plate'.tr),
          field(_iban, 'lbl_print_iban'.tr),
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
