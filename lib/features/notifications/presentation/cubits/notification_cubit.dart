import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart';
import 'package:socialx/features/notifications/domain/repos/notification_repo.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_states.dart';
import 'package:socialx/services/notifications/in_app_notification_service.dart';
import 'package:socialx/services/notifications/local_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _notificationRepo;
  Stream<List<Notification>>? _notificationStream;
  StreamSubscription<List<Notification>>? _notificationSubscription;
  final InAppNotificationService _inAppNotificationService = InAppNotificationService();
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  Set<String> _displayedNotificationIds = {};
  static const String _displayedNotificationsKey = 'displayed_notifications';

  NotificationCubit(this._notificationRepo) : super(NotificationInitial()) {
    _loadDisplayedNotifications();
  }

  // Load displayed notification IDs from shared preferences
  Future<void> _loadDisplayedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final displayedNotificationsJson = prefs.getString(_displayedNotificationsKey);
      if (displayedNotificationsJson != null) {
        final List<dynamic> displayedNotificationsList = json.decode(displayedNotificationsJson);
        _displayedNotificationIds = Set<String>.from(displayedNotificationsList);
        print('NotificationCubit: Loaded ${_displayedNotificationIds.length} displayed notifications');
      }
    } catch (e) {
      print('NotificationCubit: Error loading displayed notifications: $e');
    }
  }

  // Save displayed notification IDs to shared preferences
  Future<void> _saveDisplayedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final displayedNotificationsJson = json.encode(_displayedNotificationIds.toList());
      await prefs.setString(_displayedNotificationsKey, displayedNotificationsJson);
      print('NotificationCubit: Saved ${_displayedNotificationIds.length} displayed notifications');
    } catch (e) {
      print('NotificationCubit: Error saving displayed notifications: $e');
    }
  }

  // Mark a notification as displayed
  Future<void> _markNotificationAsDisplayed(String notificationId) async {
    _displayedNotificationIds.add(notificationId);
    await _saveDisplayedNotifications();
  }

  // Check if a notification has been displayed
  bool _hasNotificationBeenDisplayed(String notificationId) {
    return _displayedNotificationIds.contains(notificationId);
  }

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
            
            // Verify that these notifications belong to the current user
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null && currentUser.uid == userId) {
              // Show in-app notifications for unread notifications that haven't been displayed yet
              for (final notification in notifications.where((n) => !n.isRead)) {
                // Skip if this notification has already been displayed
                if (_hasNotificationBeenDisplayed(notification.id)) {
                  print('NotificationCubit: Skipping already displayed notification: ${notification.id}');
                  continue;
                }
                
                try {
                  _inAppNotificationService.showNotification(notification);
                  await _localNotificationService.showNotification(notification);
                  // Mark as displayed after showing
                  await _markNotificationAsDisplayed(notification.id);
                } catch (e) {
                  print('NotificationCubit: Error showing notification: $e');
                  // Continue processing other notifications even if one fails
                  continue;
                }
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
      
      // Only show notifications if the current user is the intended recipient
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == notification.userId) {
        // Skip if this notification has already been displayed
        if (_hasNotificationBeenDisplayed(notification.id)) {
          print('NotificationCubit: Skipping already displayed notification: ${notification.id}');
          return;
        }
        
        // Show both in-app and system notifications only to the recipient
        _inAppNotificationService.showNotification(notification);
        await _localNotificationService.showNotification(notification);
        // Mark as displayed after showing
        await _markNotificationAsDisplayed(notification.id);
      }
      
      print('NotificationCubit: Notification created successfully');
    } catch (e) {
      print('NotificationCubit: Error creating notification: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepo.markAsRead(notificationId);
      // Also mark as displayed to prevent showing again
      await _markNotificationAsDisplayed(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> acceptFollowRequest(Notification notification) async {
    try {
      print('NotificationCubit: Accepting follow request from ${notification.actorId}');
      
      // First, check if the notification exists in Firestore
      final notificationDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .get();
      
      if (!notificationDoc.exists) {
        print('NotificationCubit: Notification ${notification.id} not found in Firestore');
        // If the notification doesn't exist, we'll still proceed with the follow action
        // but we'll skip updating the notification type
      } else {
        // Update the notification type to follow
        await _notificationRepo.updateNotificationType(notification.id, NotificationType.follow);
      }
      
      // Add the user to followers list
      await _notificationRepo.addFollower(notification.userId, notification.actorId);
      
      // Add the user to following list
      await _notificationRepo.addFollowing(notification.actorId, notification.userId);
      
      // Create a new notification for the accepted follow
      final followNotification = Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: notification.actorId,
        actorId: notification.userId,
        type: NotificationType.follow,
        timestamp: DateTime.now(),
        metadata: {'actorName': notification.metadata?['actorName']},
      );
      
      await _notificationRepo.createNotification(followNotification);
      
      // Update the UI to reflect the changes
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == notification.id) {
            return n.copyWith(type: NotificationType.follow);
          }
          return n;
        }).toList();
        
        emit(NotificationLoaded(updatedNotifications));
      }
      
      print('NotificationCubit: Follow request accepted successfully');
    } catch (e) {
      print('NotificationCubit: Error accepting follow request: $e');
      emit(NotificationError('Failed to accept follow request: $e'));
    }
  }

  Future<void> rejectFollowRequest(Notification notification) async {
    try {
      print('NotificationCubit: Rejecting follow request from ${notification.actorId}');
      
      // First, check if the notification exists in Firestore
      final notificationDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .get();
      
      if (!notificationDoc.exists) {
        print('NotificationCubit: Notification ${notification.id} not found in Firestore');
        // If the notification doesn't exist, we'll still update the UI
      } else {
        // Delete the follow request notification
        await _notificationRepo.deleteNotification(notification.id);
      }
      
      // Update the UI to reflect the changes
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedNotifications = currentState.notifications
            .where((n) => n.id != notification.id)
            .toList();
        
        emit(NotificationLoaded(updatedNotifications));
      }
      
      print('NotificationCubit: Follow request rejected successfully');
    } catch (e) {
      print('NotificationCubit: Error rejecting follow request: $e');
      emit(NotificationError('Failed to reject follow request: $e'));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      print('NotificationCubit: Marking all notifications as read for user: $userId');
      await _notificationRepo.markAllAsRead(userId);
      print('NotificationCubit: Successfully marked all notifications as read');
      
      // Mark all current notifications as displayed
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        for (final notification in currentState.notifications) {
          await _markNotificationAsDisplayed(notification.id);
        }
        print('NotificationCubit: Marked all notifications as displayed');
      }
      
      // Refresh notifications to update the UI
      refreshNotifications();
    } catch (e) {
      print('NotificationCubit: Error marking all notifications as read: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      print('NotificationCubit: Deleting notification: $notificationId');
      
      // Store the notification before deletion for potential restoration
      Notification? notificationToRestore;
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        try {
          notificationToRestore = currentState.notifications.firstWhere(
            (n) => n.id == notificationId,
          );
        } catch (e) {
          print('NotificationCubit: Notification $notificationId not found in current state');
        }
      }
      
      // First delete from Firebase to ensure data consistency
      await _notificationRepo.deleteNotification(notificationId);
      print('NotificationCubit: Successfully deleted notification from Firebase: $notificationId');
      
      // Then update UI state after successful deletion
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != notificationId)
            .toList();
        
        emit(NotificationLoaded(updatedNotifications));
        print('NotificationCubit: Successfully updated UI state');
      }
      
    } catch (e) {
      print('NotificationCubit: Error deleting notification: $e');
      
      // If there was an error, refresh notifications to ensure UI is in sync with backend
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        if (currentState.notifications.isNotEmpty) {
          final userId = currentState.notifications.first.userId;
          await initializeNotifications(userId);
        }
      }
      
      emit(NotificationError('Failed to delete notification: $e'));
    }
  }

  Future<void> restoreNotification(Notification notification) async {
    try {
      print('NotificationCubit: Restoring notification: ${notification.id}');
      
      // First restore in repository
      await _notificationRepo.restoreNotification(notification);
      print('NotificationCubit: Successfully restored notification in repository');
      
      // Then update the UI state
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        
        // Check if notification already exists in the list
        final exists = currentState.notifications.any((n) => n.id == notification.id);
        if (exists) {
          print('NotificationCubit: Notification ${notification.id} already exists in UI state');
          return;
        }
        
        // Create a new list with the restored notification
        final updatedNotifications = List<Notification>.from(currentState.notifications)
          ..add(notification);
        
        // Sort notifications by timestamp to maintain order
        updatedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        emit(NotificationLoaded(updatedNotifications));
        print('NotificationCubit: Successfully restored notification in UI: ${notification.id}');
      } else {
        // If not in loaded state, initialize notifications
        print('NotificationCubit: Current state is not NotificationLoaded, initializing notifications');
        await initializeNotifications(notification.userId);
      }
    } catch (e) {
      print('NotificationCubit: Error restoring notification: $e');
      emit(NotificationError('Failed to restore notification: $e'));
      
      // Refresh notifications to ensure UI is in sync with backend
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        if (currentState.notifications.isNotEmpty) {
          final userId = currentState.notifications.first.userId;
          await initializeNotifications(userId);
        }
      }
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      print('NotificationCubit: Deleting all notifications for user: $userId');
      
      // First update UI state to provide immediate feedback
      if (state is NotificationLoaded) {
        emit(NotificationLoaded([]));
        print('NotificationCubit: Updated UI state to empty list');
      }
      
      // Then delete from Firebase
      await _notificationRepo.deleteAllNotifications(userId);
      print('NotificationCubit: Successfully deleted all notifications from Firebase');
      
      // Ensure UI is in sync with backend
      await initializeNotifications(userId);
      print('NotificationCubit: Reinitialized notifications to ensure UI is in sync');
      
    } catch (e) {
      print('NotificationCubit: Error deleting all notifications: $e');
      
      // If there was an error, refresh notifications to ensure UI is in sync with backend
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        if (currentState.notifications.isNotEmpty) {
          final userId = currentState.notifications.first.userId;
          await initializeNotifications(userId);
        }
      }
      
      emit(NotificationError('Failed to delete all notifications: $e'));
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

  // Clear the displayed notifications history
  Future<void> clearDisplayedNotificationsHistory() async {
    try {
      print('NotificationCubit: Clearing displayed notifications history');
      _displayedNotificationIds.clear();
      await _saveDisplayedNotifications();
      print('NotificationCubit: Successfully cleared displayed notifications history');
    } catch (e) {
      print('NotificationCubit: Error clearing displayed notifications history: $e');
    }
  }
}