import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart';
import 'package:socialx/features/notifications/domain/repos/notification_repo.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_states.dart';
import 'package:socialx/services/notifications/in_app_notification_service.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _notificationRepo;
  Stream<List<Notification>>? _notificationStream;
  final InAppNotificationService _inAppNotificationService = InAppNotificationService();

  NotificationCubit(this._notificationRepo) : super(NotificationInitial());

  void initializeNotifications(String userId) {
    print('NotificationCubit: Initializing notifications for user: $userId');
    emit(NotificationLoading());
    
    // Cancel any existing stream
    _notificationStream = null;
    
    // Create new stream
    _notificationStream = _notificationRepo.getNotifications(userId);
    print('NotificationCubit: Created notification stream');
    
    _notificationStream?.listen(
      (notifications) {
        print('NotificationCubit: Received ${notifications.length} notifications');
        print('NotificationCubit: Notifications: ${notifications.map((n) => '${n.id}: ${n.type} (read: ${n.isRead})').join(', ')}');
        
        // Show in-app notifications for unread notifications
        for (final notification in notifications) {
          if (!notification.isRead) {
            _inAppNotificationService.showNotification(notification);
          }
        }
        
        emit(NotificationLoaded(notifications));
      },
      onError: (error) {
        print('NotificationCubit: Error receiving notifications: $error');
        emit(NotificationError(error.toString()));
      },
    );
  }

  Future<void> createNotification(Notification notification) async {
    try {
      print('NotificationCubit: Creating notification: ${notification.id} for user: ${notification.userId}');
      await _notificationRepo.createNotification(notification);
      
      // Show in-app notification immediately
      _inAppNotificationService.showNotification(notification);
      
      print('NotificationCubit: Notification created successfully');
    } catch (e) {
      print('NotificationCubit: Error creating notification: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepo.markAsRead(notificationId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      print('NotificationCubit: Marking all notifications as read for user: $userId');
      await _notificationRepo.markAllAsRead(userId);
      print('NotificationCubit: Successfully marked all notifications as read');
      
      // Refresh notifications to update the UI
      refreshNotifications();
    } catch (e) {
      print('NotificationCubit: Error marking all notifications as read: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationRepo.deleteNotification(notificationId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _notificationRepo.deleteAllNotifications(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void refreshNotifications() {
    print('NotificationCubit: Refreshing notifications');
    if (_notificationStream != null) {
      // Cancel the existing stream
      _notificationStream = null;
      print('NotificationCubit: Cancelled existing notification stream');
      
      // Get the current user ID from the loaded state
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        if (currentState.notifications.isNotEmpty) {
          final userId = currentState.notifications.first.userId;
          print('NotificationCubit: Reinitializing notifications for user: $userId');
          initializeNotifications(userId);
        } else {
          print('NotificationCubit: No notifications found in current state');
        }
      } else {
        print('NotificationCubit: Current state is not NotificationLoaded');
      }
    } else {
      print('NotificationCubit: No existing notification stream to refresh');
    }
  }
} 