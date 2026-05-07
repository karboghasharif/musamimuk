import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:remove_bg/remove_bg.dart';

/// Service for background removal using remove_bg package
class RemoveBgService {
  static const String _apiKey =
      'u1HPQ4wdXaBztLcdCyGFunRP'; // Replace with your API key

  /// Remove background from image using remove_bg package
  Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    try {
      print('Using remove_bg service for background removal...');

      // Create a temporary file to save the input image
      final tempDir = await getTemporaryDirectory();
      final inputFile = File('${tempDir.path}/input_image.png');
      await inputFile.writeAsBytes(imageBytes);

      // Use remove_bg package to remove background
      final result = await Remove().bg(
        inputFile,
        privateKey: _apiKey,
        onUploadProgressCallback: (progress) {
          print('Upload Progress: $progress%');
        },
      );

      if (result != null) {
        // Clean up temporary files
        await inputFile.delete();

        return result;
      } else {
        print('Remove.bg service returned null result');
        return null;
      }
    } catch (e) {
      print('Error removing background with remove_bg: $e');
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
      print('Starting remove_bg background removal...');

      onProgress?.call(0.3);

      // Create a temporary file to save the input image
      final tempDir = await getTemporaryDirectory();
      final inputFile = File(
        '${tempDir.path}/input_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await inputFile.writeAsBytes(imageBytes);

      onProgress?.call(0.5);

      // Use remove_bg package to remove background
      final result = await Remove().bg(
        inputFile,
        privateKey: _apiKey,
        onUploadProgressCallback: (progress) {
          onProgress?.call(0.5 + (progress / 100) * 0.3);
        },
      );

      onProgress?.call(0.8);

      if (result != null) {
        onProgress?.call(0.9);

        // Clean up temporary files
        await inputFile.delete();

        onProgress?.call(1.0);
        return result;
      } else {
        print('Remove.bg service returned null result');
        onProgress?.call(0.0);
        return null;
      }
    } catch (e) {
      print('Error removing background with remove_bg: $e');
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
      print('Error saving image: $e');
      return null;
    }
  }

  /// Check if API key is configured
  static bool isApiKeyConfigured() {
    return _apiKey != 'u1HPQ4wdXaBztLcdCyGFunRP' && _apiKey.isNotEmpty;
  }

  /// Set API key (in a real app, you'd want to store this securely)
  static void setApiKey(String apiKey) {
    // In a real implementation, you'd update the service with the new API key
    // For now, this is a placeholder
    print('API key would be set to: ${apiKey.substring(0, 10)}...');
  }

  /// Get service information
  static Map<String, dynamic> getServiceInfo() {
    return {
      'name': 'Remove.bg',
      'description': 'Professional background removal service',
      'apiKeyRequired': true,
      'apiKeyConfigured': isApiKeyConfigured(),
      'website': 'https://www.remove.bg/',
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
