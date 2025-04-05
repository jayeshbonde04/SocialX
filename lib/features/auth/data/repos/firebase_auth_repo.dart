import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUsers?> loginWithEmailPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        return AppUsers(
          uid: user.uid,
          email: user.email!,
          name: user.displayName ?? '',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  @override
  Future<AppUsers?> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);
        // Extract username from email
        final username = email.split('@')[0].toLowerCase();
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'username': username,
          'bio': '',
          'profileImageUrl': '',
          'followers': [],
          'following': [],
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        return AppUsers(
          uid: user.uid,
          email: user.email!,
          name: name,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  @override
  Future<AppUsers?> getCurrentUsers() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Get additional user data from Firestore
        final userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          return AppUsers(
            uid: user.uid,
            email: user.email!,
            name: userData['name'] ?? user.displayName ?? '',
            followers: List<String>.from(userData['followers'] ?? []),
            following: List<String>.from(userData['following'] ?? []),
            profileImageUrl: userData['profileImageUrl'] ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<void> deleteAccount(String currentPassword) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // First, reauthenticate the user with current password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  @override
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      final user = _auth.currentUser;
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
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  @override
  Future<AppUsers?> getUserById(String uid) async {
    try {
      final userData = await _firestore.collection('users').doc(uid).get();
      if (userData.exists) {
        return AppUsers(
          uid: uid,
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          followers: List<String>.from(userData['followers'] ?? []),
          following: List<String>.from(userData['following'] ?? []),
          profileImageUrl: userData['profileImageUrl'] ?? '',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }
}
