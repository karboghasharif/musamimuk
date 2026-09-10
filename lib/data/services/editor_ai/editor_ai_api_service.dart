import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_mapper.dart';
import '../../../core/network/api_utils.dart';
import '../../models/editor_ai_api_models.dart';
import '../../models/wallet_models.dart';

class EditorAiApiException implements Exception {
  const EditorAiApiException({
    required this.message,
    this.statusCode,
    this.retryable = false,
    this.requiresSignIn = false,
    this.insufficientCoins = false,
    this.insufficient,
  });

  final String message;
  final int? statusCode;
  final bool retryable;
  final bool requiresSignIn;
  final bool insufficientCoins;
  final InsufficientCoinsInfo? insufficient;

  @override
  String toString() => message;
}

/// Authenticated Musamimuk backend API for editor AI operations.
class EditorAiApiService {
  EditorAiApiService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  static const Duration _aiTimeout = Duration(seconds: 120);

  /// Last wallet snapshot parsed from a successful AI response (if any).
  WalletBalance? lastWalletFromResponse;

  Options get _aiOptions => Options(
        connectTimeout: _aiTimeout,
        sendTimeout: _aiTimeout,
        receiveTimeout: _aiTimeout,
      );

  Future<OpenAiEditorResponse> sendOpenAiEditor(
    OpenAiEditorRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'ai/editor/openai',
        data: request.toJson(),
        options: _aiOptions,
      );
      return OpenAiEditorResponse.fromJson(_unwrapAiBody(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (_) {
      throw const EditorAiApiException(
        message: 'The AI provider returned an invalid response. Please retry.',
        retryable: true,
      );
    }
  }

  Future<OpenAiImageResponse> generateOpenAiImage(
    OpenAiImageRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'ai/editor/openai/images',
        data: request.toJson(),
        options: _aiOptions,
      );
      return OpenAiImageResponse.fromJson(_unwrapAiBody(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (_) {
      throw const EditorAiApiException(
        message: 'Image generation returned an invalid response. Please retry.',
        retryable: true,
      );
    }
  }

  Future<OpenAiEditorResponse> sendGrokEditor(
    OpenAiEditorRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'ai/editor/grok',
        data: request.toJson(),
        options: _aiOptions,
      );
      return OpenAiEditorResponse.fromJson(_unwrapAiBody(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (_) {
      throw const EditorAiApiException(
        message: 'The AI provider returned an invalid response. Please retry.',
        retryable: true,
      );
    }
  }

  Future<GeminiEditorResponse> sendGemini(GeminiEditorRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'ai/editor/gemini',
        data: request.toJson(),
        options: _aiOptions,
      );
      return GeminiEditorResponse.fromJson(_unwrapAiBody(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (_) {
      throw const EditorAiApiException(
        message: 'The AI provider returned an invalid response. Please retry.',
        retryable: true,
      );
    }
  }

  Future<Uint8List> downloadGeneratedAsset(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Empty generated asset');
      }
      return Uint8List.fromList(bytes);
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (_) {
      throw const EditorAiApiException(
        message: 'The generated image could not be loaded. Please retry.',
        retryable: true,
      );
    }
  }

  Map<String, dynamic> _unwrapAiBody(Map<String, dynamic>? body) {
    if (body == null) throw const FormatException('Empty response');
    lastWalletFromResponse = walletBalanceFromPayload(body) ??
        walletBalanceFromPayload(apiExtractPayloadMap(body));

    // Vendor-shaped OpenAI / Gemini payloads.
    if (body.containsKey('choices') || body.containsKey('candidates')) {
      return body;
    }
    // OpenAI images use `data: [ { b64_json / url } ]`.
    if (body['data'] is List) {
      return body;
    }
    final payload = apiExtractPayloadMap(body);
    if (payload != null) {
      lastWalletFromResponse =
          walletBalanceFromPayload(payload) ?? lastWalletFromResponse;
      if (payload.containsKey('choices') ||
          payload.containsKey('candidates') ||
          payload['data'] is List) {
        return payload;
      }
      return payload;
    }
    return body;
  }

  EditorAiApiException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final serverMessage = apiExtractMessage(error.response?.data)?.trim();
    if (ApiErrorMapper.isInsufficientCoins(error)) {
      return EditorAiApiException(
        message: serverMessage?.isNotEmpty == true
            ? serverMessage!
            : 'Not enough coins.',
        statusCode: status ?? 402,
        insufficientCoins: true,
        insufficient: InsufficientCoinsInfo.fromResponse(
          body: error.response?.data,
          fallbackMessage: serverMessage,
        ),
      );
    }
    switch (status) {
      case 401:
        return const EditorAiApiException(
          message: 'Please sign in to use AI tools.',
          statusCode: 401,
          requiresSignIn: true,
        );
      case 422:
        return EditorAiApiException(
          message: serverMessage?.isNotEmpty == true
              ? serverMessage!
              : 'Please check your AI request and try again.',
          statusCode: 422,
        );
      case 429:
        final retryAfter = error.response?.headers.value('retry-after');
        return EditorAiApiException(
          message: retryAfter?.isNotEmpty == true
              ? 'AI rate limit reached. Try again in $retryAfter seconds.'
              : 'AI rate limit reached. Please wait and try again.',
          statusCode: 429,
          retryable: true,
        );
      case 502:
      case 503:
      case 504:
        return EditorAiApiException(
          message: 'The AI provider is temporarily unavailable. Please retry.',
          statusCode: status,
          retryable: true,
        );
      default:
        return EditorAiApiException(
          message: apiMessageFromDioException(error),
          statusCode: status,
          retryable:
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout,
        );
    }
  }
}
