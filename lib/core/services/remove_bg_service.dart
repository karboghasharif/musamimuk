import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Legacy compatibility surface with third-party client egress disabled.
class RemoveBgService {
  Future<Uint8List?> removeBackground(Uint8List imageBytes) async => null;

  /// Remove background with progress callback
  Future<Uint8List?> removeBackgroundWithProgress(
    Uint8List imageBytes,
    Function(double progress)? onProgress,
  ) async {
    onProgress?.call(0.0);
    return null;
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
    } catch (_) {
      return null;
    }
  }

  /// Check if API key is configured
  static bool isApiKeyConfigured() {
    return false;
  }

  static void setApiKey(String apiKey) {}

  /// Get service information
  static Map<String, dynamic> getServiceInfo() {
    return {
      'name': 'Remove.bg',
      'description': 'Professional background removal service',
      'apiKeyRequired': true,
      'apiKeyConfigured': isApiKeyConfigured(),
    };
  }
}

/// Enhanced background removal service with remove_bg as primary method
class EnhancedRemoveBgService {
  final RemoveBgService _removeBgService = RemoveBgService();

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

        Uint8List? result = await _removeBgService.removeBackgroundWithProgress(
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
