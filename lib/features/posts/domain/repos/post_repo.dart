import 'package:socialx/features/posts/domain/entities/post.dart';
import 'package:socialx/features/posts/domain/entities/comment.dart';

abstract class PostRepo {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId);
  Future<void> likePost(String postId, String userId);
  Future<String> addComment(String postId, String userId, String comment);
  Future<Post?> getPost(String postId);
  Future<void> deleteComment(String postId, String commentId);
  Future<void> toggleLikePost(String postId, String userId);
}
