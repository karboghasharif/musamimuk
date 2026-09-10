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
}
