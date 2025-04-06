/*

 DATABASE SERVICE
 This class handle all the data to firebase

 -User profile
 -Post message
 -Likes
 -Comments
 -Account stuff( report / delete account / block)
 -Follow / Unfollow
 -Search users
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/models/message.dart';
import 'package:socialx/models/user.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  // get the instance of firestore db & auth
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

/*
  USER PROFILE

  WHEN A NEW USER REGISTERS, WE CREATE AN ACCOUNT FOR THEM, BUT LET'S ALSO STORE
  THEIR DETAILS IN THE DATABASE TO DISPLAY ON THEIR PROFILE PAGE

 */

  // Save user info
  Future<void> saveUserInfoInFirebase(
      {required String name, required String email}) async {
    //get current uid
    String uid = _auth.currentUser!.uid;

    //extract username from email and convert to lowercase
    String username = email.split('@')[0].toLowerCase();

    //create a user profile
    Userprofile user = Userprofile(
      uid: uid,
      name: name,
      email: email,
      username: username,
      bio: '',
    );

    //convert user into a map so that we can store in firebase
    final userMap = user.toMap();

    //save user info in firebase
    await _db.collection("users").doc(uid).set(userMap);
  }

  //Get user info
  Future<Userprofile?> getUserFromFirebase(String uid) async {
    try {
      //retrieve user doc from firebase
      DocumentSnapshot userDoc = await _db.collection("users").doc(uid).get();

      //convert doc to user profile
      return Userprofile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

/*
  POST MESSAGE

 */

/*
  LIKES

 */

/*
  COMMENTS
 */

/*
  ACCOUNT STUFFS

 */

/*
 FOLLOW

  */

/*
MESSAGING FEATURE
* */

  // FOLLOW/UNFOLLOW METHODS
  Future<void> followUser(String userToFollowId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // Add to current user's following list
    await _db.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([userToFollowId])
    });

    // Add to target user's followers list
    await _db.collection('users').doc(userToFollowId).update({
      'followers': FieldValue.arrayUnion([currentUserId])
    });
  }

  Future<void> unfollowUser(String userToUnfollowId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // Remove from current user's following list
    await _db.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayRemove([userToUnfollowId])
    });

    // Remove from target user's followers list
    await _db.collection('users').doc(userToUnfollowId).update({
      'followers': FieldValue.arrayRemove([currentUserId])
    });
  }

  // Modified getUserStream to return followed users and users who have sent messages
  Stream<List<Map<String, dynamic>>> getUserStream() {
    final String currentUserId = _auth.currentUser!.uid;
    print("Getting user stream for user: $currentUserId");

    return _db.collection('users').snapshots().asyncMap((usersSnapshot) async {
      print("Found ${usersSnapshot.docs.length} total users");

      // Get current user's following list
      final currentUserDoc =
          await _db.collection('users').doc(currentUserId).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final followingList =
          List<String>.from(currentUserData['following'] ?? []);
      print("Current user following: $followingList");

      // Get all chat rooms for the current user
      final chatRoomsSnapshot = await _db
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .get();

      print("Found ${chatRoomsSnapshot.docs.length} chat rooms");

      // Get all unique user IDs from messages
      Set<String> messageUserIds = {};
      for (var doc in chatRoomsSnapshot.docs) {
        final messagesSnapshot =
            await doc.reference.collection('messages').get();
        print("Found ${messagesSnapshot.docs.length} messages in chat room");

        for (var messageDoc in messagesSnapshot.docs) {
          final data = messageDoc.data();
          if (data['senderID'] != currentUserId) {
            messageUserIds.add(data['senderID']);
          }
          if (data['receiverID'] != currentUserId) {
            messageUserIds.add(data['receiverID']);
          }
        }
      }

      print("Found ${messageUserIds.length} unique users with messages");

      // Process users
      final filteredUsers = usersSnapshot.docs
          .map((doc) {
            final user = doc.data();
            // Include user if:
            // 1. Not current user AND
            // 2. Either current user follows them OR they have exchanged messages
            if (user['uid'] != currentUserId) {
              final isFollowing = followingList.contains(user['uid']);
              final hasMessages = messageUserIds.contains(user['uid']);

              print("Checking user: ${user['email']}");
              print("  - Following: $isFollowing");
              print("  - Has messages: $hasMessages");

              if (isFollowing || hasMessages) {
                print("Including user: ${user['email']}");
                return user;
              }
            }
            return null;
          })
          .where((user) => user != null)
          .map((user) => user as Map<String, dynamic>)
          .toList();

      print("Returning ${filteredUsers.length} filtered users");
      return filteredUsers;
    });
  }

  // Upload media file
  Future<String?> uploadMediaFile(String filePath, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('chat_media/$fileName');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading media file: $e");
      return null;
    }
  }

  //SEND MESSAGES
  Future<void> sendMessage(
    String receiverID,
    String message, {
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? audioDuration,
  }) async {
    try {
      // Get current user info
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;
      final Timestamp timestamp = Timestamp.now();

      // Get current user's name
      final currentUserDoc = await _db.collection('users').doc(currentUserId).get();
      final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';

      // Create a new message
      Message newMessage = Message(
        senderID: currentUserEmail,
        senderEmail: currentUserId,
        receiverID: receiverID,
        message: message,
        timestamp: timestamp,
        type: type,
        mediaUrl: mediaUrl,
        audioDuration: audioDuration,
      );

      // Construct chat room ID for the two users (sorted to ensure uniqueness)
      List<String> ids = [currentUserId, receiverID];
      ids.sort(); // Sort the ids (this ensures the chatRoomID is the same for any 2 people)
      String chatRoomID = ids.join('_');

      // Create or update chat room with participants
      await _db.collection("chat_rooms").doc(chatRoomID).set({
        'participants': [currentUserId, receiverID],
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'createdAt': timestamp,
      }, SetOptions(merge: true));

      // Add new message to the database
      await _db
          .collection("chat_rooms")
          .doc(chatRoomID)
          .collection("messages")
          .add(newMessage.toMap());

      // Create notification for the receiver
      await _db.collection("notifications").add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': receiverID,
        'actorId': currentUserId,
        'type': 'message',
        'timestamp': timestamp,
        'isRead': false,
        'metadata': {
          'message': message,
          'type': type.toString(),
          'mediaUrl': mediaUrl,
          'actorName': currentUserName,
        },
      });

      print("Message sent successfully to chat room: $chatRoomID");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Update message status
  Future<void> updateMessageStatus(String chatRoomId, String messageId, MessageStatus status) async {
    try {
      final messageRef = _db
          .collection("chat_rooms")
          .doc(chatRoomId)
          .collection("messages")
          .doc(messageId);

      if (status == MessageStatus.seen) {
        await messageRef.update({
          'status': status.toString(),
          'seenAt': FieldValue.serverTimestamp(),
        });
      } else {
        await messageRef.update({
          'status': status.toString(),
        });
      }
    } catch (e) {
      print("Error updating message status: $e");
    }
  }

  // Mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatRoomId, String senderId) async {
    try {
      final messagesSnapshot = await _db
          .collection("chat_rooms")
          .doc(chatRoomId)
          .collection("messages")
          .where('senderID', isEqualTo: senderId)
          .where('status', isEqualTo: MessageStatus.sent.toString())
          .get();

      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.delivered.toString(),
        });
      }
      await batch.commit();
    } catch (e) {
      print("Error marking messages as delivered: $e");
    }
  }

  // Mark messages as seen
  Future<void> markMessagesAsSeen(String chatRoomId, String senderId) async {
    try {
      final currentTimestamp = Timestamp.now();
      final messagesSnapshot = await _db
          .collection("chat_rooms")
          .doc(chatRoomId)
          .collection("messages")
          .where('senderID', isEqualTo: senderId)
          .where('status', whereIn: [
            MessageStatus.delivered.toString(),
            MessageStatus.sent.toString(),
          ])
          .get();

      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.seen.toString(),
          'seenAt': currentTimestamp,
        });
      }
      await batch.commit();
    } catch (e) {
      print("Error marking messages as seen: $e");
    }
  }

  // Modified getMessages to automatically mark messages as delivered/seen
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    // Construct chat room ID
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Mark messages as delivered when the stream is first listened to
    markMessagesAsDelivered(chatRoomID, otherUserID);

    // Mark messages as seen when the user is actively viewing them
    markMessagesAsSeen(chatRoomID, otherUserID);

    return _db
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // Update Message
  Future<void> updateMessage(String messageId, String newText) async {
    try {
      // Get the current user's ID
      final String currentUserId = _auth.currentUser!.uid;

      // Get all chat rooms where the current user is a participant
      final chatRoomsSnapshot = await _db
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Search through each chat room for the message
      for (var chatRoom in chatRoomsSnapshot.docs) {
        final messageDoc = await chatRoom.reference
            .collection('messages')
            .doc(messageId)
            .get();

        if (messageDoc.exists) {
          await messageDoc.reference.update({
            'message': newText,
            'isEdited': true,
            'editedAt': FieldValue.serverTimestamp(),
          });
          return; // Exit after finding and updating the message
        }
      }
    } catch (e) {
      print('Error updating message: $e');
      rethrow;
    }
  }

  // Delete Message
  Future<void> deleteMessage(String messageId) async {
    try {
      // Get the current user's ID
      final String currentUserId = _auth.currentUser!.uid;

      // Get all chat rooms where the current user is a participant
      final chatRoomsSnapshot = await _db
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Search through each chat room for the message
      for (var chatRoom in chatRoomsSnapshot.docs) {
        final messageDoc = await chatRoom.reference
            .collection('messages')
            .doc(messageId)
            .get();

        if (messageDoc.exists) {
          await messageDoc.reference.delete();
          return; // Exit after finding and deleting the message
        }
      }
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Delete user account and all associated data
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final String userId = user.uid;

        // 1. Delete user's posts and associated data
        final postsSnapshot = await _db.collection('posts').where('uid', isEqualTo: userId).get();
        for (var doc in postsSnapshot.docs) {
          // Delete post comments
          final commentsSnapshot = await doc.reference.collection('comments').get();
          for (var comment in commentsSnapshot.docs) {
            await comment.reference.delete();
          }
          // Delete post likes
          final likesSnapshot = await doc.reference.collection('likes').get();
          for (var like in likesSnapshot.docs) {
            await like.reference.delete();
          }
          // Delete the post itself
          await doc.reference.delete();
        }

        // 2. Delete user's profile data
        await _db.collection('users').doc(userId).delete();

        // 3. Delete user's chat rooms and messages
        final chatRoomsSnapshot = await _db.collection('chat_rooms').where('participants', arrayContains: userId).get();
        for (var chatRoom in chatRoomsSnapshot.docs) {
          // Delete all messages in the chat room
          final messagesSnapshot = await chatRoom.reference.collection('messages').get();
          for (var message in messagesSnapshot.docs) {
            await message.reference.delete();
          }
          // Delete the chat room itself
          await chatRoom.reference.delete();
        }

        // 4. Remove user from other users' followers/following lists and update their lists
        final allUsersSnapshot = await _db.collection('users').get();
        for (var userDoc in allUsersSnapshot.docs) {
          if (userDoc.id != userId) {
            final userData = userDoc.data();
            List<dynamic> followers = List<dynamic>.from(userData['followers'] ?? []);
            List<dynamic> following = List<dynamic>.from(userData['following'] ?? []);
            
            // Remove the deleted user from followers and following lists
            followers.remove(userId);
            following.remove(userId);
            
            // Update the user document with cleaned lists
            await userDoc.reference.update({
              'followers': followers,
              'following': following,
            });
          }
        }

        // 5. Delete user's profile image from storage if exists
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final profileImageUrl = userDoc.data()?['profileImageUrl'];
            if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
              final ref = FirebaseStorage.instance.refFromURL(profileImageUrl);
              await ref.delete();
            }
          }
        } catch (e) {
          print('Error deleting profile image: $e');
        }

        // 6. Delete any notifications for the user
        final notificationsSnapshot = await _db.collection('notifications').where('userId', isEqualTo: userId).get();
        for (var notification in notificationsSnapshot.docs) {
          await notification.reference.delete();
        }

        // 7. Delete any reports made by the user
        final reportsSnapshot = await _db.collection('reports').where('reporterId', isEqualTo: userId).get();
        for (var report in reportsSnapshot.docs) {
          await report.reference.delete();
        }

        // 8. Delete any blocked users list
        final blockedUsersSnapshot = await _db.collection('blocked_users').where('userId', isEqualTo: userId).get();
        for (var blockedUser in blockedUsersSnapshot.docs) {
          await blockedUser.reference.delete();
        }

        // 9. Delete any user settings
        final settingsSnapshot = await _db.collection('user_settings').where('userId', isEqualTo: userId).get();
        for (var setting in settingsSnapshot.docs) {
          await setting.reference.delete();
        }

        // 10. Delete any user activity logs
        final activityLogsSnapshot = await _db.collection('activity_logs').where('userId', isEqualTo: userId).get();
        for (var log in activityLogsSnapshot.docs) {
          await log.reference.delete();
        }

        // 11. Delete any user search history
        final searchHistorySnapshot = await _db.collection('search_history').where('userId', isEqualTo: userId).get();
        for (var history in searchHistorySnapshot.docs) {
          await history.reference.delete();
        }

        // 12. Delete any user preferences
        final preferencesSnapshot = await _db.collection('user_preferences').where('userId', isEqualTo: userId).get();
        for (var preference in preferencesSnapshot.docs) {
          await preference.reference.delete();
        }

        // 13. Update any lists or collections that might reference the user
        final listsSnapshot = await _db.collection('lists').where('members', arrayContains: userId).get();
        for (var list in listsSnapshot.docs) {
          await list.reference.update({
            'members': FieldValue.arrayRemove([userId])
          });
        }

        // 14. Update any groups that might have the user as a member
        final groupsSnapshot = await _db.collection('groups').where('members', arrayContains: userId).get();
        for (var group in groupsSnapshot.docs) {
          await group.reference.update({
            'members': FieldValue.arrayRemove([userId])
          });
        }

        // 15. Finally, delete the user's authentication account
        await user.delete();

        print('Successfully deleted all user data from Firestore and Authentication');
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Create a pending message
  Future<DocumentReference> createPendingMessage(
    String receiverID,
    String message, {
    MessageType type = MessageType.text,
  }) async {
    try {
      // Get current user info
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;
      final Timestamp timestamp = Timestamp.now();

      // Create a new message
      Message newMessage = Message(
        senderID: currentUserEmail,
        senderEmail: currentUserId,
        receiverID: receiverID,
        message: message,
        timestamp: timestamp,
        type: type,
        status: MessageStatus.pending,
      );

      // Construct chat room ID
      List<String> ids = [currentUserId, receiverID];
      ids.sort();
      String chatRoomID = ids.join('_');

      // Create or update chat room
      await _db.collection("chat_rooms").doc(chatRoomID).set({
        'participants': [currentUserId, receiverID],
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'createdAt': timestamp,
      }, SetOptions(merge: true));

      // Add pending message and return its reference
      return await _db
          .collection("chat_rooms")
          .doc(chatRoomID)
          .collection("messages")
          .add(newMessage.toMap());
    } catch (e) {
      print("Error creating pending message: $e");
      rethrow;
    }
  }

  // Update a pending message with media URL
  Future<void> updatePendingMessage(
    DocumentReference messageDoc,
    String message, {
    String? mediaUrl,
    int? audioDuration,
  }) async {
    try {
      await messageDoc.update({
        'message': message,
        'mediaUrl': mediaUrl,
        'audioDuration': audioDuration,
        'status': MessageStatus.sent.toString(),
      });
    } catch (e) {
      print("Error updating pending message: $e");
      rethrow;
    }
  }

  // Delete a pending message
  Future<void> deletePendingMessage(DocumentReference messageDoc) async {
    try {
      await messageDoc.delete();
    } catch (e) {
      print("Error deleting pending message: $e");
      rethrow;
    }
  }
}
