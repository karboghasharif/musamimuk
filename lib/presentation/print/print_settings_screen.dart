import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
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
    'business_card',
    'a5',
    'a4',
    'a3',
    'banner',
    'custom',
  ];
  static const _papers = [
    '80gsm',
    '120gsm',
    '250gsm',
    '300gsm',
    'glossy',
    'matte',
    'sticker',
    'banner',
    'canvas',
  ];
  static const _finishes = [
    'lamination',
    'cutting',
    'folding',
    'binding',
    'embossing',
    'custom',
  ];

  String _sizeId = 'a4';
  int _quantity = 100;
  int _sides = 1;
  String _color = 'color';
  String _paper = '80gsm';
  final Set<String> _finishing = {};
  final _customW = TextEditingController();
  final _customH = TextEditingController();
  final _dropoff = TextEditingController();
  final _dropLat = TextEditingController();
  final _dropLng = TextEditingController();
  String _fulfillment = 'pickup';

  @override
  void dispose() {
    _customW.dispose();
    _customH.dispose();
    _dropoff.dispose();
    _dropLat.dispose();
    _dropLng.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final live = await PrintRepository().realtime();
    if (live is PrintSuccess<Map<String, dynamic>> &&
        live.data['marketplace_enabled'] == false) {
      showAppToast(
        'msg_print_marketplace_disabled'.tr,
        type: ToastificationType.error,
      );
      return;
    }
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
    final spec = PrintSpec(
      sizeId: _sizeId,
      customWmm: int.tryParse(_customW.text.trim()),
      customHmm: int.tryParse(_customH.text.trim()),
      quantity: _quantity,
      sides: _sides,
      color: _color,
      paper: _paper,
      finishing: _finishing.toList(),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: 'lbl_print_settings'.tr,
      body: ListView(
        padding: EdgeInsets.all(AppDs.space4.h),
        children: [
          Text('lbl_print_size'.tr, style: _label),
          Wrap(
            spacing: 8,
            children: _sizes
                .map(
                  (id) => ChoiceChip(
                    label: Text('lbl_print_size_$id'.tr),
                    selected: _sizeId == id,
                    onSelected: (_) => setState(() => _sizeId = id),
                    selectedColor: AppDs.printGold,
                    labelStyle: TextStyle(
                      color: _sizeId == id ? Colors.black : Colors.white,
                    ),
                  ),
                )
                .toList(),
          ),
          if (_sizeId == 'custom') ...[
            SizedBox(height: AppDs.space3.v),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customW,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _field('lbl_print_width_mm'.tr),
                  ),
                ),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: TextField(
                    controller: _customH,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _field('lbl_print_height_mm'.tr),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: AppDs.space5.v),
          Text('lbl_print_quantity'.tr, style: _label),
          Slider(
            value: _quantity.toDouble().clamp(10, 2000),
            min: 10,
            max: 2000,
            divisions: 199,
            label: '$_quantity',
            activeColor: AppDs.printGold,
            onChanged: (v) => setState(() => _quantity = v.round()),
          ),
          Text(
            '$_quantity',
            style: const TextStyle(color: AppDs.printGold, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppDs.space4.v),
          Text('lbl_print_paper'.tr, style: _label),
          Wrap(
            spacing: 8,
            children: _papers
                .map(
                  (id) => ChoiceChip(
                    label: Text(id),
                    selected: _paper == id,
                    onSelected: (_) => setState(() => _paper = id),
                    selectedColor: AppDs.printGold,
                    labelStyle: TextStyle(
                      color: _paper == id ? Colors.black : Colors.white,
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: AppDs.space4.v),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('lbl_print_double_sided'.tr, style: _label),
            value: _sides == 2,
            onChanged: (v) => setState(() => _sides = v ? 2 : 1),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('lbl_print_black_white'.tr, style: _label),
            value: _color == 'bw',
            onChanged: (v) => setState(() => _color = v ? 'bw' : 'color'),
          ),
          SizedBox(height: AppDs.space3.v),
          Text('lbl_print_finishing'.tr, style: _label),
          Wrap(
            spacing: 8,
            children: _finishes
                .map(
                  (id) => FilterChip(
                    label: Text('lbl_print_finish_$id'.tr),
                    selected: _finishing.contains(id),
                    onSelected: (s) => setState(() {
                      if (s) {
                        _finishing.add(id);
                      } else {
                        _finishing.remove(id);
                      }
                    }),
                    selectedColor: AppDs.printGold,
                    labelStyle: TextStyle(
                      color: _finishing.contains(id) ? Colors.black : Colors.white,
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: AppDs.space4.v),
          Text('lbl_print_fulfillment'.tr, style: _label),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('lbl_print_pick_up'.tr),
                selected: _fulfillment == 'pickup',
                selectedColor: AppDs.printGold,
                labelStyle: TextStyle(
                  color: _fulfillment == 'pickup' ? Colors.black : Colors.white,
                ),
                onSelected: (_) => setState(() => _fulfillment = 'pickup'),
              ),
              ChoiceChip(
                label: Text('lbl_print_deliver_to_me'.tr),
                selected: _fulfillment == 'delivery',
                selectedColor: AppDs.printGold,
                labelStyle: TextStyle(
                  color: _fulfillment == 'delivery' ? Colors.black : Colors.white,
                ),
                onSelected: (_) => setState(() => _fulfillment = 'delivery'),
              ),
            ],
          ),
          if (_fulfillment == 'delivery') ...[
            SizedBox(height: AppDs.space3.v),
            TextField(
              controller: _dropoff,
              style: const TextStyle(color: Colors.white),
              decoration: _field('lbl_print_delivery_address'.tr),
            ),
            SizedBox(height: AppDs.space3.v),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dropLat,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: _field('lbl_print_lat'.tr),
                  ),
                ),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: TextField(
                    controller: _dropLng,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: _field('lbl_print_lng'.tr),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: AppDs.space8.v),
          PrintGoldButton(
            label: 'lbl_print_find_shops'.tr,
            loading: false,
            onPressed: _continue,
          ),
        ],
      ),
    );
  }

  TextStyle get _label => const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  InputDecoration _field(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
    filled: true,
    fillColor: AppDs.surfaceRaised,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
