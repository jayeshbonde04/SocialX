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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
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

    //extract username from email
    String username = email.split('@')[0];

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

      print("Message sent successfully to chat room: $chatRoomID");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  //GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    //construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

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

        // 1. Delete user's posts
        final postsSnapshot =
            await _db.collection('posts').where('uid', isEqualTo: userId).get();
        for (var doc in postsSnapshot.docs) {
          await doc.reference.delete();
        }

        // 2. Delete user's profile data
        await _db.collection('users').doc(userId).delete();

        // 3. Delete user's chat rooms and messages
        final chatRoomsSnapshot = await _db
            .collection('chat_rooms')
            .where('participants', arrayContains: userId)
            .get();

        for (var chatRoom in chatRoomsSnapshot.docs) {
          // Delete all messages in the chat room
          final messagesSnapshot =
              await chatRoom.reference.collection('messages').get();
          for (var message in messagesSnapshot.docs) {
            await message.reference.delete();
          }
          // Delete the chat room itself
          await chatRoom.reference.delete();
        }

        // 4. Remove user from other users' followers/following lists
        final allUsersSnapshot = await _db.collection('users').get();
        for (var userDoc in allUsersSnapshot.docs) {
          if (userDoc.id != userId) {
            await userDoc.reference.update({
              'followers': FieldValue.arrayRemove([userId]),
              'following': FieldValue.arrayRemove([userId]),
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

        // 6. Finally, delete the user's authentication account
        await user.delete();
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
