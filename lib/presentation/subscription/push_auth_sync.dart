import '../../data/services/push/push_notification_service.dart';

/// Re-upload FCM token after login / register so the backend can target the user.
Future<void> syncPushTokenAfterAuth() async {
  await PushNotificationService.instance.syncTokenAfterAuth();
}
