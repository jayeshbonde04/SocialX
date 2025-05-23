import 'package:socialx/features/auth/domain/entities/app_users.dart';

class ProfileUser extends AppUsers {
  final String bio;
  final String profileImageUrl;
  final bool isPrivate;

  ProfileUser({
    required super.uid,
    required super.email,
    required super.name,
    required this.bio,
    required this.profileImageUrl,
    super.followers = const [],
    super.following = const [],
    this.isPrivate = false,
  });

  //method to update profile user
  ProfileUser copyWith({
    String? newBio,
    String? newProfileImageUrl,
    List<String>? newFollowers,
    List<String>? newFollowing,
    String? newName,
    String? newEmail,
    bool? newIsPrivate,
  }) {
    return ProfileUser(
      uid: uid,
      email: newEmail ?? email,
      name: newName ?? name,
      bio: newBio ?? bio,
      profileImageUrl: newProfileImageUrl ?? profileImageUrl,
      followers: newFollowers ?? followers,
      following: newFollowing ?? following,
      isPrivate: newIsPrivate ?? isPrivate,
    );
  }

  //convert profile user-> json
  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'isPrivate': isPrivate,
    };
  }

  //convert json-> json user
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      isPrivate: json['isPrivate'] ?? false,
    );
  }
}
