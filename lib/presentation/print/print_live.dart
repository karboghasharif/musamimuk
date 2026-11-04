import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_client.dart' show baseUrl;
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/app_toast.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/print_models.dart';
import 'package:musamimuk/data/repositories/print_repository.dart';
import 'package:musamimuk/data/services/push/push_notification_service.dart';
import 'package:toastification/toastification.dart';

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
  StreamSubscription<ChannelReadEvent>? _printEventSubAlt;
  StreamSubscription<ChannelReadEvent>? _notificationEventSub;
  StreamSubscription<ChannelReadEvent>? _notificationEventSubAlt;
  StreamSubscription<ChannelReadEvent>? _printCatchAllSub;
  StreamSubscription<ChannelReadEvent>? _userCatchAllSub;
  bool _starting = false;
  int _sessionHolds = 0;
  DateTime? _lastNotifToastAt;
  DateTime? _lastPrintNotifyAt;

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

  /// Keep the socket alive for the signed-in session (designer dock / mode hubs).
  /// Uses a ref-count so shop/rider/designer hubs can overlap safely.
  VoidCallback holdSession() {
    _sessionHolds++;
    unawaited(_ensure());
    var released = false;
    return () {
      if (released) return;
      released = true;
      if (_sessionHolds > 0) _sessionHolds--;
      _maybeClose();
    };
  }

  void _maybeClose() {
    if (_listeners.isEmpty &&
        _notificationListeners.isEmpty &&
        _sessionHolds <= 0) {
      _close();
    }
  }

  bool get _hasListeners =>
      _listeners.isNotEmpty ||
      _notificationListeners.isNotEmpty ||
      _sessionHolds > 0;

  Future<void> _ensure() async {
    if (_client != null || _starting || !_hasListeners) return;
    _starting = true;
    try {
      final result = await PrintRepository().realtime();
      if (!_hasListeners) return;
      if (result is! PrintSuccess<Map<String, dynamic>>) {
        if (kDebugMode) debugPrint('PrintLive: realtime config failed');
        _scheduleRetry();
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
        _scheduleRetry();
        return;
      }

      final endpoint = _resolveEndpoint(data);
      if (endpoint == null) {
        if (kDebugMode) debugPrint('PrintLive: invalid host/auth endpoint');
        _scheduleRetry();
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
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: endpoint.authUri,
          headers: authHeaders,
        ),
      );
      final userChannel = client.privateChannel(
        'private-user.$userId',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
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

      void notifyPrintListeners() {
        final now = DateTime.now();
        final last = _lastPrintNotifyAt;
        if (last != null &&
            now.difference(last) < const Duration(milliseconds: 400)) {
          return;
        }
        _lastPrintNotifyAt = now;
        for (final listener in List<VoidCallback>.from(_listeners)) {
          listener();
        }
      }

      void notifyNotificationListeners(ChannelReadEvent? event) {
        _maybeToastNotification(event);
        for (final listener
            in List<VoidCallback>.from(_notificationListeners)) {
          listener();
        }
        notifyPrintListeners();
      }

      bool isPrintMarketplace(String name) =>
          name == 'print.marketplace' ||
          name == '.print.marketplace' ||
          name.endsWith('print.marketplace');

      bool isNotificationSent(String name) =>
          name == 'notification.sent' ||
          name == '.notification.sent' ||
          name.endsWith('notification.sent');

      _printEventSub =
          printChannel.bind('print.marketplace').listen((_) {
        if (kDebugMode) debugPrint('PrintLive ← print.marketplace');
        notifyPrintListeners();
      });
      _printEventSubAlt =
          printChannel.bind('.print.marketplace').listen((_) {
        if (kDebugMode) debugPrint('PrintLive ← .print.marketplace');
        notifyPrintListeners();
      });
      _notificationEventSub =
          userChannel.bind('notification.sent').listen((event) {
        if (kDebugMode) debugPrint('PrintLive ← notification.sent');
        notifyNotificationListeners(event);
      });
      _notificationEventSubAlt =
          userChannel.bind('.notification.sent').listen((event) {
        if (kDebugMode) debugPrint('PrintLive ← .notification.sent');
        notifyNotificationListeners(event);
      });

      // Catch-all in case Reverb/Pusher renames events slightly.
      _printCatchAllSub = printChannel.bindToAll().listen((event) {
        if (!isPrintMarketplace(event.name)) return;
        if (kDebugMode) {
          debugPrint('PrintLive ← catch-all ${event.name}');
        }
        notifyPrintListeners();
      });
      _userCatchAllSub = userChannel.bindToAll().listen((event) {
        if (!isNotificationSent(event.name)) return;
        if (kDebugMode) {
          debugPrint('PrintLive ← catch-all ${event.name}');
        }
        notifyNotificationListeners(event);
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
      _scheduleRetry();
    } finally {
      _starting = false;
    }
  }

  void _maybeToastNotification(ChannelReadEvent? event) {
    if (event == null) return;
    final now = DateTime.now();
    final last = _lastNotifToastAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    final map = _eventMap(event.data);
    final title = (map['title'] ?? '').toString().trim();
    final message = (map['message'] ?? map['body'] ?? '').toString().trim();
    if (title.isEmpty && message.isEmpty) return;
    _lastNotifToastAt = now;
    showAppToast(
      message.isEmpty ? title : (title.isEmpty ? message : '$title — $message'),
      type: ToastificationType.info,
      autoCloseDuration: const Duration(seconds: 5),
    );
    // Also post a system tray notification so it is visible if the toast is missed.
    unawaited(
      PushNotificationService.instance.showLocal(
        title: title.isEmpty ? 'Musamimuk' : title,
        body: message,
        data: map,
      ),
    );
  }

  Map<String, dynamic> _eventMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry('$key', value));
        }
      } catch (_) {}
    }
    return const {};
  }

  void _scheduleRetry() {
    if (!_hasListeners || _client != null) return;
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (_hasListeners && _client == null && !_starting) {
        unawaited(_ensure());
      }
    });
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
    _printEventSubAlt?.cancel();
    _notificationEventSub?.cancel();
    _notificationEventSubAlt?.cancel();
    _printCatchAllSub?.cancel();
    _userCatchAllSub?.cancel();
    _connectionSub = null;
    _printEventSub = null;
    _printEventSubAlt = null;
    _notificationEventSub = null;
    _notificationEventSubAlt = null;
    _printCatchAllSub = null;
    _userCatchAllSub = null;
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
