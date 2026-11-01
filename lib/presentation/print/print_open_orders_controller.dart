import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/pref_utils.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_live.dart';

/// Tracks the designer's open print jobs for the global bottom dock.
class PrintOpenOrdersController extends ChangeNotifier {
  PrintOpenOrdersController._();

  static final PrintOpenOrdersController instance =
      PrintOpenOrdersController._();

  final _repo = PrintRepository();
  Timer? _poll;
  VoidCallback? _stopLive;
  bool _started = false;
  bool _refreshing = false;
  bool minimized = false;
  String? _dismissedFingerprint;

  List<PrintOrder> openOrders = const [];

  bool get hasOpen => openOrders.isNotEmpty;

  PrintOrder? get primary {
    if (openOrders.isEmpty) return null;
    final ranked = List<PrintOrder>.from(openOrders)
      ..sort((a, b) => _rank(a).compareTo(_rank(b)));
    return ranked.first;
  }

  int get extraCount {
    final total = openOrders.length;
    return total > 1 ? total - 1 : 0;
  }

  bool get isDismissed {
    final order = primary;
    if (order == null || _dismissedFingerprint == null) return false;
    return _dismissedFingerprint == _fingerprint(order);
  }

  bool get shouldShowDock {
    if (!_started || !hasOpen || isDismissed) return false;
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) return false;
    if (prefs.getWorkMode() != PrefUtils.workModeNormal) return false;
    return true;
  }

  void start() {
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) {
      stop();
      return;
    }
    _ensurePolling();
    unawaited(refresh());
    notifyListeners();
  }

  void _ensurePolling() {
    if (_started) return;
    _started = true;
    _poll = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
    _stopLive = PrintLive.instance.listen(refresh);
    unawaited(refresh());
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _stopLive?.call();
    _stopLive = null;
    _started = false;
    if (openOrders.isNotEmpty || minimized || _dismissedFingerprint != null) {
      openOrders = const [];
      minimized = false;
      _dismissedFingerprint = null;
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
      final result = await _repo.myOrders();
      if (result is! PrintSuccess<List<PrintOrder>>) return;
      final next = result.data
          .where(
            (o) => o.status != 'completed' && o.status != 'cancelled',
          )
          .toList(growable: false);
      final changed = !_sameOrders(openOrders, next);
      openOrders = next;
      var dismissedCleared = false;
      if (_dismissedFingerprint != null) {
        final still =
            next.any((o) => _fingerprint(o) == _dismissedFingerprint);
        if (!still) {
          _dismissedFingerprint = null;
          dismissedCleared = true;
        }
      }
      if (changed || dismissedCleared) notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  void minimize() {
    if (minimized) return;
    minimized = true;
    notifyListeners();
  }

  void expand() {
    if (!minimized) return;
    minimized = false;
    notifyListeners();
  }

  void dismissPrimary() {
    final order = primary;
    if (order == null) return;
    _dismissedFingerprint = _fingerprint(order);
    minimized = false;
    notifyListeners();
  }

  void onWorkModeChanged() {
    if (PrefUtils().getWorkMode() != PrefUtils.workModeNormal) {
      notifyListeners();
      return;
    }
    start();
    notifyListeners();
  }

  static int _rank(PrintOrder order) {
    if (order.status == 'awaiting_payment') return 0;
    if (order.status == 'quote' && order.offeredQuote != null) return 1;
    if (order.status == 'ready' || order.status == 'out_for_delivery') return 2;
    if (order.status == 'printing' || order.status == 'quality_check') return 3;
    return 10;
  }

  static String _fingerprint(PrintOrder order) =>
      '${order.id}:${order.status}:${order.offeredQuote?.id ?? 0}';

  static bool _sameOrders(List<PrintOrder> a, List<PrintOrder> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].status != b[i].status) return false;
      if ((a[i].offeredQuote?.id ?? 0) != (b[i].offeredQuote?.id ?? 0)) {
        return false;
      }
    }
    return true;
  }
}
