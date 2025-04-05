import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart';
import 'package:socialx/features/notifications/domain/repos/notification_repo.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_states.dart';
import 'package:socialx/services/notifications/in_app_notification_service.dart';
import 'package:socialx/services/notifications/local_notification_service.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _notificationRepo;
  Stream<List<Notification>>? _notificationStream;
  StreamSubscription<List<Notification>>? _notificationSubscription;
  final InAppNotificationService _inAppNotificationService = InAppNotificationService();
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  NotificationCubit(this._notificationRepo) : super(NotificationInitial());

  @override
  Future<void> close() async {
    await _notificationSubscription?.cancel();
    return super.close();
  }

  Future<void> initializeNotifications(String userId) async {
    print('NotificationCubit: Initializing notifications for user: $userId');
    
    // Only proceed if we're not already loading
    if (state is NotificationLoading) {
      print('NotificationCubit: Already loading notifications, skipping initialization');
      return;
    }
    
    emit(NotificationLoading());
    
    try {
      // Clean up existing resources first
      await _cleanupExistingResources();
      
      // Initialize local notifications with error handling
      try {
        await _localNotificationService.initialize();
      } catch (e) {
        print('NotificationCubit: Error initializing local notifications: $e');
        emit(NotificationError('Failed to initialize notification service. Please restart the app.'));
        return;
      }
      
      // Create new stream with timeout
      try {
        _notificationStream = _notificationRepo.getNotifications(userId);
        print('NotificationCubit: Created notification stream');
      } catch (e) {
        print('NotificationCubit: Error creating notification stream: $e');
        emit(NotificationError('Failed to connect to notification service. Please check your connection.'));
        return;
      }
      
      bool hasReceivedData = false;
      Timer? timeoutTimer;
      
      timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (!hasReceivedData) {
          print('NotificationCubit: Timeout reached while waiting for notifications');
          _cleanupExistingResources();
          emit(NotificationError('Connection timeout. Please check your internet and try again.'));
        }
      });
      
      // Subscribe to the stream with enhanced error handling
      _notificationSubscription = _notificationStream?.listen(
        (notifications) async {
          hasReceivedData = true;
          timeoutTimer?.cancel();
          
          print('NotificationCubit: Received ${notifications.length} notifications');
          
          try {
            if (notifications.isEmpty) {
              emit(NotificationLoaded(notifications));
              return;
            }
            
            // Show in-app notifications for unread notifications
            for (final notification in notifications.where((n) => !n.isRead)) {
              try {
                _inAppNotificationService.showNotification(notification);
                await _localNotificationService.showNotification(notification);
              } catch (e) {
                print('NotificationCubit: Error showing notification: $e');
                // Continue processing other notifications even if one fails
                continue;
              }
            }
            
            if (!isClosed) {
              emit(NotificationLoaded(notifications));
            }
          } catch (e) {
            print('NotificationCubit: Error processing notifications: $e');
            if (!isClosed) {
              emit(NotificationError('Error displaying notifications. Please try refreshing.'));
            }
          }
        },
        onError: (error) {
          print('NotificationCubit: Error receiving notifications: $error');
          timeoutTimer?.cancel();
          if (!isClosed) {
            emit(NotificationError('Failed to receive notifications. Please check your connection.'));
          }
          _cleanupExistingResources();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('NotificationCubit: Error initializing notifications: $e');
      if (!isClosed) {
        emit(NotificationError('Failed to initialize notifications. Please restart the app.'));
      }
      _cleanupExistingResources();
    }
  }

  Future<void> _cleanupExistingResources() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notificationStream = null;
  }

  Future<void> createNotification(Notification notification) async {
    try {
      print('NotificationCubit: Creating notification: ${notification.id} for user: ${notification.userId}');
      await _notificationRepo.createNotification(notification);
      
      // Show in-app notification immediately
      // Show both in-app and system notifications
        _inAppNotificationService.showNotification(notification);
        await _localNotificationService.showNotification(notification);
      
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
      // Get current notifications
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != notificationId)
            .toList();
        
        // Update state immediately before repository call
        emit(NotificationLoaded(updatedNotifications));
        
        // Then delete from repository
        await _notificationRepo.deleteNotification(notificationId);
      }
    } catch (e) {
      emit(NotificationError('Failed to delete notification: $e'));
    }
  }

  Future<void> restoreNotification(Notification notification) async {
    try {
      await _notificationRepo.restoreNotification(notification);
    } catch (e) {
      emit(NotificationError('Failed to restore notification: $e'));
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