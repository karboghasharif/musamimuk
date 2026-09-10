import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/print_models.dart';

class PrintRepository {
  PrintRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<PrintResult<PrintOrder>> createJob({
    required int designId,
    required PrintSpec spec,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/jobs',
        data: {'design_id': designId, 'spec': spec.toJson()},
      ),
    );
  }

  Future<PrintResult<List<PrintShopSummary>>> searchShops({
    double? lat,
    double? lng,
    double? distance,
    double? rating,
    double? price,
    bool openNow = false,
    String? q,
    String? sort,
    int? level,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'print/shops',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (distance != null) 'distance': distance,
          if (rating != null) 'rating': rating,
          if (price != null) 'price': price,
          if (openNow) 'open_now': true,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
          if (level != null) 'level': level,
        },
      );
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(apiExtractMessage(data) ?? 'Unable to load shops.');
      }
      return PrintSuccess(
        apiExtractDataList(data).map(PrintShopSummary.fromJson).toList(),
      );
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintShopSummary>> shopProfile(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('print/shops/$id');
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Shop not found.',
        );
      }
      return PrintSuccess(PrintShopSummary.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintOrder>> startChat({
    required int shopId,
    required int orderId,
    required String body,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/shops/$shopId/chat',
        data: {'order_id': orderId, 'body': body},
      ),
    );
  }

  Future<PrintResult<List<PrintOrder>>> myOrders() {
    return _sendOrderList(() => _dio.get<Map<String, dynamic>>('print/orders'));
  }

  Future<PrintResult<PrintOrder>> order(int id) {
    return _sendOrder(() => _dio.get<Map<String, dynamic>>('print/orders/$id'));
  }

  Future<PrintResult<PrintOrder>> acceptQuote({
    required int orderId,
    required int quoteId,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/quotes/$quoteId/accept',
      ),
    );
  }

  Future<PrintResult<PrintOrder>> pay({
    required int orderId,
    required String method,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/pay',
        data: {'method': method},
      ),
    );
  }

  Future<PrintResult<PrintOrder>> sendMessage({
    required int orderId,
    required String body,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/messages',
        data: {'body': body},
      ),
    );
  }

  Future<PrintResult<PrintOrder>> createQuote({
    required int orderId,
    String? note,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/quotes',
        data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
      ),
    );
  }

  Future<PrintResult<PrintOrder>> advance({
    required int orderId,
    required String action,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/advance',
        data: {'action': action},
      ),
    );
  }

  Future<PrintResult<PrintShopSummary?>> myShop() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('print/shop/me');
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(apiExtractMessage(data) ?? 'Unable to load shop.');
      }
      final map = apiExtractPayloadMap(data);
      if (map == null || map.isEmpty) {
        return PrintSuccess(null);
      }
      return PrintSuccess(PrintShopSummary.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintShopSummary>> registerShop({
    required String name,
    String? nameAr,
    required String ownerName,
    required String phone,
    String? crNumber,
    String? vatNumber,
    String? iban,
    double? lat,
    double? lng,
    String? address,
    String? district,
    String? about,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'print/shop/register',
        data: {
          'name': name,
          if (nameAr != null) 'name_ar': nameAr,
          'owner_name': ownerName,
          'phone': phone,
          if (crNumber != null) 'cr_number': crNumber,
          if (vatNumber != null) 'vat_number': vatNumber,
          if (iban != null) 'iban': iban,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (address != null) 'address': address,
          if (district != null) 'district': district,
          if (about != null) 'about': about,
        },
      );
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Registration failed.',
        );
      }
      return PrintSuccess(PrintShopSummary.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<List<PrintOrder>>> shopOrders() {
    return _sendOrderList(
      () => _dio.get<Map<String, dynamic>>('print/shop/orders'),
    );
  }

  Future<PrintResult<List<PrintNotice>>> notices() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('print/notices');
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(
          apiExtractMessage(data) ?? 'Unable to load notices.',
        );
      }
      return PrintSuccess(
        apiExtractDataList(data).map(PrintNotice.fromJson).toList(),
      );
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintOrder>> confirmPickup(int orderId) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/pickup/confirm',
      ),
    );
  }

  Future<PrintResult<PrintOrder>> verifyPickup({
    required int orderId,
    required String code,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/pickup/verify',
        data: {'code': code},
      ),
    );
  }

  Future<PrintResult<PrintDeliveryQuote>> previewDelivery({
    required int orderId,
    required String address,
    required double lat,
    required double lng,
  }) {
    return _sendDeliveryQuote(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/delivery',
        data: {'address': address, 'lat': lat, 'lng': lng},
      ),
    );
  }

  Future<PrintResult<PrintDeliveryQuote>> confirmDelivery(int orderId) {
    return _sendDeliveryQuote(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/delivery/confirm',
      ),
      acceptConflict: true,
    );
  }

  Future<PrintResult<PrintDeliveryQuote>> deliveryStatus(int orderId) {
    return _sendDeliveryQuote(
      () => _dio.get<Map<String, dynamic>>('print/orders/$orderId/delivery'),
    );
  }

  Future<PrintResult<PrintOrder>> verifyDeliveryOtp({
    required int orderId,
    required String otp,
  }) {
    return _sendOrder(
      () => _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/delivery/otp',
        data: {'otp': otp},
      ),
    );
  }

  Future<PrintResult<PrintRiderProfile?>> myRider() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('print/rider/me');
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(apiExtractMessage(data) ?? 'Unable to load rider.');
      }
      final map = apiExtractPayloadMap(data);
      if (map == null || map.isEmpty) {
        return PrintSuccess(null);
      }
      return PrintSuccess(PrintRiderProfile.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintRiderProfile>> registerRider({
    required String name,
    required String phone,
    String? nationalId,
    String? vehicle,
    String? plate,
    String? iban,
    String? district,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'print/rider/register',
        data: {
          'name': name,
          'phone': phone,
          if (nationalId != null) 'national_id': nationalId,
          if (vehicle != null) 'vehicle': vehicle,
          if (plate != null) 'plate': plate,
          if (iban != null) 'iban': iban,
          if (district != null) 'district': district,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Registration failed.',
        );
      }
      return PrintSuccess(PrintRiderProfile.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintRiderProfile>> setRiderOnline({
    required bool online,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'print/rider/online',
        data: {
          'online': online,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Unable to update availability.',
        );
      }
      return PrintSuccess(PrintRiderProfile.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<List<PrintDeliveryInfo>>> riderJobs() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('print/rider/jobs');
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(apiExtractMessage(data) ?? 'Unable to load jobs.');
      }
      return PrintSuccess(
        apiExtractDataList(data).map(PrintDeliveryInfo.fromJson).toList(),
      );
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintDeliveryInfo>> acceptDelivery(int deliveryId) {
    return _sendDelivery(
      () => _dio.post<Map<String, dynamic>>(
        'print/deliveries/$deliveryId/accept',
      ),
    );
  }

  Future<PrintResult<PrintDeliveryInfo>> advanceDelivery({
    required int deliveryId,
    required String action,
    String? code,
  }) {
    return _sendDelivery(
      () => _dio.post<Map<String, dynamic>>(
        'print/deliveries/$deliveryId/advance',
        data: {
          'action': action,
          if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
        },
      ),
    );
  }

  Future<PrintResult<PrintReview>> submitReview({
    required int orderId,
    required String target,
    required Map<String, int> scores,
    String? comment,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/reviews',
        data: {
          'target': target,
          'scores': scores,
          if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        },
      );
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Review failed.',
        );
      }
      return PrintSuccess(PrintReview.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<List<PrintReview>>> shopReviews(int shopId) {
    return _sendReviews('print/shops/$shopId/reviews');
  }

  Future<PrintResult<List<PrintReview>>> riderReviews(int riderId) {
    return _sendReviews('print/riders/$riderId/reviews');
  }

  Future<PrintResult<PrintReputation>> myReputation() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'print/me/reputation',
      );
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Unable to load reputation.',
        );
      }
      return PrintSuccess(PrintReputation.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintEarnings>> shopEarnings() {
    return _sendEarnings('print/shop/earnings');
  }

  Future<PrintResult<PrintEarnings>> riderEarnings() {
    return _sendEarnings('print/rider/earnings');
  }

  Future<PrintResult<PrintEarnings>> withdrawShop({
    double? amount,
    String method = 'iban',
    String? destination,
  }) {
    return _sendWithdraw(
      'print/shop/withdraw',
      amount: amount,
      method: method,
      destination: destination,
    );
  }

  Future<PrintResult<PrintEarnings>> withdrawRider({
    double? amount,
    String method = 'iban',
    String? destination,
  }) {
    return _sendWithdraw(
      'print/rider/withdraw',
      amount: amount,
      method: method,
      destination: destination,
    );
  }

  Future<PrintResult<PrintDispute>> createDispute({
    required int orderId,
    required String issue,
    String? evidence,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/disputes',
        data: {
          'issue': issue,
          if (evidence != null && evidence.trim().isNotEmpty)
            'evidence': evidence.trim(),
        },
      );
      return _parseDispute(response.data, 'Unable to open dispute.');
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintDispute>> replyDispute({
    required int orderId,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'print/orders/$orderId/disputes/reply',
        data: {'body': body},
      );
      return _parseDispute(response.data, 'Unable to reply to dispute.');
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintEarnings>> _sendEarnings(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Unable to load earnings.',
        );
      }
      return PrintSuccess(PrintEarnings.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintEarnings>> _sendWithdraw(
    String path, {
    double? amount,
    required String method,
    String? destination,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          if (amount != null) 'amount': amount,
          'method': method,
          if (destination != null && destination.trim().isNotEmpty)
            'destination': destination.trim(),
        },
      );
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Withdrawal failed.',
        );
      }
      final wallet = map['wallet'];
      return PrintSuccess(
        PrintEarnings.fromJson(
          wallet is Map ? wallet.cast<String, dynamic>() : map,
        ),
      );
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  PrintResult<PrintDispute> _parseDispute(
    Map<String, dynamic>? data,
    String fallback,
  ) {
    final map = apiExtractPayloadMap(data);
    if (data == null || !apiResponseIsSuccess(data) || map == null) {
      return PrintFailure(apiExtractMessage(data) ?? fallback);
    }
    return PrintSuccess(PrintDispute.fromJson(map));
  }

  Future<PrintResult<List<PrintReview>>> _sendReviews(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(
          apiExtractMessage(data) ?? 'Unable to load reviews.',
        );
      }
      final map = apiExtractPayloadMap(data);
      final raw = map?['reviews'] ?? apiExtractDataList(data);
      final list = raw is List ? raw : const [];
      return PrintSuccess(
        list
            .whereType<Map>()
            .map((e) => PrintReview.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintOrder>> _sendOrder(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Print request failed.',
        );
      }
      return PrintSuccess(PrintOrder.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<List<PrintOrder>>> _sendOrderList(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null || !apiResponseIsSuccess(data)) {
        return PrintFailure(
          apiExtractMessage(data) ?? 'Unable to load orders.',
        );
      }
      return PrintSuccess(
        apiExtractDataList(data).map(PrintOrder.fromJson).toList(),
      );
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  Future<PrintResult<PrintDeliveryQuote>> _sendDeliveryQuote(
    Future<Response<Map<String, dynamic>>> Function() request, {
    bool acceptConflict = false,
  }) async {
    try {
      final response = await request();
      return _parseDeliveryQuote(response.data);
    } on DioException catch (e) {
      if (acceptConflict && e.response?.statusCode == 409) {
        final parsed = _parseDeliveryQuote(e.response?.data);
        if (parsed is PrintSuccess<PrintDeliveryQuote>) {
          return parsed;
        }
      }
      return PrintFailure(apiMessageFromDioException(e));
    }
  }

  PrintResult<PrintDeliveryQuote> _parseDeliveryQuote(
    Map<String, dynamic>? data,
  ) {
    final map = apiExtractPayloadMap(data);
    if (data == null || map == null) {
      return PrintFailure(apiExtractMessage(data) ?? 'Delivery request failed.');
    }
    return PrintSuccess(PrintDeliveryQuote.fromJson(map));
  }

  Future<PrintResult<PrintDeliveryInfo>> _sendDelivery(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final map = apiExtractPayloadMap(response.data);
      if (response.data == null ||
          !apiResponseIsSuccess(response.data!) ||
          map == null) {
        return PrintFailure(
          apiExtractMessage(response.data) ?? 'Delivery request failed.',
        );
      }
      return PrintSuccess(PrintDeliveryInfo.fromJson(map));
    } on DioException catch (e) {
      return PrintFailure(apiMessageFromDioException(e));
    }
  }
}
