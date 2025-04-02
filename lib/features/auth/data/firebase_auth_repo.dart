import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<AppUsers?> getCurrentUsers() async {
    final firebaseUser = firebaseAuth.currentUser;

    // If user is not logged in
    if (firebaseUser == null) {
      return null;
    }

    //fetch user document from firestore
    DocumentSnapshot userDoc =
        await firebaseFirestore.collection('users').doc(firebaseUser.uid).get();

    //fetch if user exists
    if (!userDoc.exists) {
      return null;
    }

    // If user exists
    return AppUsers(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        name: userDoc['name']);
  }

  @override
  Future<AppUsers?> loginWithEmailPassword(
      String email, String password) async {
    try {
      //attempt sign in
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      //fetch user document from firestore
      DocumentSnapshot userDoc = await firebaseFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      //create user
      AppUsers user = AppUsers(
          uid: userCredential.user!.uid, email: email, name: userDoc['name']);

      //return user
      return user;

      //catch any errors
    } catch (e) {
      throw Exception('login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<AppUsers?> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      //attempt sign in
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      //create user
      AppUsers user =
          AppUsers(uid: userCredential.user!.uid, email: email, name: name);

      //save user data in firestore
      await firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());

      //return user
      return user;

      //catch any errors
    } catch (e) {
      throw Exception('Registeration failed: $e');
    }
  }

  @override
  Future<void> deleteAccount(String currentPassword) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        final String userId = user.uid;

        // First, reauthenticate the user with current password
        try {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);
        } catch (e) {
          print('Reauthentication error: $e');
          throw Exception(
              'Failed to reauthenticate user. Please check your password and try again.');
        }

        // 1. Delete user's posts
        final postsSnapshot = await firebaseFirestore
            .collection('posts')
            .where('uid', isEqualTo: userId)
            .get();
        for (var doc in postsSnapshot.docs) {
          await doc.reference.delete();
        }

        // 2. Delete user's profile data
        await firebaseFirestore.collection('users').doc(userId).delete();

        // 3. Delete user's chat rooms and messages
        final chatRoomsSnapshot = await firebaseFirestore
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
        final allUsersSnapshot =
            await firebaseFirestore.collection('users').get();
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
          final userDoc =
              await firebaseFirestore.collection('users').doc(userId).get();
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
      throw Exception('Failed to delete account: $e');
    }
  }

  // Update user's email
  @override
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        // First, reauthenticate the user with current password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        // Reauthenticate the user
        await user.reauthenticateWithCredential(credential);

        // Now update the email in Firebase Auth
        await user.updateEmail(newEmail);

        // Update email in Firestore
        await firebaseFirestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });
      }
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
