/*
profile repository
 */

import 'package:socialx/features/profile/domain/entities/profile_user.dart';

abstract class ProfileRepo {
  Future<ProfileUser?> fetchUserProfile(String uid);
  Future<void> updateProfile(ProfileUser updateProfile);
  Future<void> toggleFollow(String targetUserId, String currentUserId);
  Future<List<ProfileUser>> getFollowers(String uid);
  Future<List<ProfileUser>> getFollowing(String uid);
}
