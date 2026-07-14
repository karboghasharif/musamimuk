import 'dart:typed_data';

import 'package:musamimuk/data/models/background_removal_api_models.dart';

enum BackgroundRemovalStatus {
  idle,
  validating,
  processing,
  success,
  failure,
}

class BackgroundRemovalState {
  const BackgroundRemovalState({
    this.status = BackgroundRemovalStatus.idle,
    this.badgeMessage,
    this.progressTitle,
    this.progressSubtitle,
    this.errorMessage,
    this.errorKind,
    this.resultBytes,
  });

  final BackgroundRemovalStatus status;
  final String? badgeMessage;
  final String? progressTitle;
  final String? progressSubtitle;
  final String? errorMessage;
  final BackgroundRemovalErrorKind? errorKind;
  final Uint8List? resultBytes;

  bool get isBusy =>
      status == BackgroundRemovalStatus.validating ||
      status == BackgroundRemovalStatus.processing;

  BackgroundRemovalState copyWith({
    BackgroundRemovalStatus? status,
    String? badgeMessage,
    String? progressTitle,
    String? progressSubtitle,
    String? errorMessage,
    BackgroundRemovalErrorKind? errorKind,
    Uint8List? resultBytes,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return BackgroundRemovalState(
      status: status ?? this.status,
      badgeMessage: badgeMessage ?? this.badgeMessage,
      progressTitle: progressTitle ?? this.progressTitle,
      progressSubtitle: progressSubtitle ?? this.progressSubtitle,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorKind: clearError ? null : (errorKind ?? this.errorKind),
      resultBytes: clearResult ? null : (resultBytes ?? this.resultBytes),
    );
  }

  static const idle = BackgroundRemovalState();
}
