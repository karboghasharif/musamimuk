import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/notification_item.dart';

sealed class NotificationsResult {}

class NotificationsSuccess extends NotificationsResult {
  final List<NotificationItem> items;
  final String? message;
  NotificationsSuccess({required this.items, this.message});
}

class NotificationsFailure extends NotificationsResult {
  final String message;
  NotificationsFailure(this.message);
}

sealed class UnreadCountResult {}

class UnreadCountSuccess extends UnreadCountResult {
  final int unreadCount;
  UnreadCountSuccess(this.unreadCount);
}

class UnreadCountFailure extends UnreadCountResult {
  final String message;
  UnreadCountFailure(this.message);
}

sealed class NotificationActionResult {}

class NotificationActionSuccess extends NotificationActionResult {
  final String? message;
  NotificationActionSuccess({this.message});
}

class NotificationActionFailure extends NotificationActionResult {
  final String message;
  NotificationActionFailure(this.message);
}

class NotificationRepository {
  NotificationRepository() : _api = ApiClient();

  final ApiClient _api;

  Future<NotificationsResult> list({int perPage = 10, int page = 1}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        'notifications',
        queryParameters: <String, dynamic>{
          'per_page': perPage.clamp(1, 100).toString(),
          'page': page.clamp(1, 1000000).toString(),
        },
      );
      final data = response.data;
      if (data == null) return NotificationsFailure('Empty response');

      // Shapes:
      // - { status, data: { notifications: [...], data: [...], unread_count } }
      // - { success, data: [...] }
      final db = apiExtractDbData(data);
      dynamic listRaw;
      if (db is List) {
        listRaw = db;
      } else if (db is Map) {
        listRaw = db['notifications'] ?? db['data'] ?? db['items'];
      }
      final list = (listRaw is List)
          ? listRaw
              .whereType<Map>()
              .map((e) => NotificationItem.fromJson(e.cast<String, dynamic>()))
              .where((item) => item.id.isNotEmpty)
              .toList()
          : <NotificationItem>[];

      return NotificationsSuccess(items: list, message: apiExtractMessage(data));
    } on DioException catch (e) {
      return NotificationsFailure(apiMessageFromDioException(e));
    } catch (_) {
      return NotificationsFailure('Something went wrong');
    }
  }

  Future<UnreadCountResult> unreadCount() async {
    try {
      final response =
          await _api.dio.get<Map<String, dynamic>>('notifications/unread-count');
      final data = response.data;
      if (data == null) return UnreadCountFailure('Empty response');
      final db = apiExtractDbData(data);
      final map = db is Map ? db.cast<String, dynamic>() : <String, dynamic>{};
      final n = apiParseInt(map['unread_count'], fallback: 0);
      return UnreadCountSuccess(n);
    } on DioException catch (e) {
      return UnreadCountFailure(apiMessageFromDioException(e));
    } catch (_) {
      return UnreadCountFailure('Something went wrong');
    }
  }

  /// POST legacy: `/notifications/read/{id}`
  Future<NotificationActionResult> markReadLegacy(String id) async {
    try {
      final response =
          await _api.dio.post<Map<String, dynamic>>('notifications/read/$id');
      return NotificationActionSuccess(message: apiExtractMessage(response.data));
    } on DioException catch (e) {
      return NotificationActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return NotificationActionFailure('Something went wrong');
    }
  }

  /// PATCH REST: `/notifications/{id}/read`
  Future<NotificationActionResult> markRead(String id) async {
    try {
      final response =
          await _api.dio.patch<Map<String, dynamic>>('notifications/$id/read');
      return NotificationActionSuccess(message: apiExtractMessage(response.data));
    } on DioException catch (e) {
      return NotificationActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return NotificationActionFailure('Something went wrong');
    }
  }

  Future<NotificationActionResult> markAllRead() async {
    try {
      final response =
          await _api.dio.patch<Map<String, dynamic>>('notifications/read-all');
      return NotificationActionSuccess(message: apiExtractMessage(response.data));
    } on DioException catch (e) {
      return NotificationActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return NotificationActionFailure('Something went wrong');
    }
  }

  Future<NotificationActionResult> delete(String id) async {
    try {
      final response =
          await _api.dio.delete<Map<String, dynamic>>('notifications/$id');
      return NotificationActionSuccess(message: apiExtractMessage(response.data));
    } on DioException catch (e) {
      return NotificationActionFailure(apiMessageFromDioException(e));
    } catch (_) {
      return NotificationActionFailure('Something went wrong');
    }
  }
}

