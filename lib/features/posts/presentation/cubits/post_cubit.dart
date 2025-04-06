import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart' as app_notification;
import 'package:socialx/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:socialx/features/posts/domain/entities/post.dart';
import 'package:socialx/features/posts/domain/repos/post_repo.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:socialx/storage/domain/storage_repo.dart';

class PostCubit extends Cubit<PostState> {
  final PostRepo _postRepo;
  final StorageRepo _storageRepo;
  final NotificationCubit _notificationCubit;

  PostCubit({
    required PostRepo postRepo,
    required StorageRepo storageRepo,
    required NotificationCubit notificationCubit,
  })  : _postRepo = postRepo,
        _storageRepo = storageRepo,
        _notificationCubit = notificationCubit,
        super(PostsInitial());

  Future<void> fetchAllPosts() async {
    try {
      emit(PostsLoading());
      final posts = await _postRepo.fetchAllPosts();
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> createPost(Post post, {Uint8List? imageBytes, String? imagePath}) async {
    try {
      emit(PostsUploading());
      
      // Upload image if provided
      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await _storageRepo.uploadPostImageWeb(imageBytes, 'posts/${post.id}');
      } else if (imagePath != null) {
        imageUrl = await _storageRepo.uploadPostImageMobile(imagePath, 'posts/${post.id}');
      }
      
      if (imageUrl != null) {
        post = post.copyWith(imageUrl: imageUrl);
      }
      
      await _postRepo.createPost(post);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postRepo.deletePost(postId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      await _postRepo.likePost(postId, userId);
      // Create notification for post owner
      final post = await _postRepo.getPost(postId);
      if (post != null && post.userId != userId) {
        // Get current user's name
        final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';
        
        final notification = app_notification.Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: post.userId,
          actorId: userId,
          type: app_notification.NotificationType.like,
          postId: postId,
          timestamp: DateTime.now(),
          metadata: {
            'actorName': currentUserName,
          },
        );
        _notificationCubit.createNotification(notification);
      }
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> toggleLikedPost(String postId, String userId) async {
    try {
      // Get the post to check if it's already liked
      final post = await _postRepo.getPost(postId);
      if (post == null) {
        throw Exception('Post not found');
      }
      
      // Check if the post is already liked by the user
      final isLiked = post.likes.contains(userId);
      
      // Toggle the like status
      await _postRepo.toggleLikePost(postId, userId);
      
      // Create notification for post owner if the user is liking the post (not unliking)
      if (!isLiked && post.userId != userId) {
        print('Creating like notification for post: $postId, from user: $userId, to user: ${post.userId}');
        
        // Get current user's name
        final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';
        
        final notification = app_notification.Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: post.userId,
          actorId: userId,
          type: app_notification.NotificationType.like,
          postId: postId,
          timestamp: DateTime.now(),
          metadata: {
            'actorName': currentUserName,
          },
        );
        await _notificationCubit.createNotification(notification);
      }
      
      await fetchAllPosts();
    } catch (e) {
      print('Error in toggleLikedPost: $e');
      emit(PostsError(e.toString()));
    }
  }

  Future<void> addComment(String postId, String userId, String comment) async {
    try {
      final commentId = await _postRepo.addComment(postId, userId, comment);
      // Create notification for post owner
      final post = await _postRepo.getPost(postId);
      if (post != null && post.userId != userId) {
        // Get current user's name
        final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';
        
        final notification = app_notification.Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: post.userId,
          actorId: userId,
          type: app_notification.NotificationType.comment,
          postId: postId,
          commentId: commentId,
          timestamp: DateTime.now(),
          metadata: {
            'actorName': currentUserName,
          },
        );
        _notificationCubit.createNotification(notification);
      }
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _postRepo.deleteComment(postId, commentId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }
}
