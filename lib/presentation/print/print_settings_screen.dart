import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_location_picker.dart';
import 'print_ui.dart';

class PrintSettingsScreen extends StatefulWidget {
  const PrintSettingsScreen({super.key, required this.designId});

  final int designId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    return PrintSettingsScreen(designId: apiParseInt(map['designId']));
  }

  @override
  State<PrintSettingsScreen> createState() => _PrintSettingsScreenState();
}

class _PrintSettingsScreenState extends State<PrintSettingsScreen> {
  static const _sizes = [
    ('business_card', 3.5, 2.0),
    ('a5', 148.0, 210.0),
    ('a4', 210.0, 297.0),
    ('a3', 297.0, 420.0),
    ('banner', 4.0, 1.0),
    ('custom', 1.0, 1.0),
  ];

  static const _weights = ['80gsm', '120gsm', '250gsm', '300gsm'];
  static const _stocks = ['glossy', 'matte', 'sticker', 'banner', 'canvas'];

  static const _finishes = [
    ('lamination', Icons.layers_outlined),
    ('cutting', Icons.content_cut),
    ('folding', Icons.unfold_less),
    ('binding', Icons.menu_book_outlined),
    ('embossing', Icons.texture),
    ('custom', Icons.tune),
  ];

  String _sizeId = 'a4';
  int _quantity = 100;
  int _sides = 1;
  String _color = 'color';
  String _paper = '80gsm';
  final Set<String> _finishing = {};
  final _customW = TextEditingController();
  final _customH = TextEditingController();
  final _notes = TextEditingController();
  final _dropoff = TextEditingController();
  final _dropLat = TextEditingController();
  final _dropLng = TextEditingController();
  String _fulfillment = 'pickup';
  bool _busy = false;

  @override
  void dispose() {
    _customW.dispose();
    _customH.dispose();
    _notes.dispose();
    _dropoff.dispose();
    _dropLat.dispose();
    _dropLng.dispose();
    super.dispose();
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
        filled: true,
        fillColor: AppDs.surfaceRaised,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: BorderSide(color: AppDs.atelierHairline(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: const BorderSide(color: AppDs.atelierBrass),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
        ),
      );

  String get _summaryLine {
    final size = 'lbl_print_size_$_sizeId'.tr;
    final ink = _color == 'bw'
        ? 'lbl_print_ink_bw'.tr
        : 'lbl_print_ink_color'.tr;
    final sides = _sides == 2
        ? 'lbl_print_sides_double'.tr
        : 'lbl_print_sides_single'.tr;
    final paper = 'lbl_print_paper_$_paper'.tr;
    final how = _fulfillment == 'delivery'
        ? 'lbl_print_deliver_to_me'.tr
        : 'lbl_print_pick_up'.tr;
    return '$size · $_quantity · $paper · $sides · $ink · $how';
  }

  PrintSpec? _buildSpecOrToast() {
    if (_sizeId == 'custom') {
      final w = int.tryParse(_customW.text.trim());
      final h = int.tryParse(_customH.text.trim());
      if (w == null || h == null || w <= 0 || h <= 0) {
        showAppToast(
          'msg_print_custom_size_required'.tr,
          type: ToastificationType.error,
        );
        return null;
      }
    }
    final notes = _notes.text.trim();
    if (_finishing.contains('custom') && notes.isEmpty) {
      showAppToast(
        'msg_print_custom_notes_required'.tr,
        type: ToastificationType.error,
      );
      return null;
    }
    return PrintSpec(
      sizeId: _sizeId,
      customWmm: int.tryParse(_customW.text.trim()),
      customHmm: int.tryParse(_customH.text.trim()),
      quantity: _quantity,
      sides: _sides,
      color: _color,
      paper: _paper,
      finishing: _finishing.toList(),
      notes: notes.isEmpty ? null : notes,
    );
  }

  Future<bool> _ensureMarketplace() async {
    final live = await PrintRepository().realtime();
    if (live is PrintSuccess<Map<String, dynamic>> &&
        live.data['marketplace_enabled'] == false) {
      showAppToast(
        'msg_print_marketplace_disabled'.tr,
        type: ToastificationType.error,
      );
      return false;
    }
    return true;
  }

  Future<void> _broadcast() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await _ensureMarketplace()) return;
      final lat = double.tryParse(_dropLat.text.trim());
      final lng = double.tryParse(_dropLng.text.trim());
      if (lat == null || lng == null) {
        showAppToast(
          'msg_print_broadcast_pin_required'.tr,
          type: ToastificationType.error,
        );
        return;
      }
      if (_fulfillment == 'delivery' && _dropoff.text.trim().isEmpty) {
        showAppToast(
          'lbl_print_dropoff_required'.tr,
          type: ToastificationType.error,
        );
        return;
      }
      final spec = _buildSpecOrToast();
      if (spec == null) return;
      final result = await PrintRepository().broadcastJob(
        designId: widget.designId,
        spec: spec,
        fulfillment: _fulfillment,
        dropoffAddress:
            _fulfillment == 'delivery' ? _dropoff.text.trim() : null,
        dropoffLat: _fulfillment == 'delivery' ? lat : null,
        dropoffLng: _fulfillment == 'delivery' ? lng : null,
        pinLat: lat,
        pinLng: lng,
      );
      if (!mounted) return;
      if (result is PrintFailure<PrintOrder>) {
        showAppToast(result.message, type: ToastificationType.error);
        return;
      }
      final order = (result as PrintSuccess<PrintOrder>).data;
      showAppToast(
        'msg_print_broadcast_sent'.tr,
        type: ToastificationType.success,
      );
      await NavigatorService.pushNamed(
        AppRoutes.printTrackingScreen,
        arguments: {'orderId': order.id},
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickShop() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await _ensureMarketplace()) return;
      if (_fulfillment == 'delivery') {
        final lat = double.tryParse(_dropLat.text.trim());
        final lng = double.tryParse(_dropLng.text.trim());
        if (_dropoff.text.trim().isEmpty || lat == null || lng == null) {
          showAppToast(
            'lbl_print_dropoff_required'.tr,
            type: ToastificationType.error,
          );
          return;
        }
      }
      final spec = _buildSpecOrToast();
      if (spec == null) return;
      NavigatorService.pushNamed(
        AppRoutes.printShopsScreen,
        arguments: {
          'designId': widget.designId,
          'spec': spec.toJson(),
          'fulfillment': _fulfillment,
          'dropoffAddress': _dropoff.text.trim(),
          'dropoffLat': double.tryParse(_dropLat.text.trim()),
          'dropoffLng': double.tryParse(_dropLng.text.trim()),
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PrintScaffold(
      title: 'lbl_print_settings'.tr,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppDs.space4.h,
          AppDs.space4.v,
          AppDs.space4.h,
          AppDs.space12.v,
        ),
        children: [
          Text(
            'msg_print_settings_intro'.tr,
            style: AppTypography.secondary(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_size'.tr,
            hint: 'msg_print_size_hint'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppDs.space2.v,
                  crossAxisSpacing: AppDs.space2.h,
                  childAspectRatio: 0.92,
                  children: [
                    for (final s in _sizes)
                      PrintSizeTile(
                        id: s.$1,
                        label: 'lbl_print_size_${s.$1}'.tr,
                        selected: _sizeId == s.$1,
                        aspectW: s.$2,
                        aspectH: s.$3,
                        onTap: () => setState(() => _sizeId = s.$1),
                      ),
                  ],
                ),
                if (_sizeId == 'custom') ...[
                  SizedBox(height: AppDs.space3.v),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customW,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppDs.textOnDarkPrimary),
                          decoration: _field('lbl_print_width_mm'.tr),
                        ),
                      ),
                      SizedBox(width: AppDs.space3.h),
                      Expanded(
                        child: TextField(
                          controller: _customH,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppDs.textOnDarkPrimary),
                          decoration: _field('lbl_print_height_mm'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_quantity'.tr,
            child: PrintQtyPlate(
              value: _quantity,
              onChanged: (v) => setState(() => _quantity = v),
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_paper'.tr,
            hint: 'msg_print_paper_hint'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_print_paper_weight'.tr,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Wrap(
                  spacing: AppDs.space2.h,
                  runSpacing: AppDs.space2.v,
                  children: [
                    for (final id in _weights)
                      PrintSelectTile(
                        label: 'lbl_print_paper_$id'.tr,
                        selected: _paper == id,
                        onTap: () => setState(() => _paper = id),
                      ),
                  ],
                ),
                SizedBox(height: AppDs.space4.v),
                Text(
                  'lbl_print_paper_stock'.tr,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Wrap(
                  spacing: AppDs.space2.h,
                  runSpacing: AppDs.space2.v,
                  children: [
                    for (final id in _stocks)
                      PrintSelectTile(
                        label: 'lbl_print_paper_$id'.tr,
                        selected: _paper == id,
                        onTap: () => setState(() => _paper = id),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_sides'.tr,
            child: PrintChoiceRail(
              selectedId: _sides == 2 ? 'double' : 'single',
              onSelected: (id) =>
                  setState(() => _sides = id == 'double' ? 2 : 1),
              options: [
                (
                  'single',
                  'lbl_print_sides_single'.tr,
                  Icons.filter_1_outlined,
                ),
                (
                  'double',
                  'lbl_print_sides_double'.tr,
                  Icons.filter_2_outlined,
                ),
              ],
            ),
          ),
          SizedBox(height: AppDs.space5.v),
          PrintTicketSection(
            title: 'lbl_print_ink'.tr,
            child: PrintChoiceRail(
              selectedId: _color,
              onSelected: (id) => setState(() => _color = id),
              options: [
                (
                  'color',
                  'lbl_print_ink_color'.tr,
                  Icons.palette_outlined,
                ),
                (
                  'bw',
                  'lbl_print_ink_bw'.tr,
                  Icons.contrast,
                ),
              ],
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_finishing'.tr,
            hint: 'msg_print_finishing_hint'.tr,
            child: Wrap(
              spacing: AppDs.space2.h,
              runSpacing: AppDs.space2.v,
              children: [
                for (final f in _finishes)
                  PrintSelectTile(
                    label: 'lbl_print_finish_${f.$1}'.tr,
                    icon: f.$2,
                    multi: true,
                    selected: _finishing.contains(f.$1),
                    onTap: () => setState(() {
                      if (_finishing.contains(f.$1)) {
                        _finishing.remove(f.$1);
                      } else {
                        _finishing.add(f.$1);
                      }
                    }),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_designer_notes'.tr,
            hint: _finishing.contains('custom')
                ? 'msg_print_designer_notes_custom_hint'.tr
                : 'msg_print_designer_notes_hint'.tr,
            child: TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              style: const TextStyle(color: AppDs.textOnDarkPrimary),
              decoration: _field('lbl_print_designer_notes_placeholder'.tr).copyWith(
                alignLabelWithHint: true,
                counterStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
              ),
            ),
          ),
          SizedBox(height: AppDs.space6.v),
          PrintTicketSection(
            title: 'lbl_print_fulfillment'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PrintFulfillmentCard(
                        icon: Icons.storefront_outlined,
                        title: 'lbl_print_pick_up'.tr,
                        subtitle: 'msg_print_fulfillment_pickup_hint'.tr,
                        selected: _fulfillment == 'pickup',
                        onTap: () => setState(() => _fulfillment = 'pickup'),
                      ),
                    ),
                    SizedBox(width: AppDs.space2.h),
                    Expanded(
                      child: PrintFulfillmentCard(
                        icon: Icons.local_shipping_outlined,
                        title: 'lbl_print_deliver_to_me'.tr,
                        subtitle: 'msg_print_fulfillment_delivery_hint'.tr,
                        selected: _fulfillment == 'delivery',
                        onTap: () => setState(() => _fulfillment = 'delivery'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDs.space4.v),
                Text(
                  _fulfillment == 'delivery'
                      ? 'msg_print_delivery_pin_hint'.tr
                      : 'msg_print_broadcast_pin_hint'.tr,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: AppDs.space3.v),
                PrintLocationPicker(
                  latController: _dropLat,
                  lngController: _dropLng,
                  addressController: _dropoff,
                  autoLocate: true,
                  onChanged: () => setState(() {}),
                ),
                if (_fulfillment == 'delivery') ...[
                  SizedBox(height: AppDs.space3.v),
                  TextField(
                    controller: _dropoff,
                    minLines: 2,
                    maxLines: 3,
                    style: const TextStyle(color: AppDs.textOnDarkPrimary),
                    decoration: _field('lbl_print_delivery_address'.tr),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottom: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space2.v,
            AppDs.space4.h,
            AppDs.space3.v,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _summaryLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(theme).copyWith(
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
              SizedBox(height: AppDs.space2.v),
              PrintGoldButton(
                label: 'lbl_print_broadcast_request'.tr,
                loading: _busy,
                onPressed: _broadcast,
              ),
              SizedBox(height: AppDs.space2.v),
              PrintGhostButton(
                label: 'lbl_print_find_shops'.tr,
                icon: Icons.storefront_outlined,
                onPressed: _busy ? null : _pickShop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
