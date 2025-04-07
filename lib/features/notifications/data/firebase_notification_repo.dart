import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart';
import 'package:socialx/features/notifications/domain/repos/notification_repo.dart';

class FirebaseNotificationRepo implements NotificationRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> createNotification(Notification notification) async {
    try {
      print('FirebaseNotificationRepo: Creating notification: ${notification.id}');
      final notificationData = notification.toJson();
      print('FirebaseNotificationRepo: Notification data: $notificationData');
      
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notificationData);
          
      print('FirebaseNotificationRepo: Notification created successfully');
    } catch (e) {
      print('FirebaseNotificationRepo: Error creating notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('Successfully marked all notifications as read for user: $userId');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Notification>> getNotifications(String userId) {
    print('FirebaseNotificationRepo: Getting notifications stream for user: $userId');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('FirebaseNotificationRepo: Received ${snapshot.docs.length} notifications from Firestore');
          final notifications = snapshot.docs
              .map((doc) {
                print('FirebaseNotificationRepo: Processing notification doc: ${doc.id}');
                final data = doc.data();
                print('FirebaseNotificationRepo: Notification data: $data');
                return Notification.fromJson(data);
              })
              .toList();
          print('FirebaseNotificationRepo: Processed ${notifications.length} notifications');
          return notifications;
        });
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('FirebaseNotificationRepo: Deleting notification: $notificationId');
      
      // First verify the notification exists
      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
          
      if (!notificationDoc.exists) {
        print('FirebaseNotificationRepo: Notification $notificationId not found in Firestore');
        return; // Silently return if notification doesn't exist
      }
      
      // Delete the notification
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
          
      print('FirebaseNotificationRepo: Successfully deleted notification: $notificationId');
    } catch (e) {
      print('FirebaseNotificationRepo: Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      print('FirebaseNotificationRepo: Deleting all notifications for user: $userId');
      
      // Get all notifications for the user
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (notifications.docs.isEmpty) {
        print('FirebaseNotificationRepo: No notifications found for user: $userId');
        return; // Silently return if no notifications exist
      }
      
      print('FirebaseNotificationRepo: Found ${notifications.docs.length} notifications to delete');
      
      // Use a batch to delete all notifications in a single transaction
      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
      print('FirebaseNotificationRepo: Successfully deleted all notifications for user: $userId');
    } catch (e) {
      print('FirebaseNotificationRepo: Error deleting all notifications: $e');
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  @override
  Future<void> restoreNotification(Notification notification) async {
    try {
      print('FirebaseNotificationRepo: Restoring notification: ${notification.id}');
      final notificationData = notification.toJson();
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notificationData);
      print('FirebaseNotificationRepo: Notification restored successfully');
    } catch (e) {
      print('FirebaseNotificationRepo: Error restoring notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateNotificationType(String notificationId, NotificationType type) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'type': type.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update notification type: $e');
    }
  }

  @override
  Future<void> addFollower(String userId, String followerId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'followers': FieldValue.arrayUnion([followerId]),
      });
    } catch (e) {
      throw Exception('Failed to add follower: $e');
    }
  }

  @override
  Future<void> addFollowing(String userId, String followingId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'following': FieldValue.arrayUnion([followingId]),
      });
    } catch (e) {
      throw Exception('Failed to add following: $e');
    }
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}