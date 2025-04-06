class AppUsers {
  final String uid;
  final String email;
  final String name;
  final List<String> followers;
  final List<String> following;
  final String profileImageUrl;
  final bool isPrivate;

  AppUsers({
    required this.uid,
    required this.email,
    required this.name,
    this.followers = const [],
    this.following = const [],
    this.profileImageUrl = '',
    this.isPrivate = false,
  });

  //convert app user to json
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'followers': followers,
      'following': following,
      'profileImageUrl': profileImageUrl,
      'isPrivate': isPrivate,
    };
  }

  //convert json to app user
  factory AppUsers.fromJson(Map<String, dynamic> jsonUser) {
    return AppUsers(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      name: jsonUser['name'],
      followers: List<String>.from(jsonUser['followers'] ?? []),
      following: List<String>.from(jsonUser['following'] ?? []),
      profileImageUrl: jsonUser['profileImageUrl'] ?? '',
      isPrivate: jsonUser['isPrivate'] ?? false,
    );
  }
}
