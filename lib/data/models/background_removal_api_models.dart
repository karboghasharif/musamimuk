import 'package:musamimuk/data/models/wallet_models.dart';

/// Server response payload for `POST /remove-background`.
class BackgroundRemovalApiData {
  const BackgroundRemovalApiData({
    required this.imageUrl,
    this.filename,
  });

  final String imageUrl;
  final String? filename;

  factory BackgroundRemovalApiData.fromJson(Map<String, dynamic> json) {
    return BackgroundRemovalApiData(
      imageUrl: json['image_url']?.toString() ?? '',
      filename: json['filename']?.toString(),
    );
  }
}

/// Typed failure categories mapped to user-facing copy.
enum BackgroundRemovalErrorKind {
  invalidFormat,
  fileTooLarge,
  timeout,
  apiFailure,
  network,
  insufficientCoins,
}

sealed class BackgroundRemovalApiResult {}

class BackgroundRemovalApiSuccess extends BackgroundRemovalApiResult {
  BackgroundRemovalApiSuccess({
    required this.data,
    this.message,
    this.wallet,
  });

  final BackgroundRemovalApiData data;
  final String? message;
  final WalletBalance? wallet;
}

class BackgroundRemovalApiFailure extends BackgroundRemovalApiResult {
  BackgroundRemovalApiFailure({
    required this.kind,
    required this.message,
    this.insufficient,
  });

  final BackgroundRemovalErrorKind kind;
  final String message;
  final InsufficientCoinsInfo? insufficient;
}
