import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/domain/repos/profile_user.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      //get the user document from firestore
      final userDoc =
          await firebaseFirestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        if (userData != null) {
          // Debug prints
          print("User data from Firestore: $userData");
          print("Followers: ${userData['followers']}");
          print("Following: ${userData['following']}");

          return ProfileUser(
            uid: uid,
            email: userData['email'] ?? '',
            name: userData['name'] ?? '',
            bio: userData['bio'] ?? '',
            profileImageUrl: userData['profileImageUrl'].toString(),
            followers: List<String>.from(userData['followers'] ?? []),
            following: List<String>.from(userData['following'] ?? []),
            isPrivate: userData['isPrivate'] ?? false,
          );
        }
      }

      return null;
    } catch (e) {
      print("Error fetching user profile $e");
      return null;
    }
  }

  @override
  Future<void> updateProfile(ProfileUser updateProfile) async {
    try {
      //convert updated profile to json to store in firestore
      final Map<String, dynamic> updateData = {
        'bio': updateProfile.bio,
        'profileImageUrl': updateProfile.profileImageUrl,
        'followers': updateProfile.followers,
        'following': updateProfile.following,
        'name': updateProfile.name,
        'email': updateProfile.email,
        'isPrivate': updateProfile.isPrivate,
      };

      await firebaseFirestore
          .collection('users')
          .doc(updateProfile.uid)
          .update(updateData);
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception(e);
    }
  }

  @override
  Future<void> toggleFollow(String targetUserId, String currentUserId) async {
    try {
      // Get both users' documents
      final targetUserDoc =
          await firebaseFirestore.collection('users').doc(targetUserId).get();
      final currentUserDoc =
          await firebaseFirestore.collection('users').doc(currentUserId).get();

      if (!targetUserDoc.exists || !currentUserDoc.exists) {
        throw Exception('User not found');
      }

      final targetUserData = targetUserDoc.data()!;
      final currentUserData = currentUserDoc.data()!;

      // Check if target user's account is private
      final isPrivateAccount = targetUserData['isPrivate'] ?? false;

      // Get current followers and following lists
      final targetFollowers =
          List<String>.from(targetUserData['followers'] ?? []);
      final currentFollowing =
          List<String>.from(currentUserData['following'] ?? []);

      // Get follow requests list
      final followRequests = List<String>.from(targetUserData['followRequests'] ?? []);

      // Check if current user is already following target user
      final isFollowing = targetFollowers.contains(currentUserId);

      if (isFollowing) {
        // Unfollow logic
        targetFollowers.remove(currentUserId);
        currentFollowing.remove(targetUserId);
        
        // Update both users in Firestore
        await Future.wait([
          firebaseFirestore.collection('users').doc(targetUserId).update({
            'followers': targetFollowers,
          }),
          firebaseFirestore.collection('users').doc(currentUserId).update({
            'following': currentFollowing,
          }),
        ]);

        // Create unfollow notification
        final currentUserName = currentUserData['name'] ?? 'Someone';
        await firebaseFirestore.collection('notifications').add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'userId': targetUserId,
          'actorId': currentUserId,
          'type': 'unfollow',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'metadata': {
            'actorName': currentUserName,
          },
        });
      } else {
        // Follow logic
        if (isPrivateAccount) {
          // For private accounts, add to follow requests
          if (!followRequests.contains(currentUserId)) {
            followRequests.add(currentUserId);
            
            // Update target user's follow requests
            await firebaseFirestore.collection('users').doc(targetUserId).update({
              'followRequests': followRequests,
            });

            // Create follow request notification
            final currentUserName = currentUserData['name'] ?? 'Someone';
            await firebaseFirestore.collection('notifications').add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'userId': targetUserId,
              'actorId': currentUserId,
              'type': 'followRequest',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'metadata': {
                'actorName': currentUserName,
              },
            });
          }
        } else {
          // For public accounts, follow directly
          targetFollowers.add(currentUserId);
          currentFollowing.add(targetUserId);
          
          // Update both users in Firestore
          await Future.wait([
            firebaseFirestore.collection('users').doc(targetUserId).update({
              'followers': targetFollowers,
            }),
            firebaseFirestore.collection('users').doc(currentUserId).update({
              'following': currentFollowing,
            }),
          ]);

          // Create follow notification
          final currentUserName = currentUserData['name'] ?? 'Someone';
          await firebaseFirestore.collection('notifications').add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': targetUserId,
            'actorId': currentUserId,
            'type': 'follow',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'metadata': {
              'actorName': currentUserName,
            },
          });
        }
      }
    } catch (e) {
      print("Error toggling follow: $e");
      throw Exception(e);
    }
  }

  @override
  Future<void> handleFollowRequest(String targetUserId, String currentUserId, bool accept) async {
    try {
      // Get both users' documents
      final targetUserDoc = await firebaseFirestore.collection('users').doc(targetUserId).get();
      final currentUserDoc = await firebaseFirestore.collection('users').doc(currentUserId).get();

      if (!targetUserDoc.exists || !currentUserDoc.exists) {
        throw Exception('User not found');
      }

      final targetUserData = targetUserDoc.data()!;
      final currentUserData = currentUserDoc.data()!;

      // Get current lists
      final targetFollowers = List<String>.from(targetUserData['followers'] ?? []);
      final currentFollowing = List<String>.from(currentUserData['following'] ?? []);
      final followRequests = List<String>.from(targetUserData['followRequests'] ?? []);

      // Remove from follow requests
      followRequests.remove(currentUserId);

      if (accept) {
        // Add to followers/following
        targetFollowers.add(currentUserId);
        currentFollowing.add(targetUserId);

        // Create follow notification
        final targetUserName = targetUserData['name'] ?? 'Someone';
        await firebaseFirestore.collection('notifications').add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'userId': currentUserId,
          'actorId': targetUserId,
          'type': 'follow',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'metadata': {
            'actorName': targetUserName,
          },
        });
      }

      // Update both users in Firestore
      await Future.wait([
        firebaseFirestore.collection('users').doc(targetUserId).update({
          'followers': targetFollowers,
          'followRequests': followRequests,
        }),
        firebaseFirestore.collection('users').doc(currentUserId).update({
          'following': currentFollowing,
        }),
      ]);
    } catch (e) {
      print("Error handling follow request: $e");
      throw Exception(e);
    }
  }

  @override
  Future<List<String>> getFollowRequests(String userId) async {
    try {
      final userDoc = await firebaseFirestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      return List<String>.from(userData['followRequests'] ?? []);
    } catch (e) {
      print("Error getting follow requests: $e");
      throw Exception(e);
    }
  }

  @override
  Future<List<ProfileUser>> getFollowers(String uid) async {
    try {
      // Get the user's document to get their followers list
      final userDoc =
          await firebaseFirestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final followers = List<String>.from(userData['followers'] ?? []);

      // Get all followers' profiles
      final followersProfiles = await Future.wait(
        followers.map((followerId) => fetchUserProfile(followerId)),
      );

      // Filter out any null values and return the list
      return followersProfiles.whereType<ProfileUser>().toList();
    } catch (e) {
      print("Error fetching followers: $e");
      throw Exception(e);
    }
  }

  @override
  Future<List<ProfileUser>> getFollowing(String uid) async {
    try {
      // Get the user's document to get their following list
      final userDoc =
          await firebaseFirestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final following = List<String>.from(userData['following'] ?? []);

      // Get all following users' profiles
      final followingProfiles = await Future.wait(
        following.map((followingId) => fetchUserProfile(followingId)),
      );

      // Filter out any null values and return the list
      return followingProfiles.whereType<ProfileUser>().toList();
    } catch (e) {
      print("Error fetching following: $e");
      throw Exception(e);
    }
  }
}
