import 'package:socialx/features/notifications/domain/entities/notification.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {
  @override
  String toString() => 'NotificationInitial';
}

class NotificationLoading extends NotificationState {
  @override
  String toString() => 'NotificationLoading';
}

class NotificationLoaded extends NotificationState {
  final List<Notification> notifications;
  NotificationLoaded(this.notifications);

  @override
  String toString() => 'NotificationLoaded: ${notifications.length} notifications loaded';
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);

  @override
  String toString() => 'NotificationError: $message';
}
