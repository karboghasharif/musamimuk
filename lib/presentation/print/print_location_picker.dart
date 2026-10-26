import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import 'print_kyc_wizard.dart';

/// Lat/lng fields + GPS fill + open in maps. Avoids silent hardcoded pins.
class PrintLocationPicker extends StatelessWidget {
  const PrintLocationPicker({
    super.key,
    required this.latController,
    required this.lngController,
    this.onChanged,
  });

  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback? onChanged;

  Future<void> _useGps(BuildContext context) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      showAppToast(
        'msg_print_location_denied'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      showAppToast(
        'msg_print_location_disabled'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      latController.text = pos.latitude.toStringAsFixed(6);
      lngController.text = pos.longitude.toStringAsFixed(6);
      onChanged?.call();
      showAppToast(
        'msg_print_location_set'.tr,
        type: ToastificationType.success,
      );
    } catch (_) {
      showAppToast(
        'msg_print_location_failed'.tr,
        type: ToastificationType.error,
      );
    }
  }

  Future<void> _openMaps() async {
    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());
    if (lat == null || lng == null) {
      showAppToast(
        'msg_print_location_required'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showAppToast(
        'msg_print_location_failed'.tr,
        type: ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrintKycTextField(
          controller: latController,
          label: 'lbl_print_lat'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helper: 'msg_print_map_pin_help'.tr,
          validator: requiredText,
        ),
        PrintKycTextField(
          controller: lngController,
          label: 'lbl_print_lng'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: requiredText,
        ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _useGps(context),
                  icon: const Icon(Icons.my_location, color: AppDs.printGold),
                  label: Text(
                    'lbl_print_use_gps'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.h),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_outlined, color: AppDs.printGold),
                  label: Text(
                    'lbl_print_open_map'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
