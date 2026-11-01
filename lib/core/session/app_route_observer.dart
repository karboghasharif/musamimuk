import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Tracks the active named route for session redirects and auth guards.
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>>
    with ChangeNotifier {
  AppRouteObserver._();

  static final AppRouteObserver instance = AppRouteObserver._();

  String? currentRouteName;
  dynamic currentArguments;

  bool _notifyScheduled = false;

  void _capture(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      final changed = currentRouteName != name ||
          !identical(currentArguments, route.settings.arguments);
      currentRouteName = name;
      currentArguments = route.settings.arguments;
      if (changed) _scheduleNotify();
    }
  }

  /// Navigator callbacks run during build/restore; defer listeners to avoid
  /// `setState() called during build` when hosts listen to this observer.
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      _notifyScheduled = false;
      notifyListeners();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) _capture(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) _capture(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) _capture(previousRoute);
  }
}
