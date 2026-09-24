import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

/// Manages in-app notifications for the authenticated user.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Stream of unread notification count for reactive UI updates
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Fetch all notifications for the current user
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        if (unreadOnly) 'unreadOnly': 'true',
        'limit': limit.toString(),
      };

      final response = await ApiService.instance.get(
        '/api/notifications',
        queryParameters: queryParams,
      );

      final notifications = (response['notifications'] as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      _unreadCount = response['unreadCount'] as int? ?? 0;
      _unreadCountController.add(_unreadCount);

      debugPrint('[Notification] Fetched ${notifications.length} notifications, $_unreadCount unread');

      return notifications;
    } on ApiException catch (e) {
      debugPrint('[Notification] Failed to fetch notifications: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[Notification] Unexpected error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count only (lightweight)
  Future<int> getUnreadCount() async {
    try {
      debugPrint('[Notification] Polling for unread count...');
      final response = await ApiService.instance.get(
        '/api/notifications/unread/count',
      );

      _unreadCount = response['count'] as int? ?? 0;
      _unreadCountController.add(_unreadCount);

      debugPrint('[Notification] Unread count: $_unreadCount');
      return _unreadCount;
    } on ApiException catch (e) {
      debugPrint('[Notification] Failed to get unread count: ${e.message}');
      return _unreadCount;
    } catch (e) {
      debugPrint('[Notification] Unexpected error getting unread count: $e');
      return _unreadCount;
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await ApiService.instance.put(
        '/api/notifications/$notificationId/read',
        {},
      );

      // Decrement local count
      if (_unreadCount > 0) {
        _unreadCount--;
        _unreadCountController.add(_unreadCount);
      }

      debugPrint('[Notification] Marked $notificationId as read');
      return true;
    } on ApiException catch (e) {
      debugPrint('[Notification] Failed to mark as read: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Notification] Unexpected error marking as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      await ApiService.instance.put(
        '/api/notifications/read-all',
        {},
      );

      _unreadCount = 0;
      _unreadCountController.add(_unreadCount);

      debugPrint('[Notification] Marked all as read');
      return true;
    } on ApiException catch (e) {
      debugPrint('[Notification] Failed to mark all as read: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Notification] Unexpected error marking all as read: $e');
      return false;
    }
  }

  /// Start periodic polling for unread count (every 15 seconds)
  void startPolling() {
    debugPrint('[Notification] Starting polling (15s interval)');
    
    Timer.periodic(const Duration(seconds: 15), (_) {
      getUnreadCount();
    });
    
    // Fetch immediately
    getUnreadCount();
  }

  void dispose() {
    _unreadCountController.close();
  }
}
