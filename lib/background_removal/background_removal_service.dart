import 'dart:convert';
import 'dart:typed_data';

import 'package:musamimuk/data/models/background_removal_api_models.dart';
import 'package:musamimuk/data/repositories/background_removal_repository.dart';

/// Orchestrates validation, caching, API upload, and PNG download for
/// server-side background removal.
class BackgroundRemovalService {
  BackgroundRemovalService({BackgroundRemovalRepository? repository})
      : _repository = repository ?? BackgroundRemovalRepository();

  final BackgroundRemovalRepository _repository;

  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const int maxRetries = 1;

  final Map<String, Uint8List> _processedCache = <String, Uint8List>{};

  /// Validates format and size before upload. Returns a user-facing message
  /// when invalid, or `null` when OK.
  String? validateImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return 'Unsupported file format. Please upload JPG, PNG, JPEG or WEBP.';
    }
    if (bytes.length > maxFileSizeBytes) {
      return 'Image size must be less than 10 MB.';
    }
    if (!_isSupportedFormat(bytes)) {
      return 'Unsupported file format. Please upload JPG, PNG, JPEG or WEBP.';
    }
    return null;
  }

  /// Removes the background via the musamimuk API and returns processed PNG bytes.
  Future<BackgroundRemovalProcessResult> removeBackground(
    Uint8List imageBytes, {
    String? sourceFilename,
    bool allowRetry = true,
  }) async {
    final validationError = validateImageBytes(imageBytes);
    if (validationError != null) {
      return BackgroundRemovalProcessResult.failure(
        kind: validationError.contains('10 MB')
            ? BackgroundRemovalErrorKind.fileTooLarge
            : BackgroundRemovalErrorKind.invalidFormat,
        message: validationError,
      );
    }

    final cacheKey = _cacheKeyFor(imageBytes);
    final cached = _processedCache[cacheKey];
    if (cached != null) {
      return BackgroundRemovalProcessResult.success(bytes: cached, fromCache: true);
    }

    final uploadName = sourceFilename ?? _inferFilename(imageBytes);
    var attempt = 0;
    var lastFailure = BackgroundRemovalProcessResult.failure(
      kind: BackgroundRemovalErrorKind.apiFailure,
      message: 'Unable to remove background. Please try again later.',
    );

    while (attempt <= (allowRetry ? maxRetries : 0)) {
      final apiResult = await _repository.removeBackground(
        imageBytes: imageBytes,
        filename: uploadName,
      );

      switch (apiResult) {
        case BackgroundRemovalApiSuccess(:final data):
          final downloaded = await _repository.downloadProcessedImage(
            data.imageUrl,
          );
          if (downloaded == null || downloaded.isEmpty) {
            lastFailure = BackgroundRemovalProcessResult.failure(
              kind: BackgroundRemovalErrorKind.network,
              message:
                  'No internet connection. Check your network and try again.',
            );
          } else {
            final pngBytes = Uint8List.fromList(downloaded);
            _processedCache[cacheKey] = pngBytes;
            return BackgroundRemovalProcessResult.success(
              bytes: pngBytes,
              imageUrl: data.imageUrl,
            );
          }
        case BackgroundRemovalApiFailure(:final kind, :final message):
          lastFailure = BackgroundRemovalProcessResult.failure(
            kind: kind,
            message: message,
          );
          final shouldRetry = allowRetry &&
              attempt < maxRetries &&
              (kind == BackgroundRemovalErrorKind.timeout ||
                  kind == BackgroundRemovalErrorKind.network);
          if (!shouldRetry) {
            return lastFailure;
          }
      }

      attempt++;
    }

    return lastFailure;
  }

  void clearCache() => _processedCache.clear();

  String _cacheKeyFor(Uint8List bytes) {
    final sampleLength = bytes.length < 512 ? bytes.length : 512;
    final sample = base64Url.encode(bytes.sublist(0, sampleLength));
    return '${bytes.length}_$sample';
  }

  bool _isSupportedFormat(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true; // JPEG
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true; // PNG
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true; // WEBP
    }
    return false;
  }

  String _inferFilename(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image.jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image.png';
    }
    if (bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image.webp';
    }
    return 'image.jpg';
  }
}

class BackgroundRemovalProcessResult {
  const BackgroundRemovalProcessResult._({
    required this.isSuccess,
    this.bytes,
    this.imageUrl,
    this.kind,
    this.message,
    this.fromCache = false,
  });

  factory BackgroundRemovalProcessResult.success({
    required Uint8List bytes,
    String? imageUrl,
    bool fromCache = false,
  }) {
    return BackgroundRemovalProcessResult._(
      isSuccess: true,
      bytes: bytes,
      imageUrl: imageUrl,
      fromCache: fromCache,
    );
  }

  factory BackgroundRemovalProcessResult.failure({
    required BackgroundRemovalErrorKind kind,
    required String message,
  }) {
    return BackgroundRemovalProcessResult._(
      isSuccess: false,
      kind: kind,
      message: message,
    );
  }

  final bool isSuccess;
  final Uint8List? bytes;
  final String? imageUrl;
  final BackgroundRemovalErrorKind? kind;
  final String? message;
  final bool fromCache;
}
