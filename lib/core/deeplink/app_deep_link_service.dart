import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../session/session_manager.dart';
import '../utils/logger.dart';
import '../utils/navigator_service.dart';
import 'app_deep_link.dart';
import 'app_link_config.dart';

/// Listens for App Links / custom-scheme URIs and routes inside the app.
class AppDeepLinkService {
  AppDeepLinkService._();

  static final AppDeepLinkService instance = AppDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final AppDeepLinkParser _parser = const AppDeepLinkParser();

  StreamSubscription<Uri>? _subscription;
  Uri? _pendingUri;
  bool _ready = false;
  bool _handling = false;

  /// Call once during app startup (before [runApp] is fine).
  Future<void> init() async {
    if (_subscription != null) return;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _pendingUri = initial;
      }
    } catch (e) {
      if (kDebugMode) Logger.log('Deep link initial read failed: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (_ready) {
          unawaited(handleUri(uri));
        } else {
          _pendingUri = uri;
        }
      },
      onError: (Object e) {
        if (kDebugMode) Logger.log('Deep link stream error: $e');
      },
    );
  }

  /// Call after splash has navigated to Home or Login.
  void markNavigationReady() {
    _ready = true;
    final pending = _pendingUri;
    _pendingUri = null;
    if (pending != null) {
      unawaited(handleUri(pending));
    }
  }

  Future<void> handleUri(Uri uri) async {
    if (_handling) {
      _pendingUri = uri;
      return;
    }
    final link = _parser.parse(uri);
    if (link == null) {
      if (kDebugMode) Logger.log('Unhandled deep link: $uri');
      return;
    }
    await _navigate(link);
  }

  Future<void> handleLink(AppDeepLink link) => _navigate(link);

  Future<void> _navigate(AppDeepLink link) async {
    _handling = true;
    try {
      if (link.target == AppDeepLinkTarget.playStore) {
        await _openPlayStore();
        return;
      }

      final route = link.routeName;
      final args = link.arguments;

      // Protected destinations wait for login, then resume.
      if (SessionManager.protectedRoutes.contains(route) &&
          !SessionManager.instance.canAccessRoute(route)) {
        SessionManager.instance.setPendingNavigation(route, arguments: args);
        if (!SessionManager.instance.isOnAuthScreen()) {
          SessionManager.instance.requireAuthenticated(
            routeName: route,
            arguments: args,
          );
        }
        return;
      }

      await _pushWhenNavigatorReady(route, args);
    } finally {
      _handling = false;
      final queued = _pendingUri;
      _pendingUri = null;
      if (queued != null) {
        unawaited(handleUri(queued));
      }
    }
  }

  Future<void> _pushWhenNavigatorReady(String route, dynamic args) async {
    Future<void> attempt() async {
      final nav = NavigatorService.navigatorKey.currentState;
      if (nav == null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          unawaited(attempt());
        });
        return;
      }
      await NavigatorService.pushNamed(route, arguments: args);
    }

    // Let splash / login replace finish first.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await attempt();
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(AppLinkConfig.playStoreUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) Logger.log('Play Store launch failed: $e');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
