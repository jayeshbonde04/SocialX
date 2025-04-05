import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:socialx/services/database/database_service.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

  @override
  Future<AppUsers?> getUserById(String uid) async {
    try {
      DocumentSnapshot userDoc = await firebaseFirestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      return AppUsers(
        uid: uid,
        email: userDoc['email'],
        name: userDoc['name']
      );
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

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
        // First, reauthenticate the user with current password
        try {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);
        } catch (e) {
          print('Reauthentication error: $e');
          throw Exception('Failed to reauthenticate user. Please check your password and try again.');
        }

        // Use the comprehensive deletion method from DatabaseService
        await _databaseService.deleteAccount();
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

        // Check if the current email is verified
        if (!user.emailVerified) {
          // Send verification email to the current email
          await user.sendEmailVerification();
          throw Exception('Please verify your current email before changing it. A verification email has been sent.');
        }

        // Now update the email in Firebase Auth
        await user.updateEmail(newEmail);
        
        // Send verification email to the new email
        await user.sendEmailVerification();

        // Update email in Firestore
        await firebaseFirestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });

        // Force refresh the user token to ensure the new email is reflected
        await user.reload();
        
        print('Email updated successfully in both Firebase Auth and Firestore. Please verify your new email.');
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      print('Error updating email: $e');
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
