import 'package:flutter/material.dart';

/// Tracks the active named route for session redirects and auth guards.
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  AppRouteObserver._();

  static final AppRouteObserver instance = AppRouteObserver._();

  String? currentRouteName;
  dynamic currentArguments;

  void _capture(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      currentRouteName = name;
      currentArguments = route.settings.arguments;
    }
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
