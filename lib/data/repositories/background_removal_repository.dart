import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/background_removal_api_models.dart';

class BackgroundRemovalRepository {
  BackgroundRemovalRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static const Duration _requestTimeout = Duration(seconds: 120);

  /// POST `/remove-background` with multipart field **`image`** (not `file`).
  Future<BackgroundRemovalApiResult> removeBackground({
    required List<int> imageBytes,
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
        ),
      });

      final response = await _api.dio.post<Map<String, dynamic>>(
        'remove-background',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          connectTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
        ),
      );

      final envelope = response.data;
      if (envelope == null) {
        return BackgroundRemovalApiFailure(
          kind: BackgroundRemovalErrorKind.apiFailure,
          message: 'Unable to remove background. Please try again later.',
        );
      }

      if (!apiResponseIsSuccess(envelope)) {
        return BackgroundRemovalApiFailure(
          kind: BackgroundRemovalErrorKind.apiFailure,
          message: apiExtractMessage(envelope) ??
              'Unable to remove background. Please try again later.',
        );
      }

      final payload = apiExtractPayloadMap(envelope);
      if (payload == null) {
        return BackgroundRemovalApiFailure(
          kind: BackgroundRemovalErrorKind.apiFailure,
          message: 'Unable to remove background. Please try again later.',
        );
      }

      final data = BackgroundRemovalApiData.fromJson(payload);
      if (data.imageUrl.trim().isEmpty) {
        return BackgroundRemovalApiFailure(
          kind: BackgroundRemovalErrorKind.apiFailure,
          message: 'Unable to remove background. Please try again later.',
        );
      }

      return BackgroundRemovalApiSuccess(
        data: data,
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return BackgroundRemovalApiFailure(
        kind: _kindFromDio(e),
        message: _messageFromDio(e),
      );
    } catch (_) {
      return BackgroundRemovalApiFailure(
        kind: BackgroundRemovalErrorKind.apiFailure,
        message: 'Unable to remove background. Please try again later.',
      );
    }
  }

  /// Downloads the processed transparent PNG from [url].
  Future<List<int>?> downloadProcessedImage(String url) async {
    try {
      final response = await _api.dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return data;
    } on DioException catch (e) {
      if (_isNetworkIssue(e)) return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  BackgroundRemovalErrorKind _kindFromDio(DioException e) {
    if (_isTimeout(e)) return BackgroundRemovalErrorKind.timeout;
    if (_isNetworkIssue(e)) return BackgroundRemovalErrorKind.network;
    return BackgroundRemovalErrorKind.apiFailure;
  }

  String _messageFromDio(DioException e) {
    if (_isTimeout(e)) {
      return 'Background removal is taking longer than expected. Please try again.';
    }
    if (_isNetworkIssue(e)) {
      return 'No internet connection. Check your network and try again.';
    }
    final fromBody = apiExtractMessage(e.response?.data);
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;
    return 'Unable to remove background. Please try again later.';
  }

  bool _isTimeout(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  bool _isNetworkIssue(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }
}
