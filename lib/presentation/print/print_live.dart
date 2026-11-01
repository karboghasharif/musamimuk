import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_client.dart' show baseUrl;
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/print_models.dart';
import 'package:musamimuk/data/repositories/print_repository.dart';

/// One Reverb socket for the signed-in user.
///
/// Subscribes to:
/// - `private-print.user.{id}` → `print.marketplace`
/// - `private-user.{id}` → `notification.sent`
///
/// Print screens listen and reload; notification listeners refresh the drawer.
class PrintLive {
  PrintLive._();

  static final PrintLive instance = PrintLive._();

  final List<VoidCallback> _listeners = [];
  final List<VoidCallback> _notificationListeners = [];
  PusherChannelsClient? _client;
  StreamSubscription<void>? _connectionSub;
  StreamSubscription<ChannelReadEvent>? _printEventSub;
  StreamSubscription<ChannelReadEvent>? _notificationEventSub;
  bool _starting = false;

  VoidCallback listen(VoidCallback onEvent) {
    _listeners.add(onEvent);
    unawaited(_ensure());
    return () {
      _listeners.remove(onEvent);
      _maybeClose();
    };
  }

  /// Drawer / badge refresh when a Laravel DB notification is stored.
  VoidCallback listenNotifications(VoidCallback onEvent) {
    _notificationListeners.add(onEvent);
    unawaited(_ensure());
    return () {
      _notificationListeners.remove(onEvent);
      _maybeClose();
    };
  }

  void _maybeClose() {
    if (_listeners.isEmpty && _notificationListeners.isEmpty) {
      _close();
    }
  }

  bool get _hasListeners =>
      _listeners.isNotEmpty || _notificationListeners.isNotEmpty;

  Future<void> _ensure() async {
    if (_client != null || _starting || !_hasListeners) return;
    _starting = true;
    try {
      final result = await PrintRepository().realtime();
      if (!_hasListeners) return;
      if (result is! PrintSuccess<Map<String, dynamic>>) {
        if (kDebugMode) debugPrint('PrintLive: realtime config failed');
        return;
      }
      final data = result.data;
      if (data['enabled'] != true) {
        if (kDebugMode) {
          debugPrint('PrintLive: realtime disabled by server');
        }
        return;
      }

      final key = data['key']?.toString() ?? '';
      final userId = apiParseInt(data['user_id']);
      final token = PrefUtils().getToken() ?? '';
      if (key.isEmpty || userId <= 0 || token.isEmpty || !_hasListeners) {
        return;
      }

      final endpoint = _resolveEndpoint(data);
      if (endpoint == null) {
        if (kDebugMode) debugPrint('PrintLive: invalid host/auth endpoint');
        return;
      }

      final client = PusherChannelsClient.websocket(
        options: PusherChannelsOptions.fromHost(
          scheme: endpoint.wsScheme,
          host: endpoint.host,
          key: key,
          port: endpoint.port,
        ),
        connectionErrorHandler: (exception, trace, refresh) {
          if (kDebugMode) {
            debugPrint('PrintLive connection error: $exception');
          }
          refresh();
        },
        minimumReconnectDelayDuration: const Duration(seconds: 2),
      );

      final authHeaders = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final printChannel = client.privateChannel(
        'private-print.user.$userId',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: endpoint.authUri,
          headers: authHeaders,
        ),
      );
      final userChannel = client.privateChannel(
        'private-user.$userId',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: endpoint.authUri,
          headers: authHeaders,
        ),
      );

      _connectionSub = client.onConnectionEstablished.listen((_) {
        if (kDebugMode) {
          debugPrint(
            'PrintLive connected → ${endpoint.wsScheme}://${endpoint.host}:${endpoint.port}',
          );
        }
        printChannel.subscribeIfNotUnsubscribed();
        userChannel.subscribeIfNotUnsubscribed();
      });

      _printEventSub = printChannel.bind('print.marketplace').listen((_) {
        for (final listener in List<VoidCallback>.from(_listeners)) {
          listener();
        }
      });
      _notificationEventSub =
          userChannel.bind('notification.sent').listen((_) {
        for (final listener
            in List<VoidCallback>.from(_notificationListeners)) {
          listener();
        }
        // Print desks also refresh — notices badge / incoming lists.
        for (final listener in List<VoidCallback>.from(_listeners)) {
          listener();
        }
      });

      if (!_hasListeners) {
        client.dispose();
        return;
      }
      _client = client;
      client.connect();
    } catch (e, st) {
      if (kDebugMode) debugPrint('PrintLive start failed: $e\n$st');
      _close();
    } finally {
      _starting = false;
    }
  }

  /// Rewrite loopback hosts from a misconfigured server .env to the API host.
  _SocketEndpoint? _resolveEndpoint(Map<String, dynamic> data) {
    final apiUri = Uri.parse(baseUrl);
    var host = (data['host']?.toString() ?? '').trim();
    var scheme = (data['scheme']?.toString() ?? '').trim().toLowerCase();
    var port = apiParseInt(data['port'], fallback: 0);

    if (_isLoopback(host)) {
      host = apiUri.host;
      scheme = apiUri.scheme == 'https' ? 'https' : 'http';
      port = apiUri.hasPort
          ? apiUri.port
          : (scheme == 'https' ? 443 : 80);
    }
    if (host.isEmpty) return null;
    if (scheme != 'http' && scheme != 'https') {
      scheme = apiUri.scheme == 'https' ? 'https' : 'http';
    }
    if (port <= 0) {
      port = scheme == 'https' ? 443 : 80;
    }

    var authEndpoint = data['auth_endpoint']?.toString() ?? '';
    var authUri = Uri.tryParse(authEndpoint);
    if (authUri == null ||
        authEndpoint.isEmpty ||
        _isLoopback(authUri.host)) {
      authUri = Uri(
        scheme: apiUri.scheme,
        host: apiUri.host,
        port: apiUri.hasPort ? apiUri.port : null,
        path: '/broadcasting/auth',
      );
    }

    return _SocketEndpoint(
      host: host,
      port: port,
      wsScheme: scheme == 'https' ? 'wss' : 'ws',
      authUri: authUri,
    );
  }

  bool _isLoopback(String host) {
    final h = host.trim().toLowerCase();
    return h.isEmpty ||
        h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '0.0.0.0' ||
        h == '::1';
  }

  void _close() {
    _connectionSub?.cancel();
    _printEventSub?.cancel();
    _notificationEventSub?.cancel();
    _connectionSub = null;
    _printEventSub = null;
    _notificationEventSub = null;
    _client?.dispose();
    _client = null;
  }
}

class _SocketEndpoint {
  const _SocketEndpoint({
    required this.host,
    required this.port,
    required this.wsScheme,
    required this.authUri,
  });

  final String host;
  final int port;
  final String wsScheme;
  final Uri authUri;
}
