import 'package:flutter/foundation.dart';

/// App-wide full-screen loading overlay controller.
///
/// Use [show] / [hide] in pairs (reference-counted) so concurrent operations
/// do not dismiss the overlay early.
class GlobalLoadingController extends ChangeNotifier {
  GlobalLoadingController._();

  static final GlobalLoadingController instance = GlobalLoadingController._();

  int _depth = 0;
  String? _message;

  bool get isLoading => _depth > 0;
  String? get message => _message;

  void show([String? message]) {
    _depth++;
    if (message != null && message.isNotEmpty) {
      _message = message;
    }
    notifyListeners();
  }

  void hide() {
    if (_depth <= 0) return;
    _depth--;
    if (_depth == 0) _message = null;
    notifyListeners();
  }

  /// Runs [task] while showing the global overlay.
  Future<T> during<T>(
    Future<T> Function() task, {
    String? message,
  }) async {
    show(message);
    try {
      return await task();
    } finally {
      hide();
    }
  }
}
