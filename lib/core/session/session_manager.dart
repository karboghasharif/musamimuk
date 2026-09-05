import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:toastification/toastification.dart';

import '../utils/app_toast.dart';
import '../utils/navigator_service.dart';
import '../utils/pref_utils.dart';
import '../../data/models/wallet_models.dart';
import '../../localization/app_localization.dart';
import '../../routes/app_routes.dart';
import 'app_route_observer.dart';

/// Pending navigation restored after a successful login.
class PendingNavigation {
  const PendingNavigation({required this.route, this.arguments});

  final String route;
  final dynamic arguments;
}

/// Centralized authentication / session lifecycle.
///
/// Handles JWT/session expiry, forced logout, and post-login redirects.
/// Safe to call from Dio interceptors (no infinite redirect loops).
class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  bool _handlingExpiry = false;
  PendingNavigation? _pendingNavigation;
  DateTime? _lastGuestPromptAt;
  DateTime? _lastInsufficientCoinsPromptAt;

  /// Presentation-layer hook that shows the "create a free account" prompt.
  /// Registered from the widget tree so this core class stays UI-agnostic.
  void Function(String message)? guestForbiddenHandler;

  /// Presentation-layer hook for HTTP 402 / insufficient coins.
  void Function(InsufficientCoinsInfo info)? insufficientCoinsHandler;

  /// Called after auth is cleared (logout / session expiry) so UI can reset
  /// in-memory wallet state.
  void Function()? authClearedHandler;

  /// True while a session-expiry redirect is in progress.
  bool get isHandlingExpiry => _handlingExpiry;

  /// Route to open after the next successful login, if any.
  PendingNavigation? get pendingNavigation => _pendingNavigation;

  /// Auth / public endpoints that must never trigger session-expiry handling.
  static const Set<String> _authPathFragments = {
    'user/login',
    'user/register',
    'user/guest-login',
    'user/google-login',
    'forgot-password',
    'reset-password',
    'user/logout',
  };

  /// Routes that are not restored after re-login.
  static const Set<String> _nonRestorableRoutes = {
    AppRoutes.initialRoute,
    AppRoutes.screenTwentythreeScreen,
    AppRoutes.screen0LoginScreen,
    AppRoutes.screen0RegisterScreen,
    AppRoutes.forgotPasswordScreen,
    AppRoutes.completeProfileScreen,
  };

  /// Routes that require a valid API session (Bearer token).
  static const Set<String> protectedRoutes = {
    AppRoutes.profileScreen,
    AppRoutes.changePasswordScreen,
    AppRoutes.screen18MyDesignsScreen,
    AppRoutes.openDesignDeepLinkScreen,
    AppRoutes.favoritesScreen,
    AppRoutes.notificationsScreen,
    AppRoutes.contestMySubmissionsScreen,
    AppRoutes.screen1SubcriptionScreen,
    AppRoutes.coinStoreScreen,
    AppRoutes.walletTransactionsScreen,
    AppRoutes.aiStudioImageScreen,
    AppRoutes.aiStudioDesignScreen,
    AppRoutes.aiStudioChatScreen,
    AppRoutes.aiStudioVisionScreen,
  };

  bool isAuthEndpoint(String path) {
    final normalized = path.toLowerCase();
    for (final fragment in _authPathFragments) {
      if (normalized.contains(fragment)) return true;
    }
    return false;
  }

  bool isOnAuthScreen() {
    final name = AppRouteObserver.instance.currentRouteName;
    if (name == null) return false;
    return name == AppRoutes.screen0LoginScreen ||
        name == AppRoutes.screen0RegisterScreen ||
        name == AppRoutes.forgotPasswordScreen ||
        name == AppRoutes.initialRoute ||
        name == AppRoutes.screenTwentythreeScreen;
  }

  /// Whether the user may open [routeName] without a live API token.
  bool canAccessRoute(String routeName) {
    if (!protectedRoutes.contains(routeName)) return true;
    return PrefUtils().isLoggedIn();
  }

  /// Guard for protected screens. Returns `true` when access is allowed.
  /// On failure, stores [routeName] for post-login redirect and opens Login.
  bool requireAuthenticated({
    String? routeName,
    dynamic arguments,
    bool showMessage = true,
  }) {
    if (PrefUtils().isLoggedIn()) {
      return true;
    }
    final route = routeName ?? AppRouteObserver.instance.currentRouteName;
    if (route != null && !_nonRestorableRoutes.contains(route)) {
      _pendingNavigation = PendingNavigation(
        route: route,
        arguments: arguments,
      );
    }
    if (showMessage) {
      _showToast(
        AppLocalization.translate('msg_sign_in_required'),
        ToastificationType.warning,
      );
    }
    _navigateToLogin();
    return false;
  }

  /// Remember where the user was so we can return after login.
  void rememberCurrentRouteAsPending() {
    final route = AppRouteObserver.instance.currentRouteName;
    final args = AppRouteObserver.instance.currentArguments;
    if (route == null || _nonRestorableRoutes.contains(route)) return;
    _pendingNavigation = PendingNavigation(route: route, arguments: args);
  }

  /// Store a deep-link / feature destination for after a successful login.
  void setPendingNavigation(String route, {dynamic arguments}) {
    if (_nonRestorableRoutes.contains(route)) return;
    _pendingNavigation = PendingNavigation(
      route: route,
      arguments: arguments,
    );
  }

  /// Consumes and clears the pending post-login navigation target.
  PendingNavigation? takePendingNavigation() {
    final pending = _pendingNavigation;
    _pendingNavigation = null;
    return pending;
  }

  void clearPendingNavigation() {
    _pendingNavigation = null;
  }

  /// Voluntary logout (drawer / profile). No "session expired" toast.
  Future<void> logout({bool callApi = false}) async {
    _pendingNavigation = null;
    await PrefUtils().clearAuth();
    authClearedHandler?.call();
    _navigateToLogin();
  }

  /// Called globally on 401 (and auth-related 403) responses.
  Future<void> handleSessionExpired({
    String? message,
    bool showMessage = true,
  }) async {
    if (_handlingExpiry) return;
    if (isOnAuthScreen() && !PrefUtils().isLoggedIn()) return;

    _handlingExpiry = true;
    try {
      rememberCurrentRouteAsPending();
      await PrefUtils().clearAuth();
      authClearedHandler?.call();

      if (showMessage) {
        final text = (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : AppLocalization.translate('msg_session_expired');
        _showToast(text, ToastificationType.warning);
      }

      _navigateToLogin();
    } finally {
      // Allow future expiry handling after navigation settles.
      scheduleMicrotask(() {
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          _handlingExpiry = false;
        });
      });
    }
  }

  /// A guest attempted an account-only action (HTTP 403). Prompts them to
  /// create a free account instead of logging them out. Debounced so a burst
  /// of blocked background calls shows at most one prompt.
  void handleGuestForbidden({String? message}) {
    if (!PrefUtils().isGuestAccount()) return;
    final now = DateTime.now();
    if (_lastGuestPromptAt != null &&
        now.difference(_lastGuestPromptAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastGuestPromptAt = now;

    final text = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : AppLocalization.translate('msg_guest_feature_locked');

    final handler = guestForbiddenHandler;
    void run() {
      if (handler != null) {
        handler(text);
      } else {
        _showToast(text, ToastificationType.info);
      }
    }

    // Defer so the calling flow can first dismiss its own loading dialog /
    // spinner (many callers pop the top route in a `finally`). Showing the
    // prompt immediately would push a sheet the caller then pops by mistake,
    // leaving their loader stuck.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!PrefUtils().isGuestAccount()) return;
      final scheduler = SchedulerBinding.instance;
      if (scheduler.schedulerPhase == SchedulerPhase.idle) {
        run();
      } else {
        scheduler.addPostFrameCallback((_) => run());
      }
    });
  }

  /// Not enough coins for a paid feature (HTTP 402). Debounced prompt → store.
  void handleInsufficientCoins(InsufficientCoinsInfo info) {
    if (PrefUtils().isGuestAccount()) {
      handleGuestForbidden(message: info.message);
      return;
    }
    final now = DateTime.now();
    if (_lastInsufficientCoinsPromptAt != null &&
        now.difference(_lastInsufficientCoinsPromptAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastInsufficientCoinsPromptAt = now;

    final handler = insufficientCoinsHandler;
    void run() {
      if (handler != null) {
        handler(info);
      } else {
        final text = info.message.trim().isNotEmpty
            ? info.message.trim()
            : AppLocalization.translate('msg_insufficient_coins');
        _showToast(text, ToastificationType.warning);
      }
    }

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      final scheduler = SchedulerBinding.instance;
      if (scheduler.schedulerPhase == SchedulerPhase.idle) {
        run();
      } else {
        scheduler.addPostFrameCallback((_) => run());
      }
    });
  }

  /// Navigate to the intended page after login, or Home by default.
  Future<void> navigateAfterLogin() async {
    final pending = takePendingNavigation();
    final route = pending?.route;
    if (route != null &&
        route.isNotEmpty &&
        !_nonRestorableRoutes.contains(route) &&
        canAccessRoute(route)) {
      await NavigatorService.pushNamedAndRemoveUntil(
        route,
        routePredicate: false,
        arguments: pending?.arguments,
      );
      return;
    }
    await NavigatorService.pushNamedAndRemoveUntil(
      AppRoutes.screen1HomeScreen,
      routePredicate: false,
    );
  }

  void _navigateToLogin() {
    void go() {
      final nav = NavigatorService.navigatorKey.currentState;
      if (nav == null) return;
      if (isOnAuthScreen()) return;
      nav.pushNamedAndRemoveUntil(
        AppRoutes.screen0LoginScreen,
        (route) => false,
      );
    }

    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle) {
      go();
    } else {
      scheduler.addPostFrameCallback((_) => go());
    }
  }

  void _showToast(String message, ToastificationType type) {
    void show() {
      try {
        showAppToast(message, type: type);
      } catch (_) {}
    }

    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle) {
      show();
    } else {
      scheduler.addPostFrameCallback((_) => show());
    }
  }
}
