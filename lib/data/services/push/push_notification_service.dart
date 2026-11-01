import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:musamimuk/core/app_export.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/firebase_options.dart';

/// Android notification channel used for FCM display while app is foregrounded.
const String kMusamimukPushChannelId = 'musamimuk_default';
const String kMusamimukPushChannelName = 'Musamimuk';
const String kMusamimukPushChannelDesc =
    'General notifications from Musamimuk';

/// Top-level background handler — must stay a top-level / static function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(
      'FCM background: ${message.messageId} '
      'title=${message.notification?.title}',
    );
  }
}

/// Firebase Cloud Messaging + local notification presentation.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  /// Call once after [Firebase.initializeApp] in `main`.
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _setupLocalNotifications();
    await _requestPermissions();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      scheduleMicrotask(() => _handleNotificationOpen(initial));
    }

    // firebase_messaging 17: register() + onRegistered (FID). Keep getToken for
    // classic FCM device tokens used by Console / most backends.
    // Manifest must include firebase_messaging_installation_id_enabled=true.
    try {
      await _messaging.register();
      _tokenRefreshSub = _messaging.onRegistered.listen((fid) async {
        if (kDebugMode) debugPrint('FCM registered FID: $fid');
        await _refreshAndStoreToken();
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FCM register() failed (falling back to getToken): $e\n$st');
      }
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        await PrefUtils().setFcmToken(token);
        await _registerTokenWithBackend(token);
      });
    }

    await _refreshAndStoreToken();
    _initialized = true;
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _openNotificationsScreen();
          return;
        }
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _navigateFromData(data);
        } catch (_) {
          _openNotificationsScreen();
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        kMusamimukPushChannelId,
        kMusamimukPushChannelName,
        description: kMusamimukPushChannelDesc,
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }

    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<String?> _refreshAndStoreToken() async {
    try {
      // ignore: deprecated_member_use — classic FCM token still needed for Console tests
      final token = await _messaging.getToken();
      _fcmToken = token;
      if (kDebugMode && token != null) {
        debugPrint('FCM token: $token');
      }
      if (token != null) {
        await PrefUtils().setFcmToken(token);
        await _registerTokenWithBackend(token);
      }
      return token;
    } catch (e, st) {
      debugPrint('FCM getToken failed: $e\n$st');
      return null;
    }
  }

  /// Re-register after login so the backend can target this user.
  Future<void> syncTokenAfterAuth() async {
    if (!_initialized) return;
    final token = _fcmToken ?? await _refreshAndStoreToken();
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
  }

  /// Best-effort upload. Backend endpoint may not exist yet — failures are logged.
  Future<void> _registerTokenWithBackend(String token) async {
    final prefs = PrefUtils();
    if (!prefs.isLoggedIn() || prefs.isGuestAccount()) return;

    try {
      final deviceId = await prefs.getOrCreateDeviceId();
      await ApiClient().dio.post<Map<String, dynamic>>(
        'device-tokens',
        data: <String, dynamic>{
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'device_id': deviceId,
        },
      );
      if (kDebugMode) debugPrint('FCM token registered with backend');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token backend register skipped/failed: $e');
      }
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          kMusamimukPushChannelId,
          kMusamimukPushChannelName,
          channelDescription: kMusamimukPushChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationOpen(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final href = data['href']?.toString() ?? '';
    final orderId = int.tryParse(data['order_id']?.toString() ?? '');
    final orderMatch = RegExp(r'/print/orders/(\d+)').firstMatch(href);
    final resolvedOrderId =
        orderId ?? int.tryParse(orderMatch?.group(1) ?? '');
    if (resolvedOrderId != null && resolvedOrderId > 0) {
      try {
        NavigatorService.pushNamed(
          AppRoutes.printTrackingScreen,
          arguments: {'orderId': resolvedOrderId},
        );
        return;
      } catch (_) {}
    }
    if (href.contains('/print/rider')) {
      try {
        NavigatorService.pushNamed(AppRoutes.printRiderHomeScreen);
        return;
      } catch (_) {}
    }
    if (data['type']?.toString() == 'print') {
      try {
        NavigatorService.pushNamed(AppRoutes.printNoticesScreen);
        return;
      } catch (_) {}
    }
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      try {
        NavigatorService.pushNamed(route);
        return;
      } catch (_) {
        // Fall through to notifications list.
      }
    }
    _openNotificationsScreen();
  }

  void _openNotificationsScreen() {
    try {
      NavigatorService.pushNamed(AppRoutes.notificationsScreen);
    } catch (e) {
      if (kDebugMode) debugPrint('Open notifications screen failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _initialized = false;
  }
}
