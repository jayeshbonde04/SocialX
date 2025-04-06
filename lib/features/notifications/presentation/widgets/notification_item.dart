import 'package:flutter/material.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart' as app_notification;

class NotificationItem extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  IconData _getNotificationIcon(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return Icons.favorite_rounded;
      case app_notification.NotificationType.comment:
        return Icons.comment_rounded;
      case app_notification.NotificationType.follow:
        return Icons.person_add_rounded;
      case app_notification.NotificationType.message:
        return Icons.message_rounded;
      case app_notification.NotificationType.post:
        return Icons.post_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getNotificationIcon(notification.type)),
      title: Text(notification.metadata?['message'] ?? 'New notification'),
      subtitle: Text(notification.timestamp.toString()),
      onTap: onTap,
    );
  }
} 