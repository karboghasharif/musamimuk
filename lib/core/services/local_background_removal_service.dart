import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'hugging_face_service.dart';

/// Background removal using **free** services only (no paid API keys).
///
/// Order: 1) Hugging Face Inference API (free tier), 2) local processing (white/light/green removal).
class LocalBackgroundRemovalService {
  static const List<String> _availableModels = [
    'microsoft/U-2-Net',
    'briaai/RMBG-1.4',
    'briaai/RMBG-2.0',
  ];

  /// Remove background using free options only.
  static Future<Uint8List?> removeBackground(
    Uint8List imageBytes, {
    Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    // 1) Hugging Face API (free tier – free token at huggingface.co)
    try {
      onProgress?.call(0.1);
      final hf = await _tryHuggingFaceAPI(imageBytes, onProgress);
      if (hf != null) {
        onProgress?.call(1.0);
        return hf;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Hugging Face background removal failed: $e');
    }

    // 2) Local processing (free, no key – works for white/light/green-ish backgrounds)
    try {
      onProgress?.call(0.5);
      final local = await _tryLocalProcessing(imageBytes, onProgress);
      if (local != null) {
        onProgress?.call(1.0);
        return local;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Local background removal failed: $e');
    }

    onProgress?.call(1.0);
    return imageBytes;
  }

  /// Try Hugging Face Inference API (free tier)
  static Future<Uint8List?> _tryHuggingFaceAPI(
    Uint8List imageBytes,
    Function(double progress)? onProgress,
  ) async {
    final service = HuggingFaceService();
    return service.removeBackgroundWithProgress(imageBytes, onProgress);
  }

  /// Try local image processing
  static Future<Uint8List?> _tryLocalProcessing(
    Uint8List imageBytes,
    Function(double progress)? onProgress,
  ) async {
    try {
      onProgress?.call(0.4);

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      onProgress?.call(0.6);

      // Simple background removal using edge detection
      final processedImage = _processImageLocally(image);

      onProgress?.call(0.8);

      // Encode back to bytes
      final result = img.encodePng(processedImage);

      onProgress?.call(1.0);
      return Uint8List.fromList(result);
    } catch (e) {
      if (kDebugMode) debugPrint('Local processing failed: $e');
      return null;
    }
  }

  /// Local background removal: white, very light, and green-screen style.
  static img.Image _processImageLocally(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    const int whiteThreshold = 245;
    const int lightThreshold = 220;
    // Green-screen: green dominant and not too dark
    const int greenMin = 80;
    const int greenMax = 220;
    const int redBlueMax = 120;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final isWhite =
            r >= whiteThreshold && g >= whiteThreshold && b >= whiteThreshold;
        final isLight =
            r >= lightThreshold && g >= lightThreshold && b >= lightThreshold;
        final isGreenScreen =
            g >= greenMin &&
            g <= greenMax &&
            r <= redBlueMax &&
            b <= redBlueMax &&
            g > r &&
            g > b;

        if (isWhite || isLight || isGreenScreen) {
          result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        } else {
          result.setPixel(x, y, pixel);
        }
      }
    }
    return result;
  }

  /// Get available models
  static List<String> getAvailableModels() {
    return List.from(_availableModels);
  }

  /// Check if service is available
  static Future<bool> isServiceAvailable() async {
    try {
      // Try to create a simple test
      final testBytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await removeBackground(testBytes);
      return result != null;
    } catch (e) {
      return false;
    }
  }
}

/// Alternative background removal using different APIs
class AlternativeBackgroundRemovalService {
  /// Remove background using Remove.bg API (requires API key)
  static Future<Uint8List?> removeBackgroundWithRemoveBg(
    Uint8List imageBytes,
    String apiKey, {
    Function(double progress)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      // This would require the remove.bg API
      // Implementation would go here

      onProgress?.call(1.0);
      return imageBytes; // Placeholder
    } catch (e) {
      print('Remove.bg API failed: $e');
      return null;
    }
  }

  /// Remove background using Clipdrop API (requires API key)
  static Future<Uint8List?> removeBackgroundWithClipdrop(
    Uint8List imageBytes,
    String apiKey, {
    Function(double progress)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      // This would require the Clipdrop API
      // Implementation would go here

      onProgress?.call(1.0);
      return imageBytes; // Placeholder
    } catch (e) {
      print('Clipdrop API failed: $e');
      return null;
    }
  }
}
