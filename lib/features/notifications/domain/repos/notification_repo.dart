import 'package:socialx/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepo {
  Future<void> createNotification(Notification notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Stream<List<Notification>> getNotifications(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteAllNotifications(String userId);
  Future<void> restoreNotification(Notification notification);
  Future<void> updateNotificationType(String notificationId, NotificationType type);
  Future<void> addFollower(String userId, String followerId);
  Future<void> addFollowing(String userId, String followingId);
}