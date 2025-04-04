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
          
          // Wait for a moment to ensure Firebase Auth update is complete
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Verify the email was updated
          final updatedAuthUser = FirebaseAuth.instance.currentUser;
          if (updatedAuthUser?.email != newEmail) {
            emit(ProfileErrors("Failed to update email in Firebase Authentication"));
            return;
          }
          
          print('Email updated successfully in Firebase Auth');
        } catch (e) {
          print('Error updating email: $e');
          emit(ProfileErrors("Failed to update email: $e"));
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
      final updatedUser = await profileRepo.fetchUserProfile(uid);
      if (updatedUser != null) {
        emit(ProfileLoaded(updatedUser));
      } else {
        emit(ProfileErrors("Failed to fetch updated profile"));
      }
    } catch (e) {
      emit(ProfileErrors('Error updating profile: $e'));
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
