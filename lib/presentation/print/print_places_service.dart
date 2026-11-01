import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_export.dart';
import '../../core/config/google_maps_config.dart';
import 'print_location_picker.dart';

class PrintPlaceSuggestion {
  const PrintPlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
}

class PrintResolvedPlace {
  const PrintResolvedPlace({
    required this.latLng,
    required this.labels,
  });

  final LatLng latLng;
  final PrintPlaceLabels labels;
}

/// Places API (New) Autocomplete + Details, plus classic Geocoding for reverse.
class PrintPlacesService {
  PrintPlacesService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  String get _key => GoogleMapsConfig.apiKey;

  /// Last Places/Geocode error for UI (REQUEST_DENIED, etc.).
  String? lastError;

  Future<List<PrintPlaceSuggestion>> autocomplete(
    String query, {
    LatLng? bias,
  }) async {
    lastError = null;
    final q = query.trim();
    if (q.length < 2 || _key.isEmpty) return const [];
    try {
      final body = <String, dynamic>{
        'input': q,
        'includedRegionCodes': [GoogleMapsConfig.country],
        if (bias != null)
          'locationBias': {
            'circle': {
              'center': {
                'latitude': bias.latitude,
                'longitude': bias.longitude,
              },
              'radius': 50000.0,
            },
          },
      };
      final res = await _dio.post<Map<String, dynamic>>(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: body,
        options: Options(
          headers: {
            'X-Goog-Api-Key': _key,
          },
        ),
      );
      final data = res.data;
      if (data == null) return const [];
      if (data['error'] != null) {
        lastError = data['error']?['message']?.toString() ??
            'msg_print_places_denied'.tr;
        return const [];
      }
      final suggestions = data['suggestions'] as List<dynamic>? ?? const [];
      return suggestions
          .map((raw) {
            final m = Map<String, dynamic>.from(raw as Map);
            final pred = Map<String, dynamic>.from(
              m['placePrediction'] as Map? ?? {},
            );
            if (pred.isEmpty) return null;
            final structured = Map<String, dynamic>.from(
              pred['structuredFormat'] as Map? ?? {},
            );
            final main = Map<String, dynamic>.from(
              structured['mainText'] as Map? ?? {},
            );
            final secondary = Map<String, dynamic>.from(
              structured['secondaryText'] as Map? ?? {},
            );
            final text = Map<String, dynamic>.from(pred['text'] as Map? ?? {});
            final placeId = pred['placeId']?.toString() ?? '';
            if (placeId.isEmpty) return null;
            return PrintPlaceSuggestion(
              placeId: placeId,
              primaryText: main['text']?.toString() ??
                  text['text']?.toString() ??
                  '',
              secondaryText: secondary['text']?.toString() ?? '',
            );
          })
          .whereType<PrintPlaceSuggestion>()
          .toList();
    } on DioException catch (e) {
      lastError = _dioMessage(e) ?? 'msg_print_places_denied'.tr;
      return const [];
    } catch (_) {
      lastError = 'msg_print_places_denied'.tr;
      return const [];
    }
  }

  Future<PrintResolvedPlace?> details(String placeId) async {
    lastError = null;
    if (placeId.isEmpty || _key.isEmpty) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://places.googleapis.com/v1/places/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _key,
            'X-Goog-FieldMask':
                'id,displayName,formattedAddress,location,addressComponents',
          },
        ),
      );
      final data = res.data;
      if (data == null) return null;
      if (data['error'] != null) {
        lastError = data['error']?['message']?.toString();
        return null;
      }
      final location =
          Map<String, dynamic>.from(data['location'] as Map? ?? {});
      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final components =
          (data['addressComponents'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      final displayName =
          Map<String, dynamic>.from(data['displayName'] as Map? ?? {});
      final labels = _labelsFromNewComponents(
        components,
        fallbackAddress: data['formattedAddress']?.toString() ??
            displayName['text']?.toString() ??
            '',
      );
      return PrintResolvedPlace(
        latLng: LatLng(lat, lng),
        labels: labels,
      );
    } on DioException catch (e) {
      lastError = _dioMessage(e);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PrintPlaceLabels?> reverseGeocode(double lat, double lng) async {
    lastError = null;
    if (_key.isEmpty) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _key,
          'language': 'en',
        },
      );
      final data = res.data;
      if (data == null) return null;
      final status = data['status']?.toString();
      if (status == 'REQUEST_DENIED') {
        lastError = data['error_message']?.toString() ?? status;
        return null;
      }
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        lastError = data['error_message']?.toString() ?? status;
        return null;
      }
      final results = data['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;
      final first = Map<String, dynamic>.from(results.first as Map);
      final components = (first['address_components'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return _labelsFromLegacyComponents(
        components,
        fallbackAddress: first['formatted_address']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  String? _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
      if (data['error_message'] != null) return data['error_message'].toString();
    }
    return e.message;
  }

  PrintPlaceLabels _labelsFromNewComponents(
    List<Map<String, dynamic>> components, {
    required String fallbackAddress,
  }) {
    String? pick(List<String> types) {
      for (final c in components) {
        final typeList =
            (c['types'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        if (types.any(typeList.contains)) {
          final name = c['longText']?.toString().trim() ?? '';
          if (name.isNotEmpty) return name;
        }
      }
      return null;
    }

    final streetNumber = pick(['street_number']);
    final route = pick(['route']);
    final neighborhood = pick([
      'neighborhood',
      'sublocality_level_1',
      'sublocality',
    ]);
    final locality = pick(['locality', 'postal_town']);
    final admin = pick(['administrative_area_level_2', 'administrative_area_level_1']);

    final street = [
      if (streetNumber != null) streetNumber,
      if (route != null) route,
    ].join(' ').trim();

    final address = [
      if (street.isNotEmpty) street,
      if (neighborhood != null && neighborhood != street) neighborhood,
      if (locality != null) locality,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final district = [
      if (neighborhood != null) neighborhood,
      if (locality != null && locality != neighborhood) locality,
      if (admin != null && admin != locality && admin != neighborhood) admin,
    ].take(2).join(', ');

    return PrintPlaceLabels(
      address: address.isNotEmpty ? address : fallbackAddress.trim(),
      district: district,
    );
  }

  PrintPlaceLabels _labelsFromLegacyComponents(
    List<Map<String, dynamic>> components, {
    required String fallbackAddress,
  }) {
    String? pick(List<String> types) {
      for (final c in components) {
        final typeList =
            (c['types'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        if (types.any(typeList.contains)) {
          final name = c['long_name']?.toString().trim() ?? '';
          if (name.isNotEmpty) return name;
        }
      }
      return null;
    }

    final streetNumber = pick(['street_number']);
    final route = pick(['route']);
    final neighborhood = pick([
      'neighborhood',
      'sublocality_level_1',
      'sublocality',
    ]);
    final locality = pick(['locality', 'postal_town']);
    final admin = pick(['administrative_area_level_2', 'administrative_area_level_1']);

    final street = [
      if (streetNumber != null) streetNumber,
      if (route != null) route,
    ].join(' ').trim();

    final address = [
      if (street.isNotEmpty) street,
      if (neighborhood != null && neighborhood != street) neighborhood,
      if (locality != null) locality,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final district = [
      if (neighborhood != null) neighborhood,
      if (locality != null && locality != neighborhood) locality,
      if (admin != null && admin != locality && admin != neighborhood) admin,
    ].take(2).join(', ');

    return PrintPlaceLabels(
      address: address.isNotEmpty ? address : fallbackAddress.trim(),
      district: district,
    );
  }
}
