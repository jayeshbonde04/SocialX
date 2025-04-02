import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/components/my_textfield.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/posts/domain/entities/comment.dart';
import 'package:socialx/features/posts/presentation/components/comment_tile.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import '../../domain/entities/post.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubits/profile_cubits.dart';
import 'package:share_plus/share_plus.dart';
import 'package:socialx/themes/app_colors.dart';

// Dark mode color scheme with lighter shades
const Color primaryColor = Color(0xFF1E293B); // Lighter dark blue-gray
const Color secondaryColor = Color(0xFF2D3748); // Slightly lighter secondary
const Color accentColor =
    Color(0xFF60A5FA); // Bright blue for interactive elements
const Color backgroundColor = Color(0xFF111827); // Dark background
const Color surfaceColor = Color(0xFF1F2937); // Lighter surface color
const Color textPrimary = Color(0xFFF3F4F6); // Light gray for primary text
const Color textSecondary = Color(0xFF9CA3AF); // Medium gray for secondary text
const Color dividerColor = Color(0xFF374151); // Dark gray for dividers
const Color errorColor = Color(0xFFEF4444); // Red for errors and delete actions

class PostTile extends StatefulWidget {
  final Post post;
  final void Function()? onDeletePressed;
  const PostTile(
      {super.key, required this.post, required this.onDeletePressed});

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  //cubits
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();

  bool isOwnPost = false;
  bool isFollowing = false;

  //current user
  AppUsers? currentUser;

  // post User
  ProfileUser? postUser;

  //on startup
  @override
  void initState() {
    super.initState();

    getCurrentUser();
    fetchPostUser();
  }

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentuser;
    isOwnPost = (widget.post.userId == currentUser!.uid);
  }

  Future<void> fetchPostUser() async {
    final fetchUser = await profileCubit.getUserProfile(widget.post.userId);
    if (fetchUser != null) {
      setState(() {
        postUser = fetchUser;
        isFollowing = fetchUser.followers.contains(currentUser!.uid);
      });
    }
  }

  void toggleFollow() async {
    if (currentUser == null || postUser == null) return;

    setState(() {
      isFollowing = !isFollowing;
    });

    try {
      await profileCubit.toggleFollow(postUser!.uid, currentUser!.uid);
    } catch (e) {
      // Revert on error
      setState(() {
        isFollowing = !isFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to ${isFollowing ? 'follow' : 'unfollow'}: $e')),
      );
    }
  }

  /*
  * Likes
  * */

  //user tapped like button
  void toggleLikePost() {
    //current like status
    final isLiked = widget.post.likes.contains(currentUser!.uid);

    // optimistically like & update Ui
    setState(() {
      if (isLiked) {
        widget.post.likes.remove(currentUser!.uid); //unlike
      } else {
        widget.post.likes.add(currentUser!.uid); //like
      }
    });

    //update like
    postCubit
        .toggleLikedPost(widget.post.id, currentUser!.uid)
        .catchError((error) {
      // if there and error, revert back to original values
      setState(() {
        if (isLiked) {
          widget.post.likes.add(currentUser!.uid); // revert unlike
        } else {
          widget.post.likes.remove(currentUser!.uid); // revert like
        }
      });
    });
  }

  /*
  * Comments
  * */

  //comment text controller
  final commentTextController = TextEditingController();

  //open comment box -> user wants to type a new comment
  void openCommentBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Add a Comment",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MyTextfield(
            controller: commentTextController,
            hintText: "Write a comment...",
            obscuretext: false,
            style: bodyStyle.copyWith(color: textPrimary),
            cursorColor: textPrimary,
            decoration: InputDecoration(
              hintStyle: bodyStyle.copyWith(
                color: textSecondary.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              addComment();
              Navigator.of(context).pop();
            },
            child: const Text(
              "Post",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //add comment
  void addComment() {
    //create a new comment
    final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.post.id,
        userId: currentUser!.uid,
        userName: currentUser!.name,
        text: commentTextController.text);

    //addd comment using cubit
    if (commentTextController.text.isNotEmpty) {
      postCubit.addComment(widget.post.id, newComment);
    }
  }

  @override
  void dispose() {
    commentTextController.dispose();
    super.dispose();
  }

  // Show options for deletion
  void showOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          // Delete button
          TextButton(
            onPressed: () {
              widget.onDeletePressed?.call();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void deleteComment(String commentId) {
    postCubit.deleteComment(widget.post.id, commentId);
  }

  void _sharePost() {
    try {
      String shareText = '';

      // Add user name and post text
      if (widget.post.text.isNotEmpty) {
        shareText =
            '${postUser?.name ?? "User"} shared on SocialX:\n\n${widget.post.text}\n\n';
      } else {
        shareText = '${postUser?.name ?? "User"} shared on SocialX\n\n';
      }

      // Add image URL if available
      if (widget.post.imageUrl.isNotEmpty) {
        shareText += 'Image: ${widget.post.imageUrl}\n\n';
      }

      // Add timestamp
      shareText += 'Posted ${_getTimeAgo(widget.post.timestamp)}\n\n';

      // Add app link
      shareText += 'View on SocialX';

      // Share the content
      Share.share(shareText);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(uid: widget.post.userId),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentWithOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: postUser?.profileImageUrl != null &&
                              postUser!.profileImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: postUser!.profileImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.accentWithOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.accent,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.accentWithOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.accent,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.accentWithOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: AppColors.accent,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(uid: widget.post.userId),
                            ),
                          );
                        },
                        child: Text(
                          postUser?.name ?? 'Loading...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        _getTimeAgo(widget.post.timestamp),
                        style: TextStyle(
                          color: AppColors.textSecondaryWithOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Follow/Delete Button
                if (!isOwnPost)
                  TextButton(
                    onPressed: toggleFollow,
                    style: TextButton.styleFrom(
                      backgroundColor: isFollowing
                          ? AppColors.accentWithOpacity(0.1)
                          : AppColors.buttonPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: widget.onDeletePressed,
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          // Post Content
          if (widget.post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Post Image
          if (widget.post.imageUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.accentWithOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.accentWithOpacity(0.1),
                    child: Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          // Post Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Like Button
                _buildActionButton(
                  icon: widget.post.likes.contains(currentUser!.uid)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.post.likes.contains(currentUser!.uid)
                      ? AppColors.error
                      : AppColors.textSecondary,
                  count: widget.post.likes.length,
                  onTap: toggleLikePost,
                ),
                const SizedBox(width: 24),
                // Comment Button
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.textSecondary,
                  count: widget.post.comment.length,
                  onTap: openCommentBox,
                ),
                const SizedBox(width: 24),
                // Share Button
                _buildActionButton(
                  icon: Icons.share_outlined,
                  color: AppColors.textSecondary,
                  count: 0,
                  onTap: _sharePost,
                ),
              ],
            ),
          ),
          // Comments Section
          if (widget.post.comment.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comments',
                    style: TextStyle(
                      color: AppColors.textSecondaryWithOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.post.comment.map((comment) => CommentTile(
                        comment: comment,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
