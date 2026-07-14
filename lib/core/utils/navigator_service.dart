import 'package:flutter/material.dart';

import '../session/session_manager.dart';

class NavigatorService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic> pushNamed(
    String routeName, {
    dynamic arguments,
  }) async {
    if (!_allowRoute(routeName, arguments: arguments)) return null;
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  /// Pushes [routeName] only when the user has a valid API session.
  static Future<dynamic> pushNamedAuthRequired(
    String routeName, {
    dynamic arguments,
  }) async {
    if (!SessionManager.instance.requireAuthenticated(
      routeName: routeName,
      arguments: arguments,
    )) {
      return null;
    }
    return pushNamed(routeName, arguments: arguments);
  }

  static bool _allowRoute(String routeName, {dynamic arguments}) {
    if (!SessionManager.protectedRoutes.contains(routeName)) return true;
    return SessionManager.instance.requireAuthenticated(
      routeName: routeName,
      arguments: arguments,
    );
  }

  static Future<dynamic> pushReplacementNamed(
    String routeName, {
    dynamic arguments,
  }) async {
    if (!_allowRoute(routeName, arguments: arguments)) return null;
    return navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void goBack() {
    return navigatorKey.currentState?.pop();
  }

  static Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    bool routePredicate = false,
    dynamic arguments,
  }) async {
    if (!_allowRoute(routeName, arguments: arguments)) return null;
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName, (route) => routePredicate,
        arguments: arguments);
  }

  static Future<dynamic> popAndPushNamed(
    String routeName, {
    dynamic arguments,
  }) async {
    if (!_allowRoute(routeName, arguments: arguments)) return null;
    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }
}
