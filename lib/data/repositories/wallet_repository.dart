import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_error_mapper.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/wallet_models.dart';

sealed class WalletResult<T> {}

class WalletSuccess<T> extends WalletResult<T> {
  WalletSuccess(this.data, {this.message});
  final T data;
  final String? message;
}

class WalletFailure<T> extends WalletResult<T> {
  WalletFailure(
    this.message, {
    this.isInsufficientCoins = false,
    this.insufficient,
    this.isGuestForbidden = false,
    this.requiresReLogin = false,
  });

  final String message;
  final bool isInsufficientCoins;
  final InsufficientCoinsInfo? insufficient;
  final bool isGuestForbidden;
  final bool requiresReLogin;
}

/// Wallet + IAP verify API (`/wallet/*`).
///
/// Server is the source of truth for balances — never credit/debit locally.
class WalletRepository {
  WalletRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static String storePlatform() {
    if (kIsWeb) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  /// GET `/wallet`
  Future<WalletResult<WalletBalance>> getWallet() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('wallet');
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return WalletFailure(
          apiExtractMessage(envelope) ?? 'Unable to load wallet.',
        );
      }
      final payload = apiExtractPayloadMap(envelope);
      if (payload == null) {
        return WalletFailure('Unable to load wallet.');
      }
      return WalletSuccess(
        WalletBalance.fromJson(payload),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return WalletFailure('Unable to load wallet.');
    }
  }

  /// GET `/wallet/costs`
  Future<WalletResult<List<WalletFeatureCost>>> getCosts() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('wallet/costs');
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return WalletFailure(
          apiExtractMessage(envelope) ?? 'Unable to load coin costs.',
        );
      }
      final payload = apiExtractPayloadMap(envelope) ?? envelope;
      var list = _extractList(payload, keys: const ['costs', 'items']);
      if (list.isEmpty) {
        list = apiExtractDbDataList(envelope);
      }
      return WalletSuccess(
        list.map(WalletFeatureCost.fromJson).toList(growable: false),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return WalletFailure('Unable to load coin costs.');
    }
  }

  /// GET `/wallet/packages?platform=android|ios`
  Future<WalletResult<List<WalletPackage>>> getPackages({
    String? platform,
  }) async {
    final plat = platform ?? storePlatform();
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'wallet/packages',
        queryParameters: {'platform': plat},
      );
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return WalletFailure(
          apiExtractMessage(envelope) ?? 'Unable to load coin packages.',
        );
      }
      final payload = apiExtractPayloadMap(envelope) ?? envelope;
      var list = _extractList(payload, keys: const ['packages', 'items']);
      if (list.isEmpty) {
        list = apiExtractDbDataList(envelope);
      }
      return WalletSuccess(
        list.map(WalletPackage.fromJson).toList(growable: false),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return WalletFailure('Unable to load coin packages.');
    }
  }

  /// GET `/wallet/transactions?per_page=&page=`
  Future<WalletResult<WalletTransactionsPage>> getTransactions({
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'wallet/transactions',
        queryParameters: {
          'per_page': perPage,
          'page': page,
        },
      );
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return WalletFailure(
          apiExtractMessage(envelope) ?? 'Unable to load transactions.',
        );
      }
      final payload = apiExtractPayloadMap(envelope) ?? envelope;
      final itemsRaw = _extractList(
        payload,
        keys: const ['transactions', 'items', 'data'],
      );
      final meta = _extractMeta(payload, envelope);
      return WalletSuccess(
        WalletTransactionsPage(
          items: itemsRaw
              .map(WalletTransaction.fromJson)
              .toList(growable: false),
          currentPage: apiParseInt(meta['current_page'], fallback: page),
          lastPage: apiParseInt(meta['last_page'], fallback: 1),
          perPage: apiParseInt(meta['per_page'], fallback: perPage),
          total: apiParseInt(meta['total'], fallback: itemsRaw.length),
        ),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return WalletFailure('Unable to load transactions.');
    }
  }

  /// POST `/wallet/iap/verify` — credit coins after a store purchase.
  Future<WalletResult<WalletIapVerifyResult>> verifyIap({
    required String platform,
    required String productId,
    required String storeTransactionId,
    String? purchaseToken,
    String? packageName,
    String? receiptData,
  }) async {
    try {
      final body = <String, dynamic>{
        'platform': platform,
        'product_id': productId,
        'store_transaction_id': storeTransactionId,
        if (platform == 'android') ...{
          if (purchaseToken != null) 'purchase_token': purchaseToken,
          if (packageName != null) 'package_name': packageName,
        },
        if (platform == 'ios' && receiptData != null)
          'receipt_data': receiptData,
      };
      final response = await _api.dio.post<Map<String, dynamic>>(
        'wallet/iap/verify',
        data: body,
        options: Options(
          // Purchase verify should surface its own errors.
          extra: const {ApiErrorMapper.skipSessionHandlingKey: true},
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return WalletFailure(
          apiExtractMessage(envelope) ?? 'Could not verify purchase.',
        );
      }
      final payload = apiExtractPayloadMap(envelope) ?? envelope;
      return WalletSuccess(
        WalletIapVerifyResult.fromPayload(
          payload,
          message: apiExtractMessage(envelope),
        ),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return _failureFromDio(e);
    } catch (_) {
      return WalletFailure('Could not verify purchase.');
    }
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> payload, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    // Some endpoints return the list directly as dbData.
    final asList = apiExtractDbDataList(payload);
    if (asList.isNotEmpty) return asList;
    return const [];
  }

  Map<String, dynamic> _extractMeta(
    Map<String, dynamic> payload,
    Map<String, dynamic> envelope,
  ) {
    final meta = payload['meta'] ?? envelope['meta'] ?? payload['pagination'];
    if (meta is Map) return meta.cast<String, dynamic>();
    return {
      'current_page': payload['current_page'],
      'last_page': payload['last_page'],
      'per_page': payload['per_page'],
      'total': payload['total'],
    };
  }

  WalletFailure<T> _failureFromDio<T>(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (ApiErrorMapper.isInsufficientCoins(e)) {
      return WalletFailure(
        apiMessageFromDioException(e),
        isInsufficientCoins: true,
        insufficient: InsufficientCoinsInfo.fromResponse(
          body: body,
          fallbackMessage: apiMessageFromDioException(e),
        ),
      );
    }
    if (ApiErrorMapper.isGuestForbidden(e)) {
      return WalletFailure(
        apiMessageFromDioException(e),
        isGuestForbidden: true,
      );
    }
    if (status == 401) {
      return WalletFailure(
        apiMessageFromDioException(e),
        requiresReLogin: true,
      );
    }
    return WalletFailure(apiMessageFromDioException(e));
  }
}
