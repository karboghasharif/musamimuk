import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/core/utils/pref_utils.dart';
import 'package:musamimuk/data/models/print_models.dart';
import 'package:musamimuk/data/repositories/print_repository.dart';

/// One Reverb socket for the signed-in user. Print screens listen and reload
/// when `print.marketplace` arrives. Polling stays as the fallback.
class PrintLive {
  PrintLive._();

  static final PrintLive instance = PrintLive._();

  final List<VoidCallback> _listeners = [];
  PusherChannelsClient? _client;
  StreamSubscription<void>? _connectionSub;
  StreamSubscription<ChannelReadEvent>? _eventSub;
  bool _starting = false;

  VoidCallback listen(VoidCallback onEvent) {
    _listeners.add(onEvent);
    unawaited(_ensure());
    return () {
      _listeners.remove(onEvent);
      if (_listeners.isEmpty) {
        _close();
      }
    };
  }

  Future<void> _ensure() async {
    if (_client != null || _starting || _listeners.isEmpty) return;
    _starting = true;
    try {
      final result = await PrintRepository().realtime();
      if (_listeners.isEmpty) return;
      if (result is! PrintSuccess<Map<String, dynamic>>) return;
      final data = result.data;
      if (data['enabled'] != true) return;

      final key = data['key']?.toString() ?? '';
      final host = data['host']?.toString() ?? '';
      final scheme = data['scheme']?.toString() == 'https' ? 'wss' : 'ws';
      final port = apiParseInt(data['port'], fallback: 443);
      final userId = apiParseInt(data['user_id']);
      final authEndpoint = data['auth_endpoint']?.toString() ?? '';
      final token = PrefUtils().getToken() ?? '';
      if (key.isEmpty ||
          host.isEmpty ||
          userId <= 0 ||
          authEndpoint.isEmpty ||
          token.isEmpty ||
          _listeners.isEmpty) {
        return;
      }

      final client = PusherChannelsClient.websocket(
        options: PusherChannelsOptions.fromHost(
          scheme: scheme,
          host: host,
          key: key,
          port: port,
        ),
        connectionErrorHandler: (exception, trace, refresh) {
          refresh();
        },
        minimumReconnectDelayDuration: const Duration(seconds: 2),
      );
      final channel = client.privateChannel(
        'private-print.user.$userId',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(authEndpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      _connectionSub = client.onConnectionEstablished.listen((_) {
        channel.subscribeIfNotUnsubscribed();
      });
      _eventSub = channel.bind('print.marketplace').listen((_) {
        for (final listener in List<VoidCallback>.from(_listeners)) {
          listener();
        }
      });
      if (_listeners.isEmpty) {
        client.dispose();
        return;
      }
      _client = client;
      client.connect();
    } catch (_) {
      _close();
    } finally {
      _starting = false;
    }
  }

  void _close() {
    _connectionSub?.cancel();
    _eventSub?.cancel();
    _connectionSub = null;
    _eventSub = null;
    _client?.dispose();
    _client = null;
  }
}
