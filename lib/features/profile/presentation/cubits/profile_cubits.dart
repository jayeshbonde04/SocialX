import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/domain/repos/profile_user.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/storage/domain/storage_repo.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final ProfileRepo profileRepo;
  final StorageRepo storageRepo;

  ProfileCubit({required this.storageRepo, required this.profileRepo})
      : super(ProfileInitial());

  //fetch user profile using repo -> useful for loading single profile pages
  Future<void> fetchUserProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final user = await profileRepo.fetchUserProfile(uid);

      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileErrors("User not found!"));
      }
    } catch (e) {
      emit(ProfileErrors(e.toString()));
    }
  }

  //return user profile given uid-> useful for loading many profiles for posts
  Future<ProfileUser?> getUserProfile(String uid) async {
    final user = await profileRepo.fetchUserProfile(uid);
    return user;
  }

  //update bio or profile picture
  Future<void> updateProfile({
    required String uid,
    String? newBio,
    Uint8List? imageWebBytes,
    String? imageMobilePath,
    String? newName,
    String? newEmail,
  }) async {
    emit(ProfileLoading());

    try {
      //fetch current profile first
      final currentUser = await profileRepo.fetchUserProfile(uid);

      if (currentUser == null) {
        emit(ProfileErrors("Failed to fetch user profile update"));
        return;
      }

      //profile picture update
      String? imageDownloadUrl;

      if (imageWebBytes != null || imageMobilePath != null) {
        //for mobile
        if (imageMobilePath != null) {
          //upload
          imageDownloadUrl =
              await storageRepo.uploadProfileImageMobile(imageMobilePath, uid);
        }

        //for web
        else if (imageWebBytes != null) {
          //upload
          imageDownloadUrl =
              await storageRepo.uploadProfileImageWeb(imageWebBytes, uid);
        }

        if (imageDownloadUrl == null) {
          emit(ProfileErrors("Failed to upload image"));
          return;
        }
      }

      //update new profile
      final updateProfile = currentUser.copyWith(
        newBio: newBio ?? currentUser.bio,
        newProfileImageUrl: imageDownloadUrl ?? currentUser.profileImageUrl,
        newName: newName ?? currentUser.name,
        newEmail: newEmail ?? currentUser.email,
      );

      //update in repo
      await profileRepo.updateProfile(updateProfile);

      //refetch the update profile
      await fetchUserProfile(uid);
    } catch (e) {
      emit(ProfileErrors('Error fetching user profile'));
    }
  }

  //toggle follow status between two users
  Future<void> toggleFollow(String targetUserId, String currentUserId) async {
    try {
      await profileRepo.toggleFollow(targetUserId, currentUserId);
      // Refresh the profile to show updated follow status
      await fetchUserProfile(targetUserId);
    } catch (e) {
      emit(ProfileErrors("Failed to toggle follow: $e"));
    }
  }

  // Get list of followers for a user
  Future<List<ProfileUser>> getFollowers(String uid) async {
    try {
      final followers = await profileRepo.getFollowers(uid);
      return followers;
    } catch (e) {
      emit(ProfileErrors("Failed to fetch followers: $e"));
      return [];
    }
  }

  // Get list of users that a user is following
  Future<List<ProfileUser>> getFollowing(String uid) async {
    try {
      final following = await profileRepo.getFollowing(uid);
      return following;
    } catch (e) {
      emit(ProfileErrors("Failed to fetch following: $e"));
      return [];
    }
  }
}
