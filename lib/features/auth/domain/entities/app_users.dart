class AppUsers {
  final String uid;
  final String email;
  final String name;
  final List<String> followers;
  final List<String> following;
  final String profileImageUrl;

  AppUsers({
    required this.uid,
    required this.email,
    required this.name,
    this.followers = const [],
    this.following = const [],
    this.profileImageUrl = '',
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
    );
  }
}
