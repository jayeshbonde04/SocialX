import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo{
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
  DocumentSnapshot userDoc = await firebaseFirestore.collection('users')
  .doc(firebaseUser.uid)
  .get();

  //fetch if user exists
  if(!userDoc.exists){
    return null;
  }

  // If user exists
  return AppUsers(
    uid: firebaseUser.uid, 
    email: firebaseUser.email!, 
    name: userDoc['name']);
}


  @override
  Future<AppUsers?> loginWithEmailPassword(String email, String password) async {
    try {
      //attempt sign in
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      //fetch user document from firestore
      DocumentSnapshot userDoc = await firebaseFirestore.collection('users')
      .doc(userCredential.user!.uid)
      .get();


      //create user
      AppUsers user = AppUsers(
          uid: userCredential.user!.uid,
          email:email,
          name: userDoc['name']);

      //return user
      return user;

      //catch any errors
    } catch (e) {
      throw Exception('login failed: $e');
    }
  }

  @override
  Future<void> logout() async{
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<AppUsers?> registerWithEmailPassword(String name, String email, String password) async {
    try {
      //attempt sign in
      UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      //create user
      AppUsers user = AppUsers(uid: userCredential.user!.uid, email:email, name: name);

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
}