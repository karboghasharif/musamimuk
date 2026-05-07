import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for interacting with Hugging Face API for background removal
class HuggingFaceService {
  /// Legacy `api-inference.huggingface.co` often returns **HTTP 410 Gone** (retired).
  /// Consider migrating to the current [Inference API](https://huggingface.co/docs/inference-providers) router.
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';
  static const String _modelName =
      'microsoft/U-2-Net'; // Background removal model
  static const String _apiKey =
      'REMOVED_HF_TOKEN'; // Replace with your API key

  final Dio _dio = Dio();

  HuggingFaceService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  static void _logInferenceFailure(Object e) {
    if (!kDebugMode) return;
    debugPrint(
      'Hugging Face inference failed (${_hfErrorSummary(e)}). '
      'Using local background removal in [BackgroundRemovalService].',
    );
  }

  static String _hfErrorSummary(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      String? serverHint;
      if (data is Map) {
        serverHint = data['error']?.toString() ?? data['message']?.toString();
      }
      if (code == 410) {
        return '410 Gone — inference host retired; update endpoint or rely on local processing'
            '${serverHint != null ? ': $serverHint' : ''}';
      }
      return 'HTTP $code ${serverHint ?? e.message ?? e.toString()}';
    }
    return e.toString();
  }

  /// Remove background from image using Hugging Face API.
  /// Returns **null** on failure so [BackgroundRemovalService] can run local processing.
  Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    try {
      final String base64Image = base64Encode(imageBytes);

      final Map<String, dynamic> payload = {
        'inputs': base64Image,
        'parameters': {'return_mask': false, 'return_bbox': false},
      };

      final Response response = await _dio.post(
        '/$_modelName',
        data: payload,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $_apiKey'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Uint8List) return data;
        if (data is List<int>) return Uint8List.fromList(data);
      }
      throw Exception('Unexpected status: ${response.statusCode}');
    } catch (e) {
      _logInferenceFailure(e);
      return null;
    }
  }

  /// Remove background with progress callback
  Future<Uint8List?> removeBackgroundWithProgress(
    Uint8List imageBytes,
    Function(double progress)? onProgress,
  ) async {
    try {
      onProgress?.call(0.1);

      String base64Image = base64Encode(imageBytes);
      onProgress?.call(0.3);

      Map<String, dynamic> payload = {
        'inputs': base64Image,
        'parameters': {'return_mask': false, 'return_bbox': false},
      };

      onProgress?.call(0.5);

      Response response = await _dio.post(
        '/$_modelName',
        data: payload,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $_apiKey'},
        ),
        onSendProgress: (sent, total) {
          double progress = 0.5 + (sent / total) * 0.4;
          onProgress?.call(progress);
        },
      );

      onProgress?.call(0.9);

      if (response.statusCode == 200 && response.data != null) {
        onProgress?.call(1.0);
        final data = response.data;
        if (data is Uint8List) return data;
        if (data is List<int>) return Uint8List.fromList(data);
        throw Exception('Unexpected response body type');
      }
      throw Exception('Failed to remove background: ${response.statusCode}');
    } catch (e) {
      _logInferenceFailure(e);
      onProgress?.call(0.0);
      return null;
    }
  }

  /// Save processed image to device storage
  Future<String?> saveImageToDevice(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      Directory? directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/$fileName';
      File file = File(filePath);
      await file.writeAsBytes(imageBytes);
      return filePath;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving image: $e');
      return null;
    }
  }

  /// Get available background removal models
  static List<String> getAvailableModels() {
    return [
      'briaai/RMBG-1.4', // High quality background removal
      'briaai/RMBG-2.0', // Latest version
      'microsoft/U-2-Net', // Alternative model
    ];
  }

  /// Check if API key is configured
  static bool isApiKeyConfigured() {
    return _apiKey != 'REMOVED_HF_TOKEN' &&
        _apiKey.isNotEmpty;
  }

  /// Set API key
  static void setApiKey(String apiKey) {
    // In a real app, you'd want to store this securely
    // For now, we'll just update the constant
    // You should use secure storage for production
  }
}

/// Background removal result model
class BackgroundRemovalResult {
  final Uint8List? processedImage;
  final String? error;
  final double processingTime;
  final bool success;

  BackgroundRemovalResult({
    this.processedImage,
    this.error,
    required this.processingTime,
    required this.success,
  });
}

/// Background removal service with enhanced features
class EnhancedBackgroundRemovalService {
  final HuggingFaceService _hfService = HuggingFaceService();

  /// Remove background with enhanced error handling and retry logic
  Future<BackgroundRemovalResult> removeBackgroundEnhanced(
    Uint8List imageBytes, {
    int maxRetries = 3,
    Function(double progress)? onProgress,
  }) async {
    DateTime startTime = DateTime.now();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        onProgress?.call(0.0);

        Uint8List? result = await _hfService.removeBackgroundWithProgress(
          imageBytes,
          onProgress,
        );

        DateTime endTime = DateTime.now();
        double processingTime =
            endTime.difference(startTime).inMilliseconds / 1000.0;

        if (result != null) {
          return BackgroundRemovalResult(
            processedImage: result,
            processingTime: processingTime,
            success: true,
          );
        } else {
          if (attempt == maxRetries) {
            return BackgroundRemovalResult(
              error: 'Failed to remove background after $maxRetries attempts',
              processingTime: processingTime,
              success: false,
            );
          }
        }
      } catch (e) {
        if (attempt == maxRetries) {
          DateTime endTime = DateTime.now();
          double processingTime =
              endTime.difference(startTime).inMilliseconds / 1000.0;

          return BackgroundRemovalResult(
            error: 'Error removing background: $e',
            processingTime: processingTime,
            success: false,
          );
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    DateTime endTime = DateTime.now();
    double processingTime =
        endTime.difference(startTime).inMilliseconds / 1000.0;

    return BackgroundRemovalResult(
      error: 'Unknown error occurred',
      processingTime: processingTime,
      success: false,
    );
  }
}
