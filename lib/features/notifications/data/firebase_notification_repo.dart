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
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
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