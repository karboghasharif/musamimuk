import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/pref_utils.dart';
import '../../data/repositories/notification_repository.dart';
import '../print/print_live.dart';

/// Live unread count for the main drawer badge.
class NotificationInboxController extends ChangeNotifier {
  NotificationInboxController._();

  static final NotificationInboxController instance =
      NotificationInboxController._();

  final _repo = NotificationRepository();
  Timer? _poll;
  VoidCallback? _stopLive;
  VoidCallback? _releaseSession;
  bool _started = false;
  bool _refreshing = false;
  int unreadCount = 0;

  void start() {
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) {
      stop();
      return;
    }
    if (_started) {
      unawaited(refresh());
      return;
    }
    _started = true;
    _releaseSession = PrintLive.instance.holdSession();
    _stopLive = PrintLive.instance.listenNotifications(refresh);
    _poll = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
    unawaited(refresh());
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _stopLive?.call();
    _stopLive = null;
    _releaseSession?.call();
    _releaseSession = null;
    _started = false;
    if (unreadCount != 0) {
      unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) {
      stop();
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    try {
      final result = await _repo.unreadCount();
      if (result is! UnreadCountSuccess) return;
      if (unreadCount == result.unreadCount) return;
      unreadCount = result.unreadCount;
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }
}
