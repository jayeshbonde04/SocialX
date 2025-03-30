/*
   USER PROFILE
  This is what every user should have for there profile

 -uid
 -name
 -email
 -username
 -bio
 -profile photo

*/
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter/cupertino.dart';

class Userprofile{
  final String uid;
  final String name;
  final String email;
  final String username;
  final String bio;

  Userprofile({required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.bio});

/*
firebase -> app
convert firestore document to a user profile (so we can use our app)
 */
  factory Userprofile.fromDocument(DocumentSnapshot doc){
    return Userprofile(
      uid: doc['uid'],
      name: doc['name'],
      email: doc['email'],
      username: doc['username'],
      bio: doc['bio'],
    );

  }

/*app -> firebase
covert a user profile to a map(so we can store in firebase)
*/
  Map<String, dynamic> toMap() {
    return{
      'uid': uid,
      'name': name,
      'email': email,
      'username': username,
      'bio': bio,
    };
  }
}
