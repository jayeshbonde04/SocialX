import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/domain/repos/profile_user.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/storage/domain/storage_repo.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final ProfileRepo profileRepo;
  final StorageRepo storageRepo;
  final AuthCubit authCubit;

  ProfileCubit({
    required this.storageRepo,
    required this.profileRepo,
    required this.authCubit,
  }) : super(ProfileInitial());

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
    String? currentPassword,
    bool? newIsPrivate,
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

      // Update email if changed
      if (newEmail != null && newEmail != currentUser.email) {
        try {
          if (currentPassword == null) {
            emit(ProfileErrors("Current password is required to update email"));
            return;
          }
          
          // First update email in Firebase Auth
          try {
            await authCubit.updateEmail(newEmail, currentPassword);
          } catch (e) {
            // Check if the error is about email verification
            if (e.toString().contains('verify your current email')) {
              emit(ProfileErrors("Please verify your current email before changing it. A verification email has been sent."));
              return;
            } else if (e.toString().contains('verify your new email')) {
              emit(ProfileSuccess("Email updated successfully. Please verify your new email."));
              // Continue with profile update
            } else {
              // Re-throw other errors
              rethrow;
            }
          }
        } catch (e) {
          emit(ProfileErrors(e.toString()));
          return;
        }
      }

      //create updated profile
      final updatedProfile = currentUser.copyWith(
        newBio: newBio,
        newProfileImageUrl: imageDownloadUrl,
        newName: newName,
        newEmail: newEmail,
        newIsPrivate: newIsPrivate,
      );

      //update profile in firebase
      await profileRepo.updateProfile(updatedProfile);

      //emit success
      emit(ProfileSuccess("Profile updated successfully!"));
    } catch (e) {
      emit(ProfileErrors(e.toString()));
    }
  }

  //toggle follow status between two users
  Future<void> toggleFollow(String targetUserId, String currentUserId) async {
    try {
      emit(ProfileLoading());
      
      // Get target user profile to check if private
      final targetUser = await profileRepo.fetchUserProfile(targetUserId);
      if (targetUser == null) {
        emit(ProfileErrors("User not found"));
        return;
      }
      
      // Check if already following
      final isFollowing = targetUser.followers.contains(currentUserId);
      
      if (isFollowing) {
        // Unfollow logic
        await profileRepo.toggleFollow(targetUserId, currentUserId);
        emit(ProfileSuccess("Unfollowed ${targetUser.name}"));
        // Refresh the profile to show updated state
        await fetchUserProfile(targetUserId);
      } else if (targetUser.isPrivate) {
        // For private accounts, send follow request
        await profileRepo.toggleFollow(targetUserId, currentUserId);
        emit(FollowRequestSent("Follow request sent to ${targetUser.name}"));
        // Refresh the profile to show updated state
        await fetchUserProfile(targetUserId);
      } else {
        // For public accounts, follow directly
        await profileRepo.toggleFollow(targetUserId, currentUserId);
        emit(ProfileSuccess("Following ${targetUser.name}"));
        // Refresh the target user's profile to get updated followers list
        await fetchUserProfile(targetUserId);
      }
    } catch (e) {
      emit(ProfileErrors("Failed to toggle follow: $e"));
    }
  }

  // Handle follow request (accept/reject)
  Future<void> handleFollowRequest(String targetUserId, String currentUserId, bool accept) async {
    try {
      emit(ProfileLoading());
      await profileRepo.handleFollowRequest(targetUserId, currentUserId, accept);
      
      if (accept) {
        emit(FollowRequestAccepted("Follow request accepted"));
      } else {
        emit(FollowRequestRejected("Follow request rejected"));
      }
      
      // Refresh both profiles
      await fetchUserProfile(targetUserId);
      await fetchUserProfile(currentUserId);
    } catch (e) {
      emit(ProfileErrors("Failed to handle follow request: $e"));
    }
  }

  // Get follow requests for current user
  Future<List<String>> getFollowRequests(String userId) async {
    try {
      return await profileRepo.getFollowRequests(userId);
    } catch (e) {
      emit(ProfileErrors("Failed to get follow requests: $e"));
      return [];
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

  // Refresh profile data
  Future<void> refreshProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final user = await profileRepo.fetchUserProfile(uid);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileErrors("User not found!"));
      }
    } catch (e) {
      emit(ProfileErrors("Failed to refresh profile: $e"));
    }
  }
}
