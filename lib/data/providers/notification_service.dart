import '../../core/constants/api_constants.dart';
import '../models/notification.dart';
import 'api_client.dart';

class NotificationApiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<AppNotification>> getNotifications({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.notifications,
      queryParameters: {'page': page},
    );
    final data = response.data['notifications'] ?? response.data['data'] ?? [];
    return (data as List).map((n) => AppNotification.fromJson(n)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(
      ApiConstants.notificationsUnreadCount,
    );
    return response.data['count'] ?? response.data['unread_count'] ?? 0;
  }

  Future<bool> markAsRead(int notificationId) async {
    final response = await _apiClient.post(
      '${ApiConstants.notifications}/$notificationId/read',
    );
    return response.data['success'] ?? true;
  }

  Future<bool> markAllAsRead() async {
    final response = await _apiClient.post(ApiConstants.notificationsReadAll);
    return response.data['success'] ?? true;
  }

  Future<bool> deleteNotification(int notificationId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.notifications}/$notificationId',
    );
    return response.data['success'] ?? true;
  }
}
