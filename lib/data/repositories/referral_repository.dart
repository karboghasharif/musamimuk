import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_utils.dart';

sealed class ReferralResult<T> {
  const ReferralResult();
}

class ReferralSuccess<T> extends ReferralResult<T> {
  const ReferralSuccess(this.data);
  final T data;
}

class ReferralFailure<T> extends ReferralResult<T> {
  const ReferralFailure(this.message);
  final String message;
}

class ReferralRepository {
  ReferralRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<ReferralResult<Map<String, dynamic>>> settings() {
    return _getMap('referrals/settings');
  }

  Future<ReferralResult<Map<String, dynamic>?>> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('referrals/me');
      final data = response.data?['data'];
      if (data == null) {
        return const ReferralSuccess(null);
      }
      if (data is Map<String, dynamic>) {
        return ReferralSuccess(data);
      }
      return const ReferralSuccess(null);
    } on DioException catch (e) {
      return ReferralFailure(apiExtractMessage(e.response?.data) ?? e.message ?? 'Request failed');
    } catch (e) {
      return ReferralFailure(e.toString());
    }
  }

  Future<ReferralResult<Map<String, dynamic>>> apply({
    required String iban,
    String? displayName,
    String? bankName,
    String? accountName,
    String? notes,
  }) {
    return _postMap('referrals/apply', {
      'iban': iban,
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
      if (bankName != null && bankName.isNotEmpty) 'bank_name': bankName,
      if (accountName != null && accountName.isNotEmpty) 'account_name': accountName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<ReferralResult<Map<String, dynamic>>> withdraw({
    required double amount,
    String? iban,
  }) {
    return _postMap('referrals/withdraw', {
      'amount': amount,
      if (iban != null && iban.isNotEmpty) 'iban': iban,
    });
  }

  Future<ReferralResult<List<Map<String, dynamic>>>> withdrawals() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('referrals/withdrawals');
      final data = response.data?['data'];
      if (data is List) {
        return ReferralSuccess(
          data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(),
        );
      }
      return const ReferralSuccess([]);
    } on DioException catch (e) {
      return ReferralFailure(apiExtractMessage(e.response?.data) ?? e.message ?? 'Request failed');
    } catch (e) {
      return ReferralFailure(e.toString());
    }
  }

  Future<ReferralResult<Map<String, dynamic>>> _getMap(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return ReferralSuccess(data);
      }
      return const ReferralFailure('Unexpected response');
    } on DioException catch (e) {
      return ReferralFailure(apiExtractMessage(e.response?.data) ?? e.message ?? 'Request failed');
    } catch (e) {
      return ReferralFailure(e.toString());
    }
  }

  Future<ReferralResult<Map<String, dynamic>>> _postMap(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return ReferralSuccess(data);
      }
      return const ReferralFailure('Unexpected response');
    } on DioException catch (e) {
      return ReferralFailure(apiExtractMessage(e.response?.data) ?? e.message ?? 'Request failed');
    } catch (e) {
      return ReferralFailure(e.toString());
    }
  }
}
