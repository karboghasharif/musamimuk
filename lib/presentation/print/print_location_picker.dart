import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import 'print_kyc_wizard.dart';
import 'print_places_service.dart';

/// Fallback only if GPS is unavailable (Jeddah).
const LatLng kPrintMapFallback = LatLng(21.5433, 39.1728);

class PrintGpsFix {
  const PrintGpsFix(this.lat, this.lng);

  final double lat;
  final double lng;
}

class PrintPlaceLabels {
  const PrintPlaceLabels({
    required this.address,
    required this.district,
  });

  final String address;
  final String district;
}

/// Live GPS for rider online / dropoff. Returns null after toast on failure.
Future<PrintGpsFix?> printAcquireGps({bool toastOnSuccess = false}) async {
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
    return null;
  }
  final service = await Geolocator.isLocationServiceEnabled();
  if (!service) {
    showAppToast(
      'msg_print_location_disabled'.tr,
      type: ToastificationType.error,
    );
    return null;
  }
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    if (toastOnSuccess) {
      showAppToast(
        'msg_print_location_set'.tr,
        type: ToastificationType.success,
      );
    }
    return PrintGpsFix(pos.latitude, pos.longitude);
  } catch (_) {
    showAppToast(
      'msg_print_location_failed'.tr,
      type: ToastificationType.error,
    );
    return null;
  }
}

Future<PrintPlaceLabels?> printReverseGeocode(double lat, double lng) {
  return PrintPlacesService().reverseGeocode(lat, lng);
}

Future<void> printOpenInMaps(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    showAppToast(
      'msg_print_location_failed'.tr,
      type: ToastificationType.error,
    );
  }
}

/// Lat/lng + Google Map + Places search + current-location + address autofill.
class PrintLocationPicker extends StatefulWidget {
  const PrintLocationPicker({
    super.key,
    required this.latController,
    required this.lngController,
    this.addressController,
    this.districtController,
    this.onChanged,
    this.autoLocate = true,
  });

  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController? addressController;
  final TextEditingController? districtController;
  final VoidCallback? onChanged;
  final bool autoLocate;

  @override
  State<PrintLocationPicker> createState() => _PrintLocationPickerState();
}

class _PrintLocationPickerState extends State<PrintLocationPicker> {
  final _places = PrintPlacesService();
  GoogleMapController? _mapController;
  LatLng _pin = kPrintMapFallback;
  bool _syncingFields = false;
  bool _locating = false;
  bool _geocoding = false;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    final existing = _latLngFromFields();
    _pin = existing ?? kPrintMapFallback;
    widget.latController.addListener(_onFieldEdited);
    widget.lngController.addListener(_onFieldEdited);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (existing != null) {
        unawaited(_fillAddressFromPin(existing, force: true));
        return;
      }
      if (widget.autoLocate) {
        unawaited(_locateToCurrent(showToast: false, forceAddress: true));
      }
    });
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    widget.latController.removeListener(_onFieldEdited);
    widget.lngController.removeListener(_onFieldEdited);
    _mapController?.dispose();
    super.dispose();
  }

  LatLng? _latLngFromFields() {
    final lat = double.tryParse(widget.latController.text.trim());
    final lng = double.tryParse(widget.lngController.text.trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  void _onFieldEdited() {
    if (_syncingFields) return;
    final next = _latLngFromFields();
    if (next == null) return;
    if ((next.latitude - _pin.latitude).abs() < 0.000001 &&
        (next.longitude - _pin.longitude).abs() < 0.000001) {
      return;
    }
    setState(() => _pin = next);
    _mapController?.animateCamera(CameraUpdate.newLatLng(next));
    _scheduleGeocode(next, force: true);
  }

  Future<void> _applyPin(
    LatLng pin, {
    bool moveCamera = false,
    bool geocode = true,
    bool geocodeForce = true,
    PrintPlaceLabels? labels,
  }) async {
    setState(() => _pin = pin);
    _syncingFields = true;
    widget.latController.text = pin.latitude.toStringAsFixed(6);
    widget.lngController.text = pin.longitude.toStringAsFixed(6);
    _syncingFields = false;
    if (labels != null) {
      _writeLabels(labels, force: true);
    }
    widget.onChanged?.call();
    if (moveCamera) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(pin, 16),
      );
    }
    if (geocode && labels == null) {
      _scheduleGeocode(pin, force: geocodeForce);
    }
  }

  void _writeLabels(PrintPlaceLabels labels, {required bool force}) {
    final addressCtrl = widget.addressController;
    final districtCtrl = widget.districtController;
    if (addressCtrl != null &&
        labels.address.isNotEmpty &&
        (force || addressCtrl.text.trim().isEmpty)) {
      addressCtrl.text = labels.address;
    }
    if (districtCtrl != null &&
        labels.district.isNotEmpty &&
        (force || districtCtrl.text.trim().isEmpty)) {
      districtCtrl.text = labels.district;
    }
  }

  void _scheduleGeocode(LatLng pin, {required bool force}) {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_fillAddressFromPin(pin, force: force));
    });
  }

  Future<void> _fillAddressFromPin(
    LatLng pin, {
    required bool force,
  }) async {
    final addressCtrl = widget.addressController;
    final districtCtrl = widget.districtController;
    if (addressCtrl == null && districtCtrl == null) return;
    if (!force) {
      final addressEmpty =
          addressCtrl == null || addressCtrl.text.trim().isEmpty;
      final districtEmpty =
          districtCtrl == null || districtCtrl.text.trim().isEmpty;
      if (!addressEmpty && !districtEmpty) return;
    }
    if (mounted) setState(() => _geocoding = true);
    final labels = await _places.reverseGeocode(pin.latitude, pin.longitude);
    if (!mounted) return;
    setState(() => _geocoding = false);
    if (labels == null) {
      showAppToast(
        'msg_print_address_lookup_failed'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    _writeLabels(labels, force: force);
    widget.onChanged?.call();
  }

  Future<void> _locateToCurrent({
    required bool showToast,
    bool forceAddress = true,
  }) async {
    if (_locating) return;
    setState(() => _locating = true);
    final fix = await printAcquireGps(toastOnSuccess: showToast);
    if (!mounted) return;
    if (fix == null) {
      setState(() => _locating = false);
      return;
    }
    final pin = LatLng(fix.lat, fix.lng);
    await _applyPin(
      pin,
      moveCamera: true,
      geocode: true,
      geocodeForce: forceAddress,
    );
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _openSearch() async {
    final picked = await showModalBottomSheet<PrintResolvedPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDs.atelierInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDs.radiusXl),
        ),
      ),
      builder: (ctx) {
        return _PlaceSearchSheet(
          places: _places,
          bias: _pin,
        );
      },
    );
    if (picked == null || !mounted) return;
    await _applyPin(
      picked.latLng,
      moveCamera: true,
      geocode: false,
      labels: picked.labels,
    );
  }

  Future<void> _openMaps() async {
    final lat = double.tryParse(widget.latController.text.trim());
    final lng = double.tryParse(widget.lngController.text.trim());
    if (lat == null || lng == null) {
      showAppToast(
        'msg_print_location_required'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    await printOpenInMaps(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openSearch,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDs.space3.h,
                vertical: AppDs.space3.v,
              ),
              decoration: BoxDecoration(
                color: AppDs.surfaceRaised,
                borderRadius: BorderRadius.circular(AppDs.radiusMd),
                border: Border.all(color: AppDs.atelierHairline(0.14)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppDs.atelierBrass,
                    size: AppDs.iconMd.adaptSize,
                  ),
                  SizedBox(width: AppDs.space2.h),
                  Expanded(
                    child: AppText(
                      'lbl_print_search_location'.tr,
                      variant: AppTextVariant.secondary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppDs.textOnDarkDisabled,
                    size: AppDs.iconMd.adaptSize,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: AppDs.space3.v),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDs.radiusLg),
          child: SizedBox(
            height: 240.v,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pin,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('print_pin'),
                      position: _pin,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueYellow,
                      ),
                      infoWindow: InfoWindow(
                        title: 'lbl_print_map_pin'.tr,
                      ),
                      onDragEnd: (pos) => _applyPin(pos),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (c) async {
                    _mapController = c;
                    await c.animateCamera(
                      CameraUpdate.newLatLngZoom(_pin, 16),
                    );
                  },
                  onTap: (pos) => _applyPin(pos),
                ),
                PositionedDirectional(
                  top: AppDs.space2.v,
                  end: AppDs.space2.h,
                  child: Column(
                    children: [
                      _MapIconButton(
                        tooltip: 'lbl_print_search_location'.tr,
                        icon: Icons.search_rounded,
                        onPressed: _openSearch,
                      ),
                      SizedBox(height: AppDs.space2.v),
                      _MapIconButton(
                        tooltip: 'lbl_print_use_current_location'.tr,
                        icon: Icons.my_location_rounded,
                        loading: _locating,
                        onPressed: _locating
                            ? null
                            : () => _locateToCurrent(
                                  showToast: true,
                                  forceAddress: true,
                                ),
                      ),
                    ],
                  ),
                ),
                if (_locating || _geocoding)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 28.adaptSize,
                              height: 28.adaptSize,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppDs.accentYellow,
                              ),
                            ),
                            SizedBox(height: AppDs.space2.v),
                            AppText(
                              _locating
                                  ? 'msg_print_locating'.tr
                                  : 'msg_print_resolving_address'.tr,
                              variant: AppTextVariant.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: AppDs.space2.h,
                  right: AppDs.space2.h,
                  bottom: AppDs.space2.v,
                  child: IgnorePointer(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDs.space3.h,
                        vertical: AppDs.space2.v,
                      ),
                      decoration: BoxDecoration(
                        color: AppDs.atelierInk.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      ),
                      child: AppText(
                        'msg_print_map_drag_hint'.tr,
                        variant: AppTextVariant.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDs.space3.v),
        AppPrimaryButton(
          label: 'lbl_print_use_current_location'.tr,
          isLoading: _locating,
          onPressed: _locating
              ? null
              : () => _locateToCurrent(showToast: true, forceAddress: true),
        ),
        SizedBox(height: AppDs.space2.v),
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: 'lbl_print_search_location'.tr,
                icon: Icons.search_rounded,
                onPressed: _openSearch,
              ),
            ),
            SizedBox(width: AppDs.space2.h),
            Expanded(
              child: AppSecondaryButton(
                label: 'lbl_print_open_map'.tr,
                icon: Icons.map_outlined,
                onPressed: _openMaps,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDs.space3.v),
        PrintKycTextField(
          controller: widget.latController,
          label: 'lbl_print_lat'.tr,
          prefixIcon: Icons.my_location_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helper: 'msg_print_map_pin_help'.tr,
          validator: requiredText,
        ),
        PrintKycTextField(
          controller: widget.lngController,
          label: 'lbl_print_lng'.tr,
          prefixIcon: Icons.explore_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: requiredText,
        ),
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceRaised,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: AppDs.minTap.adaptSize,
            height: AppDs.minTap.adaptSize,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18.adaptSize,
                      height: 18.adaptSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppDs.accentYellow,
                      ),
                    )
                  : Icon(
                      icon,
                      color: AppDs.accentYellow,
                      size: AppDs.iconMd.adaptSize,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({
    required this.places,
    required this.bias,
  });

  final PrintPlacesService places;
  final LatLng bias;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<PrintPlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_search(value));
    });
  }

  String? _error;

  Future<void> _search(String value) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final list = await widget.places.autocomplete(value, bias: widget.bias);
    if (!mounted) return;
    setState(() {
      _suggestions = list;
      _loading = false;
      _error = list.isEmpty ? widget.places.lastError : null;
    });
  }

  Future<void> _pick(PrintPlaceSuggestion suggestion) async {
    if (_resolving) return;
    setState(() => _resolving = true);
    final resolved = await widget.places.details(suggestion.placeId);
    if (!mounted) return;
    setState(() => _resolving = false);
    if (resolved == null) {
      showAppToast(
        'msg_print_address_lookup_failed'.tr,
        type: ToastificationType.error,
      );
      return;
    }
    Navigator.pop(context, resolved);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDs.space4.h,
          AppDs.space4.v,
          AppDs.space4.h,
          bottom + AppDs.space4.v,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.h,
                height: 4.v,
                decoration: BoxDecoration(
                  color: AppDs.atelierHairline(0.3),
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                ),
              ),
            ),
            SizedBox(height: AppDs.space4.v),
            AppText(
              'lbl_print_search_location'.tr,
              variant: AppTextVariant.heading,
            ),
            SizedBox(height: AppDs.space3.v),
            TextField(
              controller: _query,
              focusNode: _focus,
              onChanged: _onQueryChanged,
              style: AppTypography.body(Theme.of(context)),
              decoration: InputDecoration(
                hintText: 'msg_print_search_location_hint'.tr,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _loading || _resolving
                    ? Padding(
                        padding: EdgeInsets.all(AppDs.space3.h),
                        child: SizedBox(
                          width: 18.adaptSize,
                          height: 18.adaptSize,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppDs.accentYellow,
                          ),
                        ),
                      )
                    : (_query.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _query.clear();
                              setState(() => _suggestions = const []);
                            },
                            icon: const Icon(Icons.close_rounded),
                          )),
              ),
            ),
            SizedBox(height: AppDs.space3.v),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 320.v),
              child: _suggestions.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDs.space6.v),
                      child: AppText(
                        _query.text.trim().length < 2
                            ? 'msg_print_search_location_hint'.tr
                            : (_error?.trim().isNotEmpty == true
                                ? _error!
                                : 'msg_print_search_no_results'.tr),
                        variant: AppTextVariant.secondary,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) => Divider(
                        color: AppDs.atelierHairline(0.12),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.place_outlined,
                            color: AppDs.atelierBrass,
                          ),
                          title: Text(
                            s.primaryText,
                            style: AppTypography.body(Theme.of(context))
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: s.secondaryText.isEmpty
                              ? null
                              : Text(
                                  s.secondaryText,
                                  style: AppTypography.caption(
                                    Theme.of(context),
                                  ),
                                ),
                          onTap: () => _pick(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
