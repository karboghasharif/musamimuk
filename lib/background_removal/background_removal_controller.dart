import 'package:flutter/foundation.dart';
import 'package:musamimuk/background_removal/background_removal_service.dart';
import 'package:musamimuk/background_removal/background_removal_state.dart';
import 'package:musamimuk/data/models/background_removal_api_models.dart';

/// Manages in-editor background removal lifecycle: validation, loading,
/// duplicate-request guard, and result delivery.
class BackgroundRemovalController extends ChangeNotifier {
  BackgroundRemovalController({BackgroundRemovalService? service})
      : _service = service ?? BackgroundRemovalService();

  final BackgroundRemovalService _service;

  BackgroundRemovalState _state = BackgroundRemovalState.idle;
  BackgroundRemovalState get state => _state;

  bool get isBusy => _state.isBusy;

  Future<Uint8List?> removeBackground(
    Uint8List imageBytes, {
    String? sourceFilename,
  }) async {
    if (_state.isBusy) return null;

    _emit(
      _state.copyWith(
        status: BackgroundRemovalStatus.validating,
        clearError: true,
        clearResult: true,
        badgeMessage: 'AI Processing...',
        progressTitle: 'Removing background...',
        progressSubtitle: 'This may take up to 2 minutes.',
      ),
    );

    final validationError = _service.validateImageBytes(imageBytes);
    if (validationError != null) {
      _emit(
        _state.copyWith(
          status: BackgroundRemovalStatus.failure,
          errorMessage: validationError,
          errorKind: validationError.contains('10 MB')
              ? BackgroundRemovalErrorKind.fileTooLarge
              : BackgroundRemovalErrorKind.invalidFormat,
          badgeMessage: null,
          progressTitle: null,
          progressSubtitle: null,
        ),
      );
      return null;
    }

    _emit(
      _state.copyWith(
        status: BackgroundRemovalStatus.processing,
        badgeMessage: 'AI Processing...',
        progressTitle: 'Removing background...',
        progressSubtitle: 'This may take up to 2 minutes.',
      ),
    );

    final result = await _service.removeBackground(
      imageBytes,
      sourceFilename: sourceFilename,
    );

    if (result.isSuccess && result.bytes != null) {
      _emit(
        _state.copyWith(
          status: BackgroundRemovalStatus.success,
          resultBytes: result.bytes,
          badgeMessage: null,
          progressTitle: null,
          progressSubtitle: null,
          clearError: true,
        ),
      );
      return result.bytes;
    }

    _emit(
      _state.copyWith(
        status: BackgroundRemovalStatus.failure,
        errorMessage: result.message ??
            'Unable to remove background. Please try again later.',
        errorKind: result.kind,
        badgeMessage: null,
        progressTitle: null,
        progressSubtitle: null,
      ),
    );
    return null;
  }

  void reset() {
    if (_state.status == BackgroundRemovalStatus.idle &&
        _state.errorMessage == null &&
        _state.resultBytes == null) {
      return;
    }
    _emit(BackgroundRemovalState.idle);
  }

  void _emit(BackgroundRemovalState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
