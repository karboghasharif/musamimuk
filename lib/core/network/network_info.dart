import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:toastification/toastification.dart';

import '../utils/app_toast.dart';

/// For checking internet connectivity
abstract class NetworkInfoI {
  /// Checks if device is connected to internet
  /// Returns [true] if internet is connected, [false] otherwise
  Future<bool> isConnected();

  /// Gets current connectivity result
  /// Returns [List<ConnectivityResult>] containing current connection types
  Future<List<ConnectivityResult>> get connectivityResult;

  /// Stream of connectivity changes
  /// Returns [Stream<List<ConnectivityResult>>] for monitoring connection changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// NetworkInfo implementation using connectivity_plus package
class NetworkInfo implements NetworkInfoI {
  final Connectivity _connectivity;

  // Singleton pattern
  static final NetworkInfo _instance = NetworkInfo._internal(Connectivity());

  /// Factory constructor for singleton access
  factory NetworkInfo() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  NetworkInfo._internal(this._connectivity);

  /// Checks if internet is connected or not
  /// Returns [true] if internet is connected, [false] otherwise
  @override
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // Check if any connection type is available (not none)
      return result.any(
        (connectivity) => connectivity != ConnectivityResult.none,
      );
    } catch (e) {
      // If there's an error checking connectivity, assume no connection
      return false;
    }
  }

  /// Gets current connectivity result
  /// Returns [List<ConnectivityResult>] containing current connection types
  @override
  Future<List<ConnectivityResult>> get connectivityResult async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      // Return none if there's an error
      return [ConnectivityResult.none];
    }
  }

  /// Stream of connectivity changes
  /// Returns [Stream<List<ConnectivityResult>>] for monitoring connection changes
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}

/// Abstract base class for all failure types
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

/// Server-related exceptions
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server exception occurred']);

  @override
  String toString() => 'ServerException: $message';
}

/// Cache-related exceptions
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception occurred']);

  @override
  String toString() => 'CacheException: $message';
}

/// Network-related exceptions
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network exception occurred']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when no internet connection is available
/// Can be used for throwing [NoInternetException]
class NoInternetException implements Exception {
  final String _message;

  /// Creates a [NoInternetException] with optional custom message
  /// Shows a toast when [ToastificationWrapper] is initialized.
  NoInternetException([String message = 'No Internet Connection'])
    : _message = message {
    try {
      showAppToast(message, type: ToastificationType.error);
    } catch (e) {
      debugPrint('Error showing toast: $e');
    }
  }

  @override
  String toString() => 'NoInternetException: $_message';
}
